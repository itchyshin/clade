# Objective function for the IFfolk inclusive fitness scenario

Measures the linear upward trend in `mean_helper_tendency` (scaled x1000
so CMA-ES gradients are numerically comfortable), plus a per-agent
IFfolk transfer bonus. Returns `-Inf` for extinct runs or fewer than 20
active ticks (insufficient signal for the regression).

## Usage

``` r
objective_iffolk(env)
```

## Arguments

- env:

  A `clade_env` object from [`run_alife()`](run_alife.md).

## Value

A numeric scalar. Higher is better; `-Inf` = unviable.

## See also

[`tune_iffolk()`](tune_iffolk.md), [`search_cmaes()`](search_cmaes.md)

## Examples

``` r
if (FALSE) { # \dontrun{
s <- default_specs()
s$iffolk_selection <- TRUE; s$cooperative_breeding <- TRUE
s$max_ticks <- 200L
env <- run_alife(s, verbose = FALSE)
objective_iffolk(env)
} # }
```
