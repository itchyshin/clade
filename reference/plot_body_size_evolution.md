# Plot body-size evolution over time

Draws the trajectory of mean body size with a +/- 1 SD ribbon. When
`body_size_evolution = FALSE` this produces a flat line at 1.0. When
evolution is active the population mean drifts toward a size that
balances metabolic cost against foraging gain (the metabolic optimum;
Kleiber 1947).

## Usage

``` r
plot_body_size_evolution(run_data)
```

## Arguments

- run_data:

  A list returned by [`get_run_data()`](get_run_data.md). Must contain a
  `$ticks` data frame with columns `t`, `mean_body_size`, and
  `sd_body_size`.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object, or `NULL` invisibly when body-size data are absent.

## Details

Plot body-size evolution over time

## References

Kleiber, M. (1947) Body size and metabolic rate. *Physiological Reviews*
27(4):511–541.

## See also

[`plot_run()`](plot_run.md), [`get_run_data()`](get_run_data.md)

## Examples

``` r
if (FALSE) { # \dontrun{
specs <- default_specs(); specs$body_size_evolution <- TRUE
env   <- run_clade(specs)
data  <- get_run_data(env)
plot_body_size_evolution(data)
} # }
```
