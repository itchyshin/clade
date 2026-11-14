# Tests for the grass_growth_mode spec (#167).

test_that("default_specs() uses stochastic grass growth by default", {
  expect_identical(default_specs()$grass_growth_mode, "stochastic")
})

test_that(".validate_specs() accepts both grass growth modes", {
  s <- default_specs()
  for (m in c("stochastic", "deterministic")) {
    s$grass_growth_mode <- m
    expect_silent(clade:::.validate_specs(s))
  }
})

test_that(".validate_specs() rejects an unknown grass growth mode", {
  s <- default_specs()
  s$grass_growth_mode <- "continuous"
  expect_error(clade:::.validate_specs(s), "grass_growth_mode")
})

test_that("deterministic run reports grass_density in [0, 1]", {
  skip_no_julia()

  s <- default_specs()
  s$grid_rows         <- 10L
  s$grid_cols         <- 10L
  s$n_agents_init     <- 5L
  s$max_ticks         <- 5L
  s$max_agents        <- 50L
  s$random_seed       <- 42L
  s$grass_growth_mode <- "deterministic"

  env <- suppressWarnings(run_alife(s, verbose = FALSE))
  ticks <- get_run_data(env)$ticks
  expect_true("grass_density" %in% names(ticks))
  expect_true(all(ticks$grass_density >= 0 & ticks$grass_density <= 1))
})
