# Dedicated tests for load_specs().
#
# Before Phase A item 27, load_specs() (R/analysis.R:629) had no dedicated
# test coverage — relied on the R CMD check example-runner. The function is
# pure R (jsonlite::read_json + type coercion + setdiff over known fields),
# so testable without Julia or a real spec file.

library(testthat)

.write_temp_json <- function(spec_overrides) {
  skip_if_not_installed("jsonlite")
  path <- tempfile(fileext = ".json")
  jsonlite::write_json(spec_overrides, path = path, auto_unbox = TRUE,
                       pretty = FALSE)
  path
}

test_that("load_specs() applies JSON overrides on top of default_specs()", {
  path <- .write_temp_json(list(mutation_sd = 0.3, grass_rate = 0.6))
  on.exit(unlink(path), add = TRUE)
  s <- load_specs(path)
  expect_equal(s$mutation_sd, 0.3)
  expect_equal(s$grass_rate,  0.6)
  # Other fields unchanged
  expect_equal(s$n_agents_init, default_specs()$n_agents_init)
})

test_that("load_specs() preserves integer type for integer fields", {
  path <- .write_temp_json(list(n_agents_init = 250, max_ticks = 500))
  on.exit(unlink(path), add = TRUE)
  s <- load_specs(path)
  expect_equal(s$n_agents_init, 250L)
  expect_equal(s$max_ticks,     500L)
  expect_true(is.integer(s$n_agents_init))
  expect_true(is.integer(s$max_ticks))
})

test_that("load_specs() warns on unknown parameter names", {
  path <- .write_temp_json(list(grass_rate = 0.1,
                                ghost_field_xyz = TRUE))
  on.exit(unlink(path), add = TRUE)
  expect_warning(s <- load_specs(path), regexp = "unknown parameter")
  # The known override still lands; the unknown is silently dropped.
  expect_equal(s$grass_rate, 0.1)
  expect_null(s[["ghost_field_xyz"]])
})

test_that("load_specs() errors when the file does not exist", {
  expect_error(load_specs("/tmp/this_file_should_not_exist_xyz.json"),
               regexp = "File not found")
})

test_that("load_specs() returns the full ~300-field specs list", {
  path <- .write_temp_json(list(grass_rate = 0.05))
  on.exit(unlink(path), add = TRUE)
  s <- load_specs(path)
  expect_equal(length(s), length(default_specs()))
  expect_setequal(names(s), names(default_specs()))
})
