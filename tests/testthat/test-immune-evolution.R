# Tests for immune system evolution parameters.
#
# All five parameters (immune_evolution, immune_strength_init_mean,
# immune_strength_min, immune_strength_max, immune_strength_mutation_sd)
# ARE present in default_specs() and are tested here.

library(testthat)

# ── 1. immune_evolution is present in default_specs() ────────────────────────
test_that("immune_evolution is present in default_specs()", {
  expect_true("immune_evolution" %in% names(default_specs()))
})

# ── 2. immune_evolution defaults to FALSE ────────────────────────────────────
test_that("immune_evolution defaults to FALSE", {
  expect_false(default_specs()$immune_evolution)
})

# ── 3. immune_evolution is a logical scalar ───────────────────────────────────
test_that("immune_evolution is a logical scalar", {
  val <- default_specs()$immune_evolution
  expect_true(is.logical(val) && length(val) == 1L)
})

# ── 4. immune_strength_init_mean is present ───────────────────────────────────
test_that("immune_strength_init_mean is present in default_specs()", {
  expect_true("immune_strength_init_mean" %in% names(default_specs()))
})

# ── 5. immune_strength_init_mean is in [0, 1] ────────────────────────────────
test_that("immune_strength_init_mean is in [0, 1]", {
  val <- default_specs()$immune_strength_init_mean
  expect_gte(val, 0.0)
  expect_lte(val, 1.0)
})

# ── 6. immune_strength_min is present and equals 0.0 ─────────────────────────
test_that("immune_strength_min is present and defaults to 0.0", {
  s <- default_specs()
  expect_true("immune_strength_min" %in% names(s))
  expect_equal(s$immune_strength_min, 0.0)
})

# ── 7. immune_strength_max is present and equals 1.0 ─────────────────────────
test_that("immune_strength_max is present and defaults to 1.0", {
  s <- default_specs()
  expect_true("immune_strength_max" %in% names(s))
  expect_equal(s$immune_strength_max, 1.0)
})

# ── 8. immune_strength_min < immune_strength_max ─────────────────────────────
test_that("immune_strength_min is strictly less than immune_strength_max", {
  s <- default_specs()
  expect_lt(s$immune_strength_min, s$immune_strength_max)
})

# ── 9. immune_strength_mutation_sd is present ─────────────────────────────────
test_that("immune_strength_mutation_sd is present in default_specs()", {
  expect_true("immune_strength_mutation_sd" %in% names(default_specs()))
})

# ── 10. immune_strength_mutation_sd is non-negative ──────────────────────────
test_that("immune_strength_mutation_sd is non-negative", {
  expect_gte(default_specs()$immune_strength_mutation_sd, 0.0)
})
