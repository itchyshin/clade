# Tests for parental investment evolution parameters.
#
# The parental care module exists (parental_care, care_cost_per_tick, etc.)
# but parental investment evolution parameters are NOT yet in default_specs():
#   parental_investment_evolution, parental_investment_init_mean,
#   female_investment, male_repro_cost
# Failing tests document what needs to be added to config.R.

library(testthat)

# ── 1. parental_care is present in default_specs() ───────────────────────────
test_that("parental_care is present in default_specs()", {
  expect_true("parental_care" %in% names(default_specs()))
})

# ── 2. parental_care defaults to FALSE ───────────────────────────────────────
test_that("parental_care defaults to FALSE", {
  expect_false(default_specs()$parental_care)
})

# ── 3. parental_investment_evolution is present in default_specs() ────────────
# NOTE: not yet implemented — test documents what is needed.
test_that("parental_investment_evolution is present in default_specs()", {
  expect_true("parental_investment_evolution" %in% names(default_specs()))
})

# ── 4. parental_investment_evolution defaults to FALSE ────────────────────────
test_that("parental_investment_evolution defaults to FALSE", {
  expect_false(default_specs()$parental_investment_evolution)
})

# ── 5. parental_investment_init_mean is present in default_specs() ────────────
test_that("parental_investment_init_mean is present in default_specs()", {
  expect_true("parental_investment_init_mean" %in% names(default_specs()))
})

# ── 6. parental_investment_init_mean is in (0, 1) ────────────────────────────
test_that("parental_investment_init_mean is in (0, 1)", {
  val <- default_specs()$parental_investment_init_mean
  expect_gt(val, 0.0)
  expect_lt(val, 1.0)
})

# ── 7. female_investment is present in default_specs() ───────────────────────
test_that("female_investment is present in default_specs()", {
  expect_true("female_investment" %in% names(default_specs()))
})

# ── 8. female_investment is in [0, 1] ────────────────────────────────────────
test_that("female_investment is in [0, 1]", {
  val <- default_specs()$female_investment
  expect_gte(val, 0.0)
  expect_lte(val, 1.0)
})

# ── 9. male_repro_cost is present in default_specs() ─────────────────────────
test_that("male_repro_cost is present in default_specs()", {
  expect_true("male_repro_cost" %in% names(default_specs()))
})

# ── 10. male_repro_cost is non-negative ──────────────────────────────────────
test_that("male_repro_cost is non-negative", {
  expect_gte(default_specs()$male_repro_cost, 0.0)
})
