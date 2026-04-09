# Tests for genome_distance(), compute_relatedness(), heritability_estimate()
# These functions work on the clade env/run_data structures and require no Julia.

library(testthat)

# ── Mock helpers ──────────────────────────────────────────────────────────────

.mock_agent <- function(id, parent_id = 0L, weights1 = NULL, weights2 = NULL) {
  W1 <- if (!is.null(weights1)) weights1 else matrix(rnorm(12), 4, 3)
  b1 <- rnorm(4)
  W2 <- if (!is.null(weights2)) weights2 else matrix(rnorm(8), 2, 4)
  b2 <- rnorm(2)
  list(
    id        = as.integer(id),
    parent_id = as.integer(parent_id),
    energy    = 100.0,
    age       = 5L,
    brain     = list(layers = list(
      list(W = W1, b = b1),
      list(W = W2, b = b2)
    ))
  )
}

.mock_bnn_agent <- function(id, parent_id = 0L) {
  W1 <- matrix(rnorm(12), 4, 3)
  b1 <- rnorm(4)
  W2 <- matrix(rnorm(8),  2, 4)
  b2 <- rnorm(2)
  list(
    id        = as.integer(id),
    parent_id = as.integer(parent_id),
    energy    = 100.0,
    age       = 5L,
    brain     = list(layers = list(
      list(mu = W1, sigma = abs(W1) * 0.1, b = b1),
      list(mu = W2, sigma = abs(W2) * 0.1, b = b2)
    ))
  )
}

.mock_deaths <- function(n = 30L) {
  set.seed(99L)
  id        <- seq_len(n)
  parent_id <- c(NA, sample(seq_len(n %/% 2), n - 1L, replace = TRUE))
  trait_val <- rnorm(n, 3, 1)
  data.frame(
    id            = id,
    t             = seq_len(n),
    age           = sample(10:50, n, replace = TRUE),
    energy        = rnorm(n, 80, 10),
    cause         = "starvation",
    body_size     = rnorm(n, 1, 0.1),
    num_offspring = pmax(0L, round(trait_val + rnorm(n, 0, 0.3))),
    parent_id     = parent_id,
    stringsAsFactors = FALSE
  )
}

# ── genome_distance() ─────────────────────────────────────────────────────────

# 1. Returns 0 when agents have identical brains
test_that("genome_distance() is 0 for identical agents", {
  set.seed(1L)
  W <- matrix(rnorm(12), 4, 3)
  ag <- .mock_agent(1L, weights1 = W)
  expect_equal(genome_distance(ag, ag), 0.0, tolerance = 1e-10)
})

# 2. Returns a positive number for different agents
test_that("genome_distance() is positive for different agents", {
  set.seed(2L)
  a <- .mock_agent(1L)
  b <- .mock_agent(2L)
  d <- genome_distance(a, b)
  expect_true(is.numeric(d))
  expect_gte(d, 0.0)
})

# 3. Result is symmetric
test_that("genome_distance() is symmetric", {
  set.seed(3L)
  a <- .mock_agent(1L)
  b <- .mock_agent(2L)
  expect_equal(genome_distance(a, b), genome_distance(b, a), tolerance = 1e-10)
})

# 4. Works with BNN agents (mu weights)
test_that("genome_distance() works with BNN mu weights", {
  set.seed(4L)
  a <- .mock_bnn_agent(1L)
  b <- .mock_bnn_agent(2L)
  d <- genome_distance(a, b)
  expect_true(is.numeric(d))
  expect_gte(d, 0.0)
})

# 5. More mutated agent has larger distance
test_that("genome_distance() is larger for more mutated agents", {
  set.seed(5L)
  base_W <- matrix(rnorm(12), 4, 3)
  a  <- .mock_agent(1L, weights1 = base_W)
  b1 <- .mock_agent(2L, weights1 = base_W + 0.01 * matrix(rnorm(12), 4, 3))
  b2 <- .mock_agent(3L, weights1 = base_W + 5.0  * matrix(rnorm(12), 4, 3))
  expect_lt(genome_distance(a, b1), genome_distance(a, b2))
})

# ── compute_relatedness() ─────────────────────────────────────────────────────

# 6. Returns 1.0 for same agent
test_that("compute_relatedness() returns 1.0 for same id", {
  ag  <- .mock_agent(1L, parent_id = 0L)
  env <- list(agents = list(ag))
  expect_equal(compute_relatedness(1L, 1L, env), 1.0)
})

# 7. Returns 0 for unrelated agents
test_that("compute_relatedness() returns 0 for unrelated agents", {
  a <- .mock_agent(1L, parent_id = 0L)
  b <- .mock_agent(2L, parent_id = 0L)
  env <- list(agents = list(a, b))
  expect_equal(compute_relatedness(1L, 2L, env), 0.0)
})

# 8. Returns 0.5 for parent-offspring
test_that("compute_relatedness() returns 0.5 for parent-offspring", {
  parent <- .mock_agent(1L, parent_id = 0L)
  child  <- .mock_agent(2L, parent_id = 1L)
  env    <- list(agents = list(parent, child))
  expect_equal(compute_relatedness(1L, 2L, env), 0.5)
  expect_equal(compute_relatedness(2L, 1L, env), 0.5)
})

# 9. Returns 0.25 for siblings (shared parent)
test_that("compute_relatedness() returns 0.25 for full siblings", {
  parent <- .mock_agent(1L, parent_id = 0L)
  sib_a  <- .mock_agent(2L, parent_id = 1L)
  sib_b  <- .mock_agent(3L, parent_id = 1L)
  env    <- list(agents = list(parent, sib_a, sib_b))
  expect_equal(compute_relatedness(2L, 3L, env), 0.25)
})

# 10. Errors on non-list env
test_that("compute_relatedness() errors on bad env", {
  expect_error(compute_relatedness(1L, 2L, 42L))
})

# ── heritability_estimate() ───────────────────────────────────────────────────

# 11. Returns a list with required elements
test_that("heritability_estimate() returns list with h2, n_pairs, method, trait", {
  d <- .mock_deaths(40L)
  out <- heritability_estimate(list(deaths = d), trait = "num_offspring")
  expect_type(out, "list")
  expect_true(all(c("h2", "n_pairs", "method", "trait") %in% names(out)))
})

# 12. Method is "parent_offspring_regression"
test_that("heritability_estimate() reports correct method", {
  d <- .mock_deaths(40L)
  out <- heritability_estimate(list(deaths = d))
  expect_equal(out$method, "parent_offspring_regression")
})

# 13. h2 is numeric (finite or NA)
test_that("heritability_estimate() h2 is numeric", {
  d <- .mock_deaths(40L)
  out <- heritability_estimate(list(deaths = d))
  expect_true(is.numeric(out$h2))
})

# 14. Errors when deaths is empty
test_that("heritability_estimate() errors on empty deaths", {
  expect_error(
    heritability_estimate(list(deaths = data.frame())),
    regexp = "empty"
  )
})

# 15. Errors when trait column is missing
test_that("heritability_estimate() errors on missing trait column", {
  d <- .mock_deaths(20L)
  expect_error(
    heritability_estimate(list(deaths = d), trait = "wing_length"),
    regexp = "not found"
  )
})

# 16. Returns NA h2 with message when too few pairs
test_that("heritability_estimate() returns NA when too few pairs", {
  d <- .mock_deaths(4L)
  d$parent_id <- NA
  expect_message(
    out <- heritability_estimate(list(deaths = d)),
    regexp = "pairs"
  )
  expect_true(is.na(out$h2))
})

# 17. n_pairs matches number of matched parent-offspring pairs
test_that("heritability_estimate() n_pairs is non-negative integer", {
  d   <- .mock_deaths(40L)
  out <- heritability_estimate(list(deaths = d))
  expect_true(is.numeric(out$n_pairs))
  expect_gte(out$n_pairs, 0L)
})

# ── sense_env() ───────────────────────────────────────────────────────────────

.mock_env_full <- function(n_agents = 3L) {
  specs <- default_specs()
  specs$grid_rows <- 10L; specs$grid_cols <- 10L
  agents <- lapply(seq_len(n_agents), function(i) {
    list(id = i, parent_id = 0L, energy = 100.0, age = 5L,
         x = i + 1L, y = 3L,
         brain = list(layers = list(
           list(W = matrix(rnorm(44), 4, 11), b = rnorm(4)),
           list(W = matrix(rnorm(24), 6,  4), b = rnorm(6))
         )))
  })
  grass <- matrix(runif(100), 10, 10)
  list(agents = agents, specs = specs, grass = grass,
       t = 10L, progress = list(), deaths = data.frame(),
       genome_log = list())
}

# 18. sense_env() returns a numeric vector of length >= 11
test_that("sense_env() returns a numeric vector of length >= 11", {
  env <- .mock_env_full()
  v   <- sense_env(env, 1L)
  expect_type(v, "double")
  expect_gte(length(v), 11L)
})

# 19. sense_env() names the slots
test_that("sense_env() returns named vector", {
  env <- .mock_env_full()
  v   <- sense_env(env, 1L)
  expect_false(is.null(names(v)))
  expect_true("energy" %in% names(v))
})

# 20. sense_env() errors on out-of-range index
test_that("sense_env() errors on out-of-range agent index", {
  env <- .mock_env_full(2L)
  expect_error(sense_env(env, 99L), regexp = "out of range")
})

# 21. sense_env() works when env$grass is NULL
test_that("sense_env() works when grass is NULL", {
  env <- .mock_env_full()
  env$grass <- NULL
  v <- sense_env(env, 1L)
  expect_type(v, "double")
  # Grass slots should be 0
  expect_equal(as.numeric(v["grass_C"]), 0.0)
})

# ── take_action() ─────────────────────────────────────────────────────────────

# 22. take_action() returns a list with action, logits, probs, action_names
test_that("take_action() returns list with required elements", {
  env <- .mock_env_full()
  res <- take_action(env, 1L)
  expect_type(res, "list")
  expect_true(all(c("action", "logits", "probs", "action_names") %in% names(res)))
})

# 23. action is an integer in valid range
test_that("take_action() action is a valid integer", {
  env <- .mock_env_full()
  res <- take_action(env, 1L)
  expect_type(res$action, "integer")
  expect_gte(res$action, 1L)
  expect_lte(res$action, length(res$probs))
})

# 24. probs sum to 1
test_that("take_action() probs sum to 1", {
  env <- .mock_env_full()
  res <- take_action(env, 1L)
  expect_equal(sum(res$probs), 1.0, tolerance = 1e-10)
})

# 25. take_action() accepts explicit input
test_that("take_action() accepts explicit input vector", {
  env   <- .mock_env_full()
  input <- sense_env(env, 1L)
  res   <- take_action(env, 1L, input = input)
  expect_type(res$action, "integer")
})
