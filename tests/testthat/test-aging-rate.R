# Tests for aging rate evolution parameters.
#
# Covers the evolvable aging rate module:
#   aging_rate_evolution, aging_rate_min, aging_rate_max, aging_rate_init_mean
# and senescence_shape (Gompertz shape parameter) which is NOT yet in default_specs().
# Failing tests indicate parameters that need to be added to config.R.

library(testthat)

# ── 1. aging_rate_evolution is present in default_specs() ────────────────────
test_that("aging_rate_evolution is present in default_specs()", {
  expect_true("aging_rate_evolution" %in% names(default_specs()))
})

# ── 2. aging_rate_evolution defaults to FALSE ────────────────────────────────
test_that("aging_rate_evolution defaults to FALSE", {
  expect_false(default_specs()$aging_rate_evolution)
})

# ── 3. aging_rate_min is present and equals 0.01 ─────────────────────────────
test_that("aging_rate_min is present and defaults to 0.01", {
  s <- default_specs()
  expect_true("aging_rate_min" %in% names(s))
  expect_equal(s$aging_rate_min, 0.01)
})

# ── 4. aging_rate_max is present and equals 10.0 ─────────────────────────────
test_that("aging_rate_max is present and defaults to 10.0", {
  s <- default_specs()
  expect_true("aging_rate_max" %in% names(s))
  expect_equal(s$aging_rate_max, 10.0)
})

# ── 5. aging_rate_min < aging_rate_max ───────────────────────────────────────
test_that("aging_rate_min is strictly less than aging_rate_max", {
  s <- default_specs()
  expect_lt(s$aging_rate_min, s$aging_rate_max)
})

# ── 6. aging_rate_init_mean is present ───────────────────────────────────────
test_that("aging_rate_init_mean is present in default_specs()", {
  expect_true("aging_rate_init_mean" %in% names(default_specs()))
})

# ── 7. aging_rate_init_mean is within [aging_rate_min, aging_rate_max] ───────
test_that("aging_rate_init_mean is within [aging_rate_min, aging_rate_max]", {
  s <- default_specs()
  expect_gte(s$aging_rate_init_mean, s$aging_rate_min)
  expect_lte(s$aging_rate_init_mean, s$aging_rate_max)
})

# ── 8. senescence_shape is present in default_specs() ────────────────────────
# NOTE: this parameter is not yet implemented — test documents what is needed.
test_that("senescence_shape is present in default_specs()", {
  expect_true("senescence_shape" %in% names(default_specs()))
})
