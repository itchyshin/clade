# Parse-only smoke test — no Julia. Validates the parser on every s-*.Rmd
# and writes a summary CSV. Run with:
#   Rscript dev/audit/dry_run_parse.R

source(file.path("dev", "audit", "parse_rmd.R"))
source(file.path("dev", "audit", "scenario_oracle.R"))

out_dir <- "dev/audit/_artifacts"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

paths <- list.files("vignettes", pattern = "^s-.*\\.Rmd$", full.names = TRUE)

rows <- lapply(paths, function(p) {
  parsed <- audit_parse_rmd(p)
  oracle <- audit_oracle_for(parsed$vignette)
  data.frame(
    vignette      = parsed$vignette,
    title         = parsed$title %||% NA_character_,
    n_chunks      = parsed$n_chunks,
    n_displayed   = length(parsed$displayed_chunks),
    n_fig_refs    = length(parsed$fig_refs),
    first_fig     = if (length(parsed$fig_refs)) parsed$fig_refs[[1]]$name else NA_character_,
    first_fig_cap = if (length(parsed$fig_refs)) parsed$fig_refs[[1]]$fig_cap else NA_character_,
    has_hypothesis = !is.na(parsed$hypothesis),
    has_what_found = !is.na(parsed$what_we_found),
    displayed_code_chars = nchar(parsed$displayed_code),
    oracle_flags  = paste(oracle$flags, collapse = ";"),
    oracle_metric = oracle$metric %||% NA_character_,
    oracle_direction = oracle$direction %||% NA_character_,
    oracle_test   = oracle$test_file %||% NA_character_,
    oracle_module = oracle$module_file %||% NA_character_,
    stringsAsFactors = FALSE
  )
})

tbl <- do.call(rbind, rows)
out <- file.path(out_dir, "parse_summary.csv")
utils::write.csv(tbl, out, row.names = FALSE)
cat(sprintf("wrote %s (%d rows)\n", out, nrow(tbl)))
print(tbl[, c("vignette","n_displayed","n_fig_refs","has_what_found",
              "oracle_metric","oracle_direction")])
