# Tests for the random_tick_order spec field (added in 0.7.0).
#
# Background: prior to 0.7.0, every iteration over env.agents and env.predators
# happened in fixed array order, biasing foraging / mate selection / cell
# claims toward earlier-array agents. The fix is random asynchronous
# scheduling per Grimm & Railsback (2005); see dev/audit/iteration-sites.md
# for the full call-site catalogue.
#
# The tests here verify three properties:
#  1. With random_tick_order = TRUE and the same seed, two runs are identical
#     (the shuffle is RNG-deterministic, not ad-hoc).
#  2. With order TRUE vs FALSE at the same seed, runs differ in measurable
#     output — proving the flag actually does something.
#  3. With order TRUE and different seeds, runs differ — confirming the
#     shuffle is consuming RNG.

library(testthat)

# Small scenario big enough that order-bias has measurable effect.
# 30x30 grid with 60 initial agents → typical density where multiple agents
# share / compete for cells, which is where the bias manifests.
.tick_order_specs <- function(seed, random_tick_order = TRUE) {
  s <- default_specs()
  s$grid_rows         <- 30L
  s$grid_cols         <- 30L
  s$n_agents_init     <- 60L
  s$max_ticks         <- 200L
  s$max_agents        <- 500L
  s$random_seed       <- as.integer(seed)
  s$random_tick_order <- random_tick_order
  s
}

# Stable summary of a run for comparison. Uses end-state aggregates that are
# sensitive to tick-order bias (population size, mean energy, total deaths).
.run_summary <- function(env) {
  d <- get_run_data(env)$ticks
  list(
    n_final     = tail(d$n_agents,      1L),
    mean_energy = tail(d$mean_energy,   1L),
    deaths_tot  = sum(d$deaths,    na.rm = TRUE),
    births_tot  = sum(d$n_births,  na.rm = TRUE)
  )
}

test_that("default_specs() includes random_tick_order = TRUE", {
  s <- default_specs()
  expect_true("random_tick_order" %in% names(s),
              info = "random_tick_order field missing from default_specs()")
  expect_true(isTRUE(s$random_tick_order),
              info = "default should be TRUE per Grimm & Railsback 2005")
})

test_that("random_tick_order = TRUE with same seed is reproducible", {
  skip_no_julia()
  a <- run_alife(.tick_order_specs(seed = 42L, random_tick_order = TRUE),
                 verbose = FALSE)
  b <- run_alife(.tick_order_specs(seed = 42L, random_tick_order = TRUE),
                 verbose = FALSE)
  expect_identical(.run_summary(a), .run_summary(b),
                   info = "shuffle must be RNG-deterministic")
})

test_that("random_tick_order = TRUE vs FALSE produce different results at same seed", {
  skip_no_julia()
  on  <- run_alife(.tick_order_specs(seed = 42L, random_tick_order = TRUE),
                   verbose = FALSE)
  off <- run_alife(.tick_order_specs(seed = 42L, random_tick_order = FALSE),
                   verbose = FALSE)
  expect_false(identical(.run_summary(on), .run_summary(off)),
               info = "the flag must actually change behaviour; if these match, the shuffle is not wired")
})

test_that("random_tick_order = TRUE with different seeds produces different results", {
  skip_no_julia()
  a <- run_alife(.tick_order_specs(seed = 1L,  random_tick_order = TRUE),
                 verbose = FALSE)
  b <- run_alife(.tick_order_specs(seed = 2L,  random_tick_order = TRUE),
                 verbose = FALSE)
  expect_false(identical(.run_summary(a), .run_summary(b)),
               info = "shuffle must be consuming env.rng; if these match, RNG is not threaded")
})
