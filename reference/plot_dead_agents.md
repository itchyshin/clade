# Plot lifetime statistics of dead agents

Produces two panels summarising agents that died during a run. The
**left panel** plots age at death against energy at death, coloured by
body size (when body-size evolution is active) or number of offspring,
and sized by offspring count. The **right panel** shows a bar chart of
cause-of-death counts (starvation, predation, disease, old age).
Together these reveal which life-history strategies were rewarded by
selection.

## Usage

``` r
plot_dead_agents(run_data)
```

## Arguments

- run_data:

  A list returned by [`get_run_data()`](get_run_data.md). Must contain a
  `$deaths` data frame with columns `age`, `energy`, `cause`,
  `num_offspring`, and optionally `body_size`.

## Value

A two-panel
[`patchwork::wrap_plots()`](https://patchwork.data-imaginist.com/reference/wrap_plots.html)
object, or `NULL` invisibly if no agents died.

## Details

Plot lifetime statistics of dead agents

## See also

[`get_run_data()`](get_run_data.md),
[`visualize_progress()`](visualize_progress.md)

## Examples

``` r
if (FALSE) { # \dontrun{
env  <- run_clade(default_specs())
data <- get_run_data(env)
plot_dead_agents(data)
} # }
```
