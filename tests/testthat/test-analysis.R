# Tests for the analysis helpers in R/analysis.R. These functions are pure R
# and operate on the tidy `run_data` list returned by get_run_data(); no
# Julia session is required, so the tests always run.

library(testthat)

# ── Mock fixtures ────────────────────────────────────────────────────────────

# Matches the layout of the data frame produced by get_run_data()$ticks. The
# trait columns carry mild temporal structure so the lag-1 autocorrelation is
# well defined and non-degenerate.
.mock_ticks <- function(n = 20L) {
  set.seed(42L)
  data.frame(
    t                      = seq_len(n),
    n_agents               = rep(20L, n),
    n_births               = rep(2L,  n),
    n_deaths               = rep(1L,  n),
    n_starvations          = rep(0L,  n),
    n_age_deaths           = rep(0L,  n),
    mean_energy            = 100 + rnorm(n, 0, 5),
    sd_energy              = rep(10, n),
    mean_age               = rep(5, n),
    sd_age                 = rep(2, n),
    mean_body_size         = 1 + cumsum(rnorm(n, 0, 0.01)),
    sd_body_size           = rep(0.1, n),
    genetic_diversity      = seq(0.1, 0.3, length.out = n),
    n_species              = rep(1L, n),
    mean_cooperation_level = rep(0.5, n),
    mean_immune_strength   = rep(0.3, n) + rnorm(n, 0, 0.01),
    sd_immune_strength     = rep(0.05, n),
    mean_metabolic_rate    = rep(1, n),
    mean_learning_rate     = rep(0.01, n),
    mean_prior_sigma       = seq(0.5, 0.1, length.out = n),
    grass_coverage         = rep(0.4, n),
    n_infected             = rep(0L, n),
    n_new_infections       = rep(0L, n),
    n_altruistic_acts      = rep(0L, n),
    n_shelters_built       = rep(0L, n),
    n_cooperation_acts     = rep(0L, n)
  )
}

.mock_rd <- function(n = 20L) {
  list(ticks = .mock_ticks(n), deaths = data.frame())
}

# ── estimate_heritability() ──────────────────────────────────────────────────

# 1. Returns the documented structure with $h2 in [-1, 1]
test_that("estimate_heritability() returns h2 in [-1, 1] for body_size", {
  rd  <- .mock_rd()
  out <- estimate_heritability(rd, trait = "body_size")
  expect_type(out, "list")
  expect_true(all(c("h2", "method", "trait", "n", "note") %in% names(out)))
  expect_equal(out$method, "lag1_autocorrelation")
  expect_equal(out$trait,  "body_size")
  expect_equal(out$n,      nrow(rd$ticks) - 1L)
  expect_true(is.finite(out$h2))
  expect_gte(out$h2, -1)
  expect_lte(out$h2,  1)
})

# 2. Works with another trait column
test_that("estimate_heritability() works for immune_strength", {
  rd  <- .mock_rd()
  out <- estimate_heritability(rd, trait = "immune_strength")
  expect_equal(out$trait, "immune_strength")
  expect_true(is.finite(out$h2))
  expect_gte(out$h2, -1)
  expect_lte(out$h2,  1)
})

# 3. Errors informatively when the trait column is missing
test_that("estimate_heritability() errors on an unknown trait", {
  rd <- .mock_rd()
  expect_error(
    estimate_heritability(rd, trait = "wing_length"),
    regexp = "mean_wing_length"
  )
})

# 4. Errors on bad run_data
test_that("estimate_heritability() errors on a non-list run_data", {
  expect_error(estimate_heritability(42L, "body_size"))
  expect_error(estimate_heritability(list(), "body_size"))
})

# 5. Returns NA when the series has zero variance
test_that("estimate_heritability() returns NA for a flat series", {
  rd <- .mock_rd()
  rd$ticks$mean_body_size <- rep(1.0, nrow(rd$ticks))
  out <- estimate_heritability(rd, trait = "body_size")
  expect_true(is.na(out$h2))
})

# ── compute_ld() ─────────────────────────────────────────────────────────────

# 6. Returns a list with a $note character string and $ld = NULL
test_that("compute_ld() returns a stub with $ld and $note", {
  out <- compute_ld(.mock_rd())
  expect_type(out, "list")
  expect_true(all(c("ld", "note") %in% names(out)))
  expect_null(out$ld)
  expect_type(out$note, "character")
  expect_true(nzchar(out$note))
})

# ── species_tree() ───────────────────────────────────────────────────────────

# 7. Returns a list with a $note character string and $tree = NULL
test_that("species_tree() returns a stub with $tree and $note", {
  out <- species_tree(.mock_rd())
  expect_type(out, "list")
  expect_true(all(c("tree", "note") %in% names(out)))
  expect_null(out$tree)
  expect_type(out$note, "character")
  expect_true(nzchar(out$note))
})

# ── get_genome_data() smoke test on an empty genome_log ──────────────────────

# 8. get_genome_data() does not error on a minimal mock env with empty log
test_that("get_genome_data() handles an empty genome_log gracefully", {
  env <- list(genome_log = list())
  g   <- get_genome_data(env)
  expect_type(g, "list")
  expect_null(g$genomes)
})

# ── Additional tests ──────────────────────────────────────────────────────────

# 9. estimate_heritability() returns a list with named elements
test_that("estimate_heritability() return value has all required named elements", {
  out <- estimate_heritability(.mock_rd(), trait = "body_size")
  expect_true(all(c("h2", "method", "trait", "n", "note") %in% names(out)))
})

# 10. heritability estimate is numeric (finite or NA)
test_that("heritability estimate is numeric (finite or NA)", {
  out <- estimate_heritability(.mock_rd(), trait = "body_size")
  expect_true(is.numeric(out$h2))
})

# 11. compare_conditions() works when given two run_data lists
test_that("compare_conditions() accepts two run_data lists without error", {
  rd1 <- .mock_rd()
  rd2 <- .mock_rd()
  # compare_conditions may not exist yet; skip gracefully if absent.
  skip_if_not(existsFunction <- exists("compare_conditions",
                                       mode = "function",
                                       where = asNamespace("clade")),
              "compare_conditions not yet exported")
  expect_no_error(compare_conditions(rd1, rd2))
})

# 12. get_genome_data() returns a list with at least $genomes element
test_that("get_genome_data() returns a list with $genomes element", {
  env <- list(genome_log = list())
  g   <- get_genome_data(env)
  expect_true("genomes" %in% names(g))
})

# 13. genetic_diversity values are non-decreasing on a monotone mock series
test_that("genetic_diversity column in mock data changes across ticks", {
  tk <- .mock_ticks(n = 10L)
  # The mock uses seq(0.1, 0.3, ...) so it must have non-zero range.
  expect_gt(diff(range(tk$genetic_diversity)), 0)
})

# 14. estimate_heritability() note is a non-empty character string
test_that("estimate_heritability() note is a non-empty character string", {
  out <- estimate_heritability(.mock_rd(), trait = "body_size")
  expect_type(out$note, "character")
  expect_true(nzchar(out$note))
})

# 15. estimate_heritability() handles single-row ticks (too few for lag-1)
test_that("estimate_heritability() returns NA when ticks has < 3 rows", {
  rd <- .mock_rd(n = 2L)
  out <- estimate_heritability(rd, trait = "body_size")
  expect_true(is.na(out$h2))
})
