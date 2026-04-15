# Inspect the brain structure of a single agent

`inspect_brain()` extracts structural and statistical information from
the brain of a named agent in `env$agents`. It supports both ANN brains
(layers with `$W` and `$b`) and BNN brains (layers with `$mu` and
`$sigma`). When the brain structure is unavailable it returns a minimal
list with a note.

## Usage

``` r
inspect_brain(env, agent_id = 1L)
```

## Arguments

- env:

  An environment list returned by [`run_clade()`](run_clade.md).

- agent_id:

  Integer. The `$id` field of the agent to inspect. Defaults to `1L`.

## Value

A named list with elements:

- `$brain_type`:

  Character. Value of `env$specs$brain_type`.

- `$n_layers`:

  Integer. Number of layers in `brain$layers`.

- `$layer_sizes`:

  List of integer vectors `c(nrow, ncol)` for each layer weight matrix.

- `$n_weights`:

  Integer. Total number of weight values across all layers.

- `$weight_mean`:

  Numeric. Mean of all weights.

- `$weight_sd`:

  Numeric. Standard deviation of all weights.

- `$weight_min`:

  Numeric. Minimum weight value.

- `$weight_max`:

  Numeric. Maximum weight value.

- `$sigma_mean`, `$sigma_sd`, `$sigma_min`, `$sigma_max`:

  Numeric. Statistics for the `$sigma` matrices (BNN brains only).

- `$note`:

  Character. Present only when `brain$layers` is unavailable; explains
  why summary statistics are absent.

## See also

[`get_brain_weights()`](get_brain_weights.md),
[`run_clade()`](run_clade.md)

## Examples

``` r
if (FALSE) { # \dontrun{
env <- run_clade(default_specs())
inspect_brain(env, agent_id = 1L)
} # }
```
