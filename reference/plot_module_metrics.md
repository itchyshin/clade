# Plot module-specific metrics from a clade simulation run

Detects which optional simulation modules were active during a run by
inspecting the logged tick columns in `run_data$ticks`, then assembles
up to six panels into a patchwork grid. Only panels for modules that
produced non-zero data are included:

- Predators:

  `n_predators` – line plot of predator population over time.

- Species:

  `n_species` – step plot of species count; shown only when speciation
  was active (max \> 1).

- Traits:

  Overlay of `mean_toxicity`, `mean_plasticity`, and
  `mean_helper_tendency` as three coloured lines.

- Signals:

  `mean_signal_magnitude` – line plot; shown only when signal evolution
  was active (max \> 0).

- Parental care:

  `n_juveniles` – line plot of juveniles under care; shown only when max
  \> 0.

- Mimicry:

  `n_toxic_attacks` and `n_avoided_attacks` – two lines showing attacks
  versus avoidance events; shown only when mimicry attacks occurred (max
  n_toxic_attacks \> 0).

If fewer than two panels are active, a single informative placeholder
plot is returned instead.

## Usage

``` r
plot_module_metrics(run_data)
```

## Arguments

- run_data:

  A list as returned by
  [`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md).
  Must contain a `$ticks` data frame. The new module columns
  (`n_predators`, `n_helpers`, `mean_signal_magnitude`, `mean_toxicity`,
  `mean_plasticity`, `mean_helper_tendency`, `n_species`, `n_juveniles`,
  `n_toxic_attacks`, `n_avoided_attacks`) are used when present; absent
  columns are silently skipped.

## Value

A
[`patchwork::wrap_plots()`](https://patchwork.data-imaginist.com/reference/wrap_plots.html)
object with up to six panels arranged in at most three columns, or a
single
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
placeholder when fewer than two panels are active.

## Details

Plot module-specific metrics from a clade simulation run

## See also

[`plot_run()`](https://itchyshin.github.io/clade/reference/plot_run.md),
[`visualize_progress()`](https://itchyshin.github.io/clade/reference/visualize_progress.md),
[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)

## Examples

``` r
if (FALSE) { # \dontrun{
specs <- default_specs()
specs$n_predators_init  <- 10L
specs$mimicry           <- TRUE
env  <- run_clade(specs)
data <- get_run_data(env)
plot_module_metrics(data)
} # }
```
