# Tests for config parameter structure and validation — no Julia required.
#
# These tests focus on the properties of default_specs() as a configuration
# object: its type, size, required fields, numeric constraints, and absence of
# unintentional NA values.

library(testthat)

# ── 1. default_specs() returns a list ────────────────────────────────────────
test_that("default_specs() returns a list", {
  expect_type(default_specs(), "list")
})

# ── 2. default_specs() has many parameters ───────────────────────────────────
test_that("default_specs() contains more than 50 parameters", {
  expect_gt(length(default_specs()), 50L)
})

# ── 3. Required core parameters are present ───────────────────────────────────
test_that("required core parameters are present in default_specs()", {
  required <- c(
    "n_agents_init", "max_ticks", "grid_rows", "grid_cols", "grass_rate"
  )
  missing <- setdiff(required, names(default_specs()))
  expect_equal(missing, character(0L),
               info = paste("Missing:", paste(missing, collapse = ", ")))
})

# ── 4. energy_init is positive ───────────────────────────────────────────────
test_that("energy_init is positive", {
  expect_gt(default_specs()$energy_init, 0)
})

# ── 5. n_agents_init is positive ─────────────────────────────────────────────
test_that("n_agents_init is positive", {
  expect_gt(default_specs()$n_agents_init, 0L)
})

# ── 6. max_ticks is positive ──────────────────────────────────────────────────
test_that("max_ticks is positive", {
  expect_gt(default_specs()$max_ticks, 0L)
})

# ── 7. grid dimensions are positive ──────────────────────────────────────────
test_that("grid_rows and grid_cols are both positive", {
  s <- default_specs()
  expect_gt(s$grid_rows, 0L)
  expect_gt(s$grid_cols, 0L)
})

# ── 8. grass_rate is in (0, 1) ────────────────────────────────────────────────
test_that("grass_rate is in (0, 1)", {
  gr <- default_specs()$grass_rate
  expect_gt(gr, 0)
  expect_lt(gr, 1)
})

# ── 9. move_cost is non-negative ─────────────────────────────────────────────
test_that("move_cost >= 0", {
  expect_gte(default_specs()$move_cost, 0)
})

# ── 10. idle_cost is non-negative ────────────────────────────────────────────
test_that("idle_cost >= 0", {
  expect_gte(default_specs()$idle_cost, 0)
})

# ── 11. min_repro_energy > 0 (positive reproduction barrier) ─────────────────
test_that("min_repro_energy is strictly positive", {
  expect_gt(default_specs()$min_repro_energy, 0)
})

# ── 12. No unintentional NA values in defaults ───────────────────────────────
test_that("no unintentional NA values in default_specs()", {
  # random_seed = NA_integer_ is intentional — excluded.
  # fixed_patch_x / fixed_patch_y = NA_integer_ by design: they MUST be
  # set by the user before enabling fixed_patch, so NA-by-default is a
  # signal of "unconfigured", not a bug.
  # predator_max_age = NA_integer_ by design: NA means "same as prey
  # max_age", which is the biologically natural default. Set to a real
  # integer (e.g. 100L in fast_specs) to give predators a distinct lifespan.
  s        <- default_specs()
  s_check  <- s[!names(s) %in% c("random_seed",
                                  "fixed_patch_x", "fixed_patch_y",
                                  "predator_max_age")]
  na_flags <- vapply(
    s_check,
    function(x) length(x) == 1L && is.na(x),
    logical(1L)
  )
  expect_false(any(na_flags),
               info = paste("Parameters with NA values:",
                            paste(names(s_check)[na_flags], collapse = ", ")))
})

# ── 13. Numeric params expected to be positive ────────────────────────────────
test_that("core numeric params expected to be positive are positive", {
  s <- default_specs()
  positive_params <- c(
    "energy_init", "energy_max", "move_cost", "eat_gain",
    "min_repro_energy", "repro_cost", "offspring_energy",
    "grass_rate", "grass_max", "brain_energy_base"
  )
  for (nm in positive_params) {
    expect_gt(s[[nm]], 0.0, label = paste("specs$", nm, "> 0"))
  }
})

# ── 14. Logical params that should default to FALSE ───────────────────────────
test_that("module logical flags that should be FALSE by default are FALSE", {
  s <- default_specs()
  should_be_false <- c(
    "mutation_rate_evolution", "learning_rate_evolution",
    "epigenetics", "body_size_evolution", "metabolic_rate_evolution",
    "aging_rate_evolution", "immune_evolution", "disease",
    "kin_selection", "cooperation_evolution", "dispersal_evolution",
    "habitat_preference_evolution", "group_defense", "parental_care",
    "cooperative_breeding", "mimicry", "niche_construction",
    "scavenging", "social_learning", "speciation",
    "phenotypic_plasticity",
    "clutch_size_evolution", "parental_investment_evolution",
    "stress_hypermutation", "log_genomes"
  )
  for (nm in should_be_false) {
    expect_false(s[[nm]], label = paste("specs$", nm, "== FALSE"))
  }
})

# ── 15. min_repro_age defaults to 0L and is integer ──────────────────────────
test_that("min_repro_age defaults to 0L and is integer", {
  val <- default_specs()$min_repro_age
  expect_equal(val, 0L)
  expect_true(is.integer(val))
})

# ── 16. stress_hypermutation defaults to FALSE ────────────────────────────────
test_that("stress_hypermutation defaults to FALSE", {
  expect_false(default_specs()$stress_hypermutation)
})

# ── 17. clutch_size_evolution defaults to FALSE ───────────────────────────────
test_that("clutch_size_evolution defaults to FALSE", {
  expect_false(default_specs()$clutch_size_evolution)
})

# ── 18. parental_investment_evolution defaults to FALSE ───────────────────────
test_that("parental_investment_evolution defaults to FALSE", {
  expect_false(default_specs()$parental_investment_evolution)
})

# ── 19. male_repro_cost defaults to 0.3 ──────────────────────────────────────
test_that("male_repro_cost defaults to 0.3", {
  expect_equal(default_specs()$male_repro_cost, 0.3)
})

# ── 20. senescence_shape defaults to 1.0 (classic Gompertz) ──────────────────
# PR #116 (`feat(0.7.x): wire senescence_shape`) changed the default from
# 2.0 → 1.0 with the docstring update "Default 1.0 = classic Gompertz",
# but this test was not updated alongside it and has been failing silently
# since 0.7.x. Found during the Phase A item-1 walk of default_specs().
test_that("senescence_shape defaults to 1.0 (classic Gompertz)", {
  expect_equal(default_specs()$senescence_shape, 1.0)
})
