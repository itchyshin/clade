# Choose an action for an agent given its sensory input

`take_action()` runs the agent's brain forward pass on its current
sensory input and returns the chosen action index (1-indexed). Action
indices match the Julia convention: 1 = left, 2 = up, 3 = right, 4 =
down, 5 = eat, 6 = reproduce (where 5 and 6 may not be available for all
brain types).

## Usage

``` r
take_action(env, i = 1L, input = NULL)
```

## Arguments

- env:

  Environment list from [`run_alife()`](run_alife.md).

- i:

  Integer; index into `env$agents` (1-based).

- input:

  Numeric vector. Sensory input (from [`sense_env()`](sense_env.md)). If
  `NULL`, `sense_env(env, i)` is called automatically.

## Value

A named list:

- `$action`:

  Integer action index (1-based).

- `$logits`:

  Raw output values from the final brain layer.

- `$probs`:

  Softmax probabilities over actions.

- `$action_names`:

  Character vector of action labels.

## Details

For BNN brains the mean weights (`mu`) are used (the agent acts on the
mode of its weight posterior). For other brain types, `W` weights are
used.

## See also

[`sense_env()`](sense_env.md), [`inspect_brain()`](inspect_brain.md)

## Examples

``` r
if (FALSE) { # \dontrun{
env <- run_alife(default_specs())
res <- take_action(env, 1L)
res$action        # which action was chosen
res$probs         # probability distribution over actions
} # }
```
