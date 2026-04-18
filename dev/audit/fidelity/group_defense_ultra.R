# s-group-defense at ultra_realistic scale.
#
# At realistic_specs() (N ≈ 120), Δpop(on - off) = +10.1 at t = +1.60
# — direction correct, sub-2σ. Selfish-herd risk dilution scales as
# ~1/√N, so a 3× larger N should give a ~√3 ≈ 1.7× larger signal.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L,
           51L, 57L, 63L, 71L, 79L, 89L, 101L, 107L)

build_spec <- function(gd, seed) {
  s <- ultra_realistic_specs()
  s$group_defense           <- gd
  s$group_defense_strength  <- 1.0
  s$n_predators_init        <- 80L
  s$predator_max_agents     <- 300L
  s$predator_energy_gain    <- 20.0
  s$predator_attack_strength<- 40.0
  s$random_seed             <- as.integer(seed)
  s
}

specs_list <- c(
  lapply(SEEDS, function(sd) build_spec(TRUE,  sd)),
  lapply(SEEDS, function(sd) build_spec(FALSE, sd))
)
conditions <- c(rep("gd_on", length(SEEDS)), rep("gd_off", length(SEEDS)))

message(sprintf("Running %d specs (2 conds x 16 seeds) at ultra scale...",
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
  keep <- d$t >= 2000
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
saveRDS(tbl, "dev/audit/fidelity/group_defense_ultra.rds")

viable <- tbl[tbl$verdict != "crashed", ]
message("\n── Per-condition summary (viable) ──")
for (cnd in c("gd_on", "gd_off")) {
  sub <- viable[viable$condition == cnd, ]
  message(sprintf("  %-7s n=%d | pop=%.1f \u00b1 %.1f | energy=%.2f \u00b1 %.2f",
                  cnd, nrow(sub),
                  mean(sub$n_agents),    sd(sub$n_agents)    / sqrt(nrow(sub)),
                  mean(sub$mean_energy), sd(sub$mean_energy) / sqrt(nrow(sub))))
}
on  <- viable[viable$condition == "gd_on",  ]
off <- viable[viable$condition == "gd_off", ]
if (nrow(on) >= 2L && nrow(off) >= 2L) {
  for (metric in c("n_agents", "mean_energy")) {
    d_ <- mean(on[[metric]]) - mean(off[[metric]])
    se <- sqrt(var(on[[metric]]) / nrow(on) + var(off[[metric]]) / nrow(off))
    t_ <- d_ / se
    v <- if (!is.finite(t_)) "NA" else if (abs(t_) >= 2) "PASS" else "recheck"
    message(sprintf("  %-12s  \u0394(on - off) = %+7.3f \u00b1 %.3f   t = %+5.2f   %s",
                    metric, d_, se, t_, v))
  }
}
