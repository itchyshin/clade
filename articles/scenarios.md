# Biological Scenarios: A Discovery Guide

`clade` is a **discovery scientific virtual engine** for evolutionary
biology. Each scenario below implements a tested biological mechanism
and asks: what happens next? Every scenario page documents expected
dynamics from theory, reports what the model actually produces (with
real numbers, not just code), and points toward experiments that go
beyond existing theory.

Use the navigation menu above to jump directly to any scenario. The
table below maps all 35 scenarios to their biological theme.

------------------------------------------------------------------------

## Theme 1 — How do traits evolve?

*Genetics, heritability, trait architecture, mutation dynamics.*

| Scenario                                                | Key module             | What it tests                           |
|---------------------------------------------------------|------------------------|-----------------------------------------|
| [Baseline world](s-baseline.md)                         | core                   | Natural selection on foraging behaviour |
| [Population genetics & heritability](s-pop-genetics.md) | `body_size_evolution`  | h² from parent-offspring regression     |
| [Body size evolution](s-body-size.md)                   | `body_size_evolution`  | Allometric cost–benefit under predation |
| [Brain size evolution](s-brain-size.md)                 | `brain_size_evolution` | Parental provisioning hypothesis        |
| [Stress hypermutation](s-stress-hypermutation.md)       | `stress_hypermutation` | Adaptive mutation under starvation      |

------------------------------------------------------------------------

## Theme 2 — Ecology and adaptive landscapes

*Environment-phenotype feedbacks, spatial structure, niche.*

| Scenario                                               | Key module                                         | What it tests                                                                              |
|--------------------------------------------------------|----------------------------------------------------|--------------------------------------------------------------------------------------------|
| [Complex landscape](s-complex-landscape.md)            | `complex_landscape`                                | Canopy/shrub/ground habitat partitioning                                                   |
| [Dispersal, IFD & spatial sorting](s-dispersal-ifd.md) | `dispersal_evolution`, `spatial_sorting`           | Evolved dispersal and habitat matching                                                     |
| [Niche construction](s-niche.md)                       | `niche_construction` (+ `shelter_occupancy_bonus`) | Shelter building, grass-growth suppression; heritable occupancy benefit (Odling-Smee 2003) |
| [Seasonal dynamics](s-seasonal.md)                     | `seasonal_amplitude`                               | Resource cycles and life history buffering                                                 |
| [Scavenging & carrion](s-scavenging.md)                | `scavenging`                                       | Energy recycling from dead agents                                                          |

------------------------------------------------------------------------

## Theme 3 — Social evolution

*When does helping pay? Cooperation, signals, and divergence.*

| Scenario                                                | Key module                            | What it tests                                    |
|---------------------------------------------------------|---------------------------------------|--------------------------------------------------|
| [Kin selection](s-kin.md)                               | `kin_selection`                       | Hamilton’s rule in a spatially explicit model    |
| [Cooperative breeding & public goods](s-cooperation.md) | `cooperation`, `cooperative_breeding` | Heritable altruism and helper dynamics           |
| [Signals & mate choice](s-signals.md)                   | `signal_dims`, `sexual_selection`     | Signal-toxicity coevolution                      |
| [Speciation & genetic divergence](s-speciation.md)      | `n_species`                           | Ecological speciation via reproductive isolation |

------------------------------------------------------------------------

## Theme 4 — Life history strategies

*How life is organised across time and energy.*

| Scenario                                        | Key module                   | What it tests                                 |
|-------------------------------------------------|------------------------------|-----------------------------------------------|
| [Parental care](s-parental-care.md)             | `parental_care`              | Altricial development and offspring buffering |
| [Mating systems](s-mating-systems.md)           | `ploidy`, `sexual_selection` | Sexual vs asexual reproduction                |
| [Life history strategies](s-life-history.md)    | `life_history`               | Semelparous vs iteroparous evolution          |
| [Clutch size evolution](s-clutch-size.md)       | `clutch_size_evolution`      | r/K strategy trade-offs                       |
| [Parental investment](s-parental-investment.md) | `female_investment`          | Quality vs quantity offspring trade-off       |
| [Pace-of-life syndromes](s-pace-of-life.md)     | `metabolic_rate_evolution`   | Fast-slow life history continuum              |

------------------------------------------------------------------------

## Theme 5 — Species interactions and arms races

*Predator-prey, coevolution, disease, mimicry.*

| Scenario                                              | Key module                       | What it tests                                                                                                                                              |
|-------------------------------------------------------|----------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Predator-prey dynamics](s-predator-prey.md)          | `n_predators_init`               | Lotka-Volterra cycles in discrete space                                                                                                                    |
| [Group defense](s-group-defense.md)                   | `group_defense`                  | Dilution of risk and vigilance                                                                                                                             |
| [Mimicry & toxicity](s-mimicry.md)                    | `mimicry` (+ `batesian_mimicry`) | Müllerian aposematism by default; `batesian_mimicry = TRUE` enables palatable mimics exploiting learned aversion (Bates 1862) with predator-betrayal decay |
| [SIR disease](s-disease.md)                           | `disease`                        | Epidemic dynamics and immune evolution                                                                                                                     |
| [Predation & neural evolution](s-predation-neural.md) | `n_predators_init`, `brain_type` | Cognitive arms races                                                                                                                                       |

------------------------------------------------------------------------

## Theme 6 — Learning, plasticity, and cognition

*Within-lifetime change interacting with genetic evolution.*

| Scenario                                     | Key module                          | What it tests                            |
|----------------------------------------------|-------------------------------------|------------------------------------------|
| [Within-lifetime RL](s-rl.md)                | `rl_mode`                           | REINFORCE policy gradient during life    |
| [Social learning](s-social-learning.md)      | `social_learning`                   | Prestige-biased copying                  |
| [Phenotypic plasticity](s-plasticity.md)     | `plasticity_evolution`              | Canalization vs flexibility trade-off    |
| [BNN uncertainty canalization](s-baldwin.md) | `epigenetics`, `brain_type = "bnn"` | Baldwin Effect via sigma evolution       |
| [Cephalopod paradox](s-cephalopod.md)        | `rl_mode`, `max_age`                | Short lifespan selects for fast learning |

------------------------------------------------------------------------

## Theme 7 — Discovery experiments

*Combinatorial, computational, and open-ended.*

| Scenario                                            | What it tests                                               |
|-----------------------------------------------------|-------------------------------------------------------------|
| [Module comparison](s-module-comparison.md)         | 14-condition experiment across module combinations          |
| [MAP-Elites diversity search](s-map-elites.md)      | Quality-diversity optimisation of parameter space           |
| [Kitchen-sink run](s-kitchen-sink.md)               | All modules simultaneously                                  |
| [Evolution of bad science](s-bad-science.md)        | Publication pressure and false discovery rate               |
| [Cross-module discovery gallery](s-cross-module.md) | 6 executed cross-module experiments with multi-seed results |

------------------------------------------------------------------------

## How to use this guide

Each scenario page contains:

1.  **What it models** — the biological mechanism and key parameters
2.  **Example** — runnable code (`eval = FALSE`; requires Julia) and a
    figure
3.  **What we found** — real numbers from actual simulation runs
4.  **Discovery experiments** — three specific experiments that go
    beyond the baseline, with “Tried it.” results for experiment 1

All code requires Julia. Check availability with
[`julia_is_ready()`](../reference/julia_is_ready.md). The parameter
reference for all 200+ specs is at [Parameter
reference](parameter-reference.md).

``` r
library(clade)
if (julia_is_ready()) {
  s <- default_specs()
  e <- run_alife(s)
  plot_run(get_run_data(e))
}
```
