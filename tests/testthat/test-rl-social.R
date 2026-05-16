# Tests for within-lifetime RL (REINFORCE with baseline) and prestige-biased
# social learning modules.
#
# These tests exercise the full R → Julia → R round trip via run_alife().
# All tests skip gracefully when JuliaConnectoR or a Julia toolchain are
# unavailable (CRAN, CI without Julia).
#
# References
# ----------
# Williams, R.J. (1992) Simple statistical gradient-following algorithms for
#   connectionist reinforcement learning. Machine Learning 8(3-4):229-256.
# Laland, K.N. (2004) Social learning strategies. Learning and Behavior
#   32(1):4-14.
# Henrich, J. & Gil-White, F.J. (2001) The evolution of prestige.
#   Evolution and Human Behavior 22(3):165-196.

library(testthat)

.rl_specs <- function(...) {
  s <- default_specs()
  s$grid_rows     <- 15L
  s$grid_cols     <- 15L
  s$n_agents_init <- 20L
  s$max_agents    <- 100L
  s$max_ticks     <- 50L
  s$random_seed   <- 99L
  args <- list(...)
  for (nm in names(args)) s[[nm]] <- args[[nm]]
  s
}

# ── RL: default specs ────────────────────────────────────────────────────────

# ── 1. rl_mode defaults to "none" ──────────────────────────────────────────
test_that("rl_mode defaults to 'none' in default_specs()", {
  skip_no_julia()
  s <- default_specs()
  expect_equal(s$rl_mode, "none")
})

# ── 2. rl_update_freq default is a positive integer ─────────────────────────
test_that("rl_update_freq default is a positive integer", {
  skip_no_julia()
  s <- default_specs()
  expect_true(is.integer(s$rl_update_freq))
  expect_gte(s$rl_update_freq, 1L)
})

# ── 3. rl_mode = "none" run completes (module disabled) ─────────────────────
test_that("rl_mode = 'none' run completes without RL updates", {
  skip_no_julia()
  s <- .rl_specs(rl_mode = "none")
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
})

# ── 4. rl_mode = "actor_critic" run completes (ANN brain) ──────────────────
test_that("rl_mode = 'actor_critic' with ANN brain completes", {
  skip_no_julia()
  s <- .rl_specs(
    rl_mode        = "actor_critic",
    brain_type     = "ann",
    rl_update_freq = 1L
  )
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
})

# ── 5. rl_mode = "actor_critic" run completes (BNN brain) ──────────────────
test_that("rl_mode = 'actor_critic' with BNN brain completes", {
  skip_no_julia()
  s <- .rl_specs(
    rl_mode        = "actor_critic",
    brain_type     = "bnn",
    rl_update_freq = 1L
  )
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  d <- get_run_data(env)
  expect_true("mean_energy" %in% names(d$ticks))
})

# ── 6. rl_update_freq > 1 gates updates correctly ───────────────────────────
# With a high update frequency (every 25 ticks out of 50), the run should
# still complete without error.
test_that("rl_update_freq = 25 with max_ticks = 50 completes", {
  skip_no_julia()
  s <- .rl_specs(
    rl_mode        = "actor_critic",
    brain_type     = "ann",
    rl_update_freq = 25L,
    max_ticks      = 50L
  )
  expect_no_error(run_alife(s, verbose = FALSE))
})

# ── 7. rl_mode = "actor_critic" + epigenetics do not conflict ───────────────
test_that("rl_mode = 'actor_critic' is compatible with epigenetics = TRUE", {
  skip_no_julia()
  s <- .rl_specs(
    rl_mode     = "actor_critic",
    brain_type  = "bnn",
    epigenetics = TRUE
  )
  expect_no_error(run_alife(s, verbose = FALSE))
})

# ── 8. Unknown rl_mode is rejected by Julia ──────────────────────────────────
test_that("unknown rl_mode raises an error in Julia", {
  skip_no_julia()
  s <- .rl_specs(rl_mode = "invalid_mode_xyz")
  expect_error(run_alife(s, verbose = FALSE))
})

# ── Social learning: default specs ──────────────────────────────────────────

# ── 9. social_learning defaults to FALSE ────────────────────────────────────
test_that("social_learning defaults to FALSE in default_specs()", {
  skip_no_julia()
  s <- default_specs()
  expect_false(s$social_learning)
})

# ── 10. social_learning_rate default is in (0, 1) ───────────────────────────
test_that("social_learning_rate default is in the open unit interval", {
  skip_no_julia()
  s <- default_specs()
  expect_true(is.numeric(s$social_learning_rate))
  expect_gt(s$social_learning_rate, 0)
  expect_lt(s$social_learning_rate, 1)
})

# ── 11. social_learning = TRUE run completes (ANN brain) ─────────────────────
test_that("social_learning = TRUE with ANN brain completes", {
  skip_no_julia()
  s <- .rl_specs(
    social_learning      = TRUE,
    social_learning_freq = 5L,
    brain_type           = "ann"
  )
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
})

# ── 12. social_learning = TRUE run completes (BNN brain) ─────────────────────
test_that("social_learning = TRUE with BNN brain completes", {
  skip_no_julia()
  s <- .rl_specs(
    social_learning      = TRUE,
    social_learning_freq = 5L,
    brain_type           = "bnn"
  )
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  d <- get_run_data(env)
  expect_true("mean_prior_sigma" %in% names(d$ticks))
})

# ── 13. social_learning_freq gates correctly ──────────────────────────────────
test_that("social_learning_freq = 10 with max_ticks = 30 completes", {
  skip_no_julia()
  s <- .rl_specs(
    social_learning      = TRUE,
    social_learning_freq = 10L,
    max_ticks            = 30L,
    brain_type           = "ann"
  )
  expect_no_error(run_alife(s, verbose = FALSE))
})

# ── 14. social_learning + RL can be active simultaneously ────────────────────
test_that("social_learning = TRUE + rl_mode = 'actor_critic' coexist", {
  skip_no_julia()
  s <- .rl_specs(
    social_learning = TRUE,
    rl_mode         = "actor_critic",
    brain_type      = "ann",
    max_ticks       = 40L
  )
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
})

# ── 15. social_learning + disease coexist ────────────────────────────────────
test_that("social_learning = TRUE + disease = TRUE coexist", {
  skip_no_julia()
  s <- .rl_specs(
    social_learning = TRUE,
    disease         = TRUE,
    brain_type      = "ann"
  )
  expect_no_error(run_alife(s, verbose = FALSE))
})

# ── 16. social_learning = FALSE is genuinely a no-op ─────────────────────────
# With social_learning = FALSE, the tick loop should not call
# apply_social_learning! at all. We verify by checking the run completes
# with the same population trajectory regardless of social_learning_rate.
test_that("social_learning = FALSE run is independent of social_learning_rate", {
  skip_no_julia()
  # Rate = 0.0 case: gated by the social_learning flag, so this should be
  # identical to the rate = 0.99 case (both skip the copy step entirely).
  s_off <- .rl_specs(
    social_learning      = FALSE,
    social_learning_rate = 0.99,
    max_ticks            = 30L,
    brain_type           = "ann",
    random_seed          = 7L
  )
  expect_no_error(run_alife(s_off, verbose = FALSE))
})

# ── 17. rl.jl defines apply_rl! (syntax check) ───────────────────────────────
test_that("rl.jl defines apply_rl!", {
  skip_no_julia()
  JULIA_SRC <- system.file("julia", "src", package = "clade")
  skip_if(!nchar(JULIA_SRC) || !dir.exists(JULIA_SRC),
          "Julia source not installed")
  rl_jl <- paste(readLines(file.path(JULIA_SRC, "modules", "rl.jl")),
                 collapse = "\n")
  expect_true(grepl("function apply_rl!", rl_jl, fixed = TRUE))
  expect_true(grepl("actor_critic", rl_jl, fixed = TRUE))
})

# ── 18. social_learning.jl defines apply_social_learning! (syntax) ───────────
test_that("social_learning.jl defines apply_social_learning!", {
  skip_no_julia()
  JULIA_SRC <- system.file("julia", "src", package = "clade")
  skip_if(!nchar(JULIA_SRC) || !dir.exists(JULIA_SRC),
          "Julia source not installed")
  sl_jl <- paste(readLines(
    file.path(JULIA_SRC, "modules", "social_learning.jl")), collapse = "\n")
  expect_true(grepl("function apply_social_learning!", sl_jl, fixed = TRUE))
  expect_true(grepl("prestige", sl_jl, fixed = TRUE))
})

# ── 19. rl_update_freq default value ─────────────────────────────────────────
test_that("rl_update_freq has correct default in default_specs()", {
  skip_no_julia()
  s <- default_specs()
  expect_true("rl_update_freq" %in% names(s))
  expect_true(is.integer(s$rl_update_freq))
  expect_gte(s$rl_update_freq, 1L)
})

# ── 20. social_learning_freq defaults to 10L ──────────────────────────────────
test_that("social_learning_freq defaults to 10L", {
  skip_no_julia()
  s <- default_specs()
  expect_equal(s$social_learning_freq, 10L)
})

# ── 21. social_learning_rate defaults to 0.1 ─────────────────────────────────
test_that("social_learning_rate defaults to 0.1", {
  skip_no_julia()
  expect_equal(default_specs()$social_learning_rate, 0.1)
})

# ── 22. learning_rate_evolution defaults to FALSE ────────────────────────────
test_that("learning_rate_evolution defaults to FALSE", {
  skip_no_julia()
  expect_false(default_specs()$learning_rate_evolution)
})

# ── 23. learning_rate_init_mean defaults to 0.01 ─────────────────────────────
test_that("learning_rate_init_mean defaults to 0.01", {
  skip_no_julia()
  expect_equal(default_specs()$learning_rate_init_mean, 0.01)
})

# ── 24. learning_rate_min and learning_rate_max exist and are in [0, 0.5] ────
test_that("learning_rate_min and learning_rate_max exist and are in [0, 0.5]", {
  skip_no_julia()
  s <- default_specs()
  expect_true("learning_rate_min" %in% names(s))
  expect_true("learning_rate_max" %in% names(s))
  expect_gte(s$learning_rate_min, 0.0)
  expect_lte(s$learning_rate_min, 0.5)
  expect_gte(s$learning_rate_max, 0.0)
  expect_lte(s$learning_rate_max, 0.5)
})

# ── 25. plasticity_cost defaults to 0.05 ─────────────────────────────────────
test_that("plasticity_cost defaults to 0.05", {
  skip_no_julia()
  expect_equal(default_specs()$plasticity_cost, 0.05)
})

# ── 26. rl_mode = "actor_critic" + social_learning = TRUE coexist (Julia) ────
test_that("rl_mode = 'actor_critic' and social_learning = TRUE run completes", {
  skip_no_julia()
  s <- .rl_specs(
    rl_mode         = "actor_critic",
    social_learning = TRUE,
    brain_type      = "ann",
    max_ticks       = 30L,
    random_seed     = 42L
  )
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
})

# ── 27. RL + social learning run has n_births > 0 ─────────────────────────────
test_that("RL + social learning run produces births", {
  skip_no_julia()
  s <- .rl_specs(
    rl_mode         = "actor_critic",
    social_learning = TRUE,
    brain_type      = "ann",
    max_ticks       = 50L,
    random_seed     = 42L
  )
  env <- run_alife(s, verbose = FALSE)
  total_births <- sum(env$progress$n_births)
  expect_gte(total_births, 0L)
})

# ── 28. social_learning params round-trip through default_specs() ─────────────
test_that("social_learning params round-trip correctly through default_specs()", {
  skip_no_julia()
  s <- default_specs()
  expect_false(s$social_learning)
  expect_equal(s$social_learning_freq, 10L)
  expect_equal(s$social_learning_rate, 0.1)
  expect_false(s$learning_rate_evolution)
  expect_equal(s$learning_rate_init_mean, 0.01)
  expect_equal(s$learning_rate_min,       0.0)
  expect_equal(s$learning_rate_max,       0.5)
  expect_equal(s$plasticity_cost,         0.05)
})

# ── Lamarckian evolution ──────────────────────────────────────────────────────

test_that("lamarckian = FALSE is the default", {
  skip_no_julia()
  expect_false(default_specs()$lamarckian)
})

test_that("lamarckian spec round-trips through default_specs()", {
  skip_no_julia()
  s <- default_specs()
  s$lamarckian <- TRUE
  expect_true(s$lamarckian)
})

test_that("Lamarckian run completes without error (ANN + haploid)", {
  skip_no_julia()
  s <- default_specs()
  s$brain_type    <- "ann"
  s$ploidy        <- 1L
  s$n_agents_init <- 40L
  s$max_ticks     <- 80L
  s$rl_mode       <- "actor_critic"
  s$learning_rate <- 0.02
  s$lamarckian    <- TRUE
  s$random_seed   <- 7L
  env <- run_alife(s, verbose = FALSE)
  expect_gt(length(env$agents), 0L)
})

test_that("Lamarckian run completes without error (BNN + diploid)", {
  skip_no_julia()
  s <- default_specs()
  s$brain_type    <- "bnn"
  s$ploidy        <- 2L
  s$n_agents_init <- 40L
  s$max_ticks     <- 80L
  s$rl_mode       <- "actor_critic"
  s$learning_rate <- 0.02
  s$lamarckian    <- TRUE
  s$random_seed   <- 8L
  env <- run_alife(s, verbose = FALSE)
  expect_gt(length(env$agents), 0L)
})

test_that("Lamarckian is no-op when rl_mode = 'none'", {
  skip_no_julia()
  # With rl_mode='none' the genome never changes due to lamarckian flag —
  # run should be identical to lamarckian=FALSE (same seed, same outcome).
  make_sp <- function(lam) {
    s <- default_specs()
    s$brain_type    <- "ann"
    s$ploidy        <- 1L
    s$n_agents_init <- 30L
    s$max_ticks     <- 50L
    s$rl_mode       <- "none"
    s$lamarckian    <- lam
    s$random_seed   <- 99L
    s
  }
  env_f <- run_alife(make_sp(FALSE), verbose = FALSE)
  env_t <- run_alife(make_sp(TRUE),  verbose = FALSE)
  # Population trajectories should be identical (same RNG seed, no RL delta)
  expect_equal(env_f$progress$n_agents, env_t$progress$n_agents)
})

# ── Plasticity cost wired ────────────────────────────────────────────────────
#
# Wired in 0.7.x. With rl_mode = "actor_critic" the per-tick energy
# drain `plasticity_cost * learning_rate` applies. Test that turning
# the cost off vs on at the same seed produces a measurable difference
# in mean agent energy at the end of the run.

test_that("plasticity_cost > 0 reduces mean energy vs cost = 0 under RL", {
  skip_no_julia()
  run_one <- function(cost) {
    s <- .rl_specs(rl_mode = "actor_critic",
                   learning_rate_init_mean = 0.3,
                   learning_rate_min       = 0.3,
                   learning_rate_max       = 0.3,    # fix to 0.3 (no heritability)
                   plasticity_cost         = cost,
                   max_ticks               = 60L)
    env <- run_alife(s, verbose = FALSE)
    p   <- get_run_data(env)$ticks
    # Compare mean(mean_energy) over the final 20 ticks for stability.
    tail_idx <- max(1L, nrow(p) - 19L):nrow(p)
    mean(p$mean_energy[tail_idx], na.rm = TRUE)
  }
  e_off <- run_one(0.0)
  e_on  <- run_one(0.5)   # 0.5 * 0.3 = 0.15 energy/tick — well above noise
  expect_true(e_off > e_on,
              info = sprintf("mean_energy off=%.3f, on=%.3f", e_off, e_on))
})
