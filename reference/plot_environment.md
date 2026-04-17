# Plot the current state of a clade environment

Renders a snapshot of the grid world: grass density as a green tile
heatmap, agents as points coloured by energy, and (when present)
predators as red triangles. Uses the toroidal coordinate system
(1:grid_rows, 1:grid_cols).

## Usage

``` r
plot_environment(env)
```

## Arguments

- env:

  An environment list returned by
  [`run_clade()`](https://itchyshin.github.io/clade/reference/run_clade.md).
  Must contain `$specs`, `$grass` (numeric matrix), and `$agents` (list
  of per-agent records with `x`, `y`, and `energy` fields).

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Details

Plot the current state of a clade environment

## See also

[`plot_run()`](https://itchyshin.github.io/clade/reference/plot_run.md),
[`run_clade()`](https://itchyshin.github.io/clade/reference/run_clade.md)

## Examples

``` r
if (FALSE) { # \dontrun{
env <- run_clade(default_specs())
plot_environment(env)
} # }
```
