# Reconstruct a species tree from a logged simulation

`species_tree()` is a placeholder. Phylogenetic reconstruction requires
the speciation module (Phase 2), which assigns agents to discrete
species, tracks lineage splits, and emits a per-tick species log. None
of that machinery is in place yet, so this function currently returns a
stub for forward compatibility.

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
