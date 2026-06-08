# Tests for the 0.8.0 mating-system module (Phase C: pair bonds).
#
# Covers:
#   mating_system                  (character; default "any")
#   divorce_rate                   (numeric; default 0.0)
#   pair_bond_persistence          (logical; default TRUE)
#   mating_group_n_males / females (integer; default 1L)
#   mating_group_fecundity_scaling (character; default "balanced")
# and the persistent-monogamy path in `_find_mate()` + `update_unions!`.

library(testthat)

# ── 1. R-side spec presence and defaults ─────────────────────────────────────

test_that("mating_system defaults to 'any' (backward compatible)", {
  s <- default_specs()
  expect_identical(s$mating_system, "any")
})

test_that("divorce_rate defaults to 0.0 and is in [0, 1]", {
  s <- default_specs()
  expect_equal(s$divorce_rate, 0.0)
  expect_gte(s$divorce_rate, 0.0)
  expect_lte(s$divorce_rate, 1.0)
})

test_that("pair_bond_persistence defaults to TRUE", {
  s <- default_specs()
  expect_true(s$pair_bond_persistence)
})

test_that("mating_group_n_males / n_females default to 1L", {
  s <- default_specs()
  expect_equal(s$mating_group_n_males, 1L)
  expect_equal(s$mating_group_n_females, 1L)
})

test_that("mating_group_fecundity_scaling defaults to 'balanced'", {
  s <- default_specs()
  expect_identical(s$mating_group_fecundity_scaling, "balanced")
})

test_that("Mating system fields appear in .SPEC_GROUPS", {
  grp <- clade:::.SPEC_GROUPS[["Mating system"]]
  expect_false(is.null(grp))
  expect_setequal(grp, c("mating_system", "divorce_rate",
                          "pair_bond_persistence",
                          "mating_group_n_males",
                          "mating_group_n_females",
                          "mating_group_fecundity_scaling"))
})

# ── 2. Julia-integrated: monogamous-pair behaviour ───────────────────────────

.pair_specs <- function(...) {
  s <- default_specs()
  s$grid_rows         <- 12L
  s$grid_cols         <- 12L
  s$n_agents_init     <- 30L
  s$max_ticks         <- 30L
  s$max_agents        <- 200L
  s$random_seed       <- 7L
  s$ploidy            <- 2L
  s$sex_labels        <- TRUE
  s$mating_system     <- "monogamous_pair"
  args <- list(...)
  for (nm in names(args)) s[[nm]] <- args[[nm]]
  s
}

test_that("mating_system = 'monogamous_pair' runs cleanly", {
  skip_no_julia()
  s <- .pair_specs()
  expect_no_error(run_alife(s, verbose = FALSE))
})

test_that("monogamous_pair: many agents end the run with a bonded partner", {
  skip_no_julia()
  s <- .pair_specs(max_ticks = 50L, n_agents_init = 60L,
                    max_agents = 300L, random_seed = 9L)
  env <- run_alife(s, verbose = FALSE)
  n <- length(env$agents)
  skip_if(n < 20L, "population too small to inspect pair bonds")
  partner_ids <- vapply(seq_len(n),
                        function(i) as.numeric(env$agents[[i]]$union_partner_id),
                        numeric(1))
  # Some non-zero fraction should be in a current bond. Loose check
  # (≥10%) to avoid flakiness from rare-mating runs.
  expect_gt(mean(partner_ids > 0), 0.1)
})

test_that("mating_system = 'any' (default) leaves union_partner_id = 0", {
  skip_no_julia()
  s <- .pair_specs(mating_system = "any", random_seed = 11L)
  env <- run_alife(s, verbose = FALSE)
  n <- length(env$agents)
  skip_if(n < 5L, "population too small to inspect")
  partner_ids <- vapply(seq_len(n),
                        function(i) as.numeric(env$agents[[i]]$union_partner_id),
                        numeric(1))
  expect_true(all(partner_ids == 0))
})

test_that("mating_system = 'mating_groups' errors clearly (not yet implemented)", {
  skip_no_julia()
  s <- .pair_specs(mating_system = "mating_groups",
                    mating_group_n_males = 2L,
                    mating_group_n_females = 1L,
                    random_seed = 13L)
  expect_error(run_alife(s, verbose = FALSE),
                regexp = "not yet implemented")
})

test_that("monogamous_pair + divorce_rate = 1.0: bonds always dissolve next tick", {
  # With divorce_rate = 1.0 every bond formed should be dissolved by
  # update_unions! on the next tick. With pair_bond_persistence = TRUE
  # this means very few agents end the run still partnered.
  skip_no_julia()
  s <- .pair_specs(divorce_rate = 1.0, max_ticks = 40L,
                    n_agents_init = 40L, random_seed = 17L)
  env <- run_alife(s, verbose = FALSE)
  n <- length(env$agents)
  skip_if(n < 5L, "population too small")
  partner_ids <- vapply(seq_len(n),
                        function(i) as.numeric(env$agents[[i]]$union_partner_id),
                        numeric(1))
  expect_lt(mean(partner_ids > 0), 0.10)
})
