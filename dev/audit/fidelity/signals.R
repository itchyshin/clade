#!/usr/bin/env Rscript
# Fidelity audit: signals, mate choice, sexual selection.
#
# Theory:
#   Zahavi (1975) handicap: signals are costly (energetic drain);
#     high-quality individuals afford elaborate signals; signal
#     magnitude should positively correlate with condition (energy).
#   Fisher (1930) runaway: preference-signal genetic correlation
#     drives both to high values; can decouple signal from condition.
#
# Predictions:
#   P1. With signal_dims > 0 and drift enabled, mean_signal_magnitude
#       rises above 0 over evolutionary time.
#   P2. With mate_choice_mode = "preference", signal elaboration is
#       faster than "random".
#   P3. Signal cost matters: zero-cost allows runaway, high cost
#       suppresses elaboration (breaks population).
#   P4. Signal-energy correlation: Zahavi predicts positive; Fisher
#       allows decoupling. Test sign and magnitude across regimes.
#
# alifeR R prototype reference: alifeR/R/signals.R — same mechanics
#   (cost per tick, multi-dim vector, preference-based mate choice).
# MATLAB base reference: N/A — signals first appear in alifeR.
#
# Usage: Rscript dev/audit/fidelity/signals.R

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
  library(ggplot2)
  library(patchwork)
})

one_run <- function(signal_dims, signal_cost, mate_mode, seed,
                    max_ticks = 500L) {
  s <- default_specs()
  s$signal_dims            <- as.integer(signal_dims)
  s$signal_cost            <- signal_cost
  s$signal_evolution_drift <- TRUE
  s$signal_drift_sd        <- 0.05
  s$mate_choice_mode       <- mate_mode
  s$mate_choice_strength   <- 0.7
  s$n_agents_init          <- 120L
  s$grid_rows              <- 30L
  s$grid_cols              <- 30L
  s$grass_rate             <- 0.15
  s$max_ticks              <- as.integer(max_ticks)
  s$random_seed            <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$signal_cost <- signal_cost
  d$mate_mode <- mate_mode
  d$signal_dims <- signal_dims
  d$seed <- seed
  d
}

# ── Step 1: control (dims=0) vs treatment (dims=3 w/ mate choice) ───────────

seeds <- 1L:5L
cat("── Step 1: signals off vs on (dims=3, preference, cost=0.05)\n")
ctrl <- lapply(seeds, function(sd) {
  d <- one_run(0, 0.05, "random", sd)
  d$cond <- "off"; d
})
trt <- lapply(seeds, function(sd) {
  d <- one_run(3, 0.05, "preference", sd)
  d$cond <- "on_pref"; d
})
fin_signal <- function(runs) {
  vapply(runs, function(d) tail(d$mean_signal_magnitude, 1L), numeric(1L))
}
fin_energy <- function(runs) {
  vapply(runs, function(d) tail(d$mean_energy, 1L), numeric(1L))
}
fin_pop <- function(runs) {
  vapply(runs, function(d) tail(d$n_agents, 1L), numeric(1L))
}

ctrl_sig <- fin_signal(ctrl); trt_sig <- fin_signal(trt)
ctrl_e <- fin_energy(ctrl); trt_e <- fin_energy(trt)
ctrl_n <- fin_pop(ctrl); trt_n <- fin_pop(trt)

cat(sprintf("  off:      final signal=%.3f final_energy=%.1f final_n=%.0f\n",
            mean(ctrl_sig), mean(ctrl_e), mean(ctrl_n)))
cat(sprintf("  on_pref:  final signal=%.3f final_energy=%.1f final_n=%.0f\n",
            mean(trt_sig), mean(trt_e), mean(trt_n)))
p1_pass <- mean(trt_sig) > 0.01
cat(sprintf("  P1 (signal > 0 when on): %s\n", if (p1_pass) "PASS" else "FAIL"))

# ── Step 2: random vs preference mate choice at matched signal_dims ─────────

cat("\n── Step 2: mate choice mode (dims=3, cost=0.05)\n")
rand <- lapply(seeds, function(sd) {
  d <- one_run(3, 0.05, "random", sd); d$cond <- "on_random"; d
})
rand_sig <- fin_signal(rand)
cat(sprintf("  random:     final signal=%.3f\n", mean(rand_sig)))
cat(sprintf("  preference: final signal=%.3f\n", mean(trt_sig)))
p2_pass <- mean(trt_sig) > mean(rand_sig)
cat(sprintf("  P2 (preference > random): %s (ratio=%.2f)\n",
            if (p2_pass) "PASS" else "FAIL",
            mean(trt_sig) / pmax(mean(rand_sig), 0.001)))

# ── Step 3: cost sweep ──────────────────────────────────────────────────────

cat("\n── Step 3: signal_cost sweep (dims=3, preference)\n")
cost_grid <- c(0.0, 0.02, 0.05, 0.10, 0.20)
cost_results <- lapply(cost_grid, function(cc) {
  runs <- lapply(1L:3L, function(sd) one_run(3, cc, "preference", sd))
  finals <- fin_signal(runs); pops <- fin_pop(runs)
  cat(sprintf("  cost=%.2f: signal=%.3f ± %.3f, n=%.0f ± %.0f\n",
              cc, mean(finals), sd(finals),
              mean(pops), sd(pops)))
  data.frame(signal_cost = cc,
             mean_signal = mean(finals),
             mean_pop = mean(pops),
             sd_signal = sd(finals))
})
cost_df <- do.call(rbind, cost_results)

# ── Step 4: honesty check — signal vs energy correlation ────────────────────

cat("\n── Step 4: signal-energy correlation in treatment run (Zahavi check)\n")
# Use the 'on_pref' treatment data, compute within-run correlation per seed
honesty_rhos <- vapply(trt, function(d) {
  d2 <- d[d$t > 100 & !is.na(d$mean_signal_magnitude), ]
  if (nrow(d2) < 10L) return(NA_real_)
  suppressWarnings(cor(d2$mean_energy, d2$mean_signal_magnitude,
                       method = "spearman"))
}, numeric(1L))
cat(sprintf("  Spearman(energy, signal) across %d seeds: %.3f ± %.3f\n",
            length(honesty_rhos),
            mean(honesty_rhos, na.rm = TRUE),
            sd(honesty_rhos, na.rm = TRUE)))
# Positive = consistent with Zahavi; negative = inconsistent; 0 = decoupled
p4_direction <- if (mean(honesty_rhos, na.rm = TRUE) > 0.1) {
  "Zahavi-consistent (positive)"
} else if (mean(honesty_rhos, na.rm = TRUE) < -0.1) {
  "Anti-Zahavi (negative)"
} else {
  "Decoupled (weak correlation) — Fisher-runaway-consistent"
}
cat(sprintf("  P4 direction: %s\n", p4_direction))

# ── Save results + figure ───────────────────────────────────────────────────

all_ticks <- do.call(rbind, c(ctrl, trt, rand))
saveRDS(list(all_ticks = all_ticks, cost_df = cost_df,
             honesty_rhos = honesty_rhos),
        "dev/audit/fidelity/signals_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)

p_traj <- ggplot(all_ticks,
                 aes(t, mean_signal_magnitude, colour = cond,
                     group = interaction(cond, seed))) +
  geom_line(alpha = 0.4, linewidth = 0.4) +
  stat_summary(aes(group = cond), fun = mean, geom = "line",
               linewidth = 1.1) +
  scale_colour_manual(values = c(off = "#999999",
                                  on_random = "#F44336",
                                  on_pref = "#2196F3"),
                      name = NULL) +
  labs(title = "Signal magnitude evolution by condition (5 seeds)",
       x = "Tick", y = "mean_signal_magnitude") +
  theme_minimal(base_size = 11)

p_cost <- ggplot(cost_df, aes(signal_cost, mean_signal)) +
  geom_errorbar(aes(ymin = mean_signal - sd_signal,
                    ymax = mean_signal + sd_signal),
                width = 0.005, colour = "grey50") +
  geom_line(linewidth = 0.8, colour = "#9C27B0") +
  geom_point(size = 3, colour = "#9C27B0") +
  labs(title = "Dose-response: signal_cost vs equilibrium signal",
       x = "signal_cost", y = "final mean_signal_magnitude") +
  theme_minimal(base_size = 11)

p_pop <- ggplot(cost_df, aes(signal_cost, mean_pop)) +
  geom_line(linewidth = 0.8, colour = "#F44336") +
  geom_point(size = 3, colour = "#F44336") +
  labs(title = "Population cost of signalling",
       x = "signal_cost", y = "final n_agents") +
  theme_minimal(base_size = 11)

p <- p_traj / (p_cost | p_pop) +
  plot_annotation(
    title = "Signals fidelity audit: Zahavi handicap and mate choice",
    subtitle = sprintf(
      "5 seeds, 500 ticks, 30x30. Honesty: rho(energy, signal) = %.2f [%s]",
      mean(honesty_rhos, na.rm = TRUE), p4_direction),
    theme = theme(plot.title = element_text(face = "bold"))
  )

ggsave("dev/audit/fidelity/figs/signals.png", p,
       width = 12, height = 8, dpi = 150)
cat("\nWrote dev/audit/fidelity/figs/signals.png\n")
