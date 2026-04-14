# Template for tests/testthat/test-scenario-signals.R.
#
# One direction-only test per scenario with an oracle. The test runs a
# minimal-but-sufficient version of the displayed specs and asserts that the
# primary metric moves in the expected direction (or is peak-then-decline for
# epidemics, nonzero for count metrics, etc.). Magnitude is NOT asserted —
# these tests must be robust to seed noise.
#
# This file is the *template*. The real tests/testthat/test-scenario-signals.R
# is generated from dev/audit/scenario_oracle.R at Phase 5c, using the spec
# overrides established during Phase 4 (where TOO_SMALL scenarios were
# bumped to the working scale).

skip_unless_julia <- function() {
  skip_if_not_installed("JuliaConnectoR")
  skip_if_not(julia_is_ready(), "Julia session not ready")
}

.early_vs_late <- function(x) {
  x <- x[is.finite(x)]; n <- length(x)
  if (n < 4) return(c(early = NA_real_, late = NA_real_))
  c(early = mean(x[seq_len(max(1L, floor(n / 4)))]),
    late  = mean(x[seq.int(max(1L, floor(3 * n / 4)), n)]))
}

.direction_of <- function(x) {
  el <- .early_vs_late(x)
  if (is.na(el[["early"]]) || is.na(el[["late"]])) return(NA_character_)
  if (el[["late"]] > el[["early"]] * 1.1)  return("up")
  if (el[["late"]] < el[["early"]] * 0.9)  return("down")
  "flat"
}

# Example (replicated for each scenario in the oracle):
test_that("scenario s-dispersal-ifd: mean_dispersal rises at the front", {
  skip_unless_julia()
  specs <- default_specs()
  specs$dispersal_evolution <- TRUE
  specs$spatial_sorting     <- TRUE
  specs$max_ticks           <- 600L   # filled from Phase 4 audit
  specs$n_agents_init       <- 120L
  env  <- run_alife(specs, verbose = FALSE)
  data <- get_run_data(env)
  expect_equal(.direction_of(data$ticks$mean_dispersal), "up")
})
