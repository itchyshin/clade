# Parameter sweep for s-scavenging — DeVault 2003 carrion-benefit
# claim. Failed at 8 seeds at default params (Δmean_energy = +0.05,
# t = 0.05). Hypothesis: default carrion_fraction = 0.5 and
# carrion_eat_gain = 3.0 make carrion too marginal relative to
# grass foraging. Sweep both up + lower grass to stress-test.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L)

base <- default_specs()
base$n_agents_init         <- 100L
base$max_agents            <- 400L
base$grid_rows             <- 30L
base$grid_cols             <- 30L
base$max_ticks             <- 400L
base$carrion_decay_rate    <- 0.1

# 2 × 3 × 2 × 8 = 96 specs: scavenging on/off, carrion_eat_gain
# swept, grass_rate swept
specs_list <- grid_specs(
  base,
  scavenging         = c(TRUE, FALSE),
  carrion_eat_gain   = c(3.0, 8.0, 15.0),
  grass_rate         = c(0.05, 0.10),
  carrion_fraction   = c(0.5, 1.0),
  random_seed        = SEEDS
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
    scavenging        = s$scavenging,
    eat_gain          = s$carrion_eat_gain,
    grass_rate        = s$grass_rate,
    carrion_fraction  = s$carrion_fraction,
    seed              = s$random_seed,
    energy_last100    = mean(tail(d$mean_energy, 100L), na.rm = TRUE),
    n_final           = tail(d$n_agents, 1L),
    viability         = vr$verdict
  )
})
summary_tbl <- do.call(rbind, rows)
saveRDS(summary_tbl, "dev/audit/fidelity/scavenging_strength_sweep.rds")

message("\n── ON vs OFF per cell (Δmean_energy last 100) ──")
for (gr in c(0.05, 0.10)) {
  for (eg in c(3.0, 8.0, 15.0)) {
    for (cf in c(0.5, 1.0)) {
      cell <- summary_tbl[
        summary_tbl$grass_rate == gr &
        summary_tbl$eat_gain   == eg &
        summary_tbl$carrion_fraction == cf, ]
      on  <- cell$energy_last100[cell$scavenging == TRUE]
      off <- cell$energy_last100[cell$scavenging == FALSE]
      delta <- mean(on) - mean(off)
      se    <- sqrt(sd(on)^2 / length(on) + sd(off)^2 / length(off))
      t_val <- delta / se
      verdict <- if (abs(t_val) >= 2) "PASS" else "recheck"
      message(sprintf(
        "  grass=%.2f cf=%.1f eg=%4.1f | Δ=%+6.2f | t=%5.2f | %s",
        gr, cf, eg, delta, t_val, verdict
      ))
    }
  }
}
