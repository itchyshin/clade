# Compare evolutionary outcomes across simulation conditions

Takes a named list of `run_data` objects (one per condition) and
computes post-burn-in means and standard deviations for key outcome
metrics. Returns a tidy data frame for downstream analysis or plotting.

Metrics included (when present in all runs): `n_agents`,
`genetic_diversity`, `mean_energy`, `n_births`, `n_deaths`,
`grass_coverage`, `n_species`, `mean_body_size`, `mean_toxicity`,
`mean_plasticity`, `n_predators`.

## Usage

``` r
compare_conditions(conditions, burn_in = 100L, plot = TRUE)
```

## Arguments

- conditions:

  A named list of `run_data` objects, each from
  [`get_run_data()`](get_run_data.md). Names are used as condition
  labels.

- burn_in:

  Integer. Ticks to discard as burn-in (default `100L`).

- plot:

  Logical. If `TRUE`, returns a ggplot2 bar-chart comparison. If
  `FALSE`, returns only the summary data frame.

## Value

A data frame with one row per condition and columns `condition`, then
mean and SD columns for each outcome metric (e.g. `genetic_diversity`,
`genetic_diversity_sd`). If `plot = TRUE`, a `$plot` attribute is also
attached.

## Details

Compare evolutionary outcomes across simulation conditions

## See also

[`get_run_data()`](get_run_data.md),
[`estimate_heritability()`](estimate_heritability.md),
[`run_alife()`](run_alife.md)

## Examples

``` r
if (FALSE) { # \dontrun{
s1 <- default_specs(); s1$mutation_sd <- 0.05
s2 <- default_specs(); s2$mutation_sd <- 0.30
env1 <- run_alife(s1); env2 <- run_alife(s2)
result <- compare_conditions(list(low_mut = get_run_data(env1),
                                  hi_mut  = get_run_data(env2)))
result
} # }
```
