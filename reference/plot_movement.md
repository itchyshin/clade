# Plot agent trajectories from a movement log

Renders the per-agent, per-tick positions logged when
`specs$log_movement = TRUE` was set for the run. With `tick = NULL`
(default) every recorded position is drawn as a point, showing the
cumulative trajectory of every agent over the run. With `tick = t` only
positions recorded at that tick are drawn, giving a single snapshot
equivalent to a still frame from
[`plot_run_movie()`](https://itchyshin.github.io/clade/reference/plot_run_movie.md).

When the movement log is `NULL` (recording was off), a placeholder
ggplot with an explanatory message is returned rather than an error.

## Usage

``` r
plot_movement(
  md,
  colour_by = c("energy", "age", "id", "alive"),
  tick = NULL,
  grid_rows = NULL,
  grid_cols = NULL,
  ...
)
```

## Arguments

- md:

  A data frame returned by
  [`get_movement_data()`](https://itchyshin.github.io/clade/reference/get_movement_data.md),
  or `NULL` when `specs$log_movement = FALSE` was set for the run.

- colour_by:

  Character. Column of `md` used to colour points. One of `"energy"`
  (default), `"age"`, `"id"`, or `"alive"`.

- tick:

  Optional integer. When supplied, only rows with `md$t == tick` are
  drawn; when `NULL` (default), all recorded ticks are drawn together.

- grid_rows, grid_cols:

  Optional integers giving the grid extent for `coord_fixed()`. When
  `NULL` (default), the extent is inferred from `max(md$x)` and
  `max(md$y)`.

- ...:

  Currently unused. Reserved for forward compatibility.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Details

Plot agent trajectories from a movement log

## See also

[`get_movement_data()`](https://itchyshin.github.io/clade/reference/get_movement_data.md),
[`plot_run_movie()`](https://itchyshin.github.io/clade/reference/plot_run_movie.md),
[`plot_map()`](https://itchyshin.github.io/clade/reference/plot_map.md)

## Examples

``` r
if (FALSE) { # \dontrun{
specs <- default_specs()
specs$log_movement      <- TRUE
specs$log_movement_freq <- 5L
env <- run_alife(specs)
md  <- get_movement_data(env)
plot_movement(md)                     # every recorded position
plot_movement(md, tick = 100L)        # single-tick snapshot
plot_movement(md, colour_by = "age")
} # }
```
