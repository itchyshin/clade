test_that("get_run_data preserves action entropy and missing observations", {
  progress <- list(t = 1:3, behavioral_diversity = c(log(5), 0, NaN),
                   n_behavioral_agents = c(5L, 1L, 0L),
                   predator_behavioral_diversity = c(NaN, log(2), 0),
                   n_behavioral_predators = c(0L, 2L, 1L))
  ticks <- get_run_data(list(progress = progress, deaths = list()))$ticks
  expect_equal(ticks$behavioral_diversity[1:2], c(log(5), 0))
  expect_true(is.nan(ticks$behavioral_diversity[3]))
  expect_identical(ticks$n_behavioral_agents, c(5L, 1L, 0L))
  expect_equal(ticks$predator_behavioral_diversity[2:3], c(log(2), 0))
})

test_that("action entropy round-trips from Julia for five seeds", {
  skip_no_julia()
  for (seed in 101:105) {
    specs <- .minimal_specs(random_seed = seed, max_ticks = 12L,
                            n_predators_init = 2L)
    ticks <- get_run_data(run_alife(specs, verbose = FALSE))$ticks
    expect_true(all(c("behavioral_diversity", "n_behavioral_agents",
                      "predator_behavioral_diversity", "n_behavioral_predators") %in%
                    names(ticks)))
    for (prefix in c("", "predator_")) {
      entropy <- ticks[[paste0(prefix, "behavioral_diversity")]]
      count <- ticks[[if (prefix == "") "n_behavioral_agents" else "n_behavioral_predators"]]
      expect_true(all(is.na(entropy[count == 0])))
      expect_true(all(is.finite(entropy[count > 0])))
      expect_true(all(entropy[count > 0] >= -1e-12 &
                      entropy[count > 0] <= log(5) + 1e-12))
    }
  }
})

test_that("undefined predator entropy remains NaN across the Julia boundary", {
  skip_no_julia()
  ticks <- get_run_data(run_alife(.minimal_specs(n_predators_init = 0L),
                                 verbose = FALSE))$ticks
  expect_true(any(ticks$n_behavioral_predators == 0L))
  expect_true(all(is.nan(ticks$predator_behavioral_diversity)))
})
