# Compute linkage disequilibrium from a logged genome time-series

`compute_ld()` is a placeholder. Linkage disequilibrium statistics
(\\D\\, \\D'\\, \\r^2\\; Lewontin & Kojima 1960) require per-tick genome
matrices, which are produced only when `specs$log_genomes = TRUE`. That
logging path is not yet wired through to the R side, so this function
currently returns a stub.

## Usage

``` r
compute_ld(run_data)
```

## Arguments

- run_data:

  A list returned by [`get_run_data()`](get_run_data.md).

## Value

A list with components:

- `$ld`:

  Always `NULL` in the current implementation.

- `$note`:

  Character. Explains that LD computation is not yet available and
  points to the `log_genomes` flag.

## References

Lewontin, R.C. & Kojima, K. (1960) The evolutionary dynamics of complex
polymorphisms. *Evolution* 14(4):458-472.

## See also

[`get_genome_data()`](get_genome_data.md),
[`estimate_heritability()`](estimate_heritability.md)

## Examples

``` r
if (FALSE) { # \dontrun{
env <- run_alife(default_specs())
compute_ld(get_run_data(env))
} # }
```
