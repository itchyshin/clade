# Synonym for run_alife()

`run_clade()` is an alias for
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md),
provided for consistency with the package name.

## Usage

``` r
run_clade(specs = default_specs(), verbose = TRUE)
```

## Arguments

- specs:

  A named list of simulation parameters, typically from
  [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md)
  with modifications. All parameters are documented in
  [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md).

- verbose:

  Logical. Print progress messages (default `TRUE`). Pass `FALSE` for
  batch runs or testing.
