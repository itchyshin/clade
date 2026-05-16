test_that("n_predators_init defaults to 0L", {
  skip_no_julia()
  expect_equal(default_specs()$n_predators_init, 0L)
})

test_that("predator_energy_init defaults to 150.0", {
  skip_no_julia()
  expect_equal(default_specs()$predator_energy_init, 150.0)
})

test_that("predator_live_energy defaults to 2.0", {
  skip_no_julia()
  expect_equal(default_specs()$predator_live_energy, 2.0)
})

test_that("predator_attack_strength defaults to 40.0", {
  skip_no_julia()
  expect_equal(default_specs()$predator_attack_strength, 40.0)
})

test_that("predator_energy_gain defaults to 30.0", {
  skip_no_julia()
  expect_equal(default_specs()$predator_energy_gain, 30.0)
})

test_that("predator_min_repro_energy defaults to 200.0", {
  skip_no_julia()
  expect_equal(default_specs()$predator_min_repro_energy, 200.0)
})

test_that("predator_min_repro_age defaults to 5L", {
  skip_no_julia()
  expect_equal(default_specs()$predator_min_repro_age, 5L)
})

test_that("predator_mutation_sd defaults to 0.1", {
  skip_no_julia()
  expect_equal(default_specs()$predator_mutation_sd, 0.1)
})

test_that("predator_max_agents defaults to 50L", {
  skip_no_julia()
  expect_equal(default_specs()$predator_max_agents, 50L)
})

test_that("all predator params are present in default_specs", {
  skip_no_julia()
  nms <- names(default_specs())
  for (p in c("n_predators_init", "predator_energy_init", "predator_live_energy",
               "predator_move_energy", "predator_attack_strength",
               "predator_energy_gain", "predator_min_repro_energy",
               "predator_min_repro_age", "predator_mutation_sd",
               "predator_max_agents")) {
    expect_true(p %in% nms, info = paste("missing:", p))
  }
})

test_that("n_predators_init is integer-like", {
  skip_no_julia()
  v <- default_specs()$n_predators_init
  expect_true(is.integer(v) || (is.numeric(v) && v == as.integer(v)))
})

test_that("predator_attack_strength is positive", {
  skip_no_julia()
  expect_true(default_specs()$predator_attack_strength > 0)
})

test_that("predator_energy_gain is positive and within plausible energy-balance bound", {
  skip_no_julia()
  s <- default_specs()
  expect_true(s$predator_energy_gain > 0)
  expect_true(s$predator_energy_gain <= s$predator_attack_strength * 2)
})

test_that("predator_min_repro_energy exceeds predator_energy_init", {
  skip_no_julia()
  s <- default_specs()
  expect_true(s$predator_min_repro_energy > s$predator_energy_init)
})

test_that("dilution factor formula is less than 1 when predators are present", {
  skip_no_julia()
  attack_strength <- default_specs()$predator_attack_strength
  n_agents        <- 5
  factor          <- 1.0 / (1.0 + n_agents * attack_strength)
  expect_true(factor < 1.0)
  expect_true(factor > 0.0)
})

# ── Additional tests ──────────────────────────────────────────────────────────

test_that("predator_move_energy defaults to 1.0", {
  skip_no_julia()
  expect_equal(default_specs()$predator_move_energy, 1.0)
})

test_that("predator_live_energy is positive", {
  skip_no_julia()
  expect_true(default_specs()$predator_live_energy > 0)
})

test_that("predator_move_energy is positive", {
  skip_no_julia()
  expect_true(default_specs()$predator_move_energy > 0)
})

test_that("predator_attack_strength is numeric", {
  skip_no_julia()
  expect_true(is.numeric(default_specs()$predator_attack_strength))
})

test_that("predator_max_agents is integer", {
  skip_no_julia()
  expect_true(is.integer(default_specs()$predator_max_agents))
})

test_that("predator_min_repro_age is integer-typed", {
  skip_no_julia()
  v <- default_specs()$predator_min_repro_age
  expect_true(is.integer(v))
})

test_that("predator parameters are in valid_descriptor_columns (n_predators)", {
  skip_no_julia()
  expect_true("n_predators" %in% clade:::.valid_descriptor_columns())
})

test_that("n_prey_killed is in valid_descriptor_columns", {
  skip_no_julia()
  expect_true("n_prey_killed" %in% clade:::.valid_descriptor_columns())
})

test_that("predator params round-trip through default_specs modification", {
  skip_no_julia()
  s <- default_specs()
  s$n_predators_init        <- 5L
  s$predator_energy_init    <- 200.0
  s$predator_attack_strength <- 50.0
  s$predator_max_agents     <- 30L
  expect_equal(s$n_predators_init, 5L)
  expect_equal(s$predator_energy_init, 200.0)
  expect_equal(s$predator_attack_strength, 50.0)
  expect_equal(s$predator_max_agents, 30L)
})

test_that("predator_mutation_sd is in valid range (0, 1]", {
  skip_no_julia()
  v <- default_specs()$predator_mutation_sd
  expect_true(v > 0 && v <= 1)
})

test_that("predator_energy_gain is less than predator_min_repro_energy", {
  skip_no_julia()
  s <- default_specs()
  expect_true(s$predator_energy_gain < s$predator_min_repro_energy)
})

test_that("run_clade with n_predators_init = 0 has n_predators == 0 always", {
  skip_no_julia()
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- default_specs()
  s$grid_rows       <- 10L
  s$grid_cols       <- 10L
  s$n_agents_init   <- 10L
  s$max_agents      <- 60L
  s$max_ticks       <- 20L
  s$n_predators_init <- 0L
  s$random_seed     <- 42L
  env <- run_clade(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  expect_true("n_predators" %in% names(d))
  expect_true(all(d$n_predators == 0L))
})

test_that("run_clade with n_predators_init = 5 has n_predators > 0 early", {
  skip_no_julia()
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- default_specs()
  s$grid_rows        <- 10L
  s$grid_cols        <- 10L
  s$n_agents_init    <- 20L
  s$max_agents       <- 100L
  s$max_ticks        <- 20L
  s$n_predators_init <- 5L
  s$random_seed      <- 42L
  env <- run_clade(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  expect_true("n_predators" %in% names(d))
  # Predators present at tick 1
  expect_true(d$n_predators[1L] > 0L)
})

test_that("predator_live_energy defaults to 2.0", {
  skip_no_julia()
  expect_equal(default_specs()$predator_live_energy, 2.0)
})

test_that("n_prey_killed column is non-negative in a zero-predator run", {
  skip_no_julia()
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- default_specs()
  s$grid_rows        <- 10L
  s$grid_cols        <- 10L
  s$n_agents_init    <- 10L
  s$max_agents       <- 60L
  s$max_ticks        <- 20L
  s$n_predators_init <- 0L
  s$random_seed      <- 42L
  env <- run_clade(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  expect_true("n_prey_killed" %in% names(d))
  expect_true(all(d$n_prey_killed >= 0L))
})
