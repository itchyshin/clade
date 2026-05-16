# Getting started with clade

## What clade is

`clade` is an R package for agent-based simulation of evolution and
foraging ecology. Digital organisms carry heritable neural-network
genomes (haploid or diploid) and one of several brain types, and they
evolve over generations through natural selection on behaviour, life
history, and cognition. The package is designed for evolutionary
biologists who want to run controlled *in silico* experiments without
writing low-level simulation code.

`clade` is the successor to the experimental `alifeR` package. Where
`alifeR` embedded the simulation hot path in Rcpp, `clade` runs the
entire simulation in Julia (via
[JuliaConnectoR](https://CRAN.R-project.org/package=JuliaConnectoR)).
The R–Julia boundary is crossed *once* per
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)
call, not once per tick. For 200 agents and 1,000 ticks this is roughly
25× faster than the Rcpp-based alifeR backend, and it makes runs of
100,000 agents practical. The Julia backend also enables MAP-Elites
quality-diversity search and derivative-free optimisation (CMA-ES),
neither of which is feasible at this scale from an Rcpp simulator.

This vignette is an orientation, not a reference. It introduces the
workflow, the parameter list, the brain types, and the biological
modules that can be toggled on or off. All code chunks below are shown
but not evaluated, because the Julia backend is not available during
package check or vignette build.

------------------------------------------------------------------------

## Installation

### R package

``` r

# install.packages("remotes")
remotes::install_github("itchyshin/clade")
```

### Julia

`clade` requires Julia ≥ 1.9. The easiest installer is
[juliaup](https://github.com/JuliaLang/juliaup):

``` bash
curl -fsSL https://install.julialang.org | sh
```

Alternatively, download directly from
[julialang.org/downloads](https://julialang.org/downloads/).

On the **first** call to
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md),
`clade` starts a Julia session, installs its own Julia dependencies into
a private environment, and precompiles the simulation package. This
takes 60–90 seconds and is cached for all subsequent runs in the same
Julia environment.

------------------------------------------------------------------------

## Checking that Julia is ready

Before your first serious run, confirm Julia is discoverable from R:

``` r

library(clade)

if (!julia_is_ready()) {
  stop("Julia not found. See ?julia_is_ready for setup instructions.")
}
cat("Julia", julia_version(), "ready.\n")
```

If Julia is not found, the most common fixes are:

- Add Julia to `PATH` (run `export PATH="$PATH:~/.juliaup/bin"` in your
  shell, then restart R).
- Set `JULIA_BINDIR` in your `.Renviron` file to the directory
  containing the `julia` binary.
- Reinstall Julia via `juliaup`.

------------------------------------------------------------------------

## A minimal run

The default configuration is a small grid world with a single brain type
and the core ecological loop. Three calls are enough to produce a tidy
result and a diagnostic plot:

``` r

library(clade)

specs <- default_specs()

# Modules are off by default; enable any combination independently, e.g.:
# specs$disease <- TRUE
# specs$body_size_evolution <- TRUE

env  <- run_alife(specs)
data <- get_run_data(env)

plot_run(data)
```

`env` is a `clade_env` object. Its `print` method gives a one-line
summary:

``` r

print(env)
#> clade_env  [500 ticks | 193 agents | genetic_diversity: 0.319]
```

![plot_run() produces a six-panel
dashboard](figures/showcase_01_run_dashboard.png)

plot_run() produces a six-panel dashboard: population size, mean energy
(±SD ribbon), genetic diversity, births and deaths per tick, grass
coverage, and BNN prior sigma.

[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)
returns a list with two tidy data frames:

- `data$ticks` — one row per logged tick, with population-level
  summaries (mean energy, mean body size, genetic diversity, grass
  cover, births, deaths, and a column per active module).
- `data$deaths` — one row per agent death, with cause, age, energy,
  final body size, and lifetime offspring count.

These are the canonical inputs to every analysis function in the
package.

------------------------------------------------------------------------

## Inspecting specs

[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md)
returns a long named list (~296 parameters in 0.7.0). To see only what
you have changed, use `print_specs(diff_only = TRUE)`:

``` r

specs <- default_specs()
specs$kin_selection     <- TRUE
specs$complex_landscape <- TRUE
specs$max_ticks         <- 400L

print_specs(specs, diff_only = TRUE)
#> -- clade specs (~296 parameters) [diff only] --
#>
#>   Grid & population
#>     max_ticks                              400 *
#>
#>   Kin selection
#>     kin_selection                         TRUE *
#>
#>   Complex landscape
#>     complex_landscape                     TRUE *
```

For a full parameter listing with types and defaults, see
[`vignette("parameter-reference")`](https://itchyshin.github.io/clade/articles/parameter-reference.md)
or the help page for
[`?default_specs`](https://itchyshin.github.io/clade/reference/default_specs.md).

------------------------------------------------------------------------

## Simulation timescale: choosing the right spec preset

The single most important choice when designing a clade run is **how
many generations you will simulate**. Fisher (1930) showed that a
beneficial allele needs roughly $`1/s`$ generations to fix, where $`s`$
is the selection coefficient. For modest selection
($`s \approx 0.05\text{–}0.10`$), this is 20–100 generations. Weaker
selection needs hundreds.

Under
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md),
generation time is roughly `max_age / 2 ≈ 100 ticks` plus maturation
delay, so the effective generation time is ~190 ticks. A 500-tick run is
therefore only ~2.6 generations — too short to see any evolutionary
dynamics at realistic selection strengths. This is the single largest
source of “weak effect” reports in early clade audits.

The package ships three presets that make this trade-off explicit:

| Preset | Generation time | Recommended `max_ticks` | Generations | Use case |
|----|----|----|----|----|
| [`fast_specs()`](https://itchyshin.github.io/clade/reference/fast_specs.md) | ~30 ticks | 2000 | ~66 | Any evolutionary scenario — plasticity, Baldwin, body size, cooperation, speciation |
| [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md) | ~190 ticks | 500 | ~2.6 | Within-generation demos — ecology, predator-prey, disease, learning, kitchen-sink |
| [`slow_specs()`](https://itchyshin.github.io/clade/reference/slow_specs.md) | ~200 ticks | 10000 | ~50 | K-strategist scenarios (elephant, whale) where long life history is the point |

[`fast_specs()`](https://itchyshin.github.io/clade/reference/fast_specs.md)
achieves a short generation time by lowering `max_age` to 30 ticks and
`min_repro_energy` to 60 (versus 200 and 120 in default). This is how
the MATLAB ancestor of clade (Bulitko 2023) ran — agents matured quickly
and turned over fast, which is exactly what gives selection enough time
to do its work.

``` r

# Evolutionary scenario: use fast_specs
evo <- fast_specs()               # max_ticks = 2000, ~66 generations
evo$phenotypic_plasticity <- TRUE
run_alife(evo)

# Within-generation ecology / LV demo: default_specs is appropriate
ecol <- default_specs()
ecol$max_ticks <- 500L
ecol$n_predators_init <- 5L
run_alife(ecol)
```

**Rule of thumb.** If the phenomenon you want to see requires *allele
change* (heritable trait evolution, genetic assimilation, cooperation or
signal elaboration), use
[`fast_specs()`](https://itchyshin.github.io/clade/reference/fast_specs.md).
If it is a demographic or ecological phenomenon that unfolds within a
single generation (predator-prey cycles, disease spread, seasonal grass
dynamics),
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md)
is fine.

See
[`dev/docs/timescale-analysis.md`](https://github.com/itchyshin/clade/blob/main/dev/docs/timescale-analysis.md)
for the biological reference table (E. coli through elephant) and the
full MATLAB-ancestor comparison that motivated these presets.

------------------------------------------------------------------------

## Parameter overview

The parameters that most strongly shape a run are summarised below. All
others live in
[`?default_specs`](https://itchyshin.github.io/clade/reference/default_specs.md).
Values shown are the 0.7.0 defaults.

| Parameter | Default | What it controls |
|----|----|----|
| `brain_type` | `"bnn"` | The cognitive architecture used by every agent (see next section). |
| `ploidy` | `2L` | Diploid (`2L`) or haploid (`1L`) genomes. |
| `max_ticks` | `500L` | Length of the simulation in time steps. |
| `n_agents_init` | `50L` | Number of founders. |
| `grass_rate` | `0.05` | Per-tick probability that an empty cell regrows grass. |
| `max_bite` | `2.0` | Maximum grass units an agent can eat per tick (handling time; Holling 1959). |
| `mutation_sd` | `0.1` | Gaussian noise added to weights at reproduction. |
| `repro_cost_mode` | `"proportional"` | Parental cost model: `"proportional"` (0.4.0 default; Smith & Fretwell 1974) or `"fixed"`. |
| `repro_cost_fraction` | `0.5` | Fraction of parent energy spent per offspring under proportional mode. |
| `offspring_energy_mode` | `"proportional"` | Newborn energy model: proportional to cost paid, or `"fixed"`. |
| `disease` | `FALSE` | Toggles the SIR disease module. |
| `kin_selection` | `FALSE` | Toggles pedigree-based altruism toward Moore-neighbourhood relatives. |
| `cooperation_evolution` | `FALSE` | Toggles the evolution of an inheritable cooperation propensity. |
| `niche_construction` | `FALSE` | Toggles shelter-building and its protective and grass-suppressing effects. |
| `social_learning` | `FALSE` | Toggles output-layer copying from successful neighbours. |
| `rl_mode` | `"none"` | Within-lifetime reinforcement learning (`"actor_critic"` or `"none"`). |

Each module can be toggled independently, and the simulation will warn
if two modules with conflicting assumptions are active.

------------------------------------------------------------------------

## Brain types

Every agent runs the same architecture, set by `specs$brain_type`. The
choice changes both how agents make decisions and what kind of
plasticity is available.

| Brain type | Description |
|----|----|
| `"bnn"` | A Bayesian neural network with a Gaussian prior over weights; `prior_sigma` evolves under selection (Neal 1996). |
| `"ann"` | A standard multilayer perceptron with feed-forward computation and weight inheritance. |
| `"ctrnn"` | A continuous-time recurrent network with leaky integrator neurons; supports dynamical behaviour (Beer 1995). |
| `"grn"` | A gene regulatory network whose nodes are genes and whose interactions evolve via mutation of the regulatory matrix. |
| `"random"` | Uniformly random action selection; useful as a null model baseline. |

Two further names are reserved for future implementation and currently
error if requested: `"transformer"` (self-attention) and `"synthesis"`
(symbolic rule extraction from evolved weights).

`"bnn"` is the default because it admits an evolvable prior width and so
captures Baldwin-style learning–evolution interactions (Baldwin 1896,
Mouret & Clune 2015) cleanly. In 0.4.0, the BNN’s prior-width can be
drawn from heterozygosity (legacy), a fixed value, or the evolved
`plasticity` trait — see `bnn_sigma_source` in
[`?default_specs`](https://itchyshin.github.io/clade/reference/default_specs.md).

------------------------------------------------------------------------

## Biological modules

Modules are toggled through `specs`. They are all off by default, so the
core simulation is a clean baseline of foraging, reproduction, and
death.

| Module | Spec field | One-line description |
|----|----|----|
| Body size evolution | `body_size_evolution` | Heritable body size scales metabolic cost, foraging gain, and energy storage (Kleiber 1947). |
| Natal dispersal | `dispersal_evolution` | Heritable tendency to move away from birthplace each tick, reducing kin competition. |
| Group defense | `group_defense` | Agents in the same cell share an anti-predator benefit that scales with local group size. |
| Habitat preference | `habitat_preference_evolution` | Heritable preference for particular terrain or grass-density zones. |
| Seasonal dynamics | `seasonal_amplitude` | Grass productivity cycles sinusoidally, imposing periodic resource bottlenecks. |
| Signals and mate choice | `signal_dims` | Agents evolve a multi-dimensional signal; receivers apply a heritable preference at mating. |
| Speciation | `speciation` | Reproductive isolation emerges when mate-preference divergence exceeds a threshold. |
| Predators | `n_predators_init` | Evolving predator agents pursue prey; predator numbers are set at initialisation. |
| Parental care | `parental_care` | Offspring are carried until graduation; parent pays a per-tick care cost. |
| Cooperative breeding | `cooperative_breeding` | Non-breeding helpers contribute energy to raise offspring in the same cell. |
| Mimicry and toxicity | `mimicry` (+ `batesian_mimicry`) | Heritable toxicity deters predators via Rescorla–Wagner avoidance learning. In 0.4.0 predators use vector-valued signal memory so Batesian / Müllerian mimicry is signal-specific (Bates 1862, Müller 1879). |
| Phenotypic plasticity | `phenotypic_plasticity` | Heritable `plasticity` trait; when `bnn_sigma_source = "trait"`, this trait directly sets each agent’s BNN prior width. |
| Niche construction | `niche_construction` (+ `shelter_occupancy_bonus`) | Agents build shelters that protect against predators and slow grass regrowth on the cell. With `shelter_occupancy_bonus > 0`: occupants of sheltered cells receive an energy subsidy proportional to shelter depth — heritable niche effect (Odling-Smee et al. 2003). |
| Scavenging | `scavenging` | Agents may consume carrion left behind by recently dead conspecifics (DeVault et al. 2003). |
| Disease (SIR) | `disease` | Susceptible–infected–recovered transmission with energy costs and recovered immunity (Kermack & McKendrick 1927). |
| Kin selection | `kin_selection` | Pedigree-based altruistic energy transfer to related neighbours (Hamilton 1964). |
| Cooperation (PGG) | `cooperation_evolution` | An inheritable cooperation trait that scales the propensity to share with conspecifics (Nowak & May 1992). |
| Within-lifetime RL | `rl_mode` | REINFORCE-with-baseline updates to the output layer at runtime (Williams 1992). |
| Social learning | `social_learning` | Periodic copying of output-layer weights from successful Moore-neighbourhood teachers. |
| Epigenetic inheritance | `epigenetics` | Lamarckian-style transmission of within-lifetime weight changes (Jablonka & Lamb 2005). |
| Clutch size evolution | `clutch_size_evolution` | Heritable clutch size evolves under the life-history trade-off between offspring number and cost (Lack 1947). |
| Parental investment | `parental_investment_evolution` | In 0.4.0, `female_investment` splits parental cost between mother and mate and scales offspring birth energy (Trivers 1972). |
| Stress hypermutation | `stress_hypermutation` | Mutation rate increases when agent energy falls below a threshold (Rosenberg 2001). |
| Max-age pace of life | `max_age_scales_with_metabolism` | 0.4.0: when `TRUE`, effective lifespan scales inversely with metabolic rate (Réale et al. 2010). |
| Neonatal foraging deficit | `neonatal_foraging_deficit` | 0.4.3: young agents forage at reduced efficiency for `neonatal_deficit_duration` ticks. Creates the selection pressure for parental provisioning (Aiello & Wheeler 1995). |
| Coevolving parasites | `coevolving_parasites` | 0.5.0/0.5.1: Hamilton 1980 Red Queen. Continuous-trait centroid tracking or discrete-allele Hamming matching with Mendelian inheritance. |
| Sigma-action decoupling | `bnn_action_noise_scale` | 0.5.5: controls how much BNN sigma contributes to action noise. At 0, actions are deterministic from mu; sigma only affects the learning/cost channel. |

A typical experimental design fixes the brain type and toggles one
module at a time, comparing the resulting
[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)
outputs across conditions.

------------------------------------------------------------------------

## Example: body size evolution

When `body_size_evolution = TRUE`, agents evolve a heritable body size
trait. Larger agents eat more per grass cell but pay a higher metabolic
surcharge; smaller agents eat less but are cheaper to run. Reference
size 1.0 has no metabolic correction. The trait is inherited via the
genome and bounded by `body_size_min` (default 0.3) and `body_size_max`
(default 3.0).

``` r

specs                       <- default_specs()
specs$body_size_evolution   <- TRUE
specs$body_size_init_mean   <- 1.0
specs$body_size_mutation_sd <- 0.08

env  <- run_alife(specs)
data <- get_run_data(env)

# Time series of mean and SD of body size
head(data$ticks[, c("t", "n_agents", "mean_body_size", "sd_body_size")])
```

------------------------------------------------------------------------

## Example: natal dispersal

When `dispersal_evolution = TRUE`, agents evolve a heritable probability
of taking one step away from their birthplace each tick. Dispersal
reduces inbreeding and kin competition at the cost of `dispersal_cost`
energy.

``` r

specs                     <- default_specs()
specs$dispersal_evolution <- TRUE
specs$dispersal_init_mean <- 0.2

env  <- run_alife(specs)
data <- get_run_data(env)

# Total dispersal events
sum(data$ticks$n_dispersal_events)
```

------------------------------------------------------------------------

## Example: disease dynamics

To produce an SIR-style epidemic in the population, set the `disease`
flag and use the dedicated plotting helper:

``` r

specs         <- default_specs()
specs$disease <- TRUE
env           <- run_alife(specs)
data          <- get_run_data(env)

plot_disease_dynamics(data)
```

[`plot_disease_dynamics()`](https://itchyshin.github.io/clade/reference/plot_disease_dynamics.md)
reads the `n_infected` and `n_new_infections` columns from `data$ticks`
and overlays the susceptible, infected, and recovered classes through
time. The transmission probability, infectious period, and immune
duration are all controlled through
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md).

------------------------------------------------------------------------

## Running multiple scenarios in parallel

[`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md)
runs a list of specs across R worker processes. This is the recommended
way to compare parameter regimes, since each Julia process stays warm
for its slice of the batch:

``` r

specs_list <- lapply(c(0.05, 0.10, 0.20), function(gr) {
  s <- default_specs()
  s$grass_rate <- gr
  s$max_ticks  <- 200L
  s
})

results <- batch_alife(specs_list, n_cores = 3L)

# Compare mean genetic diversity across grass rates
sapply(results, function(env) {
  mean(get_run_data(env)$ticks$genetic_diversity, na.rm = TRUE)
})
```

For more systematic parameter exploration (CMA-ES, MAP-Elites, viability
search), see the [parameter search
guide](https://itchyshin.github.io/clade/articles/ps-introduction.md).

------------------------------------------------------------------------

## Performance note

`clade` crosses the R–Julia boundary exactly **once per
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)
call**, regardless of the number of ticks or the number of agents. The
entire tick loop — sensing, neural network forward pass, action
selection, movement, eating, reproduction, and death — runs inside a
single Julia process. For 200 agents and 1,000 ticks this is roughly 25×
faster than the Rcpp-based `alifeR` backend, and it scales smoothly to
populations of ~100,000 agents on a workstation.

The first call in an R session pays a one-off start-up cost (~60–90 s)
for Julia compilation. Subsequent calls reuse the warm Julia session and
return results immediately.

------------------------------------------------------------------------

## Where to go next

- **Biological scenarios.**
  [`vignette("scenarios")`](https://itchyshin.github.io/clade/articles/scenarios.md)
  is a discovery guide to all 36 pre-packaged scenarios, each with
  runnable code, expected dynamics, and follow-up experiments.
- **Parameter search.** The [parameter search
  introduction](https://itchyshin.github.io/clade/articles/ps-introduction.md)
  explains when to use random search, MAP-Elites, CMA-ES, or viability
  mapping. Separate guides cover [agent-level
  parameters](https://itchyshin.github.io/clade/articles/ps-agent-parameters.md),
  [environment-level
  parameters](https://itchyshin.github.io/clade/articles/ps-environment-parameters.md),
  and [the algorithms
  themselves](https://itchyshin.github.io/clade/articles/ps-algorithms.md).
- **Full parameter reference.** Every parameter in
  [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md)
  is documented in
  [`vignette("parameter-reference")`](https://itchyshin.github.io/clade/articles/parameter-reference.md).
- **Reading the kernel as biology.** The
  [kernel-as-biology](https://itchyshin.github.io/clade/articles/k-README.md)
  series translates the Julia simulation kernel into plain English with
  biological rationale and audit findings — the hot path (`tick.jl`,
  `sense.jl`, `reproduce.jl`, etc.), side-by-side with the code.
- **Paper reproductions.**
  [`vignette("paper-template")`](https://itchyshin.github.io/clade/articles/paper-template.md)
  plus six worked examples (K&B 2003, Griesser 2023, D&D 1999, Réale
  2010, Emlen 1982, Courchamp 1999) show how to reproduce a published
  prediction in clade end-to-end.
- **0.4.0 kernel changes.** The [0.4.0
  changelog](https://github.com/itchyshin/clade/blob/main/dev/docs/kernel-0.4.0.md)
  documents every kernel-rule change in this release with biological
  rationale and audit-driven justification.

------------------------------------------------------------------------

## References

- Baldwin, J.M. (1896) A new factor in evolution. *American Naturalist*
  30(354): 441–451.
- Bates, H.W. (1862) Contributions to an insect fauna of the Amazon
  valley. *Transactions of the Linnean Society of London* 23:495–566.
- Beer, R.D. (1995) On the dynamics of small continuous-time recurrent
  neural networks. *Adaptive Behavior* 3(4): 469–509.
- DeVault, T.L. et al. (2003) Scavenging by vertebrates. *Oikos*
  102:225–234.
- Falconer, D.S. & Mackay, T.F.C. (1996) *Introduction to Quantitative
  Genetics*, 4th ed. Longman, Harlow.
- Hamilton, W.D. (1964) The genetical evolution of social behaviour.
  *Journal of Theoretical Biology* 7(1): 1–52.
- Holling, C.S. (1959) The components of predation as revealed by a
  study of small-mammal predation of the European pine sawfly. *Canadian
  Entomologist* 91:293–320.
- Jablonka, E. & Lamb, M.J. (2005) *Evolution in Four Dimensions*. MIT
  Press, Cambridge, MA.
- Kermack, W.O. & McKendrick, A.G. (1927) A contribution to the
  mathematical theory of epidemics. *Proceedings of the Royal Society A*
  115(772): 700–721.
- Lack, D. (1947) The significance of clutch-size. *Ibis* 89:302–352.
- Mouret, J.-B. & Clune, J. (2015) Illuminating search spaces by mapping
  elites. *arXiv:1504.04909*.
- Müller, F. (1879) Ituna and Thyridia: a remarkable case of mimicry in
  butterflies. *Transactions of the Entomological Society of London*
  1879: xxvii–xxix.
- Neal, R.M. (1996) *Bayesian Learning for Neural Networks*. Springer,
  New York.
- Nowak, M.A. & May, R.M. (1992) Evolutionary games and spatial chaos.
  *Nature* 359:826–829.
- Odling-Smee, F.J., Laland, K.N. & Feldman, M.W. (2003) *Niche
  Construction.* Princeton University Press.
- Réale, D. et al. (2010) Personality and the emergence of the
  pace-of-life syndrome concept. *Phil. Trans. R. Soc. B* 365:4051–4063.
- Rosenberg, S.M. (2001) Evolving responsively: adaptive mutation.
  *Nature Reviews Genetics* 2:504–515.
- Smith, C.C. & Fretwell, S.D. (1974) The optimal balance between size
  and number of offspring. *American Naturalist* 108:499–506.
- Trivers, R.L. (1972) Parental investment and sexual selection. In
  Campbell (ed.) *Sexual Selection and the Descent of Man.*
- Williams, R.J. (1992) Simple statistical gradient-following algorithms
  for connectionist reinforcement learning. *Machine Learning*
  8:229–256.
