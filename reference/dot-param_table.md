# Generate a parameter-reference table for one group (internal)

Builds a `data.frame` with columns `parameter`, `default`, `type` for
all fields in `specs` that belong to the named group. Used by
[`vignette("parameter-reference")`](https://itchyshin.github.io/clade/articles/parameter-reference.md)
so that defaults are always synchronised with
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md)
rather than hand-maintained.

## Usage

``` r
.param_table(group, specs = default_specs())
```

## Arguments

- group:

  Character. Name of one of the groups in `.SPEC_GROUPS`. See
  [`.param_groups()`](https://itchyshin.github.io/clade/reference/dot-param_groups.md)
  for the full list.

- specs:

  A specs list (default:
  [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md)).

## Value

A `data.frame` with three columns: `parameter`, `default`, `type`. Empty
`data.frame` if no field in `group` is in `specs`.

## Details

Fields listed in `.SPEC_GROUPS[[group]]` but absent from `specs` are
silently skipped (lets the groupings hold names of reserved-future
fields without breaking the table).
