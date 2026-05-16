# Massol & Crochet (2008) Nature 451 critique of Wolf 2007 —
# multi-seed fidelity reproduction
# "Do animal personalities emerge?", Nature 451 (Brief Communications
# Arising). doi:10.1038/nature06744
#
# Core critique: Wolf 2007's bold-aggro syndrome depends critically on
# the trade-off curve shape parameter β. Massol & Crochet argue β = 1
# (linear) is more biologically defensible than Wolf's chosen β = 1.25.
# clade exposes β as `personality_beta` so the sweep is a one-knob
# probe of the critique.
#
# Single-seed observation in the vignette (seed 42, 5000 ticks):
# bold-aggro varies by ~0.39 in correlation units across
# β ∈ {0.5, 1.0, 1.25, 2.0, 3.0}, peaking at +0.307 at Wolf's
# published β = 1.25.
#
# This script upgrades to 8-seed regression baseline. Important
# context: PR #138 found the single-condition Wolf 2007 syndrome is
# null at 8 seeds. The β sweep here probes whether any β value
# produces a robust positive syndrome across seeds, or whether the
# single-seed peak at β = 1.25 was a noise-envelope landing.
#
# Run via:
#   Rscript dev/audit/fidelity/paper_massol_crochet_2008.R
# Wall-clock estimate: ~20-25 min (5 β values × 8 seeds × 5000 ticks
# = 40 runs, serial via n_cores = 1L).

suppressPackageStartupMessages({
  if (requireNamespace("devtools", quietly = TRUE))
    devtools::load_all(quiet = TRUE)
  else
    library(clade)
})

# Base preset + the vignette's specific overrides for the syndrome
# scenario (more agents + higher hawkdove rate to give the syndrome
# the best chance of expressing).
base <- wolf_personality_specs()
base$max_ticks                       <- 5000L
base$n_agents_init                   <- 200L
base$max_agents                      <- 800L
base$personality_hawkdove_per_tick   <- 0.3
base$personality_hawkdove_radius     <- 2L
base$n_predators_init                <- 10L
base$predator_max_agents             <- 30L

BETA_VALUES <- c(b0p5 = 0.5, b1p0 = 1.0, b1p25 = 1.25, b2p0 = 2.0, b3p0 = 3.0)

# Build the spec list: 5 betas × 8 seeds = 40 runs.
spec_list <- list()
for (cname in names(BETA_VALUES)) {
  beta_val <- BETA_VALUES[cname]
  for (sd in 1:8) {
    spec <- base
    spec$personality_beta <- beta_val
    spec$random_seed      <- as.integer(sd)
    key <- paste0(cname, "_seed", sd)
    spec_list[[key]] <- spec
  }
}

cat("=== Massol & Crochet 2008: β sweep × 8 seeds ===\n")
cat(sprintf("β values: %s\nSeeds per β: 8\nTotal runs: %d\n",
            paste(BETA_VALUES, collapse = ", "), length(spec_list)))

cat("Running 40 simulations (~20-25 min serial)...\n")
t_start <- Sys.time()
envs <- batch_alife(spec_list, n_cores = 1L, verbose = FALSE)
elapsed <- difftime(Sys.time(), t_start, units = "mins")
cat(sprintf("Done. Elapsed: %.1f min.\n", as.numeric(elapsed)))

# Per-run metric: three Wolf 2007 trait correlations.
.trait_cors <- function(env) {
  recs  <- env$agents
  if (is.null(recs) || length(recs) == 0L) return(c(NA_real_, NA_real_, NA_real_, NA_integer_))
  alive <- vapply(seq_along(recs),
                  function(i) as.logical(recs[[i]]$alive),
                  logical(1L))
  if (sum(alive) < 30L) return(c(NA_real_, NA_real_, NA_real_, as.integer(sum(alive))))
  idx <- which(alive)
  get_trait <- function(nm) vapply(idx, function(i) as.numeric(recs[[i]][[nm]]),
                                   numeric(1L))
  exp_v   <- get_trait("exploration")
  bold_v  <- get_trait("boldness")
  aggro_v <- get_trait("aggressiveness")
  c(cor_bold_aggro = suppressWarnings(cor(bold_v, aggro_v, use = "complete.obs")),
    cor_exp_bold   = suppressWarnings(cor(exp_v,  bold_v,  use = "complete.obs")),
    cor_exp_aggro  = suppressWarnings(cor(exp_v,  aggro_v, use = "complete.obs")),
    n_alive        = as.integer(sum(alive)))
}

per_run <- do.call(rbind, lapply(envs, .trait_cors))
meta <- expand.grid(seed = 1:8, condition = names(BETA_VALUES),
                    stringsAsFactors = FALSE)[, c("condition", "seed")]
meta$beta <- BETA_VALUES[meta$condition]
meta <- cbind(meta, per_run)

cat("\n=== Per-run correlations (40 runs) ===\n")
print(meta[, c("condition", "beta", "seed",
               "cor_bold_aggro", "cor_exp_bold", "cor_exp_aggro",
               "n_alive")],
      row.names = FALSE, digits = 3)

# Aggregate per β: mean ± SE for each of the three correlations
.agg <- function(metric) {
  do.call(rbind, lapply(names(BETA_VALUES), function(cn) {
    vals <- meta[[metric]][meta$condition == cn & !is.na(meta[[metric]])]
    data.frame(condition = cn,
               beta      = BETA_VALUES[cn],
               n_seeds   = length(vals),
               mean      = if (length(vals)) mean(vals) else NA_real_,
               se        = if (length(vals) > 1L) sd(vals) / sqrt(length(vals)) else NA_real_,
               stringsAsFactors = FALSE)
  }))
}
agg_bold_aggro <- .agg("cor_bold_aggro")
agg_exp_bold   <- .agg("cor_exp_bold")
agg_exp_aggro  <- .agg("cor_exp_aggro")

cat("\n=== cor(bold, aggro) by β (predicted > 0) ===\n")
print(agg_bold_aggro, row.names = FALSE)
cat("\n=== cor(exp, bold) by β (predicted < 0) ===\n")
print(agg_exp_bold, row.names = FALSE)
cat("\n=== cor(exp, aggro) by β (predicted < 0) ===\n")
print(agg_exp_aggro, row.names = FALSE)

# Does any β produce a 2σ-PASS bold-aggro syndrome?
agg_bold_aggro$t <- agg_bold_aggro$mean / agg_bold_aggro$se
agg_bold_aggro$verdict <- ifelse(
  is.na(agg_bold_aggro$t), "insufficient-seeds",
  ifelse(abs(agg_bold_aggro$t) >= 2,   "PASS",
  ifelse(agg_bold_aggro$t >= 1.5,      "marginal-positive",
  ifelse(agg_bold_aggro$t <= -1.5,     "marginal-negative",
                                       "null"))))
cat("\n=== Bold-aggro verdict per β (2σ ladder) ===\n")
print(agg_bold_aggro, row.names = FALSE, digits = 3)

# Range of mean bold-aggro across β
br <- range(agg_bold_aggro$mean, na.rm = TRUE)
cat(sprintf("\nBold-aggro range across β: [%+.3f, %+.3f] (Δ = %.3f)\n",
            br[1], br[2], diff(br)))
cat("Massol & Crochet predict: range should be large (β-sensitive).\n")
cat("clade single-seed result: Δ = 0.39 across the sweep.\n")

saveRDS(list(runs               = meta,
             beta_values        = BETA_VALUES,
             agg_bold_aggro     = agg_bold_aggro,
             agg_exp_bold       = agg_exp_bold,
             agg_exp_aggro      = agg_exp_aggro,
             bold_aggro_range   = br,
             elapsed_min        = as.numeric(elapsed)),
        "dev/audit/fidelity/paper_massol_crochet_2008.rds")
cat("\nSaved: dev/audit/fidelity/paper_massol_crochet_2008.rds\n")
