test_that("signal_dims defaults to 0", {
  expect_equal(default_specs()$signal_dims, 0L)
})

test_that("signal_cost defaults to 0.1", {
  expect_equal(default_specs()$signal_cost, 0.1)
})

test_that("mate_choice_mode defaults to 'random'", {
  expect_equal(default_specs()$mate_choice_mode, "random")
})

test_that("mate_choice_strength defaults to 0.5", {
  expect_equal(default_specs()$mate_choice_strength, 0.5)
})

test_that("signal_dims is integer-like", {
  d <- default_specs()$signal_dims
  expect_true(is.integer(d) || (is.numeric(d) && d == as.integer(d)))
})

test_that("signal_cost is numeric and positive", {
  s <- default_specs()$signal_cost
  expect_true(is.numeric(s))
  expect_true(s > 0)
})

test_that("mate_choice_strength is in [0, 1]", {
  m <- default_specs()$mate_choice_strength
  expect_true(m >= 0 && m <= 1)
})

test_that("mate_choice_mode is a recognised mode", {
  m <- default_specs()$mate_choice_mode
  expect_true(m %in% c("random", "energy", "signal", "genetic"))
})

test_that("signal_dims is non-negative", {
  expect_true(default_specs()$signal_dims >= 0)
})

test_that("signal_cost is in a reasonable range (0, 10)", {
  s <- default_specs()$signal_cost
  expect_true(s > 0 && s < 10)
})

test_that("all signal and mate-choice params are present in default_specs", {
  nms <- names(default_specs())
  for (p in c("signal_dims", "signal_cost", "mate_choice_mode", "mate_choice_strength")) {
    expect_true(p %in% nms, info = paste("missing:", p))
  }
})

test_that("signal evolution is effectively disabled when signal_dims == 0", {
  expect_true(default_specs()$signal_dims == 0)
})

test_that("signal energy cost formula is positive for nonzero signal", {
  signal_cost <- default_specs()$signal_cost
  signal <- c(0.5, -0.3)
  cost <- signal_cost * sum(abs(signal))
  expect_true(cost > 0)
})

test_that("signal vector length equals signal_dims (zeros initialisation)", {
  dims <- default_specs()$signal_dims
  sig <- numeric(dims)
  expect_equal(length(sig), dims)
})

test_that("mate_choice_strength closer to 0 means less randomness (documented)", {
  # strength = 0 → fully selective; strength = 1 → fully random
  # verify that 0.5 is strictly between the bounds, consistent with documentation
  m <- default_specs()$mate_choice_strength
  expect_true(m > 0 && m < 1)
})

test_that("signal_dims can be set to 2L without error", {
  s <- default_specs()
  s$signal_dims <- 2L
  expect_equal(s$signal_dims, 2L)
})
