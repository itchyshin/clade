# Generate a SLURM array-job template for a parameter-space sweep

Writes two files that together let you fan a clade sweep across a SLURM
cluster: an `.rds` with the full specs_list, and a shell script that
calls `Rscript -e 'clade::stream_specs_to_csv(...)'` for a subset of
specs per array task. You run the sweep yourself with
`sbatch <script>.sh` — this function does not talk to SLURM.

## Usage

``` r
submit_sweep_slurm(
  specs_list,
  out_path,
  script_path,
  rds_path,
  n_array_tasks = min(100L, length(specs_list)),
  n_cores_per_task = 4L,
  time = "06:00:00",
  mem = "8G",
  summary_fn = NULL,
  R_library_path = NULL,
  extra_sbatch_lines = character(0)
)
```

## Arguments

- specs_list:

  List of specs (e.g. from
  [`sample_specs()`](https://itchyshin.github.io/clade/reference/sample_specs.md)).

- out_path:

  Character. Path on the cluster filesystem where the CSV will be
  appended to. Must be reachable from every node.

- script_path:

  Character. Local path where the `.sh` file is written.

- rds_path:

  Character. Local path where the `.rds` of `specs_list` is written.
  Cluster nodes need to be able to read this path; for a shared
  filesystem just put it somewhere the cluster can see.

- n_array_tasks:

  Integer. Number of SLURM array tasks. Each gets
  `ceiling(length(specs_list) / n_array_tasks)` specs. Default:
  `min(100, length(specs_list))`.

- n_cores_per_task:

  Integer. `n_cores` passed to
  [`stream_specs_to_csv()`](https://itchyshin.github.io/clade/reference/stream_specs_to_csv.md)
  within each array task. Default 4L.

- time:

  Character. SLURM `--time` value (e.g. `"06:00:00"`).

- mem:

  Character. SLURM `--mem` value (e.g. `"8G"`).

- summary_fn:

  Optional summary function, same as
  [`stream_specs_to_csv()`](https://itchyshin.github.io/clade/reference/stream_specs_to_csv.md).
  If `NULL` (default), the default summary is used on the cluster side.

- R_library_path:

  Optional character. Added to
  [`.libPaths()`](https://rdrr.io/r/base/libPaths.html) on the cluster
  node via `.libPaths(c("<path>", .libPaths()))` before
  [`library(clade)`](https://itchyshin.github.io/clade/). Useful when
  clade is installed in a non-standard location on the cluster.

- extra_sbatch_lines:

  Character vector of extra `#SBATCH` directives (without the leading
  `#SBATCH`) to include in the script preamble.

## Value

The path to the generated shell script (invisibly), with a message
showing the `sbatch` command to invoke.

## Details

Per-task behaviour: reads `SLURM_ARRAY_TASK_ID` from the environment,
selects the corresponding slice of the specs_list, and appends summary
rows to the shared `out_path` CSV. Because
[`stream_specs_to_csv()`](https://itchyshin.github.io/clade/reference/stream_specs_to_csv.md)
is resume-safe, re-running any array task is idempotent — useful if some
jobs get preempted.

## See also

[`stream_specs_to_csv()`](https://itchyshin.github.io/clade/reference/stream_specs_to_csv.md),
[`sample_specs()`](https://itchyshin.github.io/clade/reference/sample_specs.md)

## Examples

``` r
if (FALSE) { # \dontrun{
specs_list <- sample_specs(fast_specs(), n = 100000L,
                           grass_rate  = list(0.05, 0.45),
                           mutation_sd = c(0.05, 0.1, 0.2))
submit_sweep_slurm(
  specs_list,
  out_path     = "/shared/sweeps/big_sweep.csv",
  script_path  = "/shared/sweeps/submit.sh",
  rds_path     = "/shared/sweeps/specs.rds",
  n_array_tasks = 200L,
  n_cores_per_task = 8L,
  time         = "12:00:00",
  mem          = "16G")
# then: sbatch /shared/sweeps/submit.sh
} # }
```
