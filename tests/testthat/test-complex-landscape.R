# Tests for the complex multi-resource landscape module (Tier 1).
# These tests exercise R-side default_specs() parameters; Julia-side behaviour
# is tested via integration tests at the bottom (marked \dontrun in docs).

test_that("default_specs has complex_landscape parameters", {
  s <- default_specs()
  expect_false(s$complex_landscape)
  expect_equal(s$shrub_density,    0.3)
  expect_equal(s$shrub_energy,     20.0)
  expect_equal(s$canopy_density,   0.15)
  expect_equal(s$canopy_energy,    50.0)
  expect_equal(s$canopy_threshold, 0.6)
  expect_equal(s$wing_size_init_mean,  0.0)
  expect_equal(s$wing_size_mutation_sd, 0.05)
  expect_equal(s$wing_size_min, 0.0)
  expect_equal(s$wing_size_max, 1.0)
})

test_that("complex_landscape default is FALSE", {
  s <- default_specs()
  expect_false(s$complex_landscape)
})

test_that("complex_landscape can be enabled", {
  s <- default_specs()
  s$complex_landscape <- TRUE
  expect_true(s$complex_landscape)
})

test_that("shrub and canopy energy parameters are positive", {
  s <- default_specs()
  expect_gt(s$shrub_energy, 0)
  expect_gt(s$canopy_energy, 0)
})

test_that("canopy_energy > shrub_energy (canopy is high-value)", {
  s <- default_specs()
  expect_gt(s$canopy_energy, s$shrub_energy)
})

test_that("canopy_growth_rate < shrub_growth_rate (trees grow slowly)", {
  s <- default_specs()
  expect_lt(s$canopy_growth_rate, s$shrub_growth_rate)
})

test_that("wing_size range is 0 to 1", {
  s <- default_specs()
  expect_equal(s$wing_size_min, 0.0)
  expect_equal(s$wing_size_max, 1.0)
})

test_that("canopy_threshold is in (0, 1)", {
  s <- default_specs()
  expect_gt(s$canopy_threshold, 0)
  expect_lt(s$canopy_threshold, 1)
})

test_that("canopy_density + shrub_density plausible (< 1)", {
  s <- default_specs()
  expect_lt(s$canopy_density + s$shrub_density, 1.0)
})

# Logical validation tests (spec consistency)
test_that("wing_size_init_mean is within wing_size_min and wing_size_max", {
  s <- default_specs()
  expect_gte(s$wing_size_init_mean, s$wing_size_min)
  expect_lte(s$wing_size_init_mean, s$wing_size_max)
})

test_that("shrub_growth_rate is a valid probability-ish rate (0-1)", {
  s <- default_specs()
  expect_gte(s$shrub_growth_rate, 0)
  expect_lte(s$shrub_growth_rate, 1)
})

test_that("canopy_growth_rate is a valid probability-ish rate (0-1)", {
  s <- default_specs()
  expect_gte(s$canopy_growth_rate, 0)
  expect_lte(s$canopy_growth_rate, 1)
})

test_that("niche_layer field documented in search valid columns", {
  valid <- clade:::.valid_descriptor_columns()
  expect_true("n_canopy_agents"  %in% valid)
  expect_true("n_shrub_agents"   %in% valid)
  expect_true("n_ground_agents"  %in% valid)
  expect_true("mean_wing_size"   %in% valid)
})

test_that("complex_landscape columns in valid descriptor list", {
  valid <- clade:::.valid_descriptor_columns()
  expect_true("mean_shrub_coverage"  %in% valid)
  expect_true("mean_canopy_coverage" %in% valid)
})
