# Ryan 1990 — sensory exploitation (the β_N leg of Fuller 2005).
#
# Ryan, M. J. (1990). Sexual selection, sensory systems and sensory
# exploitation. Oxford Surveys in Evolutionary Biology 7:157-195.
#
# Mechanism: a PRE-EXISTING preference, shaped by non-mating selection
# (foraging cue detection, predator avoidance), exists before any
# signal evolves. Under mate choice, signals should evolve to EXPLOIT
# the pre-existing bias.
#
# 0.6.5 adds `preference_bias_target` + `preference_bias_strength`:
# at each tick, each agent's preference is pulled toward the fixed
# target vector. This installs the β_N leg of Fuller's framework.
#
# Expected signature (strong prediction):
#   H1: preferences converge on the target       [direct kernel mechanism]
#   H2: signals under preference mating drift
#       toward the target                        [emergent from mate choice]
#
# Observed (this audit): H1 is a clean PASS. H2 is direction-correct but
# sub-threshold — same genetic-linkage gap that blocks Fisher. Mate
# choice selects parents for (A.pref ≈ B.sig) matching, but meiosis
# inherits signal and preference independently, so offspring signal
# direction is recombined each generation.

suppressPackageStartupMessages({
  library(clade)
  library(parallel)
})

SEEDS         <- 1:4
BIAS_LEVELS   <- c(0.00, 0.02, 0.05, 0.10)
BIAS_TARGET   <- c(1.0, 0.0, 0.0)

run_one <- function(bias_strength, seed) {
  suppressPackageStartupMessages(library(clade))
  s <- default_specs()
  s$grid_rows              <- 40L
  s$grid_cols              <- 40L
  s$n_agents_init          <- 120L
  s$max_agents             <- 500L
  s$max_ticks              <- 3000L
  s$grass_rate             <- 0.15
  s$n_predators_init       <- 0L
  s$signal_dims            <- 3L
  s$signal_evolution_drift <- TRUE
  s$signal_drift_sd        <- 0.05
  s$mate_choice_mode       <- "preference"
  s$mate_choice_strength   <- 1.0
  s$preference_bias_strength <- bias_strength
  if (bias_strength > 0) s$preference_bias_target <- BIAS_TARGET
  s$random_seed            <- as.integer(seed)

  env <- suppressWarnings(run_alife(s))
  sig_sums  <- rep(0, 3L)
  pref_sums <- rep(0, 3L)
  n_alive   <- 0L
  for (i in seq_len(length(env$agents))) {
    ag <- env$agents[[i]]
    if (isTRUE(ag$alive)) {
      sig_sums  <- sig_sums  + as.numeric(ag$signal)
      pref_sums <- pref_sums + as.numeric(ag$preference)
      n_alive   <- n_alive + 1L
    }
  }
  data.frame(
    bias_strength = bias_strength,
    seed          = as.integer(seed),
    n_alive       = n_alive,
    mean_sig_d1   = sig_sums[1]  / max(n_alive, 1L),
    mean_sig_d2   = sig_sums[2]  / max(n_alive, 1L),
    mean_sig_d3   = sig_sums[3]  / max(n_alive, 1L),
    mean_pref_d1  = pref_sums[1] / max(n_alive, 1L),
    mean_pref_d2  = pref_sums[2] / max(n_alive, 1L),
    mean_pref_d3  = pref_sums[3] / max(n_alive, 1L)
  )
}

grid <- expand.grid(bias_strength = BIAS_LEVELS, seed = SEEDS)
cat(sprintf("=== Ryan 1990 audit: %d conditions × %d seeds = %d runs ===\n\n",
            length(BIAS_LEVELS), length(SEEDS), nrow(grid)))

cl <- makeCluster(min(nrow(grid), 16L))
on.exit(stopCluster(cl), add = TRUE)
clusterExport(cl, varlist = c("BIAS_TARGET", "run_one"))
t0 <- Sys.time()
rows <- clusterMap(cl,
                   function(b, s) run_one(b, s),
                   b = grid$bias_strength, s = grid$seed,
                   SIMPLIFY = FALSE)
runs <- do.call(rbind, rows)
cat(sprintf("Complete in %.1fs\n\n",
            as.numeric(difftime(Sys.time(), t0, units = "secs"))))

cat("=== Per-condition means (4 seeds, final-tick agents) ===\n")
agg <- aggregate(cbind(mean_pref_d1, mean_pref_d2, mean_pref_d3,
                       mean_sig_d1,  mean_sig_d2,  mean_sig_d3,
                       n_alive) ~ bias_strength,
                 data = runs, FUN = mean)
print(agg, row.names = FALSE, digits = 3)

cat("\n=== H1: Preference response (β_N installed) ===\n")
cat("  mean_pref_d1 should grow with bias_strength (target = [1, 0, 0])\n")
fit_pref <- lm(mean_pref_d1 ~ bias_strength, data = runs)
print(summary(fit_pref)$coefficients)

cat("\n=== H2: Signal response (Ryan 1990 downstream) ===\n")
cat("  mean_sig_d1 should grow with bias_strength (signals exploit bias)\n")
fit_sig <- lm(mean_sig_d1 ~ bias_strength, data = runs)
print(summary(fit_sig)$coefficients)

saveRDS(list(runs = runs, fit_pref = fit_pref, fit_sig = fit_sig,
             bias_target = BIAS_TARGET, seeds = SEEDS),
        "dev/audit/fidelity/paper_ryan_1990.rds")
cat("\nSaved: dev/audit/fidelity/paper_ryan_1990.rds\n")
