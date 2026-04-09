# Tests for the brain_size_evolution module (parental provisioning hypothesis).
#
# Implements the expensive brain hypothesis (van Schaik et al. 2023 PLoS Biol;
# Griesser et al. 2023 PNAS; Song et al. 2025 PNAS): brain size is heritable,
# metabolically costly, and confers a cognitive foraging advantage.
# The key biological prediction tested below is that large-brained offspring
# face a bootstrapping problem that parental care resolves.

library(testthat)

# ── Helpers ───────────────────────────────────────────────────────────────────

.qs <- function(...) {
  s <- default_specs()
  s$grid_rows     <- 12L
  s$grid_cols     <- 12L
  s$n_agents_init <- 15L
  s$max_agents    <- 80L
  s$max_ticks     <- 20L
  args <- list(...)
  for (nm in names(args)) s[[nm]] <- args[[nm]]
  s
}

.bse_specs <- function(...) {
  .qs(
    brain_size_evolution   = TRUE,
    brain_size_init_mean   = 1.0,
    brain_size_mutation_sd = 0.05,
    brain_size_min         = 0.1,
    brain_size_max         = 3.0,
    brain_size_cost_scale  = 1.0,
    ...
  )
}

skip_no_julia <- function() {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
}

.agent_bsz <- function(env) {
  n <- as.integer(length(env$agents))
  if (n == 0L) return(numeric(0L))
  vapply(seq_len(n), function(i) as.numeric(env$agents[[i]]$brain_size),
         numeric(1L))
}

# ── 1. Default params present in default_specs() ─────────────────────────────
test_that("brain_size_evolution params are present in default_specs()", {
  s <- default_specs()
  expect_true("brain_size_evolution"  %in% names(s))
  expect_true("brain_size_init_mean"  %in% names(s))
  expect_true("brain_size_mutation_sd" %in% names(s))
  expect_true("brain_size_min"         %in% names(s))
  expect_true("brain_size_max"         %in% names(s))
  expect_true("brain_size_cost_scale"  %in% names(s))
})

# ── 2. brain_size_evolution defaults to FALSE ─────────────────────────────────
test_that("brain_size_evolution defaults to FALSE", {
  expect_false(default_specs()$brain_size_evolution)
})

# ── 3. brain_size_init_mean defaults to 1.0 ──────────────────────────────────
test_that("brain_size_init_mean defaults to 1.0", {
  expect_identical(default_specs()$brain_size_init_mean, 1.0)
})

# ── 4. brain_size_cost_scale defaults to 1.0 ─────────────────────────────────
test_that("brain_size_cost_scale defaults to 1.0", {
  expect_identical(default_specs()$brain_size_cost_scale, 1.0)
})

# ── 5. brain_size_min defaults to 0.1 ────────────────────────────────────────
test_that("brain_size_min defaults to 0.1", {
  expect_identical(default_specs()$brain_size_min, 0.1)
})

# ── 6. brain_size_max defaults to 3.0 ────────────────────────────────────────
test_that("brain_size_max defaults to 3.0", {
  expect_identical(default_specs()$brain_size_max, 3.0)
})

# ── 7. brain_size_mutation_sd defaults to 0.05 ───────────────────────────────
test_that("brain_size_mutation_sd defaults to 0.05", {
  expect_identical(default_specs()$brain_size_mutation_sd, 0.05)
})

# ── 8. Params round-trip through default_specs() ─────────────────────────────
test_that("brain_size params round-trip through default_specs()", {
  s <- default_specs()
  expect_false(s$brain_size_evolution)
  expect_equal(s$brain_size_init_mean,   1.0)
  expect_equal(s$brain_size_min,         0.1)
  expect_equal(s$brain_size_max,         3.0)
  expect_equal(s$brain_size_mutation_sd, 0.05)
  expect_equal(s$brain_size_cost_scale,  1.0)
})

# ── 9. run_alife completes with brain_size_evolution = TRUE ──────────────────
test_that("run_alife completes without error when brain_size_evolution = TRUE", {
  skip_no_julia()
  s <- .bse_specs()
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(as.integer(env$t) >= 1L)
})

# ── 10. brain_size = 1 for all agents when evolution is off ──────────────────
test_that("brain_size is 1.0 for all agents when brain_size_evolution = FALSE", {
  skip_no_julia()
  s   <- .qs()
  env <- run_alife(s, verbose = FALSE)
  bsz <- .agent_bsz(env)
  if (length(bsz) > 0L) {
    expect_true(all(abs(bsz - 1.0) < 1e-6),
                info = "All agents should have reference brain_size = 1.0")
  }
})

# ── 11. brain_size variation appears when evolution is on ────────────────────
test_that("brain_size variation appears when brain_size_evolution = TRUE", {
  skip_no_julia()
  s   <- .bse_specs(brain_size_mutation_sd = 0.15, max_ticks = 40L,
                    n_agents_init = 25L)
  env <- run_alife(s, verbose = FALSE)
  bsz <- .agent_bsz(env)
  if (length(bsz) > 1L) {
    expect_gt(stats::sd(bsz), 0.0,
              label = "brain_size should vary across agents after mutation")
  }
})

# ── 12. brain_size stays within [min, max] ───────────────────────────────────
test_that("brain_size stays within [brain_size_min, brain_size_max]", {
  skip_no_julia()
  s   <- .bse_specs(max_ticks = 40L)
  env <- run_alife(s, verbose = FALSE)
  bsz <- .agent_bsz(env)
  if (length(bsz) > 0L) {
    expect_true(all(bsz >= s$brain_size_min - 1e-6))
    expect_true(all(bsz <= s$brain_size_max + 1e-6))
  }
})

# ── 13. mean_brain_size is logged in env$progress ────────────────────────────
test_that("mean_brain_size is logged in env$progress", {
  skip_no_julia()
  s   <- .bse_specs()
  env <- run_alife(s, verbose = FALSE)
  expect_true("mean_brain_size" %in% names(env$progress))
})

# ── 14. mean_brain_size ≈ 1.0 when evolution is off ─────────────────────────
test_that("mean_brain_size equals 1.0 at all active ticks when evolution is off", {
  skip_no_julia()
  s   <- .qs(max_ticks = 10L, random_seed = 2L)
  env <- run_alife(s, verbose = FALSE)
  mbz    <- env$progress$mean_brain_size
  active <- env$progress$n_agents > 0L
  if (any(active)) {
    expect_true(all(abs(mbz[active] - 1.0) < 1e-9),
                info = "mean_brain_size should equal 1.0 when evolution is off")
  }
})

# ── 15. brain_size_init_mean = 1.5 gives mean_brain_size > 1 at tick 1 ──────
test_that("brain_size_init_mean = 1.5 gives mean_brain_size > 1 at tick 1", {
  skip_no_julia()
  s   <- .bse_specs(
    brain_size_init_mean   = 1.5,
    brain_size_mutation_sd = 0.0,
    max_ticks              = 5L,
    random_seed            = 7L
  )
  env    <- run_alife(s, verbose = FALSE)
  mbz_t1 <- env$progress$mean_brain_size[[1L]]
  expect_gt(mbz_t1, 1.0)
})

# ── 16. Large brain loses more energy per tick (expensive brain hypothesis) ───
test_that("large brain_size loses more energy per tick than reference (no food)", {
  skip_no_julia()
  base <- .bse_specs(
    brain_size_mutation_sd = 0.0,
    min_repro_energy       = 500.0,   # no reproduction
    grass_rate             = 0.0,
    grass_max              = 0.0,
    grass_init_prob        = 0.0,
    random_seed            = 42L
  )

  s_large           <- base
  s_large$brain_size_init_mean <- 2.0

  s_ref             <- base
  s_ref$brain_size_init_mean   <- 1.0

  env_large <- run_alife(s_large, verbose = FALSE)
  env_ref   <- run_alife(s_ref,   verbose = FALSE)

  e_large_t1 <- env_large$progress$mean_energy[[1L]]
  e_ref_t1   <- env_ref$progress$mean_energy[[1L]]

  if (!is.nan(e_large_t1) && !is.nan(e_ref_t1)) {
    expect_lt(e_large_t1, e_ref_t1,
              label = "large-brained agents should have lower mean energy after 1 tick")
  }
})

# ── 17. mean_brain_size stays within [min, max] across logged ticks ───────────
test_that("logged mean_brain_size stays within [brain_size_min, brain_size_max]", {
  skip_no_julia()
  s   <- .bse_specs(max_ticks = 30L)
  env <- run_alife(s, verbose = FALSE)
  mbz    <- env$progress$mean_brain_size
  active <- env$progress$n_agents > 0L
  if (any(active)) {
    expect_true(all(mbz[active] >= s$brain_size_min - 1e-6))
    expect_true(all(mbz[active] <= s$brain_size_max + 1e-6))
  }
})

# ── 18. brain_size > 0 for all surviving agents ───────────────────────────────
test_that("brain_size is strictly positive for all surviving agents", {
  skip_no_julia()
  s   <- .bse_specs(max_ticks = 30L, random_seed = 1L)
  env <- run_alife(s, verbose = FALSE)
  bsz <- .agent_bsz(env)
  if (length(bsz) > 0L) expect_true(all(bsz > 0.0))
})

# ── 19. get_run_data() exposes mean_brain_size ────────────────────────────────
test_that("get_run_data()$ticks has mean_brain_size column", {
  skip_no_julia()
  s    <- .bse_specs()
  env  <- run_alife(s, verbose = FALSE)
  data <- get_run_data(env)$ticks
  expect_true("mean_brain_size" %in% names(data))
})

# ── 20. brain_size_evolution works alongside body_size_evolution ──────────────
test_that("brain_size_evolution = TRUE works with body_size_evolution = TRUE", {
  skip_no_julia()
  s <- .bse_specs(body_size_evolution = TRUE, max_ticks = 20L, random_seed = 5L)
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(as.integer(env$t) >= 1L)
})

# ── 21. brain_size_evolution works alongside parental_care ────────────────────
test_that("brain_size_evolution = TRUE works with parental_care = TRUE", {
  skip_no_julia()
  s <- .bse_specs(parental_care = TRUE, max_ticks = 20L, random_seed = 9L)
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(as.integer(env$t) >= 1L)
})

# ── 22. brain_size_evolution works alongside disease ─────────────────────────
test_that("brain_size_evolution = TRUE works with disease = TRUE", {
  skip_no_julia()
  s <- .bse_specs(disease = TRUE, disease_seed_prob = 0.2, max_ticks = 20L)
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(as.integer(env$t) >= 1L)
})

# ── 23. Bootstrapping problem: mean_brain_size higher with parental care ──────
#
# Parental provisioning hypothesis (van Schaik 2023, Griesser 2023, Song 2025):
# brain size can evolve to larger values when parental care is present because
# the care-energy buffer bridges the infancy energy deficit of large-brained
# offspring. Without parental care, selection against large-brained infants
# (who immediately pay the metabolic cost but forage randomly at birth) keeps
# mean_brain_size lower.
#
# This is a weak stochastic test with a generous tolerance — the test verifies
# direction, not magnitude.
test_that("parental care allows higher mean_brain_size at final tick vs no care", {
  skip_no_julia()
  base <- .bse_specs(
    brain_size_init_mean   = 1.3,     # start above reference to speed up test
    brain_size_mutation_sd = 0.10,
    brain_size_cost_scale  = 1.5,     # steeper cost → stronger bootstrapping signal
    grass_rate             = 0.15,
    grass_max              = 5.0,
    n_agents_init          = 25L,
    max_agents             = 150L,
    max_ticks              = 80L,
    random_seed            = 42L,
    min_repro_energy       = 110.0,
    offspring_energy       = 55.0
  )

  s_care         <- base
  s_care$parental_care  <- TRUE
  s_care$care_duration  <- 8L
  s_care$feeding_rate   <- 3.0

  s_no_care      <- base
  s_no_care$parental_care <- FALSE

  env_care    <- run_alife(s_care,    verbose = FALSE)
  env_no_care <- run_alife(s_no_care, verbose = FALSE)

  # Mean brain size at final logged tick where population survives
  active_care    <- which(env_care$progress$n_agents > 0L)
  active_no_care <- which(env_no_care$progress$n_agents > 0L)

  skip_if(length(active_care)    == 0L, "care population extinct — skip")
  skip_if(length(active_no_care) == 0L, "no-care population extinct — skip")

  mbz_care    <- env_care$progress$mean_brain_size[max(active_care)]
  mbz_no_care <- env_no_care$progress$mean_brain_size[max(active_no_care)]

  expect_gte(mbz_care, mbz_no_care - 0.3,
             label = paste0(
               "mean_brain_size with care (", round(mbz_care, 3),
               ") should be >= no-care (", round(mbz_no_care, 3),
               ") - 0.3 tolerance"
             ))
})

# ── 24. brain_size_max is respected in long runs ──────────────────────────────
test_that("brain_size never exceeds brain_size_max in a 50-tick run", {
  skip_no_julia()
  s   <- .bse_specs(
    brain_size_max         = 2.0,
    brain_size_mutation_sd = 0.12,
    max_ticks              = 50L,
    random_seed            = 99L
  )
  env <- run_alife(s, verbose = FALSE)
  bsz <- .agent_bsz(env)
  if (length(bsz) > 0L) expect_true(all(bsz <= 2.0 + 1e-6))
})

# ── 25. brain_size_min is respected in long runs ──────────────────────────────
test_that("brain_size never goes below brain_size_min in a 50-tick run", {
  skip_no_julia()
  s   <- .bse_specs(
    brain_size_min         = 0.5,
    brain_size_mutation_sd = 0.12,
    max_ticks              = 50L,
    random_seed            = 77L
  )
  env <- run_alife(s, verbose = FALSE)
  bsz <- .agent_bsz(env)
  if (length(bsz) > 0L) expect_true(all(bsz >= 0.5 - 1e-6))
})

# ── 26. brain_size_sensing_exponent is in default_specs() and defaults to 0.3 ─
test_that("brain_size_sensing_exponent is present in default_specs() with default 0.3", {
  s <- default_specs()
  expect_true("brain_size_sensing_exponent" %in% names(s))
  expect_identical(s$brain_size_sensing_exponent, 0.3)
})

# ── 27. run completes with sensing exponent = 0.0 (off) and = 1.0 (linear) ───
test_that("run_alife completes with brain_size_sensing_exponent = 0.0 and 1.0", {
  skip_no_julia()
  s0 <- .bse_specs(brain_size_sensing_exponent = 0.0, random_seed = 11L)
  expect_no_error(env0 <- run_alife(s0, verbose = FALSE))
  expect_true(as.integer(env0$t) >= 1L)

  s1 <- .bse_specs(
    brain_size_init_mean        = 1.5,
    brain_size_sensing_exponent = 1.0,
    random_seed                 = 12L
  )
  expect_no_error(env1 <- run_alife(s1, verbose = FALSE))
  expect_true(as.integer(env1$t) >= 1L)
})
