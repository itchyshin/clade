# Structural guard: every spec flag-name cited in README.md's
# "Biological modules" table exists in default_specs(). Catches the
# class of Rose finding where the modules table cited `mate_choice`,
# `predators`, `signal_mating` (none of which are in default_specs();
# the actual flags are `mate_choice_mode`, `n_predators_init > 0`,
# `signal_dims > 0`).
#
# The test is deliberately narrow — only the "Biological modules"
# table, only single-word backtick-quoted identifiers, only ones that
# look like spec field names (lowercase with underscores). It doesn't
# try to be a general README linter.

library(testthat)

.find_pkg_root <- function() {
  candidates <- c(
    ".",
    file.path("..", ".."),
    file.path("..", "..", ".."),
    system.file(package = "clade")
  )
  for (p in candidates) {
    if (file.exists(file.path(p, "DESCRIPTION"))) return(normalizePath(p))
  }
  NULL
}

# Allow-list: identifiers cited in the modules table that are
# legitimate references but not literally fields in default_specs().
# Examples: function names, file paths, brain-type values, comparison
# expressions like `ploidy = 2`.
.MODULES_TABLE_ALLOWLIST <- c(
  # Brain type values (not flags)
  "bnn", "ann", "ctrnn", "grn", "transformer", "synthesis", "random",
  # Function / file references
  "default_specs", "run_alife", "get_run_data", "plot_run",
  # Comparison-style entries: `ploidy = 2`, `n_predators_init > 0` etc.
  # are extracted as `ploidy`, `n_predators_init` — those are real
  # fields, no issue. But the right-hand-side number ('2', '0') is
  # not. Numeric tokens are filtered out separately.
  # Cross-references and metaphors that aren't flags
  "specs", "TRUE", "FALSE"
)

test_that("every spec flag in README modules table exists in default_specs()", {
  pkg <- .find_pkg_root()
  skip_if(is.null(pkg), "package root not found")

  readme <- file.path(pkg, "README.md")
  skip_if_not(file.exists(readme), "no README.md")

  lines <- readLines(readme, warn = FALSE)

  # Find the "Biological modules" table. Bound it by the next "## " heading.
  start_idx <- grep("^##\\s+Biological modules", lines)
  if (!length(start_idx)) skip("no 'Biological modules' section in README")
  start_idx <- start_idx[1L]

  remaining <- lines[(start_idx + 1L):length(lines)]
  end_offset <- grep("^##\\s+", remaining)
  end_idx <- if (length(end_offset)) (start_idx + end_offset[1L] - 1L) else length(lines)
  table_lines <- lines[start_idx:end_idx]

  # Extract single-word backtick-quoted identifiers from table rows
  # (lines starting with "|"). Pattern: `lowercase_with_underscores` —
  # the canonical spec-field shape. Multi-word backticks (e.g.
  # `b/c > 1`) are skipped.
  cells <- grep("^\\|", table_lines, value = TRUE)
  flag_matches <- regmatches(
    cells,
    gregexpr("`[a-z][a-z0-9_]*`", cells)
  )
  flags <- unique(unlist(flag_matches, use.names = FALSE))
  flags <- gsub("`", "", flags, fixed = TRUE)

  # Filter: drop allowlist (function names, brain types, etc.) and
  # any pure numerics (shouldn't be in this set, but safe).
  flags <- setdiff(flags, .MODULES_TABLE_ALLOWLIST)
  flags <- flags[!grepl("^[0-9]+$", flags)]

  skip_if(!length(flags), "no candidate flag names extracted")

  s <- default_specs()
  missing <- setdiff(flags, names(s))

  expect_equal(
    missing, character(0L),
    info = paste(
      "README.md 'Biological modules' table cites flag name(s) that",
      "are not in default_specs(). Either add the field to",
      "default_specs(), correct the README, or add the name to",
      ".MODULES_TABLE_ALLOWLIST in this test if it's a legitimate",
      "non-flag reference. Missing:",
      paste(missing, collapse = ", ")
    )
  )
})
