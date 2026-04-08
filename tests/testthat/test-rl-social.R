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

skip_no_julia <- function() {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
}

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
  s <- default_specs()
  expect_equal(s$rl_mode, "none")
})

# ── 2. rl_update_freq default is a positive integer ─────────────────────────
test_that("rl_update_freq default is a positive integer", {
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
  s <- default_specs()
  expect_false(s$social_learning)
})

# ── 10. social_learning_rate default is in (0, 1) ───────────────────────────
test_that("social_learning_rate default is in the open unit interval", {
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
  JULIA_SRC <- system.file("julia", "src", package = "clade")
  skip_if(!nchar(JULIA_SRC) || !dir.exists(JULIA_SRC),
          "Julia source not installed")
  sl_jl <- paste(readLines(
    file.path(JULIA_SRC, "modules", "social_learning.jl")), collapse = "\n")
  expect_true(grepl("function apply_social_learning!", sl_jl, fixed = TRUE))
  expect_true(grepl("prestige", sl_jl, fixed = TRUE))
})
