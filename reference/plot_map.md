# Plot the spatial distribution of agents on the grid

Renders a snapshot of the grid world with grass density as a green tile
heatmap and agent positions as coloured points. The colour of each agent
can represent energy, age, species identity, or body size, making it
easy to examine the spatial structure of the population at any tick.

## Usage

``` r
plot_map(env, colour_by = "energy", ...)
```

## Arguments

- env:

  An environment list returned by [`run_clade()`](run_clade.md). Must
  contain `$specs` (with `grid_rows`, `grid_cols`, and optionally
  `grass_max`), `$grass` (numeric matrix), and `$agents` (list of
  per-agent records).

- colour_by:

  Character scalar selecting the agent attribute used to colour points.
  One of `"energy"` (continuous, blue scale), `"age"` (continuous,
  orange scale), `"species"` (`agent$species_id`, discrete, up to 10
  colours), or `"body_size"` (continuous, purple scale). Default:
  `"energy"`.

- ...:

  Currently unused. Reserved for forward compatibility.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Details

Plot the spatial distribution of agents on the grid

## See also

[`plot_environment()`](plot_environment.md),
[`plot_run()`](plot_run.md), [`run_clade()`](run_clade.md)

## Examples

``` r
if (FALSE) { # \dontrun{
env <- run_clade(default_specs())
plot_map(env)
plot_map(env, colour_by = "age")
} # }
```
