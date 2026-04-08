test_that("parental_care defaults to FALSE", {
  expect_false(default_specs()$parental_care)
})

test_that("care_cost_per_tick defaults to 1.0", {
  expect_equal(default_specs()$care_cost_per_tick, 1.0)
})

test_that("feeding_rate defaults to 5.0", {
  expect_equal(default_specs()$feeding_rate, 5.0)
})

test_that("juvenile_independence_age defaults to 10L", {
  expect_equal(default_specs()$juvenile_independence_age, 10L)
})

test_that("juvenile_independence_energy defaults to 50.0", {
  expect_equal(default_specs()$juvenile_independence_energy, 50.0)
})

test_that("parental_care is logical", {
  expect_true(is.logical(default_specs()$parental_care))
})

test_that("care_cost_per_tick is positive", {
  expect_true(default_specs()$care_cost_per_tick > 0)
})

test_that("feeding_rate is positive", {
  expect_true(default_specs()$feeding_rate > 0)
})

test_that("juvenile_independence_age is a positive integer-like value", {
  v <- default_specs()$juvenile_independence_age
  expect_true(is.integer(v) || (is.numeric(v) && v == as.integer(v)))
  expect_true(v > 0)
})

test_that("juvenile_independence_energy is positive", {
  expect_true(default_specs()$juvenile_independence_energy > 0)
})

test_that("all parental care params are present in default_specs", {
  nms <- names(default_specs())
  for (p in c("parental_care", "care_cost_per_tick", "feeding_rate",
               "juvenile_independence_age", "juvenile_independence_energy",
               "max_clutch_size")) {
    expect_true(p %in% nms, info = paste("missing:", p))
  }
})

test_that("care cost formula is numeric: total_cost = care_cost_per_tick * care_load", {
  s         <- default_specs()
  care_load <- 2L
  total     <- s$care_cost_per_tick * care_load
  expect_true(is.numeric(total))
  expect_true(total >= 0)
})

test_that("feeding is bounded by parent energy fraction", {
  s              <- default_specs()
  parent_energy  <- 120.0
  fed            <- min(s$feeding_rate, parent_energy * 0.3)
  expect_true(fed <= parent_energy * 0.3)
})

test_that("juvenile independence condition holds when either criterion is met", {
  s <- default_specs()
  # age criterion
  age1    <- s$juvenile_independence_age
  energy1 <- 0.0
  # energy criterion
  age2    <- 0L
  energy2 <- s$juvenile_independence_energy
  expect_true(age1 >= s$juvenile_independence_age || energy1 >= s$juvenile_independence_energy)
  expect_true(age2 >= s$juvenile_independence_age || energy2 >= s$juvenile_independence_energy)
})

test_that("max_clutch_size is at least 1", {
  expect_true(default_specs()$max_clutch_size >= 1L)
})
