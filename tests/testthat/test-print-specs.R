# Dedicated tests for print_specs().
#
# Before Phase A item 7, `print_specs()` had zero dedicated test coverage —
# the function was exercised only as a roxygen example and as a vignette
# code chunk (`basics.Rmd`, `parameter-reference.Rmd`, `getting-started.Rmd`).
# Post-#124 it consumes `.SPEC_GROUPS` for grouping (the same source of
# truth as `.param_table()` / `parameter-reference.Rmd`). This file covers:
#
# - the no-args path prints all defaults and returns invisibly,
# - the `diff_only = TRUE` path only prints changed fields and marks them
#   with the `*` flag,
# - the `diff_only = TRUE` empty case prints the "(no parameters differ
#   from defaults)" message,
# - `.SPEC_GROUPS` consumption: fields outside every group go into "Other",
#   and group headers only print when at least one field is non-empty
#   after intersection,
# - the function returns its `specs` argument invisibly so that it composes
#   into pipelines.

library(testthat)

# ── No-args path: print defaults ─────────────────────────────────────────────

test_that("print_specs() with no args prints the defaults header and returns invisibly", {
  out <- capture.output(rv <- print_specs())
  # Header includes the parameter count and no "diff only" tag.
  expect_match(out[1L], "^-- clade specs \\([0-9]+ parameters\\) --$")
  # Returns the specs list invisibly for piping.
  expect_equal(rv, default_specs())
})

test_that("print_specs() prints at least the always-present group headers", {
  out <- capture.output(print_specs())
  # These groups are guaranteed by `.SPEC_GROUPS` and always have fields.
  expect_true(any(grepl("Grid & population",   out, fixed = TRUE)))
  expect_true(any(grepl("Energy & metabolism", out, fixed = TRUE)))
  expect_true(any(grepl("Grass dynamics",      out, fixed = TRUE)))
  expect_true(any(grepl("Brain architecture",  out, fixed = TRUE)))
})

# ── diff_only path ───────────────────────────────────────────────────────────

test_that("print_specs(specs, diff_only = TRUE) prints only changed fields with *", {
  s <- default_specs()
  s$n_agents_init <- 200L      # change one
  s$kin_selection <- TRUE      # change another
  out <- capture.output(print_specs(s, diff_only = TRUE))
  # Header carries the diff-only tag.
  expect_match(out[1L], "\\[diff only\\]")
  # The two changed fields appear, marked with " *".
  expect_true(any(grepl("n_agents_init.*\\*", out)))
  expect_true(any(grepl("kin_selection.*\\*", out)))
  # An unchanged field (e.g. grass_rate) does NOT appear in diff-only output.
  expect_false(any(grepl("grass_rate",        out)))
})

test_that("print_specs(diff_only = TRUE) on unmodified specs prints the no-diff message", {
  out <- capture.output(print_specs(default_specs(), diff_only = TRUE))
  expect_true(any(grepl("no parameters differ from defaults", out, fixed = TRUE)))
})

# ── .SPEC_GROUPS consumption ──────────────────────────────────────────────────

test_that("print_specs() catches fields outside every group into an Other section", {
  s <- default_specs()
  # Underscore-prefixed names need backticks under `$`, so use [[ ]] —
  # avoiding the R-parser bug that broke test-integration.R until item 2
  # of the Phase A walk.
  s[["__synthetic_ungrouped_field_xyz__"]] <- 42L
  out <- capture.output(print_specs(s))
  # The Other group should appear when there are unmatched fields.
  expect_true(any(grepl("^  Other", out)))
  # And the synthetic field name should appear under it.
  expect_true(any(grepl("__synthetic_ungrouped_field_xyz__", out)))
})

test_that("print_specs() does not print group headers for groups with no matching fields", {
  # When passed an empty list (no fields), no group headers should appear at all
  # — the header line still prints, but no group body.
  out <- capture.output(print_specs(list()))
  group_lines <- grep("^  [A-Z]", out, value = TRUE)
  # No group prints when there are no fields to put under it.
  expect_equal(length(group_lines), 0L)
})

# ── Invisible return ─────────────────────────────────────────────────────────

test_that("print_specs() returns its specs argument invisibly", {
  # The return value should be exactly the input when specs is passed in.
  s <- default_specs()
  s$max_ticks <- 999L
  invisible_capture <- capture.output(rv <- print_specs(s))
  expect_equal(rv, s)
  # And no warnings or messages from a quiet print.
  expect_silent({
    capture.output(print_specs(default_specs()))
  })
})
