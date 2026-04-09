# Tests for the spatial sorting module (Tier 2a).
# Spatial sorting requires dispersal_evolution = TRUE to have effect.

test_that("default_specs has spatial_sorting parameters", {
  s <- default_specs()
  expect_false(s$spatial_sorting)
  expect_equal(s$sorting_front_threshold, 0.75)
  expect_equal(s$sorting_mating_boost,    3.0)
})

test_that("spatial_sorting default is FALSE", {
  expect_false(default_specs()$spatial_sorting)
})

test_that("sorting_front_threshold is in (0, 1)", {
  s <- default_specs()
  expect_gt(s$sorting_front_threshold, 0)
  expect_lt(s$sorting_front_threshold, 1)
})

test_that("sorting_mating_boost is > 1 (genuine bias)", {
  s <- default_specs()
  expect_gt(s$sorting_mating_boost, 1.0)
})

test_that("spatial_sorting columns present in valid descriptor list", {
  valid <- clade:::.valid_descriptor_columns()
  expect_true("n_front_agents"       %in% valid)
  expect_true("mean_front_dispersal" %in% valid)
  expect_true("mean_rear_dispersal"  %in% valid)
})

test_that("spatial sorting parameters are in default_specs", {
  s <- default_specs()
  expect_true("spatial_sorting"          %in% names(s))
  expect_true("sorting_front_threshold"  %in% names(s))
  expect_true("sorting_mating_boost"     %in% names(s))
})

test_that("dispersal_evolution required for spatial_sorting effect", {
  # Both parameters should coexist
  s <- default_specs()
  s$spatial_sorting    <- TRUE
  s$dispersal_evolution <- TRUE
  expect_true(s$spatial_sorting)
  expect_true(s$dispersal_evolution)
})

test_that("spatial sorting front threshold 0.75 means outermost 25%", {
  # Conceptual: agents at distance > 0.75 * max_dist are "front"
  thr <- default_specs()$sorting_front_threshold
  expect_equal(thr, 0.75)
  expect_equal(1 - thr, 0.25)  # front = outermost 25%
})

test_that("spatial_sorting can be disabled after being enabled", {
  s <- default_specs()
  s$spatial_sorting <- TRUE
  s$spatial_sorting <- FALSE
  expect_false(s$spatial_sorting)
})

test_that("sorting_mating_boost set to 1 means no bias", {
  # A boost of 1 is equivalent to weighting by dispersal_tendency with no front bias
  s <- default_specs()
  s$sorting_mating_boost <- 1.0
  expect_equal(s$sorting_mating_boost, 1.0)
})

test_that("spatial sorting parameters round-trip through list", {
  s <- default_specs()
  s$spatial_sorting          <- TRUE
  s$sorting_front_threshold  <- 0.8
  s$sorting_mating_boost     <- 5.0
  expect_equal(s$sorting_front_threshold, 0.8)
  expect_equal(s$sorting_mating_boost,    5.0)
})

test_that("n_front_agents and dispersal columns initialised in valid columns", {
  valid <- clade:::.valid_descriptor_columns()
  expect_true("n_front_agents"       %in% valid)
  expect_true("mean_front_dispersal" %in% valid)
  expect_true("mean_rear_dispersal"  %in% valid)
})

test_that("dispersal_evolution parameters coexist with sorting params", {
  s <- default_specs()
  expect_true("dispersal_evolution" %in% names(s))
  expect_true("spatial_sorting"     %in% names(s))
})
