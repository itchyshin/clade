# MAP-Elites quality-diversity search over simulation parameters

Finds a diverse archive of high-performing parameter combinations using
the MAP-Elites algorithm (Mouret & Clune 2015). Rather than finding one
optimal parameter set, MAP-Elites maintains a grid of niches in
behaviour space; each cell holds the best-performing specs for that
behavioural region.

## Usage

``` r
search_map_elites(
  specs_base,
  archive_dims,
  n_iterations = 1000L,
  objective = "genetic_diversity",
  mutation_params = NULL,
  mutation_sd = 0.1,
  verbose = TRUE,
  checkpoint_path = NULL,
  checkpoint_every = 100L
)
```

## Arguments

- specs_base:

  A specs list from
  [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md).
  Used as the starting point for mutations.

- archive_dims:

  A named list whose names are column names of `get_run_data()$ticks`
  and whose values are numeric vectors specifying the bin breakpoints
  for that dimension. Example:
  `list(genetic_diversity = seq(0, 1, by = 0.1), n_species = 1:10)`.

- n_iterations:

  Integer. Number of MAP-Elites iterations (default 1000L).

- objective:

  Character or function. If a character, the name of a column in
  `get_run_data()$ticks` to maximise (e.g. `"genetic_diversity"`). If a
  function, must accept an `env` list and return a numeric scalar.

- mutation_params:

  Character vector of parameter names (from
  [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md))
  to mutate. Defaults to all numeric parameters.

- mutation_sd:

  Numeric. Standard deviation of Gaussian perturbations to
  log-transformed parameter values (default 0.1).

- verbose:

  Logical. Print progress (default `TRUE`).

- checkpoint_path:

  Optional file path. If supplied, the current archive + history +
  iteration index are saved to this RDS file every `checkpoint_every`
  iterations (and once more at the end). If the same path is passed to a
  subsequent call, the search resumes from the saved iteration. Set to
  `NULL` (default) to disable checkpointing. Added 0.5.6.

- checkpoint_every:

  Integer. How often to write the checkpoint, in iterations (default
  100L). Ignored when `checkpoint_path` is `NULL`. Added 0.5.6.

## Value

A list with components:

- `$archive`:

  A list of lists, one per archive cell, each containing: `$specs`,
  `$score`, `$behavioural_descriptor` (named numeric vector).

- `$map`:

  A ggplot2 heatmap of the archive scores (for 2D archive dims only).
  `NULL` for higher-dimensional archives.

- `$history`:

  Data frame with one row per iteration: `iteration`, `score`,
  `filled_cells`.

## Details

### Algorithm

1.  Initialise: fill each archive cell by sampling random specs near
    `specs_base`.

2.  For each of `n_iterations` iterations: a. Select a random filled
    cell from the archive. b. Mutate its specs (Gaussian perturbation of
    numeric parameters). c. Run `run_alife(new_specs)`. d. Compute the
    behavioural descriptors from `get_run_data(env)`. e. If the new
    specs score better than the current occupant of the corresponding
    archive cell, replace it.

3.  Return the full archive.

## References

Mouret, J.-B. & Clune, J. (2015) Illuminating search spaces by mapping
elites. arXiv:1504.04909. Chatzilygeroudis, K., Cully, A., Vassiliades,
V. & Mouret, J.-B. (2021) Quality-Diversity Optimization: a novel branch
of stochastic optimization. arXiv:2012.04322.

## See also

[`search_cmaes()`](https://itchyshin.github.io/clade/reference/search_cmaes.md),
[`search_gradient()`](https://itchyshin.github.io/clade/reference/search_gradient.md),
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)

## Examples

``` r
if (FALSE) { # \dontrun{
result <- search_map_elites(
  specs_base   = default_specs(),
  archive_dims = list(
    genetic_diversity = seq(0, 1, by = 0.1),
    n_species         = 1:10
  ),
  n_iterations = 500L,
  objective    = "genetic_diversity"
)
result$map   # ggplot2 heatmap
} # }
```
