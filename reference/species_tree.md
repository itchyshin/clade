# Reconstruct a species tree from a logged simulation

`species_tree()` is a placeholder. The speciation module
(`specs$speciation = TRUE`) assigns agents to clusters each tick and
logs a cluster count, but doesn't retain the pairwise genetic distances
or lineage-split history needed for phylogenetic reconstruction. None of
that extended machinery is in place yet, so this function currently
returns a stub for forward compatibility.

## Usage

``` r
species_tree(run_data)
```

## Arguments

- run_data:

  A list returned by
  [`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md).

## Value

A list with components:

- `$tree`:

  Always `NULL` in the current implementation.

- `$note`:

  Character. Explains that species-tree reconstruction awaits the
  speciation module.

## See also

[`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md),
[`estimate_heritability()`](https://itchyshin.github.io/clade/reference/estimate_heritability.md),
[`compute_ld()`](https://itchyshin.github.io/clade/reference/compute_ld.md)

## Examples

``` r
if (FALSE) { # \dontrun{
env <- run_alife(default_specs())
species_tree(get_run_data(env))
} # }
```
