# Test whether an R value can round-trip through JuliaConnectoR

JuliaConnectoR fails to serialise `NULL`, `NA` scalars, and zero-length
character vectors. This helper returns `FALSE` for these, `TRUE`
otherwise.

## Usage

``` r
.is_sendable_to_julia(v)
```
