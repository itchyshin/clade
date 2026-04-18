# Plot evolution of mean signal magnitude over ticks

Draws `mean_signal_magnitude` as a function of tick `t`. Useful for the
`s-signals` scenario under sexual selection, where the signal amplitude
is expected to grow from its init value when
`mate_choice_mode = "preference"` and `signal_cost > 0`.

## Usage

``` r
plot_signal_evolution(run_data)
```

## Arguments

- run_data:

  A list returned by
  [`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md).
  Must contain a `$ticks` data frame with `t` and
  `mean_signal_magnitude` columns.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object. Returns an empty-state plot if the column is missing (scenario
didn't log signals) or all zero.

## See also

[`plot_run()`](https://itchyshin.github.io/clade/reference/plot_run.md),
[`plot_diversity()`](https://itchyshin.github.io/clade/reference/plot_diversity.md)

## Examples

``` r
if (FALSE) { # \dontrun{
s <- default_specs()
s$signal_dims <- 3L
s$mate_choice_mode <- "preference"
env <- run_alife(s)
plot_signal_evolution(get_run_data(env))
} # }
```
