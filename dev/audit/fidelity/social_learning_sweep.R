# Parameter sweep for s-social-learning — Boyd & Richerson 1985
# claim. Failed at 8 seeds at defaults (Δmean_energy = -2.2, t =
# -1.14, direction weakly wrong). Hypothesis: default
# social_learning_freq = 20 too aggressive (copies before neighbour's
# behaviour has settled). Also needs high agent density for
# copying events to fire.
#
# Sweep: social_learning_freq (5, 20, 50) × n_agents_init (80, 150,
# 250) × on/off × 8 seeds.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L)

base <- default_specs()
base$grid_rows  <- 20L
base$grid_cols  <- 20L
base$grass_rate <- 0.15
base$max_ticks  <- 400L

# 2 × 3 × 3 × 8 = 144 specs
specs_list <- grid_specs(
  base,
  social_learning      = c(TRUE, FALSE),
  social_learning_freq = c(5L, 20L, 50L),
  n_agents_init        = c(80L, 150L, 250L),
  random_seed          = SEEDS
)
message(sprintf("Built %d specs", length(specs_list)))

t0 <- Sys.time()
results <- batch_alife(specs_list, n_cores = 48L)
message(sprintf("  batch: %.1f min", as.numeric(difftime(Sys.time(), t0, units = "mins"))))

rows <- lapply(seq_along(results), function(i) {
  env <- results[[i]]; s <- specs_list[[i]]
  d <- get_run_data(env)$ticks
  vr <- viability_report(d, n_agents_init = s$n_agents_init)
  data.frame(
    social_learning = s$social_learning,
    freq            = s$social_learning_freq,
    n_init          = s$n_agents_init,
    seed            = s$random_seed,
    energy_last100  = mean(tail(d$mean_energy, 100L), na.rm = TRUE),
    n_final         = tail(d$n_agents, 1L),
    viability       = vr$verdict
  )
})
summary_tbl <- do.call(rbind, rows)
saveRDS(summary_tbl, "dev/audit/fidelity/social_learning_sweep.rds")

message("\n── ON vs OFF per (freq, n_init) cell ──")
for (f in c(5L, 20L, 50L)) {
  for (n in c(80L, 150L, 250L)) {
    cell <- summary_tbl[summary_tbl$freq == f & summary_tbl$n_init == n, ]
    on  <- cell$energy_last100[cell$social_learning == TRUE]
    off <- cell$energy_last100[cell$social_learning == FALSE]
    delta <- mean(on) - mean(off)
    se    <- sqrt(sd(on)^2 / length(on) + sd(off)^2 / length(off))
    t_val <- delta / se
    verdict <- if (abs(t_val) >= 2) "PASS" else "recheck"
    message(sprintf(
      "  freq=%2d n_init=%3d | on=%5.1f off=%5.1f | Δ=%+5.2f | t=%5.2f | %s",
      f, n, mean(on), mean(off), delta, t_val, verdict
    ))
  }
}
