# Compute normalised Euclidean genome distance between two agents

`genome_distance()` quantifies how different two agents are by computing
the normalised Euclidean distance between their flattened brain weight
vectors. For BNN brains, the `mu` (mean) weights are used; for all other
brain types, the `W` weight matrices are used.

## Usage

``` r
genome_distance(agent_a, agent_b)
```

## Arguments

- agent_a, agent_b:

  Agent lists from `env$agents`. Each must have a `$brain$layers`
  component.

## Value

A non-negative numeric scalar. Zero means the two brains are identical;
values near 1 indicate substantial divergence.

## Examples

``` r
if (FALSE) { # \dontrun{
env <- run_alife(default_specs())
if (length(env$agents) >= 2L)
  genome_distance(env$agents[[1]], env$agents[[2]])
} # }
```
