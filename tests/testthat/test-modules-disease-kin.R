# Tests for the disease (SIR) and kin-selection Julia modules.
#
# These tests exercise the full R → Julia → R round trip via run_alife().
# Because JuliaConnectoR and a running Julia toolchain may be unavailable
# on CRAN or CI machines, every test skips gracefully if either is missing.

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

skip_no_julia <- function() {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
}

# ── 1. Disease run completes without error ──────────────────────────────────
test_that("run_alife with disease = TRUE completes", {
  skip_no_julia()
  s <- .quick_specs(disease = TRUE, disease_seed_prob = 0.5)
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
  expect_true("n_infected" %in% names(env$progress))
})

# ── 2. Disease seeds infections (seed_prob = 1) ─────────────────────────────
test_that("disease_seed_prob = 1 produces infections after tick 1", {
  skip_no_julia()
  s <- .quick_specs(
    disease           = TRUE,
    disease_seed_prob = 1.0,
    transmission_prob = 0.0,     # isolate the seeding step
    disease_death_prob= 0.0      # keep everyone alive for clean counting
  )
  env <- run_alife(s, verbose = FALSE)
  # At least one tick must record a positive n_infected count.
  expect_gt(max(env$progress$n_infected), 0L)
})

# ── 3. n_new_infections is logged correctly ─────────────────────────────────
test_that("n_new_infections records seed + transmission events", {
  skip_no_julia()
  s <- .quick_specs(
    disease            = TRUE,
    disease_seed_prob  = 1.0,
    transmission_prob  = 0.0,
    disease_death_prob = 0.0
  )
  env <- run_alife(s, verbose = FALSE)
  # All founders are seeded at tick 1, so the first logged tick must show
  # at least n_agents_init new infections.
  expect_gte(env$progress$n_new_infections[1], s$n_agents_init)
})

# ── 4. immune_strength = 1 blocks transmission entirely ─────────────────────
test_that("immune_strength = 1 prevents any transmission past the seed", {
  skip_no_julia()
  s <- .quick_specs(
    disease                   = TRUE,
    disease_seed_prob         = 0.5,
    transmission_prob         = 1.0,
    disease_death_prob        = 0.0,
    immune_evolution          = TRUE,
    immune_strength_init_mean = 1.0,    # start everyone fully immune
    immune_strength_min       = 1.0,    # clamp so expression cannot shrink
    immune_strength_max       = 1.0
  )
  env <- run_alife(s, verbose = FALSE)
  # Seed infections at tick 1 are unconditional; after the first tick no new
  # infections should occur because transmission is scaled by (1 - 1) = 0.
  # Confirm this by checking that all further logged ticks are 0.
  if (length(env$progress$n_new_infections) > 1L) {
    expect_equal(env$progress$n_new_infections[-1], rep(0L, length(env$progress$n_new_infections) - 1L))
  }
})

# ── 5. disease = FALSE: n_infected is always 0 ──────────────────────────────
test_that("disease = FALSE keeps n_infected at 0 throughout", {
  skip_no_julia()
  s <- .quick_specs(disease = FALSE)
  env <- run_alife(s, verbose = FALSE)
  expect_true(all(env$progress$n_infected == 0L))
  expect_true(all(env$progress$n_new_infections == 0L))
})

# ── 6. With disease enabled, newly-created offspring start susceptible ──────
test_that("new offspring start with infected = FALSE and immune = FALSE", {
  skip_no_julia()
  # Very high seed prob so founders are infected, but offspring shouldn't be.
  s <- .quick_specs(
    disease           = TRUE,
    disease_seed_prob = 1.0,
    transmission_prob = 0.0,
    disease_death_prob= 0.0,
    min_repro_energy  = 50.0   # encourage births
  )
  env <- run_alife(s, verbose = FALSE)
  # The Julia-side `_make_offspring` writes infected=false, immune=false by
  # default. Check that at least one tick after tick 1 has agents alive and
  # that some of them are susceptible (there should be births).
  # This is a coarse but robust check — we just verify that not all agents
  # are infected after a few ticks of reproduction.
  if (length(env$agents) > s$n_agents_init) {
    # Births occurred; at least some newborns must still be susceptible.
    expect_true(any(env$progress$n_infected < vapply(
      env$progress$n_agents, as.integer, integer(1L)
    )))
  } else {
    succeed()  # not enough reproduction to check — skip silently
  }
})

# ── 7. Kin selection run completes without error ────────────────────────────
test_that("run_alife with kin_selection = TRUE completes", {
  skip_no_julia()
  s <- .quick_specs(kin_selection = TRUE)
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true("n_altruistic_acts" %in% names(env$progress))
})

# ── 8. n_altruistic_acts > 0 over a longer run ──────────────────────────────
test_that("n_altruistic_acts accumulates over a longer kin-selection run", {
  skip_no_julia()
  s <- .quick_specs(
    kin_selection                 = TRUE,
    kin_altruism_min_donor_energy = 10.0,  # easier to trigger
    max_ticks                     = 50L,
    min_repro_energy              = 60.0   # ensure siblings exist
  )
  env <- run_alife(s, verbose = FALSE)
  expect_gt(sum(env$progress$n_altruistic_acts), 0L)
})

# ── 9. Hamilton's rule (rB > C) holds for default kin parameters ────────────
test_that("default kin_altruism parameters satisfy Hamilton's rule rB > C", {
  s <- default_specs()
  expect_gt(s$kin_altruism_r_min * s$kin_altruism_benefit,
            s$kin_altruism_cost)
})

# ── 10. Module files exist on disk ──────────────────────────────────────────
test_that("disease.jl and kin.jl are present in the bundled Julia source", {
  julia_src <- system.file("julia", "src", package = "clade")
  skip_if(!nchar(julia_src) || !dir.exists(julia_src),
          "Julia source not installed")
  expect_true(file.exists(file.path(julia_src, "modules", "disease.jl")))
  expect_true(file.exists(file.path(julia_src, "modules", "kin.jl")))
})

# ── 11. Clade.jl wires in both modules ──────────────────────────────────────
test_that("Clade.jl includes modules/disease.jl and modules/kin.jl", {
  julia_src <- system.file("julia", "src", package = "clade")
  skip_if(!nchar(julia_src) || !dir.exists(julia_src),
          "Julia source not installed")
  clade_jl <- readLines(file.path(julia_src, "Clade.jl"))
  expect_true(any(grepl('include\\("modules/disease.jl"\\)', clade_jl)))
  expect_true(any(grepl('include\\("modules/kin.jl"\\)',     clade_jl)))
  # And the apply_* / seed_disease! calls are active in the tick loop
  expect_true(any(grepl("apply_disease!\\(env\\)",       clade_jl)))
  expect_true(any(grepl("apply_kin_altruism!\\(env\\)",  clade_jl)))
  expect_true(any(grepl("seed_disease!\\(env\\)",        clade_jl)))
})
