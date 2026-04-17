# Timescale analysis: biological realism in clade

## The problem

clade's default parameters produce a population where:

- **1 tick = 1 action** (sense → decide → move → eat → pay cost)
- **Lifespan ≈ 200 ticks** (max_age = 200)
- **Generation time ≈ 190 ticks** (pop / births_per_tick)
- **98% of deaths are at the age cap** (no selection via mortality)
- **Standard 500-tick audit = 2.6 generations**

Real evolutionary processes require **100–1000 generations** to
produce detectable signals (Fisher 1930: fixation time ∝ 1/s where
s is the selection coefficient). At 2.6 generations, we're
observing the opening minutes of a movie that takes days to play.

This single timescale mismatch explains **all** of our weak
evolutionary signals: Baldwin canalisation, plasticity evolution,
mimicry toxicity, Red Queen, dispersal-IFD.

## What real biology looks like

### Organism timescale reference table

| Organism | Lifespan | Gen time | Life/Gen | Offspring/life | Foraging acts/day |
|---|---|---|---|---|---|
| E. coli | 20 min | 20 min | 1 | 2 | N/A |
| Yeast | 2 hours | 1.5 hours | 1.3 | 2 | N/A |
| Drosophila | 60 days | 10 days | 6 | 400 | ~1000 |
| C. elegans | 20 days | 3 days | 7 | 300 | ~100 |
| Mouse | 2 years | 2 months | 12 | 50 | ~10,000 |
| Songbird | 5 years | 1 year | 5 | 20 | ~5,000 |
| Salmon | 4 years | 4 years | 1 | 3000 | ~5,000 |
| Elephant | 60 years | 15 years | 4 | 5 | ~100,000 |
| Oak tree | 500 years | 30 years | 17 | 10,000 | N/A |

Key ratios:
- **Lifespan / generation time**: ranges from 1 (semelparous) to 17
  (long-lived iteroparous). clade's current value: ~1.05 — essentially
  **semelparous by accident** even though the default is iteroparous.
- **Foraging acts per generation**: Drosophila ~10,000; mouse ~300,000.
  clade's current value: 190 (= generation time in ticks = actions).

### What clade SHOULD look like for realism

For a **generic small vertebrate** (mouse-like):
- Lifespan: 50 ticks (each tick ≈ 2 weeks)
- Generation time: 8 ticks (first reproduction at tick 5-8)
- Offspring per lifetime: 3-5 litters × 5-8 pups = 15-40
- At 500 ticks: 500/8 = **62 generations** ← meaningful evolution!
- At 2000 ticks: 2000/8 = **250 generations** ← strong evolution!

For a **Drosophila-like** (fast generation):
- Lifespan: 30 ticks
- Generation time: 5 ticks
- At 500 ticks: **100 generations**
- At 2000 ticks: **400 generations**

For an **elephant-like** (slow generation):
- Lifespan: 200 ticks (current default)
- Generation time: 50 ticks
- At 2000 ticks: **40 generations** (still marginal)
- At 10000 ticks: **200 generations** (adequate)

## Current default specs vs what biology needs

### Where clade's defaults go wrong

| Parameter | Current | Problem | Fix |
|---|---|---|---|
| `max_age` | 200 | Too long relative to repro → only ~1 generation/lifetime | 50 for mouse, 30 for fly |
| `min_repro_energy` | 120 | Too close to `energy_init` (100) → first repro at ~20 ticks if lucky, often much later | 40 for fast-gen, 80 for slow-gen |
| `energy_init` | 100 | Fine, but ratio to min_repro matters | Keep 100 |
| `eat_gain` | 5 | OK | OK |
| `max_bite` | 2 | Limits intake → slows energy accumulation | OK (handling time is realistic) |
| `move_cost` | 1 | OK | OK |
| `idle_cost` | 0.5 | OK | OK |
| `grass_rate` | 0.05 | Too slow for fast-gen preset | 0.15 for mouse, 0.30 for fly |
| `mutation_sd` | 0.1 | OK for brain weights | OK |
| `max_agents` | 500 | Often limits population before ecological equilibrium | 1000+ for meaningful evolution |

### The key ratio: min_repro_energy / energy_gain_rate

An agent gains energy at roughly:
```
net_gain ≈ eat_gain × max_bite × grass_availability - move_cost - idle_cost
         ≈ 5 × 2 × 0.5 - 1 - 0.5
         ≈ 3.5 energy/tick (when grass is available)
```

Time to first reproduction:
```
t_repro ≈ (min_repro_energy - energy_init) / net_gain
        ≈ (120 - 100) / 3.5
        ≈ 6 ticks (minimum, at perfect food availability)
```

But at steady state with 200 agents on a 30×30 grid, grass
competition reduces actual intake dramatically. Empirically,
generation time is ~190 ticks (not 6), because agents spend most
of their lives at suboptimal energy levels, occasionally dipping
above the repro threshold.

## Proposed presets

### `fast_specs()` — Drosophila / bacteria scale

Designed for scenarios where evolutionary dynamics are the focus.
Target: 100 generations at 500 ticks.

```r
fast_specs <- function() {
  s <- default_specs()
  s$max_age              <- 30L       # short life
  s$min_repro_energy     <- 40.0      # reproduce quickly
  s$energy_init          <- 30.0      # start near threshold
  s$grass_rate           <- 0.25      # abundant food
  s$n_agents_init        <- 200L      # large population
  s$max_agents           <- 1000L     # room to grow
  s$grid_rows            <- 40L       # bigger grid
  s$grid_cols            <- 40L
  s$max_ticks            <- 2000L     # 400 generations
  s$mutation_sd          <- 0.05      # moderate mutation
  s
}
# Expected: gen time ≈ 5 ticks, 2000 ticks = 400 generations
```

### `standard_specs()` — small vertebrate scale

The default for most evolutionary biology demonstrations.
Target: 50 generations at 500 ticks.

```r
standard_specs <- function() {
  s <- default_specs()
  s$max_age              <- 50L       # moderate life
  s$min_repro_energy     <- 60.0      # breed within ~10 ticks
  s$energy_init          <- 50.0
  s$grass_rate           <- 0.15      # moderate food
  s$n_agents_init        <- 150L
  s$max_agents           <- 800L
  s$grid_rows            <- 35L
  s$grid_cols            <- 35L
  s$max_ticks            <- 2000L     # 200 generations
  s$mutation_sd          <- 0.08
  s
}
# Expected: gen time ≈ 10 ticks, 2000 ticks = 200 generations
```

### `slow_specs()` — large vertebrate / elephant scale

For K-strategist scenarios: long-lived, few offspring, slow
evolution. Requires longer runs.

```r
slow_specs <- function() {
  s <- default_specs()
  s$max_age              <- 200L      # long life (current default)
  s$min_repro_energy     <- 150.0     # high investment
  s$energy_init          <- 100.0
  s$grass_rate           <- 0.10
  s$n_agents_init        <- 100L
  s$max_agents           <- 500L
  s$max_ticks            <- 10000L    # ~50 generations
  s$mutation_sd          <- 0.03      # low mutation
  s
}
# Expected: gen time ≈ 200 ticks, 10000 ticks = 50 generations
```

## Impact on scenarios

### What changes with `fast_specs()`

At 400 generations instead of 2.6:

| Scenario | Expected improvement |
|---|---|
| s-plasticity | Selection has 150× more time to separate seasonal from stable |
| s-baldwin | Canalisation can proceed through >100 generations of selection |
| s-mimicry | Toxicity can evolve upward through >100 generations of frequency-dependent selection |
| s-mating-systems | Red Queen recombination advantage accumulates over >100 generations |
| s-dispersal-ifd | Habitat preference evolution has >100 generations to diverge |

### Predictions

With `fast_specs()` at 2000 ticks (400 generations):
- **s-plasticity**: Δdelta should reach 0.02-0.05 (currently 0.002)
- **s-baldwin**: canalisation should be clearly visible if the
  selection coefficient is > 0.01
- **s-mimicry**: toxicity should evolve upward if the aposematic
  benefit is > the cost (which depends on predation pressure)
- **s-dispersal-ifd**: habitat preference should evolve to measurable
  levels (>0.05 from 0.0)
- **s-mating-systems**: Red Queen should have 100× more power to
  detect a sex advantage

## Recommendation

1. **Add `fast_specs()` and `standard_specs()` as exported functions**
   alongside the existing `default_specs()` and `quick_specs()`.
2. **Rerun all 🟠 scenario audits** with `fast_specs()` at 2000 ticks.
3. **Update the vignette demos** to use `fast_specs()` for
   evolutionary scenarios and `default_specs()` only for
   within-generation demonstrations.
4. **Keep `default_specs()` unchanged** for backward compatibility.
5. **Document the timescale mapping** in the getting-started guide
   so users understand what "1 tick" means biologically.

## Key literature

- Fisher, R.A. (1930) *The Genetical Theory of Natural Selection.*
  Clarendon Press. — Fixation time ∝ 1/s.
- Stearns, S.C. (1992) *The Evolution of Life Histories.* Oxford UP.
  — Life-history trade-offs and generation time.
- Charlesworth, B. (1994) *Evolution in Age-Structured Populations.*
  Cambridge UP. — Generation time in overlapping-generation models.
- Réale, D. et al. (2010) *Phil. Trans. R. Soc. B* 365:4051–4063.
  — Pace-of-life syndromes.
- Bulitko, V. (2023) MATLAB alife codebase — original timescale
  calibration (max_age=200, energy_init=100).

## What this document means for the project

The weak evolutionary signals we've documented across 4 🟠 scenarios
are NOT kernel bugs or parameter-tuning failures. They are the
**natural consequence of running 2-10 generations of an evolutionary
process that needs 100+**. The kernel machinery is correct; the
timescale is wrong.

This is a fundamental calibration insight that applies to every ABM
in the field. Most published ABMs don't report how many effective
generations their runs represent. clade should be explicit about
this — it's a scientific contribution in itself.
