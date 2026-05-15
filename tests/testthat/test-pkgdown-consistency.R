# Structural guard: every paper-reproduction vignette listed in the
# pkgdown `articles:` index is also reachable from the navbar's "Paper
# reproductions" dropdown, and vice versa. Catches the post-0.7.0
# Rose finding that #121 added paper-wolf2007/wolf2008/trivers1971 to
# the articles index but not the navbar dropdown.

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

test_that("_pkgdown.yml navbar dropdown matches articles contents for paper-reproductions", {
  pkg <- .find_pkg_root()
  skip_if(is.null(pkg), "package root not found")

  pkgdown_path <- file.path(pkg, "_pkgdown.yml")
  skip_if_not(file.exists(pkgdown_path), "no _pkgdown.yml")
  skip_if_not_installed("yaml")

  cfg <- yaml::yaml.load_file(pkgdown_path)

  # 1. Pull paper-* vignettes referenced in the navbar's papers dropdown.
  navbar_papers <- character(0L)
  papers_menu <- tryCatch(
    cfg$navbar$components$papers$menu,
    error = function(e) NULL
  )
  if (!is.null(papers_menu)) {
    hrefs <- vapply(papers_menu, function(item) {
      if (is.null(item$href)) NA_character_ else item$href
    }, character(1L))
    hrefs <- hrefs[!is.na(hrefs)]
    # articles/paper-foo.html → paper-foo
    navbar_papers <- sub("^articles/", "", sub("\\.html$", "", hrefs))
    navbar_papers <- grep("^paper-", navbar_papers, value = TRUE)
  }

  # 2. Pull paper-* vignettes referenced under any articles: section.
  articles_papers <- character(0L)
  articles_blocks <- cfg$articles
  if (!is.null(articles_blocks)) {
    for (block in articles_blocks) {
      contents <- block$contents
      if (is.null(contents)) next
      papers <- grep("^paper-", contents, value = TRUE)
      articles_papers <- c(articles_papers, papers)
    }
  }
  articles_papers <- unique(articles_papers)

  skip_if(length(navbar_papers) == 0L && length(articles_papers) == 0L,
          "no paper-* vignettes in either pkgdown index")

  # 3. Symmetric difference. Allow `paper-template` to live only in
  # articles (it's a template, not a reproduction) — but every other
  # paper-* must be in both indices.
  navbar_set   <- setdiff(navbar_papers,   "paper-template")
  articles_set <- setdiff(articles_papers, "paper-template")

  only_in_navbar   <- setdiff(navbar_set,   articles_set)
  only_in_articles <- setdiff(articles_set, navbar_set)

  expect_equal(
    only_in_navbar, character(0L),
    info = paste("Vignettes in navbar but missing from articles index:",
                 paste(only_in_navbar, collapse = ", "))
  )
  expect_equal(
    only_in_articles, character(0L),
    info = paste("Vignettes in articles index but missing from navbar dropdown:",
                 paste(only_in_articles, collapse = ", "))
  )
})
