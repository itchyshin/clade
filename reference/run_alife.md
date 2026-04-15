# Run an evolutionary simulation

`run_alife()` is the primary entry point for clade. It sends `specs` to
Julia once, runs all `specs$max_ticks` ticks entirely in Julia, and
returns an environment list containing the final agent population and
all logged statistics. The Julia session is started automatically on the
first call.

## Usage

``` r
run_alife(specs = default_specs(), verbose = TRUE)
```

## Arguments

- specs:

  A named list of simulation parameters, typically from
  [`default_specs()`](default_specs.md) with modifications. All
  parameters are documented in [`default_specs()`](default_specs.md).

- verbose:

  Logical. Print progress messages (default `TRUE`). Pass `FALSE` for
  batch runs or testing.

## Value

An `env` list with components:

- `$agents`:

  A list of agent lists, one per surviving agent.

- `$t`:

  Final tick number (equals `specs$max_ticks`).

- `$specs`:

  The specs list used for this run (may differ from input if
  `world_evolution = TRUE`).

- `$progress`:

  A data frame of per-tick logged statistics (same as
  `get_run_data(env)$ticks`).

- `$deaths`:

  A data frame of per-death records (same as
  `get_run_data(env)$deaths`).

- `$genome_log`:

  A list of per-tick genome matrices (non-NULL only when
  `specs$log_genomes = TRUE`).

## Details

The R-Julia boundary is crossed **once per call** regardless of
simulation length or agent count. This contrasts with Rcpp-based
simulators (including alifeR) where data is marshalled across the R-C++
boundary on every tick.

## See also

[`default_specs()`](default_specs.md),
[`get_run_data()`](get_run_data.md), [`batch_alife()`](batch_alife.md),
[`search_map_elites()`](search_map_elites.md)

## Examples

``` r
if (FALSE) { # \dontrun{
specs <- default_specs()
env   <- run_alife(specs)
data  <- get_run_data(env)
plot_run(data)

# Diploid run
specs$ploidy <- 2L
env2 <- run_alife(specs)

# BNN with epigenetics
specs$brain_type  <- "bnn"
specs$epigenetics <- TRUE
env3 <- run_alife(specs)
} # }
```
