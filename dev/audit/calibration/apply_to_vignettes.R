# For each scenario with fitness-ratio >= 2x, insert a "Calibrated regime"
# subsection into the corresponding vignette. Idempotent: skips if the
# section already exists.

.libPaths(c("~/R/lib", .libPaths()))
library(jsonlite)

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L) b else a

# Scenarios with strong improvement (hand-curated from RESULTS.md)
targets <- c(
  "s-speciation", "s-disease", "s-cephalopod", "s-plasticity",
  "s-mimicry", "s-scavenging", "s-complex-landscape",
  "s-kin", "s-niche", "s-clutch-size",
  "s-stress-hypermutation", "s-predator-prey",
  "s-baldwin"  # included for the sigma-sign flip
)

art <- "dev/audit/calibration/_artifacts"

read_deltas <- function(scenario) {
  p <- file.path(art, paste0(scenario, ".json"))
  if (!file.exists(p)) return(NULL)
  j <- jsonlite::fromJSON(p, simplifyVector = TRUE)
  list(
    baseline_fit = as.numeric(j$baseline_fitness %||% NA_real_),
    best_fit     = as.numeric(j$best_fitness     %||% NA_real_),
    deltas       = j$param_deltas
  )
}

fmt_num <- function(x) {
  if (is.null(x) || !is.finite(x)) return("NA")
  if (abs(x) >= 1000 || (abs(x) > 0 && abs(x) < 0.001))
    format(x, scientific = TRUE, digits = 3)
  else
    format(signif(x, 4), scientific = FALSE)
}

block_for <- function(scenario, r) {
  ratio <- if (is.finite(r$baseline_fit) && abs(r$baseline_fit) > 1e-9)
             r$best_fit / abs(r$baseline_fit) else NA
  assignments <- character()
  for (p in names(r$deltas)) {
    d <- r$deltas[[p]]
    if (is.null(d$final) || !is.finite(d$final)) next
    # Preserve integer-ness by rounding integer-like params
    val <- d$final
    # Heuristic: if the initial value looks integer-valued, round final
    init <- d$initial
    if (!is.null(init) && is.finite(init) && init == round(init) && abs(val) < 1e6) {
      val <- as.integer(round(val))
      rhs <- sprintf("%dL", val)
    } else {
      rhs <- fmt_num(val)
    }
    assignments <- c(assignments, sprintf("s$%-30s <- %s", p, rhs))
  }

  ratio_str <- if (is.finite(ratio) && ratio > 0) sprintf("%.1fx", ratio)
               else if (is.finite(ratio) && ratio < 0) sprintf("(sign flip)")
               else "n/a"

  sprintf(paste(
    "",
    "### Calibrated regime (CMA-ES discovered)",
    "",
    "Running Phase 7 auto-calibration (`dev/audit/calibration/`) over the",
    "scenario's parameter subspace discovered the following regime, which",
    "produces a fitness improvement of **%s** over the defaults above. See",
    "`dev/audit/calibration/RESULTS.md` for the full CMA-ES results.",
    "",
    "```{r %s-calibrated, eval=FALSE}",
    "# Parameter overrides discovered by CMA-ES (see dev/audit/calibration/):",
    "s <- default_specs()",
    "%s",
    "# env <- run_alife(s)   # uncomment to run the calibrated regime",
    "```",
    "",
    sep = "\n"
  ),
  ratio_str,
  sub("^s-", "", scenario),
  paste(assignments, collapse = "\n"))
}

anchor <- "### Calibrated regime (CMA-ES discovered)"

for (scenario in targets) {
  r <- read_deltas(scenario)
  if (is.null(r)) { cat("[skip] ", scenario, "(no json)\n"); next }

  rmd_path <- file.path("vignettes", paste0(scenario, ".Rmd"))
  if (!file.exists(rmd_path)) { cat("[skip] ", scenario, "(no Rmd)\n"); next }

  txt <- readLines(rmd_path, warn = FALSE)
  if (any(grepl(anchor, txt, fixed = TRUE))) {
    cat("[skip] ", scenario, "(already has Calibrated regime)\n")
    next
  }

  # Find the first figure chunk (fig-*) — insert BEFORE it so the new
  # section appears after the main displayed chunk but before the figure.
  fig_line <- NA
  for (i in seq_along(txt)) {
    if (grepl("^```\\{r fig-", txt[i])) { fig_line <- i; break }
  }
  # If no fig chunk found, append to end
  insert_at <- if (is.na(fig_line)) length(txt) + 1L else fig_line

  block <- block_for(scenario, r)
  new_txt <- c(txt[seq_len(insert_at - 1L)],
               strsplit(block, "\n", fixed = TRUE)[[1]],
               txt[seq.int(insert_at, length(txt))])

  writeLines(new_txt, rmd_path)
  cat("[wrote] ", scenario, "\n")
}
