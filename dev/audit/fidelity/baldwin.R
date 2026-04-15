#!/usr/bin/env Rscript
# Fidelity audit: Baldwin Effect / BNN uncertainty canalization.
# Prediction: mean_prior_sigma declines over time in stable environments
#            (genetic assimilation of learned behaviour).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(seasonal_amp, seed, max_ticks = 800L) {
  s <- default_specs()
  s$brain_type        <- "bnn"
  s$bnn_sigma_init    <- 0.5
  s$seasonal_amplitude <- seasonal_amp
  s$season_length     <- 50L
  s$n_agents_init     <- 100L
  s$grid_rows         <- 30L; s$grid_cols <- 30L
  s$grass_rate        <- 0.12
  s$max_agents        <- 400L
  s$max_ticks         <- as.integer(max_ticks)
  s$random_seed       <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$seasonal_amp <- seasonal_amp; d$seed <- seed
  d
}

seeds <- 1L:4L
cat("── BNN sigma: stable vs seasonal (4 seeds, 800 ticks)\n")
stable <- lapply(seeds, function(sd) {
  cat(sprintf("  stable seed %d\n", sd))
  one_run(0.0, sd)
})
seasonal <- lapply(seeds, function(sd) {
  cat(sprintf("  seasonal amp=0.8 seed %d\n", sd))
  one_run(0.8, sd)
})

fin_s <- function(runs) {
  vapply(runs, function(d) tail(d$mean_prior_sigma, 1L), numeric(1L))
}
init_s <- function(runs) {
  vapply(runs, function(d) d$mean_prior_sigma[1], numeric(1L))
}
stab_fin <- fin_s(stable); stab_init <- init_s(stable)
seas_fin <- fin_s(seasonal); seas_init <- init_s(seasonal)

cat(sprintf("\nStable:   init=%.3f → final=%.3f (Δ=%+.3f)\n",
            mean(stab_init), mean(stab_fin),
            mean(stab_fin - stab_init)))
cat(sprintf("Seasonal: init=%.3f → final=%.3f (Δ=%+.3f)\n",
            mean(seas_init), mean(seas_fin),
            mean(seas_fin - seas_init)))
p1_pass <- mean(stab_fin - stab_init) < -0.02
cat(sprintf("P1 (stable shows canalization — sigma declines): %s\n",
            if (p1_pass) "PASS" else "FAIL"))
p2_pass <- mean(seas_fin) > mean(stab_fin)
cat(sprintf("P2 (seasonal preserves higher sigma): %s\n",
            if (p2_pass) "PASS" else "FAIL"))

all_ticks <- do.call(rbind, c(stable, seasonal))
all_ticks$cond <- ifelse(all_ticks$seasonal_amp == 0,
                          "stable", "seasonal (amp=0.8)")
saveRDS(all_ticks, "dev/audit/fidelity/baldwin_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p <- ggplot(all_ticks, aes(t, mean_prior_sigma, colour = cond,
                            group = interaction(cond, seed))) +
  geom_line(alpha = 0.45, linewidth = 0.4) +
  stat_summary(aes(group = cond), fun = mean, geom = "line",
               linewidth = 1.1) +
  scale_colour_manual(values = c(stable = "#2166ac",
                                  `seasonal (amp=0.8)` = "#e41a1c"),
                      name = NULL) +
  labs(title = "Baldwin Effect: BNN prior sigma evolution",
       subtitle = sprintf("4 seeds × 800 ticks. Stable Δ=%+.3f, Seasonal Δ=%+.3f",
                          mean(stab_fin - stab_init),
                          mean(seas_fin - seas_init)),
       x = "Tick", y = "mean_prior_sigma") +
  theme_minimal(base_size = 12)
ggsave("dev/audit/fidelity/figs/baldwin.png", p,
       width = 9, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/baldwin.png\n")
