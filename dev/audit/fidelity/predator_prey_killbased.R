#!/usr/bin/env Rscript
# Predator-prey audit, kill-based energy (preserves clade kernel semantics).
#
# Strategy: the kernel grants predators `energy_gain` only when their attack
# kills a prey on their cell. In alifeR, attack_strength=15 worked because
# energy was granted per attack (not per kill). Here we raise attack_strength
# so single attacks are reliably lethal, which makes the kill-based accounting
# actually couple predator demographics to prey density (true LV).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
})

# ── Step 1: prey energy range from default_specs (for sizing attack_strength) ─

s_peek <- default_specs()
cat(sprintf("── default_specs: energy_init=%.1f, metabolic=%.2f\n",
            s_peek$energy_init, s_peek$metabolic_rate))
cat(sprintf("   attack_strength grid chosen to span single-hit-lethal region\n"))

# ── Step 2: grid search over attack_strength × repro_threshold × grass_rate ─

osc_score <- function(x, burn = 200L, lag_range = 20L:150L) {
  x <- x[seq.int(burn + 1L, length(x))]
  if (length(x) < max(lag_range) + 10L) return(NA_real_)
  if (sd(x) < 1) return(0)
  ac <- stats::acf(x, lag.max = max(lag_range), plot = FALSE)$acf[-1L]
  m <- min(ac[lag_range]); if (is.na(m) || m >= 0) return(0)
  -m
}

one_run <- function(attack_strength, min_repro_energy, grass_rate, seed,
                    max_ticks = 800L) {
  s <- default_specs()
  s$grid_rows                 <- 35L
  s$grid_cols                 <- 35L
  s$n_agents_init             <- 60L
  s$n_predators_init          <- 6L
  s$max_agents                <- 2000L
  s$predator_max_agents       <- 800L
  s$max_ticks                 <- as.integer(max_ticks)
  s$predator_energy_init      <- 40.0
  s$predator_live_energy      <- 0.2
  s$predator_move_energy      <- 0.2
  s$predator_energy_gain      <- 40.0
  s$predator_attack_strength  <- attack_strength
  s$predator_min_repro_energy <- min_repro_energy
  s$predator_min_repro_age    <- 8L
  s$grass_rate                <- grass_rate
  s$random_seed               <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  list(
    ticks = d,
    prey_osc = osc_score(d$n_agents),
    pred_osc = osc_score(d$n_predators),
    prey_min = min(d$n_agents), prey_max = max(d$n_agents),
    pred_min = min(d$n_predators), pred_max = max(d$n_predators),
    final_prey = tail(d$n_agents, 1L),
    final_pred = tail(d$n_predators, 1L)
  )
}

grid <- expand.grid(
  attack_strength  = c(50, 80, 120),
  min_repro_energy = c(30, 60),
  grass_rate       = c(0.10, 0.20),
  KEEP.OUT.ATTRS = FALSE
)

cat(sprintf("\n── Step 2: grid search (%d combos x 3 seeds = %d runs)\n",
            nrow(grid), 3L * nrow(grid)))
t0 <- Sys.time()
res <- lapply(seq_len(nrow(grid)), function(i) {
  row <- grid[i, ]
  cat(sprintf("  [%2d/%d] attack=%3.0f repro=%3.0f grass=%.2f",
              i, nrow(grid), row$attack_strength, row$min_repro_energy, row$grass_rate))
  seeds <- 1L:3L
  rs <- lapply(seeds, function(sd) {
    try(one_run(row$attack_strength, row$min_repro_energy, row$grass_rate, sd),
        silent = TRUE)
  })
  ok <- !vapply(rs, inherits, logical(1L), "try-error")
  if (!any(ok)) { cat(" ALL FAILED\n"); return(NULL) }
  rs <- rs[ok]
  prey_osc <- mean(vapply(rs, `[[`, numeric(1L), "prey_osc"), na.rm = TRUE)
  pred_osc <- mean(vapply(rs, `[[`, numeric(1L), "pred_osc"), na.rm = TRUE)
  pred_range <- mean(vapply(rs, function(r) r$pred_max - r$pred_min, numeric(1L)))
  cat(sprintf("  prey_osc=%.3f pred_osc=%.3f pred_range=%.0f\n",
              prey_osc, pred_osc, pred_range))
  data.frame(row,
             prey_osc  = prey_osc,
             pred_osc  = pred_osc,
             pred_range = pred_range,
             n_seeds   = length(rs))
})
grid_df <- do.call(rbind, res)
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
cat(sprintf("\nGrid done in %.1f min.\n", elapsed))

# Rank by joint oscillation (want both prey AND pred oscillating)
grid_df$joint_score <- grid_df$prey_osc * grid_df$pred_osc
grid_df <- grid_df[order(-grid_df$joint_score), ]
cat("\nTop 5 regimes by JOINT oscillation (prey_osc * pred_osc):\n")
print(head(grid_df, 5L))

cat("\nTop 5 regimes by PRED oscillation only:\n")
grid_df2 <- grid_df[order(-grid_df$pred_osc), ]
print(head(grid_df2, 5L))

saveRDS(grid_df, "dev/audit/fidelity/predator_prey_killbased_grid.rds")
cat("\nWrote dev/audit/fidelity/predator_prey_killbased_grid.rds\n")
