# Run one specs object with multiple random seeds

`batch_seeds()` is a convenience wrapper around
[`batch_alife()`](batch_alife.md) for the common case of replicating a
single simulation across several random seeds. Each replicate is
identical except for its `random_seed`.

## Usage

``` r
batch_seeds(specs, seeds = 1:5, n_cores = 1L, verbose = FALSE)
```

## Arguments

- specs:

  A specs list from [`default_specs()`](default_specs.md) (or
  [`quick_specs()`](quick_specs.md) / [`full_specs()`](full_specs.md))
  with your modifications. The `random_seed` field is overwritten for
  each replicate.

- seeds:

  Integer vector of seeds to use (default `1:5`).

- n_cores:

  Integer. Number of parallel R workers (default `1L`). Passed to
  [`batch_alife()`](batch_alife.md).

- verbose:

  Logical. Print progress (default `FALSE`).

## Value

A named list of `env` objects, one per seed, named `"seed_1"`,
`"seed_2"`, etc.

## See also

[`batch_alife()`](batch_alife.md),
[`default_specs()`](default_specs.md), [`quick_specs()`](quick_specs.md)

## Examples

``` r
if (FALSE) { # \dontrun{
s <- default_specs()
s$max_ticks <- 300L
results <- batch_seeds(s, seeds = 1:3)
lapply(results, function(e) tail(get_run_data(e)$ticks$mean_energy, 1))
} # }
```
