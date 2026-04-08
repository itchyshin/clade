# Tests for clutch size evolution parameters.
#
# The basic parental care parameter max_clutch_size exists. The evolvable clutch
# size module parameters (clutch_size_evolution, clutch_size_init_mean,
# clutch_size_min, clutch_size_max, clutch_size_mutation_sd) do NOT yet exist
# in default_specs(). Failing tests document what needs to be added to config.R.

library(testthat)

# ── 1. max_clutch_size is present in default_specs() ─────────────────────────
test_that("max_clutch_size is present in default_specs()", {
  expect_true("max_clutch_size" %in% names(default_specs()))
})

# ── 2. max_clutch_size defaults to 1 ─────────────────────────────────────────
test_that("max_clutch_size defaults to 1", {
  s <- default_specs()
  expect_equal(s$max_clutch_size, 1L)
})

# ── 3. max_clutch_size is integer-like ───────────────────────────────────────
test_that("max_clutch_size is integer-like", {
  val <- default_specs()$max_clutch_size
  expect_true(is.integer(val) || (is.numeric(val) && val == as.integer(val)))
})

# ── 4. clutch_size_evolution is present in default_specs() ───────────────────
# NOTE: not yet implemented — test documents what is needed.
test_that("clutch_size_evolution is present in default_specs()", {
  expect_true("clutch_size_evolution" %in% names(default_specs()))
})

# ── 5. clutch_size_evolution defaults to FALSE ────────────────────────────────
test_that("clutch_size_evolution defaults to FALSE", {
  expect_false(default_specs()$clutch_size_evolution)
})

# ── 6. clutch_size_init_mean is present in default_specs() ───────────────────
test_that("clutch_size_init_mean is present in default_specs()", {
  expect_true("clutch_size_init_mean" %in% names(default_specs()))
})

# ── 7. clutch_size_min is present and is integer-like ────────────────────────
test_that("clutch_size_min is present and is integer-like", {
  s <- default_specs()
  expect_true("clutch_size_min" %in% names(s))
  val <- s$clutch_size_min
  expect_true(is.integer(val) || (is.numeric(val) && val == as.integer(val)))
})

# ── 8. clutch_size_max is present and is integer-like ────────────────────────
test_that("clutch_size_max is present and is integer-like", {
  s <- default_specs()
  expect_true("clutch_size_max" %in% names(s))
  val <- s$clutch_size_max
  expect_true(is.integer(val) || (is.numeric(val) && val == as.integer(val)))
})

# ── 9. clutch_size_min < clutch_size_max ─────────────────────────────────────
test_that("clutch_size_min is strictly less than clutch_size_max", {
  s <- default_specs()
  expect_lt(s$clutch_size_min, s$clutch_size_max)
})

# ── 10. clutch_size_mutation_sd is present in default_specs() ────────────────
test_that("clutch_size_mutation_sd is present in default_specs()", {
  expect_true("clutch_size_mutation_sd" %in% names(default_specs()))
})
