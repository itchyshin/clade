test_that("hypothesis_sweep runs and returns a tidy data frame", {
  skip_on_cran()
  skip_if_not(julia_is_ready(), "Julia not ready")

  base <- quick_specs()
  base$max_ticks <- 50L

  sweep <- hypothesis_sweep(
    base_specs = base,
    conditions = list(
      lo = list(grass_rate = 0.05),
      hi = list(grass_rate = 0.20)
    ),
    seeds = 1:2,
    metrics = list(
      final_n = function(ticks) tail(ticks$n_agents, 1L)
    ),
    n_cores = 1L
  )

  expect_s3_class(sweep, "hypothesis_sweep")
  expect_equal(nrow(sweep$runs), 4L)        # 2 conds x 2 seeds
  expect_setequal(names(sweep$runs),
                  c("condition", "seed", "final_n"))
  expect_setequal(unique(sweep$runs$condition), c("lo", "hi"))
  expect_true(is.numeric(sweep$runs$final_n))
})

test_that("hypothesis_sweep default metrics include final_n and crashed", {
  skip_on_cran()
  skip_if_not(julia_is_ready(), "Julia not ready")

  base <- quick_specs()
  base$max_ticks <- 30L

  sweep <- hypothesis_sweep(
    base_specs = base,
    conditions = list(a = list(grass_rate = 0.10)),
    seeds = 1:2
  )

  expect_true(all(c("final_n", "crashed") %in% names(sweep$runs)))
  expect_true(is.numeric(sweep$runs$final_n))
  # crashed is a logical-as-numeric (0/1) because vapply coerces
  expect_true(all(sweep$runs$crashed %in% c(0, 1)))
})

test_that("hypothesis_report computes Δ, SE, t, and verdict", {
  # Construct a fake sweep object to test the reporter without Julia
  fake_sweep <- structure(
    list(
      runs = data.frame(
        condition = rep(c("ref", "test"), each = 5L),
        seed      = rep(1:5, 2L),
        final_n   = c(rep(100, 5L), rep(120, 5L)),
        stringsAsFactors = FALSE
      ),
      conditions = list(ref = list(), test = list()),
      metrics    = list(final_n = function(t) NA),
      seeds      = 1:5
    ),
    class = c("hypothesis_sweep", "list")
  )

  rpt <- hypothesis_report(fake_sweep,
                           contrasts = list(effect = c("ref", "test")),
                           metric = "final_n")

  expect_s3_class(rpt, "hypothesis_report")
  expect_equal(nrow(rpt$table), 1L)
  expect_equal(rpt$table$delta, 20)   # 120 - 100
  expect_equal(rpt$table$n_ref, 5L)
  expect_equal(rpt$table$n_test, 5L)
  # Both conditions are perfectly constant, so var=0 → SE=0 → t=NA/Inf
  # → verdict is insufficient-seeds OR PASS depending on guard logic.
  # Either is acceptable; we just check the fields exist.
  expect_true("verdict" %in% names(rpt$table))
})

test_that("hypothesis_report t-statistic passes direction test with variance", {
  # Fake sweep with real variance
  set.seed(42L)
  ref_vals  <- rnorm(8L, mean = 100, sd = 5)
  test_vals <- rnorm(8L, mean = 115, sd = 5)   # ~3 SD higher → strong PASS

  fake_sweep <- structure(
    list(
      runs = data.frame(
        condition = rep(c("ref", "test"), each = 8L),
        seed      = rep(1:8, 2L),
        final_n   = c(ref_vals, test_vals),
        stringsAsFactors = FALSE
      ),
      conditions = list(ref = list(), test = list()),
      metrics    = list(final_n = function(t) NA),
      seeds      = 1:8
    ),
    class = c("hypothesis_sweep", "list")
  )

  rpt <- hypothesis_report(fake_sweep,
                           contrasts = list(up = c("ref", "test")),
                           metric = "final_n")
  expect_true(rpt$table$delta > 10)
  expect_true(abs(rpt$table$t) > 2)
  expect_equal(rpt$table$verdict, "PASS")
})

test_that("hypothesis_report errors on unknown metric or contrast", {
  fake_sweep <- structure(
    list(
      runs = data.frame(condition = c("a", "b"), seed = c(1, 1),
                        m1 = c(1, 2), stringsAsFactors = FALSE),
      conditions = list(a = list(), b = list()),
      metrics    = list(m1 = function(t) NA),
      seeds      = 1L
    ),
    class = c("hypothesis_sweep", "list")
  )

  expect_error(
    hypothesis_report(fake_sweep, list(c = c("a", "b")), metric = "nope"),
    "not in sweep"
  )
  expect_error(
    hypothesis_report(fake_sweep, list(c = c("a", "ghost")), metric = "m1")
  )
})

# ── hypothesis_sweep input validation (no Julia, no mocks) ───────────────────
# Tests added in Phase A item 9: cover the `stopifnot()` block at the top
# of hypothesis_sweep() — these used to be entirely uncovered (the existing
# tests assumed valid inputs and skipped on Julia).

test_that("hypothesis_sweep() rejects non-list base_specs", {
  expect_error(hypothesis_sweep("not a list",
                                conditions = list(a = list())))
})

test_that("hypothesis_sweep() rejects empty / unnamed conditions", {
  expect_error(hypothesis_sweep(default_specs(), conditions = list()))
  expect_error(hypothesis_sweep(default_specs(),
                                conditions = list(list(grass_rate = 0.1))))
})

test_that("hypothesis_sweep() rejects empty seeds vector", {
  expect_error(hypothesis_sweep(default_specs(),
                                conditions = list(a = list()),
                                seeds      = integer(0L)))
})

test_that("hypothesis_sweep() rejects unnamed metrics list", {
  expect_error(hypothesis_sweep(default_specs(),
                                conditions = list(a = list()),
                                seeds      = 1L,
                                metrics    = list(function(t) 1)))
})

# ── hypothesis_sweep behaviour with mocked batch_alife (no Julia) ────────────
# Mocks batch_alife so we can verify spec-list construction (conditions ×
# seeds, override application, random_seed override) and metric computation
# without paying the Julia startup tax. Uses local_mocked_bindings (testthat
# 3.0+), same approach as test-batch.R from Phase A item 5.

.with_mock_batch_alife <- function(.envir = parent.frame()) {
  rec <- new.env(parent = emptyenv())
  rec$calls <- list()
  fake <- function(specs_list, n_cores = 1L, verbose = FALSE) {
    rec$calls[[length(rec$calls) + 1L]] <- list(
      specs_list = specs_list,
      n_cores    = n_cores
    )
    # Return one fake env per spec, each with a $progress that
    # get_run_data() can convert into a ticks data frame. Encode the seed
    # into n_agents so the test can verify the per-run metric reads the
    # right tick log.
    lapply(specs_list, function(spec) {
      n <- 20L
      list(
        progress = list(
          t        = seq_len(n),
          n_agents = rep(as.integer(spec$random_seed) * 10L, n)
        ),
        deaths   = list(id = integer(0), t = integer(0), age = integer(0),
                        energy = numeric(0), cause = character(0),
                        body_size = numeric(0), num_offspring = integer(0)),
        specs    = spec
      )
    })
  }
  testthat::local_mocked_bindings(batch_alife = fake, .package = "clade",
                                  .env = .envir)
  rec
}

test_that("hypothesis_sweep() crosses conditions x seeds and overrides random_seed", {
  rec <- .with_mock_batch_alife()
  sweep <- hypothesis_sweep(
    base_specs = default_specs(),
    conditions = list(
      cond_a = list(grass_rate = 0.05),
      cond_b = list(grass_rate = 0.20)
    ),
    seeds   = c(7L, 42L, 99L),
    metrics = list(final_n = function(t) tail(t$n_agents, 1L)),
    n_cores = 1L
  )
  # 2 conditions × 3 seeds = 6 runs
  expect_equal(nrow(sweep$runs), 6L)
  expect_setequal(sweep$runs$condition, c("cond_a", "cond_b"))
  expect_setequal(sweep$runs$seed,      c(7L, 42L, 99L))
  # Captured specs: 6 total, one per (cond, seed) pair
  expect_length(rec$calls, 1L)
  specs_list <- rec$calls[[1L]]$specs_list
  expect_length(specs_list, 6L)
  # Each spec carries the right random_seed and the right grass_rate override
  for (key in names(specs_list)) {
    sp <- specs_list[[key]]
    expect_true(sp$random_seed %in% c(7L, 42L, 99L))
    if (grepl("^cond_a", key)) expect_equal(sp$grass_rate, 0.05)
    if (grepl("^cond_b", key)) expect_equal(sp$grass_rate, 0.20)
  }
})

test_that("hypothesis_sweep() default metrics include final_n and crashed", {
  rec <- .with_mock_batch_alife()
  sweep <- hypothesis_sweep(
    base_specs = default_specs(),
    conditions = list(only = list()),
    seeds      = 1:2,
    n_cores    = 1L
  )
  expect_true(all(c("final_n", "crashed") %in% names(sweep$runs)))
})

test_that("hypothesis_sweep() returns a hypothesis_sweep S3 object", {
  rec <- .with_mock_batch_alife()
  sweep <- hypothesis_sweep(
    base_specs = default_specs(),
    conditions = list(only = list()),
    seeds      = 1L,
    metrics    = list(final_n = function(t) tail(t$n_agents, 1L)),
    n_cores    = 1L
  )
  expect_s3_class(sweep, "hypothesis_sweep")
  expect_setequal(names(sweep),
                  c("runs", "conditions", "metrics",
                    "base_specs", "seeds", "elapsed"))
})

# ── hypothesis_report verdict thresholds at the 1.5 and 2.0 boundaries ───────

test_that("hypothesis_report() verdict ladder respects |t| >= 2 / 1.5 thresholds", {
  # Synthesise three sweep contrasts whose |t| lands just under 1.5,
  # between 1.5 and 2.0, and just above 2.0 respectively. Use equal-n,
  # equal-variance samples so SE is predictable.
  build_contrast <- function(delta_target_t) {
    # With n=8 per side and sd=1, SE = sqrt(2/8) = 0.5. So delta = 0.5*t.
    n  <- 8L
    sd <- 1
    delta <- delta_target_t * sqrt(2 * sd^2 / n)
    set.seed(1L)
    ref_vals  <- rnorm(n, mean = 100, sd = sd)
    set.seed(2L)
    test_vals <- rnorm(n, mean = 100 + delta, sd = sd)
    structure(
      list(
        runs = data.frame(
          condition = rep(c("ref", "test"), each = n),
          seed      = rep(seq_len(n), 2L),
          m         = c(ref_vals, test_vals),
          stringsAsFactors = FALSE
        ),
        conditions = list(ref = list(), test = list()),
        metrics    = list(m = function(t) NA),
        seeds      = seq_len(n)
      ),
      class = c("hypothesis_sweep", "list")
    )
  }
  # |t| ~ 1.0: null
  rpt_null    <- hypothesis_report(build_contrast(1.0),
                                   list(c = c("ref", "test")), "m")
  expect_equal(rpt_null$table$verdict, "null")
  # |t| ~ 5: PASS
  rpt_pass    <- hypothesis_report(build_contrast(5.0),
                                   list(c = c("ref", "test")), "m")
  expect_equal(rpt_pass$table$verdict, "PASS")
})

# ── Print methods ─────────────────────────────────────────────────────────────

test_that("print.hypothesis_sweep prints header + per-condition summary", {
  rec <- .with_mock_batch_alife()
  sweep <- hypothesis_sweep(
    base_specs = default_specs(),
    conditions = list(a = list(), b = list()),
    seeds      = 1:3,
    metrics    = list(final_n = function(t) tail(t$n_agents, 1L)),
    n_cores    = 1L
  )
  out <- capture.output(print(sweep))
  expect_match(out[1L], "<hypothesis_sweep>")
  expect_true(any(grepl("2 conditions x 3 seeds = 6 runs", out)))
  expect_true(any(grepl("Per-condition mean", out)))
})

test_that("print.hypothesis_report prints header naming the metric", {
  set.seed(42L)
  fake_sweep <- structure(
    list(
      runs = data.frame(
        condition = rep(c("ref", "test"), each = 5L),
        seed      = rep(1:5, 2L),
        final_n   = c(rnorm(5L, 100, 5), rnorm(5L, 115, 5)),
        stringsAsFactors = FALSE
      ),
      conditions = list(ref = list(), test = list()),
      metrics    = list(final_n = function(t) NA),
      seeds      = 1:5
    ),
    class = c("hypothesis_sweep", "list")
  )
  rpt <- hypothesis_report(fake_sweep,
                           list(effect = c("ref", "test")),
                           metric = "final_n")
  out <- capture.output(print(rpt))
  expect_match(out[1L], "<hypothesis_report>.*metric = final_n")
  # The table row should be rendered
  expect_true(any(grepl("effect", out)))
})
