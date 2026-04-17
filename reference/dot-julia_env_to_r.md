# Convert a Julia env result to an R list

JuliaConnectoR returns Julia structs as named R lists. This function
extracts the fields expected by
[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)
and
[`plot_run()`](https://itchyshin.github.io/clade/reference/plot_run.md).

## Usage

``` r
.julia_env_to_r(env_julia, specs)
```

## Arguments

- env_julia:

  The raw return value from `juliaCall("Clade.run_clade", ...)`.

- specs:

  The specs list used for this run.

## Value

A named R list with fields `$agents`, `$t`, `$specs`, `$progress`,
`$deaths`, `$genome_log`.
