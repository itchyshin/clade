library(testthat)

test_that("sense_mode defaults to per_cell and is grouped with brain architecture", {
  specs <- default_specs()
  expect_identical(specs$sense_mode, "per_cell")
  expect_true("sense_mode" %in% .SPEC_GROUPS[["Brain architecture"]])
})
