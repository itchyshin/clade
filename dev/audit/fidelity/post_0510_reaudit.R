# Post-0.5.10 ledger check: re-run the 12 diploid-sensitive ✅ audit
# scripts to verify their verdicts hold under real diploid sex (the
# kernel bug that made every ploidy=2 scenario structurally asex was
# fixed in 0.5.10).
#
# Each script is sourced; we capture its stdout and grep for the
# PASS/recheck/FAIL verdicts. Output: a per-scenario summary.
#
# Wall time budget: ~8 min total (sequential; each script uses PSOCK
# internally).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)   # installed 0.5.10
})

SCRIPTS <- c(
  # High-risk (claims directly depend on diploid sex)
  "pop_genetics",       # parent-offspring h² regression
  "speciation",         # assortative-mating reproductive isolation
  "kin",                # Hamilton's rule via pedigree r
  # Medium-risk (diploid traits)
  "cooperation",        # kin-based altruism
  "brain_size",         # parental provisioning
  "body_size",          # Cope's rule
  "parental_investment",  # Trivers investment
  # Lower-risk (diploid life-history)
  "clutch_size",
  "life_history",
  "pace_of_life",
  "parental_care",
  "stress_hypermutation"
)

results_file <- "dev/audit/fidelity/post_0510_summary.txt"
con <- file(results_file, "w")
on.exit(close(con), add = TRUE)

cat(file = con, sprintf(
  "post-0.5.10 diploid-sensitive ledger check — %s\n\n",
  format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
cat(file = con, "clade version: ", as.character(packageVersion("clade")), "\n\n")

for (nm in SCRIPTS) {
  path <- file.path("dev/audit/fidelity", paste0(nm, ".R"))
  if (!file.exists(path)) {
    cat(file = con, sprintf("[%-22s] SKIP — runner not found\n", nm))
    next
  }
  cat(sprintf("=== %s ===\n", nm))
  t0 <- Sys.time()
  capture <- tryCatch(
    utils::capture.output(source(path, local = new.env()), type = "message"),
    error = function(e) paste0("ERROR: ", conditionMessage(e))
  )
  wall <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  # Keep lines that look like verdicts: PASS/recheck/FAIL, or Δ...t=..., or "── "
  keep_idx <- grepl("PASS|FAIL|recheck|Δ|\\bt = |t=|verdict|passed|── |ERROR",
                    capture, perl = TRUE)
  verdict_lines <- capture[keep_idx]
  cat(file = con,
      sprintf("[%-22s] %.0fs wall | %d verdict lines\n", nm, wall,
              length(verdict_lines)))
  if (length(verdict_lines) > 0L) {
    cat(file = con, paste0("  ", verdict_lines, "\n"))
  } else {
    cat(file = con, "  (no verdict lines captured — see script output)\n")
  }
  cat(file = con, "\n")
  flush(con)
}

cat("\nDone. Summary written to:", results_file, "\n")
