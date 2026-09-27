# Unknown spec names are warned about, not silently ignored (#185).

test_that(".validate_specs() warns on a name clade does not read", {
  s <- default_specs()
  s$repro_threshold <- 150
  expect_warning(clade:::.validate_specs(s), "repro_threshold")
  expect_warning(clade:::.validate_specs(s), "min_repro_energy")
})

test_that(".validate_specs() names every unknown spec in one warning", {
  s <- default_specs()
  s$foo_a <- 1
  s$foo_b <- 2
  expect_warning(clade:::.validate_specs(s), "foo_a.*foo_b")
})

test_that(".validate_specs() is silent for default_specs() and presets", {
  presets <- c("default_specs", "quick_specs", "full_specs", "fast_specs",
               "realistic_specs", "ultra_realistic_specs", "slow_specs",
               "wolf_personality_specs", "trivers_reciprocity_specs")
  for (p in presets) {
    s <- get(p, envir = asNamespace("clade"))()
    unknown <- setdiff(names(s), names(default_specs()))
    expect_identical(unknown, character(0), info = p)
  }
})
