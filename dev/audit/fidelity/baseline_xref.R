#!/usr/bin/env Rscript
# Baseline audit (expanded): 10-seed multi-seed run with metrics the
# MATLAB and alifeR prototypes also track, so the companion report
# can do a three-way comparison.
#
# This does NOT attempt to match MATLAB/alifeR output numerically —
# the three kernels differ on energy scales, grass caps, eating
# semantics, and brain costs, so quantitative parity is impossible
# without kernel harmonisation. Instead, this verifies clade's
# baseline is internally consistent and produces the qualitative
# signatures the ancestors produce:
#   - Population grows or stabilises (not extinction)
#   - Energy-efficient foraging emerges (mean_energy > 0 at
#     equilibrium; agents don't starve en masse)
#   - ANN weights evolve (mean_ann_weight_magnitude not flat)
#   - Genetic diversity decays and reaches equilibrium
#
# Usage: Rscript dev/audit/fidelity/baseline_xref.R

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
  library(ggplot2)
  library(patchwork)
})

one_run <- function(seed, max_ticks = 500L) {
  s <- default_specs()
  s$n_agents_init  <- 100L
  s$grid_rows      <- 30L
  s$grid_cols      <- 30L
  s$grass_rate     <- 0.15
  s$max_ticks      <- as.integer(max_ticks)
  s$random_seed    <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$seed <- seed
  d
}

seeds <- 1L:10L
cat(sprintf("Running baseline %d seeds x 500 ticks...\n", length(seeds)))
t0 <- Sys.time()
runs <- lapply(seeds, function(sd) {
  cat(sprintf("  seed %d\n", sd))
  one_run(sd)
})
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
cat(sprintf("Done in %.1f s.\n\n", elapsed))

all_ticks <- do.call(rbind, runs)
saveRDS(all_ticks, "dev/audit/fidelity/baseline_xref_ticks.rds")

# ── Summary at equilibrium (t > 200) ─────────────────────────────────────────

eq <- all_ticks[all_ticks$t > 200, ]
per_seed <- aggregate(
  cbind(n_agents, mean_energy, mean_age, genetic_diversity,
        mean_ann_weight_magnitude, n_births, n_starvations,
        grass_coverage) ~ seed,
  data = eq, FUN = mean
)
cat("Per-seed equilibrium (t > 200):\n")
print(per_seed)

cat("\nCross-seed summary (mean ± SD):\n")
for (col in setdiff(names(per_seed), "seed")) {
  cat(sprintf("  %-30s %8.3f ± %6.3f\n", col,
              mean(per_seed[[col]]), sd(per_seed[[col]])))
}

# Qualitative checks that ancestors also produce:
cat("\nQualitative signatures (mean across seeds):\n")
n_final <- tail(aggregate(n_agents ~ t, all_ticks, mean)$n_agents, 1L)
cat(sprintf("  Final population:        %.0f (P1 stable/growing: %s)\n",
            n_final, if (n_final > 30) "PASS" else "FAIL"))
e_final <- tail(aggregate(mean_energy ~ t, all_ticks, mean)$mean_energy, 1L)
cat(sprintf("  Final mean_energy:       %.1f (P2 > 0: %s)\n",
            e_final, if (e_final > 10) "PASS" else "FAIL"))
w0 <- aggregate(mean_ann_weight_magnitude ~ t, all_ticks, mean)
w_change <- abs(tail(w0$mean_ann_weight_magnitude, 1L)
                - head(w0$mean_ann_weight_magnitude, 1L))
cat(sprintf("  ANN weight magnitude shift: %.3f (P3 > 0.01: %s)\n",
            w_change, if (w_change > 0.01) "PASS" else "FAIL"))
d0 <- aggregate(genetic_diversity ~ t, all_ticks, mean)
d_change <- head(d0$genetic_diversity, 1L) - tail(d0$genetic_diversity, 1L)
cat(sprintf("  Diversity decay (t=1 -> t=500): %.3f (P4 > 0: %s)\n",
            d_change, if (d_change > 0) "PASS" else "FAIL"))

# ── Figure ──────────────────────────────────────────────────────────────────

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)

panels <- function(ycol, title, ylab, colour = "#2196F3") {
  ggplot(all_ticks, aes(t, .data[[ycol]], group = seed)) +
    geom_line(alpha = 0.35, colour = colour, linewidth = 0.35) +
    stat_summary(aes(group = 1), fun = mean, geom = "line",
                 colour = colour, linewidth = 1.0) +
    labs(title = title, x = "Tick", y = ylab) +
    theme_minimal(base_size = 11)
}

p1 <- panels("n_agents",                  "Population size",
             "n_agents", "#2196F3")
p2 <- panels("mean_energy",               "Mean energy",
             "energy", "#F44336")
p3 <- panels("mean_ann_weight_magnitude", "Evolved ANN weight magnitude",
             "|W| (mean)", "#9C27B0")
p4 <- panels("genetic_diversity",         "Genetic diversity",
             "mean pairwise distance", "#4CAF50")
p5 <- panels("grass_coverage",            "Grass coverage",
             "fraction cells > 0", "#8BC34A")
p6 <- panels("n_births",                  "Births per tick",
             "n_births", "#FF9800")

p <- (p1 | p2 | p3) / (p4 | p5 | p6) +
  plot_annotation(
    title = "Baseline foraging audit: 10 seeds x 500 ticks",
    subtitle = sprintf(
      "30x30 grid, 100 agents init, grass_rate=0.15. Bold=cross-seed mean."),
    theme = theme(plot.title = element_text(face = "bold"))
  )

ggsave("dev/audit/fidelity/figs/baseline_xref.png", p,
       width = 14, height = 7, dpi = 150)
cat("\nWrote dev/audit/fidelity/figs/baseline_xref.png\n")
