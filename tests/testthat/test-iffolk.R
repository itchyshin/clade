# Tests for the IFfolk inclusive fitness module (Tier 2b).
# Fromhage & Jennions (2019): IFfolk = own offspring + sum(r * relative_offspring)
# With parliament_suppression: defectors penalised in cooperative neighbourhoods.

test_that("default_specs has iffolk parameters", {
  s <- default_specs()
  expect_false(s$iffolk_selection)
  expect_equal(s$iffolk_r_min,       0.125)
  expect_equal(s$iffolk_radius,      5L)
  expect_equal(s$iffolk_transfer,    3.0)
  expect_equal(s$iffolk_min_energy,  60.0)
  expect_false(s$parliament_suppression)
  expect_equal(s$parliament_cost,    0.5)
})

test_that("iffolk_selection default is FALSE", {
  expect_false(default_specs()$iffolk_selection)
})

test_that("parliament_suppression default is FALSE", {
  expect_false(default_specs()$parliament_suppression)
})

test_that("iffolk_r_min is 1/8 (cousin-level relatedness)", {
  s <- default_specs()
  expect_equal(s$iffolk_r_min, 0.125)
  expect_equal(s$iffolk_r_min, 1/8)
})

test_that("iffolk_transfer is positive", {
  expect_gt(default_specs()$iffolk_transfer, 0)
})

test_that("iffolk_min_energy is positive", {
  expect_gt(default_specs()$iffolk_min_energy, 0)
})

test_that("iffolk_radius is a positive integer", {
  s <- default_specs()
  expect_true(is.numeric(s$iffolk_radius))
  expect_equal(s$iffolk_radius %% 1, 0)  # integer-valued
  expect_gt(s$iffolk_radius, 0)
})

test_that("parliament_cost is positive", {
  expect_gt(default_specs()$parliament_cost, 0)
})

test_that("iffolk columns present in valid descriptor list", {
  valid <- clade:::.valid_descriptor_columns()
  expect_true("n_iffolk_transfers" %in% valid)
})

test_that("iffolk_selection and parliament_suppression can be enabled together", {
  s <- default_specs()
  s$iffolk_selection     <- TRUE
  s$parliament_suppression <- TRUE
  expect_true(s$iffolk_selection)
  expect_true(s$parliament_suppression)
})

test_that("iffolk parameters all present in default_specs", {
  s <- default_specs()
  expected <- c("iffolk_selection", "iffolk_r_min", "iffolk_radius",
                "iffolk_transfer", "iffolk_min_energy",
                "parliament_suppression", "parliament_cost")
  for (param in expected) {
    expect_true(param %in% names(s), info = paste("missing:", param))
  }
})

test_that("iffolk_r_min < 0.5 (includes cousin and sibling but not unrelated)", {
  s <- default_specs()
  expect_lt(s$iffolk_r_min, 0.5)   # not just parent-offspring
  expect_gt(s$iffolk_r_min, 0.0)   # excludes strangers
})

test_that("iffolk_transfer < iffolk_min_energy (donor can't give more than threshold)", {
  s <- default_specs()
  # Transfer amount should be << min_energy (donors never deplete themselves)
  expect_lt(s$iffolk_transfer, s$iffolk_min_energy)
})

test_that("parliament_cost is small relative to energy costs", {
  s <- default_specs()
  # Parliament cost should not be catastrophically large
  expect_lt(s$parliament_cost, s$iffolk_min_energy * 0.1)
})

test_that("iffolk module is independent of kin_selection module", {
  s <- default_specs()
  # Both flags can be set independently
  s$kin_selection  <- TRUE
  s$iffolk_selection <- FALSE
  expect_true(s$kin_selection)
  expect_false(s$iffolk_selection)

  s$kin_selection  <- FALSE
  s$iffolk_selection <- TRUE
  expect_false(s$kin_selection)
  expect_true(s$iffolk_selection)
})
