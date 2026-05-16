# CMA-ES optimisation over simulation parameters

Optimises a scalar objective function over the simulation parameter
space using a pure-R implementation of the Covariance Matrix Adaptation
Evolution Strategy (CMA-ES; Hansen & Ostermeier 2001). Unlike
MAP-Elites, CMA-ES finds a single optimal parameter set by adapting its
search distribution to the local curvature of the objective landscape.

## Usage

``` r
search_cmaes(
  specs_base,
  objective = "genetic_diversity",
  params = c("grass_rate", "mutation_sd"),
  n_iterations = 200L,
  popsize = NULL,
  sigma0 = 0.3,
  n_cores = 1L,
  verbose = TRUE
)
```

## Arguments

- specs_base:

  A specs list from
  [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md).

- objective:

  Character or function (same as
  [`search_map_elites()`](https://itchyshin.github.io/clade/reference/search_map_elites.md)).

- params:

  Character vector of positive numeric parameter names to optimise.
  Defaults to `c("grass_rate", "mutation_sd")`.

- n_iterations:

  Integer. Maximum CMA-ES generations (default 200L).

- popsize:

  Integer or `NULL`. CMA-ES population size `lambda`. If `NULL`
  (default), uses the standard formula
  `max(8, 4 + floor(3 * log(n_params)))`.

- sigma0:

  Numeric. Initial step size on the log scale (default 0.3).

- n_cores:

  Integer. Parallel cores for candidate evaluation (default 1L). Uses
  [`parallel::makeCluster()`](https://rdrr.io/r/parallel/makeCluster.html)
  PSOCK workers (one R session + Julia per worker) when `> 1`. Was
  [`parallel::mclapply`](https://rdrr.io/r/parallel/mclapply.html)
  before 0.5.6 but that path silently deadlocked because JuliaConnectoR
  is not fork-safe.

- verbose:

  Logical (default `TRUE`).

## Value

A list with:

- `$specs`:

  Best specs encountered across all generations.

- `$score`:

  Best objective value encountered.

- `$history`:

  Data frame with one row per generation and columns `generation`,
  `evals`, `best_score`, `mean_score`, `sigma`.

## Details

Parameters are optimised on the log scale so that positive constraints
are always satisfied. Each generation evaluates `lambda` candidate
parameter sets, selects the best `mu = lambda/2`, and updates the mean,
step size, and covariance matrix. No external packages are required.

## References

Hansen, N. & Ostermeier, A. (2001) Completely derandomized
self-adaptation in evolution strategies. *Evolutionary Computation*
9(2):159-195. Hansen, N. (2006) The CMA evolution strategy: a comparing
review. In: Towards a New Evolutionary Computation, Springer, pp 75-102.

## See also

[`search_map_elites()`](https://itchyshin.github.io/clade/reference/search_map_elites.md),
[`search_gradient()`](https://itchyshin.github.io/clade/reference/search_gradient.md),
[`search_viability()`](https://itchyshin.github.io/clade/reference/search_viability.md)

## Examples

``` r
if (FALSE) { # \dontrun{
result <- search_cmaes(
  default_specs(),
  objective    = "genetic_diversity",
  params       = c("grass_rate", "mutation_sd"),
  n_iterations = 50L
)
result$specs$grass_rate
result$history   # one row per generation
} # }
```
