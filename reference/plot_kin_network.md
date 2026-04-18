# Plot kin network (not yet implemented — placeholder)

**Not yet implemented.** Returns a labelled empty ggplot so downstream
code relying on a stable API doesn't error. A real implementation
requires the igraph package (currently not a clade dependency) and
agent-level lineage data that
[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)
does not yet expose. Matches the alifeR API name for future
compatibility.

Do not rely on this function for analysis. Use
[`compute_relatedness()`](https://itchyshin.github.io/clade/reference/compute_relatedness.md)
directly if you need pairwise kinship values.

## Usage

``` r
plot_kin_network(run_data)
```

## Arguments

- run_data:

  A list returned by
  [`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md).
  Currently unused.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object with a single annotation stating the function is a placeholder.

## See also

[`plot_run()`](https://itchyshin.github.io/clade/reference/plot_run.md),
[`compute_relatedness()`](https://itchyshin.github.io/clade/reference/compute_relatedness.md)
