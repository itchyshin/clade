# Structural guard for the R↔Julia spec wiring contract.
#
# Background: 0.6.4 incident (mate_choice_mode) — a spec field was defined
# in R's default_specs(), R-side tested, vignette-cited for two releases,
# but the Julia kernel never branched on it. The R-side test suite caught
# the *shape* but not the *semantics*.
#
# This test makes that class of bug impossible by checking, for every
# field in default_specs(), that the field name appears as a string
# literal somewhere in inst/julia/src/**/*.jl. The check passes if every
# spec field has at least one Julia mention. New spec fields added in R
# without a Julia consumer will fail this test immediately.
#
# Allowlist: a small number of fields are deliberately R-only or are
# documented placeholders for reserved/future features. Adding to this
# allowlist requires explicit justification in the comment below.

library(testthat)

# Documented exceptions to the "every spec field must appear in Julia" rule.
# Adding a name here is a deliberate annotation that the field is either
# R-only or a placeholder for a feature not yet implemented in Julia.
.SPEC_WIRING_ALLOWLIST <- c(
  # Reserved brain-architecture placeholders. The kernel errors with
  # an explanatory message if either brain_type is requested; the spec
  # fields exist so users can see the parameter shape that future
  # implementations will use. See R/clade-package.R and README.md.
  "transformer_history",
  "transformer_heads",
  "synthesis_max_rules"
)

test_that("every default_specs() field has a Julia consumer (R↔Julia wiring guard)", {
  julia_root <- system.file("julia", "src", package = "clade")
  if (!nzchar(julia_root) || !dir.exists(julia_root)) {
    # When testing via devtools::load_all(), the package isn't installed,
    # so system.file() returns "". Fall back to the source-tree path.
    julia_root <- file.path("..", "..", "inst", "julia", "src")
  }
  skip_if_not(dir.exists(julia_root),
              message = "Julia source tree not found; cannot run wiring guard")

  julia_files <- list.files(julia_root, pattern = "\\.jl$",
                            recursive = TRUE, full.names = TRUE)
  # Read all Julia source into a single character vector for cheap grep.
  julia_lines <- unlist(lapply(julia_files, readLines, warn = FALSE),
                        use.names = FALSE)

  s <- default_specs()
  field_names <- names(s)

  is_used <- vapply(field_names, function(nm) {
    any(grepl(sprintf('"%s"', nm), julia_lines, fixed = TRUE))
  }, logical(1L))

  unwired <- setdiff(field_names[!is_used], .SPEC_WIRING_ALLOWLIST)

  expect_equal(
    unwired, character(0L),
    info = paste(
      "Found spec field(s) in default_specs() with no string-literal",
      "occurrence in inst/julia/src/.\n",
      "Either (a) wire them in Julia, (b) delete them from R, or",
      "(c) add to .SPEC_WIRING_ALLOWLIST with justification.\n",
      "Unwired:", paste(unwired, collapse = ", ")
    )
  )
})

test_that("allowlist entries are still in default_specs() (no stale entries)", {
  s <- default_specs()
  stale <- setdiff(.SPEC_WIRING_ALLOWLIST, names(s))
  expect_equal(
    stale, character(0L),
    info = paste(
      "Found .SPEC_WIRING_ALLOWLIST entries that are no longer in",
      "default_specs(). Remove these from the allowlist:",
      paste(stale, collapse = ", ")
    )
  )
})
