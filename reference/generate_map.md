# Generate a procedural habitat map

Creates a 0/1 wall matrix for use with [`run_alife()`](run_alife.md).
Five landscape types are available, ranging from completely open to
structured corridor networks. Pass the result to
[`prepare_map()`](prepare_map.md) to validate dimensions before use.

## Usage

``` r
generate_map(
  type = "random_cluster",
  grid_rows = 50L,
  grid_cols = 50L,
  p_wall = 0.3,
  scale = 4,
  corridor_width = 2L,
  seed = NULL
)
```

## Arguments

- type:

  Character; one of `"open"`, `"patchy"`, `"random_cluster"`,
  `"gaussian_field"`, `"corridors"`. Default `"random_cluster"`.

- grid_rows:

  Integer; number of grid rows. Default 50.

- grid_cols:

  Integer; number of grid columns. Default 50.

- p_wall:

  Numeric in (0, 1); target proportion of wall cells. Default 0.3.
  Ignored for `"open"`.

- scale:

  Positive numeric; spatial scale of wall clustering (sigma for
  Gaussian, autocorrelation range for `nlm_gaussianfield`). Default 4.

- corridor_width:

  Integer; open-corridor width in cells (`"corridors"` only). Default 2.

- seed:

  Integer or `NULL`; random seed. Default `NULL`.

## Value

An integer matrix (0 = open, 1 = wall) of dimensions `grid_rows` x
`grid_cols`. Assign to `specs$wall_map` before calling
[`run_alife()`](run_alife.md), or pass to
[`prepare_map()`](prepare_map.md) first.

## Details

Types `"random_cluster"` and `"gaussian_field"` use the `NLMR` package
when installed; otherwise a pure-R Gaussian-smoothed fallback is used.

## See also

[`load_map()`](load_map.md), [`prepare_map()`](prepare_map.md)

## Examples

``` r
map <- generate_map("random_cluster", grid_rows = 20L, grid_cols = 20L,
                    p_wall = 0.25, seed = 1L)
mean(map == 0L)  # fraction open
#> [1] 0.75
```
