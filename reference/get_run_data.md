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

  A data frame with one row per logged tick and columns: `t`,
  `n_agents`, `n_births`, `n_deaths`, `n_starvations`, `n_age_deaths`,
  `mean_energy`, `sd_energy`, `mean_age`, `sd_age`, `mean_body_size`,
  `sd_body_size`, `genetic_diversity`, `n_species`,
  `mean_cooperation_level`, `mean_immune_strength`,
  `sd_immune_strength`, `mean_metabolic_rate`, `mean_learning_rate`,
  `mean_prior_sigma` (BNN only), `grass_coverage`, `n_infected`,
  `n_new_infections`, `n_altruistic_acts`, `n_shelters_built`.

- `$deaths`:

  A data frame with one row per agent death and columns: `id`, `t`,
  `age`, `energy`, `cause`, `body_size`, `num_offspring`.

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
