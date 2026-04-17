# Parameter sweep for s-plasticity: does a steeper brain_energy_sigma_scale
# recover the DeWitt & Scheiner 2004 signal under v2 calibrated conditions
# (40×40 grid, milder seasonality, no crashes)?
#
# The v2 re-audit (fast_specs_reaudit_v2.R) found Δdelta = +0.002 at the
# default brain_energy_sigma_scale = 0.05. At that scale, plasticity cost
# is 0.05 × sigma ≈ 0.015 energy/tick with sigma = 0.3 — only 1.5% of
# move_cost (1.0). The cost is too small to create a selection gradient
# strong enough to overcome drift at 5-seed sample size.
#
# Hypothesis: ramping the cost scale 10-200× should reveal the DeWitt-
# Scheiner direction. Sweep: scale ∈ {0.05 baseline, 0.5, 2.0, 5.0}.
#
# Usage: Rscript dev/audit/fidelity/plasticity_cost_sweep.R
# Output: dev/audit/fidelity/plasticity_cost_sweep.rds

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L)
SCALES <- c(0.05, 0.5, 2.0, 5.0)

.base <- function(seed) {
  s <- fast_specs()
  s$n_agents_init <- 180L
  s$max_agents    <- 800L
  s$grid_rows     <- 40L
  s$grid_cols     <- 40L
  s$grass_rate    <- 0.25
  s$random_seed   <- as.integer(seed)
  s
}

one_run <- function(seasonal_amp, sigma_scale, seed) {
  s <- .base(seed)
  s$phenotypic_plasticity    <- TRUE
  s$plasticity_init_mean     <- 0.3
  s$plasticity_mutation_sd   <- 0.05
  s$bnn_sigma_source         <- "trait"
  s$brain_energy_sigma_scale <- sigma_scale
  s$seasonal_amplitude       <- seasonal_amp
  s$season_length            <- 100L
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  list(init = d$mean_plasticity[1L],
       final = tail(d$mean_plasticity, 1L),
       n_final = tail(d$n_agents, 1L))
}

t0 <- Sys.time()
message("=== plasticity × brain_energy_sigma_scale sweep ===")

res <- data.frame()
for (scale in SCALES) {
  for (amp in c(0.0, 0.35)) {
    for (sd in SEEDS) {
      r <- one_run(amp, scale, sd)
      cond <- if (amp > 0) "seasonal" else "stable"
      res <- rbind(res, data.frame(scale = scale, cond = cond, seed = sd,
                                    init = r$init, final = r$final,
                                    delta = r$final - r$init,
                                    n_final = r$n_final))
      message(sprintf("  scale=%.2f amp=%.2f seed=%2d → Δ=%+.3f n=%d",
                      scale, amp, sd, r$final - r$init, r$n_final))
    }
  }
}

message("\n── Summary per sigma_scale (mean ± sd across 5 seeds) ──")
for (scale in SCALES) {
  sub <- res[res$scale == scale, ]
  stab  <- sub[sub$cond == "stable", ]
  seas  <- sub[sub$cond == "seasonal", ]
  ddelta <- mean(seas$delta) - mean(stab$delta)
  p1 <- mean(seas$final) > mean(stab$final)
  min_n <- min(sub$n_final)
  message(sprintf(
    "  scale=%.2f | stable Δ=%+.3f | seasonal Δ=%+.3f | Δdelta=%+.3f | P1 %s | min_n=%d",
    scale,
    mean(stab$delta), mean(seas$delta),
    ddelta, if (p1) "PASS" else "FAIL", min_n))
}

saveRDS(res, "dev/audit/fidelity/plasticity_cost_sweep.rds")

elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
message(sprintf("\n=== Done in %.1f min ===", elapsed))
