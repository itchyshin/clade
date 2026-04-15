# Stochastic parameter sweep for evolutionary outcome discovery

Evaluates `n_samples` randomly drawn parameter configurations and
returns the results ranked by the chosen objective. Each sample is
obtained by independently perturbing each element of `search_params`
(log-scale for positive parameters, linear scale otherwise). This
provides an inexpensive exploration baseline comparable to a Latin
Hypercube Sampling (LHS) sweep.

## Usage

``` r
search_random(
  specs_base,
  search_params,
  n_samples = 50L,
  objective = "genetic_diversity",
  verbose = TRUE
)
```

## Arguments

- specs_base:

  A specs list from [`default_specs()`](default_specs.md).

- search_params:

  Named list of parameter ranges. Each element should be a numeric
  vector of length 2 (`c(min, max)`) for uniform sampling, or a numeric
  vector of length \> 2 for discrete sampling. Example:

      list(
        mutation_sd   = c(0.01, 0.5),
        grass_rate    = c(0.05, 0.8),
        n_agents_init = c(10L, 200L)
      )

- n_samples:

  Integer. Number of random configurations to evaluate (default `50L`).

- objective:

  Character or function. Column from `get_run_data()$ticks` to maximise
  (default `"genetic_diversity"`), or a function `f(env)` returning a
  numeric scalar.

- verbose:

  Logical. Print progress (default `TRUE`).

## Value

A data frame with one row per sample, columns:

- `rank`:

  Rank by descending objective score (1 = best).

- `score`:

  Objective value for this sample.

- ...:

  One column per element of `search_params` showing the sampled value
  used.

Attribute `"specs_list"` is a list of the full specs for each sample
row, accessible via `attr(result, "specs_list")`.

## Details

Use `search_random()` to:

- Screen which parameters most strongly influence genetic diversity.

- Identify high-diversity corners of the parameter space before running
  the more expensive [`search_map_elites()`](search_map_elites.md) or
  [`search_cmaes()`](search_cmaes.md).

- Compare stochastic results to MAP-Elites elites to spot archive gaps.

## See also

[`search_map_elites()`](search_map_elites.md),
[`search_cmaes()`](search_cmaes.md),
[`search_gradient()`](search_gradient.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Screen mutation_sd and grass_rate for highest genetic diversity
result <- search_random(
  specs_base    = default_specs(),
  search_params = list(
    mutation_sd   = c(0.01, 0.5),
    grass_rate    = c(0.05, 0.8),
    n_agents_init = c(10L, 150L)
  ),
  n_samples  = 30L,
  objective  = "genetic_diversity"
)
head(result)                          # top configurations
plot(result$grass_rate, result$score) # partial dependence
} # }
```
