# Dashboard plot summarising a clade simulation run

Constructs a 2x3 patchwork grid of time-series diagnostics from the
output of
[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md):
population size, mean energy with variability ribbon, genetic diversity,
births vs deaths per tick, grass coverage, and a sixth panel that
switches between body size (ANN brain) and BNN prior sigma (the Baldwin
Effect panel; Baldwin 1896, Hinton & Nowlan 1987) depending on the
active brain type.

## Usage

``` r
plot_run(run_data, ...)
```

## Arguments

- run_data:

  A list as returned by
  [`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md).
  Must contain a `$ticks` data frame with columns `t`, `n_agents`,
  `mean_energy`, `sd_energy`, `genetic_diversity`, `n_births`,
  `n_deaths`, `grass_coverage`, `mean_body_size`, and
  `mean_prior_sigma`.

- ...:

  Currently unused. Reserved for future plotting options.

## Value

A
[`patchwork::wrap_plots()`](https://patchwork.data-imaginist.com/reference/wrap_plots.html)
object composed of six ggplot panels.

## Details

Dashboard plot summarising a clade simulation run

## References

Baldwin, J.M. (1896) A new factor in evolution. *American Naturalist*
30(354):441–451. Hinton, G.E. & Nowlan, S.J. (1987) How learning can
guide evolution. *Complex Systems* 1(3):495–502.

## See also

[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md),
[`plot_environment()`](https://itchyshin.github.io/clade/reference/plot_environment.md),
[`plot_genome_diversity()`](https://itchyshin.github.io/clade/reference/plot_genome_diversity.md)

## Examples

``` r
if (FALSE) { # \dontrun{
env  <- run_clade(default_specs())
data <- get_run_data(env)
plot_run(data)
} # }
```
