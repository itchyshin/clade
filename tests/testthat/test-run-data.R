# Tests for get_run_data() and get_genome_data(). These operate on the env
# list returned by run_alife(), but the functions themselves are pure R and
# can be exercised against mock fixtures that match the Julia-side layout.
# No Julia session is required, so these tests always run.

library(testthat)

# ── Mock fixtures ────────────────────────────────────────────────────────────

# The Julia Dict returned in env$progress maps each statistic name to a
# Vector of length max_ticks. `as.data.frame(lapply(lst, unlist))` converts
# this into a tidy data frame in get_run_data(); the mock already satisfies
# that layout.
.mock_progress <- function(n = 5L) {
  list(
    t                      = seq_len(n),
    n_agents               = as.integer(seq(10, 15, length.out = n)),
    n_births               = rep(1L, n),
    n_deaths               = rep(0L, n),
    n_starvations          = rep(0L, n),
    n_age_deaths           = rep(0L, n),
    mean_energy            = seq(100, 90, length.out = n),
    sd_energy              = rep(10.0, n),
    mean_age               = seq(1, n, length.out = n),
    sd_age                 = rep(0.5, n),
    mean_body_size         = rep(1.0, n),
    sd_body_size           = rep(0.0, n),
    genetic_diversity      = seq(0.1, 0.2, length.out = n),
    n_species              = rep(1L, n),
    mean_cooperation_level = rep(0.3, n),
    mean_immune_strength   = rep(0.3, n),
    sd_immune_strength     = rep(0.05, n),
    mean_metabolic_rate    = rep(1.0, n),
    mean_learning_rate     = rep(0.01, n),
    mean_prior_sigma       = rep(0.0, n),
    grass_coverage         = rep(0.5, n),
    n_infected             = rep(0L, n),
    n_new_infections       = rep(0L, n),
    n_altruistic_acts      = rep(0L, n),
    n_shelters_built       = rep(0L, n),
    n_cooperation_acts     = rep(0L, n),
    n_dispersal_events     = rep(0L, n)
  )
}

.mock_deaths <- function(n = 3L) {
  list(
    id            = seq_len(n),
    t             = rep(1L, n),
    age           = rep(5L, n),
    energy        = rep(0.0, n),
    cause         = rep("starvation", n),
    body_size     = rep(1.0, n),
    num_offspring = rep(0L, n)
  )
}

.mock_env <- function(n_ticks = 5L, n_deaths = 3L, genome_log = list()) {
  list(
    agents     = list(),
    t          = n_ticks,
    specs      = default_specs(),
    progress   = .mock_progress(n_ticks),
    deaths     = .mock_deaths(n_deaths),
    genome_log = genome_log
  )
}

# ── get_run_data() ───────────────────────────────────────────────────────────

# 1. Accepts a valid env and returns a list with $ticks and $deaths
test_that("get_run_data() returns a list with $ticks and $deaths", {
  rd <- get_run_data(.mock_env())
  expect_type(rd, "list")
  expect_true(all(c("ticks", "deaths") %in% names(rd)))
})

# 2. $ticks is a data frame with nrow = max_ticks
test_that("get_run_data()$ticks is a data frame with the right dimensions", {
  rd <- get_run_data(.mock_env(n_ticks = 7L))
  expect_s3_class(rd$ticks, "data.frame")
  expect_equal(nrow(rd$ticks), 7L)
})

# 3. $deaths is a data frame with nrow = n_deaths
test_that("get_run_data()$deaths is a data frame with the right dimensions", {
  rd <- get_run_data(.mock_env(n_deaths = 4L))
  expect_s3_class(rd$deaths, "data.frame")
  expect_equal(nrow(rd$deaths), 4L)
})

# 4. $ticks carries all core population columns
test_that("get_run_data()$ticks has the documented column names", {
  rd <- get_run_data(.mock_env())
  required <- c("t", "n_agents", "n_births", "n_deaths", "n_starvations",
                "n_age_deaths", "mean_energy", "sd_energy", "mean_age",
                "mean_body_size", "genetic_diversity", "grass_coverage",
                "n_infected", "n_new_infections", "n_altruistic_acts",
                "n_shelters_built", "mean_prior_sigma")
  missing <- setdiff(required, names(rd$ticks))
  expect_equal(missing, character(0L),
               info = paste("missing columns:", paste(missing, collapse = ", ")))
})

# 5. $deaths has the documented column names
test_that("get_run_data()$deaths has the documented column names", {
  rd <- get_run_data(.mock_env())
  required <- c("id", "t", "age", "energy", "cause", "body_size",
                "num_offspring")
  missing <- setdiff(required, names(rd$deaths))
  expect_equal(missing, character(0L),
               info = paste("missing deaths columns:",
                            paste(missing, collapse = ", ")))
})

# 6. $ticks$t equals 1..n_ticks
test_that("get_run_data()$ticks$t is the tick sequence", {
  rd <- get_run_data(.mock_env(n_ticks = 6L))
  expect_equal(as.integer(rd$ticks$t), 1:6L)
})

# 7. Zero-row deaths are still returned as a data frame
test_that("get_run_data() returns a 0-row data frame when there are no deaths", {
  env <- .mock_env(n_deaths = 0L)
  rd  <- get_run_data(env)
  expect_s3_class(rd$deaths, "data.frame")
  expect_equal(nrow(rd$deaths), 0L)
})

# 8. Errors informatively when env is not a list
test_that("get_run_data() errors on non-list input", {
  expect_error(get_run_data(42L))
  expect_error(get_run_data("not a list"))
  expect_error(get_run_data(NULL))
})

# 9. Errors when env has no $progress
test_that("get_run_data() errors when env$progress is missing", {
  expect_error(get_run_data(list(deaths = .mock_deaths())))
})

# 10. Errors when env has no $deaths
test_that("get_run_data() errors when env$deaths is missing", {
  expect_error(get_run_data(list(progress = .mock_progress())))
})

# ── get_genome_data() ────────────────────────────────────────────────────────

# 11. get_genome_data() returns a list with the documented fields
test_that("get_genome_data() returns a list with $genomes/$heterozygosity/$fst", {
  g <- get_genome_data(.mock_env())
  expect_type(g, "list")
  expect_true(all(c("genomes", "heterozygosity", "fst") %in% names(g)))
})

# 12. Empty genome_log means $genomes is NULL
test_that("get_genome_data() returns genomes = NULL when genome_log is empty", {
  g <- get_genome_data(.mock_env(genome_log = list()))
  expect_null(g$genomes)
})

# 13. Non-empty genome_log is passed through
test_that("get_genome_data() returns the genome_log when non-empty", {
  m1 <- matrix(runif(6), 2, 3)
  m2 <- matrix(runif(6), 2, 3)
  g  <- get_genome_data(.mock_env(genome_log = list(m1, m2)))
  expect_length(g$genomes, 2L)
  expect_equal(g$genomes[[1]], m1)
  expect_equal(g$genomes[[2]], m2)
})

# 14. Default heterozygosity / fst fields are numeric(0) (empty numeric)
test_that("get_genome_data() placeholders are numeric(0)", {
  g <- get_genome_data(.mock_env())
  expect_type(g$heterozygosity, "double")
  expect_equal(length(g$heterozygosity), 0L)
  expect_type(g$fst, "double")
  expect_equal(length(g$fst), 0L)
})

# 15. get_genome_data() errors when env is not a list
test_that("get_genome_data() errors on non-list input", {
  expect_error(get_genome_data(42L))
  expect_error(get_genome_data("x"))
})
