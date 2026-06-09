# Tests for the 0.8.0 Phase A sex-foundation feature.
#
# Covers three new specs:
#   sex_labels         (logical; default FALSE)
#   sex_determination  (character; default "random")
#   sex_ratio_primary  (numeric in [0, 1]; default 0.5)
#
# and the per-Agent `sex` field (0 = female, 1 = male) introduced by
# inst/julia/src/types.jl. Julia-integrated tests use skip_no_julia().

library(testthat)

# ── 1. R-side spec presence and defaults ─────────────────────────────────────

test_that("sex_labels is present and defaults to FALSE", {
  s <- default_specs()
  expect_true("sex_labels" %in% names(s))
  expect_false(s$sex_labels)
})

test_that("sex_determination is present and defaults to 'random'", {
  s <- default_specs()
  expect_true("sex_determination" %in% names(s))
  expect_identical(s$sex_determination, "random")
})

test_that("sex_ratio_primary is present, in [0, 1], and defaults to 0.5", {
  s <- default_specs()
  expect_true("sex_ratio_primary" %in% names(s))
  expect_equal(s$sex_ratio_primary, 0.5)
  expect_gte(s$sex_ratio_primary, 0.0)
  expect_lte(s$sex_ratio_primary, 1.0)
})

test_that("Sex foundation fields are grouped under 'Sex foundation' in .SPEC_GROUPS", {
  # .SPEC_GROUPS lives in R/utils.R; access via clade:::.SPEC_GROUPS
  grp <- clade:::.SPEC_GROUPS[["Sex foundation"]]
  expect_false(is.null(grp))
  expect_setequal(grp, c("sex_labels", "sex_determination", "sex_ratio_primary"))
})

# ── 2. Julia-integrated tests ────────────────────────────────────────────────

# Helper: minimal specs for a short, cheap sex-foundation run.
.sex_specs <- function(...) {
  s <- default_specs()
  s$grid_rows     <- 15L
  s$grid_cols     <- 15L
  s$n_agents_init <- 30L
  s$max_ticks     <- 40L
  s$max_agents    <- 200L
  s$random_seed   <- 1L
  s$ploidy        <- 2L  # required for any mate-finding to occur
  args <- list(...)
  for (nm in names(args)) s[[nm]] <- args[[nm]]
  s
}

test_that("sex_labels = FALSE: all agents have sex == 0 (inert default)", {
  skip_no_julia()
  s <- .sex_specs(sex_labels = FALSE)
  env <- run_alife(s, verbose = FALSE)
  sexes <- vapply(seq_len(length(env$agents)),
                  function(i) as.integer(env$agents[[i]]$sex), integer(1))
  expect_true(all(sexes == 0L))
})

test_that("sex_labels = TRUE: every agent has sex in {0, 1}", {
  skip_no_julia()
  s <- .sex_specs(sex_labels = TRUE, sex_ratio_primary = 0.5)
  env <- run_alife(s, verbose = FALSE)
  sexes <- vapply(seq_len(length(env$agents)),
                  function(i) as.integer(env$agents[[i]]$sex), integer(1))
  expect_true(all(sexes %in% c(0L, 1L)))
})

test_that("sex_labels = TRUE with sex_ratio_primary = 0.5: proportion male ~ 0.5", {
  skip_no_julia()
  # Need a population large enough that the binomial SE is small. With
  # n = 200 surviving agents the 2-SE band on a binomial p=0.5 is roughly
  # 1/sqrt(200) ~ 0.07. Use a tolerance of 0.15 to stay clear of false
  # negatives from drift / small populations.
  s <- .sex_specs(sex_labels = TRUE, sex_ratio_primary = 0.5,
                   n_agents_init = 100L, max_agents = 500L,
                   max_ticks = 80L, random_seed = 7L)
  env <- run_alife(s, verbose = FALSE)
  sexes <- vapply(seq_len(length(env$agents)),
                  function(i) as.integer(env$agents[[i]]$sex), integer(1))
  skip_if(length(sexes) < 30L,
           "population too small to measure sex ratio")
  prop_male <- mean(sexes == 1L)
  expect_gt(prop_male, 0.35)
  expect_lt(prop_male, 0.65)
})

test_that("sex_labels = TRUE with sex_ratio_primary = 0.3: proportion male ~ 0.3", {
  skip_no_julia()
  s <- .sex_specs(sex_labels = TRUE, sex_ratio_primary = 0.3,
                   n_agents_init = 100L, max_agents = 500L,
                   max_ticks = 80L, random_seed = 11L)
  env <- run_alife(s, verbose = FALSE)
  sexes <- vapply(seq_len(length(env$agents)),
                  function(i) as.integer(env$agents[[i]]$sex), integer(1))
  skip_if(length(sexes) < 30L,
           "population too small to measure sex ratio")
  prop_male <- mean(sexes == 1L)
  # Looser band than 0.5 because skewed sex ratios feed back into mating
  # opportunity (limiting-sex pressure). Direction is what matters.
  expect_lt(prop_male, 0.45)
  expect_gt(prop_male, 0.10)
})

test_that("sex_labels = TRUE: founders have sex assigned at construction", {
  # Run for one tick (validator rejects 0) and use min_repro_age = 99
  # so no offspring can be born — the surviving agents are founders only.
  skip_no_julia()
  s <- .sex_specs(sex_labels = TRUE, sex_ratio_primary = 0.5,
                   n_agents_init = 60L, max_ticks = 1L,
                   min_repro_age = 99L,
                   random_seed = 13L)
  env <- run_alife(s, verbose = FALSE)
  sexes <- vapply(seq_len(length(env$agents)),
                  function(i) as.integer(env$agents[[i]]$sex), integer(1))
  expect_true(all(sexes %in% c(0L, 1L)))
  # With n = 60 founders the binomial 2-SE on p=0.5 is ~0.13. Loose check
  # that both sexes appear (failure probability under H0: 2 * 0.5^60).
  expect_true(any(sexes == 0L) && any(sexes == 1L))
})

test_that("sex_labels = TRUE: invalid sex_determination errors clearly", {
  skip_no_julia()
  s <- .sex_specs(sex_labels = TRUE, sex_determination = "chromosomal",
                   max_ticks = 1L, random_seed = 17L)
  expect_error(run_alife(s, verbose = FALSE),
                regexp = "sex_determination",
                info = "Unimplemented sex_determination should error clearly")
})

test_that("sex_labels = FALSE: kernel still runs and produces agents (non-regression)", {
  skip_no_julia()
  s <- .sex_specs(sex_labels = FALSE, random_seed = 19L)
  env <- run_alife(s, verbose = FALSE)
  expect_gt(length(env$agents), 0L)
})

# ── 3. A2 role-contract decoupling (parental_investment_evolution) ───────────

test_that("sex_labels = TRUE + parental_investment_evolution: kernel completes", {
  # Validates that the cost-split refactor in reproduce.jl handles a focal
  # agent of either sex without crashing. We don't assert specific energy
  # accounting here — that's exercised by trust-but-verify tick-level
  # debugging if a follow-up test is added.
  skip_no_julia()
  s <- .sex_specs(
    sex_labels = TRUE,
    sex_ratio_primary = 0.5,
    parental_investment_evolution = TRUE,
    female_investment = 0.7,
    n_agents_init = 60L,
    max_ticks = 30L,
    random_seed = 23L
  )
  expect_no_error(run_alife(s, verbose = FALSE))
})
