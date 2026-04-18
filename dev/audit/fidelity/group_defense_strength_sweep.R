# s-group-defense promotion attempt: strength sweep × 16 seeds at
# realistic_specs.
#
# 8-seed realistic_specs audit (2026-04-18) gave Δpop(on-off) = +10.1
# ± 6.4 at t = +1.60 — direction-correct, sub-2σ. Same pattern as
# s-mating-systems before its promotion: more seeds and/or a
# parameter scan (group_defense_strength) should expose where the
# signal crosses 2σ.
#
# Design: group_defense_strength ∈ {0.5, 1.0, 2.0, 3.0} × 16 seeds
# × defense ON vs OFF. 1 shared OFF baseline × 16 + 4 strength cells
# × ON × 16 = 80 runs.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS     <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L,
               51L, 57L, 63L, 71L, 79L, 89L, 101L, 107L)
STRENGTHS <- c(0.5, 1.0, 2.0, 3.0)

build_spec <- function(gd, strength, seed) {
  s <- realistic_specs()
  s$group_defense            <- gd
  s$group_defense_strength   <- strength
  s$n_predators_init         <- 30L
  s$predator_max_agents      <- 120L
  s$predator_energy_gain     <- 20.0
  s$predator_attack_strength <- 40.0
  s$random_seed              <- as.integer(seed)
  s
}

# Shared OFF baseline (strength irrelevant when gd = FALSE)
specs_list <- lapply(SEEDS, function(sd) build_spec(FALSE, 1.0, sd))
conditions <- rep("off", length(SEEDS))
strength_v <- rep(NA_real_, length(SEEDS))

# ON conditions at each strength
for (st in STRENGTHS) {
  specs_list <- c(specs_list,
                  lapply(SEEDS, function(sd) build_spec(TRUE, st, sd)))
  conditions <- c(conditions, rep(paste0("on_", st), length(SEEDS)))
  strength_v <- c(strength_v, rep(st, length(SEEDS)))
}

message(sprintf("Running %d specs (OFF baseline + %d strengths × 16 seeds)...",
                length(specs_list), length(STRENGTHS)))
t0 <- Sys.time()
results <- batch_alife(specs_list, n_cores = 64L)
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
    strength    = strength_v[i],
    seed        = specs_list[[i]]$random_seed,
    verdict     = via$verdict,
    n_agents    = mean(d$n_agents[keep],    na.rm = TRUE),
    mean_energy = mean(d$mean_energy[keep], na.rm = TRUE)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/group_defense_strength_sweep.rds")

viable <- tbl[tbl$verdict != "crashed" & tbl$n_agents >= 20, ]

get_stats <- function(cnd, metric) {
  sub <- viable[viable$condition == cnd, ]
  if (nrow(sub) == 0L) return(c(mean = NA_real_, se = NA_real_, n = 0L))
  c(mean = mean(sub[[metric]]),
    se   = sd(sub[[metric]]) / sqrt(nrow(sub)),
    n    = nrow(sub))
}

off_n <- get_stats("off", "n_agents")
off_e <- get_stats("off", "mean_energy")
message(sprintf("\n── OFF baseline ──"))
message(sprintf("  n=%d | pop=%.1f \u00b1 %.1f | energy=%.2f \u00b1 %.2f",
                off_n["n"], off_n["mean"], off_n["se"],
                off_e["mean"], off_e["se"]))

message("\n── Group defense ON across group_defense_strength ──")
for (st in STRENGTHS) {
  on_n <- get_stats(paste0("on_", st), "n_agents")
  on_e <- get_stats(paste0("on_", st), "mean_energy")
  d_n  <- on_n["mean"] - off_n["mean"]
  se_n <- sqrt(on_n["se"]^2 + off_n["se"]^2)
  t_n  <- d_n / se_n
  d_e  <- on_e["mean"] - off_e["mean"]
  se_e <- sqrt(on_e["se"]^2 + off_e["se"]^2)
  t_e  <- d_e / se_e
  v <- if (!is.finite(t_n))    "NA"
       else if (t_n > 0 && abs(t_n) >= 2) "PASS"
       else if (abs(t_n) >= 2)            "PASS-wrong-direction"
       else                                "recheck"
  message(sprintf(
    "  strength=%.1f | on_n=%d pop=%.1f \u00b1 %.1f | \u0394pop=%+.2f \u00b1 %.2f  t_n=%+.2f %s  |  \u0394energy=%+.2f t_e=%+.2f",
    st, on_n["n"], on_n["mean"], on_n["se"], d_n, se_n, t_n, v, d_e, t_e))
}
