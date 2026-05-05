test_that("mimicry defaults to FALSE", {
  expect_false(default_specs()$mimicry)
})

test_that("toxicity_cost_per_tick defaults to 2.0 (Zahavi handicap)", {
  # Default was raised from 0.5 to 2.0 to make the Zahavi cost biologically
  # meaningful (see roxygen in R/config.R). Test value updated 0.7.0 to
  # match the config; previously stale.
  expect_equal(default_specs()$toxicity_cost_per_tick, 2.0)
})

test_that("toxin_dose defaults to 30.0", {
  expect_equal(default_specs()$toxin_dose, 30.0)
})

test_that("signal_memory_rate defaults to 0.3", {
  expect_equal(default_specs()$signal_memory_rate, 0.3)
})

test_that("avoid_threshold defaults to 0.5", {
  expect_equal(default_specs()$avoid_threshold, 0.5)
})

test_that("toxicity_init_mean defaults to 0.0", {
  expect_equal(default_specs()$toxicity_init_mean, 0.0)
})

test_that("toxicity_mutation_sd defaults to 0.05", {
  expect_equal(default_specs()$toxicity_mutation_sd, 0.05)
})

test_that("all mimicry params are present in default_specs", {
  nms <- names(default_specs())
  for (p in c("mimicry", "toxicity_cost_per_tick", "toxin_dose",
               "signal_memory_rate", "avoid_threshold",
               "toxicity_init_mean", "toxicity_mutation_sd")) {
    expect_true(p %in% nms, info = paste("missing:", p))
  }
})

test_that("toxin_dose is positive", {
  expect_true(default_specs()$toxin_dose > 0)
})

test_that("signal_memory_rate is in (0, 1)", {
  r <- default_specs()$signal_memory_rate
  expect_true(r > 0 && r < 1)
})

# ── 11. With mimicry = TRUE, run logs n_toxic_attacks and n_avoided_attacks ──
test_that("mimicry = TRUE run has n_toxic_attacks and n_avoided_attacks in run_data", {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(), "Julia toolchain not available")
  s <- default_specs()
  s$grid_rows     <- 15L
  s$grid_cols     <- 15L
  s$n_agents_init <- 20L
  s$max_agents    <- 100L
  s$max_ticks     <- 20L
  s$random_seed   <- 42L
  s$mimicry       <- TRUE
  s$n_predators_init <- 3L
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  expect_true("n_toxic_attacks"   %in% names(d))
  expect_true("n_avoided_attacks" %in% names(d))
})

# ── 12. mean_toxicity >= 0 for all ticks when mimicry = TRUE ─────────────────
test_that("mean_toxicity is non-negative at all ticks when mimicry = TRUE", {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(), "Julia toolchain not available")
  s <- default_specs()
  s$grid_rows     <- 15L
  s$grid_cols     <- 15L
  s$n_agents_init <- 20L
  s$max_agents    <- 100L
  s$max_ticks     <- 20L
  s$random_seed   <- 42L
  s$mimicry       <- TRUE
  s$n_predators_init <- 3L
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  if ("mean_toxicity" %in% names(d)) {
    vals <- d$mean_toxicity
    expect_true(all(is.na(vals) | vals >= 0),
                info = "mean_toxicity should be non-negative")
  }
})

# ── 13. mimicry params round-trip through default_specs() ─────────────────────
test_that("mimicry params round-trip correctly through default_specs()", {
  s <- default_specs()
  expect_false(s$mimicry)
  expect_equal(s$toxicity_cost_per_tick, 2.0)   # see test at line 5 — updated 0.7.0
  expect_equal(s$toxin_dose,             30.0)
  expect_equal(s$signal_memory_rate,     0.3)
  expect_equal(s$avoid_threshold,        0.5)
  expect_equal(s$toxicity_init_mean,     0.0)
  expect_equal(s$toxicity_mutation_sd,   0.05)
})
