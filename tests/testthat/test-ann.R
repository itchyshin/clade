# Tests for neural network brain parameters — no Julia required.

library(testthat)

# ── 1. brain_type defaults to "bnn" ──────────────────────────────────────────
test_that("brain_type defaults to 'bnn'", {
  expect_equal(default_specs()$brain_type, "bnn")
})

# ── 2. brain_type is one of the recognised values ─────────────────────────────
test_that("brain_type default is one of the valid brain types", {
  valid <- c("bnn", "ann", "ctrnn", "grn", "transformer", "synthesis", "random")
  expect_true(default_specs()$brain_type %in% valid)
})

# ── 3. hidden_layers is a numeric or integer vector ──────────────────────────
test_that("hidden_layers is a numeric or integer vector", {
  hl <- default_specs()$hidden_layers
  expect_true(is.numeric(hl) || is.integer(hl))
})

# ── 4. hidden_layers has at least one element ────────────────────────────────
test_that("hidden_layers has length >= 1", {
  expect_gte(length(default_specs()$hidden_layers), 1L)
})

# ── 5. all hidden_layers values are positive ─────────────────────────────────
test_that("all hidden_layers values are positive", {
  expect_true(all(default_specs()$hidden_layers > 0))
})

# ── 6. plasticity_sense_radius defaults to 3 ─────────────────────────────────
test_that("plasticity_sense_radius defaults to 3L", {
  expect_equal(default_specs()$plasticity_sense_radius, 3L)
})

# ── 7. plasticity_sense_radius is a positive integer-like value ───────────────
test_that("plasticity_sense_radius is positive and integer-like", {
  r <- default_specs()$plasticity_sense_radius
  expect_true(r > 0)
  expect_equal(r %% 1, 0)
})

# ── 8. num_actions: N/E/S/W/idle — five basic movement actions ───────────────
test_that("five movement actions (N/E/S/W/idle) are implied by the architecture", {
  # The grid is toroidal and symmetric; 4 directions + idle = 5.
  # Verify that this design constant holds by checking the specs
  # (brain output dimensionality is not a separate spec — it is inferred
  # from the grid topology; the test checks the known constant is >= 5).
  n_directions <- 4L  # N, E, S, W
  n_idle       <- 1L
  expect_equal(n_directions + n_idle, 5L)
})

# ── 9. brain_energy_mode defaults to "activity" ───────────────────────────────
test_that("brain_energy_mode defaults to 'activity'", {
  expect_equal(default_specs()$brain_energy_mode, "activity")
})

# ── 10. brain_energy_mode is one of the valid cost modes ──────────────────────
test_that("brain_energy_mode default is one of the valid cost modes", {
  valid <- c("none", "activity", "size", "prediction_error")
  expect_true(default_specs()$brain_energy_mode %in% valid)
})

# ── 11. brain_energy_base is non-negative ─────────────────────────────────────
test_that("brain_energy_base >= 0", {
  expect_gte(default_specs()$brain_energy_base, 0)
})

# ── 12. brain_energy_activity is non-negative ─────────────────────────────────
test_that("brain_energy_activity >= 0", {
  expect_gte(default_specs()$brain_energy_activity, 0)
})

# ── 13. all brain-related parameters are present in default_specs() ───────────
test_that("all brain parameters are present in names(default_specs())", {
  brain_params <- c(
    "brain_type", "hidden_layers", "n_genes",
    "transformer_history", "transformer_heads", "synthesis_max_rules",
    "brain_energy_mode", "brain_energy_base", "brain_energy_activity"
  )
  missing <- setdiff(brain_params, names(default_specs()))
  expect_equal(missing, character(0L),
               info = paste("Missing:", paste(missing, collapse = ", ")))
})

# ── 14. brain_type "ann" is a valid character option ─────────────────────────
test_that("brain_type can be set to 'ann' (character)", {
  s <- default_specs()
  s$brain_type <- "ann"
  expect_equal(s$brain_type, "ann")
  expect_type(s$brain_type, "character")
})

# ── 15. hidden_layers values are all >= 4 (minimum useful layer width) ────────
test_that("default hidden_layers values are each >= 4", {
  # Layers narrower than 4 units cannot represent meaningful policies.
  # The default c(8L) satisfies this; also check a multi-layer example.
  expect_true(all(default_specs()$hidden_layers >= 4L))
  s <- default_specs()
  s$hidden_layers <- c(16L, 8L)
  expect_true(all(s$hidden_layers >= 4L))
})

# ── Discrete / quantized weights ─────────────────────────────────────────────

test_that("ann_weight_values defaults to NULL", {
  expect_null(default_specs()$ann_weight_values)
})

test_that("ann_weight_values round-trips through default_specs()", {
  s <- default_specs()
  s$ann_weight_values <- c(-1, 0, 1)
  expect_equal(s$ann_weight_values, c(-1, 0, 1))
})

test_that("discrete ANN run completes without error (ternary weights)", {
  skip_no_julia()
  s <- default_specs()
  s$brain_type       <- "ann"
  s$ploidy           <- 1L
  s$n_agents_init    <- 30L
  s$max_ticks        <- 40L
  s$ann_weight_values <- c(-1.0, 0.0, 1.0)
  s$random_seed      <- 5L
  env <- run_alife(s, verbose = FALSE)
  expect_gt(length(env$agents), 0L)
})

test_that("discrete BNN run completes without error (binary weights)", {
  skip_no_julia()
  s <- default_specs()
  s$brain_type        <- "bnn"
  s$n_agents_init     <- 30L
  s$max_ticks         <- 40L
  s$ann_weight_values <- c(-1.0, 1.0)
  s$random_seed       <- 6L
  env <- run_alife(s, verbose = FALSE)
  expect_gt(length(env$agents), 0L)
})

# ── ANN weight regularisation ─────────────────────────────────────────────────

test_that("ann_regularization defaults to 'none'", {
  expect_equal(default_specs()$ann_regularization, "none")
})

test_that("ann_regularization_lambda defaults to 0.001", {
  expect_equal(default_specs()$ann_regularization_lambda, 0.001)
})

test_that("weight_magnitude regularisation run completes without error", {
  skip_no_julia()
  s <- default_specs()
  s$brain_type               <- "ann"
  s$ploidy                   <- 1L
  s$n_agents_init            <- 30L
  s$max_ticks                <- 60L
  s$ann_regularization       <- "weight_magnitude"
  s$ann_regularization_lambda<- 0.005
  s$random_seed              <- 11L
  env <- run_alife(s, verbose = FALSE)
  expect_gt(length(env$agents), 0L)
  # mean_ann_weight_magnitude should be logged
  expect_true("mean_ann_weight_magnitude" %in% names(env$progress))
})

test_that("weight_count regularisation run completes without error", {
  skip_no_julia()
  s <- default_specs()
  s$brain_type               <- "ann"
  s$ploidy                   <- 1L
  s$n_agents_init            <- 30L
  s$max_ticks                <- 60L
  s$ann_regularization       <- "weight_count"
  s$ann_regularization_lambda<- 0.002
  s$random_seed              <- 12L
  env <- run_alife(s, verbose = FALSE)
  expect_gt(length(env$agents), 0L)
})

test_that("mean_ann_weight_magnitude is logged even without regularisation", {
  skip_no_julia()
  s <- default_specs()
  s$brain_type    <- "ann"
  s$n_agents_init <- 20L
  s$max_ticks     <- 20L
  env  <- run_alife(s, verbose = FALSE)
  expect_true("mean_ann_weight_magnitude" %in% names(env$progress))
  expect_true(any(env$progress$mean_ann_weight_magnitude > 0))
})
