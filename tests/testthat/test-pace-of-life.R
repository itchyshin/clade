# Tests for pace-of-life syndrome parameters — no Julia required.
#
# Pace-of-life syndrome (POLS) describes the covariation between metabolic
# rate, growth, reproduction, and lifespan across species and individuals.
# Fast life histories pair high metabolism with early reproduction and short
# life; slow life histories pair low metabolism with late reproduction and
# long life.

library(testthat)

# ── 1. senescence_rate defaults to 0 ─────────────────────────────────────────
test_that("senescence_rate defaults to 0", {
  expect_equal(default_specs()$senescence_rate, 0.0)
})

# ── 2. senescence_rate >= 0 (cannot be negative) ─────────────────────────────
test_that("senescence_rate default is non-negative", {
  expect_gte(default_specs()$senescence_rate, 0.0)
})

# ── 3. aging_rate_evolution is logical ───────────────────────────────────────
test_that("aging_rate_evolution is logical", {
  expect_type(default_specs()$aging_rate_evolution, "logical")
})

# ── 7. fast life history: metabolic_rate_max > metabolic_rate_min ─────────────
test_that("fast life history axis: metabolic_rate_max > metabolic_rate_min", {
  s <- default_specs()
  expect_gt(s$metabolic_rate_max, s$metabolic_rate_min)
})

# ── 8. slow life history: senescence_rate = 0 implies no Gompertz mortality ───
test_that("senescence_rate = 0 implies exp(0 * age) = 1 (no excess mortality)", {
  # Per the Gompertz model: per-tick death probability scales as
  # exp(senescence_rate * age). With rate = 0 this is exp(0) = 1 for any age,
  # meaning the multiplier contributes no additional mortality.
  rate <- default_specs()$senescence_rate
  for (age in c(0L, 10L, 50L, 100L, 200L)) {
    expect_equal(exp(rate * age), 1.0,
                 tolerance = .Machine$double.eps^0.5,
                 info = sprintf("exp(%g * %d) should be 1.0", rate, age))
  }
})
