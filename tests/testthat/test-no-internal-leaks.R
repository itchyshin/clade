# Drift-guard against developer-process artefacts leaking into user-facing
# surfaces (roxygen → rendered Rd, vignette prose → rendered HTML).
#
# Background: 2026-05-16 Pat+Rose pkgdown audit (dev/audit/pkgdown-pat-rose.md)
# found 17+ sites where CLAUDE.md, ~/.claude/ plan paths, PR-numbers,
# "Sergio", "Phase A", "Tier B", "v0.8-core", and bare dev/ paths had
# leaked into rendered help pages and vignettes. Tier 1 (PR #148)
# scrubbed every site; this test prevents the next regression.
#
# Two checks:
#   1. FORBIDDEN_TOKENS — substrings that should never appear in
#      user-facing surfaces.
#   2. BARE_DEV_PATHS — `dev/{docs,design,audit}/...` paths that aren't
#      wrapped in a markdown link `[...](https://github.com/...)`.
#
# Scope:
#   - R/*.R: only roxygen lines (`#'`). Plain R code comments are
#     internal-developer surface and exempt.
#   - vignettes/*.Rmd: only prose lines. Lines inside fenced code blocks
#     (``` ... ```) are exempt — code comments may legitimately reference
#     internal paths.
#
# Allowlists:
#   - Files in dev/, NEWS.md are intrinsically internal-developer surface
#     and not scanned.
#   - Specific known-OK lines via ALLOWED_LINES.

library(testthat)

# Tokens that should never appear in user-facing prose / roxygen.
.FORBIDDEN_TOKENS <- c(
  "\\bCLAUDE\\.md\\b",
  "~/\\.claude/",
  "\\bPhase [AB]\\b",
  "\\bTier [AB][0-5]?\\b",
  "\\bSergio\\b",
  "\\bv0\\.8-core\\b",
  "\\bPR #[0-9]+"
)

# Bare-path pattern (after stripping markdown links from the line).
# Matches `dev/{docs,design,audit}/...md|R|rds`.
.BARE_DEV_PATH_RE <-
  "\\bdev/(docs|design|audit)/[A-Za-z0-9_./-]+\\.(md|R|rds)\\b"

# Markdown inline-link span: `[display](url)`. Strip these from each line
# before scanning for bare paths — paths inside link targets or display
# text are properly wrapped and should not trigger.
.MD_LINK_RE <- "\\[[^\\]]*\\]\\([^)]*\\)"

# Known-OK exceptions. Add a line here only after confirming the
# violation is a deliberate display of the path inside a teaching example
# or other context where the leak rule should not apply.
.ALLOWED_LINES <- list(
  # Multi-line markdown links: the `]( ` and `https://...` are on
  # different lines, so the per-line link-stripper sees the URL alone
  # and flags it as a bare path. The link IS properly wrapped — just
  # not on one line.
  "vignettes/ps-agent-parameters.Rmd:58" = "multi-line markdown link continuation"
)

.find_repo_root <- function() {
  # Self-locating: walk up from getwd() looking for DESCRIPTION + R/ + tests/.
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

# Strip R-Markdown fenced code blocks from a character vector of lines.
# Returns the lines with chunk content blanked out (still indexed for
# error-message line numbers).
.strip_rmd_chunks <- function(lines) {
  inside <- FALSE
  for (i in seq_along(lines)) {
    if (grepl("^```", lines[i])) {
      inside <- !inside
      lines[i] <- ""
    } else if (inside) {
      lines[i] <- ""
    }
  }
  lines
}

# Keep only roxygen lines (`#'`); blank the rest.
.keep_roxygen <- function(lines) {
  ifelse(grepl("^\\s*#'", lines), lines, "")
}

.scan_file <- function(path, repo_root) {
  rel <- sub(paste0("^", repo_root, "/"), "", path)
  raw <- readLines(path, warn = FALSE)
  scan_lines <- if (grepl("\\.Rmd$", path)) {
    .strip_rmd_chunks(raw)
  } else {
    .keep_roxygen(raw)
  }
  hits <- character(0)
  for (re in .FORBIDDEN_TOKENS) {
    m <- grepl(re, scan_lines, perl = TRUE)
    for (i in which(m)) {
      key <- sprintf("%s:%d", rel, i)
      if (!key %in% names(.ALLOWED_LINES)) {
        hits <- c(hits, sprintf("%s — forbidden token /%s/: %s",
                                key, re, trimws(scan_lines[i])))
      }
    }
  }
  # Bare-path check: strip [display](url) link spans first, then look
  # for dev/{docs,design,audit}/... mentions left over (= unwrapped).
  stripped <- gsub(.MD_LINK_RE, "", scan_lines, perl = TRUE)
  m <- grepl(.BARE_DEV_PATH_RE, stripped, perl = TRUE)
  for (i in which(m)) {
    key <- sprintf("%s:%d", rel, i)
    if (!key %in% names(.ALLOWED_LINES)) {
      hits <- c(hits, sprintf("%s — bare dev/ path (wrap as markdown link): %s",
                              key, trimws(scan_lines[i])))
    }
  }
  hits
}

test_that("no developer-process leaks in R/ roxygen or vignette prose", {
  repo_root <- .find_repo_root()
  skip_if(is.null(repo_root),
          "Could not locate package root from test working directory.")

  r_files <- list.files(file.path(repo_root, "R"),
                        pattern = "\\.R$", full.names = TRUE)
  rmd_files <- list.files(file.path(repo_root, "vignettes"),
                          pattern = "\\.Rmd$", full.names = TRUE)
  files <- c(r_files, rmd_files)

  all_hits <- unlist(lapply(files, .scan_file, repo_root = repo_root),
                     use.names = FALSE)

  expect_equal(
    all_hits, character(0L),
    info = paste0(
      "Internal-leak drift detected. Either fix the source line, or ",
      "(if the mention is intentional) add the `file:line` key to ",
      "`.ALLOWED_LINES` in tests/testthat/test-no-internal-leaks.R ",
      "with a comment explaining why.\nHits:\n  ",
      paste(all_hits, collapse = "\n  ")
    )
  )
})
