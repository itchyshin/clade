# Generate a factorial grid of specs

Produces a `list` of specs objects, one per combination of the supplied
parameter values. Every other field is inherited from `base`. Useful for
systematic parameter-space exploration with
[`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md).

## Usage

``` r
grid_specs(base, ..., seed_from = 1L)
```

## Arguments

- base:

  A specs list (from
  [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md),
  [`fast_specs()`](https://itchyshin.github.io/clade/reference/fast_specs.md),
  etc.) to use as the template for each combination.

- ...:

  Named vectors / lists of candidate values for each parameter. For
  example, `grass_rate = c(0.1, 0.2, 0.3), mutation_sd = c(0.02, 0.05)`
  generates a 3 × 2 = 6-cell grid. String-typed parameters can also be
  passed (e.g. `life_history = c("iteroparous", "semelparous")`).

- seed_from:

  Integer or `NULL`. If provided, overrides each cell's `random_seed`
  with `seed_from + 0L, seed_from + 1L, ...` so a grid run is
  reproducible. Default `1L`.

## Value

A named list of specs. Names encode the parameter values, e.g.
`"grass_rate=0.1;mutation_sd=0.02"`.

## See also

[`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md),
[`sample_specs()`](https://itchyshin.github.io/clade/reference/sample_specs.md),
[`summarize_batch()`](https://itchyshin.github.io/clade/reference/summarize_batch.md)

## Examples

``` r
if (FALSE) { # \dontrun{
base <- fast_specs()
specs_list <- grid_specs(base,
                         grass_rate   = c(0.1, 0.2, 0.3),
                         mutation_sd  = c(0.02, 0.05))
results <- batch_alife(specs_list, n_cores = 6L)
} # }
```
