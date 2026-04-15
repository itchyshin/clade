# List registered custom modules

Returns a character vector of registered module names and their hook
points.

## Usage

``` r
list_modules()
```

## Value

A character vector: `"name (when)"` for each registered module. Returns
`character(0)` if no modules registered.

## See also

[`register_module()`](register_module.md),
[`clear_modules()`](clear_modules.md)
