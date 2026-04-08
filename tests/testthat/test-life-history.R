# Tests for life history trait parameters.
#
# Covers: life_history, senescence_rate, repro_senescence, max_age,
#         life_history_evolution, allee_threshold.
# min_repro_age is NOT yet in default_specs() — that test will fail and
# document what needs to be added to config.R.

library(testthat)

# ── 1. life_history is present in default_specs() ────────────────────────────
test_that("life_history is present in default_specs()", {
  expect_true("life_history" %in% names(default_specs()))
})

# ── 2. life_history defaults to "iteroparous" ─────────────────────────────────
test_that("life_history defaults to \"iteroparous\"", {
  expect_equal(default_specs()$life_history, "iteroparous")
})

# ── 3. life_history is one of the valid options ───────────────────────────────
test_that("life_history default is one of the valid options", {
  valid <- c("iteroparous", "semelparous")
  expect_true(default_specs()$life_history %in% valid)
})

# ── 4. senescence_rate is present and defaults to 0.0 ────────────────────────
test_that("senescence_rate is present and defaults to 0.0", {
  s <- default_specs()
  expect_true("senescence_rate" %in% names(s))
  expect_equal(s$senescence_rate, 0.0)
})

# ── 5. senescence_rate is non-negative ───────────────────────────────────────
test_that("senescence_rate is non-negative", {
  expect_gte(default_specs()$senescence_rate, 0.0)
})

# ── 6. repro_senescence is present and defaults to 0.0 ───────────────────────
test_that("repro_senescence is present and defaults to 0.0", {
  s <- default_specs()
  expect_true("repro_senescence" %in% names(s))
  expect_equal(s$repro_senescence, 0.0)
})

# ── 7. repro_senescence is non-negative ──────────────────────────────────────
test_that("repro_senescence is non-negative", {
  expect_gte(default_specs()$repro_senescence, 0.0)
})

# ── 8. max_age is present and is integer-like ────────────────────────────────
test_that("max_age is present and is integer-like", {
  s <- default_specs()
  expect_true("max_age" %in% names(s))
  val <- s$max_age
  expect_true(is.integer(val) || (is.numeric(val) && val == as.integer(val)))
})

# ── 9. max_age is strictly positive ──────────────────────────────────────────
test_that("max_age is strictly positive", {
  expect_gt(default_specs()$max_age, 0L)
})

# ── 10. life_history_evolution is present and defaults to FALSE ───────────────
test_that("life_history_evolution is present and defaults to FALSE", {
  s <- default_specs()
  expect_true("life_history_evolution" %in% names(s))
  expect_false(s$life_history_evolution)
})

# ── 11. allee_threshold is present and defaults to 0 ─────────────────────────
test_that("allee_threshold is present and defaults to 0", {
  s <- default_specs()
  expect_true("allee_threshold" %in% names(s))
  expect_equal(s$allee_threshold, 0L)
})

# ── 12. min_repro_age is present in default_specs() ──────────────────────────
# NOTE: not yet implemented — test documents what is needed.
test_that("min_repro_age is present in default_specs()", {
  expect_true("min_repro_age" %in% names(default_specs()))
})
