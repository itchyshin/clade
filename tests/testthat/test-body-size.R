# Tests for the body_size evolution Julia module.
#
# Mirrors alifeR/tests/testthat/test-body-size.R with adaptations for the
# clade API (Julia backend, env$progress as data.frame, env$agents as
# JuliaConnectoR proxy). Tests requiring Julia are guarded by skip_no_julia().

library(testthat)

# ── Helpers ───────────────────────────────────────────────────────────────────

.qs <- function(...) {
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

.bs_specs <- function(...) {
  .qs(
    body_size_evolution   = TRUE,
    body_size_init_mean   = 1.0,
    body_size_mutation_sd = 0.08,
    body_size_min         = 0.3,
    body_size_max         = 3.0,
    ...
  )
}

skip_no_julia <- function() {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
}

# env$agents is a JuliaConnectoR proxy; iterate by index to extract fields.
.agent_bs <- function(env) {
  n <- as.integer(length(env$agents))
  if (n == 0L) return(numeric(0L))
  vapply(seq_len(n), function(i) as.numeric(env$agents[[i]]$body_size),
         numeric(1L))
}

# ── 1. body_size = 1 for all agents when evolution is off ────────────────────
test_that("body_size is 1.0 for all agents when body_size_evolution = FALSE", {
  skip_no_julia()
  s   <- .qs()
  env <- run_alife(s, verbose = FALSE)
  bs  <- .agent_bs(env)
  expect_true(all(bs == 1.0),
              info = "All agents should have reference body_size = 1.0")
})

# ── 2. body_size variation appears when evolution is on ───────────────────────
test_that("body_size variation appears when body_size_evolution = TRUE", {
  skip_no_julia()
  s   <- .bs_specs(n_agents_init = 30L, max_ticks = 50L,
                   body_size_mutation_sd = 0.15)
  env <- run_alife(s, verbose = FALSE)
  bs  <- .agent_bs(env)
  # At least some variation after 50 ticks with sd = 0.15
  expect_gt(stats::sd(bs), 0.0,
            label = "body_size should vary across agents after mutation")
})

# ── 3. body_size stays within [min, max] throughout ──────────────────────────
test_that("body_size stays within [body_size_min, body_size_max]", {
  skip_no_julia()
  s   <- .bs_specs(n_agents_init = 30L, max_ticks = 50L)
  env <- run_alife(s, verbose = FALSE)
  bs  <- .agent_bs(env)
  if (length(bs) > 0L) {
    expect_true(all(bs >= s$body_size_min - 1e-6))
    expect_true(all(bs <= s$body_size_max + 1e-6))
  }
})

# ── 4. Large agents lose more energy per tick than reference (no food) ───────
test_that("large body_size loses more energy per tick than reference", {
  skip_no_julia()
  base <- .bs_specs(
    n_agents_init    = 20L,
    max_ticks        = 10L,
    min_repro_energy = 500.0,   # no reproduction
    grass_rate       = 0.0,
    grass_max        = 0.0,
    grass_init_prob  = 0.0,
    random_seed      = 42L
  )

  s_large <- base
  s_large$body_size_init_mean   <- 2.0
  s_large$body_size_mutation_sd <- 0.0

  s_ref <- base
  s_ref$body_size_init_mean   <- 1.0
  s_ref$body_size_mutation_sd <- 0.0

  env_large <- run_alife(s_large, verbose = FALSE)
  env_ref   <- run_alife(s_ref,   verbose = FALSE)

  # Use tick 1 mean energy (before potential population crash)
  e_large_t1 <- env_large$progress$mean_energy[[1L]]
  e_ref_t1   <- env_ref$progress$mean_energy[[1L]]

  if (!is.nan(e_large_t1) && !is.nan(e_ref_t1)) {
    expect_lt(e_large_t1, e_ref_t1,
              label = "large agents should have lower mean energy after 1 tick")
  }
})

# ── 5. mean_body_size is present in env$progress ─────────────────────────────
test_that("mean_body_size is logged in env$progress", {
  skip_no_julia()
  s   <- .bs_specs()
  env <- run_alife(s, verbose = FALSE)
  expect_true("mean_body_size" %in% names(env$progress))
})

# ── 6. sd_body_size is present in env$progress ───────────────────────────────
test_that("sd_body_size is logged in env$progress", {
  skip_no_julia()
  s   <- .bs_specs()
  env <- run_alife(s, verbose = FALSE)
  expect_true("sd_body_size" %in% names(env$progress))
})

# ── 7. mean_body_size stays within trait bounds throughout ───────────────────
test_that("logged mean_body_size stays within [body_size_min, body_size_max]", {
  skip_no_julia()
  s   <- .bs_specs(max_ticks = 30L)
  env <- run_alife(s, verbose = FALSE)
  mbz <- env$progress$mean_body_size
  active <- env$progress$n_agents > 0L
  if (any(active)) {
    expect_true(all(mbz[active] >= s$body_size_min - 1e-6))
    expect_true(all(mbz[active] <= s$body_size_max + 1e-6))
  }
})

# ── 8. run_alife completes with body_size_evolution = TRUE ───────────────────
test_that("run_alife completes without error when body_size_evolution = TRUE", {
  skip_no_julia()
  s <- .bs_specs()
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(as.integer(env$t) >= 1L)
})

# ── 9. body_size is > 0 for all surviving agents ─────────────────────────────
test_that("body_size is strictly positive for all surviving agents", {
  skip_no_julia()
  s   <- .bs_specs(max_ticks = 30L, random_seed = 1L)
  env <- run_alife(s, verbose = FALSE)
  bs  <- .agent_bs(env)
  if (length(bs) > 0L) expect_true(all(bs > 0.0))
})

# ── 10. mean_body_size = 0 at ticks where population is empty ────────────────
test_that("mean_body_size records 0 when population is empty", {
  skip_no_julia()
  s <- .bs_specs(
    n_agents_init    = 3L,
    max_ticks        = 10L,
    energy_init      = 1.0,    # agents starve immediately
    min_repro_energy = 500.0,
    grass_rate       = 0.0,
    grass_max        = 0.0,
    grass_init_prob  = 0.0
  )
  env <- run_alife(s, verbose = FALSE)
  mbz    <- env$progress$mean_body_size
  counts <- env$progress$n_agents
  empty  <- counts == 0L
  if (any(empty)) {
    expect_true(all(mbz[empty] == 0.0),
                info = "mean_body_size should be 0 when population is empty")
  }
})

# ── 11. Large init_mean reflected in early mean_body_size ────────────────────
test_that("body_size_init_mean = 1.5 gives mean_body_size > 1 at tick 1", {
  skip_no_julia()
  s   <- .bs_specs(
    body_size_init_mean   = 1.5,
    body_size_mutation_sd = 0.0,
    max_ticks             = 5L,
    random_seed           = 7L
  )
  env <- run_alife(s, verbose = FALSE)
  mbz_t1 <- env$progress$mean_body_size[[1L]]
  expect_gt(mbz_t1, 1.0)
})

# ── 12. mean_body_size ≈ 1.0 at all active ticks when evolution is off ───────
test_that("mean_body_size = 1.0 at all active ticks when evolution is off", {
  skip_no_julia()
  s   <- .qs(max_ticks = 10L, random_seed = 2L)
  env <- run_alife(s, verbose = FALSE)
  mbz    <- env$progress$mean_body_size
  active <- env$progress$n_agents > 0L
  if (any(active)) {
    expect_true(all(abs(mbz[active] - 1.0) < 1e-9),
                info = "mean_body_size should equal 1.0 when evolution is off")
  }
})

# ── 13. sd_body_size >= 0 (non-negative) ─────────────────────────────────────
test_that("sd_body_size is non-negative at all ticks", {
  skip_no_julia()
  s   <- .bs_specs(max_ticks = 20L)
  env <- run_alife(s, verbose = FALSE)
  sdz <- env$progress$sd_body_size
  expect_true(all(sdz >= 0.0))
})

# ── 14. body_size_evolution works alongside kin_selection ─────────────────────
test_that("body_size_evolution = TRUE works with kin_selection = TRUE", {
  skip_no_julia()
  s <- .bs_specs(kin_selection = TRUE, max_ticks = 20L, random_seed = 5L)
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(as.integer(env$t) >= 1L)
})

# ── 15. body_size_evolution works alongside disease ───────────────────────────
test_that("body_size_evolution = TRUE works with disease = TRUE", {
  skip_no_julia()
  s <- .bs_specs(disease = TRUE, disease_seed_prob = 0.2, max_ticks = 20L)
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_true(as.integer(env$t) >= 1L)
})

# ── 16. get_run_data() exposes body size columns ──────────────────────────────
test_that("get_run_data()$ticks has mean_body_size and sd_body_size columns", {
  skip_no_julia()
  s    <- .bs_specs()
  env  <- run_alife(s, verbose = FALSE)
  data <- get_run_data(env)$ticks
  expect_true("mean_body_size" %in% names(data))
  expect_true("sd_body_size"   %in% names(data))
})

# ── 17. body_size_max is respected in long runs ───────────────────────────────
test_that("body_size never exceeds body_size_max in a 50-tick run", {
  skip_no_julia()
  s   <- .bs_specs(
    body_size_max         = 2.0,
    body_size_mutation_sd = 0.15,
    max_ticks             = 50L,
    random_seed           = 99L
  )
  env <- run_alife(s, verbose = FALSE)
  bs  <- .agent_bs(env)
  if (length(bs) > 0L) expect_true(all(bs <= 2.0 + 1e-6))
})

# ── 18. body_size_min is respected in long runs ───────────────────────────────
test_that("body_size never goes below body_size_min in a 50-tick run", {
  skip_no_julia()
  s   <- .bs_specs(
    body_size_min         = 0.5,
    body_size_mutation_sd = 0.15,
    max_ticks             = 50L,
    random_seed           = 77L
  )
  env <- run_alife(s, verbose = FALSE)
  bs  <- .agent_bs(env)
  if (length(bs) > 0L) expect_true(all(bs >= 0.5 - 1e-6))
})

# ── 19. mean_body_size varies over time when mutation is active ───────────────
test_that("mean_body_size varies across ticks when body_size_mutation_sd > 0", {
  skip_no_julia()
  s   <- .bs_specs(
    body_size_mutation_sd = 0.15,
    max_ticks             = 50L,
    random_seed           = 5L,
    grass_rate            = 0.8,
    n_agents_init         = 20L
  )
  env <- run_alife(s, verbose = FALSE)
  mbz    <- env$progress$mean_body_size
  active <- env$progress$n_agents > 0L
  if (sum(active) > 5L) {
    expect_gt(stats::sd(mbz[active]), 0.0,
              label = "mean_body_size should vary over time with mutation")
  }
})

# ── 20. default_specs() has body_size parameters with calibrated defaults ─────
test_that("default_specs() has body_size parameters with correct defaults", {
  s <- default_specs()
  expect_true("body_size_evolution" %in% names(s))
  expect_false(s$body_size_evolution)
  expect_true("body_size_min" %in% names(s))
  expect_equal(s$body_size_min, 0.3)
  expect_true("body_size_max" %in% names(s))
  expect_equal(s$body_size_max, 3.0)
  expect_true("body_size_mutation_sd" %in% names(s))
  expect_equal(s$body_size_mutation_sd, 0.08)
  expect_true("body_size_init_mean" %in% names(s))
  expect_equal(s$body_size_init_mean, 1.0)
})

# ── 21. body_size_init_mean defaults to 1.0 ──────────────────────────────────
test_that("body_size_init_mean defaults to 1.0", {
  expect_identical(default_specs()$body_size_init_mean, 1.0)
})

# ── 22. body_size_min defaults to 0.3 ────────────────────────────────────────
test_that("body_size_min defaults to 0.3", {
  expect_identical(default_specs()$body_size_min, 0.3)
})

# ── 23. body_size_max defaults to 3.0 ────────────────────────────────────────
test_that("body_size_max defaults to 3.0", {
  expect_identical(default_specs()$body_size_max, 3.0)
})

# ── 24. body_size_mutation_sd defaults to 0.08 ───────────────────────────────
test_that("body_size_mutation_sd defaults to 0.08", {
  expect_identical(default_specs()$body_size_mutation_sd, 0.08)
})

# ── 25. body_size_evolution defaults to FALSE ─────────────────────────────────
test_that("body_size_evolution defaults to FALSE", {
  expect_identical(default_specs()$body_size_evolution, FALSE)
})

# ── 26. body_size params round-trip through default_specs() ──────────────────
test_that("body_size params round-trip through default_specs()", {
  s <- default_specs()
  expect_equal(s$body_size_evolution,   FALSE)
  expect_equal(s$body_size_init_mean,   1.0)
  expect_equal(s$body_size_min,         0.3)
  expect_equal(s$body_size_max,         3.0)
  expect_equal(s$body_size_mutation_sd, 0.08)
})

# ── 27. mean_body_size > 0 at all active ticks with body_size_evolution = TRUE
test_that("mean_body_size > 0 for all active ticks when body_size_evolution = TRUE", {
  skip_no_julia()
  s   <- .bs_specs(body_size_init_mean = 2.5, max_ticks = 15L, random_seed = 11L)
  env <- run_alife(s, verbose = FALSE)
  mbz    <- env$progress$mean_body_size
  active <- env$progress$n_agents > 0L
  if (any(active)) expect_true(all(mbz[active] > 0.0))
})

# ── 28. mean_body_size is logged when body_size_init_mean = 2.5 ──────────────
test_that("mean_body_size column present with body_size_init_mean = 2.5", {
  skip_no_julia()
  s   <- .bs_specs(body_size_init_mean = 2.5, max_ticks = 10L, random_seed = 3L)
  env <- run_alife(s, verbose = FALSE)
  expect_true("mean_body_size" %in% names(env$progress))
  mbz <- env$progress$mean_body_size
  active <- env$progress$n_agents > 0L
  if (any(active)) expect_gt(mbz[which(active)[1L]], 0.0)
})

# ── 29. sd_body_size column present when body_size_evolution = TRUE ──────────
test_that("sd_body_size column present in env$progress when body_size_evolution = TRUE", {
  skip_no_julia()
  s   <- .bs_specs(max_ticks = 10L, random_seed = 4L)
  env <- run_alife(s, verbose = FALSE)
  expect_true("sd_body_size" %in% names(env$progress))
})

# ── 30. different body_size_init_mean values produce different mean_energy ────
test_that("body_size_init_mean = 0.5 vs 2.5 produces different mean_energy", {
  skip_no_julia()
  base <- .qs(
    body_size_evolution   = TRUE,
    body_size_mutation_sd = 0.0,
    max_ticks             = 5L,
    min_repro_energy      = 500.0,
    random_seed           = 42L
  )

  s_small <- base
  s_small$body_size_init_mean <- 0.5

  s_large <- base
  s_large$body_size_init_mean <- 2.5

  env_small <- run_alife(s_small, verbose = FALSE)
  env_large <- run_alife(s_large, verbose = FALSE)

  e_small_t1 <- env_small$progress$mean_energy[[1L]]
  e_large_t1 <- env_large$progress$mean_energy[[1L]]

  if (!is.nan(e_small_t1) && !is.nan(e_large_t1)) {
    # Body size scaling alters the energy budget; the two conditions should
    # diverge — we verify they are not identical rather than assuming direction.
    expect_false(isTRUE(all.equal(e_small_t1, e_large_t1, tolerance = 1e-3)))
  }
})
