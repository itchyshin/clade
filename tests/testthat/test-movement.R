# Tests for get_movement_data(), plot_movement(), and plot_run_movie().
#
# The extractor and plot functions are pure R and can be exercised
# against mock fixtures that mirror the JuliaConnectoR-side layout
# (Julia Dict{String,Vector} arrives on the R side as a plain named
# list of typed vectors after JuliaConnectoR::juliaGet()).
#
# Mock blocks run unconditionally in CI (where CLADE_SKIP_JULIA_TESTS
# is set to "true" by tests.yaml). The final block below covers the
# Julia round-trip; it is gated with skip_no_julia() and runs only
# when Julia is available locally.

library(testthat)

# ── Mock fixtures ────────────────────────────────────────────────────────────

.mock_movement_log <- function(n = 12L, n_agents = 3L) {
  # Repeat each agent's id across the n rows to mimic a real per-tick log.
  # `tick` cycles 1..(n/n_agents); positions drift with age so the
  # column-type assertions have realistic content.
  agent_ids <- rep(seq_len(n_agents), length.out = n)
  ticks     <- rep(seq_len(ceiling(n / n_agents)), each = n_agents)[seq_len(n)]
  list(
    tick   = as.integer(ticks),
    id     = as.integer(agent_ids),
    x      = as.integer((seq_len(n) - 1L) %% 10L + 1L),
    y      = as.integer((seq_len(n) - 1L) %% 10L + 1L),
    age    = as.integer(seq_len(n)),
    energy = as.numeric(100 - seq_len(n)),
    alive  = rep(c(TRUE, TRUE, FALSE), length.out = n)
  )
}

.mock_env_movement <- function(mlog = .mock_movement_log(), t_final = 4L) {
  list(
    agents       = list(),
    t            = t_final,
    specs        = default_specs(),
    progress     = list(),
    deaths       = list(),
    genome_log   = list(),
    movement_log = mlog
  )
}

# ── get_movement_data() — mock-based ────────────────────────────────────────

test_that("get_movement_data() returns a data.frame with the documented columns", {
  env <- .mock_env_movement()
  md  <- get_movement_data(env)
  expect_s3_class(md, "data.frame")
  expect_named(md,
               c("t", "id", "x", "y", "age", "energy", "alive"),
               ignore.order = TRUE)
})

test_that("get_movement_data() row count equals length(mlog$tick)", {
  mlog <- .mock_movement_log(n = 24L, n_agents = 4L)
  env  <- .mock_env_movement(mlog = mlog)
  md   <- get_movement_data(env)
  expect_equal(nrow(md), length(mlog$tick))
})

test_that("get_movement_data() preserves column types (int / double / logical)", {
  md <- get_movement_data(.mock_env_movement())
  expect_true(is.integer(md$t))
  expect_true(is.integer(md$id))
  expect_true(is.integer(md$x))
  expect_true(is.integer(md$y))
  expect_true(is.integer(md$age))
  expect_true(is.numeric(md$energy))
  expect_true(is.logical(md$alive))
})

test_that("get_movement_data() returns NULL when movement_log is NULL", {
  env <- .mock_env_movement(mlog = NULL)
  expect_null(get_movement_data(env))
})

test_that("get_movement_data() returns a zero-row data.frame for an empty log", {
  empty_log <- list(tick = integer(0), id = integer(0),
                    x = integer(0), y = integer(0), age = integer(0),
                    energy = numeric(0), alive = logical(0))
  env <- .mock_env_movement(mlog = empty_log)
  md  <- get_movement_data(env)
  expect_s3_class(md, "data.frame")
  expect_equal(nrow(md), 0L)
  expect_named(md,
               c("t", "id", "x", "y", "age", "energy", "alive"),
               ignore.order = TRUE)
})

test_that("get_movement_data() errors on non-list input", {
  expect_error(get_movement_data(42L), regexp = "is.list")
  expect_error(get_movement_data("nope"), regexp = "is.list")
})

test_that("get_movement_data() returns NULL when required columns are missing", {
  # Simulate an unexpected proxy-shape (e.g. Julia contract drift).
  partial <- list(tick = 1:3, id = 1:3, x = 1:3)  # missing y/age/energy/alive
  env <- .mock_env_movement(mlog = partial)
  expect_null(get_movement_data(env))
})

# ── plot_movement() — mock-based ─────────────────────────────────────────────

test_that("plot_movement() returns a ggplot for a valid movement data frame", {
  md <- get_movement_data(.mock_env_movement())
  p  <- plot_movement(md)
  expect_s3_class(p, "ggplot")
})

test_that("plot_movement(NULL) returns a placeholder ggplot rather than erroring", {
  p <- plot_movement(NULL)
  expect_s3_class(p, "ggplot")
})

test_that("plot_movement() rejects an unknown colour_by via match.arg()", {
  md <- get_movement_data(.mock_env_movement())
  expect_error(plot_movement(md, colour_by = "bogus"))
})

test_that("plot_movement() with `tick` argument filters to that tick", {
  md <- get_movement_data(.mock_env_movement())
  target_tick <- unique(md$t)[1L]
  p <- plot_movement(md, tick = target_tick)
  # plot data is set at plot level (geom inherits), so read p$data.
  expect_true(all(p$data$t == target_tick))
  expect_equal(nrow(p$data), sum(md$t == target_tick))
})

test_that("plot_movement() with `tick` for an absent tick returns a placeholder", {
  md <- get_movement_data(.mock_env_movement())
  p  <- plot_movement(md, tick = 9999L)
  expect_s3_class(p, "ggplot")
})

test_that("plot_movement() accepts each documented colour_by value", {
  md <- get_movement_data(.mock_env_movement())
  for (cb in c("energy", "age", "id", "alive")) {
    expect_s3_class(plot_movement(md, colour_by = cb), "ggplot")
  }
})

test_that("plot_movement() rejects non-data.frame md that is not NULL", {
  expect_error(plot_movement(42L), regexp = "data.frame")
})

# ── plot_run_movie() — mock-based + optional gganimate ──────────────────────

test_that("plot_run_movie(NULL) returns a placeholder without calling gganimate", {
  p <- plot_run_movie(NULL)
  expect_s3_class(p, "ggplot")
})

test_that("plot_run_movie() returns a gganim object when gganimate is available", {
  skip_if_not_installed("gganimate")
  md <- get_movement_data(.mock_env_movement())
  mv <- plot_run_movie(md)
  expect_s3_class(mv, "gganim")
})

# ── Julia round-trip (skipped in CI; runs when Julia is available) ──────────

test_that("get_movement_data() round-trips through run_alife() with log_movement = TRUE", {
  skip_no_julia()

  s <- default_specs()
  s$grid_rows           <- 10L
  s$grid_cols           <- 10L
  s$n_agents_init       <- 5L
  s$max_ticks           <- 10L
  s$max_agents          <- 50L
  s$random_seed         <- 42L
  s$log_movement        <- TRUE
  s$log_movement_freq   <- 2L

  env <- suppressWarnings(run_alife(s, verbose = FALSE))
  expect_false(is.null(env$movement_log))

  md <- get_movement_data(env)
  expect_s3_class(md, "data.frame")
  expect_named(md,
               c("t", "id", "x", "y", "age", "energy", "alive"),
               ignore.order = TRUE)
  # freq = 2L → every recorded tick is even.
  if (nrow(md) > 0L) {
    expect_true(all(md$t %% 2L == 0L))
  }
})

test_that("run_alife() with log_movement = FALSE surfaces NULL movement_log", {
  skip_no_julia()

  s <- default_specs()
  s$grid_rows      <- 10L
  s$grid_cols      <- 10L
  s$n_agents_init  <- 5L
  s$max_ticks      <- 10L
  s$max_agents     <- 50L
  s$random_seed    <- 42L
  # log_movement not set → default OFF on the Julia side.

  env <- suppressWarnings(run_alife(s, verbose = FALSE))
  expect_null(env$movement_log)
  expect_null(get_movement_data(env))
})

test_that("run_alife() errors when log_movement_freq is not strictly positive", {
  skip_no_julia()

  s <- default_specs()
  s$grid_rows          <- 10L
  s$grid_cols          <- 10L
  s$n_agents_init      <- 5L
  s$max_ticks          <- 5L
  s$max_agents         <- 50L
  s$log_movement       <- TRUE
  s$log_movement_freq  <- 0L

  expect_error(suppressWarnings(run_alife(s, verbose = FALSE)))
})
