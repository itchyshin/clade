# Render the full simulation dashboard

Assembles a 2 x 3 panel dashboard from a completed clade run:

- Top-left:

  Grid snapshot – landscape and agent positions at the final tick
  ([`plot_environment()`](https://itchyshin.github.io/clade/reference/plot_environment.md)).

- Top-centre:

  Population dynamics – agent count, mean and best energy over time.

- Top-right:

  Diversity trajectory
  ([`plot_diversity()`](https://itchyshin.github.io/clade/reference/plot_diversity.md)).

- Bottom-left:

  Lifespan vs energy scatter by cause of death.

- Bottom-centre:

  Lifespan histogram.

- Bottom-right:

  Body-size evolution ribbon (or genetic diversity when body-size
  evolution is off).

## Usage

``` r
visualize_progress(env, run_data = NULL, title = NULL)
```

## Arguments

- env:

  An environment list returned by
  [`run_clade()`](https://itchyshin.github.io/clade/reference/run_clade.md).

- run_data:

  A list returned by
  [`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md).
  If `NULL`, computed from `env` automatically.

- title:

  Character scalar super-title. If `NULL`, auto-generated from tick
  count and final population size.

## Value

A
[`patchwork::wrap_plots()`](https://patchwork.data-imaginist.com/reference/wrap_plots.html)
composite ggplot object.

## Details

Render the full simulation dashboard

## See also

[`plot_environment()`](https://itchyshin.github.io/clade/reference/plot_environment.md),
[`plot_dead_agents()`](https://itchyshin.github.io/clade/reference/plot_dead_agents.md),
[`plot_diversity()`](https://itchyshin.github.io/clade/reference/plot_diversity.md),
[`plot_body_size_evolution()`](https://itchyshin.github.io/clade/reference/plot_body_size_evolution.md),
[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)

## Examples

``` r
if (FALSE) { # \dontrun{
env  <- run_clade(default_specs())
data <- get_run_data(env)
visualize_progress(env, data)
} # }
```
