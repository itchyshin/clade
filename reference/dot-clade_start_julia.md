# Start the Julia session and load Clade.jl (called automatically)

This function is called once, on the first call to
[`run_alife()`](run_alife.md). It starts a Julia process via
JuliaConnectoR, activates the Clade.jl Julia project, and imports the
module. Startup takes roughly 3-10 seconds on first call (Julia JIT
compilation); subsequent calls within the same R session are instant.

## Usage

``` r
.clade_start_julia(verbose = TRUE)
```

## Arguments

- verbose:

  Logical. Print startup messages (default `TRUE`).

## Value

Invisibly, the result of `JuliaConnectoR::juliaEval("true")` as a
connectivity check.
