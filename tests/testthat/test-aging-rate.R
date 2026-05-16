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

# ── 9. aging_rate_min bound is respected (>= 0) ──────────────────────────────
test_that("aging_rate_min is non-negative", {
  expect_gte(default_specs()$aging_rate_min, 0.0)
})

# ── 10. aging_rate_max bound is finite and positive ──────────────────────────
test_that("aging_rate_max is finite and positive", {
  val <- default_specs()$aging_rate_max
  expect_true(is.finite(val))
  expect_gt(val, 0.0)
})

# ── 11. aging_rate_evolution defaults to FALSE ───────────────────────────────
test_that("aging_rate_evolution = FALSE is the default", {
  expect_identical(default_specs()$aging_rate_evolution, FALSE)
})

# ── 12. aging_rate_init_mean defaults to 1.0 ─────────────────────────────────
test_that("aging_rate_init_mean defaults to 1.0", {
  expect_equal(default_specs()$aging_rate_init_mean, 1.0)
})

# ── 13. senescence_shape defaults to 1.0 ─────────────────────────────────────
# Was 2.0 pre-PR #116 (squarer Gompertz curve); lowered to 1.0 so the
# default approximates exponential mortality. Code is in R/config.R.
test_that("senescence_shape defaults to 1.0", {
  expect_equal(default_specs()$senescence_shape, 1.0)
})

# ── 14. default senescence_rate is in [0, 0.1) range ─────────────────────────
test_that("default senescence_rate is in [0, 0.1) range", {
  sr <- default_specs()$senescence_rate
  expect_gte(sr, 0.0)
  expect_lt(sr, 0.1)
})

# ── 15. aging_rate_init_mean is within [aging_rate_min, aging_rate_max] ──────
# (duplicates intent of test 7 but checks the actual default value 1.0 directly)
test_that("aging_rate_init_mean value 1.0 satisfies the min/max bounds", {
  s <- default_specs()
  expect_true(s$aging_rate_init_mean >= s$aging_rate_min &&
                s$aging_rate_init_mean <= s$aging_rate_max)
})
