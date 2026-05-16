# Drift-guard against stale default-value literals in test assertions.
#
# Background: 2026-05-16 tests.yaml workflow surfaced a stale
# assertion `expect_equal(default_specs()$senescence_shape, 2.0)` in
# test-aging-rate.R — the field default was lowered to 1.0 in PR #116,
# but the test kept its old 2.0 literal. The existing
# `test-test-field-assertions.R` drift-guard catches stale field
# NAMES (assertions that reference fields no longer in
# default_specs()), but NOT stale VALUES (assertions whose RHS
# literal no longer matches the current default).
#
# This test makes the latter class impossible. It parses every
# tests/testthat/test-*.R file, walks the AST for calls shaped like
# `expect_equal(default_specs()$<field>, <literal>)`, and asserts the
# literal matches the current `default_specs()[[<field>]]`.
#
# Counterpart to test-test-field-assertions.R (names) — together they
# form the R↔tests drift-guard pair.

library(testthat)

# Numeric tolerance used when both sides are numeric. Mirrors testthat
# defaults so the comparison agrees with the assertion itself.
.VALUE_TOLERANCE <- sqrt(.Machine$double.eps)

# Fields where a stale literal is deliberate (e.g. a regression test
# pinning a historical value). Each entry must have a documented
# reason. Keep this empty unless a real exception arises.
.STALE_VALUE_ALLOWLIST <- list(
  # "file:line" = "reason"
)

.find_repo_root <- function() {
  cur <- normalizePath(".", mustWork = FALSE)
  for (i in 1:6) {
    if (file.exists(file.path(cur, "DESCRIPTION")) &&
        dir.exists(file.path(cur, "R")) &&
        dir.exists(file.path(cur, "tests"))) {
      return(cur)
    }
    cur <- dirname(cur)
  }
  NULL
}

# Match calls of the shape `default_specs()$field`. Returns the field
# name as a character scalar, or NA_character_ if the call doesn't match.
.match_default_field <- function(expr) {
  if (!is.call(expr)) return(NA_character_)
  if (!identical(as.character(expr[[1L]]), "$")) return(NA_character_)
  if (length(expr) < 3L) return(NA_character_)
  inner <- expr[[2L]]
  if (!is.call(inner)) return(NA_character_)
  if (!identical(as.character(inner[[1L]]), "default_specs")) return(NA_character_)
  if (length(inner) != 1L) return(NA_character_)  # only no-arg form
  field <- expr[[3L]]
  if (!is.symbol(field) && !is.character(field)) return(NA_character_)
  as.character(field)
}

# Walk an expression. For each subcall, run `visitor(call)`.
.walk_calls <- function(expr, visitor) {
  if (is.call(expr)) {
    visitor(expr)
    for (i in seq_along(expr)) {
      .walk_calls(expr[[i]], visitor)
    }
  }
}

# Try to eval a literal expected-value expression. Permits atomic
# literals (1.0, "foo", TRUE, 5L), and `c(...)` / `list(...)` of
# atomic literals. Returns NULL if the expression is too complex
# to interpret as a literal (the test does not check those).
.try_eval_literal <- function(expr) {
  tryCatch({
    v <- eval(expr, envir = baseenv())
    if (is.atomic(v) && length(v) <= 100L) v else NULL
  }, error = function(e) NULL)
}

.scan_file <- function(path, current_defs, repo_root) {
  rel <- sub(paste0("^", repo_root, "/"), "", path)
  exprs <- tryCatch(parse(path, keep.source = TRUE),
                    error = function(e) NULL)
  if (is.null(exprs)) return(character(0))
  src_refs <- attr(exprs, "srcref")

  hits <- character(0)
  for (i in seq_along(exprs)) {
    .walk_calls(exprs[[i]], function(call) {
      fn <- as.character(call[[1L]])
      if (!fn[1L] %in% c("expect_equal", "expect_identical")) return()
      if (length(call) < 3L) return()
      lhs <- call[[2L]]
      rhs <- call[[3L]]
      field <- .match_default_field(lhs)
      if (is.na(field)) return()
      expected <- .try_eval_literal(rhs)
      if (is.null(expected)) return()
      if (!field %in% names(current_defs)) {
        # Stale-name drift, caught by test-test-field-assertions.R.
        return()
      }
      actual <- current_defs[[field]]
      ok <- isTRUE(all.equal(expected, actual,
                              tolerance = .VALUE_TOLERANCE,
                              check.attributes = FALSE))
      if (!ok) {
        line <- attr(src_refs[[i]], "srcfile")
        # Approximate line: top of the parent expression. Good enough
        # for grep-find; precise line not essential.
        ln <- if (!is.null(src_refs[[i]])) src_refs[[i]][1L] else NA_integer_
        key <- sprintf("%s:%s", rel, ln)
        if (key %in% names(.STALE_VALUE_ALLOWLIST)) return()
        hits <<- c(hits,
                   sprintf("%s — expect_equal(default_specs()$%s, %s) but current default is %s",
                           key, field,
                           paste(deparse(expected), collapse = " "),
                           paste(deparse(actual),   collapse = " ")))
      }
    })
  }
  hits
}

test_that("every `expect_equal(default_specs()$X, <literal>)` literal matches the current default", {
  repo_root <- .find_repo_root()
  skip_if(is.null(repo_root),
          "Could not locate package root from test working directory.")
  current_defs <- tryCatch(clade::default_specs(),
                           error = function(e) NULL)
  skip_if(is.null(current_defs),
          "clade not loaded; cannot read default_specs().")

  test_files <- list.files(file.path(repo_root, "tests/testthat"),
                           pattern = "^test-.*\\.R$", full.names = TRUE)
  all_hits <- unlist(lapply(test_files, .scan_file,
                            current_defs = current_defs,
                            repo_root    = repo_root),
                     use.names = FALSE)

  expect_equal(
    all_hits, character(0L),
    info = paste0(
      "Stale default-value literal(s) detected in tests/testthat/. ",
      "Either (a) fix the literal to match `default_specs()[[X]]`, ",
      "(b) intentionally pin a historical value via the field ",
      "`.STALE_VALUE_ALLOWLIST` in tests/testthat/",
      "test-test-default-value-assertions.R with a documented reason.\n",
      "Hits:\n  ",
      paste(all_hits, collapse = "\n  ")
    )
  )
})
