# s-mating-systems — Red Queen differential × parasite pressure sweep.
#
# Hypothesis (from 2026-04-18 2×2 diagnosis): RQ_benefit at
# parasite_pressure = 2.0 is direction-correct-but-sub-2σ
# (t = +0.76 for n_agents, +1.36 for diversity). If Hamilton 1980
# scales with pressure, higher parasite_pressure should amplify
# the signal until it crosses 2σ.
#
# Design: 16 seeds × 4 conditions per pressure level:
#   - asex_noP   (parasites off, pressure ignored)
#   - sex_noP    (parasites off, pressure ignored)
#   - asex_P_{p} (parasites on, parasite_pressure = p)
#   - sex_P_{p}  (parasites on, parasite_pressure = p)
# Pressure levels: {2, 4, 6, 8}.
# Total: 2 no-P conditions × 16 seeds + 4 pressures × 2 parasite
# conditions × 16 seeds = 32 + 128 = 160 runs.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS     <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L,
               51L, 57L, 63L, 71L, 79L, 89L, 101L, 107L)
PRESSURES <- c(2.0, 4.0, 6.0, 8.0)

build_spec <- function(ploidy, parasites, pressure, seed) {
  s <- realistic_specs()
  s$ploidy                        <- as.integer(ploidy)
  s$crossover_rate                <- if (ploidy == 2L) 0.5 else 0.0
  s$mate_search_radius            <- 1L
  s$parental_investment_evolution <- TRUE
  s$female_investment             <- 0.5
  if (parasites) {
    s$coevolving_parasites         <- TRUE
    s$n_parasite_loci              <- 16L
    s$parasite_pressure            <- pressure
    s$parasite_discrete_exponent   <- 6.0
    s$parasite_mutation_rate       <- 0.02
  }
  s$random_seed                   <- as.integer(seed)
  s
}

# no-parasite conditions (one set, shared across all pressures)
specs_list  <- c(
  lapply(SEEDS, function(sd) build_spec(1L, FALSE, NA_real_, sd)),
  lapply(SEEDS, function(sd) build_spec(2L, FALSE, NA_real_, sd))
)
conditions <- c(rep("asex_noP", length(SEEDS)),
                rep("sex_noP",  length(SEEDS)))
pressures_v <- c(rep(NA_real_, 2L * length(SEEDS)))

# parasite conditions at each pressure
for (p in PRESSURES) {
  specs_list <- c(specs_list,
                  lapply(SEEDS, function(sd) build_spec(1L, TRUE, p, sd)),
                  lapply(SEEDS, function(sd) build_spec(2L, TRUE, p, sd)))
  conditions <- c(conditions,
                  rep(paste0("asex_P_", p), length(SEEDS)),
                  rep(paste0("sex_P_",  p), length(SEEDS)))
  pressures_v <- c(pressures_v, rep(p, 2L * length(SEEDS)))
}

message(sprintf("Running %d specs (2 no-P + 4 pressures × 2 parasite) × 16 seeds...",
                length(specs_list)))
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
    condition = conditions[i],
    pressure  = pressures_v[i],
    seed      = specs_list[[i]]$random_seed,
    verdict   = via$verdict,
    n_agents  = mean(d$n_agents[keep],          na.rm = TRUE),
    diversity = mean(d$genetic_diversity[keep], na.rm = TRUE)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/mating_systems_pressure_sweep.rds")

viable <- tbl[tbl$verdict != "crashed" & tbl$n_agents >= 20, ]

get_stats <- function(cnd, metric) {
  sub <- viable[viable$condition == cnd, ]
  if (nrow(sub) == 0L) return(c(mean = NA_real_, se = NA_real_, n = 0))
  c(mean = mean(sub[[metric]]),
    se   = sd(sub[[metric]]) / sqrt(nrow(sub)),
    n    = nrow(sub))
}

# baseline (no parasites)
an0 <- get_stats("asex_noP", "n_agents"); sn0 <- get_stats("sex_noP", "n_agents")
ad0 <- get_stats("asex_noP", "diversity"); sd0 <- get_stats("sex_noP", "diversity")
message(sprintf("\n── No-parasite baseline ──"))
message(sprintf("  asex_noP  n=%d | pop=%.1f \u00b1 %.1f", an0["n"], an0["mean"], an0["se"]))
message(sprintf("  sex_noP   n=%d | pop=%.1f \u00b1 %.1f", sn0["n"], sn0["mean"], sn0["se"]))

# Red Queen scan across pressures
message("\n── Red Queen benefit across parasite_pressure ──")
message(sprintf("  %-8s | %-26s | %-26s | %-14s",
                "pressure", "asex_P (pop; div)", "sex_P (pop; div)", "RQ t-stats"))
for (p in PRESSURES) {
  ap <- get_stats(paste0("asex_P_", p), "n_agents")
  sp <- get_stats(paste0("sex_P_",  p), "n_agents")
  apd <- get_stats(paste0("asex_P_", p), "diversity")
  spd <- get_stats(paste0("sex_P_",  p), "diversity")

  rq_n   <- (an0["mean"] - ap["mean"]) - (sn0["mean"] - sp["mean"])
  rq_n_se <- sqrt(an0["se"]^2 + ap["se"]^2 + sn0["se"]^2 + sp["se"]^2)
  t_n    <- rq_n / rq_n_se

  rq_d    <- (ad0["mean"] - apd["mean"]) - (sd0["mean"] - spd["mean"])
  rq_d_se <- sqrt(ad0["se"]^2 + apd["se"]^2 + sd0["se"]^2 + spd["se"]^2)
  t_d     <- rq_d / rq_d_se

  message(sprintf(
    "  %.1f      | %.1f \u00b1 %.1f (%.3f \u00b1 %.3f) | %.1f \u00b1 %.1f (%.3f \u00b1 %.3f) | t_n=%+.2f t_div=%+.2f",
    p, ap["mean"], ap["se"], apd["mean"], apd["se"],
       sp["mean"], sp["se"], spd["mean"], spd["se"], t_n, t_d))
}
