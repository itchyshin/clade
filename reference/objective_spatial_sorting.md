# Objective function for the spatial sorting scenario

Measures dispersal divergence between front and rear agents over the
last 20% of active ticks. Returns `-Inf` for extinct runs, `-1.0` when
the front represents fewer than 2% of the population (no meaningful
invasion front).

## Usage

``` r
objective_spatial_sorting(env)
```

## Arguments

- env:

  A `clade_env` object from
  [`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md).

## Value

A numeric scalar. Higher is better; `-Inf` = unviable.

## See also

[`tune_spatial_sorting()`](https://itchyshin.github.io/clade/reference/tune_spatial_sorting.md),
[`search_cmaes()`](https://itchyshin.github.io/clade/reference/search_cmaes.md)

## Examples

``` r
if (FALSE) { # \dontrun{
s <- default_specs()
s$dispersal_evolution <- TRUE; s$spatial_sorting <- TRUE
s$max_ticks <- 200L
env <- run_alife(s, verbose = FALSE)
objective_spatial_sorting(env)
} # }
```
