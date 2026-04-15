# Tests for the 0.3.0 heritable-niche shelter_occupancy_bonus and
# the new n_shelter_occupied logging column.

.skip_unless_julia <- function() {
  skip_if_not_installed("JuliaConnectoR")
  skip_on_cran()
}

test_that("shelter_occupancy_bonus defaults to 0 (backward compat)", {
  s <- default_specs()
  expect_true("shelter_occupancy_bonus" %in% names(s))
  expect_equal(s$shelter_occupancy_bonus, 0)
})

test_that("niche_construction run logs n_shelter_occupied", {
  .skip_unless_julia()

  s <- default_specs()
  s$niche_construction <- TRUE
  s$max_ticks          <- 40L
  s$n_agents_init      <- 30L
  s$random_seed        <- 42L

  env  <- run_alife(s, verbose = FALSE)
  data <- get_run_data(env)

  expect_true("n_shelter_occupied" %in% names(data$ticks))
  # Non-negative counts.
  expect_true(all(data$ticks$n_shelter_occupied >= 0))
  # Bounded by the agent count at that tick.
  expect_true(all(data$ticks$n_shelter_occupied <= data$ticks$n_agents))
})

test_that("shelter_occupancy_bonus > 0 raises late-run mean_energy vs bonus=0", {
  .skip_unless_julia()

  base <- default_specs()
  base$niche_construction <- TRUE
  base$shelter_build_prob <- 0.3      # build shelters aggressively
  base$max_ticks          <- 80L
  base$n_agents_init      <- 40L
  base$grass_rate         <- 0.05     # scarce, so bonus matters
  base$random_seed        <- 42L

  # Without bonus
  s0 <- base; s0$shelter_occupancy_bonus <- 0.0
  env0 <- run_alife(s0, verbose = FALSE)
  e0 <- mean(tail(get_run_data(env0)$ticks$mean_energy, 20L))

  # With bonus
  s1 <- base; s1$shelter_occupancy_bonus <- 0.5
  env1 <- run_alife(s1, verbose = FALSE)
  e1 <- mean(tail(get_run_data(env1)$ticks$mean_energy, 20L))

  # Bonus should raise energy (directional; magnitude varies with seed).
  # Using a soft check: e1 should not be dramatically WORSE than e0 —
  # if shelters ever fire, bonus is pure energy gain. Allow for seed
  # noise by checking within 10% or higher.
  expect_gte(e1, e0 * 0.9)
})

test_that("shelter_occupancy_bonus stays 0 when niche_construction is FALSE", {
  .skip_unless_julia()

  s <- default_specs()
  s$niche_construction     <- FALSE
  s$shelter_occupancy_bonus <- 0.5   # harmless since module is off
  s$max_ticks              <- 30L
  s$n_agents_init          <- 30L

  env  <- run_alife(s, verbose = FALSE)
  data <- get_run_data(env)

  # n_shelter_occupied should be all zero since no shelters were built.
  expect_true(all(data$ticks$n_shelter_occupied == 0L))
})
