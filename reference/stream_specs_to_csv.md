# Stream a parameter-space sweep to disk, one row per run

The counterpart to
[`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md) +
[`summarize_batch()`](https://itchyshin.github.io/clade/reference/summarize_batch.md)
for long sweeps: runs each spec in `specs_list`, extracts a scalar
summary per run via `summary_fn`, and appends one CSV row to `out_path`
as each run completes. Two advantages over batching:

## Usage

``` r
stream_specs_to_csv(
  specs_list,
  out_path,
  summary_fn = NULL,
  n_cores = 1L,
  resume = TRUE,
  flush_every = 1L
)
```

## Arguments

- specs_list:

  List of specs.

- out_path:

  Path to the CSV. Created if absent; appended if present. First row is
  always a header.

- summary_fn:

  Function `(env, specs) -> named list or one-row data.frame`. Should
  return the summary stats you want to save per run. Default: viability
  verdict + n_final + mean_energy_final

  - genetic_diversity_final + the run's random_seed and any params that
    differ from
    [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md).

- n_cores:

  Integer. Parallel workers, as in
  [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md).

- resume:

  Logical. If `TRUE` (default) and `out_path` already exists, skip runs
  whose `run_id` is in the existing CSV. Set `FALSE` to overwrite.

- flush_every:

  Integer. How often to flush the CSV to disk (in rows). Default 1
  (flush every row — safest; small I/O cost).

## Value

The path to the CSV (invisibly). Read back with `read.csv(out_path)`.

## Details

- **Memory**: the full `env` object for each run is discarded after the
  summary row is written, so a 1 M-run sweep doesn't accumulate 1 M
  copies of `progress` / `deaths` in RAM.

- **Resumability**: if the job dies at run 800 000 of 1 000 000,
  re-running with the same `out_path` picks up after the last written
  row (matched by the `run_id` column).

## See also

[`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md),
[`sample_specs()`](https://itchyshin.github.io/clade/reference/sample_specs.md),
[`summarize_batch()`](https://itchyshin.github.io/clade/reference/summarize_batch.md)

## Examples

``` r
if (FALSE) { # \dontrun{
specs_list <- sample_specs(fast_specs(), n = 10000L,
  grass_rate  = list(0.05, 0.40),
  mutation_sd = c(0.02, 0.05, 0.10))
stream_specs_to_csv(specs_list, "/tmp/sweep.csv", n_cores = 50L)
tbl <- read.csv("/tmp/sweep.csv")   # even if 10k × 50 B = 500 KB
} # }
```
