# Plot genetic diversity over time

Draws the trajectory of the mean pairwise genome distance logged by
[`get_run_data()`](get_run_data.md). When `specs$speciation = TRUE` the
maximum observed `n_species` is annotated in the upper-left corner.

## Usage

``` r
plot_genome_diversity(run_data)
```

## Arguments

- run_data:

  A list returned by [`get_run_data()`](get_run_data.md). Must contain a
  `$ticks` data frame with at minimum `t` and `genetic_diversity`.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Details

Plot genetic diversity over time

## See also

[`plot_run()`](plot_run.md), [`get_run_data()`](get_run_data.md)

## Examples

``` r
if (FALSE) { # \dontrun{
env  <- run_clade(default_specs())
data <- get_run_data(env)
plot_genome_diversity(data)
} # }
```
