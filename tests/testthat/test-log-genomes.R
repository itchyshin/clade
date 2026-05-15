# Tests for the log_genomes feature.
#
# Wired in 0.7.x (this commit). When specs$log_genomes = TRUE, the
# Julia kernel snapshots every alive agent's maternal_traits vector per
# log_freq ticks and pushes to env.genome_log. The R-side
# get_run_data() and get_genome_data() then compose a long
# (t, agent_id, trait_1..N) data.frame consumed by plot_tsne_genomes().
#
# These tests verify:
#  1. Default (log_genomes = FALSE) produces no genome data.
#  2. Enabling log_genomes populates env$genome_log with > 0 entries.
#  3. get_run_data()$genomes is NULL when log_genomes is off, a
#     data.frame when on.
#  4. The data.frame has the documented columns (t, agent_id,
#     trait_1..trait_N).
#  5. plot_tsne_genomes() returns a real ggplot, not the placeholder,
#     when genome data is present.

library(testthat)

test_that("default specs have log_genomes = FALSE (regression guard)", {
  expect_false(default_specs()$log_genomes)
})

test_that("log_genomes = FALSE produces empty genome_log + NULL $genomes", {
  skip_no_julia()
  s <- default_specs()
  s$max_ticks      <- 50L
  s$random_seed    <- 11L
  s$n_agents_init  <- 20L
  s$log_genomes    <- FALSE
  env <- run_alife(s, verbose = FALSE)
  expect_length(env$genome_log, 0L)
  rd <- get_run_data(env)
  expect_null(rd$genomes)
})

test_that("log_genomes = TRUE populates the log with trait matrices", {
  skip_no_julia()
  s <- default_specs()
  s$max_ticks      <- 50L
  s$random_seed    <- 11L
  s$n_agents_init  <- 20L
  s$log_genomes    <- TRUE
  s$log_freq       <- 10L           # 5 snapshots over 50 ticks
  env <- run_alife(s, verbose = FALSE)
  expect_gt(length(env$genome_log), 0L,
            label = "env$genome_log should accumulate per-tick entries")

  # Each entry is a Julia Dict materialised via JuliaConnectoR::juliaGet
  # into a list with $keys and $values.
  raw   <- JuliaConnectoR::juliaGet(env$genome_log[[1L]])
  keys  <- unlist(raw$keys, use.names = FALSE)
  entry <- setNames(raw$values, keys)
  expect_true(all(c("t", "agent_ids", "traits") %in% keys),
              info = paste("entry keys:", paste(keys, collapse = ", ")))
  expect_type(entry$t, "integer")
  expect_true(is.matrix(entry$traits))
  # Columns of traits = N_SCALAR_TRAITS in the Julia kernel (22 as of 0.7.0).
  expect_equal(ncol(entry$traits), 22L)
  # Rows = number of alive agents at that snapshot.
  expect_equal(nrow(entry$traits), length(entry$agent_ids))
})

test_that("get_run_data()$genomes returns the expected long data.frame", {
  skip_no_julia()
  s <- default_specs()
  s$max_ticks      <- 50L
  s$random_seed    <- 11L
  s$n_agents_init  <- 20L
  s$log_genomes    <- TRUE
  s$log_freq       <- 10L
  env <- run_alife(s, verbose = FALSE)

  rd <- get_run_data(env)
  expect_s3_class(rd$genomes, "data.frame")
  expect_true(all(c("t", "agent_id") %in% names(rd$genomes)))
  expect_true(any(grepl("^trait_", names(rd$genomes))),
              info = paste("columns:", paste(names(rd$genomes), collapse = ", ")))
  expect_gt(nrow(rd$genomes), 0L)
})

test_that("plot_tsne_genomes() returns a non-placeholder ggplot when log_genomes is on", {
  skip_no_julia()
  s <- default_specs()
  s$max_ticks                  <- 80L
  s$random_seed                <- 11L
  s$n_agents_init              <- 30L
  s$log_genomes                <- TRUE
  s$log_freq                   <- 10L
  # Enable a couple of trait-evolution flags so the genome matrix has
  # non-zero variance in at least two columns (prcomp drops zero-var cols).
  s$body_size_evolution        <- TRUE
  s$metabolic_rate_evolution   <- TRUE
  env <- run_alife(s, verbose = FALSE)
  rd  <- get_run_data(env)

  p <- plot_tsne_genomes(rd)
  expect_s3_class(p, "ggplot")
  # The placeholder has a single annotation text layer; a real PCA plot
  # has a geom_point layer. Check for geom_point as the distinguishing
  # feature.
  layer_geoms <- vapply(p$layers, function(l) class(l$geom)[1L], character(1L))
  expect_true(any(grepl("GeomPoint", layer_geoms)),
              info = "plot_tsne_genomes should produce a scatter, not the placeholder")
})
