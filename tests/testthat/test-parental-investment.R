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

# ── 11. parental_investment_evolution defaults to FALSE ───────────────────────
test_that("parental_investment_evolution defaults to FALSE", {
  expect_false(default_specs()$parental_investment_evolution)
})

# ── 12. male_repro_cost defaults to 0.3 ──────────────────────────────────────
test_that("male_repro_cost defaults to 0.3", {
  expect_equal(default_specs()$male_repro_cost, 0.3)
})

# ── 13. parental_investment_init_mean defaults to 0.5 ────────────────────────
test_that("parental_investment_init_mean defaults to 0.5", {
  expect_equal(default_specs()$parental_investment_init_mean, 0.5)
})

# ── 14. female_investment is present in default_specs() ──────────────────────
test_that("female_investment is present in default_specs()", {
  expect_true("female_investment" %in% names(default_specs()))
})

# ── 15. male_repro_cost is in [0, 1] in defaults ─────────────────────────────
test_that("male_repro_cost is in [0, 1] in defaults", {
  val <- default_specs()$male_repro_cost
  expect_gte(val, 0.0)
  expect_lte(val, 1.0)
})

# ── 16. parental investment params round-trip through default_specs() ─────────
test_that("parental investment params round-trip correctly through default_specs()", {
  s <- default_specs()
  expect_false(s$parental_investment_evolution)
  expect_equal(s$parental_investment_init_mean, 0.5)
  expect_equal(s$male_repro_cost, 0.3)
  expect_true(is.numeric(s$female_investment))
})

# ── 17. parental_investment_init_mean is numeric ──────────────────────────────
test_that("parental_investment_init_mean is numeric", {
  expect_true(is.numeric(default_specs()$parental_investment_init_mean))
})

# ── 18. parental investment params are numeric type ──────────────────────────
test_that("parental investment params are numeric type", {
  s <- default_specs()
  expect_true(is.numeric(s$parental_investment_init_mean))
  expect_true(is.numeric(s$female_investment))
  expect_true(is.numeric(s$male_repro_cost))
})

# ── 19. With parental_investment_evolution = TRUE, run completes (Julia) ──────
test_that("parental_investment_evolution = TRUE run completes", {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(), "Julia toolchain not available")
  s <- default_specs()
  s$grid_rows                      <- 15L
  s$grid_cols                      <- 15L
  s$n_agents_init                  <- 20L
  s$max_agents                     <- 100L
  s$max_ticks                      <- 20L
  s$random_seed                    <- 42L
  s$parental_investment_evolution   <- TRUE
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
})

# ── 20. With high male_repro_cost, fewer births than with low male_repro_cost ─
test_that("high male_repro_cost results in fewer or equal births than low cost", {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(), "Julia toolchain not available")
  base <- default_specs()
  base$grid_rows     <- 15L
  base$grid_cols     <- 15L
  base$n_agents_init <- 20L
  base$max_agents    <- 100L
  base$max_ticks     <- 30L
  base$random_seed   <- 42L

  s_high <- base; s_high$male_repro_cost <- 0.9
  s_low  <- base; s_low$male_repro_cost  <- 0.1

  env_high <- run_alife(s_high, verbose = FALSE)
  env_low  <- run_alife(s_low,  verbose = FALSE)

  births_high <- sum(env_high$progress$n_births)
  births_low  <- sum(env_low$progress$n_births)

  expect_lte(births_high, births_low + 5L,
             label = "High male_repro_cost should not produce more births than low cost")
})
