# Tests for the analysis helpers in R/analysis.R. These functions are pure R
# and operate on the tidy `run_data` list returned by get_run_data(); no
# Julia session is required, so the tests always run.

library(testthat)

# ── Mock fixtures ────────────────────────────────────────────────────────────

# Matches the layout of the data frame produced by get_run_data()$ticks. The
# trait columns carry mild temporal structure so the lag-1 autocorrelation is
# well defined and non-degenerate.
.mock_ticks <- function(n = 20L) {
  set.seed(42L)
  data.frame(
    t                      = seq_len(n),
    n_agents               = rep(20L, n),
    n_births               = rep(2L,  n),
    n_deaths               = rep(1L,  n),
    n_starvations          = rep(0L,  n),
    n_age_deaths           = rep(0L,  n),
    mean_energy            = 100 + rnorm(n, 0, 5),
    sd_energy              = rep(10, n),
    mean_age               = rep(5, n),
    sd_age                 = rep(2, n),
    mean_body_size         = 1 + cumsum(rnorm(n, 0, 0.01)),
    sd_body_size           = rep(0.1, n),
    genetic_diversity      = seq(0.1, 0.3, length.out = n),
    n_species              = rep(1L, n),
    mean_cooperation_level = rep(0.5, n),
    mean_immune_strength   = rep(0.3, n) + rnorm(n, 0, 0.01),
    sd_immune_strength     = rep(0.05, n),
    mean_metabolic_rate    = rep(1, n),
    mean_learning_rate     = rep(0.01, n),
    mean_prior_sigma       = seq(0.5, 0.1, length.out = n),
    grass_coverage         = rep(0.4, n),
    n_infected             = rep(0L, n),
    n_new_infections       = rep(0L, n),
    n_altruistic_acts      = rep(0L, n),
    n_shelters_built       = rep(0L, n),
    n_cooperation_acts     = rep(0L, n)
  )
}

.mock_rd <- function(n = 20L) {
  list(ticks = .mock_ticks(n), deaths = data.frame())
}

# ── estimate_heritability() ──────────────────────────────────────────────────

# 1. Returns the documented structure with $h2 in [-1, 1]
test_that("estimate_heritability() returns h2 in [-1, 1] for body_size", {
  rd  <- .mock_rd()
  out <- estimate_heritability(rd, trait = "body_size")
  expect_type(out, "list")
  expect_true(all(c("h2", "method", "trait", "n", "note") %in% names(out)))
  expect_equal(out$method, "lag1_autocorrelation")
  expect_equal(out$trait,  "body_size")
  expect_equal(out$n,      nrow(rd$ticks) - 1L)
  expect_true(is.finite(out$h2))
  expect_gte(out$h2, -1)
  expect_lte(out$h2,  1)
})

# 2. Works with another trait column
test_that("estimate_heritability() works for immune_strength", {
  rd  <- .mock_rd()
  out <- estimate_heritability(rd, trait = "immune_strength")
  expect_equal(out$trait, "immune_strength")
  expect_true(is.finite(out$h2))
  expect_gte(out$h2, -1)
  expect_lte(out$h2,  1)
})

# 3. Errors informatively when the trait column is missing
test_that("estimate_heritability() errors on an unknown trait", {
  rd <- .mock_rd()
  expect_error(
    estimate_heritability(rd, trait = "wing_length"),
    regexp = "mean_wing_length"
  )
})

# 4. Errors on bad run_data
test_that("estimate_heritability() errors on a non-list run_data", {
  expect_error(estimate_heritability(42L, "body_size"))
  expect_error(estimate_heritability(list(), "body_size"))
})

# 5. Returns NA when the series has zero variance
test_that("estimate_heritability() returns NA for a flat series", {
  rd <- .mock_rd()
  rd$ticks$mean_body_size <- rep(1.0, nrow(rd$ticks))
  out <- estimate_heritability(rd, trait = "body_size")
  expect_true(is.na(out$h2))
})

# ── compute_ld() ─────────────────────────────────────────────────────────────

# 6. Returns a list with a $note character string and $ld = NULL
test_that("compute_ld() returns a stub with $ld and $note", {
  out <- compute_ld(.mock_rd())
  expect_type(out, "list")
  expect_true(all(c("ld", "note") %in% names(out)))
  expect_null(out$ld)
  expect_type(out$note, "character")
  expect_true(nzchar(out$note))
})

# ── species_tree() ───────────────────────────────────────────────────────────

# 7. Returns a list with a $note character string and $tree = NULL
test_that("species_tree() returns a stub with $tree and $note", {
  out <- species_tree(.mock_rd())
  expect_type(out, "list")
  expect_true(all(c("tree", "note") %in% names(out)))
  expect_null(out$tree)
  expect_type(out$note, "character")
  expect_true(nzchar(out$note))
})

# ── get_genome_data() smoke test on an empty genome_log ──────────────────────

# 8. get_genome_data() does not error on a minimal mock env with empty log
test_that("get_genome_data() handles an empty genome_log gracefully", {
  env <- list(genome_log = list())
  g   <- get_genome_data(env)
  expect_type(g, "list")
  expect_null(g$genomes)
})

# ── Additional tests ──────────────────────────────────────────────────────────

# 9. estimate_heritability() returns a list with named elements
test_that("estimate_heritability() return value has all required named elements", {
  out <- estimate_heritability(.mock_rd(), trait = "body_size")
  expect_true(all(c("h2", "method", "trait", "n", "note") %in% names(out)))
})

# 10. heritability estimate is numeric (finite or NA)
test_that("heritability estimate is numeric (finite or NA)", {
  out <- estimate_heritability(.mock_rd(), trait = "body_size")
  expect_true(is.numeric(out$h2))
})

# 11. compare_conditions() works when given two run_data lists
test_that("compare_conditions() accepts two run_data lists without error", {
  rd1 <- .mock_rd()
  rd2 <- .mock_rd()
  expect_no_error(
    compare_conditions(list(cond_a = rd1, cond_b = rd2), plot = FALSE)
  )
})

# 12. get_genome_data() returns a list with at least $genomes element
test_that("get_genome_data() returns a list with $genomes element", {
  env <- list(genome_log = list())
  g   <- get_genome_data(env)
  expect_true("genomes" %in% names(g))
})

# 13. genetic_diversity values are non-decreasing on a monotone mock series
test_that("genetic_diversity column in mock data changes across ticks", {
  tk <- .mock_ticks(n = 10L)
  # The mock uses seq(0.1, 0.3, ...) so it must have non-zero range.
  expect_gt(diff(range(tk$genetic_diversity)), 0)
})

# 14. estimate_heritability() note is a non-empty character string
test_that("estimate_heritability() note is a non-empty character string", {
  out <- estimate_heritability(.mock_rd(), trait = "body_size")
  expect_type(out$note, "character")
  expect_true(nzchar(out$note))
})

# 15. estimate_heritability() handles single-row ticks (too few for lag-1)
test_that("estimate_heritability() returns NA when ticks has < 3 rows", {
  rd <- .mock_rd(n = 2L)
  out <- estimate_heritability(rd, trait = "body_size")
  expect_true(is.na(out$h2))
})

# ── inspect_brain() and get_brain_weights() ───────────────────────────────────
# These tests require a running Julia session to obtain a real env. When Julia
# is unavailable the tests are skipped gracefully so that CRAN checks still
# pass without a Julia toolchain.

julia_available <- function() {
  requireNamespace("JuliaConnectoR", quietly = TRUE) &&
    JuliaConnectoR::juliaSetupOk()
}

# Mock env with a minimal ANN brain structure (used when Julia is not needed
# to run the sim but the R-level logic can be exercised directly).
.mock_brain_env <- function(brain_type = "ann") {
  W1 <- matrix(rnorm(12), nrow = 4, ncol = 3)
  b1 <- rnorm(4)
  W2 <- matrix(rnorm(8), nrow = 2, ncol = 4)
  b2 <- rnorm(2)
  brain <- list(layers = list(
    list(W = W1, b = b1, mu = W1, sigma = abs(W1) * 0.1),
    list(W = W2, b = b2, mu = W2, sigma = abs(W2) * 0.1)
  ))
  list(
    specs  = list(brain_type = brain_type),
    agents = list(list(id = 1L, brain = brain, energy = 100,
                       age = 0L, x = 1L, y = 1L))
  )
}

# 16. inspect_brain() returns a list (Julia test)
test_that("inspect_brain() returns a list", {
  skip_if_not(julia_available(), "Julia not available")
  env <- .mock_brain_env("ann")
  out <- inspect_brain(env, agent_id = 1L)
  expect_type(out, "list")
})

# 17. inspect_brain() contains brain_type element (Julia test)
test_that("inspect_brain() result contains brain_type element", {
  skip_if_not(julia_available(), "Julia not available")
  env <- .mock_brain_env("ann")
  out <- inspect_brain(env, agent_id = 1L)
  expect_true("brain_type" %in% names(out))
  expect_equal(out$brain_type, "ann")
})

# 18. inspect_brain() contains n_layers >= 1 (Julia test)
test_that("inspect_brain() result has n_layers >= 1", {
  skip_if_not(julia_available(), "Julia not available")
  env <- .mock_brain_env("ann")
  out <- inspect_brain(env, agent_id = 1L)
  expect_true("n_layers" %in% names(out))
  expect_gte(out$n_layers, 1L)
})

# 19. inspect_brain() with non-existent agent_id throws error (Julia test)
test_that("inspect_brain() errors on a non-existent agent_id", {
  skip_if_not(julia_available(), "Julia not available")
  env <- .mock_brain_env("ann")
  expect_error(inspect_brain(env, agent_id = 999L),
               regexp = "No agent with id = 999")
})

# 20. get_brain_weights() returns numeric vector with length > 0 (Julia test)
test_that("get_brain_weights() returns a numeric vector with length > 0", {
  skip_if_not(julia_available(), "Julia not available")
  env <- .mock_brain_env("ann")
  w <- get_brain_weights(env, agent_id = 1L)
  expect_type(w, "double")
  expect_gt(length(w), 0L)
})

# 21. get_brain_weights() with layer=1 returns a matrix (Julia test)
test_that("get_brain_weights() with layer = 1 returns a matrix", {
  skip_if_not(julia_available(), "Julia not available")
  env <- .mock_brain_env("ann")
  W <- get_brain_weights(env, agent_id = 1L, layer = 1L)
  expect_true(is.matrix(W))
})

# ── viability_report() ──────────────────────────────────────────────────────

.mock_ticks_with_pop <- function(n_init, n_final) {
  n <- 20L
  data.frame(
    t        = seq_len(n),
    n_agents = as.integer(round(seq(n_init, n_final, length.out = n)))
  )
}

test_that("viability_report() classifies viable runs", {
  vr <- viability_report(.mock_ticks_with_pop(100L, 90L))
  expect_equal(vr$verdict, "viable")
  expect_equal(vr$n_init, 100L)
  expect_equal(vr$n_final, 90L)
})

test_that("viability_report() classifies weak runs", {
  vr <- viability_report(.mock_ticks_with_pop(100L, 40L))
  expect_equal(vr$verdict, "weak")
})

test_that("viability_report() classifies crashed runs", {
  vr <- viability_report(.mock_ticks_with_pop(100L, 5L))
  expect_equal(vr$verdict, "crashed")
})

test_that("viability_report() respects absolute min_n floor", {
  # 60% of init (viable by fraction) but only 12 agents (below min_n=20)
  ticks <- .mock_ticks_with_pop(20L, 12L)
  expect_equal(viability_report(ticks, min_n = 20L)$verdict, "crashed")
  expect_equal(viability_report(ticks, min_n = 0L)$verdict,  "viable")
})

test_that("viability_report() accepts ticks df OR full get_run_data output", {
  ticks <- .mock_ticks_with_pop(100L, 90L)
  vr1   <- viability_report(ticks)
  vr2   <- viability_report(list(ticks = ticks, deaths = data.frame()))
  expect_equal(vr1$verdict, vr2$verdict)
  expect_equal(vr1$n_final, vr2$n_final)
})

test_that("viability_report() print method runs", {
  vr <- viability_report(.mock_ticks_with_pop(100L, 50L))
  expect_output(print(vr), "viability report")
})
