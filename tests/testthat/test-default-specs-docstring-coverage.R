# Structural drift-guard: every `default X` claim in `R/config.R`'s
# `default_specs()` `@details` `\describe{}` block must match the
# actual value in `default_specs()`.
#
# Background: PR #143 (cousin-hunt of items 6 + 8) found 21
# documented-vs-code mismatches in `default_specs()`'s docstring
# (e.g., `bnn_sigma_init` documented as default 0.1 but actual is
# 0.5; `helper_kin_threshold` claimed = half-siblings at 0.125
# but actual is 0.25 = full-siblings). All 21 were fixed.
#
# This guard makes the class non-recurrable: any future docstring
# claim that disagrees with the spec value fails the test.
#
# Same shape as `test-spec-groups-coverage.R` and
# `test-test-field-assertions.R` (also PR #129 drift guards).

library(testthat)

# Self-locating: when run from the source tree, R/config.R lives there.
# When run from an installed package, it isn't shipped — skip then.
.find_pkg_root <- function() {
  here <- normalizePath(".", mustWork = FALSE)
  candidates <- c(
    here,
    file.path(here, ".."),
    file.path(here, "..", ".."),
    file.path(here, "..", "..", "..")
  )
  for (p in candidates) {
    if (file.exists(file.path(p, "R", "config.R")) &&
        file.exists(file.path(p, "DESCRIPTION"))) {
      return(normalizePath(p))
    }
  }
  NULL
}

# Parse claimed default from one \item{...} text chunk. Returns NA when
# no claim found or claim is ambiguous (e.g., NA / NULL / character).
# Uses the same regex as the cousin-hunt script that surfaced the 21
# mismatches in PR #143.
.parse_default_claim <- function(chunk) {
  default_re <- "(?i)default\\s*[:=]?\\s*[`(]?\\s*(-?\\d+(?:\\.\\d+)?(?:[eE][-+]?\\d+)?L?|TRUE|FALSE|NA(?:_real_|_integer_|_character_)?|NULL|\"[^\"]*\")"
  m <- regmatches(chunk, regexec(default_re, chunk, perl = TRUE))[[1L]]
  if (length(m) > 1L) m[2L] else NA_character_
}

# Convert a captured claim string back into an R value.
.parse_claim_value <- function(s) {
  if (is.na(s)) return(NULL)
  s <- gsub("^\"|\"$", "", s)
  if (s == "TRUE") return(TRUE)
  if (s == "FALSE") return(FALSE)
  if (s == "NULL") return(NULL)
  if (grepl("^NA", s)) return(NA)
  s2 <- sub("L$", "", s)
  num <- suppressWarnings(as.numeric(s2))
  if (!is.na(num)) {
    if (endsWith(s, "L")) return(as.integer(num))
    return(num)
  }
  s
}

# Documented exceptions: known false positives from the regex pattern.
# Each entry is one field name where the docstring legitimately contains
# the word "default" near a number that is NOT a default-value claim.
# Adding a name here is a deliberate annotation; bare-minimum justification
# required in the comment.
.DEFAULT_SPECS_ALLOWLIST <- c(
  # "NA_integer_ uses a random seed (default)." — the "(default)" annotates
  # that NA_integer_ IS the default; regex picks up a nearby number by
  # accident. Discovered during the cousin-hunt that produced PR #143.
  "random_seed"
)

test_that("every 'default X' claim in R/config.R::default_specs() matches the actual value", {
  pkg <- .find_pkg_root()
  skip_if(is.null(pkg), "package root not found (running from installed pkg?)")

  config_path <- file.path(pkg, "R", "config.R")
  skip_if_not(file.exists(config_path), "R/config.R not found")

  lines <- readLines(config_path)
  item_starts <- grep("#'\\s+\\\\item\\{`?([a-zA-Z_][a-zA-Z0-9_]*)`?\\}", lines)
  skip_if(length(item_starts) == 0L,
          "no \\item entries parsed from R/config.R (regex out of date?)")

  field_name_of <- function(line) {
    m <- regmatches(line,
                    regexec("\\\\item\\{`?([a-zA-Z_][a-zA-Z0-9_]*)`?\\}", line))[[1L]]
    if (length(m) > 1L) m[2L] else NA_character_
  }

  # Build per-field text chunks (each spans until the next \item or end).
  chunks <- list()
  for (i in seq_along(item_starts)) {
    s <- item_starts[i]
    e <- if (i < length(item_starts)) item_starts[i + 1L] - 1L
         else min(s + 30L, length(lines))
    field <- field_name_of(lines[s])
    if (is.na(field)) next
    chunks[[field]] <- paste(lines[s:e], collapse = " ")
  }

  specs <- default_specs()
  mismatches <- character(0L)

  for (field in names(chunks)) {
    if (field %in% .DEFAULT_SPECS_ALLOWLIST) next
    if (!field %in% names(specs)) next       # ghost names handled by test-spec-groups-coverage
    raw <- .parse_default_claim(chunks[[field]])
    if (is.na(raw)) next                     # no parsable claim — skip silently
    claimed <- .parse_claim_value(raw)
    actual  <- specs[[field]]

    # Compare loosely.
    if (is.null(claimed) && is.null(actual)) next
    if (length(claimed) == 1L && is.na(claimed) &&
        length(actual) == 1L && is.na(actual)) next
    if (length(claimed) == 1L && length(actual) == 1L) {
      if (is.numeric(claimed) && is.numeric(actual)) {
        if (!isTRUE(all.equal(as.numeric(claimed), as.numeric(actual),
                              tolerance = 1e-10))) {
          mismatches <- c(mismatches,
                          sprintf("  %s: claimed %s, actual %s",
                                  field, raw, deparse(actual)))
        }
      } else if (!identical(claimed, actual)) {
        mismatches <- c(mismatches,
                        sprintf("  %s: claimed %s, actual %s",
                                field, raw, deparse(actual)))
      }
    }
  }

  if (length(mismatches) > 0L) {
    fail(paste0(
      "Found `default X` claims in R/config.R's default_specs() ",
      "@details that disagree with the actual default value.\n",
      "Either (a) update the docstring to match the code, (b) update the ",
      "code to match the docstring, or (c) if the regex caught a false ",
      "positive (e.g. the word 'default' near an unrelated number), add ",
      "the field to .DEFAULT_SPECS_ALLOWLIST with justification.\n\n",
      paste(mismatches, collapse = "\n")
    ))
  } else {
    succeed()
  }
})

# Tests-of-the-test: verify the parsing helpers on synthetic fixtures.

test_that(".parse_default_claim catches the common claim forms", {
  expect_equal(.parse_default_claim("foo (default 30)"), "30")
  expect_equal(.parse_default_claim("Default 0.5."), "0.5")
  expect_equal(.parse_default_claim("default 1L for integer fields"), "1L")
  expect_equal(.parse_default_claim("default TRUE here"), "TRUE")
  expect_equal(.parse_default_claim("default NA_integer_"), "NA_integer_")
  expect_true(is.na(.parse_default_claim("no claim here")))
})

test_that(".parse_claim_value round-trips numeric / integer / logical / NA", {
  expect_equal(.parse_claim_value("30"), 30)
  expect_equal(.parse_claim_value("0.5"), 0.5)
  expect_identical(.parse_claim_value("30L"), 30L)
  expect_true(.parse_claim_value("TRUE"))
  expect_false(.parse_claim_value("FALSE"))
  expect_true(is.na(.parse_claim_value("NA_integer_")))
  expect_null(.parse_claim_value("NULL"))
})
