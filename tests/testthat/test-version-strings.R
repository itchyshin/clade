# Structural guard: every user-visible version string equals the
# DESCRIPTION-declared version. Catches the class of regression Rose
# found in the post-0.7.0 audit (DESCRIPTION said 0.6.5,
# R/clade-package.R citation said 0.5.6, inst/CITATION said 0.3.0,
# README citation said 0.5.6).
#
# This test does NOT enforce the *content* of NEWS.md or README's
# narrative — only the explicit version strings in three predictable
# locations.

library(testthat)

# Locate package root robustly (works under devtools::test, testthat::,
# devtools::check). When running with testthat::test_file(), the cwd is
# tests/testthat; when running via devtools::check it's the .Rcheck
# directory. Walk up looking for DESCRIPTION.
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

test_that("every user-visible version string matches DESCRIPTION", {
  pkg <- .find_pkg_root()
  skip_if(is.null(pkg), "package root not found")

  desc_path <- file.path(pkg, "DESCRIPTION")
  desc      <- readLines(desc_path, warn = FALSE)
  ver       <- sub("^Version:\\s*", "",
                    grep("^Version:", desc, value = TRUE)[1L])
  ver       <- trimws(ver)
  expect_true(nzchar(ver), info = "DESCRIPTION must declare Version:")

  # 1. R/clade-package.R citation
  pkg_R <- file.path(pkg, "R", "clade-package.R")
  if (file.exists(pkg_R)) {
    txt <- paste(readLines(pkg_R, warn = FALSE), collapse = "\n")
    expect_true(
      grepl(sprintf("R package version %s", ver), txt, fixed = TRUE),
      info = sprintf(
        "R/clade-package.R citation must say 'R package version %s' (DESCRIPTION = %s)",
        ver, ver)
    )
  }

  # 2. inst/CITATION note + textVersion
  cit_path <- file.path(pkg, "inst", "CITATION")
  if (!file.exists(cit_path)) {
    cit_path <- system.file("CITATION", package = "clade")
  }
  if (nzchar(cit_path) && file.exists(cit_path)) {
    txt <- paste(readLines(cit_path, warn = FALSE), collapse = "\n")
    expect_true(
      grepl(sprintf("R package version %s", ver), txt, fixed = TRUE),
      info = sprintf("inst/CITATION must say 'R package version %s'", ver)
    )
  }

  # 3. README citation BibTeX block
  readme <- file.path(pkg, "README.md")
  if (file.exists(readme)) {
    txt <- paste(readLines(readme, warn = FALSE), collapse = "\n")
    expect_true(
      grepl(sprintf("R package version %s", ver), txt, fixed = TRUE),
      info = sprintf("README.md citation must say 'R package version %s'", ver)
    )
  }
})
