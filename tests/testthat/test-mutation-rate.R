# Tests for mutation rate evolution parameters.
#
# Covers the evolvable mutation rate module:
#   mutation_rate_evolution, mutation_sd_min, mutation_sd_max
# and stress-induced hypermutation parameters that are NOT yet in default_specs():
#   stress_hypermutation, stress_mutation_multiplier, stress_threshold
# Tests that fail indicate parameters that need to be added to config.R.

library(testthat)

# ── 1. mutation_rate_evolution is present in default_specs() ──────────────────
test_that("mutation_rate_evolution is present in default_specs()", {
  skip_no_julia()
  expect_true("mutation_rate_evolution" %in% names(default_specs()))
})

# ── 2. mutation_rate_evolution defaults to FALSE ──────────────────────────────
test_that("mutation_rate_evolution defaults to FALSE", {
  skip_no_julia()
  expect_false(default_specs()$mutation_rate_evolution)
})

# ── 3. mutation_rate_evolution is logical ─────────────────────────────────────
test_that("mutation_rate_evolution is a logical scalar", {
  skip_no_julia()
  val <- default_specs()$mutation_rate_evolution
  expect_true(is.logical(val) && length(val) == 1L)
})

# ── 4. mutation_sd_min is present in default_specs() ─────────────────────────
test_that("mutation_sd_min is present in default_specs()", {
  skip_no_julia()
  expect_true("mutation_sd_min" %in% names(default_specs()))
})

# ── 5. mutation_sd_min default is 0.001 ──────────────────────────────────────
test_that("mutation_sd_min defaults to 0.001", {
  skip_no_julia()
  expect_equal(default_specs()$mutation_sd_min, 0.001)
})

# ── 6. mutation_sd_max is present in default_specs() ─────────────────────────
test_that("mutation_sd_max is present in default_specs()", {
  skip_no_julia()
  expect_true("mutation_sd_max" %in% names(default_specs()))
})

# ── 7. mutation_sd_max defaults to 1.0 ───────────────────────────────────────
test_that("mutation_sd_max defaults to 1.0", {
  skip_no_julia()
  expect_equal(default_specs()$mutation_sd_max, 1.0)
})

# ── 8. mutation_sd_min < mutation_sd_max ─────────────────────────────────────
test_that("mutation_sd_min is strictly less than mutation_sd_max", {
  skip_no_julia()
  s <- default_specs()
  expect_lt(s$mutation_sd_min, s$mutation_sd_max)
})

# ── 9. stress_hypermutation is present in default_specs() ────────────────────
# NOTE: this parameter is not yet implemented — test documents what is needed.
test_that("stress_hypermutation is present in default_specs()", {
  skip_no_julia()
  expect_true("stress_hypermutation" %in% names(default_specs()))
})

# ── 10. stress_mutation_multiplier is present in default_specs() ──────────────
test_that("stress_mutation_multiplier is present in default_specs()", {
  skip_no_julia()
  expect_true("stress_mutation_multiplier" %in% names(default_specs()))
})

# ── 11. stress_threshold is present in default_specs() ───────────────────────
test_that("stress_threshold is present in default_specs()", {
  skip_no_julia()
  expect_true("stress_threshold" %in% names(default_specs()))
})

# ── 12. mutation_sd_min is non-negative ───────────────────────────────────────
test_that("mutation_sd_min is non-negative", {
  skip_no_julia()
  expect_gte(default_specs()$mutation_sd_min, 0.0)
})

# ── 13. mutation_rate_evolution defaults to FALSE ─────────────────────────────
test_that("mutation_rate_evolution defaults to FALSE", {
  skip_no_julia()
  expect_false(default_specs()$mutation_rate_evolution)
})

# ── 14. mutation_sd_init_mean defaults to 0.1 ─────────────────────────────────
test_that("mutation_sd_init_mean defaults to 0.1", {
  skip_no_julia()
  expect_equal(default_specs()$mutation_sd_init_mean, 0.1)
})

# ── 15. mutation_sd_min defaults to 0.001 ─────────────────────────────────────
test_that("mutation_sd_min defaults to 0.001", {
  skip_no_julia()
  expect_equal(default_specs()$mutation_sd_min, 0.001)
})

# ── 16. mutation_sd_max defaults to 1.0 ───────────────────────────────────────
test_that("mutation_sd_max defaults to 1.0", {
  skip_no_julia()
  expect_equal(default_specs()$mutation_sd_max, 1.0)
})

# ── 17. stress_hypermutation defaults to FALSE ────────────────────────────────
test_that("stress_hypermutation defaults to FALSE", {
  skip_no_julia()
  expect_false(default_specs()$stress_hypermutation)
})

# ── 18. stress_mutation_multiplier defaults to 3.0 ───────────────────────────
test_that("stress_mutation_multiplier defaults to 3.0", {
  skip_no_julia()
  expect_equal(default_specs()$stress_mutation_multiplier, 3.0)
})

# ── 19. stress_threshold defaults to 20.0 ────────────────────────────────────
test_that("stress_threshold defaults to 20.0", {
  skip_no_julia()
  expect_equal(default_specs()$stress_threshold, 20.0)
})

# ── 20. mutation_sd params round-trip through default_specs() ─────────────────
test_that("mutation_sd params round-trip correctly through default_specs()", {
  skip_no_julia()
  s <- default_specs()
  expect_false(s$mutation_rate_evolution)
  expect_equal(s$mutation_sd_init_mean,      0.1)
  expect_equal(s$mutation_sd_min,            0.001)
  expect_equal(s$mutation_sd_max,            1.0)
  expect_false(s$stress_hypermutation)
  expect_equal(s$stress_mutation_multiplier, 3.0)
  expect_equal(s$stress_threshold,           20.0)
})

# ── 21. mutation_sd_min < mutation_sd_max in defaults ─────────────────────────
test_that("mutation_sd_min is strictly less than mutation_sd_max in defaults", {
  skip_no_julia()
  s <- default_specs()
  expect_lt(s$mutation_sd_min, s$mutation_sd_max)
})

# ── 22. With stress_hypermutation = TRUE, run completes (Julia) ───────────────
test_that("stress_hypermutation = TRUE run completes", {
  skip_no_julia()
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(), "Julia toolchain not available")
  s <- default_specs()
  s$grid_rows               <- 15L
  s$grid_cols               <- 15L
  s$n_agents_init           <- 20L
  s$max_agents              <- 100L
  s$max_ticks               <- 20L
  s$random_seed             <- 42L
  s$stress_hypermutation    <- TRUE
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
})
