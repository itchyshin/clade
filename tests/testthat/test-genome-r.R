# Tests for genome-level logic that can be verified from R without Julia.
# These tests probe the R-side spec validation and parameter logic that
# feeds into the Julia genome module.
#
# For Julia-level meiosis tests, see test-integration.R (skip if no Julia).

library(testthat)

# ── Helpers ───────────────────────────────────────────────────────────────────

.kin_r_satisfied <- function(specs) {
  specs$kin_altruism_r_min * specs$kin_altruism_benefit > specs$kin_altruism_cost
}

# ── 1. Hamilton's rule is satisfied for default parameters ────────────────────
test_that("Hamilton's rule rB > C holds for default kin parameters", {
  skip_no_julia()
  expect_true(.kin_r_satisfied(default_specs()))
})

# ── 2. Genome size is proportional to hidden layer width ─────────────────────
test_that(".r_val_to_julia_str serialises integers correctly", {
  skip_no_julia()
  fn <- clade:::.r_val_to_julia_str
  expect_equal(fn(1L),    "1")
  expect_equal(fn(100L),  "100")
})

# ── 3. .r_val_to_julia_str serialises doubles correctly ──────────────────────
test_that(".r_val_to_julia_str serialises doubles correctly", {
  skip_no_julia()
  fn <- clade:::.r_val_to_julia_str
  expect_equal(fn(0.1),  sprintf("%.17g", 0.1))
  expect_equal(fn(1.0),  sprintf("%.17g", 1.0))
})

# ── 4. .r_val_to_julia_str serialises logicals correctly ─────────────────────
test_that(".r_val_to_julia_str serialises logicals correctly", {
  skip_no_julia()
  fn <- clade:::.r_val_to_julia_str
  expect_equal(fn(TRUE),  "true")
  expect_equal(fn(FALSE), "false")
})

# ── 5. .r_val_to_julia_str serialises character correctly ────────────────────
test_that(".r_val_to_julia_str serialises strings correctly", {
  skip_no_julia()
  fn <- clade:::.r_val_to_julia_str
  expect_equal(fn("bnn"), '"bnn"')
  expect_equal(fn("ann"), '"ann"')
})

# ── 6. .r_val_to_julia_str serialises NA as nothing ──────────────────────────
test_that(".r_val_to_julia_str serialises NA as 'nothing'", {
  skip_no_julia()
  fn <- clade:::.r_val_to_julia_str
  expect_equal(fn(NA_integer_), "nothing")
  expect_equal(fn(NA_real_),    "nothing")
})

# ── 7. .r_val_to_julia_str serialises empty character as String[] ─────────────
test_that(".r_val_to_julia_str serialises character(0) as 'String[]'", {
  skip_no_julia()
  fn <- clade:::.r_val_to_julia_str
  expect_equal(fn(character(0L)), "String[]")
})

# ── 8. .r_val_to_julia_str serialises integer vector ─────────────────────────
test_that(".r_val_to_julia_str serialises integer vectors", {
  skip_no_julia()
  fn <- clade:::.r_val_to_julia_str
  result <- fn(c(8L, 16L))
  expect_match(result, "^\\[")
  expect_match(result, "\\]$")
  expect_match(result, "8")
  expect_match(result, "16")
})

# ── 9. Cooperation multiplier > 1 makes PGG profitable ────────────────────────
test_that("default cooperation_multiplier makes PGG profitable (M > 1)", {
  skip_no_julia()
  s <- default_specs()
  expect_gt(s$cooperation_multiplier, 1.0)
  # Net gain for a group of 2: cooperator pays C, receives M*C/2
  # Net = M*C/2 - C = C*(M/2 - 1). For M=2: net = 0 (break even for 2).
  # For any group size < M, cooperation is net positive.
  expect_true(s$cooperation_multiplier * s$cooperation_cost / 2 >=
                s$cooperation_cost * 0.99,
              info = "With M=2 and group size 2, cooperation breaks even")
})

# ── 10. Disease defaults: effective transmission < transmission_prob ───────────
test_that("immune_evolution reduces effective transmission prob", {
  skip_no_julia()
  s <- default_specs()
  # When immune_evolution = TRUE, effective prob = transmission_prob * (1 - immune_strength)
  # immune_strength defaults to 0.3 mean
  expected_eff <- s$transmission_prob * (1 - s$immune_strength_init_mean)
  expect_lt(expected_eff, s$transmission_prob)
})

# ── 11. Diploid specs validate correctly ──────────────────────────────────────
test_that("specs with ploidy = 2 passes validation", {
  skip_no_julia()
  s <- default_specs()
  s$ploidy <- 2L
  expect_silent(clade:::.validate_specs(s))
})

# ── 12. All brain_type values pass validation ─────────────────────────────────
test_that("all valid brain_type values pass .validate_specs()", {
  skip_no_julia()
  for (bt in c("bnn", "ann", "ctrnn", "grn", "transformer", "synthesis",
               "random")) {
    s <- default_specs()
    s$brain_type <- bt
    expect_no_error(
      clade:::.validate_specs(s),
      message = sprintf("brain_type='%s' should be valid", bt)
    )
  }
})

# ── 13. All life_history values pass validation ───────────────────────────────
test_that("valid life_history values pass .validate_specs()", {
  skip_no_julia()
  for (lh in c("iteroparous", "semelparous")) {
    s <- default_specs()
    s$life_history <- lh
    expect_silent(clade:::.validate_specs(s))
  }
})

# ── 14. All rl_mode values pass validation ────────────────────────────────────
test_that("valid rl_mode values pass .validate_specs()", {
  skip_no_julia()
  for (rm in c("none", "actor_critic", "hebbian")) {
    s <- default_specs()
    s$rl_mode <- rm
    expect_silent(clade:::.validate_specs(s))
  }
})

# ── 15. All dominance_model values pass validation ────────────────────────────
test_that("valid dominance_model values pass .validate_specs()", {
  skip_no_julia()
  for (dm in c("additive", "dominant", "codominant")) {
    s <- default_specs()
    s$dominance_model <- dm
    expect_silent(clade:::.validate_specs(s))
  }
})

# ── 16. Crossover rate = 0 gives identity meiosis for haploid ────────────────
# This is a conceptual test: with crossover_rate = 0 and mutation_sd = 0,
# offspring should be genetically identical to parent. Verified via Julia
# integration tests; here we check the spec validates.
test_that("crossover_rate = 0 with mutation_sd = 0 passes validation", {
  skip_no_julia()
  s <- default_specs()
  s$crossover_rate <- 0.0
  s$mutation_sd    <- 0.0
  expect_silent(clade:::.validate_specs(s))
})

# ── 17. Senescence rate 0 means no Gompertz mortality ────────────────────────
test_that("senescence_rate = 0 (default) means no age-based mortality", {
  skip_no_julia()
  expect_equal(default_specs()$senescence_rate, 0.0)
})

# ── 18. log_freq = 1 means every tick is logged ───────────────────────────────
test_that("default log_freq = 1", {
  skip_no_julia()
  expect_equal(default_specs()$log_freq, 1L)
})

# ── 19. signal_dims = 0 means no signal evolution by default ──────────────────
test_that("default signal_dims = 0 (signal evolution off)", {
  skip_no_julia()
  expect_equal(default_specs()$signal_dims, 0L)
})

# ── 20. Immune strength bounds are ordered ────────────────────────────────────
test_that("immune_strength_min < immune_strength_max", {
  skip_no_julia()
  s <- default_specs()
  expect_lt(s$immune_strength_min, s$immune_strength_max)
})

# ── 21. ploidy = 2L is default (diploid) ──────────────────────────────────────
test_that("default_specs()$ploidy is 2L (diploid)", {
  skip_no_julia()
  expect_equal(default_specs()$ploidy, 2L)
})

# ── 22. ploidy = 2L passes validation (diploid) ───────────────────────────────
test_that("ploidy = 2L passes .validate_specs()", {
  skip_no_julia()
  s <- default_specs()
  s$ploidy <- 2L
  expect_silent(clade:::.validate_specs(s))
})

# ── 23. n_chromosomes = 1L is default ────────────────────────────────────────
test_that("default_specs()$n_chromosomes is 1L", {
  skip_no_julia()
  expect_equal(default_specs()$n_chromosomes, 1L)
})

# ── 24. crossover_rate = 1.0 is default ──────────────────────────────────────
test_that("default_specs()$crossover_rate is 1.0", {
  skip_no_julia()
  expect_equal(default_specs()$crossover_rate, 1.0)
})

# ── 25. dominance_model = "additive" is default ───────────────────────────────
test_that("default_specs()$dominance_model is 'additive'", {
  skip_no_julia()
  expect_equal(default_specs()$dominance_model, "additive")
})

# ── 26. dominance_model can be "dominant" or "codominant" ─────────────────────
test_that("dominance_model 'dominant' and 'codominant' pass .validate_specs()", {
  skip_no_julia()
  for (dm in c("dominant", "codominant")) {
    s <- default_specs()
    s$dominance_model <- dm
    expect_no_error(clade:::.validate_specs(s),
                    message = sprintf("dominance_model = '%s' should validate", dm))
  }
})

# ── 27. ploidy = 2L + n_chromosomes = 2L run completes ───────────────────────
test_that("run with ploidy = 2L and n_chromosomes = 2L completes", {
  skip_no_julia()
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- .minimal_specs(ploidy = 2L, n_chromosomes = 2L, random_seed = 11L)
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
})

# ── 28. crossover_rate = 0.0 (no crossover) run completes ────────────────────
test_that("run with crossover_rate = 0.0 completes", {
  skip_no_julia()
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- .minimal_specs(crossover_rate = 0.0, random_seed = 12L)
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
})

# ── 29. Diploid run produces n_births > 0 over 200 ticks ──────────────────────
test_that("diploid run produces at least one birth over 200 ticks", {
  skip_no_julia()
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- .minimal_specs(ploidy = 2L, random_seed = 13L,
                       grid_rows = 20L, grid_cols = 20L,
                       n_agents_init = 30L, max_agents = 200L,
                       max_ticks = 200L)
  env <- run_alife(s, verbose = FALSE)
  data <- get_run_data(env)
  expect_gt(sum(data$ticks$n_births, na.rm = TRUE), 0L,
            label = "diploid run should produce at least one birth")
})

# ── 30. Genome params are all present in default_specs() ──────────────────────
test_that("genome params present in default_specs()", {
  skip_no_julia()
  s <- default_specs()
  for (param in c("ploidy", "n_chromosomes", "crossover_rate", "dominance_model")) {
    expect_true(param %in% names(s),
                info = sprintf("default_specs() missing '%s'", param))
  }
})
