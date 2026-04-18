# s-scavenging redo with PREDATION as the carrion source.
#
# Yesterday's 192-run sweep found no cell where scavenging ON boosts
# mean_energy. Diagnosis: without predators, carrion comes only from
# starvation/aging — a marginal supply. Under active predation, each
# kill leaves a fresh carcass, so scavenging becomes a meaningful
# foraging channel.
#
# Sweep: scavenging ∈ {TRUE, FALSE} × n_predators_init ∈ {5, 15} ×
# grass_rate ∈ {0.05, 0.10} × carrion_eat_gain ∈ {5, 15} × 8 seeds.
# = 128 runs.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L)

base <- default_specs()
base$n_agents_init       <- 100L
base$max_agents          <- 400L
base$grid_rows           <- 30L
base$grid_cols           <- 30L
base$max_ticks           <- 400L
base$carrion_decay_rate  <- 0.1
base$carrion_fraction    <- 1.0   # full body → carrion (max supply)

specs_list <- grid_specs(
  base,
  scavenging         = c(TRUE, FALSE),
  n_predators_init   = c(5L, 15L),
  grass_rate         = c(0.05, 0.10),
  carrion_eat_gain   = c(5.0, 15.0),
  random_seed        = SEEDS
)
message(sprintf("Built %d specs", length(specs_list)))

t0 <- Sys.time()
results <- batch_alife(specs_list, n_cores = 48L)
message(sprintf("  batch: %.1f min",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))

rows <- lapply(seq_along(results), function(i) {
  env <- results[[i]]; s <- specs_list[[i]]
  d <- get_run_data(env)$ticks
  data.frame(
    scavenging = s$scavenging,
    n_pred     = s$n_predators_init,
    grass      = s$grass_rate,
    eg         = s$carrion_eat_gain,
    seed       = s$random_seed,
    energy_last100 = mean(tail(d$mean_energy, 100L), na.rm = TRUE),
    n_final    = tail(d$n_agents, 1L)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/scavenging_with_predators.rds")

message("\n── ON vs OFF per (n_pred, grass, eg) cell ──")
for (np in c(5L, 15L)) for (gr in c(0.05, 0.10)) for (eg in c(5.0, 15.0)) {
  cell <- tbl[tbl$n_pred == np & tbl$grass == gr & tbl$eg == eg, ]
  on  <- cell$energy_last100[cell$scavenging == TRUE]
  off <- cell$energy_last100[cell$scavenging == FALSE]
  delta <- mean(on) - mean(off)
  se <- sqrt(sd(on)^2 / length(on) + sd(off)^2 / length(off))
  t_val <- delta / se
  message(sprintf(
    "  n_pred=%2d grass=%.2f eg=%4.1f | on=%5.1f off=%5.1f | Δ=%+5.2f | t=%+5.2f | %s",
    np, gr, eg, mean(on), mean(off), delta, t_val,
    if (abs(t_val) >= 2) "PASS" else "recheck"
  ))
}
