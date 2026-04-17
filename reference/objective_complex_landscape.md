# Objective function for the complex landscape scenario

Measures how well the complex-landscape module is working by combining:
(1) wing size evolution (late mean - early mean), (2) niche diversity
entropy across ground/shrub/canopy layers, and (3) a log-survival bonus.
Returns `-Inf` for extinct populations or runs with fewer than 10 active
ticks, making it safe to pass directly to
[`search_cmaes()`](https://itchyshin.github.io/clade/reference/search_cmaes.md).

## Usage

``` r
objective_complex_landscape(env)
```

## Arguments

- env:

  A `clade_env` object from
  [`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md).

## Value

A numeric scalar. Higher is better; `-Inf` = unviable.

## See also

[`tune_complex_landscape()`](https://itchyshin.github.io/clade/reference/tune_complex_landscape.md),
[`search_cmaes()`](https://itchyshin.github.io/clade/reference/search_cmaes.md)

## Examples

``` r
if (FALSE) { # \dontrun{
s <- default_specs()
s$complex_landscape <- TRUE; s$max_ticks <- 100L
env <- run_alife(s, verbose = FALSE)
objective_complex_landscape(env)
} # }
```
