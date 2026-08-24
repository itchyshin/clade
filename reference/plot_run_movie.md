# Animate agent trajectories as a gganimate movie

Builds a `gganim` object from a movement log for post-hoc playback.
Wraps
[`plot_movement()`](https://itchyshin.github.io/clade/reference/plot_movement.md)
with a
[`gganimate::transition_time()`](https://gganimate.com/reference/transition_time.html)
layer so successive frames show the population as it evolved. The
returned object is **not rendered** — hand it to
[`gganimate::animate()`](https://gganimate.com/reference/animate.html)
(to view in RStudio) or
[`gganimate::anim_save()`](https://gganimate.com/reference/anim_save.html)
(to write a GIF or MP4).

Requires the `gganimate` package (in `Suggests`). When `gganimate` is
not installed the function errors with a clear install hint. When `md`
is `NULL` (recording was off) a placeholder ggplot is returned rather
than an error.

## Usage

``` r
plot_run_movie(
  md,
  colour_by = c("energy", "age", "id", "alive"),
  grid_rows = NULL,
  grid_cols = NULL,
  ...
)
```

## Arguments

- md:

  A data frame returned by
  [`get_movement_data()`](https://itchyshin.github.io/clade/reference/get_movement_data.md),
  or `NULL`.

- colour_by:

  Character. Passed to
  [`plot_movement()`](https://itchyshin.github.io/clade/reference/plot_movement.md).
  Default `"energy"`.

- grid_rows, grid_cols:

  Optional integers giving the grid extent, passed to
  [`plot_movement()`](https://itchyshin.github.io/clade/reference/plot_movement.md).

- ...:

  Currently unused. Reserved for forward compatibility.

## Value

A `gganim` object when `gganimate` is available and `md` is non-`NULL`.
A ggplot placeholder when `md` is `NULL`.

## Details

Animate agent trajectories as a gganimate movie

## See also

[`plot_movement()`](https://itchyshin.github.io/clade/reference/plot_movement.md),
[`get_movement_data()`](https://itchyshin.github.io/clade/reference/get_movement_data.md)

## Examples

``` r
if (FALSE) { # \dontrun{
specs <- default_specs()
specs$log_movement      <- TRUE
specs$log_movement_freq <- 5L
env <- run_alife(specs)
md  <- get_movement_data(env)

mv <- plot_run_movie(md)
# Render options belong on animate() / anim_save():
gganimate::animate(mv, fps = 10, width = 480, height = 480)
gganimate::anim_save("run.gif", mv)
} # }
```
