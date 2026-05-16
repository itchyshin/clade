# Extract simulation results as tidy data frames

`get_run_data()` converts the raw environment list returned by
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)
into a list of two tidy data frames:

- `$ticks` – one row per logged tick, with population-level statistics.

- `$deaths` – one row per agent death, with individual-level records.

## Usage

``` r
get_run_data(env)
```

## Arguments

- env:

  An environment list returned by
  [`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md).

## Value

A list with components:

- `$ticks`:

  A data frame with one row per logged tick and ~60 population-level
  columns. Core columns always present: `t`, `n_agents`, `n_births`,
  `n_deaths`, `n_starvations`, `n_age_deaths`, `mean_energy`,
  `sd_energy`, `mean_age`, `sd_age`, `mean_body_size`, `sd_body_size`,
  `genetic_diversity`, `n_species`, `grass_coverage`. Module-specific
  columns are present as zeros when the corresponding module is disabled
  (so the data frame shape is stable across specs), including
  `mean_cooperation_level`, `mean_immune_strength`,
  `sd_immune_strength`, `mean_metabolic_rate`, `mean_learning_rate`,
  `mean_prior_sigma` (BNN only), `n_infected`, `n_new_infections`,
  `n_altruistic_acts`, `n_shelters_built`, `n_predators`,
  `n_prey_killed`, `n_juveniles`, `n_helpers`, `mean_signal_magnitude`,
  `mean_preference_magnitude`, `mean_signal_preference_dist`,
  `sd_signal_magnitude`, `mean_toxicity`, `mean_plasticity`,
  `mean_helper_tendency`, `mean_habitat_preference`, `mean_brain_size`,
  `n_ground_agents`, `n_shrub_agents`, `n_canopy_agents`,
  `mean_wing_size`, `n_front_agents`, `mean_front_dispersal`,
  `n_iffolk_transfers`, `mean_relatedness`, `n_scavenge_events`,
  `n_gd_events`, `mean_shelter_depth`, `mean_mutation_rate`,
  `mean_clutch_size`, `mean_ann_weight_magnitude`. The authoritative
  full list is in `inst/julia/src/logging.jl::_init_progress`; use
  `colnames(get_run_data(env)$ticks)` to see every column for a specific
  run.

- `$deaths`:

  A data frame with one row per agent death and columns: `id`, `t`,
  `age`, `energy`, `cause`, `body_size`, `num_offspring`.

- `$genomes`:

  A long data frame with one row per (tick, agent) and columns `t`,
  `agent_id`, `trait_1`..`trait_N`. `NULL` unless
  `specs$log_genomes = TRUE` was set for the run. Consumed by
  [`plot_tsne_genomes()`](https://itchyshin.github.io/clade/reference/plot_tsne_genomes.md).

## See also

[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md),
[`plot_run()`](https://itchyshin.github.io/clade/reference/plot_run.md)

## Examples

``` r
if (FALSE) { # \dontrun{
env  <- run_alife(default_specs())
data <- get_run_data(env)
head(data$ticks)
hist(data$deaths$age, main = "Age at death")
} # }
```
