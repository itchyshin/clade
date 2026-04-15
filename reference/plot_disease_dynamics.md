# Plot disease dynamics over time

Plots `n_infected` (solid red line) and `n_new_infections` (dashed
orange line) from a clade run. When both series are zero (disease module
off) the function returns an informative empty placeholder plot.

## Usage

``` r
plot_disease_dynamics(run_data)
```

## Arguments

- run_data:

  A list returned by [`get_run_data()`](get_run_data.md). Must contain
  `$ticks` with the columns `t`, `n_infected`, `n_new_infections`.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Details

Plot disease dynamics over time

## See also

[`plot_run()`](plot_run.md), [`get_run_data()`](get_run_data.md)

## Examples

``` r
if (FALSE) { # \dontrun{
specs <- default_specs(); specs$disease <- TRUE
env   <- run_clade(specs)
data  <- get_run_data(env)
plot_disease_dynamics(data)
} # }
```
