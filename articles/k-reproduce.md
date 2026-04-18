# reproduce.jl — birth, inheritance, parental cost

## `reproduce.jl` — birth, inheritance, and parental cost

This file is where new agents come from. Once per tick, every eligible
parent produces a clutch of offspring. Each offspring inherits its brain
from one or two parents (depending on ploidy) via a meiosis-like genome
operation, with mutation. The parent pays an energetic cost; the
offspring starts life with some energy.

This is also where the **0.4.0 kernel changes** for proportional
parental cost and proportional offspring birth energy live. Both
implement Smith & Fretwell (1974) life-history theory.

Source file:
[`inst/julia/src/reproduce.jl`](https://github.com/itchyshin/clade/blob/main/inst/julia/src/reproduce.jl)
(~330 lines).

------------------------------------------------------------------------

### 1. Function header — load reproduction parameters

``` julia
function create_offspring!(env::Environment)
    specs     = env.specs
    refresh_sorting_centroid!(env)
    # 0.4.0: parental cost can be either fixed (legacy) or proportional to
    # parent energy. Proportional cost is the biological default per
    # Smith & Fretwell (1974) and all life-history theory: parents in
    # better condition have more to invest. Fixed-cost mode preserved for
    # reproducibility of pre-0.4.0 runs.
    repro_cost_mode = String(get(specs, "repro_cost_mode", "proportional"))
    repro_cost      = Float32(get(specs, "repro_cost",          30.0))
    repro_cost_frac = Float32(get(specs, "repro_cost_fraction", 0.5))
    off_energy_base = Float32(get(specs, "offspring_energy",    60.0))
    off_energy_mode = String(get(specs, "offspring_energy_mode", "proportional"))
    off_energy_frac = Float32(get(specs, "offspring_energy_fraction", 0.25))
    max_ag    = Int(get(specs, "max_agents",           500))
    care      = Bool(get(specs, "parental_care",       false))
    allee_th      = Int(get(specs, "allee_threshold",  0))
    min_repro_age = Int32(get(specs, "min_repro_age",  0))
```

**What this says.** Read all the reproduction-related parameters once at
the top:

- `repro_cost_mode` — `"proportional"` (default in 0.4.0) or `"fixed"`
  (legacy). Determines how much energy the parent pays per offspring.
- `repro_cost`, `repro_cost_fraction` — the actual cost values for each
  mode.
- `off_energy_mode`, `offspring_energy`, `off_energy_fraction` —
  parallel structure for newborn starting energy.
- `max_ag` — population cap; reproduction stops once reached.
- `care` — whether to use the parental-care pathway.
- `allee_th` — minimum neighbour count to reproduce (Allee effect).
- `min_repro_age` — minimum age before reproduction is allowed.

**Biology.** This block encodes most of the **life-history theory** in
the model. The choices here determine whether the model can recover
predictions like Smith-Fretwell quality-quantity, Cole’s paradox,
Trivers’ parental investment, and r/K selection.

The 0.4.0 default (`"proportional"`) implements the textbook Smith &
Fretwell (1974) model: parents in better condition have *more* to
invest. The legacy `"fixed"` mode (constant cost regardless of parent
condition) preserves backward compatibility with pre-0.4.0 runs but is
biologically less realistic.

**Audit findings.** The 0.3.x fixed-cost implementation was directly
flagged by the s-parental-investment audit: `female_investment` had no
detectable effect on outcomes because per-offspring cost didn’t scale
with anything related to parental condition. The 0.4.0 proportional mode
should make `female_investment` couple to outcomes via the `cost_paid`
quantity that ripples through to offspring birth energy.

**Variants worth considering.**

- **Quadratic cost** (cost ∝ energy²) would make high-condition parents
  pay disproportionately more — a “winner’s curse” pattern documented in
  some species.
- **Cost depending on clutch size** (each additional offspring costs
  more than the last — diminishing returns) is a Smith-Fretwell
  refinement. Currently each offspring in a clutch costs the same.

------------------------------------------------------------------------

### 2. Eligibility checks — who can reproduce

``` julia
for ag in env.agents
    ag.alive              || continue
    ag.reproduced         && continue
    ag.age < min_repro_age && continue
    ag.energy < effective_repro_threshold(ag, env) && continue
    length(env.agents) + length(new_agents) >= max_ag && break

    # Allee effect: count neighbours
    if allee_th > 0
        n_nbrs = _count_neighbours(ag, env)
        n_nbrs < allee_th && continue
    end
```

**What this says.** Loop over every agent. Skip those that are dead,
have already reproduced this tick, are too young, or have insufficient
energy. Stop entirely if the population cap is reached. If an Allee
threshold is set, also skip agents without enough neighbours.

**Biology.** Four biological gates:

1.  **Alive.** Dead agents don’t reproduce.
2.  **Not already reproduced this tick.** Each agent reproduces at most
    once per tick. (For semelparous species the `reproduced` flag is
    then used by `death.jl` to kill the parent on the next tick.)
3.  **Age threshold.** Below `min_repro_age`, no reproduction. Default
    is 0 (clade) — any age can reproduce — which differs from the
    ancestors (MATLAB and alifeR both required minimum age). This is a
    simplification that can be reversed by the user. Real animals
    universally have a juvenile period.
4.  **Energy threshold.** Must have at least `effective_repro_threshold`
    energy. The `effective_` prefix means plasticity-adjusted: with
    `phenotypic_plasticity = TRUE`, the threshold can vary per agent.
5.  **Allee effect** (optional, off by default). Below a critical
    neighbour density, reproduction stops. Models species that depend on
    group cohesion for breeding (Allee 1931).

**Audit findings.** The s-life-history audit ✅ verified this
eligibility logic. Semelparous and iteroparous strategies produce
distinct demographic signatures (mean age 13 vs 102, births 4.2 vs 0.9
per tick). The `reproduced` flag interaction with `death.jl`’s
semelparous trigger is wired correctly.

**Variants worth considering.**

1.  **Reproductive senescence** — older agents reproduce with reduced
    probability. Currently can only be implemented via the
    `senescence_rate` parameter in `death.jl`, which causes death rather
    than fecundity reduction.
2.  **Condition-dependent threshold** — the threshold itself could
    depend on the agent’s body size, social rank, etc.

------------------------------------------------------------------------

### 3. Clutch size — how many offspring per event

``` julia
clutch = if Bool(get(specs, "clutch_size_evolution", false))
    lo = Int(get(specs, "clutch_size_min", 1))
    hi = Int(get(specs, "clutch_size_max", 5))
    mu = Float64(get(specs, "clutch_size_init_mean", 1.0))
    sd = Float64(get(specs, "clutch_size_mutation_sd", 0.3))
    clamp(round(Int, mu + randn(env.rng) * sd), lo, hi)
else
    Int(get(specs, "max_clutch_size", 1))
end
env.n_repro_events += Int32(1)
env.n_clutch_total += Int32(clutch)
```

**What this says.** Determine the clutch size for this reproduction
event. If `clutch_size_evolution` is on, sample from a truncated normal
(mean = init_mean, sd = mutation_sd, clamped to \[clutch_size_min,
clutch_size_max\]). Otherwise use the fixed `max_clutch_size`. Update
bookkeeping counters.

**Biology.** **Clutch size** is one of the most-studied life-history
traits (Lack 1947, *Ibis* 89:302-352). The trade-off: many small
offspring vs few large ones. Lack proposed the optimal clutch size is
the one that maximises *raised* offspring (not just born).

clade’s implementation lets clutch size evolve as a heritable trait,
sampled per parent per reproduction event. Truncated-normal sampling
introduces stochastic variation — biologically reasonable, since real
clutch sizes vary among individuals even with identical genotypes.

**Audit findings.** s-clutch-size ✅ recovered the bell-shaped r/K
response: clutch rises with grass_rate (r-arm) up to 0.15, then falls as
the population hits the cap and density-dependent K-selection takes
over. Clean recovery of MacArthur-Wilson r/K theory at the population
level.

**Variants worth considering.**

1.  **Iteroparous birth distribution** — currently every agent gives
    birth to its full clutch in one tick, then waits for the
    `reproduced` flag to clear next tick. Real iteroparous species often
    spread births across days/weeks within a season.
2.  **Maternal effects** — clutch size in real species is influenced by
    maternal condition, age, and even prior reproductive history.
    Currently only the genome-encoded clutch trait matters.

------------------------------------------------------------------------

### 4. Cost (the 0.4.0 change)

``` julia
for _ in 1:clutch
    length(env.agents) + length(new_agents) >= max_ag && break

    # Find mate (or reproduce asexually)
    mate = _find_mate(ag, env)

    # 0.4.0: parental cost
    #   "fixed"        — deduct constant `repro_cost` (legacy)
    #   "proportional" — deduct `repro_cost_fraction * parent.energy`
    #                    (Smith & Fretwell 1974; default in 0.4.0)
    cost_paid = if repro_cost_mode == "proportional"
        repro_cost_frac * ag.energy
    else
        repro_cost
    end
    ag.energy -= cost_paid
    mate !== nothing && (mate.energy -= cost_paid * 0.5f0)

    # 0.4.0: offspring birth energy
    #   "fixed"        — every newborn starts with `offspring_energy`
    #                    (legacy; ignores parent condition)
    #   "proportional" — newborn starts with `offspring_energy_fraction
    #                    * cost_paid` per Smith-Fretwell quality-quantity
    #                    (default in 0.4.0)
    off_energy_actual = if off_energy_mode == "proportional"
        off_energy_frac * cost_paid
    else
        off_energy_base
    end
```

**What this says.** For each offspring in the clutch:

1.  Find a mate (or set mate to `nothing` for asexual reproduction).
2.  Compute `cost_paid` — either fixed `repro_cost` or
    `repro_cost_fraction * parent_energy`, depending on mode.
3.  Deduct from parent’s energy. If a mate is present, deduct half from
    the mate too.
4.  Compute the offspring’s starting energy — either fixed
    `offspring_energy` or `offspring_energy_fraction * cost_paid`, per
    the second mode flag.

**Biology.** This is the **parental investment trade-off** — the
mathematical core of life-history theory. Smith & Fretwell (1974) showed
that the optimal allocation of parental resources depends on the
marginal fitness gain per unit invested in a single offspring. In
practice this means:

- Parents in better condition can invest more total or per-offspring.
- Each unit of investment yields diminishing returns in offspring
  fitness — a single super-rich offspring isn’t necessarily more fit
  than two moderately-rich ones.

The 0.4.0 default (`"proportional"`) implements this directly:

- `cost_paid = 0.5 * parent.energy` (default
  `repro_cost_fraction = 0.5`)
- `offspring_energy = 0.25 * cost_paid` (default
  `offspring_energy_fraction = 0.25`)
- The other 75% of cost is “lost to development” — eggshells, gestation
  inefficiency, placental drain, etc. This 25-40% conversion efficiency
  is documented for many vertebrates.

The mate paying half the cost models **biparental investment** — stable
in many vertebrates and birds. Asexual or single-parent species get the
full cost.

**Audit findings.** Pre-0.4.0, the s-parental-investment audit was 🟠
because `female_investment` didn’t couple to outcomes. With the 0.4.0
proportional cost, it does — through the `cost_paid` chain to
`off_energy_actual`. Re-audit pending.

**Variants worth considering.**

- **Asymmetric mate cost** — currently mate pays exactly half. Some
  species have very different investments (e.g., brood-parasitic birds:
  mate pays 0%; eusocial workers: queen pays 100%).
- **Quality-vs-quantity selection** — at fixed `cost_paid`, varying
  `offspring_energy_fraction` upward produces fewer high-quality
  offspring (since cost \> offspring energy means “lost to development”
  inefficiency rises). This is the testable Smith-Fretwell knob.

------------------------------------------------------------------------

### 5. Mutation rate adjustment — stress hypermutation

``` julia
global_mut_sd = Float32(get(specs, "mutation_sd", 0.1))
evo_rate_on  = Bool(get(specs, "mutation_rate_evolution", false))
base_mut_sd  = evo_rate_on ? ag.mutation_sd : global_mut_sd
eff_mut_sd = if Bool(get(specs, "stress_hypermutation", false)) &&
                ag.energy < Float32(get(specs, "stress_threshold", 20.0))
    base_mut_sd * Float32(get(specs, "stress_mutation_multiplier", 3.0))
else
    base_mut_sd
end
specs["mutation_sd"] = eff_mut_sd
```

**What this says.** Compute the mutation rate for *this* reproduction
event:

- Default: use the global `mutation_sd` from specs.
- If `mutation_rate_evolution` is on: use the parent’s heritable
  `mutation_sd` trait.
- If `stress_hypermutation` is on AND the parent is below the stress
  threshold: multiply the mutation rate by `stress_mutation_multiplier`
  (default 3×).
- Temporarily overwrite the global mutation rate so meiosis below picks
  it up.

**Biology.** **Mutation rate evolution** plus **stress-induced
hypermutation**. Two distinct ideas:

1.  **Heritable mutation rate.** The mutation rate itself can be a
    selected trait (Sniegowski et al. 1997). Some lineages evolve higher
    mutation rates (“mutator alleles”) that produce more variants per
    generation.
2.  **Stress hypermutation.** Bacteria activate the SOS response under
    genotoxic stress (Rosenberg 2001). The model abstracts this: parent
    below energy threshold → 3× mutation rate for this clutch.

Combining the two gives a richer model — agents can evolve both their
baseline mutation rate AND their stress-response sensitivity.

**Audit findings.** s-stress-hypermutation ✅: hypermutation raises
diversity by +0.003 under scarcity. Direction correct, magnitude small
(consistent with bet-hedging being a slow-response strategy).

------------------------------------------------------------------------

### 6. Lamarckian write-back

``` julia
do_lamarck && lamarck_genome_update!(ag)
```

(after `do_lamarck = ... && get(specs, "rl_mode", "none") != "none"` was
computed at function start)

**What this says.** If Lamarckian inheritance is active (and an RL mode
is on, since Lamarckianism only makes sense with within-lifetime
learning), write the agent’s *learned* phenotype back to its genome just
before meiosis. This way the offspring inherits the learned traits, not
just the prior.

**Biology.** **Lamarckian inheritance** — the classical (and largely
discredited in biological evolution) idea that acquired characteristics
can be inherited. clade implements it as an opt-in mode for two reasons:

1.  Some real biological mechanisms approximate it (epigenetic
    inheritance, transgenerational learning).
2.  Comparing Darwinian (no Lamarck) vs Lamarckian runs is
    scientifically interesting — it bounds the importance of
    genetic-vs-learned contributions.

The flag is off by default. When on, the within-lifetime RL updates to
the brain weights get propagated to the genome before meiosis,
effectively making the offspring “born knowing what its parent learned.”

**Audit findings.** Not currently in the audit. The Baldwin Effect audit
(s-baldwin) tests the *opposite* — whether learning gets canalised
genetically without explicit Lamarckian write-back. Currently 🔴 due to
BNN-sigma coupling; Tier 5 backlog.

------------------------------------------------------------------------

### 7. Meiosis — the genome operation

``` julia
off_genome = make_offspring_genome(
    ag.genome,
    mate !== nothing ? mate.genome : nothing,
    specs, env.rng
)
specs["mutation_sd"] = global_mut_sd   # restore after meiosis

off_brain = make_brain(off_genome, specs)
off = _make_offspring(env.next_id, off_genome, off_brain,
                       ag, mate, off_energy_actual, specs, env.rng)
env.next_id += Int64(1)
```

**What this says.** Call `make_offspring_genome` (defined in
`genome.jl`) to produce a new genome from the parent (and mate, if
sexual). Restore the mutation rate to its global default. Construct the
offspring’s brain from the new genome. Build the full Agent struct.
Increment the global ID counter.

**Biology.** This is the **inheritance step** — where the offspring gets
its biological identity from its parents. The detailed mechanics
(crossover, mutation, dominance, ploidy) live in `genome.jl` ([genome.jl
chapter](https://itchyshin.github.io/clade/articles/k-genome.md) — to be
written). Briefly:

- For haploid (`ploidy = 1`): direct copy + mutation from the parent.
  Mate is ignored.
- For diploid (`ploidy = 2`): meiosis with independent assortment and
  recombination, then mutation. Both parents contribute one haploid
  gamete each, which are fused.

The brain is a *phenotypic expression* of the genome — different brain
types (`bnn`, `ann`, `ctrnn`, etc.) decode the genome’s weight vector
differently.

**Audit findings.** s-pop-genetics ✅ very strong heritability proxy
(lag-1 ac = 0.992) — the meiosis + mutation pipeline produces realistic
parent-offspring resemblance.

------------------------------------------------------------------------

### 8. Bookkeeping and brood / population assignment

``` julia
ag.num_offspring += Int32(1)
ag.reproduced     = true
env.n_births     += Int32(1)

if care
    push!(ag.carried_offspring, off)
    ag.care_load += Int32(1)
else
    push!(new_agents, off)
end
```

**What this says.** Update the parent’s offspring counter and set its
`reproduced` flag (consumed later by semelparous death). Increment the
global births counter. Then either:

- If parental care is on: add the offspring to the parent’s brood list
  (and don’t put it in the main population yet).
- Otherwise: add the offspring to the new-agents list (will be added to
  the main population at the end of the function).

**Biology.** **Parental care** is the dichotomy here. In care-on species
(most mammals, many birds), the offspring is carried/fed by the parent
for a period before it can survive independently. In care-off species
(most fish, insects), the offspring is on its own from birth.

The `reproduced` flag is the bridge to semelparity — once set, the
parent dies on the next tick if `life_history = "semelparous"`. For
iteroparous agents (the default), the flag is cleared at the start of
the next tick.

**Audit findings.** s-parental-care ✅ confirmed the brood + graduation
pathway works. s-life-history ✅ confirmed semelparous death triggers
correctly via `reproduced`.

------------------------------------------------------------------------

### 9. Adding new agents to the population

``` julia
for off in new_agents
    push!(env.agents, off)
    env.agent_map[off.x, off.y] = length(env.agents)
end
```

**What this says.** All offspring not in parental care get added to the
main population, and the agent map gets updated.

**Biology.** **Recruitment** — the moment new individuals become
“counted” as part of the breeding population. In care-off species this
is at birth; in care-on species this happens at graduation (handled in
`parental_care.jl`).

------------------------------------------------------------------------

### X. Mate finding — a kernel-level issue worth knowing about

``` julia
function _find_mate(ag::Agent, env::Environment)::Union{Agent, Nothing}
    specs = env.specs
    if specs["ploidy"] == 1
        return nothing     # haploid: asexual by genome
    end
    radius = Int(get(specs, "mate_search_radius", 1))
    radius = max(radius, 1)
    # ... collect live neighbours within Moore radius ...
    if Int(get(specs, "signal_dims", 0)) == 0
        return candidates[rand(env.rng, 1:length(candidates))]
    end
    # signal_dims > 0: pick best signal-preference match (Zahavi 1975)
    # ...
end
```

**What this says.** Look for a mate for agent `ag`. If haploid, return
nothing (no mate needed). Otherwise search a Moore neighbourhood of
configurable radius (default 1 = 3×3) for a live other agent. When
`signal_dims == 0` (the default for scenarios that don’t evolve signal
traits), pick a random eligible neighbour — sexual reproduction without
mate choice. When `signal_dims > 0`, prefer the candidate whose `signal`
best matches `ag.preference` (Zahavi-style honest-signal mate choice).

**Biology.** Real organisms search a finite area for mates, and for most
species mate choice is either absent (random pairing among neighbours)
or signal-based (e.g. preference for a trait like plumage). clade models
both with a single neighbour-search loop.

**Historical note — the 0.5.10 kernel fix.** Pre-0.5.10 this function
had a **short-circuit on `signal_dims == 0`** that made it return
`nothing` immediately without searching. Because `signal_dims = 0` is
the default for every non-signal-evolving scenario, every
supposedly-diploid run was actually doing asexual reproduction:
`_find_mate` returned `nothing`, `make_offspring_genome` set
`pat_w = Float32[]`, and the offspring was effectively haploid. The
“diploid” ploidy flag was a no-op unless you turned on signal evolution.

The 0.5.10 fix removes the short-circuit. When `ploidy == 2` and
`signal_dims == 0`, `_find_mate` now picks a random live neighbour —
which is the correct default semantics for a diploid that doesn’t evolve
signal-based mate choice.

**Audit consequences.** Every `ploidy = 2` scenario whose claims depend
on real diploid dynamics (heritability, heterozygosity, pedigree-based
kin, speciation through mate choice, sex vs asex) was running on
structurally-haploid mechanics before 0.5.10. The 0.5.11 re-audit of the
12 most diploid-sensitive ✅ scenarios found that 11 still hold under
the fixed kernel — the demographic predictions (Cope, Trivers, Lack,
life-history, pace-of-life, etc.) are robust to the ploidy flip. One
demotion: `s-stress-hypermutation` becomes 🟠 because under real diploid
sex, baseline mutation input already equals what hypermutation adds (Δ
diversity = +0.000).

**Variants worth considering.**

- **Broader radius.** `mate_search_radius = 2` (5×5) or `3` (7×7)
  reduces Allee-failure rate on sparse grids. Cost: more outcrossing
  dilutes local adaptation.
- **Self-fertilization fallback.** When no mate is found and you still
  want to preserve diploidy (rather than silently degrading to haploid
  offspring), set `self_fertilization_fallback = TRUE`. The second
  gamete is drawn from parent1 (self-fertilization), which keeps `pat_w`
  non-empty but inbreeds the population.
- **Outcrossed fallback** (not yet implemented). Would pick a random
  agent from anywhere on the grid when the local search fails — avoids
  both Allee-failure-haploid conversion and the selfing-inbreeding cost.

------------------------------------------------------------------------

### What this file *doesn’t* do

- **Genome operations** (crossover, mutation, dominance). Defined in
  `genome.jl`.
- **Brain construction.** Defined in `brains/` files.
- **Death.** Even semelparous death (which is triggered by the
  `reproduced` flag set here) actually fires from `death.jl`.
- **Care logic** (graduation timing, feeding). Defined in
  `modules/parental_care.jl`.

------------------------------------------------------------------------

### Reading guide for biologists who want to spot bugs

1.  **Are the eligibility checks complete?** Yes — alive, age, energy,
    not-already-reproduced, optional Allee. All present, all defensible
    biology.
2.  **Is the cost realistic?** With `repro_cost_mode = "proportional"`
    (default 0.4.0): yes, parents pay a fraction of their condition.
    With `"fixed"` (legacy): no, but preserved for backward
    compatibility.
3.  **Does the offspring inherit anything observable?** Yes — through
    `make_offspring_genome` (genome) and the cost-coupled birth energy.
    Parental condition affects offspring starting condition.
4.  **Are mate-selection and brain-construction abstracted away?** Yes —
    they live in their own files. This file is purely the reproduction
    *event* logic.

------------------------------------------------------------------------

### Citations referenced in this document

- Allee, W.C. (1931) *Animal Aggregations: A Study in General
  Sociology.* University of Chicago Press.
- Lack, D. (1947) The significance of clutch-size. *Ibis* 89:302-352.
- Rosenberg, S.M. (2001) Evolving responsively: adaptive mutation. *Nat.
  Rev. Genet.* 2:504-515.
- Smith, C.C. & Fretwell, S.D. (1974) The optimal balance between size
  and number of offspring. *Am. Nat.* 108:499-506.
- Sniegowski, P.D., Gerrish, P.J., Lenski, R.E. (1997) Evolution of high
  mutation rates in experimental populations of E. coli. *Nature*
  387:703-705.

------------------------------------------------------------------------

------------------------------------------------------------------------

### Companion chapters

- [Kernel as biology —
  overview](https://itchyshin.github.io/clade/articles/k-README.md)
- [tick.jl — one tick in the life of an
  agent](https://itchyshin.github.io/clade/articles/k-tick.md)
- [Clade.jl — the main loop, in biological
  order](https://itchyshin.github.io/clade/articles/k-clade-main.md)
- [sense.jl — what an agent
  perceives](https://itchyshin.github.io/clade/articles/k-sense.md)
- [reproduce.jl — birth, inheritance, parental
  cost](https://itchyshin.github.io/clade/articles/k-reproduce.md)
- [death.jl — when agents die and
  why](https://itchyshin.github.io/clade/articles/k-death.md)
- [genome.jl — meiosis, traits,
  inheritance](https://itchyshin.github.io/clade/articles/k-genome.md)
