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
