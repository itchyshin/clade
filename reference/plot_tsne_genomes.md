# Plot genome PCA to reveal population genetic structure

Takes genome data logged by
[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)
when `log_genomes = TRUE` was set during the run, draws a random sample
of up to `n_agents` rows, runs principal components analysis on the
genome weight matrix, and plots PC1 versus PC2 coloured by tick to show
how genetic structure shifts over time.

When genome data are absent or contain fewer than four rows, a
placeholder ggplot with an explanatory message is returned instead.

## Usage

``` r
plot_tsne_genomes(run_data, n_agents = 50L, perplexity = 15, ...)
```

## Arguments

- run_data:

  A list returned by
  [`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md).
  When `log_genomes = TRUE` was active, this list contains a `$genomes`
  data frame with an `id` column, a `t` column, and one numeric column
  per genome weight. When absent the function returns a placeholder.

- n_agents:

  Integer. Maximum number of genome rows to sample before running PCA.
  Keeps computation tractable for large logs. Default: `50L`.

- perplexity:

  Numeric. Unused; retained for API forward-compatibility with a future
  t-SNE upgrade. Default: `15`.

- ...:

  Currently unused. Reserved for forward compatibility.

## Value

A
[`ggplot2::ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Details

Plot genome PCA to reveal population genetic structure

## See also

[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md),
[`plot_genome_diversity()`](https://itchyshin.github.io/clade/reference/plot_genome_diversity.md)

## Examples

``` r
if (FALSE) { # \dontrun{
specs <- default_specs(); specs$log_genomes <- TRUE
env   <- run_clade(specs)
data  <- get_run_data(env)
plot_tsne_genomes(data)
} # }
```
