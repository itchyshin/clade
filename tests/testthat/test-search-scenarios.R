# Tests for tune_complex_landscape(), tune_spatial_sorting(), tune_iffolk().
#
# These tests focus on argument handling and structural validation. All
# Julia-backed tests are wrapped in skip_no_julia().

library(testthat)

.tiny_specs <- function(...) {
  s <- default_specs()
  s$grid_rows     <- 3L
  s$grid_cols     <- 3L
  s$n_agents_init <- 5L
  s$max_agents    <- 20L
  s$max_ticks     <- 5L
  args <- list(...)
  for (nm in names(args)) s[[nm]] <- args[[nm]]
  s
}

# ── tune_complex_landscape ────────────────────────────────────────────────────

test_that("tune_complex_landscape() sets complex_landscape = TRUE", {
  skip_no_julia()
  result <- tune_complex_landscape(.tiny_specs(), n_iterations = 1L,
                                    verbose = FALSE)
  expect_type(result, "list")
  expect_true(!is.null(result$specs))
  expect_true(isTRUE(result$specs$complex_landscape))
})

test_that("tune_complex_landscape() returns specs/score/history structure", {
  skip_no_julia()
  result <- tune_complex_landscape(.tiny_specs(), n_iterations = 1L,
                                    verbose = FALSE)
  expect_named(result, c("specs", "score", "history"))
})

test_that("tune_complex_landscape() method='map_elites' returns archive structure", {
  skip_no_julia()
  result <- tune_complex_landscape(.tiny_specs(), n_iterations = 2L,
                                    method = "map_elites", verbose = FALSE)
  expect_named(result, c("archive", "map", "history"))
})

test_that("tune_complex_landscape() optimises landscape-specific params", {
  skip_no_julia()
  result <- tune_complex_landscape(.tiny_specs(), n_iterations = 1L,
                                    verbose = FALSE)
  for (p in c("shrub_density", "canopy_density", "shrub_energy",
              "canopy_energy", "shrub_growth_rate")) {
    expect_false(is.null(result$specs[[p]]),
                 info = sprintf("result$specs$%s is NULL", p))
  }
})

# ── tune_spatial_sorting ──────────────────────────────────────────────────────

test_that("tune_spatial_sorting() sets dispersal_evolution and spatial_sorting", {
  skip_no_julia()
  result <- tune_spatial_sorting(.tiny_specs(), n_iterations = 1L,
                                  verbose = FALSE)
  expect_true(isTRUE(result$specs$dispersal_evolution))
  expect_true(isTRUE(result$specs$spatial_sorting))
})

test_that("tune_spatial_sorting() returns specs/score/history structure", {
  skip_no_julia()
  result <- tune_spatial_sorting(.tiny_specs(), n_iterations = 1L,
                                  verbose = FALSE)
  expect_named(result, c("specs", "score", "history"))
})

test_that("tune_spatial_sorting() method='map_elites' returns archive", {
  skip_no_julia()
  result <- tune_spatial_sorting(.tiny_specs(), n_iterations = 2L,
                                  method = "map_elites", verbose = FALSE)
  expect_named(result, c("archive", "map", "history"))
})

test_that("tune_spatial_sorting() optimises sorting-specific params", {
  skip_no_julia()
  result <- tune_spatial_sorting(.tiny_specs(), n_iterations = 1L,
                                  verbose = FALSE)
  for (p in c("sorting_mating_boost", "sorting_front_threshold",
              "dispersal_init_mean", "dispersal_mutation_sd")) {
    expect_false(is.null(result$specs[[p]]),
                 info = sprintf("result$specs$%s is NULL", p))
  }
})

# ── tune_iffolk ───────────────────────────────────────────────────────────────

test_that("tune_iffolk() sets iffolk_selection and cooperative_breeding", {
  skip_no_julia()
  result <- tune_iffolk(.tiny_specs(), n_iterations = 1L, verbose = FALSE)
  expect_true(isTRUE(result$specs$iffolk_selection))
  expect_true(isTRUE(result$specs$cooperative_breeding))
})

test_that("tune_iffolk() returns specs/score/history structure", {
  skip_no_julia()
  result <- tune_iffolk(.tiny_specs(), n_iterations = 1L, verbose = FALSE)
  expect_named(result, c("specs", "score", "history"))
})

test_that("tune_iffolk() method='map_elites' returns archive", {
  skip_no_julia()
  result <- tune_iffolk(.tiny_specs(), n_iterations = 2L,
                         method = "map_elites", verbose = FALSE)
  expect_named(result, c("archive", "map", "history"))
})

test_that("tune_iffolk() optimises iffolk-specific params", {
  skip_no_julia()
  result <- tune_iffolk(.tiny_specs(), n_iterations = 1L, verbose = FALSE)
  for (p in c("iffolk_transfer", "iffolk_min_energy",
              "parliament_cost")) {
    expect_false(is.null(result$specs[[p]]),
                 info = sprintf("result$specs$%s is NULL", p))
  }
})

# ── tune_iffolk: iffolk_radius is integer — CMA-ES must handle it gracefully ─
# (iffolk_radius is integer in default_specs; search_cmaes requires > 0 numeric)
# The tune wrapper must ensure a valid starting value is found or skip CMA-ES
# for integer params. This is a known limitation documented in the help page.
# Test that tune_iffolk does not crash when iffolk_radius default is present.
test_that("tune_iffolk() does not crash with default specs (integer radius)", {
  skip_no_julia()
  # iffolk_radius default is integer; tune_iffolk passes it to search_cmaes
  # which operates on the log scale. This should work since iffolk_radius > 0.
  expect_no_error(
    tune_iffolk(.tiny_specs(), n_iterations = 1L, verbose = FALSE)
  )
})
