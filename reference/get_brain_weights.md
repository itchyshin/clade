# Extract weight values from an agent's brain

`get_brain_weights()` returns either all weights concatenated across
layers (when `layer = NULL`) or the weight matrix for a single specified
layer. For ANN brains the weight matrix is `$W`; for BNN brains it is
`$mu`.

## Usage

``` r
get_brain_weights(env, agent_id = 1L, layer = NULL)
```

## Arguments

- env:

  An environment list returned by
  [`run_clade()`](https://itchyshin.github.io/clade/reference/run_clade.md).

- agent_id:

  Integer. The `$id` field of the agent. Defaults to `1L`.

- layer:

  Integer or NULL. If `NULL` (default), all weights are returned as a
  named numeric vector. If an integer, the weight matrix for that layer
  index is returned.

## Value

A named numeric vector (when `layer = NULL`) or a numeric matrix (when
`layer` is specified).

## See also

[`inspect_brain()`](https://itchyshin.github.io/clade/reference/inspect_brain.md),
[`run_clade()`](https://itchyshin.github.io/clade/reference/run_clade.md)

## Examples

``` r
if (FALSE) { # \dontrun{
env <- run_clade(default_specs())
get_brain_weights(env, agent_id = 1L)           # all weights
get_brain_weights(env, agent_id = 1L, layer = 1L) # layer-1 matrix
} # }
```
