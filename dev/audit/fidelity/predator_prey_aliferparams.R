#!/usr/bin/env Rscript
# Test alifeR prototype parameters in clade kernel.
# Question: does alifeR's working predator-prey regime still oscillate here?

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
})

one_run <- function(seed) {
  s <- default_specs()
  s$grid_rows                 <- 35L
  s$grid_cols                 <- 35L
  s$n_agents_init             <- 60L
  s$n_predators_init          <- 6L
  s$max_agents                <- 2000L
  s$predator_max_agents       <- 800L
  s$max_ticks                 <- 800L
  s$predator_energy_init      <- 40.0
  s$predator_live_energy      <- 0.2
  s$predator_move_energy      <- 0.2
  s$predator_energy_gain      <- 40.0
  s$predator_attack_strength  <- 15.0
  s$predator_min_repro_energy <- 30.0
  s$predator_min_repro_age    <- 8L
  s$random_seed               <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  get_run_data(env)$ticks
}

osc_score <- function(x, burn = 200L, lag_range = 20L:150L) {
  x <- x[seq.int(burn + 1L, length(x))]
  if (length(x) < max(lag_range) + 10L) return(NA_real_)
  if (sd(x) < 1) return(0)
  ac <- stats::acf(x, lag.max = max(lag_range), plot = FALSE)$acf[-1L]
  m <- min(ac[lag_range]); if (is.na(m) || m >= 0) return(0)
  -m
}

seeds <- 1L:5L
cat(sprintf("Running %d seeds, 800 ticks each, 35x35 grid...\n", length(seeds)))
t0 <- Sys.time()
runs <- lapply(seeds, function(sd) {
  cat(sprintf("  seed %d...\n", sd))
  d <- one_run(sd); d$seed <- sd; d
})
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
cat(sprintf("Done in %.1f s.\n\n", elapsed))

cat("Per-seed summary:\n")
cat(sprintf("%-5s %-10s %-10s %-10s %-10s %-10s %-10s\n",
            "seed", "prey_min", "prey_max", "pred_min", "pred_max",
            "prey_osc", "pred_osc"))
for (r in runs) {
  prey <- r$n_agents; pred <- r$n_predators
  cat(sprintf("%-5d %-10d %-10d %-10d %-10d %-10.3f %-10.3f\n",
              r$seed[1], min(prey), max(prey), min(pred), max(pred),
              osc_score(prey), osc_score(pred)))
}

all_ticks <- do.call(rbind, runs)
saveRDS(all_ticks, "dev/audit/fidelity/predator_prey_aliferparams.rds")
cat("\nWrote dev/audit/fidelity/predator_prey_aliferparams.rds\n")
