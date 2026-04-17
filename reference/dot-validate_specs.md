# Validate a specs list before sending to Julia

Checks types and value ranges for key parameters. Errors early in R
rather than letting Julia produce a cryptic stack trace.

## Usage

``` r
.validate_specs(specs)
```

## Arguments

- specs:

  A specs list from
  [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md).

## Value

Invisibly `TRUE` if all checks pass.
