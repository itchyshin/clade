# test-calibration-harness.R
# Smoke-tests for the expect_evolution() helper itself.

test_that("expect_evolution works for direction='any' with a known column", {
  skip_no_julia()
  sp <- default_specs()
  sp$n_agents_init <- 30L
  sp$max_ticks     <- 60L
  sp$random_seed   <- 1L

  # mean_energy always exists and should be finite
  expect_evolution(sp, trait = "mean_energy", direction = "any", window = 10L)
})

test_that("expect_evolution fails informatively for a missing column", {
  skip_no_julia()
  sp <- default_specs()
  sp$n_agents_init <- 20L
  sp$max_ticks     <- 20L

  expect_error(
    expect_evolution(sp, trait = "nonexistent_column_xyz", direction = "any"),
    regexp = "nonexistent_column_xyz"
  )
})
