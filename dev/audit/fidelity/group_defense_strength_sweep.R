# Parameter sweep for s-group-defense (one of the Tier-C batch-1
# silent failures). Canonical Hamilton 1971 selfish-herd claim is
# that group_defense ON reduces per-prey attack risk → higher prey
# survival under predation. At default parameters the 8-seed
# direction check gave Δn = -0.9, t = -0.15 (no signal). Hypothesis:
# default strength = 0.3 is too weak relative to default predator
# pressure (5 predators vs 100 prey).
#
# Sweep: group_defense_strength ∈ {0.3, 0.6, 0.9} ×
# n_predators_init ∈ {10, 20} × defense {ON, OFF} × 8 seeds.
# Uses the 0.5.6 PSOCK batch_alife().

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS   <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L)
STRENGTHS <- c(0.3, 0.6, 0.9)
N_PREDS   <- c(10L, 20L)

base <- default_specs()
base$n_agents_init <- 100L
base$max_agents    <- 400L
base$grid_rows     <- 30L
base$grid_cols     <- 30L
base$max_ticks     <- 400L
base$group_defense_radius <- 2L

# Build 3 × 2 × 2 × 8 = 96 specs via grid_specs
specs_list <- grid_specs(
  base,
  group_defense           = c(TRUE, FALSE),
  group_defense_strength  = STRENGTHS,
  n_predators_init        = N_PREDS,
  random_seed             = SEEDS
)
message(sprintf("Built %d specs", length(specs_list)))

t0 <- Sys.time()
message(sprintf("Running %d specs × PSOCK cluster...", length(specs_list)))
results <- batch_alife(specs_list, n_cores = 48L)
message(sprintf("  batch: %.1f min", as.numeric(difftime(Sys.time(), t0, units = "mins"))))

rows <- lapply(seq_along(results), function(i) {
  env <- results[[i]]; s <- specs_list[[i]]
  d <- get_run_data(env)$ticks
  vr <- viability_report(d, n_agents_init = s$n_agents_init)
  data.frame(
    group_defense          = s$group_defense,
    strength               = s$group_defense_strength,
    n_predators            = s$n_predators_init,
    seed                   = s$random_seed,
    n_final                = tail(d$n_agents, 1L),
    n_mean_last100         = mean(tail(d$n_agents, 100L), na.rm = TRUE),
    viability              = vr$verdict
  )
})
summary_tbl <- do.call(rbind, rows)
saveRDS(summary_tbl, "dev/audit/fidelity/group_defense_strength_sweep.rds")

message("\n── ON vs OFF at each (strength, n_predators) cell ──")
for (st in STRENGTHS) {
  for (np in N_PREDS) {
    cell <- summary_tbl[summary_tbl$strength  == st &
                         summary_tbl$n_predators == np, ]
    on  <- cell$n_mean_last100[cell$group_defense == TRUE]
    off <- cell$n_mean_last100[cell$group_defense == FALSE]
    delta <- mean(on) - mean(off)
    se    <- sqrt(sd(on)^2 / length(on) + sd(off)^2 / length(off))
    t_val <- delta / se
    message(sprintf(
      "  strength=%.1f n_pred=%2d | on=%5.1f off=%5.1f | Δ=%+6.1f | t=%5.2f | %s",
      st, np, mean(on), mean(off), delta, t_val,
      if (abs(t_val) >= 2) "PASS (t ≥ 2)" else "RECHECK"
    ))
  }
}

message(sprintf("\n=== Done in %.1f min ===",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))
