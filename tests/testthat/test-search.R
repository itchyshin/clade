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
test_that("search_map_elites() with 10 iterations fills at least one cell", {
  skip_no_julia()
  result <- search_map_elites(
    specs_base   = .tiny_specs(grass_rate = 0.5),
    archive_dims = list(genetic_diversity = seq(0, 0.5, by = 0.1)),
    n_iterations = 10L,
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

.tiny_cmaes <- function() {
  search_cmaes(
    specs_base   = .tiny_specs(),
    objective    = "genetic_diversity",
    params       = c("grass_rate", "mutation_sd"),
    n_iterations = 2L,
    popsize      = 4L,    # small but above mu=2 minimum
    verbose      = FALSE
  )
}

# ── 7. search_cmaes: tiny run returns the documented structure ───────────────
test_that("search_cmaes() returns specs/score/history list", {
  skip_no_julia()
  result <- .tiny_cmaes()
  expect_type(result, "list")
  expect_named(result, c("specs", "score", "history"))
})

# ── 8. search_cmaes: returned specs round-trips through .validate_specs() ────
test_that("search_cmaes() result$specs passes .validate_specs()", {
  skip_no_julia()
  result <- .tiny_cmaes()
  expect_true(is.list(result$specs))
  expect_silent(clade:::.validate_specs(result$specs))
})

# ── 9. search_cmaes: result$score is finite and numeric ──────────────────────
test_that("search_cmaes() result$score is finite numeric", {
  skip_no_julia()
  result <- .tiny_cmaes()
  expect_true(is.numeric(result$score))
  expect_length(result$score, 1L)
  expect_true(is.finite(result$score))
})

# ── 9b. search_cmaes: history has rows and expected columns (pure-R CMA-ES) ──
test_that("search_cmaes() history has rows and correct columns (no GA needed)", {
  skip_no_julia()
  result <- .tiny_cmaes()
  expect_s3_class(result$history, "data.frame")
  expect_gte(nrow(result$history), 1L)
  for (nm in c("generation", "evals", "best_score", "mean_score", "sigma"))
    expect_true(nm %in% names(result$history),
                info = sprintf("history missing column '%s'", nm))
})

# ── 9c. search_cmaes: bad params raise descriptive error ─────────────────────
test_that("search_cmaes() raises error for non-positive parameter value", {
  expect_error(
    search_cmaes(
      .tiny_specs(grass_rate = 0),
      params       = "grass_rate",
      n_iterations = 1L,
      verbose      = FALSE
    ),
    regexp = "grass_rate"
  )
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

# ── search_viability: input validation (no Julia needed) ─────────────────────

test_that("search_viability() rejects an unknown param_x", {
  expect_error(
    search_viability(default_specs(), "not_a_param", c(0.1, 0.2),
                     verbose = FALSE),
    regexp = "not_a_param"
  )
})

test_that("search_viability() rejects non-numeric values_x", {
  expect_error(
    search_viability(default_specs(), "grass_rate",
                     values_x = "oops", verbose = FALSE)
  )
})

test_that("search_viability() rejects an unknown param_y", {
  expect_error(
    search_viability(default_specs(), "grass_rate", c(0.1, 0.2),
                     param_y  = "bad_param",
                     values_y = c(1, 2),
                     verbose  = FALSE),
    regexp = "bad_param"
  )
})

test_that("search_viability() returns list with $data and $map", {
  skip_no_julia()
  result <- search_viability(
    .tiny_specs(),
    param_x  = "grass_rate",
    values_x = c(0.1, 0.3),
    n_reps   = 1L,
    verbose  = FALSE
  )
  expect_type(result, "list")
  expect_named(result, c("data", "map"))
  expect_s3_class(result$data, "data.frame")
  expect_true("viability" %in% names(result$data))
  expect_true("grass_rate" %in% names(result$data))
})

test_that("search_viability() 2D grid has both param columns", {
  skip_no_julia()
  result <- search_viability(
    .tiny_specs(),
    param_x  = "grass_rate",  values_x = c(0.1, 0.3),
    param_y  = "mutation_sd", values_y = c(0.01, 0.1),
    n_reps   = 1L,
    verbose  = FALSE
  )
  expect_true("grass_rate"  %in% names(result$data))
  expect_true("mutation_sd" %in% names(result$data))
  expect_equal(nrow(result$data), 4L)   # 2 x 2 grid
})

# ── Objective functions: structural tests with mock envs ─────────────────────

# Build a minimal mock env so objectives can be tested without Julia.
# get_run_data(env) returns list(ticks = as.data.frame(lapply(env$progress, unlist))).
.mock_env <- function(n_ticks = 30L, wing = NULL, helper = NULL,
                       front_disp = NULL, rear_disp = NULL,
                       n_front = NULL, n_alive = NULL) {
  progress <- list(
    n_agents           = rep(10L, n_ticks),
    mean_wing_size     = if (!is.null(wing)) wing else rep(NA_real_, n_ticks),
    n_ground_agents    = rep(5L,  n_ticks),
    n_shrub_agents     = rep(3L,  n_ticks),
    n_canopy_agents    = rep(2L,  n_ticks),
    mean_helper_tendency  = if (!is.null(helper)) helper else rep(NA_real_, n_ticks),
    n_iffolk_transfers = rep(2L,  n_ticks),
    mean_front_dispersal  = if (!is.null(front_disp)) front_disp else
      rep(NA_real_, n_ticks),
    mean_rear_dispersal   = if (!is.null(rear_disp)) rear_disp else
      rep(NA_real_, n_ticks),
    n_front_agents     = if (!is.null(n_front)) n_front else rep(3L, n_ticks)
  )
  if (!is.null(n_alive)) progress$n_agents <- n_alive
  structure(
    list(
      agents   = vector("list", 10L),
      t        = n_ticks,
      specs    = list(n_agents_init = 10L),
      progress = progress,
      deaths   = list(id = integer(0L), t = integer(0L), age = integer(0L),
                      energy = numeric(0L), cause = character(0L),
                      body_size = numeric(0L), num_offspring = integer(0L))
    ),
    class = "clade_env"
  )
}

test_that("objective_complex_landscape() returns a finite scalar for a mock env", {
  env <- .mock_env(wing = seq(0.1, 0.5, length.out = 30L))
  val <- objective_complex_landscape(env)
  expect_length(val, 1L)
  expect_true(is.finite(val))
})

test_that("objective_complex_landscape() returns -Inf for an extinct env", {
  env <- .mock_env(n_alive = rep(0L, 30L))
  expect_equal(objective_complex_landscape(env), -Inf)
})

test_that("objective_spatial_sorting() returns -Inf for extinct env", {
  env <- .mock_env(n_alive = rep(0L, 30L),
                   front_disp = rep(0.5, 30L),
                   rear_disp  = rep(0.3, 30L))
  expect_equal(objective_spatial_sorting(env), -Inf)
})

test_that("objective_spatial_sorting() returns numeric for valid mock env", {
  env <- .mock_env(front_disp = seq(0.3, 0.7, length.out = 30L),
                   rear_disp  = rep(0.3, 30L),
                   n_front    = rep(3L, 30L))
  val <- objective_spatial_sorting(env)
  expect_length(val, 1L)
  expect_true(is.numeric(val))
})

test_that("objective_iffolk() returns -Inf for extinct env", {
  env <- .mock_env(n_alive = rep(0L, 30L),
                   helper = rep(0.2, 30L))
  expect_equal(objective_iffolk(env), -Inf)
})

test_that("objective_iffolk() returns numeric for valid mock env", {
  env <- .mock_env(helper = seq(0.1, 0.5, length.out = 30L))
  val <- objective_iffolk(env)
  expect_length(val, 1L)
  expect_true(is.numeric(val))
})
