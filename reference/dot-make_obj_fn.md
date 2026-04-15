# Build an objective function from a character name or callable

All four search functions accept `objective` as either a column name
(character) or a function `f(env) -> scalar`. This helper standardises
both cases, eliminating four identical copy-pasted blocks.

## Usage

``` r
.make_obj_fn(objective)
```

## Arguments

- objective:

  Character column name or a function accepting a `clade_env` object and
  returning a numeric scalar.

## Value

A function `f(env) -> numeric(1)`.
