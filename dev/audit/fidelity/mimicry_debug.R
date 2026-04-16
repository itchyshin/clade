#!/usr/bin/env Rscript
# Debug: check if predators are actually attacking prey, and whether
# the mimicry counters are wired up.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
})

s <- default_specs()
s$mimicry                <- TRUE
s$toxicity_init_mean     <- 0.5
s$toxin_dose             <- 60
s$toxicity_cost_per_tick <- 0.2
s$signal_memory_rate     <- 0.3
s$avoid_threshold        <- 0.3
s$n_predators_init       <- 15L
s$predator_attack_strength <- 60
s$predator_min_repro_energy <- 50
s$predator_max_agents    <- 50L
s$n_agents_init          <- 100L
s$grid_rows              <- 30L
s$grid_cols              <- 30L
s$grass_rate             <- 0.20
s$max_ticks              <- 400L
s$random_seed            <- 1L

env <- run_alife(s, verbose = FALSE)
d <- get_run_data(env)$ticks
cat("Columns in tick data:\n")
print(names(d))
cat("\nFinal row:\n")
print(d[nrow(d), ])

# Did anything change?
cat("\nKey series ranges:\n")
for (col in c("n_agents", "n_predators", "n_births", "mean_toxicity",
              "n_toxic_attacks", "n_avoided_attacks")) {
  if (col %in% names(d)) {
    cat(sprintf("  %-22s min=%7.2f max=%7.2f final=%7.2f\n",
                col, min(d[[col]], na.rm = TRUE),
                max(d[[col]], na.rm = TRUE),
                tail(d[[col]], 1L)))
  } else {
    cat(sprintf("  %-22s NOT IN DATA\n", col))
  }
}

# Toxicity range
cat(sprintf("\nMean toxicity over time: t0=%.3f  t100=%.3f  t200=%.3f  tend=%.3f\n",
            d$mean_toxicity[1], d$mean_toxicity[100],
            d$mean_toxicity[200], tail(d$mean_toxicity, 1L)))

cat("\nCumulative counters (sum over all 400 ticks):\n")
for (col in c("n_births", "n_deaths", "n_prey_killed",
              "n_toxic_attacks", "n_avoided_attacks", "n_starvations")) {
  if (col %in% names(d)) {
    cat(sprintf("  total %-22s = %d\n", col, sum(d[[col]], na.rm = TRUE)))
  }
}

cat(sprintf("\nGiven %d predators saturated at cap=50, sum(n_prey_killed) = %d\n",
            tail(d$n_predators, 1L), sum(d$n_prey_killed, na.rm = TRUE)))
cat(sprintf("Toxicity attack rate per tick: %.2f (= %d / 400 ticks)\n",
            sum(d$n_toxic_attacks, na.rm = TRUE) / 400,
            sum(d$n_toxic_attacks, na.rm = TRUE)))
