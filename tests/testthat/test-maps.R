# Tests for wall/barrier map generation parameters.
#
# wall_density and wall_clusters are NOT yet in default_specs(). Failing tests
# document what needs to be added to config.R.
# Parameters that DO exist and are tested here: seasonal_amplitude (related
# environmental structure), niche_construction (structural habitat features).

library(testthat)

# ── 1. wall_density is present in default_specs() ────────────────────────────
# NOTE: not yet implemented — test documents what is needed.
test_that("wall_density is present in default_specs()", {
  expect_true("wall_density" %in% names(default_specs()))
})

# ── 2. wall_density defaults to 0.0 ──────────────────────────────────────────
test_that("wall_density defaults to 0.0", {
  expect_equal(default_specs()$wall_density, 0.0)
})

# ── 3. wall_density is in [0, 1] ─────────────────────────────────────────────
test_that("wall_density default is in [0, 1]", {
  val <- default_specs()$wall_density
  expect_gte(val, 0.0)
  expect_lte(val, 1.0)
})

# ── 4. wall_clusters is present in default_specs() ───────────────────────────
test_that("wall_clusters is present in default_specs()", {
  expect_true("wall_clusters" %in% names(default_specs()))
})

# ── 5. wall_clusters defaults to TRUE ────────────────────────────────────────
test_that("wall_clusters defaults to TRUE", {
  expect_true(default_specs()$wall_clusters)
})

# ── 6. wall_clusters is logical ──────────────────────────────────────────────
test_that("wall_clusters is a logical scalar", {
  val <- default_specs()$wall_clusters
  expect_true(is.logical(val) && length(val) == 1L)
})

# ── 7. niche_construction (related structural feature) defaults to FALSE ──────
test_that("niche_construction is present and defaults to FALSE", {
  s <- default_specs()
  expect_true("niche_construction" %in% names(s))
  expect_false(s$niche_construction)
})

# ── 8. seasonal_amplitude defaults to 0.0 ────────────────────────────────────
test_that("seasonal_amplitude is present and defaults to 0.0", {
  s <- default_specs()
  expect_true("seasonal_amplitude" %in% names(s))
  expect_equal(s$seasonal_amplitude, 0.0)
})

# ── 9. wall_density = 0.0 by default ─────────────────────────────────────────
test_that("wall_density defaults to 0.0 (no walls by default)", {
  expect_equal(default_specs()$wall_density, 0.0)
})

# ── 10. wall_density cannot be negative: default is non-negative ──────────────
test_that("wall_density default value is non-negative", {
  expect_gte(default_specs()$wall_density, 0.0)
})

# ── 11. wall_clusters is logical ──────────────────────────────────────────────
test_that("wall_clusters is a logical scalar", {
  val <- default_specs()$wall_clusters
  expect_true(is.logical(val))
  expect_length(val, 1L)
})

# ── 12. grid_rows and grid_cols defaults ──────────────────────────────────────
test_that("grid_rows defaults to 30L", {
  expect_equal(default_specs()$grid_rows, 30L)
})

test_that("grid_cols defaults to 30L", {
  expect_equal(default_specs()$grid_cols, 30L)
})

# ── 13. wall parameters round-trip through default_specs() ───────────────────
test_that("wall_density and wall_clusters round-trip through modified specs", {
  s <- default_specs()
  s$wall_density  <- 0.2
  s$wall_clusters <- FALSE
  expect_equal(s$wall_density, 0.2)
  expect_false(s$wall_clusters)
})
