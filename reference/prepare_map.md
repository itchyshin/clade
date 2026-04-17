# Validate and resize a habitat map

Checks that a wall matrix has the correct dimensions for a given specs
list. If dimensions differ, the map is rescaled via nearest-neighbour
resampling and a warning is issued. Values are coerced to 0/1 integer.

## Usage

``` r
prepare_map(map, specs)
```

## Arguments

- map:

  Integer or numeric matrix; a raw wall matrix.

- specs:

  Named list; simulation parameters from
  [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md).
  Used for dimension checking (`$grid_rows`, `$grid_cols`).

## Value

An integer matrix of dimensions `specs$grid_rows` x `specs$grid_cols`
with values 0 or 1.

## See also

[`generate_map()`](https://itchyshin.github.io/clade/reference/generate_map.md),
[`load_map()`](https://itchyshin.github.io/clade/reference/load_map.md)

## Examples

``` r
specs   <- default_specs()
specs$grid_rows <- 20L; specs$grid_cols <- 20L
raw_map <- matrix(0L, nrow = 20L, ncol = 20L)
raw_map[1L, ] <- 1L; raw_map[20L, ] <- 1L
map <- prepare_map(raw_map, specs)
sum(map)   # number of wall cells
#> [1] 40
```
