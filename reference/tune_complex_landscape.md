# Tune parameters for the complex landscape module

Pre-configures
[`search_cmaes()`](https://itchyshin.github.io/clade/reference/search_cmaes.md)
or
[`search_map_elites()`](https://itchyshin.github.io/clade/reference/search_map_elites.md)
with biologically sensible parameters and the
[`objective_complex_landscape()`](https://itchyshin.github.io/clade/reference/objective_complex_landscape.md)
objective for the complex landscape (forest) module. Call this instead
of configuring CMA-ES manually.

## Usage

``` r
tune_complex_landscape(
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
  `complex_landscape` and `wing_size_init_mean` are set automatically.

- n_iterations:

  Integer. Number of CMA-ES generations or MAP-Elites iterations
  (default 100L).

- method:

  Character. `"cmaes"` (default) or `"map_elites"`.

- ...:

  Additional arguments passed to
  [`search_cmaes()`](https://itchyshin.github.io/clade/reference/search_cmaes.md)
  or
  [`search_map_elites()`](https://itchyshin.github.io/clade/reference/search_map_elites.md).

## Value

The result of
[`search_cmaes()`](https://itchyshin.github.io/clade/reference/search_cmaes.md)
or
[`search_map_elites()`](https://itchyshin.github.io/clade/reference/search_map_elites.md).

## See also

[`objective_complex_landscape()`](https://itchyshin.github.io/clade/reference/objective_complex_landscape.md),
[`search_viability()`](https://itchyshin.github.io/clade/reference/search_viability.md)

## Examples

``` r
if (FALSE) { # \dontrun{
tuned <- tune_complex_landscape(default_specs(), n_iterations = 50L)
tuned$specs    # optimal parameter set
tuned$history  # score over generations
} # }
```
