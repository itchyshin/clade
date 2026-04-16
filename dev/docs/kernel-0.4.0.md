# clade 0.4.0 kernel changes — biology rationale

This document records each kernel rule change made between 0.3.x and 0.4.0,
with the biological reasoning, the citation it implements, and the
audit-driven justification for making it now.

The fidelity audit (35 scenarios, see `dev/audit/fidelity/STATUS.md`)
identified ten kernel rules that smoothed-over biology in ways that
either contradicted theoretical predictions (s-baldwin 🔴) or made them
unreproducible at any parameter setting (10 🟠 scenarios). 0.4.0 fixes
the most defensible rules — those for which there is broad consensus that
the biology is well-established and the simplification was a port-time
shortcut rather than a research choice.

The guiding principle: **prefer biologically-realistic rules even when
they make the model harder to tune**. If a quantity matters in real
ecology (handling time, parental investment scales with parent
condition), it should matter in the simulation. Otherwise we are testing
a different theory.

---

## Tier 1 (this PR): energy-budget realism

These three changes touch how agents extract energy from the environment
and pay for offspring. They are independent fixes but are bundled because
they all change the energy economy and have to be re-tuned together.

### Change #5 — handling time (`max_bite`)

**Files changed:** `inst/julia/src/tick.jl`, `R/config.R`.

**The rule before 0.4.0:**

```
if grass[x, y] > 0:
    energy += eat_gain * grass[x, y]   # take all of it
    grass[x, y] = 0                    # cell stripped
```

**The rule from 0.4.0:**

```
if grass[x, y] > 0:
    bite     = min(grass[x, y], max_bite)
    energy  += eat_gain * bite          # bounded intake
    grass[x, y] -= bite                  # cell partially depleted
```

with `max_bite = 2.0` by default (out of `grass_max = 5.0`).

**Why this is more biological.**

Real grazers have *handling time*: a sheep does not eat a square metre
of grass in one step. The maximum per-tick intake is bounded by jaw size,
gut capacity, processing rate. Both ancestor implementations enforced
this:

- **MATLAB ancestor (Bulitko 2023, `takeAction.m:138-148`):**
  `eaten = min(grass(y,x), maxbite); energy = min(1, energy + eaten)`.
- **alifeR (Bulitko et al., `R/take_action.R:167-174` and
  `src/tick_agents.cpp:276-280`):** same `min(grass, max_bite)` pattern,
  `max_bite = 10` by default with `grass_max = 100` (also a 1:10 ratio).

clade's strip-the-cell semantics was an undocumented port-time
simplification.

**Biological consequences this restores:**

1. **Local resource depletion by groups, not individuals.** A rich cell
   can sustain multiple grazing visits or multiple simultaneous grazers
   over several ticks. Without `max_bite`, the first arrival always wins
   the entire cell, suppressing density-dependent foraging dynamics.
2. **Bounded per-tick energy income.** Previously a single rich-cell
   visit could yield 25 energy in one tick (~12.5% of `energy_max`),
   producing reproductive windfalls that distorted selection
   differentials in audits like clutch-size and parental-investment.
   With `max_bite = 2.0`, max gain per tick is 10 energy (~5% of cap),
   bringing the gain:cost ratio from ~25:1 to ~5:1 — much closer to
   vertebrate energetics (Nagy 1987, *Ecol. Monogr.* 57:111-128).
3. **Foraging strategy matters more.** When meals are bounded, agents
   that revisit productive areas across ticks gain over those that
   blunder onto a single rich cell. The neural network has to *learn
   to graze*, not just to find one rich cell.

**Default rationale.** `max_bite = 2.0` chosen to give:

- Per-tick max intake = `eat_gain * max_bite` = 5 × 2 = 10 energy,
  approximately 5% of `energy_max = 200`. Real vertebrate grazers ingest
  roughly 2-5% of body mass in dry matter per day; cap is in the upper
  end of that range, generous enough to keep populations viable while
  still requiring multiple meals to fill from empty.
- Cell with full grass (5 units) takes 3 ticks of dedicated feeding to
  clear (taking 2, 2, 1) — a meaningful handling time.
- A single agent staying on a rich cell will eat at the bite cap every
  tick, but the cell now constrains the maximum reward rate of "sit on
  a rich cell forever".

**Audits affected (re-run after this change):**

All baseline-derived audits, especially:

- s-baseline (carrying capacity will shift down — meals are smaller, so
  equilibrium population is lower at the same `grass_rate`).
- s-clutch-size (the bell-shaped r/K signal should sharpen because the
  per-tick energy windfall is gone).
- s-life-history (semelparous vs iteroparous birth rates will change).
- s-cooperation, s-kin (any scenario relying on energy as the selection
  currency).

### Change #7 — proportional parental cost

**Files changed:** `inst/julia/src/reproduce.jl`, `R/config.R`.

**The rule before 0.4.0:**

```
parent.energy -= repro_cost   # fixed 30, regardless of parent condition
mate.energy   -= 0.5 * repro_cost   # fixed 15
offspring.energy = offspring_energy   # fixed 60, regardless of parent
```

**The rule from 0.4.0 (default `repro_cost_mode = "proportional"`):**

```
cost_paid          = repro_cost_fraction * parent.energy   # 0.5 * energy
parent.energy     -= cost_paid
mate.energy       -= 0.5 * cost_paid
offspring.energy   = offspring_energy_fraction * cost_paid # 0.25 * cost_paid
```

The legacy fixed-cost behaviour is preserved by setting
`repro_cost_mode = "fixed"`.

**Why this is more biological.**

Smith & Fretwell (1974, *Am. Nat.* 108:499-506) is the foundational paper
on parental investment. They argue:

1. Parents in better condition allocate *more* per offspring (or more
   total) — fitness per offspring rises sub-linearly with provisioning,
   so the optimal allocation depends on what the parent has available.
2. Offspring birth condition reflects parental allocation: well-provisioned
   offspring survive and recruit better.

A fixed cost of 30 energy regardless of whether the parent has 50 energy
or 200 violates both. A fixed offspring birth energy regardless of
parental condition violates the second.

Stearns (1992, *The Evolution of Life Histories*) makes the same point in
generic life-history terms: reproductive effort is a *fraction* of
soma, not a constant. The MATLAB ancestor charged
`minReproductionEnergy` (which acted as a soft proportional via its
gating on parent energy); alifeR charged `parent.energy * 0.5 / clutch`
(explicitly proportional). clade's fixed `repro_cost = 30` was an
undocumented simplification.

**Biological consequences this restores:**

1. **Parental investment trade-off becomes measurable.** s-parental-
   investment 🟠 produced a flat dynamic across `female_investment ∈
   {0.3, 0.5, 0.7, 0.9}` because the ratio didn't couple to outcomes.
   With proportional allocation, female_investment now scales offspring
   birth energy via `cost_paid`.
2. **Quality-quantity trade-off becomes visible.** Smith-Fretwell's
   classic prediction: many low-quality offspring vs few high-quality
   ones. Previously every offspring was identical (energy = 60). Now
   parents in low condition produce poorly-provisioned young who
   themselves die earlier, creating real selection on `clutch_size`.
3. **Reproductive senescence emerges naturally.** Old parents with
   accumulated metabolic wear (low energy) automatically produce smaller
   broods and weaker young. Previously these costs all hit the *next*
   reproduction event uniformly.

**Default rationale.**

- `repro_cost_fraction = 0.5`: parent gives up half its current energy
  per offspring. Across vertebrates this is on the high end (typical
  reproductive effort is 10-50% of body mass for one breeding event),
  but at a per-clutch level it's defensible — clutch size of 1 with 50%
  cost is a single high-investment offspring.
- `offspring_energy_fraction = 0.25`: newborn gets a quarter of the
  cost the parent paid. The other 75% is "lost to development" (the
  egg-shell, the nursing inefficiency, the placental drain, etc.). Real
  conversion efficiency from maternal investment to neonate biomass is
  often quoted in the 20-40% range.

**Backward compatibility.** Any spec list that explicitly sets
`repro_cost_mode = "fixed"` gets the old behaviour. Plain
`repro_cost = 30` without a mode now means "ignored, mode is
proportional" — this is a documented breaking change (vignettes
updated).

**Audits affected:**

- s-parental-investment 🟠 → expected to promote to ✅.
- s-clutch-size — bell shape may sharpen (or shift) because per-offspring
  cost now varies with parent condition.
- s-life-history (Cole/Williams) — semelparous-vs-iteroparous birth
  rates will change; sign predictions should still hold.
- s-cooperation, s-kin — any energy-driven population dynamics.
- s-baseline — equilibrium population may shift.

### Change #6 — grass:energy ratio (folded into #5)

The original audit flagged this as separate but on re-reading the code:
the diagnostic "1:40 ratio" was overstated. The real per-tick gain :
metabolic-cost ratio is currently 25:1 (one full cell, 25 energy, vs
1 energy/tick movement). Adding `max_bite = 2.0` (Change #5)
automatically brings this to 10:1 — within striking distance of
realistic vertebrate energetics. **No additional rescale of
`energy_max` or `grass_max` is needed.**

If after re-running the audits we still see equilibrium populations
that are too "fat" (mean_energy > 80% of cap routinely) we will add a
second rescale step.

---

## Validation protocol

After Tier 1 lands:

1. Re-run the following audits — they touch the energy economy directly:
   - `Rscript dev/audit/fidelity/baseline_xref.R`
   - `Rscript dev/audit/fidelity/life_history.R`
   - `Rscript dev/audit/fidelity/clutch_size.R`
   - `Rscript dev/audit/fidelity/cooperation.R`
   - `Rscript dev/audit/fidelity/kin.R`
   - `Rscript dev/audit/fidelity/parental_investment.R`
2. For each, compare new numbers to the archived `*_results.rds` from
   pre-0.4.0 runs.
3. Update the corresponding fidelity report:
   - Tag results with `(0.4.0)` and add comparison to pre-0.4.0 numbers.
   - Update the verdict if it changes.
   - Update the vignette's "What we found" paragraph.
4. The qualitative passes (Hamilton ρ=0.97, Nowak-May ρ=1.00, Cope
   direction +0.13) should be robust. The quantitative ones (carrying
   capacity, mean energy) will move and need to be re-stated.

---

## Tier 2-5 (subsequent PRs)

Documented in audit reports and STATUS.md but not yet implemented:

- **Tier 2** — `max_age` scales with `metabolic_rate` (s-pace-of-life).
- **Tier 3** — `female_investment` couples to graduation energy
  (s-parental-investment final cleanup).
- **Tier 4** — vector-signal predator memory (s-mimicry).
- **Tier 5** — BNN sigma decoupling + sampling cadence (s-baldwin,
  s-social-learning, s-rl).
- **Tooling** — `search_map_elites` defaults (s-map-elites).

Each tier will get its own changelog section here.

---

## Tier 5C (0.4.1): log-scaled plasticity cost

**Motivation.** Tier 5A (`bnn_sigma_source = "trait"`) decouples BNN
posterior width from heterozygosity so sigma can be an evolvable
trait. But sigma still carries no energetic cost, so selection has
no gradient to canalise. The pre-0.4.1 Baldwin audit (🔴
*contradicts*) confirmed this: sigma rose to the cap in both stable
and seasonal environments.

**Change.** Add `brain_energy_sigma_scale` (default 0.0) to the
energy-cost mode. When `brain_energy_sigma_scale > 0` and the brain
is a `BNNBrain`, the per-tick metabolic cost gains a log-scaled
information term:

```
cost_sigma = scale × mean(max(log(sigma / sigma_min), 0))
```

This is the **log-information cost** formulation (Aiello & Wheeler
1995 expensive-tissue direction applied to weight posteriors):

- Near `sigma_min = 0.01` the cost is ~0 (canalised weights are
  cheap).
- Cost grows as `log(sigma)`, so broad priors are penalised but not
  catastrophically — one-order-of-magnitude wider sigma is one unit
  of cost, not exponentially more.
- Backward-compatible: `brain_energy_sigma_scale = 0.0` gives
  unchanged kernel behaviour.

**Interaction notes.**

- Does not double-count with `brain_energy_mode = "activity"` —
  measures structural not activity cost.
- Fires per tick, not per BNN sample — independent of
  `bnn_sample_freq`.
- Only meaningful under `bnn_sigma_source = "trait"` (or `"fixed"`),
  where sigma can evolve; under legacy `"heterozygosity"` mode sigma
  still varies with mutation but now has a cost term associated
  with that variation.

**Audit impact.** Three pre-0.4.1 flagged scenarios move on the
verdict ladder once Tier 5C + Tier 5A are paired:

- **s-baldwin** 🔴 → 🟠: at `brain_energy_sigma_scale = 0.05`,
  stable env canalises (Δ = −0.004) while seasonal preserves
  (Δ = +0.003). Direction reversal confirmed across 3 seeds.
- **s-plasticity** 🟠 (flat) → 🟠 (directional): seasonal
  maintains ~0.003 above stable, a direction correction over the
  pre-0.4.1 flat null.
- **s-rl** 🟠 → ✅: unrelated fix via Tier 5B (`bnn_sample_freq`),
  but verified in the same 0.4.1 release — at freq=5 the Williams
  1992 benefit emerges (Δn = +5.2).

**Tooling fix.** `search_map_elites()` default `mutation_params`
changed from "all positive doubles" to a curated list of
behavioural drivers (`grass_rate`, `mutation_sd`, `move_cost`,
`idle_cost`, `metabolic_rate_init_mean`, `max_bite`). Fallback to
the legacy filter if none match. Added a low-coverage warning when
filled cells < 10% after 50+ iterations.

**Files touched.**

- `inst/julia/src/tick.jl` — `_brain_energy_cost` signature and
  body.
- `R/config.R` — `brain_energy_sigma_scale = 0.0` default.
- `R/search.R` — mutation-param default + warning.
- `vignettes/custom-modules.Rmd` — restructured around 4 hook
  points.
- `dev/audit/fidelity/{plasticity,rl,baldwin,brain_size,dispersal_ifd,mating_systems,group_defense,body_size}.{R,md}`
  — rerun under 0.4.1 and updated verdicts.

**Out of scope for 0.4.1.**

- Coevolving-parasite module (s-mating-systems Red Queen).
- Neonatal mortality cost for unprovisioned offspring
  (s-brain-size magnitude).
- Shine-style large-escape body-size mechanism (s-body-size
  reframed to detectability variant instead).

---

## References

- Smith, C.C. & Fretwell, S.D. (1974) The optimal balance between size and
  number of offspring. *Am. Nat.* 108:499-506.
- Stearns, S.C. (1992) *The Evolution of Life Histories.* Oxford UP.
- Nagy, K.A. (1987) Field metabolic rate and food requirement scaling
  in mammals and birds. *Ecological Monographs* 57:111-128.
- Bulitko, V. (Aug 2023) MATLAB alife codebase, `~/Documents/alifeR/alife_matlab/codebase/`.
- alifeR R port — `~/Documents/alifeR/`, `R/take_action.R`,
  `R/reproduction.R`.
- clade fidelity audit — `dev/audit/fidelity/STATUS.md` (35 scenarios).
