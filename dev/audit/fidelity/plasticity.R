#!/usr/bin/env Rscript
# Fidelity audit: phenotypic plasticity (Pigliucci 2001, DeWitt & Scheiner 2004).
# Prediction: In stable environments, plasticity drifts down; in variable
#            environments (seasonality), plasticity is maintained higher.
#
# 0.4.1 update: use Tier 5A `bnn_sigma_source = "trait"` so BNN prior
# width tracks TRAIT_PLASTICITY directly. Pair with Tier 5C
# `brain_energy_sigma_scale > 0` so plasticity carries a real energetic
# cost — this is what creates the selection gradient DeWitt & Scheiner
# predict. Without these two flags the audit was flat pre-0.4.1
# (see prior verdict in plasticity.md).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(seasonal_amp, seed, max_ticks = 500L) {
  s <- default_specs()
  s$phenotypic_plasticity   <- TRUE
  s$plasticity_init_mean    <- 0.3
  s$plasticity_mutation_sd  <- 0.05
  # 0.4.1: couple BNN sigma to the plasticity trait and cost it.
  s$bnn_sigma_source        <- "trait"
  s$brain_energy_sigma_scale <- 0.02
  s$seasonal_amplitude      <- seasonal_amp
  s$season_length           <- 50L
  s$n_agents_init           <- 100L
  s$grid_rows               <- 30L
  s$grid_cols               <- 30L
  s$grass_rate              <- 0.15
  s$max_agents              <- 400L
  s$max_ticks               <- as.integer(max_ticks)
  s$random_seed             <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$seasonal_amp <- seasonal_amp
  d$seed <- seed
  d
}

seeds <- 1L:4L
cat("── plasticity: stable vs seasonal (4 seeds, 500 ticks)\n")
stable <- lapply(seeds, function(sd) {
  cat(sprintf("  stable seed %d\n", sd))
  one_run(0.0, sd)
})
seasonal <- lapply(seeds, function(sd) {
  cat(sprintf("  seasonal amp=0.7 seed %d\n", sd))
  one_run(0.7, sd)
})

fin_p <- function(runs) {
  vapply(runs, function(d) tail(d$mean_plasticity, 1L), numeric(1L))
}
init_p <- function(runs) {
  vapply(runs, function(d) d$mean_plasticity[1], numeric(1L))
}
stab_fin <- fin_p(stable); stab_init <- init_p(stable)
seas_fin <- fin_p(seasonal); seas_init <- init_p(seasonal)

cat(sprintf("\nStable:   init=%.3f → final=%.3f (Δ=%+.3f)\n",
            mean(stab_init), mean(stab_fin),
            mean(stab_fin - stab_init)))
cat(sprintf("Seasonal: init=%.3f → final=%.3f (Δ=%+.3f)\n",
            mean(seas_init), mean(seas_fin),
            mean(seas_fin - seas_init)))
p1_pass <- mean(seas_fin) > mean(stab_fin)
cat(sprintf("P1 (seasonal maintains higher plasticity): %s\n",
            if (p1_pass) "PASS" else "FAIL"))

all_ticks <- do.call(rbind, c(stable, seasonal))
all_ticks$cond <- ifelse(all_ticks$seasonal_amp == 0,
                          "stable", "seasonal (amp=0.7)")
saveRDS(all_ticks, "dev/audit/fidelity/plasticity_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p <- ggplot(all_ticks, aes(t, mean_plasticity, colour = cond,
                            group = interaction(cond, seed))) +
  geom_line(alpha = 0.45, linewidth = 0.4) +
  stat_summary(aes(group = cond), fun = mean, geom = "line",
               linewidth = 1.1) +
  scale_colour_manual(values = c(stable = "#377eb8",
                                  `seasonal (amp=0.7)` = "#e41a1c"),
                      name = NULL) +
  labs(title = "Phenotypic plasticity: stable vs seasonal (DeWitt & Scheiner 2004)",
       subtitle = sprintf("4 seeds × 500 ticks. Stable Δ=%+.3f, Seasonal Δ=%+.3f",
                          mean(stab_fin - stab_init),
                          mean(seas_fin - seas_init)),
       x = "Tick", y = "mean_plasticity") +
  theme_minimal(base_size = 12)
ggsave("dev/audit/fidelity/figs/plasticity.png", p,
       width = 9, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/plasticity.png\n")
