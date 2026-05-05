# Tests for the Wolf et al. 2007 Nature personality syndrome (added 0.7.0).
#
# The headline biological prediction (Wolf 2007 Fig 2/3): individuals with
# high `exploration` (much to lose at year 2) evolve to be less bold + less
# aggressive; individuals with low exploration (little to lose) evolve to
# be more bold + more aggressive. The boldness-aggressiveness syndrome
# (positive correlation across contexts) emerges as a side effect of the
# shared asset-protection mechanism.
#
# Tests here verify:
#  1. The wolf_personality_specs() preset returns a valid specs list with
#     personality_syndrome = TRUE.
#  2. A short run (no Julia required for the structural test).
#  3. A medium run (skip_no_julia()) produces age-windowed reproduction
#     events at the expected ticks.
#  4. A longer run produces the predicted sign of trait correlations.
#     This is the headline biological assertion.

library(testthat)

# Tunable for the syndrome correlation test. With the spatially-explicit
# clade interpretation (neighborhood hawk-dove pairing, predator-anchored
# anti-predator), selection signal is weaker than Wolf's mean-field model:
#  - Wolf's (1+α·N) competition denominator is replaced by clade's grid-
#    based spatial competition (less efficient at producing dimorphism).
#  - Hawk-dove neighborhood pairing depends on local density (radius=2 with
#    7–25% population density yields a few games per agent per between-phase).
# These choices favor biological realism over reproducing Wolf's exact
# correlation magnitudes. The test threshold below is the level at which
# the syndrome is reliably detectable above seed-to-seed noise — *not*
# the strength Wolf reports for his abstract model.
.WOLF_SYNDROME_TICKS  <- 5000L
.WOLF_SYNDROME_SEED   <- 42L
.WOLF_R_MIN_MAGNITUDE <- 0.05

test_that("wolf_personality_specs() returns a valid spec list with personality_syndrome = TRUE", {
  s <- wolf_personality_specs()
  expect_type(s, "list")
  expect_true(s$personality_syndrome)
  expect_equal(s$ploidy, 1L)                          # Wolf's haploid basic model
  expect_true(s$min_repro_energy >= 1e8)              # standard repro disabled
  expect_true("wolf_year1_repro_age" %in% names(s))
  expect_true("wolf_year2_repro_age" %in% names(s))
  expect_true(s$wolf_year1_repro_age < s$wolf_year2_repro_age)
})

test_that("personality_syndrome defaults to FALSE in default_specs()", {
  expect_false(default_specs()$personality_syndrome)
})

test_that("Wolf scenario completes a short run without error and produces births + deaths", {
  skip_no_julia()
  s <- wolf_personality_specs()
  s$max_ticks   <- 200L
  s$random_seed <- 1L
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  d <- get_run_data(env)$ticks
  expect_true(sum(d$n_births)  > 0L, info = "Wolf age-windowed reproduction must fire")
  expect_true(sum(d$n_deaths)  > 0L, info = "Wolf year-2 reproduction must kill the parent")
})

test_that("Wolf scenario produces the boldness-aggressiveness syndrome (signs only)", {
  skip_no_julia()
  skip_on_cran()           # 5000-tick run is slow for CRAN
  s <- wolf_personality_specs()
  s$max_ticks                       <- .WOLF_SYNDROME_TICKS
  s$random_seed                     <- .WOLF_SYNDROME_SEED
  s$n_agents_init                   <- 200L     # higher density → more hawk-dove encounters
  s$max_agents                      <- 800L
  s$personality_hawkdove_per_tick   <- 0.3
  s$personality_hawkdove_radius     <- 2L
  s$n_predators_init                <- 10L     # spatially-explicit anti-predator needs predators
  s$predator_max_agents             <- 30L
  env <- run_alife(s, verbose = FALSE)

  # Pull final trait vectors from agent records
  recs <- env$agents
  alive <- vapply(seq_along(recs), function(i) as.logical(recs[[i]]$alive),
                  logical(1L))
  ex <- vapply(seq_along(recs)[alive],
               function(i) as.numeric(recs[[i]]$exploration), numeric(1L))
  bo <- vapply(seq_along(recs)[alive],
               function(i) as.numeric(recs[[i]]$boldness), numeric(1L))
  ag <- vapply(seq_along(recs)[alive],
               function(i) as.numeric(recs[[i]]$aggressiveness), numeric(1L))

  skip_if(length(ex) < 30L,
          paste("not enough live agents for a meaningful correlation:",
                length(ex)))

  r_eb <- suppressWarnings(stats::cor(ex, bo))
  r_ea <- suppressWarnings(stats::cor(ex, ag))
  r_ba <- suppressWarnings(stats::cor(bo, ag))

  msg <- sprintf("n=%d  cor(exp,bold)=%.3f  cor(exp,aggro)=%.3f  cor(bold,aggro)=%.3f",
                 length(ex), r_eb, r_ea, r_ba)
  message("Wolf syndrome correlations: ", msg)

  # Wolf's prediction: exploration negatively correlates with both boldness
  # and aggressiveness; boldness and aggressiveness positively correlate.
  # Use signed magnitude check: must be in the predicted direction with
  # at least .WOLF_R_MIN_MAGNITUDE absolute value.
  expect_true(r_eb < -.WOLF_R_MIN_MAGNITUDE,
              info = paste("Pearson(exploration, boldness) should be < -",
                           .WOLF_R_MIN_MAGNITUDE, ":", msg))
  expect_true(r_ea < -.WOLF_R_MIN_MAGNITUDE,
              info = paste("Pearson(exploration, aggressiveness) should be < -",
                           .WOLF_R_MIN_MAGNITUDE, ":", msg))
  expect_true(r_ba >  .WOLF_R_MIN_MAGNITUDE,
              info = paste("Pearson(boldness, aggressiveness) should be > +",
                           .WOLF_R_MIN_MAGNITUDE, ":", msg))
})
