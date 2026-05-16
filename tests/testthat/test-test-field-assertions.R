# Structural drift-guard: every spec-field name asserted as present in a
# test file must exist in `default_specs()`.
#
# Background: Phase A item 2 (run_alife walk, commit 9651f54) found that
# `tests/testthat/test-integration.R` had been failing to parse since the
# `world_evolution` deletion (commit 2c7cf66) — and that *several* test
# files had `expect_true("<field>" %in% names(default_specs()))` blocks
# asserting fields that had been deleted by the spec-wiring audit
# (PR #114, NEWS 0.7.1). Examples then-found and now-cleaned in commit
# 7b625f8: `repro_senescence`, `life_history_evolution`,
# `parental_investment_init_mean`.
#
# This test scans every `tests/testthat/test-*.R` file for the high-signal
# pattern `expect_true("<word>" %in% names(...))` and asserts the captured
# `<word>` is in `default_specs()`. The `expect_true(...)` qualifier means
# we deliberately do NOT flag `expect_false(...)` absence assertions
# (e.g. `test-cell-occupancy.R:57` asserts `max_agents_per_cell` is *not*
# in defaults; that is correct behaviour, not stale).
#
# Same shape as the four existing structural drift guards
# (`test-spec-wiring.R`, `test-version-strings.R`,
# `test-pkgdown-consistency.R`, `test-readme-flag-names.R`, plus
# `test-spec-groups-coverage.R` from earlier in this PR).

library(testthat)

# Self-locating: when run from the source tree the test dir is `tests/testthat`;
# when run from an installed package, fall back to system.file().
.find_testthat_dir <- function() {
  here <- normalizePath(".", mustWork = FALSE)
  candidates <- c(
    here,
    file.path(here, "tests", "testthat"),
    file.path(here, "..", "tests", "testthat"),
    file.path(here, "..", "..", "tests", "testthat"),
    system.file("tests", "testthat", package = "clade")
  )
  for (p in candidates) {
    if (file.exists(file.path(p, "test-spec-groups-coverage.R"))) {
      return(normalizePath(p))
    }
  }
  NULL
}

test_that("no test file asserts presence of a field absent from default_specs()", {
  testthat_dir <- .find_testthat_dir()
  skip_if(is.null(testthat_dir),
          "could not locate tests/testthat directory")

  test_files <- list.files(testthat_dir, pattern = "^test-.*\\.R$",
                           full.names = TRUE)
  # Exclude self: this file's tests-of-the-test below contain literal
  # synthetic-fixture strings like `expect_true("ghost_field" %in%
  # names(default_specs()))` that would (correctly) match the drift-guard
  # pattern but are not real assertions.
  test_files <- test_files[basename(test_files) != "test-test-field-assertions.R"]
  skip_if(length(test_files) == 0L, "no test files found")

  s_fields <- names(default_specs())

  # Two patterns, both deliberately conservative to avoid false positives
  # on `%in% names(env$progress)` etc.:
  #
  # (1) Direct: `expect_true("<x>" %in% names(default_specs()))`.
  # (2) Indirect: per-test_that-block, if `<- default_specs()` assigns to
  #     variable `<v>`, then `expect_true("<x>" %in% names(<v>))` asserts
  #     the spec-field presence.
  #
  # Both qualifiers (`expect_true(...)`) intentionally exclude
  # `expect_false(...)` absence assertions (e.g. test-cell-occupancy.R's
  # `max_agents_per_cell` absence check — correct, not stale).
  pat_direct   <- 'expect_true\\("([a-zA-Z_][a-zA-Z0-9_]*)"\\s+%in%\\s+names\\(default_specs\\(\\)\\)'
  pat_assign   <- '([a-zA-Z_][a-zA-Z0-9_]*)\\s*<-\\s*default_specs\\(\\)'
  pat_indirect <- 'expect_true\\("([a-zA-Z_][a-zA-Z0-9_]*)"\\s+%in%\\s+names\\(([a-zA-Z_][a-zA-Z0-9_]*)\\)\\)'

  stale <- list()

  for (f in test_files) {
    txt <- paste(readLines(f, warn = FALSE), collapse = "\n")
    # Per-test_that-block isolation: split by `test_that(` so each chunk
    # is one test block (plus the file preamble before the first split).
    blocks <- strsplit(txt, "test_that\\(", fixed = FALSE)[[1L]]
    file_ghosts <- character(0L)
    for (b in blocks) {
      # (1) Direct pattern
      m1 <- regmatches(b, gregexec(pat_direct, b))[[1L]]
      if (length(m1) > 0L) {
        cap <- m1[2L, ]
        file_ghosts <- c(file_ghosts, setdiff(cap, s_fields))
      }
      # (2) Indirect pattern: only flag if the same block assigned from
      # default_specs() to the variable referenced inside names(...).
      assigned <- character(0L)
      mA <- regmatches(b, gregexec(pat_assign, b))[[1L]]
      if (length(mA) > 0L) assigned <- mA[2L, ]
      if (length(assigned) > 0L) {
        mI <- regmatches(b, gregexec(pat_indirect, b))[[1L]]
        if (length(mI) > 0L) {
          captured_fields <- mI[2L, ]
          referenced_vars <- mI[3L, ]
          # Only count assertions whose variable was assigned from default_specs()
          relevant <- captured_fields[referenced_vars %in% assigned]
          file_ghosts <- c(file_ghosts, setdiff(relevant, s_fields))
        }
      }
    }
    file_ghosts <- unique(file_ghosts)
    if (length(file_ghosts) > 0L) {
      stale[[basename(f)]] <- file_ghosts
    }
  }

  if (length(stale) > 0L) {
    detail <- paste(
      vapply(names(stale), function(nm) {
        sprintf("  %s: %s", nm, paste(stale[[nm]], collapse = ", "))
      }, character(1L)),
      collapse = "\n"
    )
    fail(paste0(
      "Found `expect_true(\"<field>\" %in% names(...))` assertions on ",
      "fields that do not exist in `default_specs()`.\n",
      "Either (a) restore the field to `default_specs()`, (b) delete the ",
      "assertion, or (c) change `expect_true` to `expect_false` if the ",
      "assertion documents the field's deliberate absence.\n",
      detail
    ))
  } else {
    succeed()
  }
})

# Tests-of-the-test: synthetic-fixture sanity checks for the drift-guard
# regexes themselves. These verify that the patterns above would actually
# catch a stale assertion if one slipped in, and would NOT false-positive on
# `expect_false` or on `%in% names(env$progress)`.

test_that("drift-guard direct pattern catches a synthetic stale expect_true", {
  pat <- 'expect_true\\("([a-zA-Z_][a-zA-Z0-9_]*)"\\s+%in%\\s+names\\(default_specs\\(\\)\\)'
  txt <- 'expect_true("ghost_field" %in% names(default_specs()))'
  m   <- regmatches(txt, gregexec(pat, txt))[[1L]]
  expect_equal(ncol(m), 1L)
  expect_equal(m[2L, 1L], "ghost_field")
})

test_that("drift-guard direct pattern ignores expect_false absence assertions", {
  pat <- 'expect_true\\("([a-zA-Z_][a-zA-Z0-9_]*)"\\s+%in%\\s+names\\(default_specs\\(\\)\\)'
  txt <- 'expect_false("removed_field" %in% names(default_specs()))'
  m   <- regmatches(txt, gregexec(pat, txt))[[1L]]
  # No matches: gregexec returns either NULL or a 0-column matrix
  expect_equal(length(m), 0L)
})

test_that("drift-guard indirect pattern only fires when assigned from default_specs()", {
  pat_assign   <- '([a-zA-Z_][a-zA-Z0-9_]*)\\s*<-\\s*default_specs\\(\\)'
  pat_indirect <- 'expect_true\\("([a-zA-Z_][a-zA-Z0-9_]*)"\\s+%in%\\s+names\\(([a-zA-Z_][a-zA-Z0-9_]*)\\)\\)'
  # Block A: indirect assertion on `s` after `s <- default_specs()` — fires.
  txtA  <- 's <- default_specs()\nexpect_true("foo" %in% names(s))'
  mA1   <- regmatches(txtA, gregexec(pat_assign, txtA))[[1L]]
  mA2   <- regmatches(txtA, gregexec(pat_indirect, txtA))[[1L]]
  expect_equal(mA1[2L, 1L], "s")
  expect_equal(mA2[2L, 1L], "foo")
  expect_equal(mA2[3L, 1L], "s")
  # Block B: indirect assertion on `env$progress` — must NOT match the
  # simple-variable indirect pattern (env$progress has a $ and is rejected).
  txtB  <- 'expect_true("n_juveniles" %in% names(env$progress))'
  mB    <- regmatches(txtB, gregexec(pat_indirect, txtB))[[1L]]
  # No matches: gregexec returns either NULL or a 0-column matrix
  expect_equal(length(mB), 0L)
})
