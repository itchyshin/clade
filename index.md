# clade

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![pkgdown](https://img.shields.io/badge/docs-pkgdown-blue.svg)](https://itchyshin.github.io/clade/)

**Agent-based evolutionary simulation with a Julia backend and R
interface.**

`clade` runs populations of digital organisms on a renewable resource
grid. Each agent carries a heritable neural-network genome; natural
selection acts on brain weights, life-history traits, and — with
optional modules — body size, dispersal tendency, wing morphology,
cooperative behaviour, and more.

The simulation kernel is written in Julia for performance. R is the
interface: you set parameters, call
[`run_alife()`](reference/run_alife.md) once, and receive the full
simulation environment back for analysis and visualisation. The R–Julia
boundary is crossed **once per run**, not once per tick, so large
populations and long simulations stay fast.

------------------------------------------------------------------------

## Installation

### R package

``` r
# From GitHub (development version)
remotes::install_github("itchyshin/clade")
```

### Julia

clade requires Julia ≥ 1.9. The easiest way to install it is via
[juliaup](https://github.com/JuliaLang/juliaup):

``` bash
curl -fsSL https://install.julialang.org | sh
```

Or download directly from
[julialang.org/downloads](https://julialang.org/downloads/).

### First-run compilation

On the first call to [`run_alife()`](reference/run_alife.md), Julia
compiles the simulation kernel. This takes **60–90 seconds** and is
cached for all subsequent runs in the same Julia environment.

------------------------------------------------------------------------

## Quick start

``` r
library(clade)

# Confirm Julia is ready (compiles kernel on first call — ~60-90 s once)
julia_is_ready()

# Set up a baseline run
specs <- default_specs()
specs$n_agents_init <- 40L
specs$max_ticks     <- 300L

# Run the simulation
env  <- run_alife(specs)

# Extract and plot results
data <- get_run_data(env)
plot_run(data)   # population, energy, genetic diversity dashboard
```

------------------------------------------------------------------------

## Biological modules

All modules are disabled by default and enabled with a single flag in
the specs list. Modules can be freely combined.

| Module                        | Flag(s)                                                        | What it models                                                                                                                                                                                    |
|-------------------------------|----------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Baseline                      | —                                                              | Foraging and neural evolution on a toroidal grass grid                                                                                                                                            |
| Body size                     | `body_size_evolution`                                          | Metabolic scaling (approximate Kleiber); size-foraging trade-off                                                                                                                                  |
| Brain size                    | `brain_size_evolution`                                         | Cognitive-bonus × metabolic-cost; bootstrapping under `parental_care`                                                                                                                             |
| Clutch size                   | `clutch_size_evolution`                                        | r/K-style trade-off between clutch count and offspring quality                                                                                                                                    |
| Complex landscape             | `complex_landscape`                                            | 3-layer forest (grass / shrubs / canopy); wing-size evolves for canopy access                                                                                                                     |
| Cooperation                   | `cooperation_evolution`                                        | Public-goods games with helper-tendency evolution                                                                                                                                                 |
| Cooperative breeding          | `cooperative_breeding`                                         | Helpers at the nest (Emlen 1982)                                                                                                                                                                  |
| Dispersal                     | `dispersal_evolution`                                          | Heritable dispersal tendency                                                                                                                                                                      |
| Habitat preference            | `habitat_preference_evolution`                                 | Agents move toward preferred grass density                                                                                                                                                        |
| IFfolk + parliament           | `iffolk_selection`, `parliament_suppression`                   | Inclusive-fitness transfers + intragenomic-conflict suppression (Haig 2000; Fromhage & Jennions 2019)                                                                                             |
| Kin selection                 | `kin_selection`                                                | Hamilton’s rule, pedigree-based relatedness (r = 0.5 / 0.25 / 0)                                                                                                                                  |
| Life history / pace of life   | `metabolic_rate_evolution`, `aging_rate_evolution`             | Metabolic rate ↔︎ lifespan trade-off                                                                                                                                                               |
| Mating systems                | `ploidy = 2`, `mate_choice`                                    | Haploid / diploid; signal-preference assortative mating                                                                                                                                           |
| Mimicry                       | `mimicry`                                                      | Predator learning + warning colouration (currently Müllerian; Batesian disabled by design)                                                                                                        |
| Mutation-rate evolution       | `mutation_rate_evolution`                                      | Per-agent heritable `mutation_sd`                                                                                                                                                                 |
| Niche construction            | `niche_construction`                                           | Shelter-building modifies the selection environment (local public good). With `shelter_occupancy_bonus > 0`: shelters confer a heritable metabolic benefit to occupants (Odling-Smee et al. 2003) |
| Batesian mimicry              | `mimicry` + `batesian_mimicry`                                 | Palatable mimics (`toxicity = 0`) exploit a predator’s aversion for a shared signal; predator-betrayal decay prevents runaway cheating (Bates 1862)                                               |
| Parental care                 | `parental_care`                                                | Obligate altriciality — offspring carried, fed, and graduated                                                                                                                                     |
| Parental investment           | `parental_investment_evolution`                                | Evolved male / offspring-quality investment                                                                                                                                                       |
| Phenotypic plasticity         | `phenotypic_plasticity`                                        | Environment-dependent reproduction threshold                                                                                                                                                      |
| Predation                     | `predators`, `n_predators_init > 0`                            | Co-evolving predator guild with dedicated 15-input sensory brain                                                                                                                                  |
| Predator group defence        | `group_defense`                                                | Coordinated anti-predator behaviour                                                                                                                                                               |
| Scavenging                    | `scavenging`                                                   | Carcass consumption; decay-based carcass lifetime                                                                                                                                                 |
| Seasonal dynamics             | `seasonal_amplitude > 0`, `winter_death_prob`                  | Resource oscillation + winter mortality                                                                                                                                                           |
| SIR disease                   | `disease`                                                      | Susceptible–Infected–Recovered epidemic dynamics                                                                                                                                                  |
| Signals / sexual selection    | `signal_mating`, `signal_evolution_drift`                      | Signal-preference coevolution (Fisher 1915; Kirkpatrick & Ryan 1991)                                                                                                                              |
| Social learning               | `social_learning`                                              | Copy successful neighbours’ brain weights                                                                                                                                                         |
| Spatial sorting               | `spatial_sorting` + `dispersal_evolution` + `toroidal = FALSE` | Invasion-front dispersal assortment (Shine et al. 2011; needs bounded grid)                                                                                                                       |
| Speciation                    | `speciation`                                                   | Genome-distance clustering + reproductive isolation                                                                                                                                               |
| Stress hypermutation          | `stress_hypermutation`                                         | SOS-style mutation-rate spike below `stress_threshold`                                                                                                                                            |
| Transgenerational epigenetics | `epigenetics`                                                  | Methylation inheritance on BNN sigma (Jablonka & Lamb 2005)                                                                                                                                       |
| Within-lifetime RL            | `rl_mode = "actor_critic"`                                     | REINFORCE score-function update on BNN posterior (Williams 1992; Blundell et al. 2015)                                                                                                            |
| Lamarckian inheritance        | `lamarckian = TRUE`                                            | RL-learned weights written back to genome before meiosis                                                                                                                                          |
| Quantised weights             | `ann_weight_values`                                            | Snap weights to a discrete set (e.g. ternary) after expression                                                                                                                                    |

See
[`vignettes/parameter-reference.Rmd`](vignettes/parameter-reference.Rmd)
for the complete parameter list.

------------------------------------------------------------------------

## Brain architectures

The `brain_type` parameter selects the neural architecture. All types
share the same R interface; only the forward pass and learning dynamics
differ.

| Type            | Description                                                             |
|-----------------|-------------------------------------------------------------------------|
| `"bnn"`         | Bayesian neural network — learns a distribution over weights (default)  |
| `"ann"`         | Standard multilayer perceptron                                          |
| `"ctrnn"`       | Continuous-time recurrent network; suited for temporally extended tasks |
| `"grn"`         | Gene regulatory network topology; sparse and biologically motivated     |
| `"transformer"` | Self-attention architecture; highest capacity, slowest                  |
| `"synthesis"`   | Symbolic rule extraction from evolved weights                           |

------------------------------------------------------------------------

## Documentation

Full documentation is available at
**<https://itchyshin.github.io/clade/>**.

| Article                                                                                    | Contents                                                                               |
|--------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------|
| [Getting Started](https://itchyshin.github.io/clade/articles/getting-started.html)         | Installation, first run, extracting results, batch runs                                |
| [Biological Scenarios](https://itchyshin.github.io/clade/articles/scenarios.html)          | Code and expected outputs for every module                                             |
| [Custom Modules](https://itchyshin.github.io/clade/articles/custom-modules.html)           | Write your own per-tick hooks with [`register_module()`](reference/register_module.md) |
| [Parameter Reference](https://itchyshin.github.io/clade/articles/parameter-reference.html) | Every parameter in [`default_specs()`](reference/default_specs.md), grouped by theme   |
| [Diversity Search](https://itchyshin.github.io/clade/articles/diversity-search.html)       | CMA-ES, MAP-Elites, viability mapping, and scenario-specific tuning                    |

------------------------------------------------------------------------

## Citation

If you use clade in published work, please cite:

``` bibtex
@misc{clade2026,
  author  = {Nakagawa, Shinichi},
  title   = {clade: Agent-based evolutionary simulation with a Julia backend},
  year    = {2026},
  note    = {R package version 0.3.0},
  url     = {https://github.com/itchyshin/clade}
}
```

------------------------------------------------------------------------

## License

MIT — see [LICENSE](LICENSE).
