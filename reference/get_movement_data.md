# Extract per-tick agent-position log as a tidy data frame

`get_movement_data()` converts `env$movement_log` (opt-in per-tick agent
positions logged Julia-side when `specs$log_movement = TRUE`) into a
single long data.frame with one row per (logged tick x agent).

## Usage

``` r
get_movement_data(env)
```

## Arguments

- env:

  An environment list returned by
  [`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md).

## Value

A data.frame with columns `t` (integer), `id` (integer), `x` (integer),
`y` (integer), `age` (integer), `energy` (double), `alive` (logical) -
one row per (logged tick x agent). Returns `NULL` when
`log_movement = FALSE` for the run. A zero-row data.frame (with the
correct columns) is returned when logging was enabled but no ticks were
recorded (short runs at low `log_movement_freq`).

## Details

Movement logging is off by default and off in the returned env when the
run did not enable it (`env$movement_log` is `NULL`), so
`get_movement_data()` returns `NULL` in that case. Downstream code can
guard cleanly with `if (is.null(md)) ...`.

To enable, set two extra specs before calling
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md):


      specs$log_movement      <- TRUE
      specs$log_movement_freq <- 5L   # record every 5 ticks; 1L = every tick

Neither field is in
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md)
(trajectory logging is memory-heavy and off by default); they are read
on the Julia side via `get(specs, "log_movement", false)` so extra keys
pass through the R-to-Julia bridge without modification.

## See also

[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md),
[`plot_movement()`](https://itchyshin.github.io/clade/reference/plot_movement.md),
[`plot_run_movie()`](https://itchyshin.github.io/clade/reference/plot_run_movie.md),
[`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)

## Examples

``` r
if (FALSE) { # \dontrun{
specs <- default_specs()
specs$log_movement      <- TRUE
specs$log_movement_freq <- 5L
env <- run_alife(specs)
md  <- get_movement_data(env)
head(md)
plot_movement(md)
} # }
```
