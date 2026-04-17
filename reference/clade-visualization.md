# Visualisation layer for clade simulation output

Functions in this file construct ggplot2 (Wickham 2016) and patchwork
(Pedersen 2020) objects from the tidy data returned by
[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md).
All plots use a minimal theme and are safe to print, save, or combine.

## References

Wickham, H. (2016) *ggplot2: Elegant Graphics for Data Analysis.* 2nd
ed. Springer-Verlag, New York. Pedersen, T.L. (2020) *patchwork: The
Composer of Plots.* R package version 1.1.0.
https://patchwork.data-imaginist.com
