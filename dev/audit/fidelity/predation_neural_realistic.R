# s-predation-neural promotion attempt: NA → quantitative claim.
#
# Latent claim in the vignette: predation increases prey genetic
# diversity (directional selection on cognition) and decreases mean
# energy (evasion cost).
#
# Previous audit (3 seeds, 400 ticks, grass_rate = 0.2) found a null,
# honestly documented as "predation mortality too small relative to
# starvation".  Re-audit at realistic_specs() scale with a
# predation-dominant ecology (grass_rate = 0.08) where predation is
# the dominant mortality source.
#
# Design: 2 conditions (no_predators, predators) × 8 seeds × 5000 ticks
# at 60×60 grid.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L)

build_spec <- function(n_pred, seed) {
  s <- realistic_specs()
  s$n_predators_init          <- as.integer(n_pred)
  s$predator_max_agents       <- 120L
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

message(sprintf("Running %d specs (2 conditions x 8 seeds) at realistic scale...",
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
  keep <- d$t >= 1500  # last 500 ticks (max_ticks = 2000)
  data.frame(
    condition     = conditions[i],
    seed          = specs_list[[i]]$random_seed,
    verdict       = via$verdict,
    n_agents      = mean(d$n_agents[keep],          na.rm = TRUE),
    mean_energy   = mean(d$mean_energy[keep],       na.rm = TRUE),
    gen_diversity = mean(d$genetic_diversity[keep], na.rm = TRUE),
    n_predators   = mean(d$n_predators[keep],       na.rm = TRUE),
    n_final       = tail(d$n_agents, 1L)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/predation_neural_realistic.rds")

message("\n── Viability ──")
with(tbl, print(table(condition, verdict)))

viable <- tbl[tbl$verdict != "crashed", ]
summarise_one <- function(sub, col) {
  x <- sub[[col]]
  sprintf("%.3f ± %.3f", mean(x), sd(x) / sqrt(length(x)))
}

message("\n── Per-condition summary (viable runs, t >= 1500) ──")
for (cnd in c("no_predators", "predators")) {
  sub <- viable[viable$condition == cnd, ]
  message(sprintf(
    "  %-13s  n=%d | diversity=%s | energy=%s | prey=%s",
    cnd, nrow(sub),
    summarise_one(sub, "gen_diversity"),
    summarise_one(sub, "mean_energy"),
    summarise_one(sub, "n_agents")))
}

# Direction tests (only if both conditions have viable runs)
no  <- viable[viable$condition == "no_predators", ]
yes <- viable[viable$condition == "predators",    ]
if (nrow(no) >= 2L && nrow(yes) >= 2L) {
  for (metric in c("gen_diversity", "mean_energy", "n_agents")) {
    d_ <- mean(yes[[metric]]) - mean(no[[metric]])
    se <- sqrt(var(yes[[metric]]) / nrow(yes) + var(no[[metric]]) / nrow(no))
    t_ <- d_ / se
    verdict <- if (!is.finite(t_)) "NA-insufficient data"
               else if (abs(t_) >= 2) "PASS"
               else                   "recheck"
    message(sprintf("  %-14s  \u0394(pred - no) = %+7.3f \u00b1 %.3f   t = %+5.2f   %s",
                    metric, d_, se, t_, verdict))
  }
} else {
  message(sprintf("  Not enough viable runs for direction test (no=%d, yes=%d)",
                  nrow(no), nrow(yes)))
}
