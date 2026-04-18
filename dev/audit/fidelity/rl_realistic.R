# s-rl re-audit at realistic scale.
#
# Previous 144-run sweep (freq × lr) + 16-seed at best cell: no cell
# gave canonical Δenergy > 0 at t ≥ 2 under fast_specs at 30×30.
#
# Re-audit at realistic_specs() scale + complex_landscape to give
# RL a non-trivial foraging problem to solve.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L)

build_spec <- function(mode, seed) {
  s <- realistic_specs()
  s$rl_mode                 <- mode
  s$rl_update_freq          <- 5L
  s$learning_rate_init_mean <- 0.005
  s$complex_landscape       <- TRUE
  s$random_seed             <- as.integer(seed)
  s
}

specs_list <- c(
  lapply(SEEDS, function(sd) build_spec("actor_critic", sd)),
  lapply(SEEDS, function(sd) build_spec("none",         sd))
)
conditions <- c(rep("ac", length(SEEDS)), rep("none", length(SEEDS)))

message(sprintf("Running %d specs (2 conds x 8 seeds) at realistic scale...",
                length(specs_list)))
t0 <- Sys.time()
results <- batch_alife(specs_list, n_cores = length(specs_list))
message(sprintf("  batch wall: %.1f min",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))

rows <- lapply(seq_along(results), function(i) {
  env <- results[[i]]
  rd  <- get_run_data(env)
  via <- viability_report(rd)
  d   <- rd$ticks
  keep <- d$t >= 1500
  data.frame(
    condition   = conditions[i],
    seed        = specs_list[[i]]$random_seed,
    verdict     = via$verdict,
    n_agents    = mean(d$n_agents[keep],    na.rm = TRUE),
    mean_energy = mean(d$mean_energy[keep], na.rm = TRUE),
    n_final     = tail(d$n_agents, 1L)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/rl_realistic.rds")

viable <- tbl[tbl$verdict != "crashed", ]
message("\n── Per-condition summary (viable) ──")
for (cnd in c("ac", "none")) {
  sub <- viable[viable$condition == cnd, ]
  message(sprintf("  %-5s n=%d | energy=%.2f ± %.2f | pop=%.2f ± %.2f",
                  cnd, nrow(sub),
                  mean(sub$mean_energy), sd(sub$mean_energy) / sqrt(nrow(sub)),
                  mean(sub$n_agents),    sd(sub$n_agents)    / sqrt(nrow(sub))))
}
on  <- viable[viable$condition == "ac",   ]
off <- viable[viable$condition == "none", ]
if (nrow(on) >= 2L && nrow(off) >= 2L) {
  for (metric in c("mean_energy", "n_agents")) {
    d_ <- mean(on[[metric]]) - mean(off[[metric]])
    se <- sqrt(var(on[[metric]]) / nrow(on) + var(off[[metric]]) / nrow(off))
    t_ <- d_ / se
    v <- if (!is.finite(t_)) "NA" else if (abs(t_) >= 2) "PASS" else "recheck"
    message(sprintf("  %-12s  \u0394(ac - none) = %+7.3f \u00b1 %.3f   t = %+5.2f   %s",
                    metric, d_, se, t_, v))
  }
}
