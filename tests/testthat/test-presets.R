# Dedicated tests for the preset family:
#   quick_specs(), full_specs(), fast_specs(),
#   realistic_specs(), ultra_realistic_specs(), slow_specs()
#
# Before Phase A item 8, the preset family had no dedicated test coverage —
# `quick_specs()` was used in `test-hypothesis.R` and `test-integration.R`
# implicitly, but the documented-vs-code parameter values were never
# asserted. This file covers:
#
# - shape: each preset returns a list with the same fields as default_specs(),
# - documented values: each preset's roxygen-table claims match the code,
# - validation: each preset passes `.validate_specs()` cleanly,
# - chain inheritance: the realistic → fast → default chain preserves
#   upstream settings unless explicitly overridden,
# - immutability: calling a preset does not mutate `default_specs()`.

library(testthat)

# ── Shape: each preset returns a full-shaped specs list ──────────────────────

.presets <- list(
  quick           = quick_specs,
  full            = full_specs,
  fast            = fast_specs,
  realistic       = realistic_specs,
  ultra_realistic = ultra_realistic_specs,
  slow            = slow_specs
)

test_that("every preset returns a list with the same field names as default_specs()", {
  defs <- default_specs()
  for (nm in names(.presets)) {
    s <- .presets[[nm]]()
    expect_type(s, "list")
    extra   <- setdiff(names(s), names(defs))
    missing <- setdiff(names(defs), names(s))
    expect_equal(extra,   character(0L),
                 info = sprintf("%s_specs() added fields: %s", nm,
                                paste(extra, collapse = ", ")))
    expect_equal(missing, character(0L),
                 info = sprintf("%s_specs() dropped fields: %s", nm,
                                paste(missing, collapse = ", ")))
  }
})

test_that("every preset passes .validate_specs() cleanly", {
  for (nm in names(.presets)) {
    s <- .presets[[nm]]()
    expect_silent(clade:::.validate_specs(s))
  }
})

# ── Documented values: each preset's roxygen table matches the code ──────────

test_that("quick_specs() documented values match code", {
  s <- quick_specs()
  expect_equal(s$n_agents_init, 50L)
  expect_equal(s$max_ticks,     200L)
  expect_equal(s$grid_rows,     20L)
  expect_equal(s$grid_cols,     20L)
})

test_that("full_specs() documented values match code", {
  s <- full_specs()
  expect_equal(s$n_agents_init, 200L)
  expect_equal(s$max_ticks,     1000L)
  expect_equal(s$grid_rows,     30L)
  expect_equal(s$grid_cols,     30L)
})

test_that("fast_specs() documented values match code (including predator_max_age)", {
  s <- fast_specs()
  expect_equal(s$max_age,          30L)
  expect_equal(s$min_repro_energy, 60.0)
  expect_equal(s$min_repro_age,    3L)
  expect_equal(s$grass_rate,       0.20)
  expect_equal(s$n_agents_init,    80L)
  expect_equal(s$max_agents,       400L)
  expect_equal(s$grid_rows,        30L)
  expect_equal(s$grid_cols,        30L)
  expect_equal(s$max_ticks,        2000L)
  expect_equal(s$predator_max_age, 100L)   # documented in roxygen since item 8
})

test_that("realistic_specs() documented values match code", {
  s <- realistic_specs()
  expect_equal(s$grid_rows,           60L)
  expect_equal(s$grid_cols,           60L)
  expect_equal(s$n_agents_init,       150L)
  expect_equal(s$max_agents,          1500L)
  expect_equal(s$max_ticks,           2000L)
  expect_equal(s$predator_max_agents, 150L)
  expect_equal(s$predator_max_age,    60L)
})

test_that("ultra_realistic_specs() documented values match code", {
  s <- ultra_realistic_specs()
  expect_equal(s$grid_rows,           120L)
  expect_equal(s$grid_cols,           120L)
  # The pre-item-8 roxygen claimed 800L; the code has always been 500L. Audit
  # fixed the roxygen to match the code (the "right-sized to ~400 equilibrium"
  # inline comment was the truth).
  expect_equal(s$n_agents_init,       500L)
  expect_equal(s$max_agents,          5000L)
  expect_equal(s$max_ticks,           2500L)
  expect_equal(s$predator_max_agents, 400L)
})

test_that("slow_specs() documented values match code (including grass_rate, n_agents_init, max_agents)", {
  s <- slow_specs()
  expect_equal(s$max_age,          200L)
  expect_equal(s$min_repro_energy, 150.0)
  expect_equal(s$min_repro_age,    20L)
  expect_equal(s$max_ticks,        10000L)
  expect_equal(s$grass_rate,       0.10)   # documented in roxygen since item 8
  expect_equal(s$n_agents_init,    100L)   # documented in roxygen since item 8
  expect_equal(s$max_agents,       500L)   # documented in roxygen since item 8
})

# ── Chain inheritance: realistic ← fast, ultra_realistic ← realistic ─────────

test_that("realistic_specs() inherits fast_specs()'s pace-of-life calibration", {
  r <- realistic_specs()
  # These come from fast_specs() and must NOT be reset by realistic_specs()
  expect_equal(r$max_age,          30L)
  expect_equal(r$min_repro_energy, 60.0)
  expect_equal(r$min_repro_age,    3L)
  expect_equal(r$grass_rate,       0.20)
})

test_that("ultra_realistic_specs() inherits fast/realistic upstream settings", {
  u <- ultra_realistic_specs()
  # Fast-pace inheritance (via realistic via fast)
  expect_equal(u$max_age,          30L)
  expect_equal(u$min_repro_energy, 60.0)
  expect_equal(u$min_repro_age,    3L)
  expect_equal(u$grass_rate,       0.20)
  # Realistic predator-age inheritance (60L, NOT fast's original 100L)
  expect_equal(u$predator_max_age, 60L)
  # And ultra_realistic's own override
  expect_equal(u$grid_rows,        120L)
})

# ── Immutability: a preset call does not mutate default_specs() ──────────────

test_that("calling a preset does not mutate default_specs()", {
  baseline <- default_specs()
  invisible(quick_specs())
  invisible(full_specs())
  invisible(fast_specs())
  invisible(realistic_specs())
  invisible(ultra_realistic_specs())
  invisible(slow_specs())
  expect_identical(default_specs(), baseline)
})
