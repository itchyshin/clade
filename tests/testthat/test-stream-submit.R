# Tests for stream_specs_to_csv() and submit_sweep_slurm() — the two
# Tier A5 (utilities) functions that previously had no dedicated tests
# (per dev/audit/r-function-walk.md, Phase A item 28 "Deferred").
#
# Both functions are scaffolding for large-sweep workflows (millions
# of runs to disk; SLURM array fan-out). They don't run Julia
# themselves — stream_specs_to_csv() calls run_alife(), submit_sweep_slurm()
# emits an .sh script. We test both with no-Julia mocks.

library(testthat)

# ── stream_specs_to_csv ─────────────────────────────────────────────────

# Synthetic env that mimics what run_alife() returns. Populated with
# the bare minimum that summary_fn touches.
.fake_env <- function(n_final = 50, mean_energy = 1.5, diversity = 0.3,
                      verdict = "viable") {
  list(
    progress  = list(
      n_agents          = c(50, 60, n_final),
      mean_energy       = c(1.0, 1.2, mean_energy),
      genetic_diversity = c(0.1, 0.2, diversity)
    ),
    viability = list(verdict = verdict)
  )
}

test_that("stream_specs_to_csv validates input shape", {
  expect_error(stream_specs_to_csv(specs_list = "not a list",
                                   out_path   = tempfile(fileext = ".csv")),
               "is.list")
  expect_error(stream_specs_to_csv(specs_list = list(),
                                   out_path   = tempfile(fileext = ".csv")),
               "length")
  expect_error(stream_specs_to_csv(specs_list = list(list(a = 1L)),
                                   out_path   = 123L),
               "is.character")
})

test_that("stream_specs_to_csv writes one CSV row per spec with header", {
  csv  <- tempfile(fileext = ".csv")
  on.exit(unlink(csv), add = TRUE)

  # All three specs use the same non-default grass_rate so the default
  # summary_fn produces the same column set for every row (CSV column
  # alignment depends on this — varying-shape rows are a separate
  # known-issue we don't exercise here).
  specs_list <- list(
    s1 = list(grass_rate = 0.10),
    s2 = list(grass_rate = 0.10),
    s3 = list(grass_rate = 0.10)
  )

  local_mocked_bindings(
    run_alife    = function(specs, verbose = TRUE) .fake_env(),
    default_specs = function() list(grass_rate = 0.05)
  )

  res <- stream_specs_to_csv(specs_list, csv, n_cores = 1L)
  expect_equal(res, csv)
  expect_true(file.exists(csv))

  out <- utils::read.csv(csv, stringsAsFactors = FALSE)
  expect_equal(nrow(out), 3L)
  expect_setequal(out$run_id, c("s1", "s2", "s3"))
  expect_true("viability" %in% names(out))
  expect_true(all(out$viability == "viable"))
})

test_that("stream_specs_to_csv resumes by skipping run_ids already in CSV", {
  csv  <- tempfile(fileext = ".csv")
  on.exit(unlink(csv), add = TRUE)

  # Uniform shape so the CSV column set is stable across rows.
  specs_list <- list(
    s1 = list(grass_rate = 0.10),
    s2 = list(grass_rate = 0.10),
    s3 = list(grass_rate = 0.10)
  )

  call_count <- 0L
  local_mocked_bindings(
    run_alife    = function(specs, verbose = TRUE) {
      call_count <<- call_count + 1L
      .fake_env()
    },
    default_specs = function() list(grass_rate = 0.05)
  )

  # First call: 3 runs invoked
  stream_specs_to_csv(specs_list, csv, n_cores = 1L)
  expect_equal(call_count, 3L)

  # Second call with resume=TRUE (default): all 3 already in CSV, so 0 new
  call_count <- 0L
  expect_message(
    stream_specs_to_csv(specs_list, csv, n_cores = 1L),
    "nothing to do"
  )
  expect_equal(call_count, 0L)

  # Second call with resume=FALSE: overwrites; all 3 invoked again
  # (file is truncated by the header rewrite, not by us — verify rowcount).
  call_count <- 0L
  unlink(csv)
  stream_specs_to_csv(specs_list, csv, n_cores = 1L, resume = FALSE)
  expect_equal(call_count, 3L)
})

test_that("stream_specs_to_csv records error_msg when run_alife() fails", {
  csv  <- tempfile(fileext = ".csv")
  on.exit(unlink(csv), add = TRUE)

  specs_list <- list(s1 = list(grass_rate = 0.05))

  local_mocked_bindings(
    run_alife    = function(specs, verbose = TRUE) stop("boom"),
    default_specs = function() list(grass_rate = 0.05)
  )

  stream_specs_to_csv(specs_list, csv, n_cores = 1L)
  out <- utils::read.csv(csv, stringsAsFactors = FALSE)
  expect_equal(nrow(out), 1L)
  expect_equal(out$run_id, "s1")
  expect_equal(out$error_msg, "run_alife failed")
})

test_that("stream_specs_to_csv honours a custom summary_fn", {
  csv  <- tempfile(fileext = ".csv")
  on.exit(unlink(csv), add = TRUE)

  specs_list <- list(s1 = list(grass_rate = 0.05))

  local_mocked_bindings(
    run_alife    = function(specs, verbose = TRUE)
      .fake_env(n_final = 99, mean_energy = 7.7),
    default_specs = function() list(grass_rate = 0.05)
  )

  summary_fn <- function(env, specs) {
    list(
      custom_a = 42L,
      custom_b = tail(env$progress$n_agents, 1L),
      passed_grass = specs$grass_rate
    )
  }
  stream_specs_to_csv(specs_list, csv, summary_fn = summary_fn, n_cores = 1L)
  out <- utils::read.csv(csv, stringsAsFactors = FALSE)
  expect_equal(out$custom_a,     42L)
  expect_equal(out$custom_b,     99)
  expect_equal(out$passed_grass, 0.05)
})

test_that("stream_specs_to_csv auto-numbers run_ids when specs_list is unnamed", {
  csv  <- tempfile(fileext = ".csv")
  on.exit(unlink(csv), add = TRUE)

  # Both specs use the same non-default grass_rate (uniform shape).
  specs_list <- list(list(grass_rate = 0.10), list(grass_rate = 0.10))

  local_mocked_bindings(
    run_alife    = function(specs, verbose = TRUE) .fake_env(),
    default_specs = function() list(grass_rate = 0.05)
  )

  stream_specs_to_csv(specs_list, csv, n_cores = 1L)
  out <- utils::read.csv(csv, stringsAsFactors = FALSE)
  expect_setequal(out$run_id, c("run_000001", "run_000002"))
})

# ── submit_sweep_slurm ──────────────────────────────────────────────────

test_that("submit_sweep_slurm validates input shape", {
  td <- withr::local_tempdir()
  expect_error(submit_sweep_slurm(specs_list  = "nope",
                                  out_path    = file.path(td, "o.csv"),
                                  script_path = file.path(td, "s.sh"),
                                  rds_path    = file.path(td, "p.rds")),
               "is.list")
  expect_error(submit_sweep_slurm(specs_list  = list(),
                                  out_path    = file.path(td, "o.csv"),
                                  script_path = file.path(td, "s.sh"),
                                  rds_path    = file.path(td, "p.rds")),
               "length")
  expect_error(submit_sweep_slurm(specs_list  = list(list(grass_rate = 0.05)),
                                  out_path    = 1L,
                                  script_path = file.path(td, "s.sh"),
                                  rds_path    = file.path(td, "p.rds")),
               "is.character")
})

test_that("submit_sweep_slurm writes .sh + .rds with correct directives", {
  td <- withr::local_tempdir()
  out_path    <- file.path(td, "out.csv")
  script_path <- file.path(td, "submit.sh")
  rds_path    <- file.path(td, "specs.rds")

  specs_list <- lapply(1:10, function(i) list(grass_rate = 0.05 * i,
                                              mutation_sd = 0.05))

  res <- suppressMessages(submit_sweep_slurm(
    specs_list,
    out_path         = out_path,
    script_path      = script_path,
    rds_path         = rds_path,
    n_array_tasks    = 5L,
    n_cores_per_task = 2L,
    time             = "01:00:00",
    mem              = "4G"
  ))
  expect_equal(res, script_path)

  # Both files exist
  expect_true(file.exists(script_path))
  expect_true(file.exists(rds_path))

  # Script directives
  sh <- readLines(script_path)
  expect_match(sh[1], "^#!/bin/bash")
  expect_true(any(grepl("#SBATCH --array=1-5",         sh)))
  expect_true(any(grepl("#SBATCH --cpus-per-task=2",   sh)))
  expect_true(any(grepl("#SBATCH --time=01:00:00",     sh)))
  expect_true(any(grepl("#SBATCH --mem=4G",            sh)))
  expect_true(any(grepl("set -euo pipefail",           sh)))
  expect_true(any(grepl("Rscript -e",                  sh)))

  # Chunk-size math: ceil(10 / 5) = 2 per task
  expect_true(any(grepl("chunk_size <- 2L", sh)))

  # RDS payload shape
  payload <- readRDS(rds_path)
  expect_named(payload, c("specs_list", "summary_fn"))
  expect_length(payload$specs_list, 10L)
  expect_null(payload$summary_fn)

  # Script is executable (0755 on POSIX = at least owner-execute)
  if (.Platform$OS.type == "unix") {
    mode <- file.info(script_path)$mode
    expect_true(file.access(script_path, mode = 1) == 0,
                info = sprintf("script not executable: mode=%s", format(mode)))
  }
})

test_that("submit_sweep_slurm default n_array_tasks is min(100, N)", {
  td <- withr::local_tempdir()
  script_path <- file.path(td, "submit.sh")
  rds_path    <- file.path(td, "specs.rds")

  # Small N → array=1-N
  specs_list <- lapply(1:7, function(i) list(grass_rate = 0.05))
  suppressMessages(submit_sweep_slurm(
    specs_list,
    out_path    = "/tmp/o.csv",
    script_path = script_path,
    rds_path    = rds_path
  ))
  sh <- readLines(script_path)
  expect_true(any(grepl("#SBATCH --array=1-7", sh)))

  # Large N → capped at 100
  specs_list <- lapply(1:500, function(i) list(grass_rate = 0.05))
  suppressMessages(submit_sweep_slurm(
    specs_list,
    out_path    = "/tmp/o.csv",
    script_path = script_path,
    rds_path    = rds_path
  ))
  sh <- readLines(script_path)
  expect_true(any(grepl("#SBATCH --array=1-100", sh)))
  expect_true(any(grepl("chunk_size <- 5L", sh))) # ceil(500/100) = 5
})

test_that("submit_sweep_slurm injects R_library_path and extra_sbatch_lines", {
  td <- withr::local_tempdir()
  script_path <- file.path(td, "submit.sh")
  rds_path    <- file.path(td, "specs.rds")

  specs_list <- lapply(1:3, function(i) list(grass_rate = 0.05))

  suppressMessages(submit_sweep_slurm(
    specs_list,
    out_path           = "/tmp/o.csv",
    script_path        = script_path,
    rds_path           = rds_path,
    R_library_path     = "/shared/R-libs/clade-0.7.0",
    extra_sbatch_lines = c("--partition=long", "--qos=high")
  ))
  sh <- readLines(script_path)
  expect_true(any(grepl('.libPaths\\(c\\("/shared/R-libs/clade-0\\.7\\.0"', sh)))
  expect_true(any(grepl("#SBATCH --partition=long", sh)))
  expect_true(any(grepl("#SBATCH --qos=high",       sh)))
})

test_that("submit_sweep_slurm names unnamed specs_list automatically", {
  td <- withr::local_tempdir()
  script_path <- file.path(td, "submit.sh")
  rds_path    <- file.path(td, "specs.rds")

  specs_list <- lapply(1:3, function(i) list(grass_rate = 0.05 * i))
  suppressMessages(submit_sweep_slurm(
    specs_list,
    out_path    = "/tmp/o.csv",
    script_path = script_path,
    rds_path    = rds_path
  ))
  payload <- readRDS(rds_path)
  expect_equal(names(payload$specs_list),
               c("run_000001", "run_000002", "run_000003"))
})
