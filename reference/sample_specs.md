# Sample specs randomly from parameter distributions

Draws `n` specs from a set of univariate distributions. Each
distribution is either a numeric vector (sampled with replacement), a
function of one argument `n` that returns `n` values, or a two-element
list `list(runif_min, runif_max)` for uniform random draws.

## Usage

``` r
sample_specs(base, n, ..., seed = 1L, seed_from = 1L)
```

## Arguments

- base:

  A specs list template (see
  [`grid_specs()`](https://itchyshin.github.io/clade/reference/grid_specs.md)).

- n:

  Integer. Number of specs to draw.

- ...:

  Named distributions. See Details.

- seed:

  Integer. Seed for the R-side sampler so the draw is reproducible.
  Default `1L`.

- seed_from:

  Integer or `NULL`. Base for each drawn spec's `random_seed`. Default
  `1L`.

## Value

A named list of specs. Names are `"sample_1"`, `"sample_2"`, …

## Details

Three ways to specify a distribution for each parameter:

- **Vector**: `grass_rate = c(0.05, 0.1, 0.2, 0.3, 0.5)` — draws from
  the vector with replacement.

- **Range (list of 2)**: `mutation_sd = list(0.01, 0.1)` — uniform draw
  from \[0.01, 0.1\]. Useful when the parameter is continuous.

- **Function**: `plasticity_init_mean = function(n) rbeta(n, 2, 2)` —
  any function that takes `n` and returns `n` values.

## See also

[`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md),
[`grid_specs()`](https://itchyshin.github.io/clade/reference/grid_specs.md),
[`summarize_batch()`](https://itchyshin.github.io/clade/reference/summarize_batch.md)

## Examples

``` r
if (FALSE) { # \dontrun{
base <- fast_specs()
specs_list <- sample_specs(base, n = 500L,
                           grass_rate   = list(0.05, 0.40),
                           mutation_sd  = c(0.02, 0.05, 0.1),
                           plasticity_init_mean = function(n) rbeta(n, 2, 2))
results <- batch_alife(specs_list, n_cores = 50L)
summary_tbl <- summarize_batch(results, specs_list)
} # }
```
