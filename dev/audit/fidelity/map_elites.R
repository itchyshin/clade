#!/usr/bin/env Rscript
# Fidelity audit: MAP-Elites (Mouret & Clune 2015).
# Prediction: MAP-Elites fills a behavioural archive with diverse
#            high-fitness parameter configurations — not a single optimum.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2)
})

specs <- default_specs()
specs$n_agents_init <- 50L
specs$grid_rows     <- 20L
specs$grid_cols     <- 20L
specs$max_ticks     <- 150L

cat("── MAP-Elites 150 iterations, short runs\n")
t0 <- Sys.time()
result <- search_map_elites(
  specs_base   = specs,
  archive_dims = list(
    genetic_diversity = seq(0, 1,   by = 0.1),
    n_agents          = seq(0, 100, by = 10)
  ),
  n_iterations = 150L,
  objective    = "genetic_diversity",
  verbose      = FALSE
)
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
cat(sprintf("Done in %.1f min.\n", elapsed))

archive <- result$archive
n_total <- length(archive)
n_filled <- sum(vapply(archive, function(x) !is.null(x), logical(1L)))
fill_rate <- n_filled / n_total

# Extract best scores from filled cells (whatever structure they have)
scores <- unlist(lapply(archive, function(x) {
  if (is.null(x)) return(NA_real_)
  if (is.list(x) && "score" %in% names(x)) return(as.numeric(x$score))
  if (is.list(x) && "fitness" %in% names(x)) return(as.numeric(x$fitness))
  if (is.numeric(x) && length(x) == 1L) return(as.numeric(x))
  NA_real_
}))

cat(sprintf("\nArchive fill: %d / %d cells (%.1f%%)\n",
            n_filled, n_total, 100 * fill_rate))
if (any(!is.na(scores))) {
  cat(sprintf("Score range: %.3f – %.3f (mean %.3f)\n",
              min(scores, na.rm = TRUE),
              max(scores, na.rm = TRUE),
              mean(scores, na.rm = TRUE)))
}

if (!is.null(result$history) && nrow(result$history) > 0) {
  h <- result$history
  cat("\nHistory summary:\n")
  print(summary(h$score))
  cat(sprintf("Cells filled grew from %d → %d over %d iterations\n",
              head(h$filled_cells, 1L), tail(h$filled_cells, 1L),
              nrow(h)))
}

p1_pass <- n_filled >= 5
cat(sprintf("\nP1 (archive has ≥5 filled cells = diversity): %s\n",
            if (p1_pass) "PASS" else "FAIL"))

saveRDS(list(n_filled = n_filled, n_total = n_total,
             scores = scores, history = result$history,
             elapsed_min = elapsed),
        "dev/audit/fidelity/map_elites_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
if (!is.null(result$map)) {
  ggsave("dev/audit/fidelity/figs/map_elites.png", result$map,
         width = 9, height = 6, dpi = 150)
  cat("Wrote dev/audit/fidelity/figs/map_elites.png\n")
} else {
  cat("result$map is NULL; skipping figure\n")
}
