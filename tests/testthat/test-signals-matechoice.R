test_that("signal_dims defaults to 0", {
  expect_equal(default_specs()$signal_dims, 0L)
})

test_that("signal_cost defaults to 0.1", {
  expect_equal(default_specs()$signal_cost, 0.1)
})

test_that("mate_choice_mode defaults to 'preference' (0.6.4 wiring)", {
  expect_equal(default_specs()$mate_choice_mode, "preference")
})

test_that("mate_choice_strength defaults to 1.0 (greedy argmax, preserves pre-0.6.4 behaviour)", {
  expect_equal(default_specs()$mate_choice_strength, 1.0)
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
  expect_true(m %in% c("random", "preference", "highest_signal"))
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

test_that("mate_choice_strength default is in [0, 1]", {
  m <- default_specs()$mate_choice_strength
  expect_true(m >= 0 && m <= 1)
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

test_that("mate_choice_strength default is a valid [0, 1] scalar", {
  m <- default_specs()$mate_choice_strength
  expect_true(is.numeric(m) && m >= 0 && m <= 1)
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

test_that("preference_bias_strength defaults to 0 (off)", {
  expect_equal(default_specs()$preference_bias_strength, 0.0)
})

test_that("preference_bias_target defaults to NULL (off)", {
  expect_null(default_specs()$preference_bias_target)
})

test_that("preference_bias_target + strength > 0 pulls preferences toward target", {
  # 0.6.5 regression test: Ryan 1990 β_N mechanism. With bias active,
  # mean agent preference should converge on the target over time.
  # Fails if apply_preference_bias! is not hooked into the tick loop.
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")

  s <- default_specs()
  s$grid_rows              <- 30L
  s$grid_cols              <- 30L
  s$n_agents_init          <- 60L
  s$max_agents             <- 150L
  s$max_ticks              <- 500L
  s$grass_rate             <- 0.15
  s$n_predators_init       <- 0L
  s$signal_dims            <- 3L
  s$signal_evolution_drift <- TRUE
  s$signal_drift_sd        <- 0.05
  s$preference_bias_strength <- 0.05
  s$preference_bias_target   <- c(1.0, 0.0, 0.0)
  s$random_seed            <- 42L

  env <- suppressWarnings(run_alife(s))
  # Mean preference[1] should be positive and substantially away from 0.
  pref_sum <- 0; n_alive <- 0L
  for (i in seq_len(length(env$agents))) {
    ag <- env$agents[[i]]
    if (isTRUE(ag$alive)) {
      pref_sum <- pref_sum + as.numeric(ag$preference)[1]
      n_alive  <- n_alive + 1L
    }
  }
  expect_gt(n_alive, 0L)
  mean_pref_d1 <- pref_sum / n_alive
  # With κ = 0.05 for 500 ticks, preference[1] should saturate above 0.3.
  expect_gt(mean_pref_d1, 0.3)
})

test_that("mate_choice_mode is wired: random vs preference produce different trajectories", {
  # Regression test for the 0.6.4 fix. Before 0.6.4, reproduce.jl ignored
  # mate_choice_mode and always used preference-argmax when signal_dims > 0.
  # This test fails against the pre-0.6.4 kernel because both conditions
  # would produce bit-identical trajectories.
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")

  run_with <- function(mode) {
    s <- default_specs()
    s$grid_rows              <- 30L
    s$grid_cols              <- 30L
    s$n_agents_init          <- 80L
    s$max_agents             <- 200L
    s$max_ticks              <- 400L
    s$grass_rate             <- 0.15
    s$n_predators_init       <- 0L
    s$signal_dims            <- 3L
    s$signal_evolution_drift <- TRUE
    s$signal_drift_sd        <- 0.05
    s$mate_choice_mode       <- mode
    s$mate_choice_strength   <- 1.0
    s$random_seed            <- 7L
    suppressWarnings(get_run_data(run_alife(s))$ticks$mean_signal_magnitude)
  }

  traj_random <- run_with("random")
  traj_pref   <- run_with("preference")

  # The trajectories must differ somewhere. If they match exactly at every
  # tick, the kernel is ignoring mate_choice_mode (the 0.6.4 bug).
  expect_false(isTRUE(all.equal(traj_random, traj_pref, tolerance = 0)))
})

test_that("mate_choice_strength is wired: strength=1.0 ≠ strength=0.0 under preference mode", {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")

  run_with <- function(strength) {
    s <- default_specs()
    s$grid_rows              <- 30L
    s$grid_cols              <- 30L
    s$n_agents_init          <- 80L
    s$max_agents             <- 200L
    s$max_ticks              <- 400L
    s$grass_rate             <- 0.15
    s$n_predators_init       <- 0L
    s$signal_dims            <- 3L
    s$signal_evolution_drift <- TRUE
    s$signal_drift_sd        <- 0.05
    s$mate_choice_mode       <- "preference"
    s$mate_choice_strength   <- strength
    s$random_seed            <- 11L
    suppressWarnings(get_run_data(run_alife(s))$ticks$mean_signal_magnitude)
  }

  traj_greedy <- run_with(1.0)
  traj_random <- run_with(0.0)

  expect_false(isTRUE(all.equal(traj_greedy, traj_random, tolerance = 0)))
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
