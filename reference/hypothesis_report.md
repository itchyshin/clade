# Compute contrast tests from a hypothesis_sweep

`hypothesis_report()` produces t-tests (Welch, two-sample) for named
pairwise contrasts drawn from a
[`hypothesis_sweep()`](https://itchyshin.github.io/clade/reference/hypothesis_sweep.md)
result. The conventional behavioural-ecology audit pattern is to name a
contrast with a direction-of-effect question ("does parental care reduce
population variance?") and report `Δ ± SE` and `t` across seeds.

## Usage

``` r
hypothesis_report(sweep, contrasts, metric = NULL)
```

## Arguments

- sweep:

  A `hypothesis_sweep` object from
  [`hypothesis_sweep()`](https://itchyshin.github.io/clade/reference/hypothesis_sweep.md).

- contrasts:

  Named list of pairwise contrasts. Each element is a length-two
  character vector `c(reference, test)` naming conditions present in
  `sweep$conditions`.

- metric:

  Character. Name of the metric column in `sweep$runs` to test. Defaults
  to the first metric.

## Value

An S3 `"hypothesis_report"` object — a list with `table` (a data frame
of contrast statistics) and `metric` (the metric name). Has a
[`print()`](https://rdrr.io/r/base/print.html) method that renders the
table.

## Details

Each contrast is a length-two character vector specifying
`c(reference_condition, test_condition)`. The reported delta is
`mean(test) − mean(reference)` on the chosen metric; the interpretation
of the sign is left to the caller.

The verdict column uses the 2σ threshold convention shared across
clade's fidelity audits: `|t| >= 2` → **PASS**, `1.5 <= |t| < 2` →
**marginal**, otherwise → **null**. This is a screening heuristic, not a
formal hypothesis test — report the underlying statistic in
publications.

## See also

[`hypothesis_sweep()`](https://itchyshin.github.io/clade/reference/hypothesis_sweep.md)

## Examples

``` r
if (FALSE) { # \dontrun{
sweep <- hypothesis_sweep(...)
hypothesis_report(sweep,
                  contrasts = list(
                    food_effect = c("low", "high"),
                    cost_under_stress = c("cost0_stress", "cost1_stress")
                  ),
                  metric = "final_n")
} # }
```
