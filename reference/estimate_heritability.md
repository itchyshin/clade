# Estimate narrow-sense heritability from a logged trait time-series

`estimate_heritability()` returns a coarse estimate of narrow-sense
heritability (\\h^2\\) for a quantitative trait that has been logged
once per tick by
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md).
The estimator is the lag-1 temporal autocorrelation of the population
mean, \$\$\hat{h}^2 \approx \mathrm{cor}(\bar{z}\_t,\\
\bar{z}\_{t+1}),\$\$ which is used here as a *proxy* for the
parent-offspring regression (Falconer & Mackay 1996, ch. 10). The proxy
is reasonable when (i) the trait is under directional or stabilising
selection, (ii) generation overlap is moderate, and (iii) the logging
interval is short relative to the generation time. It is **not** an
exact quantitative-genetic estimate and should not be reported as one.
An exact estimate requires parent-offspring pairs, which clade does not
currently log.

## Usage

``` r
estimate_heritability(run_data, trait = "body_size")
```

## Arguments

- run_data:

  A list returned by
  [`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)
  (must contain `$ticks` with the column `paste0("mean_", trait)`).

- trait:

  Character. The trait name (without the `mean_` prefix). Defaults to
  `"body_size"`. Any column of the form `mean_<trait>` in
  `run_data$ticks` is supported (e.g. `"immune_strength"`,
  `"metabolic_rate"`, `"learning_rate"`).

## Value

A list with components:

- `$h2`:

  Numeric. Lag-1 autocorrelation of `mean_<trait>`. Returns `NA_real_`
  if the series has fewer than three usable values or zero variance.

- `$method`:

  Character constant `"lag1_autocorrelation"`.

- `$trait`:

  The trait name supplied by the caller.

- `$n`:

  Integer. Number of paired observations used.

- `$note`:

  Character. A reminder that this is a proxy and that an exact estimate
  requires parent-offspring logging.

Note that clade also exports
[`heritability_estimate()`](https://itchyshin.github.io/clade/reference/heritability_estimate.md)
— a different function that computes h^2 by parent-offspring regression
on `get_run_data(env)$deaths` (the agent-death log), and so requires
that agents have died with recorded `parent_id` and the trait of
interest. `estimate_heritability()` is the population-level
autocorrelation proxy (works on any logged trait series);
[`heritability_estimate()`](https://itchyshin.github.io/clade/reference/heritability_estimate.md)
is the individual-level regression (requires the deaths data frame).

## References

Falconer, D.S. & Mackay, T.F.C. (1996) *Introduction to Quantitative
Genetics*, 4th ed. Longman, Harlow.

## See also

[`heritability_estimate()`](https://itchyshin.github.io/clade/reference/heritability_estimate.md)
for the parent-offspring regression approach.
[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md),
[`compute_ld()`](https://itchyshin.github.io/clade/reference/compute_ld.md),
[`species_tree()`](https://itchyshin.github.io/clade/reference/species_tree.md).

## Examples

``` r
if (FALSE) { # \dontrun{
env  <- run_alife(default_specs())
rd   <- get_run_data(env)
estimate_heritability(rd, trait = "body_size")
estimate_heritability(rd, trait = "immune_strength")
} # }
```
