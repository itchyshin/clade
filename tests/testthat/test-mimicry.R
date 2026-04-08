test_that("mimicry defaults to FALSE", {
  expect_false(default_specs()$mimicry)
})

test_that("toxicity_cost_per_tick defaults to 0.5", {
  expect_equal(default_specs()$toxicity_cost_per_tick, 0.5)
})

test_that("toxin_dose defaults to 30.0", {
  expect_equal(default_specs()$toxin_dose, 30.0)
})

test_that("signal_memory_rate defaults to 0.3", {
  expect_equal(default_specs()$signal_memory_rate, 0.3)
})

test_that("avoid_threshold defaults to 0.5", {
  expect_equal(default_specs()$avoid_threshold, 0.5)
})

test_that("toxicity_init_mean defaults to 0.0", {
  expect_equal(default_specs()$toxicity_init_mean, 0.0)
})

test_that("toxicity_mutation_sd defaults to 0.05", {
  expect_equal(default_specs()$toxicity_mutation_sd, 0.05)
})

test_that("all mimicry params are present in default_specs", {
  nms <- names(default_specs())
  for (p in c("mimicry", "toxicity_cost_per_tick", "toxin_dose",
               "signal_memory_rate", "avoid_threshold",
               "toxicity_init_mean", "toxicity_mutation_sd")) {
    expect_true(p %in% nms, info = paste("missing:", p))
  }
})

test_that("toxin_dose is positive", {
  expect_true(default_specs()$toxin_dose > 0)
})

test_that("signal_memory_rate is in (0, 1)", {
  r <- default_specs()$signal_memory_rate
  expect_true(r > 0 && r < 1)
})
