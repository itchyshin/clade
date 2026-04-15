#!/usr/bin/env Rscript
# Fidelity audit: speciation via reproductive isolation.
#
# Theory:
#   Dieckmann & Doebeli (1999) Nature 400:354: sympatric speciation
#     via assortative mating after disruptive selection.
#   Coyne & Orr (2004): reproductive isolation accumulates with
#     genetic distance.
#
# Predictions:
#   P1. With speciation=TRUE + sufficient mutation_sd + time, n_species
#       rises above 1.
#   P2. Higher mutation_sd accelerates divergence (n_species reached
#       earlier or higher).
#   P3. Lower isolation_threshold allows more species to form.
#
# MATLAB base: N/A. alifeR prototype: speciation.R (114 lines).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
  library(ggplot2)
  library(patchwork)
})

one_run <- function(mutation_sd, isolation_threshold, seed,
                    max_ticks = 1000L) {
  s <- default_specs()
  s$speciation          <- TRUE
  s$isolation_threshold <- isolation_threshold
  s$mutation_sd         <- mutation_sd
  s$speciation_cluster_interval <- 10L
  s$n_agents_init       <- 100L
  s$grid_rows           <- 30L
  s$grid_cols           <- 30L
  s$grass_rate          <- 0.15
  s$max_agents          <- 500L
  s$max_ticks           <- as.integer(max_ticks)
  s$random_seed         <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$mutation_sd <- mutation_sd
  d$isolation_threshold <- isolation_threshold
  d$seed <- seed
  d
}

# ── Step 1: default-ish vs permissive regime ────────────────────────────────

seeds <- 1L:3L
cat("── Step 1: default mutation_sd=0.1 vs aggressive 0.3 at iso=0.15\n")
default_runs <- lapply(seeds, function(sd) {
  cat(sprintf("  default mut=0.1 seed %d\n", sd))
  one_run(0.1, 0.15, sd)
})
aggr_runs <- lapply(seeds, function(sd) {
  cat(sprintf("  aggr    mut=0.3 seed %d\n", sd))
  one_run(0.3, 0.15, sd)
})

final_nsp <- function(runs) {
  vapply(runs, function(d) max(d$n_species, na.rm = TRUE), numeric(1L))
}
default_nsp <- final_nsp(default_runs)
aggr_nsp <- final_nsp(aggr_runs)
cat(sprintf("  default mut=0.1: max n_species = %.1f ± %.1f\n",
            mean(default_nsp), sd(default_nsp)))
cat(sprintf("  aggr    mut=0.3: max n_species = %.1f ± %.1f\n",
            mean(aggr_nsp), sd(aggr_nsp)))
p1_pass <- mean(aggr_nsp) > 1
cat(sprintf("  P1 (speciation occurs at aggressive regime): %s\n",
            if (p1_pass) "PASS" else "FAIL"))
p2_pass <- mean(aggr_nsp) > mean(default_nsp)
cat(sprintf("  P2 (higher mut -> more speciation): %s\n",
            if (p2_pass) "PASS" else "FAIL"))

# ── Step 2: isolation threshold sweep ───────────────────────────────────────

cat("\n── Step 2: isolation_threshold sweep (mut_sd = 0.2)\n")
iso_grid <- c(0.10, 0.15, 0.25, 0.40, 0.60)
iso_results <- lapply(iso_grid, function(iso) {
  nsps <- vapply(1L:3L, function(sd) {
    d <- one_run(0.2, iso, sd, max_ticks = 1000L)
    max(d$n_species, na.rm = TRUE)
  }, numeric(1L))
  cat(sprintf("  iso=%.2f: max n_species = %.1f ± %.1f\n",
              iso, mean(nsps), sd(nsps)))
  data.frame(isolation_threshold = iso,
             mean_nsp = mean(nsps), sd_nsp = sd(nsps))
})
iso_df <- do.call(rbind, iso_results)
spear <- cor(iso_df$isolation_threshold, iso_df$mean_nsp,
             method = "spearman")
cat(sprintf("  P3 (Spearman iso vs n_species rho = %.2f, expect negative): %s\n",
            spear, if (spear < -0.3) "PASS" else "WEAK"))

# ── Save + figure ───────────────────────────────────────────────────────────

all_ticks <- do.call(rbind, c(default_runs, aggr_runs))
saveRDS(list(all_ticks = all_ticks, iso_df = iso_df),
        "dev/audit/fidelity/speciation_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)

all_ticks$regime <- ifelse(all_ticks$mutation_sd == 0.1,
                            "default mut=0.1", "aggr mut=0.3")

p_nsp <- ggplot(all_ticks, aes(t, n_species, colour = regime,
                                group = interaction(regime, seed))) +
  geom_step(alpha = 0.5, linewidth = 0.5) +
  stat_summary(aes(group = regime), fun = mean, geom = "step",
               linewidth = 1.1) +
  scale_colour_manual(values = c("default mut=0.1" = "#F44336",
                                  "aggr mut=0.3" = "#2196F3"),
                      name = NULL) +
  labs(title = "n_species over time (1000 ticks, iso=0.15)",
       x = "Tick", y = "n_species") +
  theme_minimal(base_size = 11)

p_div <- ggplot(all_ticks, aes(t, genetic_diversity, colour = regime,
                                group = interaction(regime, seed))) +
  geom_line(alpha = 0.5, linewidth = 0.4) +
  stat_summary(aes(group = regime), fun = mean, geom = "line",
               linewidth = 1.0) +
  scale_colour_manual(values = c("default mut=0.1" = "#F44336",
                                  "aggr mut=0.3" = "#2196F3"),
                      name = NULL) +
  labs(title = "Genetic diversity over time",
       x = "Tick", y = "genetic_diversity") +
  theme_minimal(base_size = 11)

p_iso <- ggplot(iso_df, aes(isolation_threshold, mean_nsp)) +
  geom_errorbar(aes(ymin = mean_nsp - sd_nsp,
                    ymax = mean_nsp + sd_nsp),
                width = 0.02, colour = "grey50") +
  geom_line(linewidth = 0.8, colour = "#FF9800") +
  geom_point(size = 3, colour = "#FF9800") +
  labs(title = "Speciation vs isolation threshold (mut=0.2)",
       x = "isolation_threshold",
       y = "max n_species (1000 ticks)") +
  theme_minimal(base_size = 11)

p <- (p_nsp | p_div) / p_iso +
  plot_annotation(
    title = "Speciation fidelity audit: reproductive isolation",
    subtitle = "3 seeds, 1000 ticks. Dieckmann & Doebeli 1999.",
    theme = theme(plot.title = element_text(face = "bold"))
  )

ggsave("dev/audit/fidelity/figs/speciation.png", p,
       width = 12, height = 8, dpi = 150)
cat("\nWrote dev/audit/fidelity/figs/speciation.png\n")
