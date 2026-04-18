# s-mating-systems promotion attempt: 🟠 → ✅ at realistic scale.
#
# 0.5.1 found +1.1 sex > asex direction under discrete multi-locus
# parasites (n_loci=16, pressure=2.0, exponent=6.0) at 3 seeds.
# 0.5.3 at 16 seeds × 19 regimes: direction correct on average
# across regimes, no single cell crossed 2 σ.
#
# Re-audit at realistic_specs() scale + 32 seeds on the 0.5.1 best
# cell (parasite_discrete, n_loci=16, pressure=2.0, exponent=6.0,
# mutation=0.02, crossover=0.5).
#
# Design: 2 ploidies (asex=1, sex=2) × 32 seeds × 2000 ticks × 60×60
# grid + discrete parasites.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L,
           51L, 57L, 63L, 71L, 79L, 89L, 101L, 107L,
           113L, 121L, 131L, 139L, 149L, 157L, 163L, 173L,
           179L, 191L, 197L, 211L, 223L, 227L, 239L, 251L)

build_spec <- function(ploidy, seed) {
  s <- realistic_specs()
  s$ploidy                      <- as.integer(ploidy)
  s$crossover_rate              <- if (ploidy == 2L) 0.5 else 0.0
  s$coevolving_parasites        <- TRUE
  s$n_parasite_loci             <- 16L
  s$parasite_pressure           <- 2.0
  s$parasite_discrete_exponent  <- 6.0
  s$parasite_mutation_rate      <- 0.02
  s$random_seed                 <- as.integer(seed)
  s
}

specs_list <- c(
  lapply(SEEDS, function(sd) build_spec(1L, sd)),
  lapply(SEEDS, function(sd) build_spec(2L, sd))
)
conditions <- c(rep("asex", length(SEEDS)), rep("sex", length(SEEDS)))

message(sprintf("Running %d specs (2 ploidies x 32 seeds) at realistic scale...",
                length(specs_list)))
t0 <- Sys.time()
results <- batch_alife(specs_list, n_cores = min(64L, length(specs_list)))
message(sprintf("  batch wall: %.1f min",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))

rows <- lapply(seq_along(results), function(i) {
  env <- results[[i]]
  rd  <- get_run_data(env)
  via <- viability_report(rd)
  d   <- rd$ticks
  keep <- d$t >= 1500  # last 500 ticks
  data.frame(
    condition     = conditions[i],
    seed          = specs_list[[i]]$random_seed,
    verdict       = via$verdict,
    n_agents      = mean(d$n_agents[keep],          na.rm = TRUE),
    mean_energy   = mean(d$mean_energy[keep],       na.rm = TRUE),
    gen_diversity = mean(d$genetic_diversity[keep], na.rm = TRUE),
    n_final       = tail(d$n_agents, 1L)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/mating_systems_realistic.rds")

message("\n── Viability ──")
with(tbl, print(table(condition, verdict)))

viable <- tbl[tbl$verdict != "crashed", ]
message("\n── Per-condition summary (viable, t >= 1500) ──")
for (cnd in c("asex", "sex")) {
  sub <- viable[viable$condition == cnd, ]
  message(sprintf(
    "  %-5s  n=%d | pop=%.2f ± %.2f | div=%.3f ± %.3f | energy=%.2f ± %.2f",
    cnd, nrow(sub),
    mean(sub$n_agents),      sd(sub$n_agents)      / sqrt(nrow(sub)),
    mean(sub$gen_diversity), sd(sub$gen_diversity) / sqrt(nrow(sub)),
    mean(sub$mean_energy),   sd(sub$mean_energy)   / sqrt(nrow(sub))))
}

# Paired direction test (Hamilton 1980: sex > asex in n_agents)
asex <- viable[viable$condition == "asex", ]
sex  <- viable[viable$condition == "sex",  ]
if (nrow(asex) >= 4L && nrow(sex) >= 4L) {
  for (metric in c("n_agents", "gen_diversity", "mean_energy")) {
    d_ <- mean(sex[[metric]]) - mean(asex[[metric]])
    se <- sqrt(var(sex[[metric]]) / nrow(sex) + var(asex[[metric]]) / nrow(asex))
    t_ <- d_ / se
    verdict <- if (!is.finite(t_))     "NA"
               else if (abs(t_) >= 2)  "PASS"
               else                    "recheck"
    message(sprintf("  %-14s  \u0394(sex - asex) = %+7.3f \u00b1 %.3f   t = %+5.2f   %s",
                    metric, d_, se, t_, verdict))
  }
}
