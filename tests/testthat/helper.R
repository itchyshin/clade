# helpers for clade tests
# All tests that do NOT require Julia are pure R (no .clade_start_julia()).
# Tests that require Julia are wrapped in skip_if_not(julia_is_ready()) or
# marked with skip("requires Julia") to keep CRAN check clean.

.minimal_specs <- function(...) {
  s <- default_specs()
  s$grid_rows        <- 10L
  s$grid_cols        <- 10L
  s$n_agents_init    <- 5L
  s$max_ticks        <- 5L
  s$max_agents       <- 50L
  args <- list(...)
  for (nm in names(args)) s[[nm]] <- args[[nm]]
  s
}
