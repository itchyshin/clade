# Tests for config parameter structure and validation — no Julia required.
#
# These tests focus on the properties of default_specs() as a configuration
# object: its type, size, required fields, numeric constraints, and absence of
# unintentional NA values.

library(testthat)

# ── 1. default_specs() returns a list ────────────────────────────────────────
test_that("default_specs() returns a list", {
  expect_type(default_specs(), "list")
})

# ── 2. default_specs() has many parameters ───────────────────────────────────
test_that("default_specs() contains more than 50 parameters", {
  expect_gt(length(default_specs()), 50L)
})

# ── 3. Required core parameters are present ───────────────────────────────────
test_that("required core parameters are present in default_specs()", {
  required <- c(
    "n_agents_init", "max_ticks", "grid_rows", "grid_cols", "grass_rate"
  )
  missing <- setdiff(required, names(default_specs()))
  expect_equal(missing, character(0L),
               info = paste("Missing:", paste(missing, collapse = ", ")))
})

# ── 4. energy_init is positive ───────────────────────────────────────────────
test_that("energy_init is positive", {
  expect_gt(default_specs()$energy_init, 0)
})

# ── 5. n_agents_init is positive ─────────────────────────────────────────────
test_that("n_agents_init is positive", {
  expect_gt(default_specs()$n_agents_init, 0L)
})

# ── 6. max_ticks is positive ──────────────────────────────────────────────────
test_that("max_ticks is positive", {
  expect_gt(default_specs()$max_ticks, 0L)
})

# ── 7. grid dimensions are positive ──────────────────────────────────────────
test_that("grid_rows and grid_cols are both positive", {
  s <- default_specs()
  expect_gt(s$grid_rows, 0L)
  expect_gt(s$grid_cols, 0L)
})

# ── 8. grass_rate is in (0, 1) ────────────────────────────────────────────────
test_that("grass_rate is in (0, 1)", {
  gr <- default_specs()$grass_rate
  expect_gt(gr, 0)
  expect_lt(gr, 1)
})

# ── 9. move_cost is non-negative ─────────────────────────────────────────────
test_that("move_cost >= 0", {
  expect_gte(default_specs()$move_cost, 0)
})

# ── 10. idle_cost is non-negative ────────────────────────────────────────────
test_that("idle_cost >= 0", {
  expect_gte(default_specs()$idle_cost, 0)
})

# ── 11. min_repro_energy > 0 (positive reproduction barrier) ─────────────────
test_that("min_repro_energy is strictly positive", {
  expect_gt(default_specs()$min_repro_energy, 0)
})

# ── 12. No unintentional NA values in defaults ───────────────────────────────
test_that("no unintentional NA values in default_specs()", {
  # random_seed = NA_integer_ is intentional — excluded.
  # world_params_to_evolve = character(0) is length 0, not NA — harmless,
  # but we exclude it too so the vapply stays length-1 safe.
  s        <- default_specs()
  s_check  <- s[!names(s) %in% c("random_seed", "world_params_to_evolve")]
  na_flags <- vapply(
    s_check,
    function(x) length(x) == 1L && is.na(x),
    logical(1L)
  )
  expect_false(any(na_flags),
               info = paste("Parameters with NA values:",
                            paste(names(s_check)[na_flags], collapse = ", ")))
})
