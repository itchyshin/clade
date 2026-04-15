# Tests for the 0.3.0 Batesian mimicry mode
# (specs$batesian_mimicry = TRUE).

.skip_unless_julia <- function() {
  skip_if_not_installed("JuliaConnectoR")
  skip_on_cran()
}

test_that("batesian_mimicry defaults to FALSE", {
  expect_false(default_specs()$batesian_mimicry)
})

test_that("batesian_mimicry is in default_specs", {
  expect_true("batesian_mimicry" %in% names(default_specs()))
})

test_that("Müllerian mode (default): toxicity_cost_per_tick is 2.0 post-0.3.0", {
  # Handicap-principle honesty: toxicity_cost_per_tick should be meaningful
  # relative to idle_cost (0.5). Raised from 0.5 -> 2.0 in 0.3.0.
  s <- default_specs()
  expect_equal(s$toxicity_cost_per_tick, 2.0)
  expect_gt(s$toxicity_cost_per_tick, s$idle_cost)
})

test_that("Müllerian run produces mean_toxicity trajectory and avoided-attack counter", {
  .skip_unless_julia()

  s <- default_specs()
  s$mimicry           <- TRUE
  s$batesian_mimicry  <- FALSE   # Müllerian only
  s$n_agents_init     <- 40L
  s$n_predators_init  <- 3L
  s$max_ticks         <- 30L
  s$grid_rows         <- 15L
  s$grid_cols         <- 15L
  s$toxicity_init_mean <- 0.3
  s$random_seed       <- 42L

  env  <- run_alife(s, verbose = FALSE)
  data <- get_run_data(env)

  expect_true("mean_toxicity" %in% names(data$ticks))
  expect_true("n_avoided_attacks" %in% names(data$ticks))
  expect_true("n_toxic_attacks"   %in% names(data$ticks))
  expect_true(all(data$ticks$n_avoided_attacks >= 0))
})

test_that("Batesian run completes and logs the same counters", {
  .skip_unless_julia()

  s <- default_specs()
  s$mimicry           <- TRUE
  s$batesian_mimicry  <- TRUE
  s$n_agents_init     <- 40L
  s$n_predators_init  <- 3L
  s$max_ticks         <- 30L
  s$grid_rows         <- 15L
  s$grid_cols         <- 15L
  s$toxicity_init_mean <- 0.3
  s$random_seed       <- 42L

  env  <- run_alife(s, verbose = FALSE)
  data <- get_run_data(env)

  # Counters exist and are non-negative (direction-only test; exact
  # magnitudes depend on seed).
  expect_true("n_avoided_attacks" %in% names(data$ticks))
  expect_true(all(data$ticks$n_avoided_attacks >= 0))
  # Simulation survived to the end.
  expect_equal(env$t, s$max_ticks)
})
