# Integration tests for the R → Julia → R round trip via run_alife().
#
# These tests exercise the full pipeline: .specs_to_julia() sends specs
# through JuliaConnectoR, Clade.run_clade() runs the simulation, and
# .julia_env_to_r() rebuilds the R-side env list. Each test skips gracefully
# when JuliaConnectoR or the Julia toolchain is unavailable (e.g. on CRAN or
# CI workers without Julia), so `devtools::test()` still passes on
# Julia-free systems.
#
# Reference for the boundary-crossing pattern: Lenz, S. & Csala, A. (2021)
# JuliaConnectoR: A functionally oriented interface between R and Julia,
# Journal of Statistical Software 101(6).

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

# Convert a JuliaArrayProxy (or anything list-like) to a plain R integer
# count — length() is the stable API across both cases.
.n_agents <- function(env) as.integer(length(env$agents))

# ── 1. Round-trip with default_specs() completes ─────────────────────────────
test_that("run_alife(default_specs()) completes without error", {
  skip_no_julia()
  s <- .quick_specs()
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(is.list(env))
})

# ── 2. Returned env has all expected top-level components ────────────────────
test_that("run_alife() returns the expected env fields", {
  skip_no_julia()
  env <- run_alife(.quick_specs(), verbose = FALSE)
  for (nm in c("agents", "t", "specs", "progress", "deaths", "genome_log")) {
    expect_true(nm %in% names(env),
                info = sprintf("env is missing field `%s`", nm))
  }
})

# ── 3. env$t equals specs$max_ticks ──────────────────────────────────────────
test_that("final tick equals specs$max_ticks", {
  skip_no_julia()
  s   <- .quick_specs(max_ticks = 15L)
  env <- run_alife(s, verbose = FALSE)
  expect_equal(as.integer(env$t), 15L)
})

# ── 4. Population is non-empty on the default quick specs ────────────────────
test_that("population survives a short run on default quick specs", {
  skip_no_julia()
  env <- run_alife(.quick_specs(random_seed = 1L), verbose = FALSE)
  expect_gt(.n_agents(env), 0L)
})

# ── 5. env$progress is a data frame with the expected names ──────────────────
test_that("env$progress is a data frame with the expected columns", {
  skip_no_julia()
  env <- run_alife(.quick_specs(), verbose = FALSE)
  expect_s3_class(env$progress, "data.frame")
  required <- c("t", "n_agents", "mean_energy", "sd_energy", "mean_age",
                "mean_body_size", "genetic_diversity", "grass_coverage",
                "n_births", "n_deaths", "n_starvations", "n_age_deaths",
                "n_infected", "n_new_infections", "n_altruistic_acts",
                "n_shelters_built", "mean_prior_sigma")
  missing <- setdiff(required, names(env$progress))
  expect_equal(missing, character(0L),
               info = paste("missing progress columns:",
                            paste(missing, collapse = ", ")))
})

# ── 6. env$deaths is a data frame with the expected columns ──────────────────
test_that("env$deaths is a data frame with the expected columns", {
  skip_no_julia()
  env <- run_alife(.quick_specs(), verbose = FALSE)
  expect_s3_class(env$deaths, "data.frame")
  required <- c("id", "t", "age", "energy", "cause", "body_size",
                "num_offspring")
  missing <- setdiff(required, names(env$deaths))
  expect_equal(missing, character(0L),
               info = paste("missing deaths columns:",
                            paste(missing, collapse = ", ")))
})

# ── 7. get_run_data() returns a ticks frame with max_ticks rows ──────────────
test_that("get_run_data()$ticks has nrow == max_ticks", {
  skip_no_julia()
  s  <- .quick_specs(max_ticks = 12L)
  rd <- get_run_data(run_alife(s, verbose = FALSE))
  expect_equal(nrow(rd$ticks), 12L)
})

# ── 8. get_run_data()$ticks$t is the sequence 1..max_ticks ───────────────────
test_that("get_run_data()$ticks$t is 1:max_ticks", {
  skip_no_julia()
  s  <- .quick_specs(max_ticks = 10L)
  rd <- get_run_data(run_alife(s, verbose = FALSE))
  expect_equal(as.integer(rd$ticks$t), 1L:10L)
})

# ── 9. n_agents is always non-negative ───────────────────────────────────────
test_that("n_agents in every tick is non-negative", {
  skip_no_julia()
  rd <- get_run_data(run_alife(.quick_specs(), verbose = FALSE))
  expect_true(all(as.integer(rd$ticks$n_agents) >= 0L))
})

# ── 10. mean_energy is always non-negative ───────────────────────────────────
test_that("mean_energy in every tick is non-negative", {
  skip_no_julia()
  rd <- get_run_data(run_alife(.quick_specs(), verbose = FALSE))
  expect_true(all(rd$ticks$mean_energy >= 0))
})

# ── 11. genetic_diversity is always non-negative ─────────────────────────────
test_that("genetic_diversity in every tick is non-negative", {
  skip_no_julia()
  rd <- get_run_data(run_alife(.quick_specs(), verbose = FALSE))
  expect_true(all(rd$ticks$genetic_diversity >= 0))
})

# ── 12. grass_coverage stays in [0, 1] ───────────────────────────────────────
test_that("grass_coverage in every tick is in [0, 1]", {
  skip_no_julia()
  rd <- get_run_data(run_alife(.quick_specs(), verbose = FALSE))
  expect_true(all(rd$ticks$grass_coverage >= 0 &
                    rd$ticks$grass_coverage <= 1))
})

# ── 13. BNN brain run completes ──────────────────────────────────────────────
test_that("run_alife() completes with brain_type = 'bnn'", {
  skip_no_julia()
  s   <- .quick_specs(brain_type = "bnn", random_seed = 2L)
  env <- run_alife(s, verbose = FALSE)
  expect_equal(as.integer(env$t), s$max_ticks)
  expect_gt(.n_agents(env), 0L)
})

# ── 14. ANN brain run completes ──────────────────────────────────────────────
test_that("run_alife() completes with brain_type = 'ann'", {
  skip_no_julia()
  s   <- .quick_specs(brain_type = "ann", random_seed = 3L)
  env <- run_alife(s, verbose = FALSE)
  expect_equal(as.integer(env$t), s$max_ticks)
  expect_gt(.n_agents(env), 0L)
})

# ── 15. Haploid run completes ────────────────────────────────────────────────
test_that("run_alife() completes with ploidy = 1 (haploid)", {
  skip_no_julia()
  s   <- .quick_specs(ploidy = 1L, random_seed = 4L)
  env <- run_alife(s, verbose = FALSE)
  expect_equal(as.integer(env$t), s$max_ticks)
})

# ── 16. Diploid run completes ────────────────────────────────────────────────
test_that("run_alife() completes with ploidy = 2 (diploid)", {
  skip_no_julia()
  s   <- .quick_specs(ploidy = 2L, random_seed = 5L)
  env <- run_alife(s, verbose = FALSE)
  expect_equal(as.integer(env$t), s$max_ticks)
})

# ── 17. Semelparous life history completes ───────────────────────────────────
test_that("run_alife() completes with life_history = 'semelparous'", {
  skip_no_julia()
  s   <- .quick_specs(life_history = "semelparous", random_seed = 6L)
  env <- run_alife(s, verbose = FALSE)
  expect_equal(as.integer(env$t), s$max_ticks)
})

# ── 18. senescence_rate > 0 completes ────────────────────────────────────────
test_that("run_alife() completes with senescence_rate = 0.01", {
  skip_no_julia()
  s   <- .quick_specs(senescence_rate = 0.01, random_seed = 7L)
  env <- run_alife(s, verbose = FALSE)
  expect_equal(as.integer(env$t), s$max_ticks)
})

# ── 19. Seeded runs are deterministic at tick 1 ──────────────────────────────
# The tick-1 statistics depend only on the explicit seed used to construct the
# Julia Xoshiro RNG, so two calls with the same random_seed must yield
# identical tick-1 means. Downstream divergence can arise from brain-specific
# sources of randomness elsewhere; we verify only the guaranteed tick-1 seed
# behaviour here.
test_that("two seeded runs produce identical tick-1 statistics", {
  skip_no_julia()
  s  <- .quick_specs(random_seed = 2026L, brain_type = "ann",
                     n_agents_init = 15L)
  r1 <- run_alife(s, verbose = FALSE)
  r2 <- run_alife(s, verbose = FALSE)
  expect_equal(as.numeric(r1$progress$mean_energy[1]),
               as.numeric(r2$progress$mean_energy[1]))
  expect_equal(as.integer(r1$progress$n_agents[1]),
               as.integer(r2$progress$n_agents[1]))
})

# ── 20. batch_alife returns a list of the right length ───────────────────────
test_that("batch_alife() returns one env per spec", {
  skip_no_julia()
  specs_list <- list(
    .quick_specs(grass_rate = 0.05, random_seed = 10L),
    .quick_specs(grass_rate = 0.20, random_seed = 11L)
  )
  res <- batch_alife(specs_list, n_cores = 1L, verbose = FALSE)
  expect_type(res, "list")
  expect_length(res, 2L)
  for (env in res) {
    expect_true(is.list(env))
    expect_true("progress" %in% names(env))
  }
})

# ── 21. Tick-1 mean energy is in a plausible range ───────────────────────────
# The original assertion (`mean_energy[1] <= energy_init + 1e-6`) was *wrong*.
# Agents pay move/idle cost (~ 1.0/0.5) but can eat up to `eat_gain * max_bite`
# (~ 5 * 2 = 10) per tick, so a well-fed agent gains net energy on tick 1 and
# can exceed `energy_init`. The fixed-array-order tick scheduling bias (lost in
# 0.7.0 — see dev/docs/consolidation-audit.md) was masking this by
# concentrating eating on a few first-array agents, producing low mean energy.
# With the random-asynchronous scheduling restored from MATLAB, eating is
# distributed more evenly and mean energy can sit above `energy_init`.
#
# The honest invariant is a range: each agent can lose at most `move_cost`
# and gain at most `eat_gain * max_bite`, so the mean must lie within those
# absolute bounds. (Body-size scaling at the eat source — 0.5.6 — pushes the
# upper bound slightly higher; we allow a generous margin.)
test_that("tick-1 mean_energy lies in a plausible range", {
  skip_no_julia()
  s   <- .quick_specs(energy_init = 100.0, random_seed = 12L)
  env <- run_alife(s, verbose = FALSE)
  m1  <- env$progress$mean_energy[1]
  lo  <- s$energy_init - s$move_cost - 1e-6
  hi  <- s$energy_init + s$eat_gain * s$max_bite + 1e-6
  expect_gte(m1, lo)
  expect_lte(m1, hi)
})

# ── 22. Performance: a 200 agent, 500 tick run finishes quickly ──────────────
# Benchmark target from Phase 1 plan: < 10 s on a modern laptop. We set a
# generous 30 s ceiling so slower CI runners do not flap.
test_that("200 agents x 500 ticks completes well under 30 s", {
  skip_no_julia()
  skip_on_cran()
  s <- default_specs()
  s$grid_rows     <- 20L
  s$grid_cols     <- 20L
  s$n_agents_init <- 200L
  s$max_agents    <- 600L
  s$max_ticks     <- 500L
  s$brain_type    <- "ann"
  s$random_seed   <- 99L
  elapsed <- system.time(run_alife(s, verbose = FALSE))[["elapsed"]]
  expect_lt(elapsed, 30.0)
})

# ── 23. BNN run reports a positive mean_prior_sigma ──────────────────────────
test_that("BNN run records mean_prior_sigma > 0", {
  skip_no_julia()
  s   <- .quick_specs(brain_type = "bnn", random_seed = 13L)
  env <- run_alife(s, verbose = FALSE)
  # mean_prior_sigma should be strictly positive in at least one logged tick
  # because BNN priors are initialised with sigma > 0.
  expect_true(any(env$progress$mean_prior_sigma > 0),
              info = "BNN mean_prior_sigma should be > 0 in at least one tick")
})

# ── 24. body_size_evolution = TRUE run completes ─────────────────────────────
test_that("run_alife() completes with body_size_evolution = TRUE", {
  skip_no_julia()
  s   <- .quick_specs(body_size_evolution = TRUE, random_seed = 14L)
  env <- run_alife(s, verbose = FALSE)
  expect_equal(as.integer(env$t), s$max_ticks)
})

# ── 25. disease = TRUE run completes and logs n_infected ─────────────────────
test_that("run_alife() completes with disease = TRUE", {
  skip_no_julia()
  s   <- .quick_specs(disease = TRUE, disease_seed_prob = 0.3,
                      random_seed = 15L)
  env <- run_alife(s, verbose = FALSE)
  expect_equal(as.integer(env$t), s$max_ticks)
  expect_true("n_infected" %in% names(env$progress))
})

# ── 26. Round trip preserves scalar spec types ───────────────────────────────
# Regression guard for .specs_to_julia(): integers must arrive in Julia as
# Int64, not Float64, because several Julia callers use `specs["field"]` as
# an index.
test_that(".specs_to_julia() preserves integer vs double scalars", {
  skip_no_julia()
  JuliaConnectoR::juliaEval(
    "_clade_test_type(d, k) = string(typeof(d[k]))"
  )
  s <- .quick_specs()
  d <- clade:::.specs_to_julia(s)
  t_grid <- as.character(JuliaConnectoR::juliaCall(
    "_clade_test_type", d, "grid_rows"))
  t_mut  <- as.character(JuliaConnectoR::juliaCall(
    "_clade_test_type", d, "mutation_sd"))
  t_bt   <- as.character(JuliaConnectoR::juliaCall(
    "_clade_test_type", d, "brain_type"))
  t_plo  <- as.character(JuliaConnectoR::juliaCall(
    "_clade_test_type", d, "ploidy"))
  expect_true(grepl("Int",   t_grid), info = paste("grid_rows type:", t_grid))
  expect_true(grepl("Float", t_mut),  info = paste("mutation_sd type:", t_mut))
  expect_equal(t_bt, "String")
  expect_true(grepl("Int",   t_plo),  info = paste("ploidy type:", t_plo))
})

# ── 27. .specs_to_julia() drops NA scalars and character(0) ──────────────────
test_that(".specs_to_julia() silently drops NA and character(0)", {
  skip_no_julia()
  JuliaConnectoR::juliaEval("_clade_test_has(d, k) = haskey(d, k)")
  s <- .quick_specs()
  s$random_seed       <- NA_integer_
  # Synthetic character(0) — exercises the drop-empty-character logic
  # without depending on any specific spec field. Name chosen for R parser
  # legality (underscore-prefixed names need backticks under `$`).
  s$synthetic_empty_char <- character(0L)
  expect_no_error(d <- clade:::.specs_to_julia(s))
  expect_false(as.logical(JuliaConnectoR::juliaCall(
    "_clade_test_has", d, "random_seed")))
  expect_false(as.logical(JuliaConnectoR::juliaCall(
    "_clade_test_has", d, "synthetic_empty_char")))
  # A normal key remains present
  expect_true(as.logical(JuliaConnectoR::juliaCall(
    "_clade_test_has", d, "grid_rows")))
})

# ── 28. input_radius = 1 (default) run completes ─────────────────────────────
test_that("run_alife() completes with input_radius = 1L (default)", {
  skip_no_julia()
  s   <- .quick_specs(input_radius = 1L, random_seed = 28L)
  env <- run_alife(s, verbose = FALSE)
  expect_equal(as.integer(env$t), s$max_ticks)
})

# ── 29. input_radius = 2 (wider sensing) run completes ───────────────────────
test_that("run_alife() completes with input_radius = 2L (wider sensing)", {
  skip_no_julia()
  s   <- .quick_specs(input_radius = 2L, random_seed = 29L)
  env <- run_alife(s, verbose = FALSE)
  expect_equal(as.integer(env$t), s$max_ticks)
})

# ── 30. Kitchen-sink run produces births over 300 ticks ──────────────────────
test_that("kitchen-sink run (all modules) produces n_births > 0 over 300 ticks", {
  skip_no_julia()
  skip_on_cran()
  s <- default_specs()
  s$grid_rows            <- 15L
  s$grid_cols            <- 15L
  s$n_agents_init        <- 30L
  s$max_agents           <- 200L
  s$max_ticks            <- 300L
  s$brain_type           <- "ann"
  s$disease              <- TRUE
  s$disease_seed_prob    <- 0.1
  s$kin_selection        <- TRUE
  s$body_size_evolution  <- TRUE
  s$dispersal_evolution  <- TRUE
  s$parental_care        <- TRUE
  s$social_learning      <- TRUE
  s$niche_construction   <- TRUE
  s$random_seed          <- 30L
  env <- run_alife(s, verbose = FALSE)
  expect_gt(sum(as.integer(env$progress$n_births)), 0L)
})

# ── 31. diploid run reports genetic_diversity >= 0 ───────────────────────────
test_that("run with ploidy = 2L reports genetic_diversity >= 0 always", {
  skip_no_julia()
  s   <- .quick_specs(ploidy = 2L, random_seed = 31L)
  env <- run_alife(s, verbose = FALSE)
  expect_true(all(as.numeric(env$progress$genetic_diversity) >= 0))
})

# ── 32. disease + kin_selection simultaneously ────────────────────────────────
test_that("run_alife() completes with disease = TRUE and kin_selection = TRUE", {
  skip_no_julia()
  s   <- .quick_specs(disease       = TRUE,
                      disease_seed_prob = 0.2,
                      kin_selection = TRUE,
                      random_seed   = 32L)
  env <- run_alife(s, verbose = FALSE)
  expect_equal(as.integer(env$t), s$max_ticks)
})

# ── 33. body_size_evolution + dispersal_evolution simultaneously ──────────────
test_that("run_alife() completes with body_size_evolution and dispersal_evolution", {
  skip_no_julia()
  s   <- .quick_specs(body_size_evolution  = TRUE,
                      dispersal_evolution  = TRUE,
                      random_seed          = 33L)
  env <- run_alife(s, verbose = FALSE)
  expect_equal(as.integer(env$t), s$max_ticks)
})

# ── 34. Population goes extinct when grass_rate = 0 ──────────────────────────
test_that("population goes extinct within 100 ticks when grass_rate = 0", {
  skip_no_julia()
  s <- .quick_specs(grass_rate           = 0.0,
                    grass_init_prob      = 0.0,
                    starvation_threshold = 1000.0,
                    max_ticks            = 100L,
                    random_seed          = 34L)
  env <- run_alife(s, verbose = FALSE)
  expect_equal(.n_agents(env), 0L)
})

# ── 35. social_learning + rl_mode = "actor_critic" simultaneously ─────────────
test_that("run_alife() completes with social_learning and rl_mode = 'actor_critic'", {
  skip_no_julia()
  s   <- .quick_specs(social_learning = TRUE,
                      rl_mode         = "actor_critic",
                      brain_type      = "ann",
                      random_seed     = 35L)
  env <- run_alife(s, verbose = FALSE)
  expect_equal(as.integer(env$t), s$max_ticks)
})
