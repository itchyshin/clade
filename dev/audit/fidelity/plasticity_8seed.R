# 8-seed re-audit of plasticity at season_length = 10 (the promotion
# candidate regime from PR #39). Goal: see if the Δdelta crosses the
# 0.02 threshold with tighter SE at 8 seeds.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L)

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

one_run <- function(amp, seed) {
  s <- .base(seed)
  s$phenotypic_plasticity    <- TRUE
  s$plasticity_init_mean     <- 0.3
  s$plasticity_mutation_sd   <- 0.05
  s$bnn_sigma_source         <- "trait"
  s$brain_energy_sigma_scale <- 0.05
  s$seasonal_amplitude       <- amp
  s$season_length            <- 10L      # within-lifetime variability
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  list(init = d$mean_plasticity[1L],
       final = tail(d$mean_plasticity, 1L),
       n_final = tail(d$n_agents, 1L))
}

t0 <- Sys.time()
message("=== plasticity 8-seed re-audit at sl=10 ===")

res <- data.frame()
for (amp in c(0.0, 0.35)) {      # match sweep execution order
  for (sd in SEEDS) {
    r <- one_run(amp, sd)
    cond <- if (amp > 0) "seasonal" else "stable"
    res <- rbind(res, data.frame(
      cond = cond, seed = sd,
      init = r$init, final = r$final,
      delta = r$final - r$init, n_final = r$n_final))
    message(sprintf("  amp=%.2f seed=%2d → init=%.3f final=%.3f Δ=%+.3f n=%d",
                    amp, sd, r$init, r$final, r$final - r$init, r$n_final))
  }
}

stab <- res[res$cond == "stable", ]
seas <- res[res$cond == "seasonal", ]
ddelta <- mean(seas$delta) - mean(stab$delta)
se_dd  <- sqrt(sd(seas$delta)^2 / length(seas$delta) +
               sd(stab$delta)^2 / length(stab$delta))
p1     <- mean(seas$final) > mean(stab$final)

message("\n── 8-seed summary ──")
message(sprintf("  stable Δ   = %+.4f ± %.4f (sd)",
                mean(stab$delta), sd(stab$delta)))
message(sprintf("  seasonal Δ = %+.4f ± %.4f (sd)",
                mean(seas$delta), sd(seas$delta)))
message(sprintf("  Δdelta     = %+.4f, SE = %.4f, t ≈ %.2f",
                ddelta, se_dd, ddelta / se_dd))
message(sprintf("  P1 direction: %s",
                if (p1) "PASS (seasonal > stable)" else "FAIL"))
message(sprintf("  Promotion:   %s",
                if (abs(ddelta) > 0.02 && p1 && ddelta / se_dd > 2)
                   "✅ CROSSES 0.02 THRESHOLD + 2×SE"
                else if (abs(ddelta) > 0.02 && p1)
                   "crosses 0.02 but within 2×SE"
                else
                   sprintf("still below threshold (Δ=%+.3f)", ddelta)))

saveRDS(res, "dev/audit/fidelity/plasticity_8seed.rds")
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
message(sprintf("\n=== Done in %.1f min ===", elapsed))
