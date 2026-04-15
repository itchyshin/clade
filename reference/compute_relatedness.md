# Compute pedigree-based relatedness between two agents

`compute_relatedness()` estimates the coefficient of relatedness (r)
between two agents using parent-ID pedigree chains stored in
`env$agents`. The algorithm returns r = 0.5 for parent-offspring, r =
0.25 for full siblings (shared parent), and r = 0 otherwise. This
matches Hamilton's rule coefficients used by the kin selection module.

## Usage

``` r
compute_relatedness(id_a, id_b, env)
```

## Arguments

- id_a, id_b:

  Integer; `$id` values of the two agents to compare.

- env:

  Environment list from [`run_alife()`](run_alife.md).

## Value

Numeric scalar in the range 0–1.

## Examples

``` r
if (FALSE) { # \dontrun{
env <- run_alife(default_specs())
ids <- sapply(env$agents, `[[`, "id")
compute_relatedness(ids[1], ids[2], env)
} # }
```
