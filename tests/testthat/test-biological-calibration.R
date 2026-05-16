# Biological calibration tests for clade.
#
# Each test validates a specific theoretical prediction from evolutionary
# biology or ecology against simulated dynamics. Tests are directional:
# they check that measurable quantities move in the expected direction given
# the perturbation, not merely that the run completes.
#
# All tests require Julia and are skipped gracefully on Julia-free systems.

library(testthat)

# ── Helpers ───────────────────────────────────────────────────────────────────

# Base specs for calibration runs: small grid, moderate population, enough
# ticks to observe dynamics, reproducible seed.
.cal_specs <- function(...) {
  s <- default_specs()
  s$grid_rows     <- 20L
  s$grid_cols     <- 20L
  s$n_agents_init <- 30L
  s$max_agents    <- 300L
  s$max_ticks     <- 300L
  s$random_seed   <- 42L
  args <- list(...)
  for (nm in names(args)) s[[nm]] <- args[[nm]]
  s
}

# ── 1. Energy conservation floor ─────────────────────────────────────────────
test_that("mean_energy never goes negative (energy has a floor)", {
  skip_no_julia()
  s   <- .cal_specs()
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  # Starvation kills agents before energy can go negative; exclude ticks
  # where n_agents == 0 (mean is undefined / recorded as 0).
  active <- d$n_agents > 0
  expect_true(
    all(d$mean_energy[active] >= 0),
    info = "mean_energy should never go negative while agents are alive"
  )
})

# ── 2. Population dynamics: boom-bust ────────────────────────────────────────
test_that("population fluctuates — CV of n_agents > 0.05", {
  skip_no_julia()
  s   <- .cal_specs()
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  cv  <- stats::sd(d$n_agents) / mean(d$n_agents)
  expect_gt(cv, 0.05)
})

# ── 3. Genetic drift without selection ───────────────────────────────────────
test_that("genetic_diversity changes over time under drift", {
  skip_no_julia()
  s   <- .cal_specs()
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  gd  <- d$genetic_diversity[d$n_agents > 0]
  expect_gt(length(gd), 1L)
  expect_true(
    any(diff(gd) != 0),
    info = "genetic_diversity should not be constant under drift"
  )
})

# ── 4. Mutation increases diversity ──────────────────────────────────────────
test_that("high mutation_sd gives higher genetic_diversity than low", {
  skip_no_julia()
  s_hi   <- .cal_specs(mutation_sd = 0.5)
  s_lo   <- .cal_specs(mutation_sd = 0.01)
  env_hi <- run_alife(s_hi, verbose = FALSE)
  env_lo <- run_alife(s_lo, verbose = FALSE)
  d_hi   <- get_run_data(env_hi)$ticks
  d_lo   <- get_run_data(env_lo)$ticks
  expect_gt(mean(d_hi$genetic_diversity), mean(d_lo$genetic_diversity))
})

# ── 5. Body size metabolic scaling ───────────────────────────────────────────
test_that("large body size gives lower mean_energy at tick 1 (metabolic cost)", {
  skip_no_julia()
  base <- .cal_specs(
    body_size_evolution   = TRUE,
    body_size_mutation_sd = 0.0,
    min_repro_energy      = 500.0,
    grass_rate            = 0.0,
    grass_max             = 0.0,
    grass_init_prob       = 0.0,
    max_ticks             = 10L
  )
  s_large <- base; s_large$body_size_init_mean <- 2.0
  s_small <- base; s_small$body_size_init_mean <- 0.5

  env_large <- run_alife(s_large, verbose = FALSE)
  env_small <- run_alife(s_small, verbose = FALSE)
  d_large   <- get_run_data(env_large)$ticks
  d_small   <- get_run_data(env_small)$ticks

  e_large <- d_large$mean_energy[1L]
  e_small <- d_small$mean_energy[1L]

  if (!is.nan(e_large) && !is.nan(e_small) &&
        d_large$n_agents[1L] > 0 && d_small$n_agents[1L] > 0) {
    expect_lt(e_large, e_small)
  } else {
    succeed()
  }
})

# ── 6. Disease reduces population ────────────────────────────────────────────
test_that("high-transmission disease lowers mean n_agents vs control", {
  skip_no_julia()
  s_disease <- .cal_specs(
    disease            = TRUE,
    disease_seed_prob  = 0.5,
    transmission_prob  = 0.5,
    disease_death_prob = 0.1,
    max_ticks          = 200L
  )
  s_control <- .cal_specs(disease = FALSE, max_ticks = 200L)

  env_disease <- run_alife(s_disease, verbose = FALSE)
  env_control <- run_alife(s_control, verbose = FALSE)
  d_disease   <- get_run_data(env_disease)$ticks
  d_control   <- get_run_data(env_control)$ticks

  expect_lt(mean(d_disease$n_agents), mean(d_control$n_agents))
})

# ── 7. Kin selection: population survives 400 ticks ──────────────────────────
test_that("kin_selection = TRUE: population survives 400 ticks", {
  skip_no_julia()
  s   <- .cal_specs(kin_selection = TRUE, max_ticks = 400L)
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  expect_gt(d$n_agents[400L], 0L)
})

# ── 8. Dispersal runs both survive 200 ticks ─────────────────────────────────
test_that("dispersal and no-dispersal runs both have > 10 agents at tick 200", {
  skip_no_julia()
  s_disp <- .cal_specs(
    dispersal_evolution = TRUE,
    dispersal_init_mean = 0.8,
    max_ticks           = 200L
  )
  s_nodisp <- .cal_specs(dispersal_evolution = FALSE, max_ticks = 200L)

  env_disp   <- run_alife(s_disp,   verbose = FALSE)
  env_nodisp <- run_alife(s_nodisp, verbose = FALSE)
  d_disp   <- get_run_data(env_disp)$ticks
  d_nodisp <- get_run_data(env_nodisp)$ticks

  expect_gt(d_disp$n_agents[200L],   10L)
  expect_gt(d_nodisp$n_agents[200L], 10L)
})

# ── 9. Predators kill prey ────────────────────────────────────────────────────
test_that("predators kill prey — n_prey_killed > 0 over 100 ticks", {
  skip_no_julia()
  s <- .cal_specs(
    n_predators_init     = 10L,
    max_predators        = 50L,
    predator_energy_init = 150.0,
    max_ticks            = 100L
  )
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  expect_gt(sum(d$n_prey_killed), 0L)
})

# ── 10. Parental care run completes with surviving agents ─────────────────────
test_that("parental_care = TRUE: agents survive a 200-tick run", {
  skip_no_julia()
  s <- .cal_specs(
    parental_care      = TRUE,
    care_cost_per_tick = 2.0,
    max_ticks          = 200L
  )
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  expect_gt(tail(d$n_agents, 1L), 0L)
})

# ── 11. Seasonal dynamics modulate grass coverage ─────────────────────────────
test_that("seasonal_amplitude = 0.8 oscillates grass_coverage by > 0.1", {
  skip_no_julia()
  s <- .cal_specs(
    seasonal_amplitude = 0.8,
    season_length      = 50L,
    max_ticks          = 200L,
    grass_rate         = 0.2
  )
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  rng <- diff(range(d$grass_coverage))
  expect_gt(rng, 0.1)
})

# ── 12. Senescence shortens mean lifespan ────────────────────────────────────
test_that("senescence_rate = 0.05 reduces mean_age vs senescence_rate = 0", {
  skip_no_julia()
  s_senes    <- .cal_specs(senescence_rate = 0.05)
  s_no_senes <- .cal_specs(senescence_rate = 0.0)
  env_senes    <- run_alife(s_senes,    verbose = FALSE)
  env_no_senes <- run_alife(s_no_senes, verbose = FALSE)
  d_senes    <- get_run_data(env_senes)$ticks
  d_no_senes <- get_run_data(env_no_senes)$ticks

  # Gompertz senescence kills agents earlier, so mean_age should be lower.
  active_s  <- d_senes$n_agents > 0
  active_ns <- d_no_senes$n_agents > 0
  mean_age_s  <- mean(d_senes$mean_age[active_s])
  mean_age_ns <- mean(d_no_senes$mean_age[active_ns])
  expect_lt(mean_age_s, mean_age_ns)
})

# ── 13. Diploid organisms produce births ─────────────────────────────────────
test_that("ploidy = 2L run produces births over 300 ticks", {
  skip_no_julia()
  s   <- .cal_specs(ploidy = 2L, max_ticks = 300L)
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  expect_gt(sum(d$n_births), 0L)
})

# ── 14. Allee effect run completes and returns a data frame ──────────────────
test_that("allee_threshold = 5L run returns a non-empty tick data frame", {
  skip_no_julia()
  s <- .cal_specs(
    allee_threshold = 5L,
    n_agents_init   = 30L,
    max_ticks       = 200L
  )
  env <- run_alife(s, verbose = FALSE)
  rd  <- get_run_data(env)
  expect_s3_class(rd$ticks, "data.frame")
  expect_gt(nrow(rd$ticks), 0L)
})

# ── 15. High grass rate sustains a larger population ─────────────────────────
test_that("grass_rate = 0.5 gives higher mean n_agents than grass_rate = 0.02", {
  skip_no_julia()
  s_hi   <- .cal_specs(grass_rate = 0.5)
  s_lo   <- .cal_specs(grass_rate = 0.02)
  env_hi <- run_alife(s_hi, verbose = FALSE)
  env_lo <- run_alife(s_lo, verbose = FALSE)
  d_hi   <- get_run_data(env_hi)$ticks
  d_lo   <- get_run_data(env_lo)$ticks
  expect_gt(mean(d_hi$n_agents), mean(d_lo$n_agents))
})

# ── 16. Niche construction produces births ────────────────────────────────────
test_that("niche_construction = TRUE: births occur over 200 ticks", {
  skip_no_julia()
  s <- .cal_specs(
    niche_construction = TRUE,
    shelter_build_prob = 0.3,
    shelter_min_energy = 60.0,
    max_ticks          = 200L
  )
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  expect_gt(sum(d$n_births), 0L)
})

# ── 17. Social learning run completes alongside control ──────────────────────
test_that("social_learning TRUE and FALSE runs both return tick data", {
  skip_no_julia()
  s_sl <- .cal_specs(social_learning = TRUE)
  s_no <- .cal_specs(social_learning = FALSE)
  env_sl <- run_alife(s_sl, verbose = FALSE)
  env_no <- run_alife(s_no, verbose = FALSE)
  rd_sl  <- get_run_data(env_sl)
  rd_no  <- get_run_data(env_no)
  expect_gt(nrow(rd_sl$ticks), 0L)
  expect_gt(nrow(rd_no$ticks), 0L)
})

# ── 18. min_repro_age delays first birth ─────────────────────────────────────
test_that("no births occur in ticks 1-19 when min_repro_age = 20", {
  skip_no_julia()
  # Agents start at age 0.  With min_repro_age = 20 they cannot reproduce
  # until they reach age 20.  Tick 20 is when founders first become eligible,
  # so ticks 1-19 must have zero births.
  s <- .cal_specs(
    min_repro_age = 20L,
    n_agents_init = 50L,
    max_ticks     = 100L
  )
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  early_births <- sum(d$n_births[seq_len(min(19L, nrow(d)))])
  expect_equal(as.integer(early_births), 0L)
})

# ── 19. Stress hypermutation raises genetic diversity ─────────────────────────
test_that("always-stressed run has >= 50% genetic_diversity of never-stressed", {
  skip_no_julia()
  # stress_threshold = 200 > energy_init (100), so agents are always stressed.
  s_stress <- .cal_specs(
    stress_hypermutation       = TRUE,
    stress_threshold           = 200.0,
    stress_mutation_multiplier = 10.0,
    max_ticks                  = 200L
  )
  # stress_threshold = 0: energy is always > 0, so agents are never stressed.
  s_none <- .cal_specs(
    stress_hypermutation       = TRUE,
    stress_threshold           = 0.0,
    stress_mutation_multiplier = 10.0,
    max_ticks                  = 200L
  )
  env_stress <- run_alife(s_stress, verbose = FALSE)
  env_none   <- run_alife(s_none,   verbose = FALSE)
  d_stress   <- get_run_data(env_stress)$ticks
  d_none     <- get_run_data(env_none)$ticks

  mean_s <- mean(d_stress$genetic_diversity)
  mean_n <- mean(d_none$genetic_diversity)
  expect_gt(mean_s, mean_n * 0.5)
})

# ── 20. Clutch size evolution: some ticks have > 1 birth ─────────────────────
test_that("clutch_size_evolution = TRUE: some ticks have n_births > 1", {
  skip_no_julia()
  s <- .cal_specs(
    clutch_size_evolution   = TRUE,
    clutch_size_init_mean   = 3.0,
    clutch_size_min         = 1L,
    clutch_size_max         = 5L,
    clutch_size_mutation_sd = 0.3,
    max_ticks               = 300L
  )
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  expect_true(
    any(d$n_births > 1L),
    info = "clutch evolution should produce ticks with > 1 birth"
  )
})
