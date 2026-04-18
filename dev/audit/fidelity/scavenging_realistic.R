# s-scavenging promotion attempt at realistic scale.
#
# Previous audits (128-run with predators, 192-run grid): no cell
# produced canonical Δenergy > 0 under DeVault 2003.
#
# Re-audit at realistic_specs() scale: 60×60 grid + predator guild
# provides more carrion supply; 2000 ticks gives scavenging time to
# express as an energy channel.
#
# Design: scavenging ∈ {TRUE, FALSE} × 8 seeds × 2000 ticks with
# predators on (30 init). Measure mean_energy last 500 ticks.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L)

build_spec <- function(scav, seed) {
  s <- realistic_specs()
  s$scavenging              <- scav
  s$carrion_eat_gain        <- 15.0
  s$carrion_fraction        <- 1.0
  s$carrion_decay_rate      <- 0.1
  s$n_predators_init        <- 30L
  s$predator_max_agents     <- 120L
  s$predator_energy_gain    <- 20.0
  s$predator_attack_strength<- 40.0
  s$random_seed             <- as.integer(seed)
  s
}

specs_list <- c(
  lapply(SEEDS, function(sd) build_spec(TRUE,  sd)),
  lapply(SEEDS, function(sd) build_spec(FALSE, sd))
)
conditions <- c(rep("scav_on", length(SEEDS)), rep("scav_off", length(SEEDS)))

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
    condition     = conditions[i],
    seed          = specs_list[[i]]$random_seed,
    verdict       = via$verdict,
    n_agents      = mean(d$n_agents[keep],    na.rm = TRUE),
    mean_energy   = mean(d$mean_energy[keep], na.rm = TRUE),
    n_final       = tail(d$n_agents, 1L)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/scavenging_realistic.rds")

message("\n── Viability ──")
with(tbl, print(table(condition, verdict)))

viable <- tbl[tbl$verdict != "crashed", ]
message("\n── Per-condition summary (viable, t >= 1500) ──")
for (cnd in c("scav_on", "scav_off")) {
  sub <- viable[viable$condition == cnd, ]
  message(sprintf("  %-9s n=%d | energy=%.2f ± %.2f | pop=%.2f ± %.2f",
                  cnd, nrow(sub),
                  mean(sub$mean_energy), sd(sub$mean_energy) / sqrt(nrow(sub)),
                  mean(sub$n_agents),    sd(sub$n_agents)    / sqrt(nrow(sub))))
}
on  <- viable[viable$condition == "scav_on",  ]
off <- viable[viable$condition == "scav_off", ]
if (nrow(on) >= 2L && nrow(off) >= 2L) {
  for (metric in c("mean_energy", "n_agents")) {
    d_ <- mean(on[[metric]]) - mean(off[[metric]])
    se <- sqrt(var(on[[metric]]) / nrow(on) + var(off[[metric]]) / nrow(off))
    t_ <- d_ / se
    verdict <- if (!is.finite(t_))     "NA"
               else if (abs(t_) >= 2)  "PASS"
               else                    "recheck"
    message(sprintf("  %-12s  \u0394(on - off) = %+7.3f \u00b1 %.3f   t = %+5.2f   %s",
                    metric, d_, se, t_, verdict))
  }
}
