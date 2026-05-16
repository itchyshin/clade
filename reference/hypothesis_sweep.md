# Sweep hypothesis conditions across seeds and compute per-run metrics

`hypothesis_sweep()` is the researcher-facing wrapper for the common
simulation workflow surfaced repeatedly in clade's fidelity audits:
define a base spec, vary a small number of parameters across several
conditions, replicate each condition across seeds, and collect summary
metrics from each run's tick log.

## Usage

``` r
hypothesis_sweep(
  base_specs,
  conditions,
  seeds = 1:8,
  metrics = NULL,
  n_cores = 1L,
  verbose = FALSE
)
```

## Arguments

- base_specs:

  A specs list from
  [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md),
  [`fast_specs()`](https://itchyshin.github.io/clade/reference/fast_specs.md),
  [`realistic_specs()`](https://itchyshin.github.io/clade/reference/realistic_specs.md),
  etc. Supplies the template from which each run's spec is derived.

- conditions:

  Named list of conditions. Each element is itself a named list of
  parameter overrides, e.g.
  `list(cost_low = list(signal_cost = 0.0, grass_rate = 0.2))`. The
  names appear in the output as the `condition` column.

- seeds:

  Integer vector of random seeds (default `1:8`). Each condition is
  replicated across all seeds.

- metrics:

  Named list of functions. Each function takes the `ticks` tibble
  returned by
  [`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)
  and returns a length-one scalar (numeric or logical). Defaults collect
  `final_n` (mean n_agents over the last 500 ticks) and `crashed` (a
  logical — whether n_agents fell below 10 at run end). Note: this
  `crashed` flag is *intentionally different* from
  [`viability_report()`](https://itchyshin.github.io/clade/reference/viability_report.md)'s
  `verdict == "crashed"`. The sweep's `crashed` answers "did the
  population effectively go extinct?" (absolute floor of 10 agents);
  [`viability_report()`](https://itchyshin.github.io/clade/reference/viability_report.md)'s
  `crashed` answers "is the run interpretable?" (fractional floor of
  `crashed_frac = 0.2` plus the configurable `min_n = 20L` absolute
  floor with a flat-population bypass). Use
  [`viability_report()`](https://itchyshin.github.io/clade/reference/viability_report.md)
  when you want the interpretability-gate; use the sweep's `crashed`
  metric when you want a per-condition extinction count.

- n_cores:

  Integer. Passed to
  [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md).
  Set as close as possible to `length(conditions) * length(seeds)` to
  keep each worker on one run (subject to your machine's compute limits
  — see CLAUDE.md for per-machine caps).

- verbose:

  Logical. Passed to
  [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md)
  (default FALSE).

## Value

An S3 object of class `"hypothesis_sweep"` — a list with:

- `runs`: tibble with one row per run, columns `condition`, `seed`, plus
  one column per metric.

- `conditions`: the input conditions list (for re-referencing).

- `metrics`: the input metrics list.

- `base_specs`: the input base specs.

- `seeds`: the seeds vector.

- `elapsed`: difftime for the batch run.

The object has a [`print()`](https://rdrr.io/r/base/print.html) method
that summarises per-condition means ± SE across seeds.

## Details

Each condition is a named list of parameter overrides applied on top of
`base_specs`. Conditions are crossed with `seeds` to produce
`length(conditions) * length(seeds)` runs, dispatched via
[`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md).

Metrics are evaluated on each run's `get_run_data(env)$ticks` tibble
(see
[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md))
and must return a scalar or a length-one logical. Common choices — mean
over the last N ticks, peak value, end-of-run value — are illustrated in
the examples.

## See also

[`hypothesis_report()`](https://itchyshin.github.io/clade/reference/hypothesis_report.md),
[`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md),
[`grid_specs()`](https://itchyshin.github.io/clade/reference/grid_specs.md),
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Example: how does grass_rate affect equilibrium population?
specs <- fast_specs()
specs$max_ticks <- 1000L

sweep <- hypothesis_sweep(
  base_specs = specs,
  conditions = list(
    low  = list(grass_rate = 0.05),
    mid  = list(grass_rate = 0.10),
    high = list(grass_rate = 0.20)
  ),
  seeds = 1:8,
  n_cores = 24L
)
print(sweep)  # per-condition summary table

# Test a specific direction:
hypothesis_report(sweep,
                  contrasts = list(food_effect = c("low", "high")),
                  metric = "final_n")
} # }
```
