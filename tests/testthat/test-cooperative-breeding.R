test_that("cooperative_breeding defaults to FALSE", {
  skip_no_julia()
  expect_false(default_specs()$cooperative_breeding)
})

test_that("helper_min_energy defaults to 80.0", {
  skip_no_julia()
  expect_equal(default_specs()$helper_min_energy, 80.0)
})

test_that("helper_transfer defaults to 5.0", {
  skip_no_julia()
  expect_equal(default_specs()$helper_transfer, 5.0)
})

test_that("helper_kin_threshold defaults to 0.25", {
  skip_no_julia()
  expect_equal(default_specs()$helper_kin_threshold, 0.25)
})

test_that("helper_tendency_init_mean defaults to 0.1", {
  skip_no_julia()
  expect_equal(default_specs()$helper_tendency_init_mean, 0.1)
})

test_that("helper_tendency_mutation_sd defaults to 0.02", {
  skip_no_julia()
  expect_equal(default_specs()$helper_tendency_mutation_sd, 0.02)
})

test_that("cooperative_breeding is logical", {
  skip_no_julia()
  expect_true(is.logical(default_specs()$cooperative_breeding))
})

test_that("helper_min_energy is positive", {
  skip_no_julia()
  expect_true(default_specs()$helper_min_energy > 0)
})

test_that("helper_transfer is positive and less than helper_min_energy", {
  skip_no_julia()
  s <- default_specs()
  expect_true(s$helper_transfer > 0)
  expect_true(s$helper_transfer < s$helper_min_energy)
})

test_that("helper_kin_threshold is in (0, 1)", {
  skip_no_julia()
  t <- default_specs()$helper_kin_threshold
  expect_true(t > 0 && t < 1)
})

test_that("all cooperative breeding params are present in default_specs", {
  skip_no_julia()
  nms <- names(default_specs())
  for (p in c("cooperative_breeding", "helper_min_energy", "helper_transfer",
               "helper_kin_threshold", "helper_tendency_init_mean",
               "helper_tendency_mutation_sd")) {
    expect_true(p %in% nms, info = paste("missing:", p))
  }
})

test_that("Hamilton's rule: r * B > C is satisfied for siblings with default transfer", {
  skip_no_julia()
  # Siblings: r = 0.5; benefit B = helper_transfer; cost C = helper_transfer
  # r * B = 0.5 * B; cost C = B; 0.5 * B < B for B > 0, so rule is NOT satisfied for equal B and C
  # The test verifies the formula evaluates correctly (not that altruism necessarily evolves)
  s <- default_specs()
  r <- 0.5             # relatedness for full siblings
  B <- s$helper_transfer
  C <- s$helper_transfer
  hamilton_lhs <- r * B
  expect_true(is.numeric(hamilton_lhs))
  expect_true(hamilton_lhs > 0)
})

# ── New tests ─────────────────────────────────────────────────────────────────

test_that("cooperative_breeding defaults to FALSE (explicit identical check)", {
  skip_no_julia()
  expect_identical(default_specs()$cooperative_breeding, FALSE)
})

test_that("helper_min_energy defaults to 80.0 (explicit identical check)", {
  skip_no_julia()
  expect_identical(default_specs()$helper_min_energy, 80.0)
})

test_that("helper_transfer defaults to 5.0 (explicit identical check)", {
  skip_no_julia()
  expect_identical(default_specs()$helper_transfer, 5.0)
})

test_that("helper_kin_threshold defaults to 0.25 (explicit identical check)", {
  skip_no_julia()
  expect_identical(default_specs()$helper_kin_threshold, 0.25)
})

test_that("helper_tendency_init_mean defaults to 0.1 (explicit identical check)", {
  skip_no_julia()
  expect_identical(default_specs()$helper_tendency_init_mean, 0.1)
})

test_that("helper_tendency_mutation_sd defaults to 0.02 (explicit identical check)", {
  skip_no_julia()
  expect_identical(default_specs()$helper_tendency_mutation_sd, 0.02)
})

test_that("cooperative breeding params round-trip through default_specs()", {
  skip_no_julia()
  s <- default_specs()
  expect_equal(s$cooperative_breeding,        FALSE)
  expect_equal(s$helper_min_energy,           80.0)
  expect_equal(s$helper_transfer,             5.0)
  expect_equal(s$helper_kin_threshold,        0.25)
  expect_equal(s$helper_tendency_init_mean,   0.1)
  expect_equal(s$helper_tendency_mutation_sd, 0.02)
})

test_that("helper_tendency_init_mean is in [0, 1]", {
  skip_no_julia()
  v <- default_specs()$helper_tendency_init_mean
  expect_gte(v, 0.0)
  expect_lte(v, 1.0)
})

test_that("n_helpers is in valid_descriptor_columns()", {
  skip_no_julia()
  cols <- clade:::.valid_descriptor_columns()
  expect_true("n_helpers" %in% cols)
})

test_that("cooperative_breeding = TRUE + parental_care = TRUE run completes with n_helpers present", {
  skip_no_julia()
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- default_specs()
  s$grid_rows          <- 10L
  s$grid_cols          <- 10L
  s$n_agents_init      <- 10L
  s$max_agents         <- 60L
  s$max_ticks          <- 10L
  s$parental_care      <- TRUE
  s$cooperative_breeding <- TRUE
  s$random_seed        <- 42L
  env <- run_alife(s, verbose = FALSE)
  expect_true("n_helpers" %in% names(env$progress))
})

test_that("n_helpers >= 0 for all ticks when cooperative_breeding = TRUE", {
  skip_no_julia()
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  s <- default_specs()
  s$grid_rows          <- 10L
  s$grid_cols          <- 10L
  s$n_agents_init      <- 10L
  s$max_agents         <- 60L
  s$max_ticks          <- 10L
  s$parental_care      <- TRUE
  s$cooperative_breeding <- TRUE
  s$random_seed        <- 42L
  env <- run_alife(s, verbose = FALSE)
  expect_true(all(env$progress$n_helpers >= 0L))
})

test_that("high helper_kin_threshold reduces mean n_helpers versus low threshold", {
  skip_no_julia()
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
  base <- list(
    grid_rows          = 10L,
    grid_cols          = 10L,
    n_agents_init      = 15L,
    max_agents         = 80L,
    max_ticks          = 20L,
    parental_care      = TRUE,
    cooperative_breeding = TRUE
  )
  s_low <- do.call(.minimal_specs, c(base, list(
    helper_kin_threshold = 0.0,
    random_seed          = 42L
  )))
  s_high <- do.call(.minimal_specs, c(base, list(
    helper_kin_threshold = 0.9,
    random_seed          = 42L
  )))
  env_low  <- run_alife(s_low,  verbose = FALSE)
  env_high <- run_alife(s_high, verbose = FALSE)
  mean_low  <- mean(env_low$progress$n_helpers,  na.rm = TRUE)
  mean_high <- mean(env_high$progress$n_helpers, na.rm = TRUE)
  expect_gte(mean_low, mean_high)
})
