# Tests for one-agent-per-cell movement enforcement (added in 0.7.0).
#
# Background: prior to 0.7.0, clade silently allowed multiple agents (and
# multiple predators) to occupy the same cell. The MATLAB ancestor
# (Bulitko, takeAction.m:79) and the alifeR R port (tick_agents.cpp:257)
# both enforce one-per-cell at movement time. Phase 2 of the consolidation
# work restored this rule. See dev/docs/consolidation-audit.md and
# dev/audit/agent-map-call-sites.md for the ancestor diff and call-site
# catalogue.
#
# These tests verify the invariant directly: after any tick, no two live
# agents occupy the same cell, and likewise for predators.

library(testthat)

# Dense scenario: agents per cell ≈ 0.5, so contention is frequent and the
# one-per-cell rule actually triggers many blocks per tick.
.dense_specs <- function(seed) {
  s <- default_specs()
  s$grid_rows         <- 20L
  s$grid_cols         <- 20L
  s$n_agents_init     <- 200L     # 200 agents on 400 cells = 0.5 density
  s$max_agents        <- 1000L
  s$max_ticks         <- 50L
  s$random_seed       <- as.integer(seed)
  s$random_tick_order <- TRUE
  s
}

# Helper: assert no two live agents on the same (x, y). Always makes at least
# one expectation so testthat doesn't flag the test as empty.
expect_one_per_cell <- function(env) {
  agents <- env$agents
  expect_true(!is.null(agents), info = "env$agents missing")
  if (is.null(agents) || length(agents) == 0L) {
    expect_true(TRUE, info = "no agents to check (vacuously satisfied)")
    return(invisible(NULL))
  }
  alive_idx <- which(as.logical(agents$alive))
  if (length(alive_idx) < 2L) {
    expect_true(TRUE, info = sprintf("only %d live agents — nothing to collide", length(alive_idx)))
    return(invisible(NULL))
  }
  xs <- as.integer(agents$x[alive_idx])
  ys <- as.integer(agents$y[alive_idx])
  cells <- paste(xs, ys, sep = ",")
  dups  <- cells[duplicated(cells)]
  expect_equal(length(dups), 0L,
               info = sprintf("Found %d cells with co-occupying agents: %s",
                              length(dups), paste(unique(dups), collapse = "; ")))
}

test_that("default_specs() does NOT include max_agents_per_cell (Policy A hook removed)", {
  # Phase 2 went with restoring MATLAB Policy B (one-per-cell at movement) instead
  # of Policy A (allow + lookup). The forward-compat hook from the previous plan
  # is no longer needed: one-per-cell is the new default at movement time.
  expect_false("max_agents_per_cell" %in% names(default_specs()))
})

test_that("after tick_agents!, no two agents share a cell (random tick order)", {
  skip_no_julia()
  env <- run_alife(.dense_specs(seed = 1L), verbose = FALSE)
  expect_one_per_cell(env)
})

test_that("one-per-cell holds across multiple seeds", {
  skip_no_julia()
  for (seed in c(2L, 3L, 4L, 5L)) {
    env <- run_alife(.dense_specs(seed = seed), verbose = FALSE)
    expect_one_per_cell(env)
  }
})

test_that("one-per-cell still holds with random_tick_order = FALSE (legacy)", {
  skip_no_julia()
  s <- .dense_specs(seed = 1L)
  s$random_tick_order <- FALSE
  env <- run_alife(s, verbose = FALSE)
  expect_one_per_cell(env)
})

test_that("predator-tick code path runs cleanly with one-per-cell enforcement enabled", {
  # Predators are not included in the R-side env result (see Clade.jl
  # _env_to_result) so we can't directly assert their per-cell uniqueness from
  # R. The one-per-cell rule for predators is enforced inside _move_predator!
  # in tick_predators.jl (see Phase 2 changes); this test verifies the code
  # path runs to completion without error when predators are enabled, which is
  # a necessary condition for the rule being honoured.
  skip_no_julia()
  s <- .dense_specs(seed = 1L)
  s$n_predators_init     <- 5L
  s$predator_max_agents  <- 30L
  s$max_ticks            <- 20L
  expect_no_error(env <- run_alife(s, verbose = FALSE))
  expect_one_per_cell(env)   # prey still obey the rule even with predators present
})
