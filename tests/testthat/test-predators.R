test_that("n_predators_init defaults to 0L", {
  expect_equal(default_specs()$n_predators_init, 0L)
})

test_that("predator_energy_init defaults to 150.0", {
  expect_equal(default_specs()$predator_energy_init, 150.0)
})

test_that("predator_live_energy defaults to 2.0", {
  expect_equal(default_specs()$predator_live_energy, 2.0)
})

test_that("predator_attack_strength defaults to 40.0", {
  expect_equal(default_specs()$predator_attack_strength, 40.0)
})

test_that("predator_energy_gain defaults to 30.0", {
  expect_equal(default_specs()$predator_energy_gain, 30.0)
})

test_that("predator_min_repro_energy defaults to 200.0", {
  expect_equal(default_specs()$predator_min_repro_energy, 200.0)
})

test_that("predator_min_repro_age defaults to 5L", {
  expect_equal(default_specs()$predator_min_repro_age, 5L)
})

test_that("predator_mutation_sd defaults to 0.1", {
  expect_equal(default_specs()$predator_mutation_sd, 0.1)
})

test_that("predator_max_agents defaults to 50L", {
  expect_equal(default_specs()$predator_max_agents, 50L)
})

test_that("all predator params are present in default_specs", {
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
  v <- default_specs()$n_predators_init
  expect_true(is.integer(v) || (is.numeric(v) && v == as.integer(v)))
})

test_that("predator_attack_strength is positive", {
  expect_true(default_specs()$predator_attack_strength > 0)
})

test_that("predator_energy_gain is positive and within plausible energy-balance bound", {
  s <- default_specs()
  expect_true(s$predator_energy_gain > 0)
  expect_true(s$predator_energy_gain <= s$predator_attack_strength * 2)
})

test_that("predator_min_repro_energy exceeds predator_energy_init", {
  s <- default_specs()
  expect_true(s$predator_min_repro_energy > s$predator_energy_init)
})

test_that("dilution factor formula is less than 1 when predators are present", {
  attack_strength <- default_specs()$predator_attack_strength
  n_agents        <- 5
  factor          <- 1.0 / (1.0 + n_agents * attack_strength)
  expect_true(factor < 1.0)
  expect_true(factor > 0.0)
})
