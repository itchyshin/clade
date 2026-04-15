# Grid-search parameter viability: which combinations allow population survival?

Runs a grid of parameter combinations and measures the fraction of
replicates in which the population survives to the end of the
simulation. Returns both a data frame and a ggplot2 heatmap so you can
quickly identify the "viable region" of parameter space before running
CMA-ES or MAP-Elites inside it.

## Usage

``` r
search_viability(
  specs_base,
  param_x,
  values_x,
  param_y = NULL,
  values_y = NULL,
  n_reps = 3L,
  survival_threshold = 0.1,
  objective = NULL,
  verbose = TRUE
)
```

## Arguments

- specs_base:

  A specs list from [`default_specs()`](default_specs.md).

- param_x:

  Character. Name of the first parameter to vary.

- values_x:

  Numeric vector of values to test for `param_x`.

- param_y:

  Character or `NULL`. Optional second parameter (creates a 2D grid when
  supplied).

- values_y:

  Numeric vector of values for `param_y`. Ignored if `param_y = NULL`.

- n_reps:

  Integer. Replicates per grid cell (different random seeds; default
  3L).

- survival_threshold:

  Numeric. Fraction of initial agents that must survive for a run to
  count as viable (default 0.1).

- objective:

  Character or function or `NULL`. If supplied, the mean objective score
  across surviving replicates is added as column `mean_objective`
  (default `NULL`).

- verbose:

  Logical (default `TRUE`).

## Value

A list with:

- `$data`:

  Data frame with columns `param_x`, optionally `param_y`, `viability`
  (fraction surviving), `mean_final_pop`, and optionally
  `mean_objective`.

- `$map`:

  A ggplot2 tile/line plot coloured by viability.

## Details

This directly answers the question "which parameters allow organisms to
evolve?" without requiring CMA-ES to converge first.

## See also

[`search_cmaes()`](search_cmaes.md),
[`tune_complex_landscape()`](tune_complex_landscape.md)

## Examples

``` r
if (FALSE) { # \dontrun{
s <- default_specs()
s$complex_landscape <- TRUE
vm <- search_viability(
  s,
  param_x = "shrub_density",  values_x = seq(0.1, 0.5, 0.1),
  param_y = "canopy_density", values_y = seq(0.05, 0.3, 0.1),
  n_reps  = 3L
)
vm$map          # heatmap
vm$data         # raw viability fractions
} # }
```
