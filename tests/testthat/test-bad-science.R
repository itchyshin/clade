test_that("run_bad_science returns correct structure", {
  result <- run_bad_science(n_labs = 50L, n_ticks = 10L, seed = 1L)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 10L)
  expected_cols <- c("t", "mean_power", "mean_effort", "mean_fpr",
                     "total_publications", "failed_replications")
  expect_true(all(expected_cols %in% names(result)))
})

test_that("run_bad_science t column is sequential", {
  result <- run_bad_science(n_labs = 20L, n_ticks = 50L, seed = 2L)
  expect_equal(result$t, seq_len(50L))
})

test_that("run_bad_science mean_fpr is in (0, 1)", {
  result <- run_bad_science(n_labs = 100L, n_ticks = 20L, seed = 3L)
  expect_true(all(result$mean_fpr > 0))
  expect_true(all(result$mean_fpr < 1))
})

test_that("run_bad_science mean_effort decreases over time (evolutionary deterioration)", {
  # Run 10 replicates; mean effort should decline significantly
  efforts_start <- numeric(10L)
  efforts_end   <- numeric(10L)
  for (i in seq_len(10L)) {
    r <- run_bad_science(n_labs = 100L, n_ticks = 200L, seed = i * 7L)
    efforts_start[i] <- mean(r$mean_effort[1:10])
    efforts_end[i]   <- mean(r$mean_effort[191:200])
  }
  # Effort should decrease on average
  expect_true(mean(efforts_end) < mean(efforts_start))
})

test_that("run_bad_science is deterministic with seed", {
  r1 <- run_bad_science(n_labs = 50L, n_ticks = 30L, seed = 99L)
  r2 <- run_bad_science(n_labs = 50L, n_ticks = 30L, seed = 99L)
  expect_equal(r1, r2)
})

test_that("run_bad_science total_publications is positive each tick", {
  result <- run_bad_science(n_labs = 50L, n_ticks = 10L, seed = 5L)
  expect_true(all(result$total_publications > 0L))
})

test_that("run_bad_science failed_replications is 0 when replication_rate = 0", {
  result <- run_bad_science(n_labs = 50L, n_ticks = 10L,
                             replication_rate = 0.0, seed = 6L)
  expect_true(all(result$failed_replications == 0L))
})

test_that("run_bad_science replication_rate > 0 produces some failed replications", {
  result <- run_bad_science(n_labs = 200L, n_ticks = 50L,
                             replication_rate = 0.5, seed = 7L)
  expect_true(sum(result$failed_replications) > 0L)
})

test_that("run_bad_science n_ticks is respected", {
  for (n in c(1L, 10L, 100L)) {
    r <- run_bad_science(n_labs = 20L, n_ticks = n, seed = 8L)
    expect_equal(nrow(r), n)
  }
})

test_that("run_bad_science n_labs >= 2 is required", {
  expect_error(run_bad_science(n_labs = 1L))
})

test_that("strong replication + penalty lowers final FPR vs no replication", {
  # Across 5 seeds, mean FPR at tick 500 under rr=0.5 + penalty=5 must be
  # lower than mean FPR under rr=0. This is the S&M 2016 qualitative claim
  # and the reason replication_penalty exists.
  seeds <- 1L:5L
  fpr_no_rep <- sapply(seeds, function(s) {
    run_bad_science(n_ticks = 500L, replication_rate = 0,
                    seed = s)$mean_fpr[500]
  })
  fpr_strong <- sapply(seeds, function(s) {
    run_bad_science(n_ticks = 500L, replication_rate = 0.5,
                    replication_penalty = 5, seed = s)$mean_fpr[500]
  })
  expect_lt(mean(fpr_strong), mean(fpr_no_rep))
})

test_that("replication_penalty = 0 silences the replication mechanism", {
  # With zero penalty, replication_rate = 0 and 0.5 should produce
  # statistically indistinguishable FPR trajectories.
  seeds <- 1L:5L
  fpr_no_rep <- sapply(seeds, function(s) {
    run_bad_science(n_ticks = 500L, replication_rate = 0,
                    seed = s)$mean_fpr[500]
  })
  fpr_rep_nopen <- sapply(seeds, function(s) {
    run_bad_science(n_ticks = 500L, replication_rate = 0.5,
                    replication_penalty = 0, seed = s)$mean_fpr[500]
  })
  expect_lt(abs(mean(fpr_rep_nopen) - mean(fpr_no_rep)),
            sd(fpr_no_rep) + sd(fpr_rep_nopen))
})

test_that("alpha depends on effort only, not on research_power", {
  # Freeze traits via mutation_sd = 0; tick 1 mean_fpr should equal
  # alpha_base * (1 - mean_effort) regardless of research_power.
  df <- run_bad_science(n_ticks = 100L,
                        research_power_init_mean  = 0.9,
                        research_effort_init_mean = 0.5,
                        mutation_sd               = 0,
                        replication_rate          = 0,
                        seed                      = 1L)
  expect_equal(df$mean_fpr[1], 0.25, tolerance = 0.02)
})

test_that("run_bad_science mean_power stays in (0, 1)", {
  result <- run_bad_science(n_labs = 50L, n_ticks = 100L, seed = 10L)
  expect_true(all(result$mean_power > 0 & result$mean_power < 1))
})
