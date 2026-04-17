# CLAUDE.md

Guidance for Claude Code (and other LLM assistants) working in this
repository.

## Project overview

**clade** is an R package providing an agent-based evolutionary
simulation with a Julia backend. R is the user-facing interface (specs,
runs, analysis, plots); the per-tick simulation kernel lives in Julia
and is called once per [`run_alife()`](reference/run_alife.md) via
`JuliaConnectoR`, so the R↔︎Julia boundary is crossed once per run, not
per tick.

Key facts: - R package layout (`DESCRIPTION`, `NAMESPACE`, `R/`, `man/`,
`tests/testthat/`, `vignettes/`). - Julia kernel under `inst/julia/`
(own `Project.toml`/`Manifest.toml`, sources in `inst/julia/src/`). -
Cached simulation outputs in `Rdata/*.rds` (used by vignettes/figures so
they render without re-running). - pkgdown site config: `_pkgdown.yml`.
Docs published at <https://itchyshin.github.io/clade/>.

## Repository map

| Path                                                                  | Purpose                                                                                                                                                                                                            |
|-----------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `R/run.R`                                                             | [`run_alife()`](reference/run_alife.md), [`batch_alife()`](reference/batch_alife.md) — main entry points                                                                                                           |
| `R/config.R`                                                          | [`default_specs()`](reference/default_specs.md), [`quick_specs()`](reference/quick_specs.md), [`full_specs()`](reference/full_specs.md), [`load_specs()`](reference/load_specs.md)                                 |
| `R/scenarios.R`                                                       | Pre-baked scenario specs and tuning helpers                                                                                                                                                                        |
| `R/modules.R`                                                         | [`register_module()`](reference/register_module.md), custom per-tick R hooks                                                                                                                                       |
| `R/analysis.R`                                                        | [`get_run_data()`](reference/get_run_data.md), [`compute_ld()`](reference/compute_ld.md), heritability, relatedness                                                                                                |
| `R/visualization.R`                                                   | [`plot_run()`](reference/plot_run.md), [`plot_diversity()`](reference/plot_diversity.md), etc.                                                                                                                     |
| `R/search.R`                                                          | [`search_cmaes()`](reference/search_cmaes.md), [`search_map_elites()`](reference/search_map_elites.md), [`search_gradient()`](reference/search_gradient.md), [`search_viability()`](reference/search_viability.md) |
| `R/maps.R`                                                            | Landscape generation ([`generate_map()`](reference/generate_map.md), [`prepare_map()`](reference/prepare_map.md))                                                                                                  |
| `R/utils.R`, `R/zzz.R`                                                | Helpers and package load hooks                                                                                                                                                                                     |
| `inst/julia/src/Clade.jl`                                             | Julia kernel entry point                                                                                                                                                                                           |
| `inst/julia/src/{tick,sense,reproduce,death,genome,logging,types}.jl` | Core simulation loop                                                                                                                                                                                               |
| `inst/julia/src/brains/`                                              | Brain architectures (BNN, ANN, CTRNN, GRN, transformer, synthesis)                                                                                                                                                 |
| `inst/julia/src/modules/`                                             | Optional biological modules (disease, dispersal, kin, etc.)                                                                                                                                                        |
| `vignettes/*.Rmd`                                                     | Long-form articles and per-scenario showcases (`s-*.Rmd`)                                                                                                                                                          |
| `tests/testthat/test-*.R`                                             | Unit and integration tests                                                                                                                                                                                         |

## Common commands

R-side (run from repo root):

``` r
# Load package for interactive dev (no install required)
devtools::load_all()

# Run all tests
devtools::test()

# Run a single test file
testthat::test_file("tests/testthat/test-config.R")

# Rebuild documentation from roxygen comments
devtools::document()

# Full check (CRAN-style)
devtools::check()

# Build pkgdown site locally (writes to docs/, gitignored)
pkgdown::build_site()
```

Quick smoke run:

``` r
library(clade)
julia_is_ready()         # first call compiles Julia kernel (~60–90 s)
specs <- default_specs()
specs$n_agents_init <- 40L
specs$max_ticks     <- 300L
env <- run_alife(specs)
plot_run(get_run_data(env))
```

Julia-side (only needed for kernel debugging):

``` bash
cd inst/julia
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

## Conventions

- Exports are managed by roxygen → do **not** edit `NAMESPACE` by hand;
  edit `@export` tags in `R/*.R` and run
  [`devtools::document()`](https://devtools.r-lib.org/reference/document.html).
- Public R API surface is everything listed in `NAMESPACE`
  (`export(...)`).
- Specs are plain named lists — see
  [`default_specs()`](reference/default_specs.md) for the canonical
  schema and `vignettes/parameter-reference.Rmd` for documentation.
- Modules are toggled via boolean flags on the specs list
  (e.g. `specs$disease <- TRUE`); see README “Biological modules” table.
- Cached `.rds` files in `Rdata/` are checked into git so vignettes
  render cheaply — regenerate only when the underlying simulation
  changes meaningfully.

## Resource limits (important)

When running parallel sweeps, batch jobs, or anything CPU/memory-heavy
on this machine, **cap at ≤200 cores and target ≲300 GB memory**
(machine has ~1 TB but keep headroom). Flag any job that would exceed
either before launching.

## Two-machine workflow

This repo is also edited from a second machine. Before making
changes: 1. `git pull --rebase` and verify `git status` is clean. 2.
Prefer feature branches over committing directly to `main`. 3. Push
frequently so the other machine can rebase on your work. 4. Avoid
editing the same file as the other machine concurrently — ask if unsure
which area is in flight.

## Things to avoid

- Don’t commit large regenerated artifacts (pkgdown `docs/`,
  `*.Rcheck/`, `.Rhistory` — already gitignored, but double-check).
- Don’t hand-edit `NAMESPACE` or `man/*.Rd` (regenerated by roxygen).
- Don’t bypass `JuliaConnectoR` — there should be exactly one R↔︎Julia
  boundary crossing per [`run_alife()`](reference/run_alife.md) call.
