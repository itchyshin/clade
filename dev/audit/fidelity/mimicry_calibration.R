#!/usr/bin/env Rscript
# 0.5.4 mimicry parameter calibration (with 0.5.3 methodology lessons).
#
# Motivation: the 0.4.4 audit confirmed the mimicry kernel machinery is
# theoretically aligned (vector-signal memory + delta-rule RW + aposematic
# pleiotropy, P3/P4 PASS). But Step 1 P2 (treatment > control toxicity
# evolution) remained direction-sensitive at ±0.002 — ecology-limited,
# not kernel-limited. This script searches for an ecological regime
# that produces statistically clean upward toxicity evolution under the
# full 0.4.4 machinery.
#
# Methodology (learned from 0.5.3 Red Queen retraction): use adequate
# seeds with 2×SE hypothesis testing from the start. Don't claim a
# signal from 3–5-seed direction without verification at 16 seeds.
#
# Strategy: 8-cell grid × 5 seeds × 1000 ticks for initial screen;
# top-3 regimes verified at 16 seeds with 2×SE test.
# Target: Δtoxicity > +0.05 with LCL > 0 (2×SE significance).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(n_pred, toxin_dose, toxicity_cost, pleiotropy,
                    toxicity_init, seed, max_ticks = 1000L) {
  s <- default_specs()
  s$mimicry                    <- TRUE
  s$toxicity_init_mean         <- toxicity_init
  s$toxin_dose                 <- toxin_dose
  s$toxicity_cost_per_tick     <- toxicity_cost
  s$signal_dims                <- 3L
  s$signal_evolution_drift     <- TRUE
  s$signal_drift_sd            <- 0.03
  s$signal_memory_rate         <- 0.5
  s$avoid_threshold            <- 0.1
  s$signal_toxicity_coupling   <- pleiotropy
  s$n_predators_init           <- as.integer(n_pred)
  s$predator_attack_strength   <- 60
  s$predator_min_repro_energy  <- 50
  s$predator_max_agents        <- 60L
  s$n_agents_init              <- 100L
  s$grid_rows                  <- 30L
  s$grid_cols                  <- 30L
  s$grass_rate                 <- 0.15
  s$max_agents                 <- 400L
  s$max_ticks                  <- as.integer(max_ticks)
  s$random_seed                <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  p <- env$progress
  list(
    final_tox   = tail(p$mean_toxicity, 1L),
    init_tox    = p$mean_toxicity[1],
    n_toxic     = sum(p$n_toxic_attacks, na.rm = TRUE),
    n_avoided   = sum(p$n_avoided_attacks, na.rm = TRUE),
    final_n     = tail(p$n_agents, 1L)
  )
}

# Focused grid: fix pleiotropy = 1.0 (full honest signal) and vary the
# ecological knobs that determine whether parasite protection offsets
# toxicity cost. 8 cells × 5 seeds × 1000 ticks.
grid <- expand.grid(
  n_pred        = c(12, 20),
  toxin_dose    = c(80, 150),
  toxicity_cost = c(0.1, 0.2),
  pleiotropy    = c(1.0),
  toxicity_init = c(0.3),
  KEEP.OUT.ATTRS = FALSE
)
seeds <- 1L:5L

cat(sprintf("── 0.5.3 mimicry calibration: %d grid cells × %d seeds = %d runs\n",
            nrow(grid), length(seeds), nrow(grid) * length(seeds)))

results <- list()
for (i in seq_len(nrow(grid))) {
  row <- grid[i, ]
  cell <- lapply(seeds, function(sd) {
    one_run(row$n_pred, row$toxin_dose, row$toxicity_cost,
            row$pleiotropy, row$toxicity_init, sd)
  })
  deltas  <- vapply(cell, function(r) r$final_tox - r$init_tox, numeric(1))
  avoids  <- vapply(cell, function(r) r$n_avoided, numeric(1))
  toxics  <- vapply(cell, function(r) r$n_toxic, numeric(1))
  ns      <- vapply(cell, function(r) r$final_n, numeric(1))
  results[[i]] <- data.frame(
    n_pred       = row$n_pred,
    toxin_dose   = row$toxin_dose,
    tox_cost     = row$toxicity_cost,
    pleiotropy   = row$pleiotropy,
    tox_init     = row$toxicity_init,
    delta_mean   = mean(deltas),
    delta_se     = sd(deltas) / sqrt(length(deltas)),
    avoid_mean   = mean(avoids),
    toxic_mean   = mean(toxics),
    n_mean       = mean(ns)
  )
  cat(sprintf("  cell %d/%d: pred=%d dose=%d cost=%.1f pleio=%.1f init=%.1f → Δ=%+.3f±%.3f  avoid=%.0f  n=%.0f\n",
              i, nrow(grid), row$n_pred, row$toxin_dose, row$toxicity_cost,
              row$pleiotropy, row$toxicity_init,
              mean(deltas), sd(deltas) / sqrt(length(deltas)),
              mean(avoids), mean(ns)))
}
summary <- do.call(rbind, results)

cat("\nTop 5 regimes by Δmean (upward toxicity evolution):\n")
print(summary[order(-summary$delta_mean), ][1:5, ])

best <- summary[which.max(summary$delta_mean), ]
cat(sprintf("\nBest regime:\n"))
print(best)

# Hypothesis test: is the best regime's Δ > 0 at 2×SE?
lcl <- best$delta_mean - 2 * best$delta_se
p1_pass <- lcl > 0
p2_pass <- best$delta_mean > 0.05
cat(sprintf("\nP1 (best regime Δ > 0 at 2×SE): %s (LCL = %+.4f)\n",
            if (p1_pass) "PASS" else "FAIL", lcl))
cat(sprintf("P2 (best regime Δ > 0.05 threshold): %s (Δ = %+.4f)\n",
            if (p2_pass) "PASS" else "FAIL", best$delta_mean))

saveRDS(summary, "dev/audit/fidelity/mimicry_calibration_results.rds")
cat("\nSaved dev/audit/fidelity/mimicry_calibration_results.rds\n")
