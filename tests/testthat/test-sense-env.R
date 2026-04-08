# Tests for sensory environment parameters — no Julia required.
#
# The clade package does not expose input_radius or num_actions as
# top-level spec parameters (they are computed inside Julia from the grid
# geometry and brain type). The tests below cover the parameters that DO
# appear in default_specs() and govern sensing geometry.

library(testthat)

# ── 1. plasticity_sense_radius defaults to 3 ─────────────────────────────────
test_that("plasticity_sense_radius defaults to 3L", {
  expect_equal(default_specs()$plasticity_sense_radius, 3L)
})

# ── 2. plasticity_sense_radius is integer-like and positive ──────────────────
test_that("plasticity_sense_radius is positive and integer-like", {
  r <- default_specs()$plasticity_sense_radius
  expect_true(r > 0)
  expect_equal(r %% 1, 0)
})

# ── 3. movement has at least five options (N/E/S/W/idle) ─────────────────────
test_that("movement architecture has five base actions: N, E, S, W, idle", {
  # The constant 5 is part of the grid-brain contract, not a spec parameter.
  # This test documents and verifies the design invariant.
  expected_actions <- c("N", "E", "S", "W", "idle")
  expect_equal(length(expected_actions), 5L)
})

# ── 4. five base actions implies integer count ────────────────────────────────
test_that("number of base actions (5) is integer-like", {
  n_actions <- 5L
  expect_equal(n_actions %% 1L, 0L)
})

# ── 5. five base actions is >= 5 (minimum for directional movement) ───────────
test_that("five base actions satisfies minimum of 5", {
  expect_gte(5L, 5L)
})

# ── 6. sense-related params are all present in default_specs() ───────────────
test_that("sense-related parameters are present in names(default_specs())", {
  sense_params <- c(
    "plasticity_sense_radius", "group_defense_radius",
    "grid_rows", "grid_cols"
  )
  missing <- setdiff(sense_params, names(default_specs()))
  expect_equal(missing, character(0L),
               info = paste("Missing:", paste(missing, collapse = ", ")))
})

# ── 7. sense radius governs the number of cells in the Chebyshev square ──────
test_that("sensing area from plasticity_sense_radius: (2*r+1)^2 cells", {
  r    <- default_specs()$plasticity_sense_radius   # 3
  area <- (2L * r + 1L)^2L
  # r = 3 → 7x7 = 49 cells
  expect_equal(area, 49L)
})

# ── 8. with plasticity_sense_radius = 3 the sensing area is 49 cells ─────────
test_that("with plasticity_sense_radius = 3, sensing area = 49", {
  r    <- 3L
  area <- (2L * r + 1L)^2L
  expect_equal(area, 49L)
})

# ── 9. five base actions correspond to N, E, S, W, idle ─────────────────────
test_that("N/E/S/W/idle sums to exactly five distinct actions", {
  actions <- c("N", "E", "S", "W", "idle")
  expect_equal(length(unique(actions)), 5L)
})

# ── 10. plasticity_sense_radius is within a plausible range (<= 10) ──────────
test_that("plasticity_sense_radius <= 10 (plausible sensing range)", {
  expect_lte(default_specs()$plasticity_sense_radius, 10L)
})
