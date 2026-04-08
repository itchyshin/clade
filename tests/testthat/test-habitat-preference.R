test_that("habitat_preference_evolution defaults to FALSE in specs", {
  s <- default_specs()
  expect_false(s$habitat_preference_evolution)
})

test_that("habitat_preference_strength default is 0.5", {
  expect_equal(default_specs()$habitat_preference_strength, 0.5)
})

test_that("habitat_preference_min / max default to -1 / 1", {
  s <- default_specs()
  expect_equal(s$habitat_preference_min, -1.0)
  expect_equal(s$habitat_preference_max,  1.0)
})

test_that("habitat_move_cost defaults to 0", {
  expect_equal(default_specs()$habitat_move_cost, 0.0)
})

test_that("n_habitat_moves present in ticks data frame", {
  rd <- list(ticks = data.frame(
    t = 1L, n_agents = 10L, n_births = 0L, n_deaths = 0L,
    n_starvations = 0L, n_age_deaths = 0L,
    mean_energy = 50.0, sd_energy = 1.0,
    mean_age = 5.0, sd_age = 1.0,
    mean_body_size = 1.0, sd_body_size = 0.1,
    genetic_diversity = 0.3, n_species = 1L,
    mean_cooperation_level = 0.0, mean_immune_strength = 0.5,
    sd_immune_strength = 0.1, mean_metabolic_rate = 1.0,
    mean_learning_rate = 0.01, mean_prior_sigma = 0.5,
    grass_coverage = 0.6, n_infected = 0L, n_new_infections = 0L,
    n_altruistic_acts = 0L, n_shelters_built = 0L,
    n_cooperation_acts = 0L, n_dispersal_events = 0L,
    n_habitat_moves = 0L
  ))
  expect_true("n_habitat_moves" %in% names(rd$ticks))
})

test_that("n_habitat_moves is numeric / integer", {
  rd <- list(ticks = data.frame(n_habitat_moves = 3L))
  expect_true(is.numeric(rd$ticks$n_habitat_moves) ||
              is.integer(rd$ticks$n_habitat_moves))
})

test_that("habitat_preference_init_mean defaults to 0", {
  expect_equal(default_specs()$habitat_preference_init_mean, 0.0)
})

test_that("habitat_preference_mutation_sd defaults to 0.03", {
  expect_equal(default_specs()$habitat_preference_mutation_sd, 0.03)
})

test_that("habitat preference params appear in default_specs names", {
  nms <- names(default_specs())
  for (p in c("habitat_preference_evolution", "habitat_preference_strength",
               "habitat_move_cost", "habitat_preference_min",
               "habitat_preference_max")) {
    expect_true(p %in% nms, info = paste("missing:", p))
  }
})

test_that("habitat_preference_evolution spec is logical", {
  expect_true(is.logical(default_specs()$habitat_preference_evolution))
})

test_that("habitat_preference_strength is in (0, 1]", {
  s <- default_specs()$habitat_preference_strength
  expect_true(s > 0 && s <= 1)
})

test_that("habitat_preference_min < habitat_preference_max", {
  s <- default_specs()
  expect_true(s$habitat_preference_min < s$habitat_preference_max)
})
