# Parameter search — environment-level parameters

Environment-level parameters describe the world the agents live in, not
the agents themselves. They shape primary productivity, spatial
structure, temporal structure, and external selection forces — and they
are typically what gets tuned when you ask “in which world does this
kind of organism thrive?”. For per-organism parameters (traits, brain
architecture, life history, reproduction), see
[ps-agent-parameters.html](https://itchyshin.github.io/clade/articles/ps-agent-parameters.md).

This vignette lists the environment-level parameters by domain, flags
the ones that are only active under an enabling flag, and shows worked
searches — especially
[`search_viability()`](https://itchyshin.github.io/clade/reference/search_viability.md)
for mapping survivable regions before committing to CMA-ES. For the
algorithms themselves, see
[ps-algorithms.html](https://itchyshin.github.io/clade/articles/ps-algorithms.md).

------------------------------------------------------------------------

## Grid and population bookkeeping

| Parameter | Default | Role |
|----|----|----|
| `grid_rows` / `grid_cols` | `30L` each | World dimensions |
| `toroidal` | `TRUE` | Edges wrap; set `FALSE` for bounded invasion fronts (Shine 2011) |
| `n_agents_init` | `50L` | Number of founders |
| `max_agents` | `500L` | Population cap (hard ceiling on reproduction) |
| `max_ticks` | `500L` | Simulation length |

These usually aren’t the parameters you *search* — they’re the ones you
*set* for the experiment. The exception is `max_ticks`: because
simulation cost scales linearly with ticks, the coarse-to-fine search
workflow uses short `max_ticks` values (200–500) for the search and long
`max_ticks` (1000+) for the winning configuration’s final verification.

------------------------------------------------------------------------

## Resources

| Parameter | Default | Role |
|----|----|----|
| `grass_rate` | `0.05` | Per-tick probability an empty cell grows grass |
| `grass_max` | `5.0` | Maximum grass units per cell |
| `grass_init_prob` | `0.5` | Fraction of cells with grass at tick 0 |
| `eat_gain` | `5.0` | Energy per unit of grass eaten |
| `max_bite` | `2.0` | 0.4.0: maximum grass units eaten per tick (handling time; Holling 1959) |
| `energy_init` | `100.0` | Starting energy per agent |
| `energy_max` | `200.0` | Energy cap |

`grass_rate` is the single most consequential environmental parameter.
Low values (0.02–0.05) give a scarce environment that exposes
life-history trade-offs; high values (0.2–0.5) give an abundant
environment where density-dependent effects dominate. Most of the
scenario audits in
[`dev/audit/fidelity/`](https://github.com/itchyshin/clade/tree/main/dev/audit/fidelity)
sweep it explicitly.

`max_bite` is new in 0.4.0. It implements handling time — a rich cell
cannot be stripped in one step. This matters for ecological-release
scenarios: with `max_bite = grass_max`, a forager who finds a rich cell
wins everything; with smaller `max_bite`, the cell sustains multiple
grazings across ticks. See
[kernel-0.4.0.md](https://github.com/itchyshin/clade/blob/main/dev/docs/kernel-0.4.0.md)
for the biology.

------------------------------------------------------------------------

## Temporal and spatial structure

| Parameter | Default | Role |
|----|----|----|
| `seasonal_amplitude` | `0.0` | Amplitude of sinusoidal grass-rate modulation; 0 disables |
| `season_length` | `50L` | Period of the seasonal cycle (ticks) |
| `fixed_patch` | `NULL` | Named list defining a perennially-rich cell (see [`?default_specs`](https://itchyshin.github.io/clade/reference/default_specs.md)) |
| `complex_landscape` | `FALSE` | Enable 3-layer habitat (ground + shrub + canopy) |
| `shrub_density` | `0.3` | Fraction of cells with shrub layer (when `complex_landscape`) |
| `canopy_density` | `0.1` | Fraction of cells with canopy layer (when `complex_landscape`) |
| `shrub_energy` | `3.0` | Energy per unit shrub |
| `canopy_energy` | `5.0` | Energy per unit canopy |
| `shrub_growth_rate` | `0.03` | Shrub-layer regrowth probability |

Complex-landscape parameters are the classic “map this region before you
optimise” case. Many combinations drive the population extinct (too
little productive area, or wrong energy ratios), and CMA-ES cannot
follow a gradient through a dead region. Use
[`search_viability()`](https://itchyshin.github.io/clade/reference/search_viability.md)
first — see [worked example](#viability-mapping) below.

`seasonal_amplitude` interacts multiplicatively with `grass_rate`:
`effective_rate_t = grass_rate × (1 + seasonal_amplitude × sin(2π t / season_length))`.
The signature in `s-seasonal` is a lag-`season_length/2`
anti-correlation in `grass_coverage`.

------------------------------------------------------------------------

## External forces — predators

Predators are agents with their own brains and lineages, but the handful
of parameters that control their *abundance and lethality* are best read
as environmental selection forces on the prey population.

| Parameter | Default | Role |
|----|----|----|
| `n_predators_init` | `0L` | Initial predator count; 0 disables predators entirely |
| `predator_attack_strength` | `40.0` | Damage per attack on prey |
| `predator_energy_gain` | `30.0` | Energy transfer per successful kill |
| `predator_max_agents` | `50L` | Predator population cap |
| `predator_min_repro_energy` | `200.0` | Predator reproduction threshold |

The per-predator traits (`predator_attack_strength`,
`predator_energy_gain`) are closer to agent parameters — see
[ps-agent-parameters.html#cross-links-to-fuzzy-parameters](https://itchyshin.github.io/clade/articles/ps-agent-parameters.html#cross-links-to-fuzzy-parameters).

------------------------------------------------------------------------

## External forces — disease

Disease state (infected/recovered) lives on agents, but transmission
mechanics live in the environment.

| Parameter             | Default | Role                                      |
|-----------------------|---------|-------------------------------------------|
| `disease`             | `FALSE` | Enable SIR module                         |
| `disease_seed_prob`   | `0.02`  | Fraction infected at tick 1               |
| `transmission_prob`   | `0.1`   | Per-contact transmission probability      |
| `disease_duration`    | `10L`   | Ticks of infection before recovery        |
| `immune_duration`     | `20L`   | Ticks of immunity after recovery          |
| `disease_death_prob`  | `0.02`  | Per-tick death probability while infected |
| `disease_energy_cost` | `5.0`   | Per-tick energy drain while infected      |

`transmission_prob` is the R0-equivalent knob. The `s-disease` scenario
audit showed a Spearman ρ = 1.00 dose-response between
`transmission_prob` and epidemic peak — one of the cleanest theoretical
signals in the suite.

------------------------------------------------------------------------

## Worked example: viability mapping

Before running CMA-ES on a parameter region, it is worth mapping the
*viable region* — the set of parameter combinations where the population
doesn’t go extinct.
[`search_viability()`](https://itchyshin.github.io/clade/reference/search_viability.md)
does this in a single call and returns both a heatmap and a tidy data
frame.

``` r

library(clade)

s <- default_specs()
s$complex_landscape <- TRUE

vmap <- search_viability(
  s,
  param_x = "shrub_density",  values_x = seq(0.1, 0.6, by = 0.1),
  param_y = "canopy_density", values_y = seq(0.05, 0.35, by = 0.1),
  n_reps  = 3L
)

vmap$map     # ggplot2 heatmap: green = viable, red = extinct
vmap$data    # data frame with viability, mean_final_pop per cell
```

Once the viable region is identified, run CMA-ES inside it:

``` r

tuned <- tune_complex_landscape(default_specs(), n_iterations = 80L)
tuned$specs          # optimal parameter set
tuned$history$sigma  # step-size decay — smaller sigma = converged
```

[`tune_complex_landscape()`](https://itchyshin.github.io/clade/reference/tune_complex_landscape.md)
is a pre-configured wrapper: it sets five landscape parameters
(`shrub_density`, `canopy_density`, `shrub_energy`, `canopy_energy`,
`shrub_growth_rate`) and uses
[`objective_complex_landscape()`](https://itchyshin.github.io/clade/reference/objective_complex_landscape.md),
which measures the joint increase in wing size, niche diversity, and
survival.

------------------------------------------------------------------------

## Worked example: CMA-ES on resource parameters

When viability isn’t the concern and you just want the single best
resource environment for some biological outcome, CMA-ES on a handful of
continuous environment parameters is cheap:

``` r

result <- search_cmaes(
  specs_base = default_specs(),
  params     = c("grass_rate", "grass_max", "max_bite"),
  objective  = "genetic_diversity",
  n_iterations = 20L,
  popsize      = 10L
)

cat("Best diversity:", result$score, "\n")
print(result$specs[c("grass_rate", "grass_max", "max_bite")])
```

This is the same call pattern as the agent-parameter CMA-ES example; the
only difference is which parameters you pass. The search functions don’t
care about the agent/environment distinction — that distinction is for
you, the experimenter, to keep the conceptual design clean.

------------------------------------------------------------------------

## Worked example: MAP-Elites on seasonality

MAP-Elites is especially useful for temporal-structure parameters
because the *achievable set* of (mean diversity, amplitude of population
oscillation) is inherently two-dimensional.

``` r

result <- search_map_elites(
  specs_base   = default_specs(),
  search_params = list(
    seasonal_amplitude = c(0.0, 1.0),
    season_length      = c(20L, 200L)
  ),
  archive_dims = list(
    genetic_diversity = seq(0, 1, by = 0.1),
    n_agents          = seq(0, 200, by = 20)
  ),
  n_iterations = 300L,
  objective    = "genetic_diversity",
  verbose      = FALSE
)

result$map   # heatmap of achievable niches
```

Reading the heatmap: empty cells are combinations no seasonal regime
achieved. If high-diversity, high-population cells are empty, that
combination may be intrinsically unattainable — seasonality may
*preclude* simultaneous high diversity and high density.

------------------------------------------------------------------------

## Cross-links to fuzzy parameters

Some parameters blur the agent/environment line. They’re listed on the
agent page but their *world-facing* effects are summarised here:

- **Predator abundance** (`n_predators_init`, `predator_max_agents`) —
  determines overall predation pressure on prey, behaves like an
  environmental selection force.
- **Niche-construction effects on grass regrowth** — shelter-building is
  an agent behaviour, but the resulting grass-suppression is an
  environmental consequence searchable via `grass_rate` × `niche_*`
  interactions.
- **Carrion** (`carrion_fraction`, `carrion_decay_rate`) — state of the
  environment created by agent deaths; see
  [ps-agent-parameters.html#cross-links-to-fuzzy-parameters](https://itchyshin.github.io/clade/articles/ps-agent-parameters.html#cross-links-to-fuzzy-parameters).

------------------------------------------------------------------------

## See also

- **[ps-introduction.html](https://itchyshin.github.io/clade/articles/ps-introduction.md)**
  — when to search, which algorithm, how to design an objective
  function.
- **[ps-agent-parameters.html](https://itchyshin.github.io/clade/articles/ps-agent-parameters.md)**
  — traits, brain, life history, reproduction, social behaviour.
- **[ps-algorithms.html](https://itchyshin.github.io/clade/articles/ps-algorithms.md)**
  — full algorithm reference.
- **[`vignette("parameter-reference")`](https://itchyshin.github.io/clade/articles/parameter-reference.md)**
  — exhaustive list of every parameter in
  [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md).
