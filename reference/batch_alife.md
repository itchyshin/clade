# Run multiple simulations in parallel

`batch_alife()` runs a list of specs across R worker processes. At
`n_cores = 1L` (default), runs are serial via
[`lapply()`](https://rdrr.io/r/base/lapply.html). At `n_cores > 1L`,
runs are distributed across a
[`parallel::makeCluster()`](https://rdrr.io/r/parallel/makeCluster.html)
PSOCK cluster — each worker is a separate R process with its own Julia
session.

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

  Integer. Number of R worker processes to use (default 1L). Each worker
  pays a ~60 s Julia compile cost on its first run; for batches smaller
  than ~20 scenarios, serial may be faster. For 50+ scenarios, the
  speedup is near-linear in `n_cores`, capped by
  [`parallel::detectCores()`](https://rdrr.io/r/parallel/detectCores.html).

- verbose:

  Logical. Print progress (default `FALSE` for batch mode).

## Value

A list of `env` objects, one per element of `specs_list`, in the same
order.

## Details

The PSOCK approach (0.5.6 default) replaces an earlier
[`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html) path
that silently deadlocked: forked R workers shared the parent's
JuliaConnectoR socket and all blocked on the same Julia server.

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
