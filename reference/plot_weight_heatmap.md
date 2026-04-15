# Visualise a neural genome as a weight heatmap

Renders each weight matrix in an ANN-format brain (a list with a
`layers` element, each layer having `$W` and `$b`) as a diverging
blue-white-red tile heatmap. Blue = strong inhibitory connections, red =
strong excitatory connections, white = near-zero weights. One panel per
layer.

Agents under strong selection often show structured weight matrices
(certain input-to-hidden connections consistently strong) compared to
the near-random patterns of newly initialised founders.

## Usage

``` r
plot_weight_heatmap(ann, title = "Neural genome")
```

## Arguments

- ann:

  A brain list with a `$layers` element, as returned by
  `env$agents[[i]]$brain` for ANN brain types. Must be an R list (not a
  JuliaConnectoR proxy).

- title:

  Character scalar prepended to each panel title. Default:
  `"Neural genome"`.

## Value

A
[`patchwork::wrap_plots()`](https://patchwork.data-imaginist.com/reference/wrap_plots.html)
object with one panel per layer.

## Details

Visualise a neural genome as a weight heatmap

## See also

[`visualize_progress()`](visualize_progress.md)

## Examples

``` r
if (FALSE) { # \dontrun{
env <- run_clade(default_specs())
# Access brain data (requires converting from Julia proxy first)
# plot_weight_heatmap(brain_list)
} # }
```
