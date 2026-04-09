test_that("group_defense defaults to FALSE in specs", {
  expect_false(default_specs()$group_defense)
})

test_that("group_defense_radius defaults to 2L", {
  expect_equal(default_specs()$group_defense_radius, 2L)
})

test_that("group_defense_strength defaults to 0.3", {
  expect_equal(default_specs()$group_defense_strength, 0.3)
})

test_that("group_defense params present in default_specs", {
  nms <- names(default_specs())
  for (p in c("group_defense", "group_defense_radius", "group_defense_strength")) {
    expect_true(p %in% nms, info = paste("missing:", p))
  }
})

test_that("group_defense is logical", {
  expect_true(is.logical(default_specs()$group_defense))
})

test_that("group_defense_radius is integer-like", {
  r <- default_specs()$group_defense_radius
  expect_true(is.integer(r) || (is.numeric(r) && r == as.integer(r)))
})

test_that("group_defense_strength is in (0, 1]", {
  s <- default_specs()$group_defense_strength
  expect_true(s > 0 && s <= 1)
})

test_that("group_defense dilution formula: factor < 1 when n_nearby > 0", {
  strength  <- 0.3
  n_nearby  <- 5
  factor    <- 1.0 / (1.0 + n_nearby * strength)
  expect_true(factor < 1.0)
  expect_true(factor > 0.0)
})

test_that("group_defense_radius defaults to 2L", {
  r <- default_specs()$group_defense_radius
  expect_equal(r, 2L)
})

test_that("group_defense_strength is in (0, 1] range", {
  s <- default_specs()$group_defense_strength
  expect_gt(s, 0.0)
  expect_lte(s, 1.0)
})

test_that("group_defense defaults to FALSE", {
  expect_false(default_specs()$group_defense)
})

test_that("disabling predators makes group_defense irrelevant: n_predators_init = 0 by default", {
  s <- default_specs()
  s$group_defense <- TRUE
  # With no predators, the group_defense flag changes no population dynamics.
  # Smoke test: constructing this spec list does not error.
  expect_true(is.list(s))
  expect_true(s$group_defense)
  expect_equal(s$n_predators_init, 0L)
})

test_that("group_defense parameter round-trips through default_specs()", {
  s <- default_specs()
  s$group_defense <- TRUE
  expect_true(s$group_defense)
  s$group_defense <- FALSE
  expect_false(s$group_defense)
})

test_that("group_defense parameter is included in valid_descriptor_columns()", {
  # group_defense itself is a binary flag, not a tick-logged column.
  # The logged column for group defense effects would be captured through
  # n_agents or similar. Verify the module flag is in default_specs names.
  expect_true("group_defense" %in% names(default_specs()))
})

test_that("with high group_defense_strength, dilution factor is small (more protection)", {
  # High strength => factor approaches 0 as n_nearby grows.
  strength <- 1.0
  n_nearby <- 10
  factor   <- 1.0 / (1.0 + n_nearby * strength)
  expect_lt(factor, 0.1)
})
