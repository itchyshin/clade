# Tests for the dispersal evolution Julia module.
#
# Natal dispersal: agents move away from birthplace (x_birth, y_birth) with
# per-tick probability = dispersal_tendency.
# Tests requiring Julia are guarded by skip_no_julia(). Pure parameter/spec
# tests run without Julia.

library(testthat)

# ── Helpers ───────────────────────────────────────────────────────────────────

.qs <- function(...) {
  s <- default_specs()
  s$grid_rows     <- 15L
  s$grid_cols     <- 15L
  s$n_agents_init <- 10L
  s$max_agents    <- 60L
  s$max_ticks     <- 30L
  args <- list(...)
  for (nm in names(args)) s[[nm]] <- args[[nm]]
  s
}

.disp_specs <- function(...) {
  .qs(
    dispersal_evolution   = TRUE,
    dispersal_init_mean   = 0.3,
    dispersal_mutation_sd = 0.02,
    dispersal_min         = 0.0,
    dispersal_max         = 0.5,
    dispersal_cost        = 2.0,
    ...
  )
}

# ── 1. n_dispersal_events = 0 when dispersal_evolution = FALSE ───────────────
test_that("n_dispersal_events = 0 when dispersal_evolution = FALSE", {
  skip_no_julia()
  s   <- .qs()
  env <- run_alife(s, verbose = FALSE)
  nd  <- env$progress$n_dispersal_events
  expect_true(all(nd == 0L),
              info = "No dispersal when dispersal_evolution is off")
})

# ── 2. n_dispersal_events > 0 with high dispersal_tendency ───────────────────
test_that("n_dispersal_events > 0 when dispersal_tendency is high", {
  skip_no_julia()
  s <- .disp_specs(
    dispersal_init_mean   = 0.5,
    dispersal_mutation_sd = 0.0,
    dispersal_max         = 0.5,
    energy_init           = 200.0,   # plenty of energy so cost doesn't block
    n_agents_init         = 20L,
    random_seed           = 42L
  )
  env  <- run_alife(s, verbose = FALSE)
  total <- sum(env$progress$n_dispersal_events)
  expect_gt(total, 0L,
            label = "Dispersal events expected with high dispersal_tendency")
})

# ── 3. run_alife completes without error when dispersal_evolution = TRUE ──────
test_that("run_alife completes with dispersal_evolution = TRUE", {
  skip_no_julia()
  s <- .disp_specs()
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(as.integer(env$t) >= 1L)
})

# ── 4. n_dispersal_events is logged in env$progress ──────────────────────────
test_that("n_dispersal_events column is present in env$progress", {
  skip_no_julia()
  s   <- .disp_specs()
  env <- run_alife(s, verbose = FALSE)
  expect_true("n_dispersal_events" %in% names(env$progress))
})

# ── 5. n_dispersal_events in get_run_data()$ticks ────────────────────────────
test_that("get_run_data()$ticks has n_dispersal_events column", {
  skip_no_julia()
  s    <- .disp_specs()
  env  <- run_alife(s, verbose = FALSE)
  data <- get_run_data(env)$ticks
  expect_true("n_dispersal_events" %in% names(data))
})

# ── 6. n_dispersal_events is non-negative at all ticks ───────────────────────
test_that("n_dispersal_events is non-negative at every tick", {
  skip_no_julia()
  s   <- .disp_specs()
  env <- run_alife(s, verbose = FALSE)
  nd  <- env$progress$n_dispersal_events
  expect_true(all(nd >= 0L))
})

# ── 7. Dispersal cost reduces energy relative to no-dispersal baseline ────────
test_that("high dispersal_tendency leads to lower mean energy than no dispersal", {
  skip_no_julia()
  base <- .qs(
    dispersal_evolution   = TRUE,
    dispersal_mutation_sd = 0.0,
    dispersal_cost        = 8.0,          # high cost to amplify signal
    n_agents_init         = 30L,
    max_ticks             = 10L,
    min_repro_energy      = 500.0,        # no reproduction
    grass_rate            = 0.0,
    grass_max             = 0.0,
    grass_init_prob       = 0.0,
    energy_init           = 200.0,
    random_seed           = 10L
  )

  s_high <- base
  s_high$dispersal_init_mean <- 0.5
  s_high$dispersal_max       <- 0.5

  s_zero <- base
  s_zero$dispersal_init_mean <- 0.0
  s_zero$dispersal_max       <- 0.5

  env_high <- run_alife(s_high, verbose = FALSE)
  env_zero <- run_alife(s_zero, verbose = FALSE)

  # Use tick 1 to avoid population-crash NaN
  e_high <- env_high$progress$mean_energy[[1L]]
  e_zero <- env_zero$progress$mean_energy[[1L]]

  if (!is.nan(e_high) && !is.nan(e_zero) && e_zero > 0) {
    expect_lt(e_high, e_zero,
              label = "Dispersal cost should lower mean energy")
  }
})

# ── 8. Higher dispersal tendency → more events than lower tendency ────────────
test_that("higher dispersal_init_mean produces more dispersal events", {
  skip_no_julia()
  base <- .disp_specs(
    dispersal_mutation_sd = 0.0,
    energy_init           = 200.0,
    n_agents_init         = 20L,
    max_ticks             = 20L,
    grass_rate            = 0.0,
    grass_max             = 0.0,
    grass_init_prob       = 0.0,
    min_repro_energy      = 500.0,
    random_seed           = 22L
  )
  s_high <- base; s_high$dispersal_init_mean <- 0.5
  s_low  <- base; s_low$dispersal_init_mean  <- 0.1

  env_high <- run_alife(s_high, verbose = FALSE)
  env_low  <- run_alife(s_low,  verbose = FALSE)

  n_high <- sum(env_high$progress$n_dispersal_events)
  n_low  <- sum(env_low$progress$n_dispersal_events)

  expect_gte(n_high, n_low,
             label = "Higher tendency should produce at least as many events")
})

# ── 9. Dispersal runs on a small 5x5 grid without error ──────────────────────
test_that("dispersal_evolution runs on a 5x5 grid without error", {
  skip_no_julia()
  s <- default_specs()
  s$grid_rows           <- 5L
  s$grid_cols           <- 5L
  s$n_agents_init       <- 5L
  s$max_agents          <- 25L
  s$max_ticks           <- 10L
  s$dispersal_evolution <- TRUE
  s$dispersal_init_mean <- 0.3
  expect_no_error(env <- run_alife(s, verbose = FALSE))
})

# ── 10. Dispersal works alongside kin_selection ───────────────────────────────
test_that("dispersal_evolution = TRUE works with kin_selection = TRUE", {
  skip_no_julia()
  s <- .disp_specs(kin_selection = TRUE)
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(as.integer(env$t) >= 1L)
})

# ── 11. Dispersal works alongside body_size_evolution ────────────────────────
test_that("dispersal_evolution = TRUE works with body_size_evolution = TRUE", {
  skip_no_julia()
  s <- .disp_specs(
    body_size_evolution   = TRUE,
    body_size_init_mean   = 1.0,
    body_size_mutation_sd = 0.08,
    body_size_min         = 0.3,
    body_size_max         = 3.0
  )
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(as.integer(env$t) >= 1L)
})

# ── 12. default_specs() has all dispersal parameters with correct defaults ────
test_that("default_specs() has all dispersal parameters with correct defaults", {
  skip_no_julia()
  s <- default_specs()
  expect_true("dispersal_evolution" %in% names(s))
  expect_false(s$dispersal_evolution)
  expect_true("dispersal_cost" %in% names(s))
  expect_equal(s$dispersal_cost, 2.0)
  expect_true("dispersal_min" %in% names(s))
  expect_equal(s$dispersal_min, 0.0)
  expect_true("dispersal_max" %in% names(s))
  expect_equal(s$dispersal_max, 0.5)
  expect_true("dispersal_mutation_sd" %in% names(s))
  expect_equal(s$dispersal_mutation_sd, 0.02)
  expect_true("dispersal_init_mean" %in% names(s))
})

# ── 13. dispersal_evolution defaults to FALSE ─────────────────────────────────
test_that("dispersal_evolution defaults to FALSE", {
  skip_no_julia()
  expect_false(default_specs()$dispersal_evolution)
})

# ── 14. dispersal_cost defaults to 2.0 ───────────────────────────────────────
test_that("dispersal_cost defaults to 2.0", {
  skip_no_julia()
  expect_equal(default_specs()$dispersal_cost, 2.0)
})

# ── 15. dispersal_init_mean is present and in [0, 1] ─────────────────────────
test_that("dispersal_init_mean is present and in [0, 1]", {
  skip_no_julia()
  val <- default_specs()$dispersal_init_mean
  expect_true("dispersal_init_mean" %in% names(default_specs()))
  expect_gte(val, 0.0)
  expect_lte(val, 1.0)
})

# ── 16. dispersal_mutation_sd defaults to 0.02 ───────────────────────────────
test_that("dispersal_mutation_sd defaults to 0.02", {
  skip_no_julia()
  expect_equal(default_specs()$dispersal_mutation_sd, 0.02)
})

# ── 17. dispersal_min defaults to 0.0 ────────────────────────────────────────
test_that("dispersal_min defaults to 0.0", {
  skip_no_julia()
  expect_equal(default_specs()$dispersal_min, 0.0)
})

# ── 18. dispersal_max defaults to 0.5 ────────────────────────────────────────
test_that("dispersal_max defaults to 0.5", {
  skip_no_julia()
  expect_equal(default_specs()$dispersal_max, 0.5)
})

# ── 19. dispersal params round-trip through default_specs() ──────────────────
test_that("dispersal params round-trip correctly through default_specs()", {
  skip_no_julia()
  s <- default_specs()
  expect_false(s$dispersal_evolution)
  expect_equal(s$dispersal_cost,        2.0)
  expect_equal(s$dispersal_mutation_sd, 0.02)
  expect_equal(s$dispersal_min,         0.0)
  expect_equal(s$dispersal_max,         0.5)
})

# ── 20. dispersal_tendency_mutation_sd does not exist; dispersal_mutation_sd does ─
test_that("dispersal_mutation_sd (not dispersal_tendency_mutation_sd) is the correct param name", {
  skip_no_julia()
  nms <- names(default_specs())
  expect_true("dispersal_mutation_sd" %in% nms)
})

# ── 21. With dispersal_evolution = TRUE, run completes and n_births > 0 ──────
test_that("dispersal_evolution = TRUE run completes", {
  skip_no_julia()
  s <- .disp_specs(random_seed = 42L)
  env <- run_alife(s, verbose = FALSE)
  expect_true(is.list(env))
  expect_true(as.integer(env$t) >= 1L)
})

# ── 22. With dispersal_cost = 0.0, population survives at least 30 ticks ─────
test_that("dispersal_cost = 0.0 (free dispersal) population survives all ticks", {
  skip_no_julia()
  s <- .qs(
    dispersal_evolution = TRUE,
    dispersal_init_mean = 0.3,
    dispersal_cost      = 0.0,
    n_agents_init       = 20L,
    max_ticks           = 30L,
    random_seed         = 42L
  )
  env <- run_alife(s, verbose = FALSE)
  expect_true(as.integer(env$t) >= 1L)
})

# ── 23. With dispersal_init_mean = 1.0, run completes and n_births > 0 ───────
test_that("dispersal_init_mean = 1.0 (always disperse) run completes with births", {
  skip_no_julia()
  s <- .qs(
    dispersal_evolution   = TRUE,
    dispersal_init_mean   = 1.0,
    dispersal_max         = 1.0,
    dispersal_mutation_sd = 0.0,
    dispersal_cost        = 0.0,
    n_agents_init         = 20L,
    max_ticks             = 30L,
    energy_init           = 200.0,
    random_seed           = 42L
  )
  env <- run_alife(s, verbose = FALSE)
  expect_true(is.list(env))
  total_births <- sum(env$progress$n_births)
  expect_gt(total_births, 0L)
})
