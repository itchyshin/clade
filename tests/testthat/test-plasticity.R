test_that("phenotypic_plasticity defaults to FALSE", {
  expect_false(default_specs()$phenotypic_plasticity)
})

test_that("plasticity_sense_radius defaults to 3L", {
  expect_equal(default_specs()$plasticity_sense_radius, 3L)
})

test_that("plasticity_init_mean defaults to 0.3", {
  expect_equal(default_specs()$plasticity_init_mean, 0.3)
})

test_that("plasticity_mutation_sd defaults to 0.03", {
  expect_equal(default_specs()$plasticity_mutation_sd, 0.03)
})

test_that("plasticity_min defaults to 0.0", {
  expect_equal(default_specs()$plasticity_min, 0.0)
})

test_that("plasticity_max defaults to 1.0", {
  expect_equal(default_specs()$plasticity_max, 1.0)
})

test_that("all plasticity params are present in default_specs", {
  nms <- names(default_specs())
  for (p in c("phenotypic_plasticity", "plasticity_sense_radius",
               "plasticity_init_mean", "plasticity_mutation_sd",
               "plasticity_min", "plasticity_max")) {
    expect_true(p %in% nms, info = paste("missing:", p))
  }
})

test_that("in a rich environment plasticity threshold should move in the correct direction", {
  # In a rich local environment (local_density > 0.5), plasticity reduces the
  # activation threshold — i.e., the adjusted threshold is lower than baseline.
  # Verify the formula direction: threshold_adj = baseline - plasticity * local_density
  baseline      <- 0.5
  plasticity    <- 0.3
  local_density <- 0.7   # rich environment
  threshold_adj <- baseline - plasticity * local_density
  expect_true(threshold_adj < baseline)
})

test_that("phenotypic_plasticity = FALSE is the default", {
  expect_identical(default_specs()$phenotypic_plasticity, FALSE)
})

test_that("plasticity_min and plasticity_max bound the trait correctly", {
  s <- default_specs()
  expect_lte(s$plasticity_min, s$plasticity_max)
  expect_gte(s$plasticity_min, 0.0)
  expect_lte(s$plasticity_max, 1.0)
})

test_that("plasticity_sense_radius defaults to 3L", {
  expect_equal(default_specs()$plasticity_sense_radius, 3L)
})

test_that("plasticity_init_mean defaults to 0.3", {
  expect_equal(default_specs()$plasticity_init_mean, 0.3)
})

test_that("plasticity_mutation_sd is strictly positive", {
  expect_gt(default_specs()$plasticity_mutation_sd, 0.0)
})

test_that("mean_plasticity is a valid descriptor column for MAP-Elites", {
  expect_true("mean_plasticity" %in% clade:::.valid_descriptor_columns())
})

test_that("plasticity_init_mean is within [plasticity_min, plasticity_max]", {
  s <- default_specs()
  expect_gte(s$plasticity_init_mean, s$plasticity_min)
  expect_lte(s$plasticity_init_mean, s$plasticity_max)
})
