# Dedicated tests for batch_alife() and batch_seeds().
#
# Before Phase A item 5, batch_alife had a single Julia-required test buried
# in test-integration.R (#20) and batch_seeds had no tests at all. The
# transformations these functions perform — building a parallel specs list,
# overriding random_seed per replicate, naming the results — are pure R and
# can be verified without Julia by mocking run_alife() with
# `testthat::local_mocked_bindings()` (testthat 3.0+).
#
# The PSOCK cluster path (`n_cores > 1L`) requires real R worker processes
# and is exercised end-to-end in test-integration.R behind `skip_no_julia()`;
# we do not duplicate that here.

library(testthat)

# Helper: install a fake run_alife that records its (specs, verbose) call
# arguments and returns a recognisable stub env. Returns the recording
# environment so the test can inspect what was captured.
.with_mock_run_alife <- function(expr_quoted, .envir = parent.frame()) {
  rec <- new.env(parent = emptyenv())
  rec$calls <- list()
  fake <- function(specs, verbose = TRUE) {
    rec$calls[[length(rec$calls) + 1L]] <- list(
      specs   = specs,
      verbose = verbose
    )
    list(progress = list(t = 1L), deaths = list(), specs = specs,
         marker = "mock_env")
  }
  testthat::local_mocked_bindings(run_alife = fake, .package = "clade",
                                  .env = .envir)
  rec
}

# ── batch_seeds() — seed override + naming ───────────────────────────────────

test_that("batch_seeds() overrides random_seed for each replicate", {
  rec <- .with_mock_run_alife()
  specs <- default_specs()
  res <- batch_seeds(specs, seeds = c(7L, 42L, 99L), verbose = FALSE)
  expect_length(rec$calls, 3L)
  seeds_seen <- vapply(rec$calls, function(c) c$specs$random_seed, integer(1L))
  expect_equal(seeds_seen, c(7L, 42L, 99L))
})

test_that("batch_seeds() names each result `seed_<N>` in input order", {
  rec <- .with_mock_run_alife()
  res <- batch_seeds(default_specs(), seeds = c(10L, 20L, 30L),
                     verbose = FALSE)
  expect_named(res, c("seed_10", "seed_20", "seed_30"))
})

test_that("batch_seeds() preserves all non-seed fields from the template", {
  rec <- .with_mock_run_alife()
  specs <- default_specs()
  specs$max_ticks   <- 137L          # distinctive sentinel
  specs$brain_type  <- "ann"         # distinctive sentinel
  batch_seeds(specs, seeds = 1:2, verbose = FALSE)
  for (call in rec$calls) {
    expect_equal(call$specs$max_ticks, 137L)
    expect_equal(call$specs$brain_type, "ann")
  }
})

test_that("batch_seeds() coerces non-integer seeds via as.integer()", {
  rec <- .with_mock_run_alife()
  batch_seeds(default_specs(), seeds = c(1.0, 2.0, 3.7), verbose = FALSE)
  seeds_seen <- vapply(rec$calls, function(c) c$specs$random_seed, integer(1L))
  # as.integer() truncates 3.7 -> 3L
  expect_equal(seeds_seen, c(1L, 2L, 3L))
})

test_that("batch_seeds() rejects non-list specs", {
  expect_error(batch_seeds("not a list"))
  expect_error(batch_seeds(42L))
})

test_that("batch_seeds() rejects empty seeds vector", {
  expect_error(batch_seeds(default_specs(), seeds = integer(0L)))
})

# ── batch_alife() — input validation + serial fallback ───────────────────────

test_that("batch_alife() runs each spec in order under n_cores = 1L", {
  rec <- .with_mock_run_alife()
  s1 <- default_specs(); s1$random_seed <- 100L
  s2 <- default_specs(); s2$random_seed <- 200L
  s3 <- default_specs(); s3$random_seed <- 300L
  res <- batch_alife(list(s1, s2, s3), n_cores = 1L, verbose = FALSE)
  expect_length(res, 3L)
  seeds_seen <- vapply(rec$calls, function(c) c$specs$random_seed, integer(1L))
  expect_equal(seeds_seen, c(100L, 200L, 300L))
})

test_that("batch_alife() propagates the verbose flag to run_alife()", {
  rec <- .with_mock_run_alife()
  batch_alife(list(default_specs()), n_cores = 1L, verbose = TRUE)
  expect_true(rec$calls[[1L]]$verbose)
  rec2 <- .with_mock_run_alife()
  batch_alife(list(default_specs()), n_cores = 1L, verbose = FALSE)
  expect_false(rec2$calls[[1L]]$verbose)
})

test_that("batch_alife() rejects non-list specs_list", {
  expect_error(batch_alife("not a list"))
  expect_error(batch_alife(42L))
})

test_that("batch_alife() rejects empty specs_list", {
  expect_error(batch_alife(list()))
})

test_that("batch_alife() coerces n_cores to integer", {
  rec <- .with_mock_run_alife()
  # Pass numeric 1.0 — must take the serial path, not error.
  res <- batch_alife(list(default_specs()), n_cores = 1.0, verbose = FALSE)
  expect_length(res, 1L)
  expect_length(rec$calls, 1L)
})
