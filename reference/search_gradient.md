# Finite-difference gradient ascent over simulation parameters

Optimises a scalar objective with respect to named numeric simulation
parameters using forward-difference gradient ascent. Each gradient
coordinate is estimated by re-running
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)
with one parameter perturbed by `epsilon` on the log scale, then
comparing the resulting objective to a baseline run. Updates are applied
on the log scale so that positive parameters remain positive.

## Usage

``` r
search_gradient(
  specs_base,
  params = c("grass_rate", "mutation_sd"),
  objective = "genetic_diversity",
  n_steps = 20L,
  epsilon = 0.05,
  learning_rate = 0.1,
  n_cores = 1L,
  verbose = TRUE
)
```

## Arguments

- specs_base:

  A specs list from
  [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md).

- params:

  Character vector of numeric parameter names to optimise. Defaults to
  `c("grass_rate", "mutation_sd")`.

- objective:

  Character or function. If a character, the name of a column in
  `get_run_data()$ticks` to maximise. If a function, must accept an
  `env` list and return a numeric scalar.

- n_steps:

  Integer. Number of gradient ascent steps (default 20L).

- epsilon:

  Numeric. Finite-difference step on the log scale (default 0.05).

- learning_rate:

  Numeric. Log-scale step size for parameter updates (default 0.1).

- n_cores:

  Integer. Reserved for future parallel finite-difference evaluation;
  currently unused (default 1L).

- verbose:

  Logical. Print progress (default `TRUE`).

## Value

A list with components:

- `$specs`:

  Best specs encountered across all gradient steps.

- `$score`:

  Best objective value encountered.

- `$history`:

  Data frame with one row per step and columns `step`, `score`, and one
  column per optimised parameter.

## Details

This implementation is intentionally backend-agnostic: it treats
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)
as a black box and only requires `(n_steps + 1) * n_params` simulation
calls per run. For a true gradient-through-simulation approach using
Zygote.jl automatic differentiation through the Julia backend, see the
deferred Phase 4b plan.

## References

Spall, J.C. (1998) An overview of the simultaneous perturbation method
for efficient optimization. *Johns Hopkins APL Technical Digest*
19(4):482-492. Innes, M. (2018) Don't unroll adjoint: differentiating
SSA-form programs. arXiv:1810.07951. (Zygote.jl – Phase 4b deferred.)

## See also

[`search_map_elites()`](https://itchyshin.github.io/clade/reference/search_map_elites.md),
[`search_cmaes()`](https://itchyshin.github.io/clade/reference/search_cmaes.md)

## Examples

``` r
if (FALSE) { # \dontrun{
result <- search_gradient(
  default_specs(),
  params        = c("grass_rate", "mutation_sd"),
  objective     = "genetic_diversity",
  n_steps       = 20L,
  epsilon       = 0.05,
  learning_rate = 0.1
)
result$specs$grass_rate
} # }
```
