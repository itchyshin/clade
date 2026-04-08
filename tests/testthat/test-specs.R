# Tests for default_specs() and .validate_specs() — no Julia required.

library(testthat)

# ── 1. default_specs() returns a named list ───────────────────────────────────
test_that("default_specs() returns a named list", {
  s <- default_specs()
  expect_type(s, "list")
  expect_true(length(names(s)) > 0L)
  expect_true(!anyNA(names(s)))
  expect_true(all(nchar(names(s)) > 0L))
})

# ── 2. All required parameters are present ────────────────────────────────────
test_that("default_specs() contains all required parameters", {
  s <- default_specs()
  required <- c(
    "grid_rows", "grid_cols", "n_agents_init", "max_agents", "max_ticks",
    "energy_init", "energy_max", "move_cost", "idle_cost", "eat_gain",
    "min_repro_energy", "repro_cost", "offspring_energy",
    "grass_init_prob", "grass_rate", "grass_max",
    "brain_type", "hidden_layers",
    "ploidy", "n_chromosomes", "crossover_rate", "dominance_model",
    "mutation_sd",
    "rl_mode", "learning_rate", "learning_rate_evolution",
    "epigenetics", "epigenetic_learning_coupling", "epigenetic_inheritance",
    "epigenetic_effect_size", "methylation_rate", "demethylation_rate",
    "disease", "transmission_prob", "disease_seed_prob",
    "kin_selection", "cooperation_evolution",
    "body_size_evolution", "body_size_min", "body_size_max",
    "body_size_mutation_sd",
    "dispersal_evolution", "dispersal_cost", "dispersal_min", "dispersal_max",
    "dispersal_mutation_sd",
    "metabolic_rate_evolution", "aging_rate_evolution", "immune_evolution",
    "speciation", "isolation_threshold",
    "world_evolution", "world_mutation_sd", "world_params_to_evolve",
    "log_freq", "log_genomes", "random_seed"
  )
  missing_params <- setdiff(required, names(s))
  expect_equal(missing_params, character(0L),
               info = paste("Missing:", paste(missing_params, collapse = ", ")))
})

# ── 3. Default brain_type is "bnn" ────────────────────────────────────────────
test_that("default brain_type is 'bnn'", {
  expect_equal(default_specs()$brain_type, "bnn")
})

# ── 4. Default ploidy is haploid (1L) ─────────────────────────────────────────
test_that("default ploidy is 1 (haploid)", {
  expect_equal(default_specs()$ploidy, 1L)
})

# ── 5. All boolean flags default to FALSE ─────────────────────────────────────
test_that("all boolean module flags default to FALSE", {
  s <- default_specs()
  bool_flags <- c(
    "disease", "kin_selection", "cooperation_evolution", "speciation",
    "niche_construction", "scavenging", "group_defense",
    "habitat_preference_evolution", "parental_care", "mimicry",
    "social_learning", "body_size_evolution", "metabolic_rate_evolution",
    "aging_rate_evolution", "immune_evolution", "dispersal_evolution",
    "epigenetics", "world_evolution", "log_genomes",
    "mutation_rate_evolution", "learning_rate_evolution",
    "life_history_evolution"
  )
  for (nm in bool_flags) {
    expect_false(s[[nm]], info = sprintf("specs$%s should default to FALSE", nm))
  }
})

# ── 6. .validate_specs() passes on default_specs() ────────────────────────────
test_that(".validate_specs() accepts default_specs() without error", {
  expect_silent(clade:::.validate_specs(default_specs()))
})

# ── 7. .validate_specs() rejects invalid brain_type ──────────────────────────
test_that(".validate_specs() rejects unknown brain_type", {
  s <- default_specs()
  s$brain_type <- "skynet"
  expect_error(clade:::.validate_specs(s), regexp = "brain_type")
})

# ── 8. .validate_specs() rejects ploidy other than 1 or 2 ────────────────────
test_that(".validate_specs() rejects ploidy not in {1, 2}", {
  s <- default_specs()
  s$ploidy <- 3L
  expect_error(clade:::.validate_specs(s), regexp = "ploidy")
})

# ── 9. .validate_specs() rejects n_agents_init > max_agents ──────────────────
test_that(".validate_specs() rejects n_agents_init > max_agents", {
  s <- default_specs()
  s$n_agents_init <- 1000L
  s$max_agents    <- 100L
  expect_error(clade:::.validate_specs(s), regexp = "max_agents")
})

# ── 10. .validate_specs() rejects invalid dominance_model ────────────────────
test_that(".validate_specs() rejects invalid dominance_model", {
  s <- default_specs()
  s$dominance_model <- "recessive"
  expect_error(clade:::.validate_specs(s), regexp = "dominance_model")
})

# ── 11. .validate_specs() rejects probability out of [0,1] ───────────────────
test_that(".validate_specs() rejects grass_rate > 1", {
  s <- default_specs()
  s$grass_rate <- 1.5
  expect_error(clade:::.validate_specs(s), regexp = "grass_rate")
})

# ── 12. Modifying specs does not mutate the default ───────────────────────────
test_that("modifying a specs copy does not mutate default_specs()", {
  s <- default_specs()
  s$brain_type <- "ann"
  expect_equal(default_specs()$brain_type, "bnn")
})

# ── 13. crossover_rate = 0 is valid ──────────────────────────────────────────
test_that("crossover_rate = 0 passes validation", {
  s <- default_specs()
  s$crossover_rate <- 0.0
  expect_silent(clade:::.validate_specs(s))
})

# ── 14. crossover_rate = 1 is valid ──────────────────────────────────────────
test_that("crossover_rate = 1 passes validation", {
  s <- default_specs()
  s$crossover_rate <- 1.0
  expect_silent(clade:::.validate_specs(s))
})

# ── 15. world_params_to_evolve defaults to character(0) ──────────────────────
test_that("world_params_to_evolve defaults to character(0)", {
  s <- default_specs()
  expect_equal(s$world_params_to_evolve, character(0L))
})

# ── 16. hidden_layers defaults to c(8L) ──────────────────────────────────────
test_that("hidden_layers defaults to c(8L)", {
  s <- default_specs()
  expect_equal(s$hidden_layers, c(8L))
})

# ── 17. rl_mode defaults to "none" ───────────────────────────────────────────
test_that("rl_mode defaults to 'none'", {
  expect_equal(default_specs()$rl_mode, "none")
})

# ── 18. epigenetic parameters are in (0, 1) ──────────────────────────────────
test_that("epigenetic default parameters are in (0, 1)", {
  s <- default_specs()
  for (nm in c("epigenetic_learning_coupling", "epigenetic_inheritance",
               "epigenetic_effect_size", "methylation_rate",
               "demethylation_rate")) {
    expect_true(s[[nm]] > 0 && s[[nm]] < 1,
                info = sprintf("specs$%s = %g should be in (0, 1)", nm, s[[nm]]))
  }
})

# ── 19. Hamilton's rule holds for default kin selection parameters ─────────────
test_that("default kin_altruism parameters satisfy Hamilton's rule (rB > C)", {
  s <- default_specs()
  # r_min * benefit > cost
  expect_true(s$kin_altruism_r_min * s$kin_altruism_benefit > s$kin_altruism_cost,
              info = sprintf("r=%g, B=%g, C=%g: rB=%g must exceed C=%g",
                             s$kin_altruism_r_min, s$kin_altruism_benefit,
                             s$kin_altruism_cost,
                             s$kin_altruism_r_min * s$kin_altruism_benefit,
                             s$kin_altruism_cost))
})

# ── 20. Cooperation multiplier > 1 (PGG is profitable) ────────────────────────
test_that("default cooperation_multiplier > 1", {
  expect_gt(default_specs()$cooperation_multiplier, 1.0)
})
