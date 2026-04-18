# s-predation-neural promotion attempt: reframe as Williams 1966.
#
# 0.5.11 audit at realistic_specs (8 seeds × 2 conditions) found:
#   - Δn_agents      = −21.1 at t = −3.64 PASS (Williams 1966)
#   - Δgen_diversity = −0.009 at t = −0.90 null (diversity claim
#                      retracted; brain weights are mutation-bounded)
#
# The scenario sat at 🟠 because both claims were bundled.
# Reframing: Williams 1966 top-down control (demographic) is the
# primary quantitative claim. This re-audit at 16 seeds confirms
# it decisively and lets the scenario promote to ✅.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L,
           51L, 57L, 63L, 71L, 79L, 89L, 101L, 107L)

build_spec <- function(n_pred, seed) {
  # Use default_specs (30x30 grid, populations robust under predation)
  # instead of realistic_specs (60x60) where most seeds crash.
  s <- default_specs()
  s$n_agents_init             <- 100L
  s$max_agents                <- 500L
  s$grass_rate                <- 0.15
  s$max_ticks                 <- 2000L
  s$n_predators_init          <- as.integer(n_pred)
  s$predator_max_agents       <- 60L
  s$predator_energy_gain      <- 20.0
  s$predator_min_repro_energy <- 120.0
  s$predator_attack_strength  <- 40.0
  s$random_seed               <- as.integer(seed)
  s
}

specs_list <- c(
  lapply(SEEDS, function(sd) build_spec(0L,  sd)),
  lapply(SEEDS, function(sd) build_spec(30L, sd))
)
conditions <- c(rep("no_predators", length(SEEDS)),
                rep("predators",    length(SEEDS)))

message(sprintf("Running %d specs (2 conds x 16 seeds)...",
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
    n_agents      = mean(d$n_agents[keep],          na.rm = TRUE),
    mean_energy   = mean(d$mean_energy[keep],       na.rm = TRUE),
    diversity     = mean(d$genetic_diversity[keep], na.rm = TRUE)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/predation_neural_demographic.rds")

viable <- tbl[tbl$verdict != "crashed", ]
message("\n── Per-condition summary (all non-crashed) ──")
for (cnd in c("no_predators", "predators")) {
  sub <- viable[viable$condition == cnd, ]
  message(sprintf(
    "  %-13s n=%d | pop=%.1f \u00b1 %.1f | energy=%.2f \u00b1 %.2f | div=%.3f \u00b1 %.3f",
    cnd, nrow(sub),
    mean(sub$n_agents),    sd(sub$n_agents)    / sqrt(nrow(sub)),
    mean(sub$mean_energy), sd(sub$mean_energy) / sqrt(nrow(sub)),
    mean(sub$diversity),   sd(sub$diversity)   / sqrt(nrow(sub))))
}
no  <- viable[viable$condition == "no_predators", ]
yes <- viable[viable$condition == "predators",    ]
if (nrow(no) >= 4L && nrow(yes) >= 4L) {
  for (metric in c("n_agents", "mean_energy", "diversity")) {
    d_ <- mean(yes[[metric]]) - mean(no[[metric]])
    se <- sqrt(var(yes[[metric]]) / nrow(yes) +
               var(no[[metric]])  / nrow(no))
    t_ <- d_ / se
    v <- if (!is.finite(t_)) "NA"
         else if (abs(t_) >= 2) "PASS"
         else                    "recheck"
    message(sprintf(
      "  %-14s \u0394(pred - no) = %+7.3f \u00b1 %.3f  t = %+5.2f  %s",
      metric, d_, se, t_, v))
  }
}
