# Tune parameters for the IFfolk inclusive fitness module

Pre-configures [`search_cmaes()`](search_cmaes.md) or
[`search_map_elites()`](search_map_elites.md) with
[`objective_iffolk()`](objective_iffolk.md) and the key
IFfolk/parliament parameters.

## Usage

``` r
tune_iffolk(
  specs_base = default_specs(),
  n_iterations = 100L,
  method = "cmaes",
  ...
)
```

## Arguments

- specs_base:

  A specs list from [`default_specs()`](default_specs.md).
  `iffolk_selection` and `cooperative_breeding` are set automatically.

- n_iterations:

  Integer (default 100L).

- method:

  Character. `"cmaes"` (default) or `"map_elites"`.

- ...:

  Additional arguments passed to the chosen search function.

## Value

The result of [`search_cmaes()`](search_cmaes.md) or
[`search_map_elites()`](search_map_elites.md).

## See also

[`objective_iffolk()`](objective_iffolk.md),
[`search_viability()`](search_viability.md)

## Examples

``` r
if (FALSE) { # \dontrun{
tuned <- tune_iffolk(default_specs(), n_iterations = 50L)
tuned$specs$iffolk_transfer
} # }
```
