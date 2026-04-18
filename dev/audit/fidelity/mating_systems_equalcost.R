# s-mating-systems with equalized total reproduction cost.
#
# Problem: under clade's default (`parental_investment_evolution = FALSE`),
# sex is structurally 1.5× more costly per offspring than asex:
#   asex: parent pays cost_paid
#   sex:  parent pays cost_paid + mate pays cost_paid * 0.5
# This makes sex viability-negative regardless of Red Queen benefit.
#
# Fix (no kernel change): turn on `parental_investment_evolution = TRUE`
# with `female_investment = 0.5`. The `pi_on` code path splits
# cost symmetrically:
#   ag.energy   -= cost_paid * 0.5
#   mate.energy -= cost_paid * 0.5
# Total = cost_paid per offspring, same as asex.
#
# Under equalized cost, Hamilton 1980 Red Queen becomes testable.
# Predict: sex population > asex population under parasite pressure.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L,
           51L, 57L, 63L, 71L, 79L, 89L, 101L, 107L)

build_spec <- function(ploidy, seed) {
  s <- realistic_specs()
  s$ploidy                        <- as.integer(ploidy)
  s$crossover_rate                <- if (ploidy == 2L) 0.5 else 0.0
  s$mate_search_radius            <- 2L   # 5x5 Moore → more candidates
  # equal-cost split: each parent pays 0.5 × cost_paid (sex) or full (asex)
  s$parental_investment_evolution <- TRUE
  s$female_investment             <- 0.5
  s$coevolving_parasites          <- TRUE
  s$n_parasite_loci               <- 16L
  s$parasite_pressure             <- 2.0
  s$parasite_discrete_exponent    <- 6.0
  s$parasite_mutation_rate        <- 0.02
  s$random_seed                   <- as.integer(seed)
  s
}

specs_list <- c(
  lapply(SEEDS, function(sd) build_spec(1L, sd)),
  lapply(SEEDS, function(sd) build_spec(2L, sd))
)
conditions <- c(rep("asex", length(SEEDS)), rep("sex", length(SEEDS)))

message(sprintf("Running %d specs (2 ploidies x 16 seeds) equal-cost...",
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
    gen_diversity = mean(d$genetic_diversity[keep], na.rm = TRUE),
    n_final       = tail(d$n_agents, 1L)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/mating_systems_equalcost.rds")

message("\n── Viability ──")
with(tbl, print(table(condition, verdict)))

viable <- tbl[tbl$verdict != "crashed" & tbl$n_agents >= 20, ]
message("\n── Per-condition summary (viable, t >= 1500) ──")
for (cnd in c("asex", "sex")) {
  sub <- viable[viable$condition == cnd, ]
  if (nrow(sub) == 0L) {
    message(sprintf("  %-5s n=0 | (all crashed)", cnd))
    next
  }
  message(sprintf(
    "  %-5s n=%d | pop=%.1f \u00b1 %.1f | div=%.3f \u00b1 %.3f",
    cnd, nrow(sub),
    mean(sub$n_agents),      sd(sub$n_agents)      / sqrt(nrow(sub)),
    mean(sub$gen_diversity), sd(sub$gen_diversity) / sqrt(nrow(sub))))
}
asex <- viable[viable$condition == "asex", ]
sex  <- viable[viable$condition == "sex",  ]
if (nrow(asex) >= 4L && nrow(sex) >= 4L) {
  for (metric in c("n_agents", "gen_diversity")) {
    d_ <- mean(sex[[metric]]) - mean(asex[[metric]])
    se <- sqrt(var(sex[[metric]]) / nrow(sex) + var(asex[[metric]]) / nrow(asex))
    t_ <- d_ / se
    v <- if (!is.finite(t_))     "NA"
         else if (abs(t_) >= 2)  "PASS"
         else                    "recheck"
    message(sprintf("  %-14s  \u0394(sex - asex) = %+7.3f \u00b1 %.3f   t = %+5.2f   %s",
                    metric, d_, se, t_, v))
  }
}
