# Plot kin network (Phase 2 placeholder)

Placeholder returning a ggplot noting that kin network visualisation
requires the igraph package and is scheduled for Phase 2. Matches the
alifeR API.

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
object with a single annotation.

## Details

Plot kin network (Phase 2 placeholder)

## See also

[`plot_run()`](https://itchyshin.github.io/clade/reference/plot_run.md)

## Examples

``` r
if (FALSE) { # \dontrun{
plot_kin_network(get_run_data(run_clade(default_specs())))
} # }
```
