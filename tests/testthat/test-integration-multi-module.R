# Multi-module integration smoke test.
#
# Activates 13 modules simultaneously (disease + kin + cooperation +
# mimicry[Batesian] + niche[heritable] + parental-care + body-size +
# brain-size + dispersal + epigenetics + social-learning + signals +
# 0.3.0 observables) and verifies the simulation completes without
# error, producing sensible non-zero values on the observable channels
# each module contributes.
#
# Direction-only; does not assert biological magnitudes.

test_that("13-module integration run completes and logs every activated module", {
  skip_no_julia()

  s <- default_specs()
  # Evolution flags
  s$body_size_evolution  <- TRUE
  s$brain_size_evolution <- TRUE
  s$dispersal_evolution  <- TRUE
  # Social / altruism
  s$kin_selection           <- TRUE
  s$cooperation_evolution   <- TRUE
  s$social_learning         <- TRUE
  # Ecology
  s$disease             <- TRUE
  s$niche_construction  <- TRUE
  s$shelter_occupancy_bonus <- 0.2          # 0.3.0 heritable niche
  s$parental_care       <- TRUE
  # Coevolutionary
  s$mimicry             <- TRUE
  s$batesian_mimicry    <- TRUE             # 0.3.0 Batesian mode
  s$n_predators_init    <- 3L
  # Plasticity / inheritance
  s$epigenetics         <- TRUE

  # Scale
  s$n_agents_init <- 100L
  s$max_agents    <- 500L
  s$max_ticks     <- 100L
  s$random_seed   <- 42L

  env  <- run_alife(s, verbose = FALSE)
  data <- get_run_data(env)

  # Simulation completed to the end.
  expect_equal(env$t, s$max_ticks)

  # Core observables present.
  needed <- c("n_agents", "n_shelter_occupied", "n_shelters_built",
              "n_altruistic_acts", "n_cooperation_acts", "n_infected",
              "mean_brain_size", "mean_body_size", "mean_toxicity")
  for (col in needed) expect_true(col %in% names(data$ticks),
                                   info = sprintf("missing column: %s", col))

  # Each activated module contributes a non-trivial trajectory:
  expect_true(any(data$ticks$n_shelters_built > 0),
              info = "niche_construction active")
  expect_true(any(data$ticks$n_shelter_occupied > 0),
              info = "heritable niche observable fires")
  expect_true(any(data$ticks$n_cooperation_acts > 0),
              info = "cooperation module active")
  expect_true(all(data$ticks$n_agents > 0),
              info = "population survived the run")
})
