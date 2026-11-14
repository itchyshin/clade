test_that("saved sensory input is returned in brain order with meaningful names", {
  specs <- default_specs()
  specs$input_radius <- 2L
  specs$sense_mode <- "per_cell"
  specs$n_predators_init <- 1L
  specs$parental_care <- TRUE
  specs$signal_dims <- 2L
  values <- seq_len(31L) / 10
  env <- list(agents = list(list()), specs = specs, sensory_inputs = list(values))
  v <- sense_env(env)
  dirs <- c("N", "E", "S", "W")
  directional <- function(prefix) unlist(lapply(1:2, function(d) paste0(prefix, "_", dirs, "_", d)))
  expect_equal(unname(v), values)
  expect_identical(names(v), c("energy", "age_norm", directional("grass"),
                               directional("agent"), "bias", directional("predator"),
                               "care_load", "offspring_energy", "signal_1", "signal_2"))
  specs$sense_mode <- "weighted_sum"
  values <- seq_len(19L) / 10
  env$specs <- specs
  env$sensory_inputs <- list(values)
  v <- sense_env(env)
  expect_equal(unname(v), values)
  expect_identical(names(v), c("energy", "age_norm", paste0("grass_", dirs),
                               paste0("agent_", dirs), "bias", paste0("predator_", dirs),
                               "care_load", "offspring_energy", "signal_1", "signal_2"))
})

test_that("weighted snapshots cannot be reconstructed from old results", {
  specs <- default_specs(); specs$sense_mode <- "weighted_sum"
  env <- list(agents = list(list(x = 1L, y = 1L, age = 1L, energy = 1)), specs = specs)
  expect_error(sense_env(env), "rerun", ignore.case = TRUE)
})

test_that("result conversion retains the sensory snapshot", {
  specs <- default_specs()
  raw <- list(agents = list(list()), t = 1L, progress = list(t = 1L), deaths = list(),
              sensory_inputs = list(1:11))
  env <- .julia_env_to_r(raw, specs)
  expect_equal(env$sensory_inputs, raw$sensory_inputs)
})

test_that("real final snapshots match each sensing architecture", {
  skip_no_julia()
  for (mode in c("per_cell", "weighted_sum")) {
    specs <- default_specs()
    specs$sense_mode <- mode; specs$input_radius <- 2L
    specs$n_agents_init <- 5L; specs$grid_rows <- 10L; specs$grid_cols <- 10L
    specs$max_ticks <- 1L; specs$random_seed <- 101L
    env <- run_alife(specs, verbose = FALSE)
    expect_gt(length(env$agents), 0L)
    actual <- sense_env(env, 1L)
    expect_length(actual, if (mode == "per_cell") 19L else 11L)
    expect_equal(unname(actual), as.numeric(env$sensory_inputs[[1L]]))
    expect_equal(unname(actual[1]), min(1, env$agents[[1]]$energy / specs$energy_max), tolerance = 1e-6)
  }
})
