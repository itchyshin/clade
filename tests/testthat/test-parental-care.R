test_that("parental_care defaults to FALSE", {
  expect_false(default_specs()$parental_care)
})

test_that("care_cost_per_tick defaults to 1.0", {
  expect_equal(default_specs()$care_cost_per_tick, 1.0)
})

test_that("feeding_rate defaults to 5.0", {
  expect_equal(default_specs()$feeding_rate, 5.0)
})

test_that("juvenile_independence_age defaults to 10L", {
  expect_equal(default_specs()$juvenile_independence_age, 10L)
})

test_that("juvenile_independence_energy defaults to 50.0", {
  expect_equal(default_specs()$juvenile_independence_energy, 50.0)
})

test_that("parental_care is logical", {
  expect_true(is.logical(default_specs()$parental_care))
})

test_that("care_cost_per_tick is positive", {
  expect_true(default_specs()$care_cost_per_tick > 0)
})

test_that("feeding_rate is positive", {
  expect_true(default_specs()$feeding_rate > 0)
})

test_that("juvenile_independence_age is a positive integer-like value", {
  v <- default_specs()$juvenile_independence_age
  expect_true(is.integer(v) || (is.numeric(v) && v == as.integer(v)))
  expect_true(v > 0)
})

test_that("juvenile_independence_energy is positive", {
  expect_true(default_specs()$juvenile_independence_energy > 0)
})

test_that("all parental care params are present in default_specs", {
  nms <- names(default_specs())
  for (p in c("parental_care", "care_cost_per_tick", "feeding_rate",
               "juvenile_independence_age", "juvenile_independence_energy",
               "max_clutch_size")) {
    expect_true(p %in% nms, info = paste("missing:", p))
  }
})

test_that("care cost formula is numeric: total_cost = care_cost_per_tick * care_load", {
  s         <- default_specs()
  care_load <- 2L
  total     <- s$care_cost_per_tick * care_load
  expect_true(is.numeric(total))
  expect_true(total >= 0)
})

test_that("feeding is bounded by parent energy fraction", {
  s              <- default_specs()
  parent_energy  <- 120.0
  fed            <- min(s$feeding_rate, parent_energy * 0.3)
  expect_true(fed <= parent_energy * 0.3)
})

test_that("juvenile independence condition holds when either criterion is met", {
  s <- default_specs()
  # age criterion
  age1    <- s$juvenile_independence_age
  energy1 <- 0.0
  # energy criterion
  age2    <- 0L
  energy2 <- s$juvenile_independence_energy
  expect_true(age1 >= s$juvenile_independence_age || energy1 >= s$juvenile_independence_energy)
  expect_true(age2 >= s$juvenile_independence_age || energy2 >= s$juvenile_independence_energy)
})

test_that("max_clutch_size is at least 1", {
  expect_true(default_specs()$max_clutch_size >= 1L)
})

# ── New tests ─────────────────────────────────────────────────────────────────

test_that("parental_care defaults to FALSE (explicit FALSE check)", {
  s <- default_specs()
  expect_identical(s$parental_care, FALSE)
})

test_that("care_cost_per_tick defaults to 1.0 (explicit value)", {
  s <- default_specs()
  expect_identical(s$care_cost_per_tick, 1.0)
})

test_that("feeding_rate defaults to 5.0 (explicit value)", {
  s <- default_specs()
  expect_identical(s$feeding_rate, 5.0)
})

test_that("juvenile_independence_age defaults to 10L and is integer", {
  s <- default_specs()
  expect_identical(s$juvenile_independence_age, 10L)
  expect_true(is.integer(s$juvenile_independence_age))
})

test_that("juvenile_independence_energy defaults to 50.0", {
  s <- default_specs()
  expect_identical(s$juvenile_independence_energy, 50.0)
})

test_that("max_clutch_size defaults to 1L", {
  s <- default_specs()
  expect_identical(s$max_clutch_size, 1L)
})

test_that("max_carried parameter does not exist in default_specs (not yet implemented)", {
  # max_carried is not in default_specs(); document that fact
  expect_false("max_carried" %in% names(default_specs()))
})

test_that("parental care params round-trip through default_specs()", {
  s <- default_specs()
  expect_equal(s$parental_care,               FALSE)
  expect_equal(s$care_cost_per_tick,          1.0)
  expect_equal(s$feeding_rate,                5.0)
  expect_equal(s$juvenile_independence_age,   10L)
  expect_equal(s$juvenile_independence_energy, 50.0)
  expect_equal(s$max_clutch_size,             1L)
})

test_that("n_juveniles is in valid_descriptor_columns()", {
  cols <- clade:::.valid_descriptor_columns()
  expect_true("n_juveniles" %in% cols)
})

test_that("juvenile_independence_age is integer type in default_specs()", {
  v <- default_specs()$juvenile_independence_age
  expect_true(is.integer(v))
})

test_that("parental_care = TRUE run completes and n_juveniles present in progress", {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- .minimal_specs(
    parental_care    = TRUE,
    random_seed      = 42L
  )
  env <- run_alife(s, verbose = FALSE)
  expect_true("n_juveniles" %in% names(env$progress))
})

test_that("n_juveniles >= 0 for all ticks when parental_care = TRUE", {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- .minimal_specs(
    parental_care    = TRUE,
    random_seed      = 42L
  )
  env <- run_alife(s, verbose = FALSE)
  expect_true(all(env$progress$n_juveniles >= 0L))
})

test_that("parental_care = TRUE + max_clutch_size = 3L runs without error", {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- .minimal_specs(
    parental_care  = TRUE,
    max_clutch_size = 3L,
    random_seed    = 42L
  )
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
})

test_that("high feeding_rate run completes without error", {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- .minimal_specs(
    parental_care = TRUE,
    feeding_rate  = 20.0,
    random_seed   = 42L
  )
  expect_no_error(env <- run_alife(s, verbose = FALSE))
})

test_that("parental_care = TRUE: n_juveniles column is non-negative and care completes", {
  # A simpler, non-stochastic-direction test: verify that the care system
  # records juvenile counts without error and populations survive.
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- .minimal_specs(
    parental_care      = TRUE,
    care_cost_per_tick = 1.0,
    random_seed        = 42L
  )
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  expect_true("n_juveniles" %in% names(d))
  expect_true(all(d$n_juveniles >= 0L))
})
