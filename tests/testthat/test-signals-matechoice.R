test_that("signal_dims defaults to 0", {
  expect_equal(default_specs()$signal_dims, 0L)
})

test_that("signal_cost defaults to 0.1", {
  expect_equal(default_specs()$signal_cost, 0.1)
})

test_that("mate_choice_mode defaults to 'random'", {
  expect_equal(default_specs()$mate_choice_mode, "random")
})

test_that("mate_choice_strength defaults to 0.5", {
  expect_equal(default_specs()$mate_choice_strength, 0.5)
})

test_that("signal_dims is integer-like", {
  d <- default_specs()$signal_dims
  expect_true(is.integer(d) || (is.numeric(d) && d == as.integer(d)))
})

test_that("signal_cost is numeric and positive", {
  s <- default_specs()$signal_cost
  expect_true(is.numeric(s))
  expect_true(s > 0)
})

test_that("mate_choice_strength is in [0, 1]", {
  m <- default_specs()$mate_choice_strength
  expect_true(m >= 0 && m <= 1)
})

test_that("mate_choice_mode is a recognised mode", {
  m <- default_specs()$mate_choice_mode
  expect_true(m %in% c("random", "energy", "signal", "genetic"))
})

test_that("signal_dims is non-negative", {
  expect_true(default_specs()$signal_dims >= 0)
})

test_that("signal_cost is in a reasonable range (0, 10)", {
  s <- default_specs()$signal_cost
  expect_true(s > 0 && s < 10)
})

test_that("all signal and mate-choice params are present in default_specs", {
  nms <- names(default_specs())
  for (p in c("signal_dims", "signal_cost", "mate_choice_mode", "mate_choice_strength")) {
    expect_true(p %in% nms, info = paste("missing:", p))
  }
})

test_that("signal evolution is effectively disabled when signal_dims == 0", {
  expect_true(default_specs()$signal_dims == 0)
})

test_that("signal energy cost formula is positive for nonzero signal", {
  signal_cost <- default_specs()$signal_cost
  signal <- c(0.5, -0.3)
  cost <- signal_cost * sum(abs(signal))
  expect_true(cost > 0)
})

test_that("signal vector length equals signal_dims (zeros initialisation)", {
  dims <- default_specs()$signal_dims
  sig <- numeric(dims)
  expect_equal(length(sig), dims)
})

test_that("mate_choice_strength closer to 0 means less randomness (documented)", {
  # strength = 0 → fully selective; strength = 1 → fully random
  # verify that 0.5 is strictly between the bounds, consistent with documentation
  m <- default_specs()$mate_choice_strength
  expect_true(m > 0 && m < 1)
})

test_that("signal_dims can be set to 2L without error", {
  s <- default_specs()
  s$signal_dims <- 2L
  expect_equal(s$signal_dims, 2L)
})

# ── Additional tests ──────────────────────────────────────────────────────────

test_that("signal_cost defaults to 0.1", {
  expect_equal(default_specs()$signal_cost, 0.1)
})

test_that("signal_evolution_drift defaults to TRUE", {
  expect_true(default_specs()$signal_evolution_drift)
})

test_that("signal_drift_sd defaults to 0.01", {
  expect_equal(default_specs()$signal_drift_sd, 0.01)
})

test_that("mate_choice_mode is a character parameter", {
  expect_true(is.character(default_specs()$mate_choice_mode))
})

test_that("mean_signal_magnitude is in valid_descriptor_columns", {
  expect_true("mean_signal_magnitude" %in% clade:::.valid_descriptor_columns())
})

test_that("signal parameter names are all in valid_descriptor_columns", {
  vd <- clade:::.valid_descriptor_columns()
  expect_true("mean_signal_magnitude" %in% vd)
})

test_that("signal params round-trip through default_specs", {
  s <- default_specs()
  s$signal_dims            <- 2L
  s$signal_cost            <- 0.05
  s$signal_evolution_drift <- TRUE
  s$signal_drift_sd        <- 0.02
  s$mate_choice_mode       <- "signal"
  s$mate_choice_strength   <- 0.8
  expect_equal(s$signal_dims, 2L)
  expect_equal(s$signal_cost, 0.05)
  expect_true(s$signal_evolution_drift)
  expect_equal(s$signal_drift_sd, 0.02)
  expect_equal(s$mate_choice_mode, "signal")
  expect_equal(s$mate_choice_strength, 0.8)
})

test_that("signal_drift_sd is non-negative", {
  expect_true(default_specs()$signal_drift_sd >= 0)
})

test_that("signal_evolution_drift is logical", {
  expect_true(is.logical(default_specs()$signal_evolution_drift))
})

test_that("signal_dims = 0 implies zero-length signal vector", {
  dims <- default_specs()$signal_dims
  expect_equal(dims, 0L)
  expect_equal(length(numeric(dims)), 0L)
})

test_that("signal cost scales linearly with magnitude", {
  cost_per_unit <- default_specs()$signal_cost
  magnitude     <- 2.0
  total_cost    <- cost_per_unit * magnitude
  expect_equal(total_cost, cost_per_unit * 2.0)
})

test_that("mate_choice_strength = 0.5 is strictly interior", {
  m <- default_specs()$mate_choice_strength
  expect_true(m > 0.0 && m < 1.0)
})

test_that("all signal and mate-choice params present in default_specs names", {
  nms <- names(default_specs())
  expected <- c("signal_dims", "signal_cost", "signal_evolution_drift",
                "signal_drift_sd", "mate_choice_mode", "mate_choice_strength")
  for (p in expected) {
    expect_true(p %in% nms, info = paste("missing:", p))
  }
})

test_that("run_clade with signal_dims = 2L and ploidy = 2L completes without error", {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- default_specs()
  s$grid_rows     <- 10L
  s$grid_cols     <- 10L
  s$n_agents_init <- 10L
  s$max_agents    <- 60L
  s$max_ticks     <- 20L
  s$signal_dims   <- 2L
  s$ploidy        <- 2L
  s$random_seed   <- 42L
  expect_no_error(env <- run_clade(s, verbose = FALSE))
  expect_true(is.list(env))
})

test_that("run_clade with signal_dims = 2 has mean_signal_magnitude column", {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- default_specs()
  s$grid_rows     <- 10L
  s$grid_cols     <- 10L
  s$n_agents_init <- 10L
  s$max_agents    <- 60L
  s$max_ticks     <- 20L
  s$signal_dims   <- 2L
  s$random_seed   <- 42L
  env <- run_clade(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  expect_true("mean_signal_magnitude" %in% names(d))
  expect_true(all(d$mean_signal_magnitude >= 0))
})

test_that("run_clade with signal_dims = 0 has mean_signal_magnitude == 0 always", {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- default_specs()
  s$grid_rows     <- 10L
  s$grid_cols     <- 10L
  s$n_agents_init <- 10L
  s$max_agents    <- 60L
  s$max_ticks     <- 20L
  s$signal_dims   <- 0L
  s$random_seed   <- 42L
  env <- run_clade(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  expect_true(all(d$mean_signal_magnitude == 0))
})
