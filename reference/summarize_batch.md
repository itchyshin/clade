# Summarize a batch of run results into a tidy data frame

Pulls the parameter values from each spec and summary stats from the
corresponding run result into a single row, returning a data frame
suitable for plotting or filtering. Intended as the lightweight
companion to
[`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md)
for parameter-space exploration.

## Usage

``` r
summarize_batch(results, specs_list, param_names = NULL, metrics = NULL)
```

## Arguments

- results:

  A list of `env` objects from
  [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md).

- specs_list:

  The list of specs passed to
  [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md),
  so the parameter values can be recovered. Must have the same length as
  `results`.

- param_names:

  Character vector of spec field names to extract. If `NULL` (default),
  infers them from the first spec by taking every field that differs
  from
  [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md).

- metrics:

  Named list of functions. Each function takes a single `env` and
  returns a scalar numeric. Default metrics: final population size,
  final mean energy, final genetic diversity, viability verdict.

## Value

A data frame with one row per run. Columns: the named parameters, each
metric, and `viability` (the verdict string).

## See also

[`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md),
[`grid_specs()`](https://itchyshin.github.io/clade/reference/grid_specs.md),
[`sample_specs()`](https://itchyshin.github.io/clade/reference/sample_specs.md),
[`viability_report()`](https://itchyshin.github.io/clade/reference/viability_report.md)

## Examples

``` r
if (FALSE) { # \dontrun{
specs_list <- sample_specs(fast_specs(), n = 100L,
                           grass_rate = list(0.05, 0.4))
results <- batch_alife(specs_list, n_cores = 10L)
tbl <- summarize_batch(results, specs_list,
                       param_names = "grass_rate")
plot(tbl$grass_rate, tbl$n_final)
} # }
```
