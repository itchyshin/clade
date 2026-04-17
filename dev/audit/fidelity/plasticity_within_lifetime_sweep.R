# Re-think plasticity audit: the DeWitt & Scheiner prediction is that
# plasticity evolves when agents experience ENVIRONMENTAL CHANGE WITHIN
# A LIFETIME. At fast_specs (max_age = 30) with season_length = 100,
# agents live through only ~1/3 of a seasonal cycle — each agent sees
# essentially one season its whole life, so genetic adaptation to the
# current season is just as good as plasticity. No selection gradient
# for plasticity to evolve on.
#
# Hypothesis: season_length ≤ max_age should recover the signal.
# Sweep season_length ∈ {10, 20, 30, 60, 100} at max_age = 30.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
})

SEEDS   <- c(1L, 7L, 13L, 19L, 25L)
LENGTHS <- c(10L, 20L, 30L, 60L, 100L)

.base <- function(seed) {
  s <- fast_specs()       # max_age = 30
  s$n_agents_init <- 180L
  s$max_agents    <- 800L
  s$grid_rows     <- 40L
  s$grid_cols     <- 40L
  s$grass_rate    <- 0.25
  s$random_seed   <- as.integer(seed)
  s
}

one_run <- function(seasonal_amp, season_length, seed) {
  s <- .base(seed)
  s$phenotypic_plasticity    <- TRUE
  s$plasticity_init_mean     <- 0.3
  s$plasticity_mutation_sd   <- 0.05
  s$bnn_sigma_source         <- "trait"
  s$brain_energy_sigma_scale <- 0.05
  s$seasonal_amplitude       <- seasonal_amp
  s$season_length            <- as.integer(season_length)
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  list(init = d$mean_plasticity[1L],
       final = tail(d$mean_plasticity, 1L),
       n_final = tail(d$n_agents, 1L))
}

t0 <- Sys.time()
message("=== plasticity × season_length sweep (max_age = 30) ===")

res <- data.frame()
for (sl in LENGTHS) {
  for (amp in c(0.0, 0.35)) {
    for (sd in SEEDS) {
      r <- one_run(amp, sl, sd)
      cond <- if (amp > 0) "seasonal" else "stable"
      res <- rbind(res, data.frame(
        season_length = sl, cond = cond, seed = sd,
        init = r$init, final = r$final,
        delta = r$final - r$init, n_final = r$n_final))
      message(sprintf("  sl=%3d amp=%.2f seed=%2d → Δ=%+.3f n=%d",
                      sl, amp, sd, r$final - r$init, r$n_final))
    }
  }
}

message("\n── Summary per season_length ──")
for (sl in LENGTHS) {
  sub  <- res[res$season_length == sl, ]
  stab <- sub[sub$cond == "stable", ]
  seas <- sub[sub$cond == "seasonal", ]
  dd   <- mean(seas$delta) - mean(stab$delta)
  p1   <- mean(seas$final) > mean(stab$final)
  min_n <- min(sub$n_final)
  message(sprintf(
    "  sl=%3d | stable Δ=%+.3f | seasonal Δ=%+.3f | Δdelta=%+.3f | P1 %s | min_n=%d",
    sl, mean(stab$delta), mean(seas$delta), dd,
    if (p1) "PASS" else "FAIL", min_n))
}

saveRDS(res, "dev/audit/fidelity/plasticity_within_lifetime_sweep.rds")
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
message(sprintf("\n=== Done in %.1f min ===", elapsed))
