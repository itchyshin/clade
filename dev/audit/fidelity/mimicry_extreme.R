#!/usr/bin/env Rscript
# Push parameters to extreme to see if mimicry dynamics ever activate.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
})

run_one <- function(label, overrides, max_ticks = 600L, seed = 1L) {
  s <- default_specs()
  s$mimicry            <- TRUE
  s$n_predators_init   <- 15L
  s$predator_attack_strength <- 80
  s$predator_min_repro_energy <- 50
  s$predator_max_agents <- 80L
  s$n_agents_init      <- 100L
  s$grid_rows          <- 25L
  s$grid_cols          <- 25L
  s$grass_rate         <- 0.20
  s$max_ticks          <- max_ticks
  s$random_seed        <- seed
  for (k in names(overrides)) s[[k]] <- overrides[[k]]
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  tot_tox <- sum(d$n_toxic_attacks, na.rm = TRUE)
  tot_avoid <- sum(d$n_avoided_attacks, na.rm = TRUE)
  tot_kill <- sum(d$n_prey_killed, na.rm = TRUE)
  cat(sprintf("%-30s init=%.2f t0=%.3f tend=%.3f kills=%d toxic=%d avoid=%d\n",
              label, s$toxicity_init_mean, d$mean_toxicity[1],
              tail(d$mean_toxicity, 1L), tot_kill, tot_tox, tot_avoid))
  invisible(d)
}

cat("Trying regimes designed to maximize toxicity dynamics:\n\n")
run_one("init=1.0 cost=0.1 dose=100",
        list(toxicity_init_mean = 1.0,
             toxicity_cost_per_tick = 0.1,
             toxin_dose = 100,
             avoid_threshold = 0.05))
run_one("init=0.8 cost=0.05 dose=200",
        list(toxicity_init_mean = 0.8,
             toxicity_cost_per_tick = 0.05,
             toxin_dose = 200,
             avoid_threshold = 0.02,
             signal_memory_rate = 0.5))
run_one("init=0.5 lr=0.9 thr=0.01",
        list(toxicity_init_mean = 0.5,
             toxicity_cost_per_tick = 0.1,
             toxin_dose = 100,
             avoid_threshold = 0.01,
             signal_memory_rate = 0.9))
run_one("init=0.0 (must evolve up)",
        list(toxicity_init_mean = 0.0,
             toxicity_cost_per_tick = 0.0,
             toxin_dose = 200,
             avoid_threshold = 0.05))
run_one("default vignette (Calibrated CMA-ES)",
        list(toxicity_init_mean = 0.3,
             toxin_dose = 23,
             toxicity_cost_per_tick = 0.2776,
             signal_memory_rate = 0.2991))
