# Fidelity audit for scenario: predator-prey dynamics.
#
# The vignette's "Expected output" promises Lotka-Volterra-style
# oscillations with predator peaks lagging prey peaks by ~30 ticks, but
# the vignette's own "What we found" prose already admits the default
# parameters produce stable coexistence without oscillations. This
# script (1) grid-searches a modest parameter subspace for a regime
# that DOES produce oscillations, (2) multi-seed verifies the winner,
# (3) writes the verified figure.
#
# Usage:  Rscript dev/audit/fidelity/predator_prey.R
# Output:
#   dev/audit/fidelity/figs/predator_prey.png
#   dev/audit/fidelity/predator_prey_results.rds (grid + multi-seed runs)
#
# Primary source:
#   Lotka, A.J. (1925) Elements of Physical Biology.
#   Volterra, V. (1926) Fluctuations in the abundance of a species
#     considered mathematically. Nature 118: 558-560.
#   Huffaker, C.B. (1958) Experimental studies on predation: dispersion
#     factors and predator-prey oscillations. Hilgardia 27: 343-383.
#   Comins, H.N. & Hassell, M.P. (1996) Persistence of multispecies
#     host-parasitoid interactions in spatially distributed models.
#     J. Theor. Biol. 183: 19-28.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
  library(ggplot2)
  library(patchwork)
})

# ── Scoring: oscillation strength in a prey time series ──────────────────────

#' Oscillation score: how far prey's autocorrelation dips below zero.
#' @param prey Numeric vector of prey population over ticks.
#' @param burn Integer burn-in ticks to drop.
#' @param lag_range Integer vector of lags to search for negative ACF.
#' @return Numeric: 0 if no dip below zero; otherwise magnitude of the most
#'   negative ACF value in the lag range (a valid LV oscillation gives
#'   ACF < 0 at lag ~period/2).
oscillation_score <- function(prey, burn = 100L, lag_range = 20L:100L) {
  x <- prey[seq.int(burn + 1L, length(prey))]
  if (length(x) < max(lag_range) + 10L) return(NA_real_)
  if (sd(x) < 1)                         return(0)
  ac <- stats::acf(x, lag.max = max(lag_range), plot = FALSE)$acf[-1L]
  min_ac_in_range <- min(ac[lag_range])
  if (is.na(min_ac_in_range) || min_ac_in_range >= 0) return(0)
  -min_ac_in_range
}

# ── One run ───────────────────────────────────────────────────────────────────

.one <- function(predator_energy_gain,
                 predator_min_repro_energy,
                 n_predators_init,
                 grass_rate,
                 seed,
                 max_ticks = 800L) {
  s <- default_specs()
  s$n_agents_init             <- 100L
  s$grid_rows                 <- 30L
  s$grid_cols                 <- 30L
  s$n_predators_init          <- as.integer(n_predators_init)
  s$predator_energy_gain      <- predator_energy_gain
  s$predator_min_repro_energy <- predator_min_repro_energy
  s$grass_rate                <- grass_rate
  s$max_ticks                 <- as.integer(max_ticks)
  s$random_seed               <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  list(
    ticks = d,
    score = oscillation_score(d$n_agents),
    final_prey     = tail(d$n_agents, 1L),
    final_predator = tail(d$n_predators, 1L),
    max_prey       = max(d$n_agents, na.rm = TRUE),
    max_predator   = max(d$n_predators, na.rm = TRUE)
  )
}

# ── Grid search ──────────────────────────────────────────────────────────────

grid <- expand.grid(
  predator_energy_gain      = c(30, 60, 90),
  predator_min_repro_energy = c(50, 100, 200),
  n_predators_init          = c(3L, 5L, 10L),
  grass_rate                = c(0.10, 0.20),
  KEEP.OUT.ATTRS = FALSE
)

message(sprintf("Grid search: %d combos x 3 seeds = %d runs",
                nrow(grid), 3L * nrow(grid)))

t0 <- Sys.time()
grid_results <- lapply(seq_len(nrow(grid)), function(i) {
  row <- grid[i, ]
  message(sprintf("  [%d/%d] gain=%.0f repro=%.0f n_pred=%d grass=%.2f",
                  i, nrow(grid),
                  row$predator_energy_gain, row$predator_min_repro_energy,
                  row$n_predators_init, row$grass_rate))
  scores <- sapply(1L:3L, function(sd) {
    res <- try(.one(row$predator_energy_gain,
                    row$predator_min_repro_energy,
                    row$n_predators_init,
                    row$grass_rate,
                    sd),
               silent = TRUE)
    if (inherits(res, "try-error")) NA_real_ else res$score
  })
  data.frame(row,
             mean_score = mean(scores, na.rm = TRUE),
             sd_score   = sd  (scores, na.rm = TRUE))
})
grid_df <- do.call(rbind, grid_results)
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
message(sprintf("Grid done in %.1f min.", elapsed))

# Rank best regimes
grid_df <- grid_df[order(-grid_df$mean_score), ]
message("\nTop 5 regimes by oscillation score:")
print(head(grid_df, 5L))

saveRDS(grid_df, "dev/audit/fidelity/predator_prey_grid.rds")

# ── Multi-seed verification at best regime ───────────────────────────────────

best <- grid_df[1L, ]
message(sprintf("\nMulti-seed verification at gain=%.0f repro=%.0f n_pred=%d grass=%.2f",
                best$predator_energy_gain, best$predator_min_repro_energy,
                best$n_predators_init, best$grass_rate))

verify_seeds <- 1L:10L
verify_results <- lapply(verify_seeds, function(sd) {
  res <- .one(best$predator_energy_gain,
              best$predator_min_repro_energy,
              best$n_predators_init,
              best$grass_rate,
              sd,
              max_ticks = 1000L)
  res$ticks$seed <- sd
  res
})
all_ticks <- do.call(rbind, lapply(verify_results, `[[`, "ticks"))
scores    <- sapply(verify_results, `[[`, "score")

message(sprintf("Oscillation scores across %d seeds: mean=%.3f  sd=%.3f",
                length(scores), mean(scores), sd(scores)))

saveRDS(list(best = best, verify_results = verify_results,
             all_ticks = all_ticks, scores = scores),
        "dev/audit/fidelity/predator_prey_results.rds")

# ── Figure: 10-seed mean ± SD with one-seed example highlighted ──────────────

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)

p_prey <- ggplot(all_ticks, aes(t, n_agents, group = seed)) +
  geom_line(colour = "#2196F3", alpha = 0.3, linewidth = 0.3) +
  stat_summary(aes(group = 1), fun = mean, geom = "line",
               colour = "#2196F3", linewidth = 1.0) +
  labs(title = "Prey abundance (10 seeds; bold = mean)",
       x = "Tick", y = "n_agents (prey)") +
  theme_minimal(base_size = 11)

p_pred <- ggplot(all_ticks, aes(t, n_predators, group = seed)) +
  geom_line(colour = "#F44336", alpha = 0.3, linewidth = 0.3) +
  stat_summary(aes(group = 1), fun = mean, geom = "line",
               colour = "#F44336", linewidth = 1.0) +
  labs(title = "Predator abundance (10 seeds; bold = mean)",
       x = "Tick", y = "n_predators") +
  theme_minimal(base_size = 11)

p <- p_prey / p_pred + plot_annotation(
  title = sprintf(
    "Predator-prey fidelity audit: calibrated regime (osc. score = %.2f ± %.2f)",
    mean(scores), sd(scores)),
  subtitle = sprintf(
    "gain=%.0f  repro_thresh=%.0f  n_pred_init=%d  grass_rate=%.2f  1000 ticks",
    best$predator_energy_gain, best$predator_min_repro_energy,
    best$n_predators_init, best$grass_rate),
  theme = theme(plot.title = element_text(face = "bold"))
)

ggsave("dev/audit/fidelity/figs/predator_prey.png", p,
       width = 10, height = 7, dpi = 150)
message("Wrote dev/audit/fidelity/figs/predator_prey.png")
