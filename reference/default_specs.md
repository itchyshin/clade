# Default simulation parameters for clade

Returns a named list of all simulation parameters with type-annotated
defaults. Every parameter is documented below. Pass a modified copy to
[`run_alife()`](run_alife.md) or
[`search_map_elites()`](search_map_elites.md).

## Usage

``` r
default_specs()
```

## Value

A named list of simulation parameters.

## Details

## See also

[`run_alife()`](run_alife.md), [`get_run_data()`](get_run_data.md),
[`search_map_elites()`](search_map_elites.md)

## Examples

``` r
specs <- default_specs()
specs$brain_type   <- "bnn"
specs$ploidy       <- 2L
specs$n_agents_init <- 100L
# run_alife(specs)   # requires Julia
```
