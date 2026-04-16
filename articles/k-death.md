# death.jl — when agents die and why

## `death.jl` — when agents die and why

The shortest of the core kernel files (113 lines), and biologically the
most consequential. Mortality drives the demographic engine of the
simulation — selection works through differential survival, so the rules
in `death.jl` shape every evolutionary outcome.

There are exactly four causes of death in clade. Each maps to a distinct
biological process.

Source file:
[`inst/julia/src/death.jl`](https://github.com/itchyshin/clade/blob/main/inst/julia/src/death.jl).

------------------------------------------------------------------------

### 1. The four causes

``` julia
function kill_dead!(env::Environment)
    specs     = env.specs
    starv_th  = Float32(get(specs, "starvation_threshold", 0.0))
    max_age   = Int(get(specs, "max_age", 200))
    senes_r   = Float32(get(specs, "senescence_rate", 0.0))
    semel     = get(specs, "life_history", "iteroparous") == "semelparous"
    scav_on   = Bool(get(specs, "scavenging", false))
```

**What this says.** Read the four mortality parameters once at the top:

- `starvation_threshold` — die when energy falls below this value
  (default 0).
- `max_age` — die when age reaches this value (default 200).
- `senescence_rate` — Gompertz mortality coefficient (default 0, meaning
  off).
- `life_history` — `"iteroparous"` (default) or `"semelparous"`. The
  latter triggers post-reproduction death.
- `scavenging` — whether to deposit carrion when an agent dies.

**Biology.** This is **demographic accounting**. Every population
biology model has to decide who dies and why. clade exposes four
orthogonal mortality processes that the user can combine:

- Starvation = ecological mortality (resource limitation).
- Age cap = hard maximum lifespan (a simplification — real animals don’t
  have a fixed cap, just a vanishing survival probability).
- Senescence = Gompertz mortality (Gompertz 1825) — exponentially rising
  death probability with age, the standard demographic model for
  vertebrate aging.
- Semelparous = post-reproductive death (salmon, annual plants, some
  insects).

By default only starvation and age cap are active. Senescence and
semelparous are opt-in.

**Audit findings.** s-pace-of-life ✗ flagged that the always-on
`max_age = 200` cap masks pace-of-life dynamics — every agent dies at
the cap before metabolic-rate-driven differences accumulate. Tier 2 fix
planned: scale `max_age` with `metabolic_rate` so fast-pace species have
shorter lifespans (Réale 2010).

------------------------------------------------------------------------

### 2. The death decision — per agent

``` julia
for ag in env.agents
    ag.alive || continue
    cause = _death_cause(ag, starv_th, max_age, senes_r, semel, env.rng)
    if cause != :alive
        ag.alive = false
        env.n_deaths += Int32(1)
        cause == :starvation && (env.n_starvations += Int32(1))
        cause == :age        && (env.n_age_deaths  += Int32(1))
        _log_death!(env, ag, cause)
        scav_on && deposit_carrion!(env, ag)
    end
end
```

**What this says.** For each living agent: ask `_death_cause` whether
this agent dies this tick (and from what cause). If yes:

- Mark the agent dead.
- Update global death and cause-specific counters.
- Log the death record (id, age, energy, cause, body size, lifetime
  offspring).
- If scavenging is on, leave a carrion deposit at the agent’s cell.

**Biology.** The death decision is per-tick, per-agent, deterministic
given the agent’s state and the parameters (the only randomness is in
Gompertz senescence). The death record retained in `env.deaths` serves
analyses like life-table reconstruction and fitness analysis.

The carrion deposit is the natural consequence of death in scavenging
ecosystems — corpses are resources for other agents (DeVault 2003).
Without scavenging, the carcass is “lost to the system” — a biological
simplification (in real ecosystems decomposers always recycle the
energy).

**Audit findings.** s-scavenging ✅: carrion deposition + decay sustains
population +5 agents under scarcity. Mechanism wired and biologically
correct.

------------------------------------------------------------------------

### 3. The cause function — applied in priority order

``` julia
function _death_cause(ag::Agent, starv_th::Float32, max_age::Int,
                       senes_r::Float32, semel::Bool, rng)::Symbol
    # 1. Starvation
    ag.energy < starv_th && return :starvation

    # 2. Age cap
    ag.age >= max_age && return :age

    # 3. Gompertz senescence
    if senes_r > 0.0f0
        # Scaled by heritable aging_rate: faster-aging genotypes die sooner
        eff_r = senes_r * ag.aging_rate
        p_die = Float32(1.0 - exp(-Float64(eff_r) * exp(Float64(eff_r) * Float64(ag.age))))
        rand(rng) < p_die && return :senescence
    end

    # 4. Semelparous
    semel && ag.reproduced && return :semelparous

    :alive
end
```

**What this says.** Check death causes in priority order. Return the
first one that fires:

1.  **Starvation** — if energy below the threshold.
2.  **Age cap** — if age has reached the maximum.
3.  **Gompertz senescence** — if random draw is below the age-dependent
    death probability.
4.  **Semelparous** — if the agent has reproduced this tick AND the life
    history is set to semelparous.

If none fires, return `:alive`.

**Biology.** The four causes encode four distinct biological processes:

#### 3.1 Starvation

``` julia
ag.energy < starv_th && return :starvation
```

Energy below threshold = death. The threshold defaults to 0 (run out of
energy = die), but can be raised to model “subclinical starvation
mortality” — agents that fall below a critical condition die even before
energy hits zero.

**Biology.** This is **ecological mortality** — the most common cause of
death in nature (predation aside). It’s selection’s main weapon: agents
that forage poorly run out of energy and die, removing their genes from
the pool.

#### 3.2 Age cap

``` julia
ag.age >= max_age && return :age
```

Hard ceiling — at age `max_age`, certain death.

**Biology.** Real animals don’t have a hard age cap; they have
exponentially decreasing survival with age. The hard cap is a
simplification used in many ABMs to bound memory and prevent “immortal
genotype” artefacts. Default 200 ticks.

**Audit findings.** s-pace-of-life flagged this as the *cause* of
metabolic-rate-not-mattering. Every agent dies at age 200 regardless of
metabolic rate, so pace-of-life evolution can’t express. **Tier 2 fix:**
make `max_age` scale with `metabolic_rate` (so
`max_age_effective = base / metabolic_rate`), letting fast-pace agents
have shorter lifespans as Réale 2010 predicts.

#### 3.3 Gompertz senescence

``` julia
if senes_r > 0.0f0
    eff_r = senes_r * ag.aging_rate
    p_die = Float32(1.0 - exp(-Float64(eff_r) * exp(Float64(eff_r) * Float64(ag.age))))
    rand(rng) < p_die && return :senescence
end
```

The Gompertz mortality law: per-tick death probability rises
exponentially with age. The formula is:

    p_die(age) = 1 - exp(-r * exp(r * age))

where *r* is `senescence_rate × aging_rate` and `aging_rate` is the
agent’s heritable trait.

**Biology.** This is the **standard demographic model for vertebrate
aging** (Gompertz 1825 — yes, that old). The exponential shape captures
the empirical observation that mortality rises 8-10% per year in adult
humans. Senescence is *evolved* — natural selection’s force weakens with
age (Hamilton 1966, *J. Theor. Biol.* 12:12-45), so deleterious
late-life mutations accumulate. clade lets `senescence_rate` be a
population-level constant and `aging_rate` be a per-agent heritable
trait — together they implement evolved senescence.

**Audit findings.** Senescence is off by default
(`senescence_rate = 0`). When the user enables it the formula works
correctly. Not the bottleneck for s-pace-of-life — that’s the always-on
`max_age` cap, even when senescence is off.

#### 3.4 Semelparous

``` julia
semel && ag.reproduced && return :semelparous
```

If the life history is “semelparous” AND this agent reproduced this
tick, it dies.

**Biology.** **Semelparity** — single big-bang reproduction followed by
death. Salmon, annual plants, octopus, some bamboo species.
Implementation is just a flag: did this agent reproduce this tick? If
yes and life history is semelparous, die.

**Audit findings.** s-life-history ✅: semelparous and iteroparous
strategies produce distinct demographic signatures. Mechanism is wired
correctly through the `reproduced` flag set in `reproduce.jl`.

------------------------------------------------------------------------

### 4. Removal — physical cleanup

``` julia
function remove_dead!(env::Environment)
    filter!(ag -> ag.alive, env.agents)
    fill!(env.agent_map, Int64(0))
    for (idx, ag) in enumerate(env.agents)
        env.agent_map[ag.x, ag.y] = idx
    end
end
```

**What this says.** Walk through `env.agents`, keeping only the live
ones. Then rebuild the spatial agent map.

**Biology.** Pure bookkeeping — the death event happened in
`kill_dead!`; this is just garbage collection. The map rebuild is
necessary because agent indices change when dead agents are removed.

The split between `kill_dead!` (mark) and `remove_dead!` (sweep) is
deliberate: between the two calls, downstream code can still look up
just-dead agents by index. Most modules don’t need this, but some
logging and statistics functions do.

------------------------------------------------------------------------

### 5. Death logging — for life-table analysis

``` julia
function _log_death!(env::Environment, ag::Agent, cause::Symbol)
    push!(env.deaths["id"],        Int(ag.id))
    push!(env.deaths["t"],         Int(env.t))
    push!(env.deaths["age"],       Int(ag.age))
    push!(env.deaths["energy"],    Float64(ag.energy))
    push!(env.deaths["cause"],     string(cause))
    push!(env.deaths["body_size"], Float64(ag.body_size))
    push!(env.deaths["num_offspring"], Int(ag.num_offspring))
end
```

**What this says.** When an agent dies, record seven fields: id, tick,
age at death, energy at death, cause, body size, and lifetime offspring
count.

**Biology.** This is the **life-table data** that supports demographic
analyses downstream:

- **Survival curves** — distribution of age-at-death by cause.
- **Lifetime reproductive success** — `num_offspring` per individual.
- **Selection differential** — comparing trait values (body_size) at
  death across causes (do larger agents die more from predation? more
  from starvation?).
- **Cause-specific mortality** — what fraction of deaths are starvation
  vs senescence?

The death log is a fundamental piece of biological data that real
ecologists spend years collecting in field studies.

------------------------------------------------------------------------

### What this file *doesn’t* do

- **Predation kills.** Predators kill prey directly in
  `tick_predators.jl` by setting `prey.alive = false` and depositing
  carrion. The `kill_dead!` function then sees the already-dead prey and
  just tallies them.
- **Disease deaths.** `apply_disease!` (in `modules/disease.jl`) handles
  per-tick disease mortality. It can set `alive = false` directly.
- **Module-driven deaths.** Niche construction, kin altruism, etc. don’t
  kill directly — they affect energy, which then triggers starvation
  through the normal pathway.

The clean separation matters: starvation, age, and senescence are the
“intrinsic” mortality processes; predation and disease are “extrinsic”
and live in their own modules. Keeping them separate makes their effects
testable independently.

------------------------------------------------------------------------

### Reading guide for biologists who want to spot bugs

1.  **Are the four causes mutually exclusive?** Yes — the function
    returns at the first matching cause, so each death has exactly one
    cause.
2.  **Is the priority order biologically defensible?** Mostly:
    starvation first makes sense (an agent with no energy can’t even
    reach old age). Age cap before Gompertz means the cap dominates when
    both are active. Semelparous last makes sense — it’s an “additional”
    trigger, not a replacement.
3.  **Are the senescence parameters well-scaled?** Default
    `senescence_rate = 0` (off). When enabled, even small values like
    0.01 cause significant late-life mortality. Worth running with
    traces.
4.  **What about juvenile mortality?** Currently no separate juvenile
    mortality — agents just have age 0 at birth and start the same risk
    profile as adults. Real species often have very high juvenile
    mortality (90%+). Adding a `juvenile_mortality_rate` parameter would
    be a natural extension.

------------------------------------------------------------------------

### Citations referenced in this document

- DeVault, T.L. et al. (2003) Scavenging by vertebrates. *Oikos*
  102:225-234.
- Gompertz, B. (1825) On the nature of the function expressive of the
  law of human mortality. *Phil. Trans. R. Soc.* 115:513-583.
- Hamilton, W.D. (1966) The moulding of senescence by natural selection.
  *J. Theor. Biol.* 12:12-45.
- Réale, D. et al. (2010) Personality and the emergence of the
  pace-of-life syndrome concept. *Phil. Trans. R. Soc. B* 365:4051-
  4063. 
- Stearns, S.C. (1992) *The Evolution of Life Histories.* Oxford UP.

------------------------------------------------------------------------

------------------------------------------------------------------------

### Companion chapters

- [Kernel as biology — overview](k-README.md)
- [tick.jl — one tick in the life of an agent](k-tick.md)
- [Clade.jl — the main loop, in biological order](k-clade-main.md)
- [sense.jl — what an agent perceives](k-sense.md)
- [reproduce.jl — birth, inheritance, parental cost](k-reproduce.md)
- [death.jl — when agents die and why](k-death.md)
- [genome.jl — meiosis, traits, inheritance](k-genome.md)
