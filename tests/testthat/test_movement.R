test_that("Recording is disabled by default", {
  s <- default_specs()
  expect_false(s$log_movement)
  
  env <- run_alife(s)
  expect_error(get_movement_data(env), "No movement data found")
})

test_that("Recording outputs correct frequencies and dimensions", {
  s <- default_specs()
  s$max_ticks <- 10
  s$log_movement <- TRUE
  s$log_movement_freq <- 2L
  s$n_agents_init <- 15
  
  env <- run_alife(s)
  df <- get_movement_data(env)
  
  # Check frequency
  expect_true(all(df$t %% 2 == 0))
  
  # Check expected columns exist
  expect_true(all(c("t", "id", "x", "y", "age", "energy", "alive") %in% colnames(df)))
})

test_that("Recording does not alter deterministic simulation results", {
  s1 <- default_specs()
  s1$random_seed <- 42
  s1$max_ticks <- 20
  
  s2 <- s1
  s2$log_movement <- TRUE
  
  env1 <- run_alife(s1)
  env2 <- run_alife(s2)
  
  # The final agent states and tick counts should be completely identical
  res1 <- get_run_data(env1)
  res2 <- get_run_data(env2)
  
  expect_equal(res1$n_agents, res2$n_agents)
  expect_equal(res1$mean_energy, res2$mean_energy)
})