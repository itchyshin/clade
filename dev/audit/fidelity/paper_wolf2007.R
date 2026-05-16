# Wolf et al. (2007) Nature personality-syndrome multi-seed fidelity reproduction
# "Life-history trade-offs favour the evolution of animal
# personalities", Nature 447:581-584
#
# Core claim: under the asset-protection mechanism (high
# year-1 exploration → much to lose at year 2 → less bold +
# less aggressive), a positive boldness–aggressiveness syndrome
# evolves as a cross-context correlation across agents.
#
# Single-seed test in tests/testthat/test-personality-syndrome.R
# asserts only that |cor(bold, aggro)| >= 0.05 at seed 42.
# This script upgrades the audit to 8-seed regression baseline
# with explicit reporting of all three Wolf 2007 correlations
# (the syndrome + the two asset-protection gradients).
#
# Run via:
#   Rscript dev/audit/fidelity/paper_wolf2007.R
# Requires a healthy Julia + Clade.jl installation. Wall-clock
# estimate: ~20-25 min (8 seeds × 5000 ticks per run, no sweep —
# we just want the per-seed correlation pattern at the default
# Wolf preset).

suppressPackageStartupMessages({
  if (requireNamespace("devtools", quietly = TRUE))
    devtools::load_all(quiet = TRUE)
  else
    library(clade)
})

# Use the preset directly — Wolf's basic-model parameters.
# Per-strategy (1+α·N_i) denominator at α=0.005 (Phase 6 default).
base <- wolf_personality_specs()
base$max_ticks    <- 5000L      # ~50 generations at year2_repro_age = 100
base$n_agents_init <- 200L      # higher density → more hawk-dove + antipred encounters

# Single condition × 8 seeds. The "sweep" is over seeds only.
spec_list <- lapply(1:8, function(sd) {
  s <- base
  s$random_seed <- as.integer(sd)
  s
})
names(spec_list) <- paste0("seed", 1:8)

cat("=== Wolf 2007: personality-syndrome 8-seed reproduction ===\n")
cat(sprintf("Seeds: 1..8\nTicks per run: %d\nTotal runs: %d\n",
            base$max_ticks, length(spec_list)))

cat("Running 8 simulations (this takes ~15-25 min serial)...\n")
t_start <- Sys.time()
# n_cores = 1L: serial via lapply, no PSOCK workers (which require
# `library(clade)` available globally — works only if clade is
# installed, not when using devtools::load_all()).
envs <- batch_alife(spec_list, n_cores = 1L, verbose = FALSE)
elapsed <- difftime(Sys.time(), t_start, units = "mins")
cat(sprintf("Done. Elapsed: %.1f min.\n", as.numeric(elapsed)))

# Extract end-of-run trait correlations per seed.
# Wolf 2007's three predictions:
#   cor(bold, aggro)  > 0   ← the defining syndrome (strongest)
#   cor(exp,  bold)   < 0   ← asset-protection
#   cor(exp,  aggro)  < 0   ← asset-protection
.trait_cors <- function(env) {
  recs  <- env$agents
  if (is.null(recs) || length(recs) == 0L) return(c(NA_real_, NA_real_, NA_real_, NA_integer_))
  alive <- vapply(seq_along(recs),
                  function(i) as.logical(recs[[i]]$alive),
                  logical(1L))
  if (sum(alive) < 10L) return(c(NA_real_, NA_real_, NA_real_, as.integer(sum(alive))))
  idx <- which(alive)
  get_trait <- function(nm) vapply(idx, function(i) as.numeric(recs[[i]][[nm]]),
                                   numeric(1L))
  exp_v   <- get_trait("exploration")
  bold_v  <- get_trait("boldness")
  aggro_v <- get_trait("aggressiveness")
  c(cor_bold_aggro = cor(bold_v, aggro_v, use = "complete.obs"),
    cor_exp_bold   = cor(exp_v,  bold_v,  use = "complete.obs"),
    cor_exp_aggro  = cor(exp_v,  aggro_v, use = "complete.obs"),
    n_alive        = as.integer(sum(alive)))
}

per_seed <- do.call(rbind, lapply(envs, .trait_cors))
rownames(per_seed) <- paste0("seed", 1:8)

cat("\n=== Per-seed correlations + n_alive ===\n")
print(round(per_seed, 4))

# Mean ± SE across seeds
agg <- data.frame(
  correlation = c("cor(bold, aggro)", "cor(exp, bold)", "cor(exp, aggro)"),
  predicted   = c("> 0 (syndrome)", "< 0 (asset-protection)", "< 0 (asset-protection)"),
  mean = c(mean(per_seed[, 1], na.rm = TRUE),
           mean(per_seed[, 2], na.rm = TRUE),
           mean(per_seed[, 3], na.rm = TRUE)),
  se   = c(sd(per_seed[, 1], na.rm = TRUE) / sqrt(sum(!is.na(per_seed[, 1]))),
           sd(per_seed[, 2], na.rm = TRUE) / sqrt(sum(!is.na(per_seed[, 2]))),
           sd(per_seed[, 3], na.rm = TRUE) / sqrt(sum(!is.na(per_seed[, 3])))),
  stringsAsFactors = FALSE
)
agg$t       <- agg$mean / agg$se
agg$verdict <- ifelse(abs(agg$t) >= 2,   "PASS",
              ifelse(abs(agg$t) >= 1.5, "marginal", "null"))

cat("\n=== Mean ± SE across 8 seeds ===\n")
print(agg, row.names = FALSE, digits = 3)

saveRDS(list(per_seed_correlations = per_seed,
             aggregate             = agg,
             base_specs            = base,
             elapsed_min           = as.numeric(elapsed)),
        "dev/audit/fidelity/paper_wolf2007.rds")
cat("\nSaved: dev/audit/fidelity/paper_wolf2007.rds\n")
