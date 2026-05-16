# Tests for the Wolf et al. 2008 PNAS responsive-personalities module (added 0.7.0).
#
# Wolf 2008's headline prediction: under negative frequency-dependent
# selection, responsive and unresponsive types coexist. clade's
# spatially-explicit implementation captures the mechanism — responsive
# agents pay a cost to sample local state and override their action
# toward the richest free cardinal-neighbour cell — but the equilibrium
# polymorphism Wolf reports requires careful parameter tuning. The tests
# below verify the MECHANISM works (trait moves under selection) without
# asserting the specific frequency-dependent coexistence Wolf reports
# (which requires a per-resource competition denominator we have not
# implemented; see vignette for the discussion).

library(testthat)

.WOLF2008_TEST_TICKS <- 2000L
.WOLF2008_TEST_SEED  <- 42L

# Helper: extract mean responsiveness trait at end of run
.mean_responsiveness <- function(env) {
  recs  <- env$agents
  alive <- vapply(seq_along(recs), function(i) as.logical(recs[[i]]$alive),
                  logical(1L))
  if (sum(alive) < 5L) return(NA_real_)
  mean(vapply(seq_along(recs)[alive],
              function(i) as.numeric(recs[[i]]$responsiveness),
              numeric(1L)))
}

test_that("wolf2008_responsiveness_specs() returns a valid spec list", {
  s <- wolf2008_responsiveness_specs()
  expect_type(s, "list")
  expect_true(s$responsive_personalities)
  expect_equal(s$ploidy, 1L)
  expect_true("responsiveness_init_mean" %in% names(s))
  expect_true("responsiveness_cost"      %in% names(s))
})

# Pin every value documented in the roxygen `@details` table so future
# drift between docstring and code is caught immediately. Same pattern as
# `test-presets.R`'s "documented values match code" block (Phase A item 8).
test_that("wolf2008_responsiveness_specs() documented values match code", {
  s <- wolf2008_responsiveness_specs()
  expect_true(s$responsive_personalities)
  expect_equal(s$responsiveness_cost, 0.1)  # calibrated below default's 0.4
  expect_equal(s$grid_rows,           30L)
  expect_equal(s$grid_cols,           30L)
  expect_equal(s$n_agents_init,       200L)
  expect_equal(s$max_agents,          800L)
  expect_equal(s$max_ticks,           3000L)
  expect_equal(s$ploidy,              1L)
})

test_that("wolf2008_responsiveness_specs() does not mutate default_specs()", {
  baseline <- default_specs()
  invisible(wolf2008_responsiveness_specs())
  expect_identical(default_specs(), baseline)
})

test_that("responsive_personalities defaults to FALSE in default_specs()", {
  expect_false(default_specs()$responsive_personalities)
})

test_that("Wolf 2008 scenario completes a short run without error", {
  skip_no_julia()
  s <- wolf2008_responsiveness_specs()
  s$max_ticks   <- 200L
  s$random_seed <- 1L
  expect_no_error(env <- suppressWarnings(run_alife(s, verbose = FALSE)))
  d <- get_run_data(env)$ticks
  expect_true(tail(d$n_agents, 1) > 0L)
})

test_that("responsiveness is under selection (trait moves vs no-module baseline)", {
  skip_no_julia()
  skip_on_cran()                # 2× 2000-tick runs is slow

  # No-module baseline: trait drifts
  s_off <- wolf2008_responsiveness_specs()
  s_off$responsive_personalities <- FALSE
  s_off$max_ticks                <- .WOLF2008_TEST_TICKS
  s_off$random_seed              <- .WOLF2008_TEST_SEED
  env_off <- suppressWarnings(run_alife(s_off, verbose = FALSE))
  off_resp <- .mean_responsiveness(env_off)

  # Module on: trait should move (in either direction) — selection signal
  s_on <- wolf2008_responsiveness_specs()
  s_on$max_ticks   <- .WOLF2008_TEST_TICKS
  s_on$random_seed <- .WOLF2008_TEST_SEED
  env_on <- suppressWarnings(run_alife(s_on, verbose = FALSE))
  on_resp <- .mean_responsiveness(env_on)

  message(sprintf(
    "Wolf 2008 responsiveness — off (drift): %.3f  on (selection): %.3f  delta: %+.3f",
    off_resp, on_resp, on_resp - off_resp))

  skip_if(is.na(off_resp) || is.na(on_resp),
          "not enough live agents to compare responsiveness")

  # Selection signal: with the module on, the trait should differ from
  # pure drift by at least 0.05 (in EITHER direction — clade's
  # implementation may select for or against responsiveness depending on
  # the local cost/benefit balance, which is itself frequency-dependent).
  expect_true(abs(on_resp - off_resp) > 0.05,
              info = sprintf(
                "Module on should move trait. off=%.3f on=%.3f |delta|=%.3f",
                off_resp, on_resp, abs(on_resp - off_resp)))
})
