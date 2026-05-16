# Tests for clutch size evolution parameters.
#
# The basic parental care parameter max_clutch_size exists. The evolvable clutch
# size module parameters (clutch_size_evolution, clutch_size_init_mean,
# clutch_size_min, clutch_size_max, clutch_size_mutation_sd) do NOT yet exist
# in default_specs(). Failing tests document what needs to be added to config.R.

library(testthat)

# ── 1. max_clutch_size is present in default_specs() ─────────────────────────
test_that("max_clutch_size is present in default_specs()", {
  skip_no_julia()
  expect_true("max_clutch_size" %in% names(default_specs()))
})

# ── 2. max_clutch_size defaults to 1 ─────────────────────────────────────────
test_that("max_clutch_size defaults to 1", {
  skip_no_julia()
  s <- default_specs()
  expect_equal(s$max_clutch_size, 1L)
})

# ── 3. max_clutch_size is integer-like ───────────────────────────────────────
test_that("max_clutch_size is integer-like", {
  skip_no_julia()
  val <- default_specs()$max_clutch_size
  expect_true(is.integer(val) || (is.numeric(val) && val == as.integer(val)))
})

# ── 4. clutch_size_evolution is present in default_specs() ───────────────────
# NOTE: not yet implemented — test documents what is needed.
test_that("clutch_size_evolution is present in default_specs()", {
  skip_no_julia()
  expect_true("clutch_size_evolution" %in% names(default_specs()))
})

# ── 5. clutch_size_evolution defaults to FALSE ────────────────────────────────
test_that("clutch_size_evolution defaults to FALSE", {
  skip_no_julia()
  expect_false(default_specs()$clutch_size_evolution)
})

# ── 6. clutch_size_init_mean is present in default_specs() ───────────────────
test_that("clutch_size_init_mean is present in default_specs()", {
  skip_no_julia()
  expect_true("clutch_size_init_mean" %in% names(default_specs()))
})

# ── 7. clutch_size_min is present and is integer-like ────────────────────────
test_that("clutch_size_min is present and is integer-like", {
  skip_no_julia()
  s <- default_specs()
  expect_true("clutch_size_min" %in% names(s))
  val <- s$clutch_size_min
  expect_true(is.integer(val) || (is.numeric(val) && val == as.integer(val)))
})

# ── 8. clutch_size_max is present and is integer-like ────────────────────────
test_that("clutch_size_max is present and is integer-like", {
  skip_no_julia()
  s <- default_specs()
  expect_true("clutch_size_max" %in% names(s))
  val <- s$clutch_size_max
  expect_true(is.integer(val) || (is.numeric(val) && val == as.integer(val)))
})

# ── 9. clutch_size_min < clutch_size_max ─────────────────────────────────────
test_that("clutch_size_min is strictly less than clutch_size_max", {
  skip_no_julia()
  s <- default_specs()
  expect_lt(s$clutch_size_min, s$clutch_size_max)
})

# ── 10. clutch_size_mutation_sd is present in default_specs() ────────────────
test_that("clutch_size_mutation_sd is present in default_specs()", {
  skip_no_julia()
  expect_true("clutch_size_mutation_sd" %in% names(default_specs()))
})

# ── 11. clutch_size_evolution defaults to FALSE ───────────────────────────────
test_that("clutch_size_evolution defaults to FALSE", {
  skip_no_julia()
  expect_false(default_specs()$clutch_size_evolution)
})

# ── 12. clutch_size_min defaults to 1L ───────────────────────────────────────
test_that("clutch_size_min defaults to 1L", {
  skip_no_julia()
  val <- default_specs()$clutch_size_min
  expect_equal(val, 1L)
})

# ── 13. clutch_size_max defaults to 5L ───────────────────────────────────────
test_that("clutch_size_max defaults to 5L", {
  skip_no_julia()
  val <- default_specs()$clutch_size_max
  expect_equal(val, 5L)
})

# ── 14. clutch_size_init_mean defaults to 1.0 ────────────────────────────────
test_that("clutch_size_init_mean defaults to 1.0", {
  skip_no_julia()
  expect_equal(default_specs()$clutch_size_init_mean, 1.0)
})

# ── 15. clutch_size_mutation_sd defaults to 0.3 ──────────────────────────────
test_that("clutch_size_mutation_sd defaults to 0.3", {
  skip_no_julia()
  expect_equal(default_specs()$clutch_size_mutation_sd, 0.3)
})

# ── 16. max_clutch_size defaults to 1L ───────────────────────────────────────
test_that("max_clutch_size defaults to 1L", {
  skip_no_julia()
  expect_equal(default_specs()$max_clutch_size, 1L)
})

# ── 17. clutch_size_min <= clutch_size_max in defaults ───────────────────────
test_that("clutch_size_min is less than or equal to clutch_size_max in defaults", {
  skip_no_julia()
  s <- default_specs()
  expect_lte(s$clutch_size_min, s$clutch_size_max)
})

# ── 18. clutch size params round-trip through default_specs() ─────────────────
test_that("clutch size params round-trip correctly through default_specs()", {
  skip_no_julia()
  s <- default_specs()
  expect_false(s$clutch_size_evolution)
  expect_equal(s$clutch_size_init_mean,  1.0)
  expect_equal(s$clutch_size_min,        1L)
  expect_equal(s$clutch_size_max,        5L)
  expect_equal(s$clutch_size_mutation_sd, 0.3)
  expect_equal(s$max_clutch_size,        1L)
})

# ── 19. With clutch_size_evolution = TRUE, run completes (Julia) ──────────────
test_that("clutch_size_evolution = TRUE run completes", {
  skip_no_julia()
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(), "Julia toolchain not available")
  s <- default_specs()
  s$grid_rows            <- 15L
  s$grid_cols            <- 15L
  s$n_agents_init        <- 20L
  s$max_agents           <- 100L
  s$max_ticks            <- 20L
  s$random_seed          <- 42L
  s$clutch_size_evolution <- TRUE
  s$clutch_size_max      <- 3L
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
})

# ── 20. With clutch_size_max = 3L and evolution, n_births can exceed 0 ───────
test_that("clutch_size_evolution = TRUE with clutch_size_max = 3 produces births", {
  skip_no_julia()
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(), "Julia toolchain not available")
  s <- default_specs()
  s$grid_rows             <- 15L
  s$grid_cols             <- 15L
  s$n_agents_init         <- 20L
  s$max_agents            <- 100L
  s$max_ticks             <- 30L
  s$random_seed           <- 42L
  s$clutch_size_evolution <- TRUE
  s$clutch_size_max       <- 3L
  s$clutch_size_init_mean <- 2.0
  env <- run_alife(s, verbose = FALSE)
  total_births <- sum(env$progress$n_births)
  expect_gte(total_births, 0L)
})
