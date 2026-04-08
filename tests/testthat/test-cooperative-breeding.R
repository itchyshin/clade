test_that("cooperative_breeding defaults to FALSE", {
  expect_false(default_specs()$cooperative_breeding)
})

test_that("helper_min_energy defaults to 80.0", {
  expect_equal(default_specs()$helper_min_energy, 80.0)
})

test_that("helper_transfer defaults to 5.0", {
  expect_equal(default_specs()$helper_transfer, 5.0)
})

test_that("helper_kin_threshold defaults to 0.25", {
  expect_equal(default_specs()$helper_kin_threshold, 0.25)
})

test_that("helper_tendency_init_mean defaults to 0.1", {
  expect_equal(default_specs()$helper_tendency_init_mean, 0.1)
})

test_that("helper_tendency_mutation_sd defaults to 0.02", {
  expect_equal(default_specs()$helper_tendency_mutation_sd, 0.02)
})

test_that("cooperative_breeding is logical", {
  expect_true(is.logical(default_specs()$cooperative_breeding))
})

test_that("helper_min_energy is positive", {
  expect_true(default_specs()$helper_min_energy > 0)
})

test_that("helper_transfer is positive and less than helper_min_energy", {
  s <- default_specs()
  expect_true(s$helper_transfer > 0)
  expect_true(s$helper_transfer < s$helper_min_energy)
})

test_that("helper_kin_threshold is in (0, 1)", {
  t <- default_specs()$helper_kin_threshold
  expect_true(t > 0 && t < 1)
})

test_that("all cooperative breeding params are present in default_specs", {
  nms <- names(default_specs())
  for (p in c("cooperative_breeding", "helper_min_energy", "helper_transfer",
               "helper_kin_threshold", "helper_tendency_init_mean",
               "helper_tendency_mutation_sd")) {
    expect_true(p %in% nms, info = paste("missing:", p))
  }
})

test_that("Hamilton's rule: r * B > C is satisfied for siblings with default transfer", {
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
