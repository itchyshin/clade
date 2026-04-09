test_that("register_module stores a module", {
  clear_modules()
  register_module(function(env) env, when = "post_tick", name = "test_mod")
  expect_length(list_modules(), 1L)
  clear_modules()
})

test_that("list_modules returns empty when no modules registered", {
  clear_modules()
  expect_equal(list_modules(), character(0L))
})

test_that("list_modules returns name and when", {
  clear_modules()
  register_module(function(env) env, when = "post_tick",  name = "a")
  register_module(function(env) env, when = "pre_tick",   name = "b")
  mods <- list_modules()
  expect_length(mods, 2L)
  expect_true(any(grepl("post_tick", mods)))
  expect_true(any(grepl("pre_tick",  mods)))
  clear_modules()
})

test_that("clear_modules removes all modules", {
  register_module(function(env) env, name = "x")
  register_module(function(env) env, name = "y")
  clear_modules()
  expect_equal(list_modules(), character(0L))
})

test_that("register_module errors on invalid `when`", {
  expect_error(register_module(function(env) env, when = "invalid_hook"),
               regexp = "when")
})

test_that("register_module errors on non-function `fn`", {
  expect_error(register_module(42, when = "post_tick"), regexp = "function")
})

test_that("multiple modules at same hook stored in order", {
  clear_modules()
  register_module(function(env) env, when = "post_tick", name = "first")
  register_module(function(env) env, when = "post_tick", name = "second")
  mods <- list_modules()
  expect_equal(length(mods), 2L)
  expect_true(grepl("first", mods[1]))
  expect_true(grepl("second", mods[2]))
  clear_modules()
})

test_that(".apply_custom_modules runs module at matching hook only", {
  clear_modules()
  counter <- 0L
  register_module(function(env) { counter <<- counter + 1L; env },
                  when = "post_tick", name = "counter_mod")
  snap <- list(agents = list(), grass = matrix(0, 2, 2), t = 1L, specs = list())
  clade:::.apply_custom_modules(snap, "pre_tick")     # should NOT fire
  expect_equal(counter, 0L)
  clade:::.apply_custom_modules(snap, "post_tick")    # should fire
  expect_equal(counter, 1L)
  clear_modules()
})

test_that(".apply_custom_modules returns env unchanged when no module matches", {
  clear_modules()
  snap <- list(agents = list(), grass = matrix(1, 2, 2), t = 5L, specs = list())
  result <- clade:::.apply_custom_modules(snap, "post_reproduce")
  expect_identical(result, snap)
})

test_that(".apply_custom_modules catches errors and returns warning", {
  clear_modules()
  register_module(function(env) stop("oops"), when = "post_tick", name = "bad_mod")
  snap <- list(agents = list(), grass = matrix(0, 2, 2), t = 1L, specs = list())
  expect_warning(
    clade:::.apply_custom_modules(snap, "post_tick"),
    regexp = "bad_mod"
  )
  clear_modules()
})

test_that("energy-drain module modifies snapshot correctly", {
  clear_modules()
  drain_mod <- function(env) {
    for (i in seq_along(env$agents)) {
      env$agents[[i]]$energy <- 0
    }
    env
  }
  register_module(drain_mod, when = "post_tick", name = "drain")
  snap <- list(
    agents = list(list(energy = 100, alive = TRUE),
                  list(energy = 80,  alive = TRUE)),
    grass = matrix(0, 2, 2), t = 1L, specs = list()
  )
  result <- clade:::.apply_custom_modules(snap, "post_tick")
  expect_equal(result$agents[[1]]$energy, 0)
  expect_equal(result$agents[[2]]$energy, 0)
  clear_modules()
})

test_that("alive-setter module works correctly", {
  clear_modules()
  kill_mod <- function(env) {
    env$agents[[1]]$alive <- FALSE
    env
  }
  register_module(kill_mod, when = "post_tick", name = "kill_first")
  snap <- list(
    agents = list(list(energy = 100, alive = TRUE),
                  list(energy = 80,  alive = TRUE)),
    grass = matrix(0, 2, 2), t = 1L, specs = list()
  )
  result <- clade:::.apply_custom_modules(snap, "post_tick")
  expect_false(result$agents[[1]]$alive)
  expect_true(result$agents[[2]]$alive)
  clear_modules()
})

test_that("register_module auto-names when name is NULL", {
  clear_modules()
  register_module(function(env) env)
  mods <- list_modules()
  expect_true(grepl("module_1", mods[1]))
  clear_modules()
})
