# Tune parameters for the spatial sorting module

Pre-configures
[`search_cmaes()`](https://itchyshin.github.io/clade/reference/search_cmaes.md)
or
[`search_map_elites()`](https://itchyshin.github.io/clade/reference/search_map_elites.md)
with
[`objective_spatial_sorting()`](https://itchyshin.github.io/clade/reference/objective_spatial_sorting.md)
and the key dispersal/sorting parameters.

## Usage

``` r
tune_spatial_sorting(
  specs_base = default_specs(),
  n_iterations = 100L,
  method = "cmaes",
  ...
)
```

## Arguments

- specs_base:

  A specs list from
  [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md).
  `dispersal_evolution` and `spatial_sorting` are set automatically.

- n_iterations:

  Integer (default 100L).

- method:

  Character. `"cmaes"` (default) or `"map_elites"`.

- ...:

  Additional arguments passed to the chosen search function.

## Value

The result of
[`search_cmaes()`](https://itchyshin.github.io/clade/reference/search_cmaes.md)
or
[`search_map_elites()`](https://itchyshin.github.io/clade/reference/search_map_elites.md).

## See also

[`objective_spatial_sorting()`](https://itchyshin.github.io/clade/reference/objective_spatial_sorting.md),
[`search_viability()`](https://itchyshin.github.io/clade/reference/search_viability.md)

## Examples

``` r
if (FALSE) { # \dontrun{
tuned <- tune_spatial_sorting(default_specs(), n_iterations = 50L)
tuned$specs$sorting_mating_boost
} # }
```
