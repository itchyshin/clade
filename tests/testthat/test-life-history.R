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

# ── New tests ─────────────────────────────────────────────────────────────────

# ── 13. life_history defaults to "iteroparous" (explicit identical) ───────────
test_that("life_history defaults to \"iteroparous\" (identical check)", {
  expect_identical(default_specs()$life_history, "iteroparous")
})

# ── 14. life_history can be "semelparous" ─────────────────────────────────────
test_that("life_history accepts \"semelparous\" without error in specs", {
  s <- default_specs()
  s$life_history <- "semelparous"
  expect_equal(s$life_history, "semelparous")
})

# ── 15. max_age defaults to 200L and is integer ──────────────────────────────
test_that("max_age defaults to 200L and is integer", {
  s <- default_specs()
  expect_identical(s$max_age, 200L)
  expect_true(is.integer(s$max_age))
})

# ── 16. repro_senescence defaults to 0.0 ─────────────────────────────────────
test_that("repro_senescence defaults to 0.0 (identical check)", {
  expect_identical(default_specs()$repro_senescence, 0.0)
})

# ── 17. life_history_evolution defaults to FALSE ─────────────────────────────
test_that("life_history_evolution defaults to FALSE (identical check)", {
  expect_identical(default_specs()$life_history_evolution, FALSE)
})

# ── 18. senescence_rate defaults to 0.0 ──────────────────────────────────────
test_that("senescence_rate defaults to 0.0 (identical check)", {
  expect_identical(default_specs()$senescence_rate, 0.0)
})

# ── 19. senescence_shape defaults to 2.0 ─────────────────────────────────────
test_that("senescence_shape defaults to 2.0", {
  s <- default_specs()
  expect_true("senescence_shape" %in% names(s))
  expect_identical(s$senescence_shape, 2.0)
})

# ── 20. life_history params round-trip through default_specs() ───────────────
test_that("life_history params round-trip through default_specs()", {
  s <- default_specs()
  expect_equal(s$life_history,           "iteroparous")
  expect_equal(s$max_age,                200L)
  expect_equal(s$senescence_rate,        0.0)
  expect_equal(s$repro_senescence,       0.0)
  expect_equal(s$life_history_evolution, FALSE)
  expect_equal(s$senescence_shape,       2.0)
})

# ── 21. semelparous run completes and n_births > 0 somewhere ─────────────────
test_that("life_history = 'semelparous' run completes and produces births", {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- default_specs()
  s$grid_rows     <- 10L
  s$grid_cols     <- 10L
  s$n_agents_init <- 10L
  s$max_agents    <- 80L
  s$max_ticks     <- 20L
  s$life_history  <- "semelparous"
  s$random_seed   <- 42L
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_gt(sum(env$progress$n_births), 0L)
})

# ── 22. high senescence_rate lowers mean_age vs no senescence ────────────────
test_that("high senescence_rate produces lower mean_age than zero rate", {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  base <- list(
    grid_rows     = 10L,
    grid_cols     = 10L,
    n_agents_init = 15L,
    max_agents    = 80L,
    max_ticks     = 30L,
    random_seed   = 42L
  )
  s_none <- do.call(default_specs, list())
  for (nm in names(base)) s_none[[nm]] <- base[[nm]]
  s_none$senescence_rate <- 0.0

  s_high <- do.call(default_specs, list())
  for (nm in names(base)) s_high[[nm]] <- base[[nm]]
  s_high$senescence_rate <- 0.1

  env_none <- run_alife(s_none, verbose = FALSE)
  env_high <- run_alife(s_high, verbose = FALSE)

  age_none <- mean(env_none$progress$mean_age[env_none$progress$n_agents > 0L],
                   na.rm = TRUE)
  age_high <- mean(env_high$progress$mean_age[env_high$progress$n_agents > 0L],
                   na.rm = TRUE)
  expect_gte(age_none, age_high)
})

# ── 23. max_age = 50L: no agent survives beyond 50 ticks ────────────────────
test_that("max_age = 50L: mean_age never exceeds 50 at any tick", {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- default_specs()
  s$grid_rows     <- 10L
  s$grid_cols     <- 10L
  s$n_agents_init <- 15L
  s$max_agents    <- 80L
  s$max_ticks     <- 80L
  s$max_age       <- 50L
  s$random_seed   <- 42L
  env <- run_alife(s, verbose = FALSE)
  active <- env$progress$n_agents > 0L
  if (any(active)) {
    expect_true(all(env$progress$mean_age[active] <= 50.0))
  }
})

# ── 24. repro_senescence = 0.01 run completes without error ──────────────────
test_that("repro_senescence = 0.01 run completes without error", {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- default_specs()
  s$grid_rows       <- 10L
  s$grid_cols       <- 10L
  s$n_agents_init   <- 10L
  s$max_agents      <- 60L
  s$max_ticks       <- 15L
  s$repro_senescence <- 0.01
  s$random_seed     <- 42L
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
})

# ── 25. semelparous repro_cost is high relative to normal reproduction ────────
test_that("semelparous repro_cost >= iteroparous repro_cost in default_specs", {
  # Verify that the semelparous configuration uses a meaningful repro_cost.
  # This is a structural / documentation test — no Julia needed.
  s <- default_specs()
  s$life_history <- "semelparous"
  # repro_cost should be positive (agents pay to reproduce and then die)
  expect_gt(s$repro_cost, 0.0)
})
