# Plot genetic diversity over the run

Draws the trajectory of mean pairwise genome distance (genetic
diversity) and, when body-size evolution is active, the coefficient of
variation of body size as a proxy for phenotypic diversity. All series
are scaled to the same 0-1 range for visual comparison.

A common pattern is high diversity in the founders, a selective sweep
that reduces diversity as the best foraging strategy spreads, then a
partial recovery as the population niches. Permanent low diversity
indicates genetic drift or clonal selection; permanently high diversity
indicates balancing selection or frequency-dependent dynamics.

## Usage

``` r
plot_diversity(run_data)
```

## Arguments

- run_data:

  A list returned by [`get_run_data()`](get_run_data.md). Must contain a
  `$ticks` data frame with at minimum `t`, `n_agents`, and
  `genetic_diversity`.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Details

Plot genetic diversity over the run

## See also

[`plot_genome_diversity()`](plot_genome_diversity.md),
[`visualize_progress()`](visualize_progress.md)

## Examples

``` r
if (FALSE) { # \dontrun{
env  <- run_clade(default_specs())
data <- get_run_data(env)
plot_diversity(data)
} # }
```
