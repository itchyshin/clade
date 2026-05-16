# Tests verifying that multiple modules can be enabled simultaneously without
# error at the parameter level — no Julia required.

library(testthat)

# ── 1. All major module flags default to FALSE or 0 ──────────────────────────
test_that("all major module flags default to FALSE or 0 (no module on by default)", {
  skip_no_julia()
  s <- default_specs()
  module_flags <- c(
    "disease", "kin_selection", "cooperation_evolution", "speciation",
    "niche_construction", "scavenging", "group_defense",
    "habitat_preference_evolution", "parental_care", "mimicry",
    "social_learning", "body_size_evolution", "metabolic_rate_evolution",
    "aging_rate_evolution", "immune_evolution", "dispersal_evolution",
    "epigenetics", "world_evolution", "log_genomes",
    "mutation_rate_evolution", "learning_rate_evolution",
    "life_history_evolution", "phenotypic_plasticity",
    "cooperative_breeding", "clutch_size_evolution",
    "parental_investment_evolution", "stress_hypermutation"
  )
  count_flags <- c("n_predators_init", "signal_dims", "allee_threshold")

  for (nm in module_flags) {
    expect_false(isTRUE(s[[nm]]),
                 info = sprintf("specs$%s should default to FALSE", nm))
  }
  for (nm in count_flags) {
    expect_equal(s[[nm]], 0L,
                 info = sprintf("specs$%s should default to 0", nm))
  }
})

# ── 2. disease + kin_selection can coexist ────────────────────────────────────
test_that("disease = TRUE and kin_selection = TRUE can coexist in a specs list", {
  skip_no_julia()
  s <- default_specs()
  s$disease      <- TRUE
  s$kin_selection <- TRUE
  expect_true(is.list(s))
  expect_true(s$disease)
  expect_true(s$kin_selection)
})

# ── 3. cooperation_evolution + dispersal_evolution can coexist ────────────────
test_that("cooperation_evolution and dispersal_evolution can coexist", {
  skip_no_julia()
  s <- default_specs()
  s$cooperation_evolution <- TRUE
  s$dispersal_evolution   <- TRUE
  expect_true(is.list(s))
  expect_true(s$cooperation_evolution)
  expect_true(s$dispersal_evolution)
})

# ── 4. parental_care + cooperative_breeding can coexist ──────────────────────
test_that("parental_care and cooperative_breeding can coexist", {
  skip_no_julia()
  s <- default_specs()
  s$parental_care        <- TRUE
  s$cooperative_breeding <- TRUE
  expect_true(is.list(s))
  expect_true(s$parental_care)
  expect_true(s$cooperative_breeding)
})

# ── 5. mimicry + speciation can coexist ──────────────────────────────────────
test_that("mimicry and speciation can coexist", {
  skip_no_julia()
  s <- default_specs()
  s$mimicry    <- TRUE
  s$speciation <- TRUE
  expect_true(is.list(s))
  expect_true(s$mimicry)
  expect_true(s$speciation)
})

# ── 6. body_size_evolution + metabolic_rate_evolution can coexist ─────────────
test_that("body_size_evolution and metabolic_rate_evolution can coexist", {
  skip_no_julia()
  s <- default_specs()
  s$body_size_evolution      <- TRUE
  s$metabolic_rate_evolution <- TRUE
  expect_true(is.list(s))
  expect_true(s$body_size_evolution)
  expect_true(s$metabolic_rate_evolution)
})

# ── 7. social_learning + rl_mode != "none" can coexist ───────────────────────
test_that("social_learning = TRUE and rl_mode = 'actor_critic' can coexist", {
  skip_no_julia()
  s <- default_specs()
  s$social_learning <- TRUE
  s$rl_mode         <- "actor_critic"
  expect_true(is.list(s))
  expect_true(s$social_learning)
  expect_equal(s$rl_mode, "actor_critic")
})

# ── 8. all parameter names in default_specs() are unique ─────────────────────
test_that("all parameter names in default_specs() are unique (no duplicates)", {
  skip_no_julia()
  nms <- names(default_specs())
  expect_equal(length(nms), length(unique(nms)))
})

# ── Julia-dependent tests ─────────────────────────────────────────────────────

# ── 9. Kitchen-sink run with multiple modules completes without error ─────────
test_that("run with disease + kin_selection + social_learning completes", {
  skip_no_julia()
  s <- default_specs()
  s$grid_rows          <- 10L
  s$grid_cols          <- 10L
  s$n_agents_init      <- 8L
  s$max_agents         <- 60L
  s$max_ticks          <- 10L
  s$disease            <- TRUE
  s$kin_selection      <- TRUE
  s$social_learning    <- TRUE
  env <- run_alife(s, verbose = FALSE)
  expect_true(is.list(env))
})

# ── 10. Number of ticks in run_data matches max_ticks ────────────────────────
test_that("number of rows in run_data$ticks equals max_ticks", {
  skip_no_julia()
  s <- default_specs()
  s$grid_rows     <- 10L
  s$grid_cols     <- 10L
  s$n_agents_init <- 5L
  s$max_agents    <- 50L
  s$max_ticks     <- 8L
  env <- run_alife(s, verbose = FALSE)
  rd  <- get_run_data(env)
  expect_equal(nrow(rd$ticks), 8L)
})

# ── 11. All expected column names are present in ticks ───────────────────────
test_that("run_data$ticks contains all core column names", {
  skip_no_julia()
  s <- default_specs()
  s$grid_rows     <- 10L
  s$grid_cols     <- 10L
  s$n_agents_init <- 5L
  s$max_agents    <- 50L
  s$max_ticks     <- 5L
  env <- run_alife(s, verbose = FALSE)
  rd  <- get_run_data(env)
  core_cols <- c("t", "n_agents", "n_births", "n_deaths", "mean_energy",
                 "mean_age", "genetic_diversity", "grass_coverage")
  missing <- setdiff(core_cols, names(rd$ticks))
  expect_equal(missing, character(0L))
})

# ── 12. Births occurred somewhere in the run ─────────────────────────────────
test_that("n_births > 0 in at least one tick of a standard run", {
  skip_no_julia()
  s <- default_specs()
  s$grid_rows     <- 15L
  s$grid_cols     <- 15L
  s$n_agents_init <- 20L
  s$max_agents    <- 200L
  s$max_ticks     <- 50L
  env <- run_alife(s, verbose = FALSE)
  rd  <- get_run_data(env)
  expect_true(any(rd$ticks$n_births > 0L))
})

# ── 13. genetic_diversity is non-negative throughout the run ─────────────────
test_that("genetic_diversity column is non-negative throughout the run", {
  skip_no_julia()
  s <- default_specs()
  s$grid_rows     <- 10L
  s$grid_cols     <- 10L
  s$n_agents_init <- 5L
  s$max_agents    <- 50L
  s$max_ticks     <- 10L
  env <- run_alife(s, verbose = FALSE)
  rd  <- get_run_data(env)
  expect_true(all(rd$ticks$genetic_diversity >= 0.0, na.rm = TRUE))
})

# ── 14. Population size stays positive for at least the first 5 ticks ────────
test_that("n_agents > 0 for at least the first 5 ticks", {
  skip_no_julia()
  s <- default_specs()
  s$grid_rows     <- 10L
  s$grid_cols     <- 10L
  s$n_agents_init <- 8L
  s$max_agents    <- 80L
  s$max_ticks     <- 10L
  env <- run_alife(s, verbose = FALSE)
  rd  <- get_run_data(env)
  early <- head(rd$ticks$n_agents, 5L)
  expect_true(all(early > 0L))
})

# ── 15. mean_energy stays positive for at least the first 5 ticks ────────────
test_that("mean_energy > 0 for at least the first 5 ticks", {
  skip_no_julia()
  s <- default_specs()
  s$grid_rows     <- 10L
  s$grid_cols     <- 10L
  s$n_agents_init <- 8L
  s$max_agents    <- 80L
  s$max_ticks     <- 10L
  env <- run_alife(s, verbose = FALSE)
  rd  <- get_run_data(env)
  early <- head(rd$ticks$mean_energy, 5L)
  expect_true(all(early > 0.0, na.rm = TRUE))
})
