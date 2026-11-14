library(testthat)

test_that("sense_mode defaults to per_cell and is grouped with brain architecture", {
  specs <- default_specs()
  expect_identical(specs$sense_mode, "per_cell")
  expect_true("sense_mode" %in% .SPEC_GROUPS[["Brain architecture"]])
})

test_that("saved specs without sense_mode retain per-cell compatibility", {
  specs <- default_specs()
  specs$sense_mode <- NULL
  expect_silent(.validate_specs(specs))
  specs$sense_mode <- "invalid"
  expect_error(.validate_specs(specs), "sense_mode")
})


test_that("run_alife records the per-cell fallback for saved specs", {
  skip_no_julia()
  specs <- .minimal_specs()
  specs$sense_mode <- NULL
  env <- run_alife(specs, verbose = FALSE)
  expect_identical(env$specs$sense_mode, "per_cell")
  expect_length(sense_env(env, 1L), 11L)
})
