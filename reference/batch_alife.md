# Run multiple simulations in parallel

`batch_alife()` runs a list of specs in parallel, distributing across
Julia threads (via `Threads.@threads`) if more than one thread is
available, and additionally across R worker processes via the `parallel`
package.

## Usage

``` r
batch_alife(specs_list, n_cores = 1L, verbose = FALSE)
```

## Arguments

- specs_list:

  A list of specs lists. Each element is passed to
  [`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)
  independently.

- n_cores:

  Integer. Number of R worker processes to use (default 1L). When `> 1`,
  uses
  [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html) on
  Unix/macOS or
  [`parallel::parLapply()`](https://rdrr.io/r/parallel/clusterApply.html)
  on Windows.

- verbose:

  Logical. Print progress (default `FALSE` for batch mode).

## Value

A list of `env` objects, one per element of `specs_list`, in the same
order.

## See also

[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md),
[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)

## Examples

``` r
if (FALSE) { # \dontrun{
specs_list <- lapply(c(0.05, 0.1, 0.2), function(gr) {
  s <- default_specs()
  s$grass_rate <- gr
  s
})
results <- batch_alife(specs_list, n_cores = 3L)
} # }
```
