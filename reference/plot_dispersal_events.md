# Plot natal dispersal events over time

Draws the count of natal dispersal moves per tick as a bar chart
overlaid with a smoothed trend line. Each bar represents the number of
agents that moved away from their birthplace during that tick. When
`dispersal_evolution = FALSE` all bars are zero.

## Usage

``` r
plot_dispersal_events(run_data)
```

## Arguments

- run_data:

  A list returned by
  [`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md).
  Must contain a `$ticks` data frame with columns `t` and
  `n_dispersal_events`.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object, or `NULL` invisibly when the dispersal column is absent.

## Details

Plot natal dispersal events over time

## See also

[`plot_run()`](https://itchyshin.github.io/clade/reference/plot_run.md),
[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)

## Examples

``` r
if (FALSE) { # \dontrun{
specs <- default_specs(); specs$dispersal_evolution <- TRUE
env   <- run_clade(specs)
data  <- get_run_data(env)
plot_dispersal_events(data)
} # }
```
