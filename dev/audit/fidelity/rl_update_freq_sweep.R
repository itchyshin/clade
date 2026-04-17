# Parameter sweep for s-rl — Williams 1992 REINFORCE claim that
# actor-critic within-life learning boosts mean_energy relative to
# non-learning baseline. 8-seed default check failed (Δ = -2.5,
# t = -1.66). Same pattern as social_learning suggests aggressive
# `rl_update_freq = 5` is too frequent — updates before advantage
# signal stabilises inject noise.
#
# Sweep: rl_update_freq × learning_rate_init_mean × on/off × 8 seeds.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L)

base <- default_specs()
base$n_agents_init <- 80L
base$max_agents    <- 400L
base$grid_rows     <- 30L
base$grid_cols     <- 30L
base$grass_rate    <- 0.15
base$max_ticks     <- 400L

# 2 × 3 × 3 × 8 = 144 specs
specs_list <- grid_specs(
  base,
  rl_mode                 = c("actor_critic", "none"),
  rl_update_freq          = c(5L, 20L, 50L),
  learning_rate_init_mean = c(0.005, 0.01, 0.05),
  random_seed             = SEEDS
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
    rl_mode        = s$rl_mode,
    freq           = s$rl_update_freq,
    lr             = s$learning_rate_init_mean,
    seed           = s$random_seed,
    energy_last100 = mean(tail(d$mean_energy, 100L), na.rm = TRUE),
    n_final        = tail(d$n_agents, 1L),
    viability      = vr$verdict
  )
})
summary_tbl <- do.call(rbind, rows)
saveRDS(summary_tbl, "dev/audit/fidelity/rl_update_freq_sweep.rds")

message("\n── actor_critic vs none per (freq, lr) cell ──")
for (f in c(5L, 20L, 50L)) {
  for (lr in c(0.005, 0.01, 0.05)) {
    cell <- summary_tbl[summary_tbl$freq == f &
                          summary_tbl$lr == lr, ]
    on  <- cell$energy_last100[cell$rl_mode == "actor_critic"]
    off <- cell$energy_last100[cell$rl_mode == "none"]
    delta <- mean(on) - mean(off)
    se    <- sqrt(sd(on)^2 / length(on) + sd(off)^2 / length(off))
    t_val <- delta / se
    verdict <- if (abs(t_val) >= 2) "PASS" else "recheck"
    message(sprintf(
      "  freq=%2d lr=%.3f | ac=%5.1f none=%5.1f | Δ=%+5.2f | t=%5.2f | %s",
      f, lr, mean(on), mean(off), delta, t_val, verdict
    ))
  }
}
