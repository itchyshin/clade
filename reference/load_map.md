# Load a bundled or saved habitat map

Returns a wall matrix from a bundled `.rds` file in the package's
`inst/maps/` directory (use short name, e.g. `"open"` or `"patchy"`) or
from an arbitrary file path.

## Usage

``` r
load_map(fn)
```

## Arguments

- fn:

  Character; short map name (e.g. `"open"`, `"patchy"`) or the full path
  to a saved `.rds` file.

## Value

An integer matrix (0 = open, 1 = wall).

## See also

[`generate_map()`](https://itchyshin.github.io/clade/reference/generate_map.md),
[`prepare_map()`](https://itchyshin.github.io/clade/reference/prepare_map.md)

## Examples

``` r
if (FALSE) { # \dontrun{
map <- load_map("open")
} # }
```
