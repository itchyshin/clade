# Visualise the multi-trait diversity landscape

Creates a faceted time-series showing the evolution of multiple
heritable trait means plus/minus one standard deviation across ticks.
Each facet corresponds to one trait. Only traits that are present in
`run_data$ticks` and have non-zero variance across the run are shown.
When SD columns exist (e.g. `sd_body_size` for `mean_body_size`) a
shaded ribbon is drawn around the mean trajectory.

## Usage

``` r
diversity_landscape(run_data, traits = NULL)
```

## Arguments

- run_data:

  A list from [`get_run_data()`](get_run_data.md). Must contain a
  `$ticks` data frame with a `t` column and at least one `mean_*` trait
  column.

- traits:

  Character vector of `mean_*` column names to plot. `NULL` (default)
  auto-detects from the standard set of trait columns.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
faceted plot object.

## Details

Visualise the multi-trait diversity landscape

## See also

[`plot_run()`](plot_run.md),
[`plot_module_metrics()`](plot_module_metrics.md)

## Examples

``` r
if (FALSE) { # \dontrun{
env  <- run_clade(default_specs())
data <- get_run_data(env)
diversity_landscape(data)
} # }
```
