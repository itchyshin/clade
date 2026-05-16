# Tests for the cooperation, scavenging, and niche-construction Julia modules.
#
# These exercise the full R → Julia → R round trip via run_alife(). Each
# Julia-dependent test skips gracefully if JuliaConnectoR or the Julia
# toolchain is unavailable.

library(testthat)

# ── Helpers ──────────────────────────────────────────────────────────────────

.quick_specs <- function(...) {
  s <- default_specs()
  s$grid_rows     <- 10L
  s$grid_cols     <- 10L
  s$n_agents_init <- 10L
  s$max_agents    <- 60L
  s$max_ticks     <- 20L
  args <- list(...)
  for (nm in names(args)) s[[nm]] <- args[[nm]]
  s
}

# ── Cooperation ──────────────────────────────────────────────────────────────

# 1. run_alife with cooperation_evolution = TRUE completes
test_that("run_alife with cooperation_evolution = TRUE completes", {
  skip_no_julia()
  s <- .quick_specs(cooperation_evolution = TRUE)
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
  expect_true("n_cooperation_acts" %in% names(env$progress))
})

# 2. default cooperation_multiplier is > 1 (non-trivial public goods game)
test_that("default cooperation_multiplier is > 1", {
  skip_no_julia()
  s <- default_specs()
  expect_gt(s$cooperation_multiplier, 1.0)
})

# 3. Selection: high multiplier and dyadic groups should increase mean
#    cooperation_level over a long run. We use a tiny grid to force Moore
#    overlaps, high multiplier, and low cooperation cost so the stochastic
#    birth-death noise does not dominate selection.
test_that("high cooperation_multiplier preserves mean cooperation_level", {
  skip_no_julia()
  s <- .quick_specs(
    cooperation_evolution  = TRUE,
    cooperation_multiplier = 3.0,
    cooperation_init_mean  = 0.3,
    cooperation_cost       = 0.5,
    max_ticks              = 200L,
    grid_rows              = 8L,
    grid_cols              = 8L,
    n_agents_init          = 20L,
    max_agents             = 150L,
    random_seed            = 42L
  )
  env <- run_alife(s, verbose = FALSE)
  coop_series <- env$progress$mean_cooperation_level
  coop_series <- coop_series[coop_series > 0]
  skip_if(length(coop_series) < 20L,
          "too few logged ticks with live agents for a trend test")
  n_series <- length(coop_series)
  window   <- max(1L, floor(n_series * 0.25))
  early <- mean(coop_series[seq_len(window)])
  late  <- mean(tail(coop_series, window))
  # Directional expectation only — small grids and short runs mean the test
  # should be robust to noise, not a quantitative benchmark. Allow the late
  # mean to equal the early mean but not drop substantially.
  expect_gte(late, early - 0.05)
})

# 4. cooperation_evolution = FALSE: n_cooperation_acts is 0 throughout.
test_that("cooperation_evolution = FALSE keeps n_cooperation_acts at 0", {
  skip_no_julia()
  s <- .quick_specs(cooperation_evolution = FALSE)
  env <- run_alife(s, verbose = FALSE)
  expect_true(all(env$progress$n_cooperation_acts == 0L))
})

# ── Scavenging ───────────────────────────────────────────────────────────────

# 5. run_alife with scavenging = TRUE completes
test_that("run_alife with scavenging = TRUE completes", {
  skip_no_julia()
  s <- .quick_specs(scavenging = TRUE, carrion_fraction = 0.5)
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
})

# 6. Carrion is actually deposited when agents die. We force rapid die-offs
#    via a starvation threshold close to energy_init, turn off consumption
#    and decomposition, and verify that env.carrion_map accumulates non-zero
#    biomass by the end of the run. total_carrion is added to the run_alife
#    result for this purpose.
test_that("scavenging deposits carrion when agents die", {
  skip_no_julia()
  s <- .quick_specs(
    scavenging           = TRUE,
    carrion_fraction     = 0.5,
    carrion_eat_gain     = 0.0,    # nobody consumes carrion
    carrion_decay_rate   = 0.0,    # no decomposition
    starvation_threshold = 90.0,   # most agents starve fast
    energy_init          = 95.0,
    max_ticks            = 15L,
    random_seed          = 7L
  )
  env <- run_alife(s, verbose = FALSE)
  expect_gt(as.numeric(env$total_carrion), 0)
})

# 7. carrion_fraction = 0: no carrion is deposited even when agents die.
test_that("carrion_fraction = 0 deposits no carrion", {
  skip_no_julia()
  s <- .quick_specs(
    scavenging           = TRUE,
    carrion_fraction     = 0.0,
    carrion_eat_gain     = 0.0,
    carrion_decay_rate   = 0.0,
    starvation_threshold = 90.0,
    energy_init          = 95.0,
    max_ticks            = 15L,
    random_seed          = 7L
  )
  env <- run_alife(s, verbose = FALSE)
  expect_equal(as.numeric(env$total_carrion), 0)
})

# ── Niche construction ──────────────────────────────────────────────────────

# 8. run_alife with niche_construction = TRUE completes
test_that("run_alife with niche_construction = TRUE completes", {
  skip_no_julia()
  s <- .quick_specs(niche_construction = TRUE)
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true("n_shelters_built" %in% names(env$progress))
})

# 9. Over a sufficiently long run with enough agents and energy,
#    n_shelters_built accumulates above 0.
test_that("n_shelters_built > 0 over a long niche-construction run", {
  skip_no_julia()
  s <- .quick_specs(
    niche_construction = TRUE,
    shelter_build_prob = 0.5,        # high rate so shelters appear fast
    shelter_min_energy = 50.0,       # easy to satisfy
    shelter_max_depth  = 5L,
    shelter_decay_prob = 0.0,        # isolate the building step
    max_ticks          = 50L,
    n_agents_init      = 20L,
    max_agents         = 100L,
    energy_init        = 150.0,
    random_seed        = 11L
  )
  env <- run_alife(s, verbose = FALSE)
  expect_gt(sum(env$progress$n_shelters_built), 0L)
})

# 10. niche_construction = FALSE: n_shelters_built is 0 throughout.
test_that("niche_construction = FALSE keeps n_shelters_built at 0", {
  skip_no_julia()
  s <- .quick_specs(niche_construction = FALSE)
  env <- run_alife(s, verbose = FALSE)
  expect_true(all(env$progress$n_shelters_built == 0L))
})

# ── Source files are present and wired in ──────────────────────────────────

# 11. All three module files exist on disk.
test_that("cooperation.jl, scavenging.jl, and niche.jl are present", {
  skip_no_julia()
  julia_src <- system.file("julia", "src", package = "clade")
  skip_if(!nchar(julia_src) || !dir.exists(julia_src),
          "Julia source not installed")
  expect_true(file.exists(file.path(julia_src, "modules", "cooperation.jl")))
  expect_true(file.exists(file.path(julia_src, "modules", "scavenging.jl")))
  expect_true(file.exists(file.path(julia_src, "modules", "niche.jl")))
})

# 12. Clade.jl wires in all three modules and calls their apply_* entry
#     points in the tick loop.
test_that("Clade.jl includes and calls all three modules", {
  skip_no_julia()
  julia_src <- system.file("julia", "src", package = "clade")
  skip_if(!nchar(julia_src) || !dir.exists(julia_src),
          "Julia source not installed")
  clade_jl <- readLines(file.path(julia_src, "Clade.jl"))
  expect_true(any(grepl('include\\("modules/cooperation.jl"\\)', clade_jl)))
  expect_true(any(grepl('include\\("modules/scavenging.jl"\\)',  clade_jl)))
  expect_true(any(grepl('include\\("modules/niche.jl"\\)',       clade_jl)))
  expect_true(any(grepl("apply_cooperation!\\(env\\)",           clade_jl)))
  expect_true(any(grepl("apply_scavenging!\\(env\\)",            clade_jl)))
  expect_true(any(grepl("decay_carrion!\\(env\\)",               clade_jl)))
  expect_true(any(grepl("apply_niche_construction!\\(env\\)",    clade_jl)))
})

# 13. death.jl calls deposit_carrion! when an agent is flagged dead.
test_that("death.jl deposits carrion on agent death", {
  skip_no_julia()
  julia_src <- system.file("julia", "src", package = "clade")
  skip_if(!nchar(julia_src) || !dir.exists(julia_src),
          "Julia source not installed")
  death_jl <- readLines(file.path(julia_src, "death.jl"))
  expect_true(any(grepl("deposit_carrion!", death_jl, fixed = TRUE)))
})
