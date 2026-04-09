test_that("seasonal_amplitude defaults to 0", {
  expect_equal(default_specs()$seasonal_amplitude, 0.0)
})

test_that("season_length defaults to 100L", {
  expect_equal(default_specs()$season_length, 100L)
})

test_that("winter_death_prob defaults to 0", {
  expect_equal(default_specs()$winter_death_prob, 0.0)
})

test_that("seasonal params present in default_specs", {
  nms <- names(default_specs())
  for (p in c("seasonal_amplitude", "season_length", "winter_death_prob")) {
    expect_true(p %in% nms, info = paste("missing:", p))
  }
})

test_that("seasonal_amplitude is numeric", {
  expect_true(is.numeric(default_specs()$seasonal_amplitude))
})

test_that("season_length is positive integer-like", {
  sl <- default_specs()$season_length
  expect_true(sl > 0)
  expect_true(is.integer(sl) || (is.numeric(sl) && sl == as.integer(sl)))
})

test_that("winter_death_prob is in [0, 1]", {
  wdp <- default_specs()$winter_death_prob
  expect_true(wdp >= 0 && wdp <= 1)
})

test_that("winter phase is sin < 0: second half of cycle", {
  # At t = 75, season_length = 100: sin(2*pi*75/100) = sin(3*pi/2) = -1 < 0
  season_length <- 100
  t <- 75
  phase <- sin(2 * pi * t / season_length)
  expect_true(phase < 0)
})

test_that("summer phase is sin >= 0: first half of cycle", {
  season_length <- 100
  t <- 25
  phase <- sin(2 * pi * t / season_length)
  expect_true(phase >= 0)
})

test_that("seasonal grass modulation formula is >1 in summer", {
  amplitude <- 0.5
  season_length <- 100
  t <- 25  # summer
  factor <- 1 + amplitude * sin(2 * pi * t / season_length)
  expect_true(factor > 1.0)
})

test_that("seasonal grass modulation formula is <1 in winter", {
  amplitude <- 0.5
  season_length <- 100
  t <- 75  # winter
  factor <- 1 + amplitude * sin(2 * pi * t / season_length)
  expect_true(factor < 1.0)
})

test_that("winter_death_prob defaults to 0.0", {
  expect_equal(default_specs()$winter_death_prob, 0.0)
})

test_that("season_length defaults to 100L", {
  sl <- default_specs()$season_length
  expect_equal(sl, 100L)
  expect_true(is.integer(sl))
})

test_that("seasonal_amplitude defaults to 0.0", {
  expect_equal(default_specs()$seasonal_amplitude, 0.0)
})

test_that("seasonal_amplitude is a valid descriptor column for MAP-Elites search", {
  # seasonal_amplitude is a spec parameter, not a tick-logged column; however,
  # it can be swept during MAP-Elites. The spec name itself should be accessible.
  expect_true("seasonal_amplitude" %in% names(default_specs()))
})
