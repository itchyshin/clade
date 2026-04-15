# Valid behavioural-descriptor column names for archive_dims

Mirrors the columns produced by [`get_run_data()`](get_run_data.md)
`$ticks`. Used by [`search_map_elites()`](search_map_elites.md) for
early validation of `archive_dims` names so that typos are caught before
any Julia call.

## Usage

``` r
.valid_descriptor_columns()
```
