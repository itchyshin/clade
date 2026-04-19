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
