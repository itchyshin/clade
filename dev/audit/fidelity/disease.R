#!/usr/bin/env Rscript
# Fidelity audit: SIR epidemic dynamics.
#
# Theory:
#   Kermack & McKendrick (1927) SIR model: dS/dt = -βSI,
#   dI/dt = βSI - γI, dR/dt = γI. Epidemic fires when R0 > 1.
#
# Predictions:
#   P1. With disease ON and transmission > threshold, epidemic fires
#       (peak n_infected > seed count).
#   P2. Peak scales with transmission_prob (monotone).
#   P3. Very low transmission (below threshold) → epidemic dies out.
#   P4. Classic SIR shape: bell-shaped n_infected curve (single peak
#       then decay, not plateau).
#
# MATLAB: N/A. alifeR: disease.R.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
  library(ggplot2)
  library(patchwork)
})

one_run <- function(transmission_prob, seed, seed_prob = 0.05,
                    max_ticks = 300L) {
  s <- default_specs()
  s$disease           <- TRUE
  s$transmission_prob <- transmission_prob
  s$disease_seed_prob <- seed_prob
  s$disease_energy_cost <- 5.0
  s$disease_duration  <- 10L
  s$immune_duration   <- 20L
  s$disease_death_prob <- 0.01
  s$n_agents_init     <- 120L
  s$grid_rows         <- 30L
  s$grid_cols         <- 30L
  s$grass_rate        <- 0.15
  s$max_ticks         <- as.integer(max_ticks)
  s$random_seed       <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$transmission_prob <- transmission_prob
  d$seed <- seed
  d
}

# ── Step 1: default transmission, 5 seeds ──────────────────────────────────

seeds <- 1L:5L
cat("── Step 1: default transmission_prob = 0.20, 5 seeds\n")
runs <- lapply(seeds, function(sd) {
  cat(sprintf("  seed %d\n", sd))
  one_run(0.20, sd)
})
peaks <- vapply(runs, function(d) max(d$n_infected, na.rm = TRUE),
                numeric(1L))
totals <- vapply(runs, function(d) sum(d$n_new_infections, na.rm = TRUE),
                 numeric(1L))
peak_times <- vapply(runs, function(d) d$t[which.max(d$n_infected)],
                     numeric(1L))

cat(sprintf("  Peak infected:      %.1f ± %.1f (at tick %.1f ± %.1f)\n",
            mean(peaks), sd(peaks),
            mean(peak_times), sd(peak_times)))
cat(sprintf("  Total new infects:  %.1f ± %.1f\n",
            mean(totals), sd(totals)))
p1_pass <- mean(peaks) > 5
cat(sprintf("  P1 (epidemic fires): %s\n",
            if (p1_pass) "PASS" else "FAIL"))

# Bell-shape check: peak then decline
bell_pass <- mean(vapply(runs, function(d) {
  pt <- which.max(d$n_infected)
  if (pt < 5 || pt > nrow(d) - 20) return(FALSE)
  # Decline after peak?
  d$n_infected[pt + 20] < d$n_infected[pt] * 0.5
}, logical(1L))) > 0.6
cat(sprintf("  P4 (bell-shaped epidemic): %s\n",
            if (bell_pass) "PASS" else "FAIL"))

# ── Step 2: transmission sweep ──────────────────────────────────────────────

cat("\n── Step 2: transmission_prob sweep (3 seeds each)\n")
tr_grid <- c(0.02, 0.05, 0.10, 0.20, 0.40, 0.60)
tr_results <- lapply(tr_grid, function(tp) {
  pks <- vapply(1L:3L, function(sd) {
    d <- one_run(tp, sd)
    max(d$n_infected, na.rm = TRUE)
  }, numeric(1L))
  tots <- vapply(1L:3L, function(sd) {
    d <- one_run(tp, sd)
    sum(d$n_new_infections, na.rm = TRUE)
  }, numeric(1L))
  cat(sprintf("  transmission=%.2f: peak=%.1f±%.1f, total=%.1f±%.1f\n",
              tp, mean(pks), sd(pks), mean(tots), sd(tots)))
  data.frame(transmission_prob = tp,
             mean_peak = mean(pks), sd_peak = sd(pks),
             mean_total = mean(tots))
})
tr_df <- do.call(rbind, tr_results)
spear <- cor(tr_df$transmission_prob, tr_df$mean_peak, method = "spearman")
cat(sprintf("  P2 (Spearman transmission vs peak rho = %.2f): %s\n",
            spear, if (spear > 0.5) "PASS" else "FAIL"))

# Save + figure
all_ticks <- do.call(rbind, runs)
saveRDS(list(all_ticks = all_ticks, tr_df = tr_df,
             peaks = peaks, totals = totals, peak_times = peak_times),
        "dev/audit/fidelity/disease_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)

p_traj <- ggplot(all_ticks, aes(t, n_infected, group = seed)) +
  geom_line(alpha = 0.45, colour = "#C62828", linewidth = 0.4) +
  stat_summary(aes(group = 1), fun = mean, geom = "line",
               colour = "#C62828", linewidth = 1.1) +
  labs(title = "Epidemic curve: 5 seeds (bold = mean)",
       x = "Tick", y = "n_infected") +
  theme_minimal(base_size = 11)

p_pop <- ggplot(all_ticks, aes(t, n_agents, group = seed)) +
  geom_line(alpha = 0.45, colour = "#1976D2", linewidth = 0.4) +
  stat_summary(aes(group = 1), fun = mean, geom = "line",
               colour = "#1976D2", linewidth = 1.1) +
  labs(title = "Population during epidemic",
       x = "Tick", y = "n_agents") +
  theme_minimal(base_size = 11)

p_tr <- ggplot(tr_df, aes(transmission_prob, mean_peak)) +
  geom_errorbar(aes(ymin = mean_peak - sd_peak,
                    ymax = mean_peak + sd_peak),
                width = 0.02, colour = "grey50") +
  geom_line(linewidth = 0.8, colour = "#E53935") +
  geom_point(size = 3, colour = "#E53935") +
  labs(title = "Dose-response: transmission_prob vs epidemic peak",
       x = "transmission_prob", y = "peak n_infected") +
  theme_minimal(base_size = 11)

p <- (p_traj | p_pop) / p_tr +
  plot_annotation(
    title = "SIR disease fidelity audit (Kermack-McKendrick 1927)",
    subtitle = sprintf(
      "5 seeds @ default, 3 seeds x 6 transmission levels. Peak=%.1f at t=%.0f",
      mean(peaks), mean(peak_times)),
    theme = theme(plot.title = element_text(face = "bold"))
  )

ggsave("dev/audit/fidelity/figs/disease.png", p,
       width = 12, height = 8, dpi = 150)
cat("\nWrote dev/audit/fidelity/figs/disease.png\n")
