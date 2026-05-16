# Trivers (1971) reciprocal-altruism multi-seed fidelity reproduction
# "The Evolution of Reciprocal Altruism", Quarterly Review of Biology 46(1):35-57
#
# Core claim: cooperation evolves when partners can re-encounter
# (Trivers' condition 2: low dispersal). The sweep below maps the
# regime boundary across dispersal rates and verifies the
# direction at 8 seeds per cell.
#
# Single-seed test in tests/testthat/test-reciprocal-altruism.R
# asserts only that cooperation rises by Δ > 0.05 at seed 42.
# This script upgrades the audit to multi-seed regression baseline.
#
# Run via:
#   Rscript dev/audit/fidelity/paper_trivers1971.R
# Requires a healthy Julia + Clade.jl installation. Wall-clock
# estimate: ~15-20 min total (8 seeds × 4 conditions × 5000 ticks).

suppressPackageStartupMessages({
  if (requireNamespace("devtools", quietly = TRUE))
    devtools::load_all(quiet = TRUE)
  else
    library(clade)
})

# Trivers' two-condition lever: dispersal_init_mean.
# Low dispersal → partners stay nearby → high re-encounter →
# cooperation favoured. High dispersal → mean-field-like mixing
# → cooperation breaks down (no benefit to recognising partners).
#
# Base preset already sets reciprocal_altruism = TRUE, max_age = 500,
# n_agents_init = 200, ploidy = 1 (haploid for clean trait dynamics).
base <- trivers_reciprocity_specs()
# Enable dispersal evolution so we can fix it per condition.
base$dispersal_evolution     <- TRUE
base$dispersal_mutation_sd   <- 0.0   # freeze at the init value per condition
base$max_ticks               <- 5000L # ~10 lifetimes at max_age = 500

DISPERSAL_RATES <- c(none = 0.0, low = 0.05, mid = 0.15, high = 0.30)

conds <- setNames(
  lapply(DISPERSAL_RATES, function(r) list(dispersal_init_mean = r)),
  names(DISPERSAL_RATES)
)

cat("=== Trivers 1971: reciprocal-altruism dispersal sweep ===\n")
cat(sprintf("Conditions: %d (dispersal_init_mean = %s)\n",
            length(conds), paste(DISPERSAL_RATES, collapse = ", ")))
cat(sprintf("Seeds per condition: 8\nTotal runs: %d\n",
            length(conds) * 8L))

# Metric: mean of reciprocity_initial trait across surviving agents
# at end of run. "Initial cooperation" — tendency to cooperate first,
# before knowing the partner — is the canonical Trivers signature.
.mean_initial_coop <- function(env) {
  recs  <- env$agents
  if (is.null(recs) || length(recs) == 0L) return(NA_real_)
  alive <- vapply(seq_along(recs),
                  function(i) as.logical(recs[[i]]$alive),
                  logical(1L))
  if (sum(alive) < 5L) return(NA_real_)
  mean(vapply(seq_along(recs)[alive],
              function(i) as.numeric(recs[[i]]$reciprocity_initial),
              numeric(1L)))
}

# Because the metric needs the env (not just ticks), we run via
# batch_seeds directly rather than hypothesis_sweep's tick-only
# metric path. Build the spec list explicitly.
spec_list <- list()
for (cname in names(conds)) {
  overrides <- conds[[cname]]
  for (sd in 1:8) {
    spec <- base
    for (pname in names(overrides)) spec[[pname]] <- overrides[[pname]]
    spec$random_seed <- as.integer(sd)
    key <- paste0(cname, "_seed", sd)
    spec_list[[key]] <- spec
  }
}

cat("Running 32 simulations (this takes ~25-40 min serial)...\n")
t_start <- Sys.time()
# n_cores = 1L: serial via lapply, no PSOCK workers (which require
# `library(clade)` available globally — works only if clade is
# installed, not when using devtools::load_all()).
envs <- batch_alife(spec_list, n_cores = 1L, verbose = FALSE)
elapsed <- difftime(Sys.time(), t_start, units = "mins")
cat(sprintf("Done. Elapsed: %.1f min.\n", as.numeric(elapsed)))

# Per-run metric extraction
meta <- expand.grid(seed = 1:8, condition = names(conds),
                    stringsAsFactors = FALSE)[, c("condition", "seed")]
meta$mean_initial_coop <- vapply(seq_along(envs),
                                 function(i) .mean_initial_coop(envs[[i]]),
                                 numeric(1L))
meta$n_final <- vapply(seq_along(envs),
                       function(i) tail(envs[[i]]$progress$n_agents, 1L),
                       integer(1L))

cat("\n=== Per-condition mean ± SE (mean_initial_coop) ===\n")
agg <- do.call(rbind, lapply(names(conds), function(cn) {
  vals <- meta$mean_initial_coop[meta$condition == cn & !is.na(meta$mean_initial_coop)]
  data.frame(condition = cn,
             dispersal = DISPERSAL_RATES[cn],
             n_seeds   = length(vals),
             mean      = if (length(vals)) mean(vals) else NA_real_,
             se        = if (length(vals) > 1L) sd(vals) / sqrt(length(vals)) else NA_real_,
             stringsAsFactors = FALSE)
}))
print(agg, row.names = FALSE)

# Spearman: lower dispersal → higher initial cooperation
sp <- cor(DISPERSAL_RATES[meta$condition],
          meta$mean_initial_coop,
          method = "spearman", use = "complete.obs")
cat(sprintf("\nSpearman(dispersal, mean_initial_coop) = %+.3f\n", sp))
cat("Trivers predicts: NEGATIVE (low dispersal → high cooperation).\n")

# Contrast: none-dispersal vs high-dispersal
ref  <- meta$mean_initial_coop[meta$condition == "none" & !is.na(meta$mean_initial_coop)]
test <- meta$mean_initial_coop[meta$condition == "high" & !is.na(meta$mean_initial_coop)]
delta <- mean(test, na.rm = TRUE) - mean(ref, na.rm = TRUE)
se <- if (length(ref) > 1L && length(test) > 1L) {
  sqrt(var(test) / length(test) + var(ref) / length(ref))
} else NA_real_
tval <- if (!is.na(se) && se > 0) delta / se else NA_real_
cat(sprintf("\nContrast high − none: Δ = %+.4f ± %.4f, t = %+.2f\n",
            delta, se, tval))

saveRDS(list(runs           = meta,
             dispersal_rates = DISPERSAL_RATES,
             aggregate      = agg,
             spearman       = sp,
             contrast       = list(delta = delta, se = se, t = tval),
             elapsed        = as.numeric(elapsed)),
        "dev/audit/fidelity/paper_trivers1971.rds")
cat("\nSaved: dev/audit/fidelity/paper_trivers1971.rds\n")
