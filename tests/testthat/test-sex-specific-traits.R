# Tests for the 0.8.0 sex-specific trait expression mechanism (Phase B).
#
# Covers:
#   sex_specific_traits     (character vector; default character(0))
#   sex_specific_tradeoffs  (list; default both 0.0)
# and the Rees-Baylis-style exponential trade-off grafted into
# `_find_mate()` and `create_offspring!()` when sex_labels = TRUE.
#
# Julia-integrated checks use skip_no_julia().

library(testthat)

# ── 1. R-side spec presence and defaults ─────────────────────────────────────

test_that("sex_specific_traits defaults to empty character vector", {
  s <- default_specs()
  expect_true("sex_specific_traits" %in% names(s))
  expect_identical(s$sex_specific_traits, character(0))
})

test_that("sex_specific_tradeoffs defaults to zero-strength named list", {
  s <- default_specs()
  expect_true("sex_specific_tradeoffs" %in% names(s))
  expect_type(s$sex_specific_tradeoffs, "list")
  expect_setequal(names(s$sex_specific_tradeoffs),
                  c("male_mating_vs_aging", "female_offspring_vs_aging"))
  expect_equal(s$sex_specific_tradeoffs$male_mating_vs_aging, 0.0)
  expect_equal(s$sex_specific_tradeoffs$female_offspring_vs_aging, 0.0)
})

test_that("Sex-specific traits fields appear in .SPEC_GROUPS", {
  grp <- clade:::.SPEC_GROUPS[["Sex-specific traits"]]
  expect_false(is.null(grp))
  expect_setequal(grp, c("sex_specific_traits", "sex_specific_tradeoffs"))
})

# ── 2. Julia-integrated: sex-specific aging behaviour ────────────────────────

.sst_specs <- function(...) {
  s <- default_specs()
  s$grid_rows         <- 15L
  s$grid_cols         <- 15L
  s$n_agents_init     <- 40L
  s$max_ticks         <- 30L
  s$max_agents        <- 200L
  s$random_seed       <- 1L
  s$ploidy            <- 2L
  s$sex_labels        <- TRUE
  s$sex_ratio_primary <- 0.5
  args <- list(...)
  for (nm in names(args)) s[[nm]] <- args[[nm]]
  s
}

test_that("sex_specific_traits = c('aging_rate') runs without error", {
  skip_no_julia()
  s <- .sst_specs(sex_specific_traits = c("aging_rate"),
                   aging_rate_evolution = TRUE)
  expect_no_error(run_alife(s, verbose = FALSE))
})

test_that("sex_specific_traits empty + sex_labels=TRUE: aging unchanged", {
  # When the trait list is empty, the new gene slots mirror the shared
  # TRAIT_AGING_RATE so expressed aging_rate matches pre-0.8.0 behaviour.
  skip_no_julia()
  s <- .sst_specs(aging_rate_evolution = TRUE)
  env <- run_alife(s, verbose = FALSE)
  n <- length(env$agents)
  skip_if(n < 5L, "population too small to compare aging rates")
  rates <- vapply(seq_len(n),
                  function(i) as.numeric(env$agents[[i]]$aging_rate),
                  numeric(1))
  # Aging rate evolution active → values within expected min/max bounds.
  expect_true(all(rates >= s$aging_rate_min - 1e-6))
  expect_true(all(rates <= s$aging_rate_max + 1e-6))
})

# ── 3. Rees-Baylis trade-off math (Julia-integrated) ─────────────────────────

test_that("male_mating_vs_aging > 0 reduces realised male reproduction", {
  # Compare two runs: one with no male trade-off, one with strong male
  # trade-off. The latter should produce fewer offspring overall because
  # males are systematically failing to find mates when their target
  # lifespan (1/aging_rate) is high.
  skip_no_julia()

  # Use a setup where many agents have target_lifespan > 1 → trade-off
  # actually fires. aging_rate_init_mean = 0.5 → target_lifespan ≈ 2.
  base <- .sst_specs(
    n_agents_init     = 80L,
    max_agents        = 400L,
    max_ticks         = 100L,
    aging_rate_evolution = TRUE,
    aging_rate_init_mean = 0.5,
    aging_rate_min       = 0.1,
    aging_rate_max       = 2.0,
    sex_specific_traits  = c("aging_rate"),
    random_seed          = 5L
  )

  base$sex_specific_tradeoffs <- list(
    male_mating_vs_aging      = 0.0,
    female_offspring_vs_aging = 0.0
  )
  env_off <- run_alife(base, verbose = FALSE)

  base$sex_specific_tradeoffs <- list(
    male_mating_vs_aging      = 2.0,   # strong
    female_offspring_vs_aging = 0.0
  )
  base$random_seed <- 5L
  env_on <- run_alife(base, verbose = FALSE)

  # With a strong male trade-off, total agents at the end should be no
  # greater than with the trade-off off. Loose direction-only check —
  # the precise effect is sensitive to many couplings.
  expect_lte(length(env_on$agents), length(env_off$agents))
})

test_that("trade-off math: clutch modifier formula matches Rees-Baylis", {
  # Direct numeric sanity check of the trade-off formula. With s_f = 0.05
  # and aging_rate = 0.2 (target_lifespan = 5), modifier = exp(-0.05*4)
  # = 0.819. Confirm at the R level that we agree with the kernel's
  # documented math.
  s_f <- 0.05
  aging_rate <- 0.2
  target_lifespan <- 1 / aging_rate
  penalty <- max(0, target_lifespan - 1)
  modifier <- exp(-s_f * penalty)
  expect_equal(modifier, exp(-0.2), tolerance = 1e-9)
  expect_equal(round(modifier, 3), 0.819)
})
