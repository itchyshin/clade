# Estimate narrow-sense heritability from parent-offspring data

`heritability_estimate()` computes h2 by regressing offspring trait
values on parent trait values using the `$deaths` data frame returned by
[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md).
This is the parent-offspring regression method, as distinct from the
lag-1 autocorrelation approach used by
[`estimate_heritability()`](https://itchyshin.github.io/clade/reference/estimate_heritability.md).

## Usage

``` r
heritability_estimate(data, trait = "num_offspring")
```

## Arguments

- data:

  A list from
  [`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md),
  specifically using `data$deaths`.

- trait:

  Character; column name in `data$deaths` to use as the trait. Default
  `"num_offspring"`.

## Value

A list with:

- `$h2`:

  Estimated heritability (slope of parent-offspring regression). `NA`
  when fewer than 5 matched pairs are found.

- `$n_pairs`:

  Number of matched parent-offspring pairs.

- `$method`:

  `"parent_offspring_regression"`.

- `$trait`:

  The trait used.

## Details

The deaths data frame must contain `parent_id` and the requested `trait`
column. Run the simulation long enough that agents die and are recorded.

## See also

[`estimate_heritability()`](https://itchyshin.github.io/clade/reference/estimate_heritability.md)
for the lag-1 autocorrelation approach.

## Examples

``` r
if (FALSE) { # \dontrun{
env  <- run_alife(default_specs())
data <- get_run_data(env)
h    <- heritability_estimate(data, trait = "num_offspring")
h$h2
} # }
```
