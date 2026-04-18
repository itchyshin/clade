# s-plasticity / s-baldwin — brain-architecture-as-plasticity-axis test.
#
# Insight: plasticity (in the DeWitt/Hinton-Nowlan sense — within-
# lifetime phenotype adjustment) is inherently a BNN property in
# clade. ANN has fixed weights; BNN has N(mu, sigma) weights with
# Thompson sampling = within-lifetime stochasticity that can be
# viewed as a plastic response channel.
#
# Test: under spatial heterogeneity (complex_landscape), do plastic
# brains (BNN) outperform fixed brains (ANN)? If yes, that's DeWitt
# 2004's spatial-plasticity prediction validated at the brain-
# architecture level.
#
# 2×2 design: brain_type × landscape × 16 seeds.
# Hypothesis: BNN × complex beats ANN × complex by more than
# BNN × flat beats ANN × flat (differential plasticity advantage).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L,
           51L, 57L, 63L, 71L, 79L, 89L, 101L, 107L)

build_spec <- function(brain_type, complex_landscape, seed) {
  # Using fast_specs (30x30) — realistic_specs + complex_landscape
  # crashes too often without wing_size_evolution.
  s <- fast_specs()
  s$brain_type        <- brain_type
  s$complex_landscape <- complex_landscape
  s$random_seed       <- as.integer(seed)
  s
}

specs_list <- c(
  lapply(SEEDS, function(sd) build_spec("bnn", FALSE, sd)),
  lapply(SEEDS, function(sd) build_spec("ann", FALSE, sd)),
  lapply(SEEDS, function(sd) build_spec("bnn", TRUE,  sd)),
  lapply(SEEDS, function(sd) build_spec("ann", TRUE,  sd))
)
conditions <- c(rep("bnn_flat",    length(SEEDS)),
                rep("ann_flat",    length(SEEDS)),
                rep("bnn_complex", length(SEEDS)),
                rep("ann_complex", length(SEEDS)))

message(sprintf("Running %d specs (4 conds × 16 seeds)...",
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
  keep <- d$t >= 1000
  data.frame(
    condition = conditions[i],
    seed      = specs_list[[i]]$random_seed,
    verdict   = via$verdict,
    n_agents  = mean(d$n_agents[keep],          na.rm = TRUE),
    diversity = mean(d$genetic_diversity[keep], na.rm = TRUE),
    mean_energy = mean(d$mean_energy[keep],     na.rm = TRUE)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/plasticity_brain_arch.rds")

message("\n── Verdict ──")
with(tbl, print(table(condition, verdict)))

viable <- tbl[tbl$verdict != "crashed" & tbl$n_agents >= 20, ]
message("\n── Per-condition summary (viable) ──")
for (cnd in c("bnn_flat", "ann_flat", "bnn_complex", "ann_complex")) {
  sub <- viable[viable$condition == cnd, ]
  if (nrow(sub) == 0L) {
    message(sprintf("  %-12s n=0 (all crashed)", cnd))
    next
  }
  message(sprintf(
    "  %-12s n=%d | pop=%.1f \u00b1 %.1f | div=%.3f \u00b1 %.3f | energy=%.1f",
    cnd, nrow(sub),
    mean(sub$n_agents),  sd(sub$n_agents)  / sqrt(nrow(sub)),
    mean(sub$diversity), sd(sub$diversity) / sqrt(nrow(sub)),
    mean(sub$mean_energy)))
}

# 2x2 differential: plasticity advantage = (BNN−ANN)_complex − (BNN−ANN)_flat
get_mean <- function(cnd, metric) {
  sub <- viable[viable$condition == cnd, ]
  if (nrow(sub) == 0L) return(c(m = NA, se = NA, n = 0))
  c(m = mean(sub[[metric]]),
    se = sd(sub[[metric]]) / sqrt(nrow(sub)),
    n = nrow(sub))
}
for (metric in c("n_agents", "diversity", "mean_energy")) {
  bf <- get_mean("bnn_flat", metric);    af <- get_mean("ann_flat", metric)
  bc <- get_mean("bnn_complex", metric); ac <- get_mean("ann_complex", metric)
  adv_flat    <- bf["m"] - af["m"]          # plasticity benefit in flat
  adv_complex <- bc["m"] - ac["m"]          # plasticity benefit in complex
  diff        <- adv_complex - adv_flat      # differential advantage
  se_d <- sqrt(bf["se"]^2 + af["se"]^2 + bc["se"]^2 + ac["se"]^2)
  t_d  <- diff / se_d
  v <- if (!is.finite(t_d)) "NA"
       else if (diff > 0 && abs(t_d) >= 2) "PASS (plastic advantage in complex)"
       else if (abs(t_d) >= 2)             "PASS wrong direction"
       else                                 "recheck"
  message(sprintf(
    "  %-12s | adv_flat=%+.3f, adv_complex=%+.3f | differential=%+.3f \u00b1 %.3f  t=%+.2f  %s",
    metric, adv_flat, adv_complex, diff, se_d, t_d, v))
}
