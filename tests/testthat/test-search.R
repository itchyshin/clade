# Tests for search_map_elites(), search_cmaes(), and search_gradient().
#
# Pure-R structural tests run on every CI machine; Julia round-trip tests are
# wrapped in skip_no_julia() so the suite still passes when JuliaConnectoR or
# the Julia toolchain is unavailable.

library(testthat)

# ── Helpers ──────────────────────────────────────────────────────────────────

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

skip_no_julia <- function() {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
}

skip_no_ga <- function() {
  skip_if_not(requireNamespace("GA", quietly = TRUE),
              "GA package not available")
}

# ── 1. search_map_elites: bad archive_dims name is rejected ──────────────────
test_that("search_map_elites() rejects unknown archive_dims column names", {
  expect_error(
    search_map_elites(
      specs_base   = .tiny_specs(),
      archive_dims = list(not_a_real_column = seq(0, 1, by = 0.5)),
      n_iterations = 0L,
      verbose      = FALSE
    ),
    regexp = "not_a_real_column"
  )
})

# ── 2. search_gradient: invalid params raise descriptive errors ──────────────
test_that("search_gradient() raises a descriptive error for bad params", {
  # Non-existent parameter name
  expect_error(
    search_gradient(
      specs_base = .tiny_specs(),
      params     = "nonexistent_parameter",
      n_steps    = 1L,
      verbose    = FALSE
    ),
    regexp = "nonexistent_parameter"
  )
  # Non-positive numeric (zero) — finite differences on log scale require > 0
  expect_error(
    search_gradient(
      specs_base = .tiny_specs(grass_rate = 0),
      params     = "grass_rate",
      n_steps    = 1L,
      verbose    = FALSE
    ),
    regexp = "grass_rate"
  )
})

# ── 3. search_map_elites: n_iterations = 0L returns an empty archive ─────────
test_that("search_map_elites(n_iterations = 0L) returns empty archive", {
  result <- search_map_elites(
    specs_base   = .tiny_specs(),
    archive_dims = list(genetic_diversity = seq(0, 0.5, by = 0.1)),
    n_iterations = 0L,
    verbose      = FALSE
  )
  expect_type(result, "list")
  expect_named(result, c("archive", "map", "history"))
  expect_true(all(vapply(result$archive, is.null, logical(1L))))
  expect_equal(nrow(result$history), 0L)
})

# ── 4. search_map_elites: default genetic_diversity dim accepted ─────────────
test_that("search_map_elites() accepts genetic_diversity archive dimension", {
  expect_no_error(
    search_map_elites(
      specs_base   = .tiny_specs(),
      archive_dims = list(genetic_diversity = seq(0, 0.5, by = 0.1)),
      n_iterations = 0L,
      verbose      = FALSE
    )
  )
})

# ── 5. search_map_elites: tiny Julia run produces a non-empty archive ────────
test_that("search_map_elites() with 3 iterations fills at least one cell", {
  skip_no_julia()
  result <- search_map_elites(
    specs_base   = .tiny_specs(),
    archive_dims = list(genetic_diversity = seq(0, 0.5, by = 0.1)),
    n_iterations = 3L,
    verbose      = FALSE
  )
  expect_type(result, "list")
  expect_named(result, c("archive", "map", "history"))
  filled <- sum(!vapply(result$archive, is.null, logical(1L)))
  expect_gte(filled, 1L)
})

# ── 6. search_map_elites: history has the documented columns ─────────────────
test_that("search_map_elites() history data frame has expected columns", {
  skip_no_julia()
  result <- search_map_elites(
    specs_base   = .tiny_specs(),
    archive_dims = list(genetic_diversity = seq(0, 0.5, by = 0.1)),
    n_iterations = 3L,
    verbose      = FALSE
  )
  expect_s3_class(result$history, "data.frame")
  for (nm in c("iteration", "score", "filled_cells"))
    expect_true(nm %in% names(result$history),
                info = sprintf("history is missing column `%s`", nm))
})

# Helper: GA::ga emits "population size is less than 10" when popsize < 10.
# This is purely informational, but we use popsize = 3 to keep tests fast,
# so suppress that one warning at the call site to keep test output clean.
.tiny_cmaes <- function() {
  suppressWarnings(search_cmaes(
    specs_base   = .tiny_specs(),
    objective    = "genetic_diversity",
    params       = c("grass_rate", "mutation_sd"),
    n_iterations = 2L,
    popsize      = 3L,
    verbose      = FALSE
  ))
}

# ── 7. search_cmaes: tiny run returns the documented structure ───────────────
test_that("search_cmaes() returns specs/score/history list", {
  skip_no_julia()
  skip_no_ga()
  result <- .tiny_cmaes()
  expect_type(result, "list")
  expect_named(result, c("specs", "score", "history"))
})

# ── 8. search_cmaes: returned specs round-trips through .validate_specs() ────
test_that("search_cmaes() result$specs passes .validate_specs()", {
  skip_no_julia()
  skip_no_ga()
  result <- .tiny_cmaes()
  expect_true(is.list(result$specs))
  expect_silent(clade:::.validate_specs(result$specs))
})

# ── 9. search_cmaes: result$score is finite and numeric ──────────────────────
test_that("search_cmaes() result$score is finite numeric", {
  skip_no_julia()
  skip_no_ga()
  result <- .tiny_cmaes()
  expect_true(is.numeric(result$score))
  expect_length(result$score, 1L)
  expect_true(is.finite(result$score))
})

# ── 10. search_gradient: tiny run returns the documented structure ───────────
test_that("search_gradient() returns specs/score/history list", {
  skip_no_julia()
  result <- search_gradient(
    specs_base    = .tiny_specs(),
    params        = "grass_rate",
    objective     = "genetic_diversity",
    n_steps       = 2L,
    epsilon       = 0.05,
    learning_rate = 0.1,
    verbose       = FALSE
  )
  expect_type(result, "list")
  expect_named(result, c("specs", "score", "history"))
})

# ── 11. search_gradient: returned specs round-trips through .validate_specs() ─
test_that("search_gradient() result$specs passes .validate_specs()", {
  skip_no_julia()
  result <- search_gradient(
    specs_base    = .tiny_specs(),
    params        = "grass_rate",
    objective     = "genetic_diversity",
    n_steps       = 2L,
    epsilon       = 0.05,
    learning_rate = 0.1,
    verbose       = FALSE
  )
  expect_true(is.list(result$specs))
  expect_silent(clade:::.validate_specs(result$specs))
})

# ── 12. search_gradient: history has at least one row ────────────────────────
test_that("search_gradient() history data frame has at least one row", {
  skip_no_julia()
  result <- search_gradient(
    specs_base    = .tiny_specs(),
    params        = "grass_rate",
    objective     = "genetic_diversity",
    n_steps       = 2L,
    epsilon       = 0.05,
    learning_rate = 0.1,
    verbose       = FALSE
  )
  expect_s3_class(result$history, "data.frame")
  expect_gte(nrow(result$history), 1L)
})

# ── 13. search_random: structural checks (no Julia) ───────────────────────────
test_that("search_random() rejects unnamed search_params", {
  expect_error(
    search_random(
      specs_base    = default_specs(),
      search_params = list(c(0.01, 0.5)),   # unnamed
      n_samples     = 1L
    ),
    "fully named"
  )
})

test_that("search_random() returns data frame with rank, score, and param columns", {
  skip_no_julia()
  result <- search_random(
    specs_base    = .tiny_specs(),
    search_params = list(grass_rate = c(0.1, 0.5)),
    n_samples     = 3L,
    objective     = "genetic_diversity",
    verbose       = FALSE
  )
  expect_s3_class(result, "data.frame")
  expect_true("rank"       %in% names(result))
  expect_true("score"      %in% names(result))
  expect_true("grass_rate" %in% names(result))
  expect_equal(nrow(result), 3L)
})

test_that("search_random() returns rows sorted by descending score", {
  skip_no_julia()
  result <- search_random(
    specs_base    = .tiny_specs(),
    search_params = list(grass_rate = c(0.1, 0.6)),
    n_samples     = 4L,
    objective     = "genetic_diversity",
    verbose       = FALSE
  )
  valid <- !is.na(result$score)
  expect_true(all(diff(result$score[valid]) <= 0))
})

test_that("search_random() rank column is 1..n_samples", {
  skip_no_julia()
  result <- search_random(
    specs_base    = .tiny_specs(),
    search_params = list(mutation_sd = c(0.01, 0.3)),
    n_samples     = 3L,
    objective     = "n_agents",
    verbose       = FALSE
  )
  expect_equal(result$rank, seq_len(3L))
})

test_that("search_random() accepts integer parameter ranges", {
  skip_no_julia()
  result <- search_random(
    specs_base    = .tiny_specs(),
    search_params = list(n_agents_init = c(3L, 10L)),
    n_samples     = 2L,
    objective     = "genetic_diversity",
    verbose       = FALSE
  )
  expect_true(is.integer(result$n_agents_init))
})

test_that("search_random() accepts a custom objective function", {
  skip_no_julia()
  obj <- function(env) max(get_run_data(env)$ticks$n_agents, na.rm = TRUE)
  result <- search_random(
    specs_base    = .tiny_specs(),
    search_params = list(grass_rate = c(0.1, 0.5)),
    n_samples     = 2L,
    objective     = obj,
    verbose       = FALSE
  )
  expect_true(all(result$score >= 0 | is.na(result$score)))
})

test_that("search_random() attaches specs_list attribute with correct length", {
  skip_no_julia()
  result <- search_random(
    specs_base    = .tiny_specs(),
    search_params = list(grass_rate = c(0.1, 0.5)),
    n_samples     = 3L,
    objective     = "genetic_diversity",
    verbose       = FALSE
  )
  sl <- attr(result, "specs_list")
  expect_equal(length(sl), 3L)
  expect_true(all(vapply(sl, is.list, logical(1L))))
})

test_that("search_random() can sweep multiple parameters simultaneously", {
  skip_no_julia()
  result <- search_random(
    specs_base    = .tiny_specs(),
    search_params = list(
      mutation_sd = c(0.01, 0.4),
      grass_rate  = c(0.1, 0.6)
    ),
    n_samples  = 4L,
    objective  = "genetic_diversity",
    verbose    = FALSE
  )
  expect_true("mutation_sd" %in% names(result))
  expect_true("grass_rate"  %in% names(result))
})

# ── Diversity-search vignette: structural tests ───────────────────────────────

# ── 14. search_random: n_samples = 1L returns a single-row data frame ─────────
test_that("search_random() with n_samples = 1L returns a one-row data frame with a score column", {
  skip_no_julia()
  result <- search_random(
    specs_base    = .tiny_specs(),
    search_params = list(mutation_sd = c(0.01, 0.5)),
    n_samples     = 1L,
    objective     = "genetic_diversity",
    verbose       = FALSE
  )
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_true("score" %in% names(result))
})

# ── 15. search_random: result$score is numeric ────────────────────────────────
test_that("search_random() result$score column is numeric", {
  skip_no_julia()
  result <- search_random(
    specs_base    = .tiny_specs(),
    search_params = list(mutation_sd = c(0.01, 0.5)),
    n_samples     = 2L,
    objective     = "genetic_diversity",
    verbose       = FALSE
  )
  expect_true(is.numeric(result$score))
})

# ── 16. search_random: sampled mutation_sd values are within the specified range
test_that("search_random() samples mutation_sd within the specified range", {
  skip_no_julia()
  result <- search_random(
    specs_base    = .tiny_specs(),
    search_params = list(mutation_sd = c(0.01, 0.5)),
    n_samples     = 3L,
    objective     = "genetic_diversity",
    verbose       = FALSE
  )
  sl <- attr(result, "specs_list")
  sampled_vals <- vapply(sl, function(s) s$mutation_sd, numeric(1L))
  expect_true(all(sampled_vals >= 0.01 & sampled_vals <= 0.5),
              info = paste("Out-of-range values:", paste(sampled_vals, collapse = ", ")))
})
