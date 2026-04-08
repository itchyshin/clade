# Tests for metabolic rate evolution parameters.
#
# All five parameters (metabolic_rate_evolution, metabolic_rate_init_mean,
# metabolic_rate_min, metabolic_rate_max, metabolic_rate_mutation_sd)
# ARE present in default_specs() and are tested here.

library(testthat)

# ── 1. metabolic_rate_evolution is present in default_specs() ─────────────────
test_that("metabolic_rate_evolution is present in default_specs()", {
  expect_true("metabolic_rate_evolution" %in% names(default_specs()))
})

# ── 2. metabolic_rate_evolution defaults to FALSE ─────────────────────────────
test_that("metabolic_rate_evolution defaults to FALSE", {
  expect_false(default_specs()$metabolic_rate_evolution)
})

# ── 3. metabolic_rate_evolution is a logical scalar ───────────────────────────
test_that("metabolic_rate_evolution is a logical scalar", {
  val <- default_specs()$metabolic_rate_evolution
  expect_true(is.logical(val) && length(val) == 1L)
})

# ── 4. metabolic_rate_init_mean is present and equals 1.0 ────────────────────
test_that("metabolic_rate_init_mean is present and defaults to 1.0", {
  s <- default_specs()
  expect_true("metabolic_rate_init_mean" %in% names(s))
  expect_equal(s$metabolic_rate_init_mean, 1.0)
})

# ── 5. metabolic_rate_min is present and equals 0.1 ──────────────────────────
test_that("metabolic_rate_min is present and defaults to 0.1", {
  s <- default_specs()
  expect_true("metabolic_rate_min" %in% names(s))
  expect_equal(s$metabolic_rate_min, 0.1)
})

# ── 6. metabolic_rate_max is present and equals 5.0 ──────────────────────────
test_that("metabolic_rate_max is present and defaults to 5.0", {
  s <- default_specs()
  expect_true("metabolic_rate_max" %in% names(s))
  expect_equal(s$metabolic_rate_max, 5.0)
})

# ── 7. metabolic_rate_min < metabolic_rate_max ───────────────────────────────
test_that("metabolic_rate_min is strictly less than metabolic_rate_max", {
  s <- default_specs()
  expect_lt(s$metabolic_rate_min, s$metabolic_rate_max)
})

# ── 8. metabolic_rate_mutation_sd is present ──────────────────────────────────
test_that("metabolic_rate_mutation_sd is present in default_specs()", {
  expect_true("metabolic_rate_mutation_sd" %in% names(default_specs()))
})

# ── 9. metabolic_rate_mutation_sd defaults to 0.05 ───────────────────────────
test_that("metabolic_rate_mutation_sd defaults to 0.05", {
  expect_equal(default_specs()$metabolic_rate_mutation_sd, 0.05)
})

# ── 10. metabolic_rate_init_mean is within [min, max] ────────────────────────
test_that("metabolic_rate_init_mean is within [metabolic_rate_min, metabolic_rate_max]", {
  s <- default_specs()
  expect_gte(s$metabolic_rate_init_mean, s$metabolic_rate_min)
  expect_lte(s$metabolic_rate_init_mean, s$metabolic_rate_max)
})
