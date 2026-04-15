# Convert an R specs list to a Julia `Dict{String,Any}`

Sends the specs list to Julia through
[`JuliaConnectoR::juliaCall()`](https://rdrr.io/pkg/JuliaConnectoR/man/juliaCall.html)
and lets the Julia helper `Clade.r_specs_to_dict()` unpack it into a
`Dict{String,Any}`. This replaces the earlier string-interpolation
approach which required manual escaping for every scalar type.
JuliaConnectoR serialises an R named list as an `RConnector.ElementList`
whose scalars retain their R types (integer, double, logical,
character), and the Julia helper rebuilds the Dict keyed by string.

## Usage

``` r
.specs_to_julia(specs)
```

## Arguments

- specs:

  A validated specs list from [`default_specs()`](default_specs.md).

## Value

A Julia proxy for the resulting `Dict{String,Any}`, suitable for passing
to `Clade.run_clade()`.

## Details

Values that JuliaConnectoR cannot serialise – single `NA`s and
zero-length character vectors – are dropped before sending. Julia reads
optional fields via `get(specs, key, default)`, so an absent key is
equivalent to `nothing` or the coded default.
