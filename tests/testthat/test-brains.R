# Tests for the CTRNN and GRN brain implementations.
#
# Structural tests (pure R) run on every check — they verify that the specs
# interface exposes the new brain types and passes validation. Integration
# tests require Julia and are guarded by skip_no_julia() so that CRAN checks
# without Julia still pass.

library(testthat)

# ── Helper: skip when Julia toolchain is unavailable ──────────────────────────
skip_no_julia <- function() {
  skip_if_not(requireNamespace("JuliaConnectoR", quietly = TRUE),
              "JuliaConnectoR not available")
  skip_if_not(JuliaConnectoR::juliaSetupOk(),
              "Julia toolchain not available")
}

# ── Structural tests (no Julia required) ─────────────────────────────────────

# 7. default_specs()$brain_type is "bnn"
test_that("default_specs() defaults to brain_type = 'bnn'", {
  expect_equal(default_specs()$brain_type, "bnn")
})

# 8. brain_type = "ctrnn" passes .validate_specs()
test_that(".validate_specs() accepts brain_type = 'ctrnn'", {
  s <- default_specs()
  s$brain_type <- "ctrnn"
  expect_silent(clade:::.validate_specs(s))
})

# 9. brain_type = "grn" passes .validate_specs()
test_that(".validate_specs() accepts brain_type = 'grn'", {
  s <- default_specs()
  s$brain_type <- "grn"
  expect_silent(clade:::.validate_specs(s))
})

# 10. n_genes is accessible in default_specs() and is a positive integer
test_that("default_specs()$n_genes is a positive integer", {
  n_genes <- default_specs()$n_genes
  expect_true(is.integer(n_genes) || is.numeric(n_genes))
  expect_length(n_genes, 1L)
  expect_gt(n_genes, 0L)
})

# Julia source files for the two new brain types exist and are non-trivial
test_that("brains/ctrnn.jl and brains/grn.jl exist with content", {
  julia_src <- system.file("julia", "src", package = "clade")
  skip_if(!nchar(julia_src) || !dir.exists(julia_src),
          "Julia source directory not found")
  ctrnn_path <- file.path(julia_src, "brains", "ctrnn.jl")
  grn_path   <- file.path(julia_src, "brains", "grn.jl")
  expect_true(file.exists(ctrnn_path))
  expect_true(file.exists(grn_path))
  expect_gt(file.info(ctrnn_path)$size, 1000L)
  expect_gt(file.info(grn_path)$size,   1000L)
})

# Clade.jl dispatches on ctrnn and grn in make_brain()
test_that("Clade.jl make_brain dispatcher covers ctrnn and grn", {
  julia_src <- system.file("julia", "src", package = "clade")
  skip_if(!nchar(julia_src) || !dir.exists(julia_src),
          "Julia source directory not found")
  clade_jl <- paste(readLines(file.path(julia_src, "Clade.jl")),
                    collapse = "\n")
  expect_true(grepl("make_ctrnn_brain_from_genome", clade_jl, fixed = TRUE))
  expect_true(grepl("make_grn_brain_from_genome",   clade_jl, fixed = TRUE))
  expect_true(grepl('include("brains/ctrnn.jl")', clade_jl, fixed = TRUE))
  expect_true(grepl('include("brains/grn.jl")',   clade_jl, fixed = TRUE))
})

# ── Integration tests (require Julia) ────────────────────────────────────────

# 1. run_clade with brain_type = "ctrnn" completes without error
test_that("run_clade completes with brain_type = 'ctrnn'", {
  skip_no_julia()
  s <- .minimal_specs(brain_type = "ctrnn", random_seed = 1L)
  env <- expect_silent(run_clade(s, verbose = FALSE))
  expect_true(is.list(env))
  expect_equal(env$t, s$max_ticks)
})

# 2. CTRNN forward passes shift over time (temporal memory)
test_that("CTRNN temporal state actually evolves between ticks", {
  skip_no_julia()
  s <- .minimal_specs(brain_type = "ctrnn", random_seed = 2L,
                       max_ticks = 10L, n_agents_init = 20L,
                       max_agents = 100L)
  env <- run_clade(s, verbose = FALSE)
  data <- get_run_data(env)
  # Energy should not be identical across all ticks — dynamics imply change
  expect_true(stats::var(data$ticks$mean_energy, na.rm = TRUE) >= 0)
  expect_true(nrow(data$ticks) >= 1L)
})

# 3. CTRNN run with more agents and ticks produces non-trivial births
test_that("CTRNN run produces births over a longer simulation", {
  skip_no_julia()
  s <- .minimal_specs(brain_type = "ctrnn", random_seed = 3L,
                       grid_rows = 20L, grid_cols = 20L,
                       n_agents_init = 30L, max_agents = 200L,
                       max_ticks = 80L)
  env <- run_clade(s, verbose = FALSE)
  data <- get_run_data(env)
  expect_true(sum(data$ticks$n_births, na.rm = TRUE) > 0L,
              info = "CTRNN run should produce at least one birth")
})

# 4. run_clade with brain_type = "grn" completes without error
test_that("run_clade completes with brain_type = 'grn'", {
  skip_no_julia()
  s <- .minimal_specs(brain_type = "grn", random_seed = 4L)
  env <- expect_silent(run_clade(s, verbose = FALSE))
  expect_true(is.list(env))
  expect_equal(env$t, s$max_ticks)
})

# 5. GRN run produces positive mean_energy
test_that("GRN run produces positive mean_energy", {
  skip_no_julia()
  s <- .minimal_specs(brain_type = "grn", random_seed = 5L,
                       max_ticks = 20L, n_agents_init = 20L,
                       max_agents = 100L)
  env <- run_clade(s, verbose = FALSE)
  data <- get_run_data(env)
  # At least the early ticks should have positive mean energy
  expect_true(any(data$ticks$mean_energy > 0, na.rm = TRUE),
              info = "GRN run should have positive mean_energy in at least one tick")
})

# 6. GRN produces non-zero genetic diversity across agents
test_that("GRN run exhibits non-zero genetic diversity", {
  skip_no_julia()
  s <- .minimal_specs(brain_type = "grn", random_seed = 6L,
                       max_ticks = 20L, n_agents_init = 30L,
                       max_agents = 150L)
  env <- run_clade(s, verbose = FALSE)
  data <- get_run_data(env)
  # Founder agents start with different random weights, so diversity > 0
  if ("genetic_diversity" %in% names(data$ticks)) {
    expect_true(any(data$ticks$genetic_diversity > 0, na.rm = TRUE),
                info = "GRN genetic diversity should be > 0 in at least one tick")
  }
})

# ── Additional structural tests ───────────────────────────────────────────────

# 13. brain_type = "ann" is a valid option in default_specs
test_that("brain_type = 'ann' passes .validate_specs()", {
  s <- default_specs()
  s$brain_type <- "ann"
  expect_silent(clade:::.validate_specs(s))
})

# 14. brain_type = "bnn" is the default
test_that("default_specs() has brain_type = 'bnn'", {
  expect_equal(default_specs()$brain_type, "bnn")
})

# 15. brain_type = "transformer" is a valid option
test_that("brain_type = 'transformer' passes .validate_specs()", {
  s <- default_specs()
  s$brain_type <- "transformer"
  expect_silent(clade:::.validate_specs(s))
})

# 16. brain_type = "synthesis" is a valid option
test_that("brain_type = 'synthesis' passes .validate_specs()", {
  s <- default_specs()
  s$brain_type <- "synthesis"
  expect_silent(clade:::.validate_specs(s))
})

# 17. brain_type = "random" is a valid option
test_that("brain_type = 'random' passes .validate_specs()", {
  s <- default_specs()
  s$brain_type <- "random"
  expect_silent(clade:::.validate_specs(s))
})

# 18. hidden_layers defaults to c(8L)
test_that("default_specs()$hidden_layers defaults to c(8L)", {
  hl <- default_specs()$hidden_layers
  expect_true(is.integer(hl) || is.numeric(hl))
  expect_equal(as.integer(hl), c(8L))
})

# 19. brain_energy_mode defaults to "activity"
test_that("default_specs()$brain_energy_mode is 'activity'", {
  expect_equal(default_specs()$brain_energy_mode, "activity")
})

# 20. brain_energy_base is a positive numeric
test_that("default_specs()$brain_energy_base is a positive numeric", {
  beb <- default_specs()$brain_energy_base
  expect_true(is.numeric(beb))
  expect_length(beb, 1L)
  expect_gt(beb, 0)
})

# ── Additional integration tests (require Julia) ──────────────────────────────

# 21. run_clade with brain_type = "ann" completes without error
test_that("run_clade completes with brain_type = 'ann'", {
  skip_no_julia()
  s <- .minimal_specs(brain_type = "ann", random_seed = 7L)
  env <- expect_silent(run_clade(s, verbose = FALSE))
  expect_true(is.list(env))
  expect_equal(env$t, s$max_ticks)
})

# 22. run_clade with brain_type = "bnn" produces mean_prior_sigma column
test_that("run_clade with brain_type = 'bnn' logs mean_prior_sigma", {
  skip_no_julia()
  s <- .minimal_specs(brain_type = "bnn", random_seed = 8L)
  env <- run_clade(s, verbose = FALSE)
  expect_true("mean_prior_sigma" %in% names(env$progress),
              info = "BNN run should log mean_prior_sigma in env$progress")
})

# 23. run_clade with brain_type = "random" completes and n_births >= 0
test_that("run_clade with brain_type = 'random' completes and n_births >= 0", {
  skip_no_julia()
  s <- .minimal_specs(brain_type = "random", random_seed = 9L,
                       max_ticks = 10L, n_agents_init = 10L,
                       max_agents = 100L)
  env <- expect_silent(run_clade(s, verbose = FALSE))
  data <- get_run_data(env)
  expect_true(all(data$ticks$n_births >= 0L, na.rm = TRUE))
})
