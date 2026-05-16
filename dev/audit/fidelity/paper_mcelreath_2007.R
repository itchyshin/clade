# McElreath, Luttbeg, Fogarty, Brodin & Sih (2007) Nature 450 critique
# of Wolf 2007 — multi-seed fidelity reproduction
# "Evolution of animal personalities", Nature 450 (Brief Communications
# Arising). doi:10.1038/nature06326
#
# Core critique: asset-protection is a negative-feedback mechanism
# that erodes individual differences over time. Wolf 2007's reported
# correlations are transient — they peak at ~50 generations (his
# simulation length) and decay at longer horizons.
#
# Single-seed observations in the vignette (seed 42):
#   2 000 ticks: bold-aggro = −0.004 (not yet established)
#   5 000 ticks: bold-aggro = +0.307 (peak; Wolf's reported value)
#  15 000 ticks: bold-aggro = +0.032 (decayed by order of magnitude)
#
# This script upgrades to 8-seed regression baseline. Important
# context: PR #138 found the 5000-tick single-condition Wolf 2007
# syndrome is null at 8 seeds. The horizon sweep here probes
# whether the "peak then decay" trajectory exists across seeds,
# or whether the single-seed +0.307 peak was a noise-envelope
# landing.
#
# Run via:
#   Rscript dev/audit/fidelity/paper_mcelreath_2007.R
# Wall-clock estimate: ~20-30 min (3 horizons × 8 seeds, serial).
# Cost is heavily weighted toward the 15000-tick cell:
# 8×(2k + 5k + 15k) = 176k tick-runs total.

suppressPackageStartupMessages({
  if (requireNamespace("devtools", quietly = TRUE))
    devtools::load_all(quiet = TRUE)
  else
    library(clade)
})

# Base preset + the vignette's specific overrides for the syndrome
# scenario (matches paper_wolf2007.R + paper_massol_crochet_2008.R).
base <- wolf_personality_specs()
base$n_agents_init                   <- 200L
base$max_agents                      <- 800L
base$personality_hawkdove_per_tick   <- 0.3
base$personality_hawkdove_radius     <- 2L
base$n_predators_init                <- 10L
base$predator_max_agents             <- 30L

HORIZONS <- c(short = 2000L, mid = 5000L, long = 15000L)

# Build the spec list: 3 horizons × 8 seeds = 24 runs.
spec_list <- list()
for (cname in names(HORIZONS)) {
  ticks_val <- HORIZONS[cname]
  for (sd in 1:8) {
    spec <- base
    spec$max_ticks    <- as.integer(ticks_val)
    spec$random_seed  <- as.integer(sd)
    key <- paste0(cname, "_seed", sd)
    spec_list[[key]] <- spec
  }
}

cat("=== McElreath et al. 2007: time-horizon sweep × 8 seeds ===\n")
cat(sprintf("Horizons (ticks): %s\nSeeds per horizon: 8\nTotal runs: %d\n",
            paste(HORIZONS, collapse = ", "), length(spec_list)))

cat("Running 24 simulations (~20-30 min serial; 15k-tick runs dominate)...\n")
t_start <- Sys.time()
envs <- batch_alife(spec_list, n_cores = 1L, verbose = FALSE)
elapsed <- difftime(Sys.time(), t_start, units = "mins")
cat(sprintf("Done. Elapsed: %.1f min.\n", as.numeric(elapsed)))

# Per-run metric: three Wolf 2007 trait correlations + mean(x), sd(x).
.trait_summary <- function(env) {
  recs  <- env$agents
  if (is.null(recs) || length(recs) == 0L) {
    return(c(NA_real_, NA_real_, NA_real_, NA_real_, NA_real_, NA_integer_))
  }
  alive <- vapply(seq_along(recs),
                  function(i) as.logical(recs[[i]]$alive),
                  logical(1L))
  if (sum(alive) < 30L) {
    return(c(NA_real_, NA_real_, NA_real_, NA_real_, NA_real_, as.integer(sum(alive))))
  }
  idx <- which(alive)
  get_trait <- function(nm) vapply(idx, function(i) as.numeric(recs[[i]][[nm]]),
                                   numeric(1L))
  exp_v   <- get_trait("exploration")
  bold_v  <- get_trait("boldness")
  aggro_v <- get_trait("aggressiveness")
  c(cor_bold_aggro = suppressWarnings(cor(bold_v, aggro_v, use = "complete.obs")),
    cor_exp_bold   = suppressWarnings(cor(exp_v,  bold_v,  use = "complete.obs")),
    cor_exp_aggro  = suppressWarnings(cor(exp_v,  aggro_v, use = "complete.obs")),
    mean_x         = mean(exp_v,  na.rm = TRUE),
    sd_x           = sd(exp_v,  na.rm = TRUE),
    n_alive        = as.integer(sum(alive)))
}

per_run <- do.call(rbind, lapply(envs, .trait_summary))
meta <- expand.grid(seed = 1:8, condition = names(HORIZONS),
                    stringsAsFactors = FALSE)[, c("condition", "seed")]
meta$max_ticks <- HORIZONS[meta$condition]
meta <- cbind(meta, per_run)

cat("\n=== Per-run trait summary (24 runs) ===\n")
print(meta[, c("condition", "max_ticks", "seed",
               "cor_bold_aggro", "cor_exp_bold", "cor_exp_aggro",
               "mean_x", "sd_x", "n_alive")],
      row.names = FALSE, digits = 3)

# Aggregate per horizon
.agg <- function(metric) {
  do.call(rbind, lapply(names(HORIZONS), function(cn) {
    vals <- meta[[metric]][meta$condition == cn & !is.na(meta[[metric]])]
    data.frame(condition = cn,
               max_ticks = HORIZONS[cn],
               n_seeds   = length(vals),
               mean      = if (length(vals)) mean(vals) else NA_real_,
               se        = if (length(vals) > 1L) sd(vals) / sqrt(length(vals)) else NA_real_,
               stringsAsFactors = FALSE)
  }))
}
agg_bold_aggro <- .agg("cor_bold_aggro")
agg_exp_bold   <- .agg("cor_exp_bold")
agg_exp_aggro  <- .agg("cor_exp_aggro")
agg_mean_x     <- .agg("mean_x")
agg_sd_x       <- .agg("sd_x")

cat("\n=== cor(bold, aggro) by max_ticks (McElreath: should peak then decay) ===\n")
print(agg_bold_aggro, row.names = FALSE, digits = 3)
cat("\n=== cor(exp, bold) by max_ticks (predicted < 0) ===\n")
print(agg_exp_bold, row.names = FALSE, digits = 3)
cat("\n=== cor(exp, aggro) by max_ticks (predicted < 0) ===\n")
print(agg_exp_aggro, row.names = FALSE, digits = 3)
cat("\n=== mean(exploration) by max_ticks (stability check) ===\n")
print(agg_mean_x, row.names = FALSE, digits = 3)
cat("\n=== sd(exploration) by max_ticks (variance stability) ===\n")
print(agg_sd_x, row.names = FALSE, digits = 3)

# Is the McElreath "peak then decay" pattern visible at 8 seeds?
peak  <- agg_bold_aggro$mean[agg_bold_aggro$condition == "mid"]
short <- agg_bold_aggro$mean[agg_bold_aggro$condition == "short"]
long  <- agg_bold_aggro$mean[agg_bold_aggro$condition == "long"]
cat(sprintf("\nBold-aggro: short=%+.3f → mid=%+.3f → long=%+.3f\n",
            short, peak, long))
cat("McElreath predicts: mid > short AND mid > long (transient peak).\n")
cat(sprintf("Peak-then-decay pattern visible? %s\n",
            if (!is.na(peak) && !is.na(short) && !is.na(long)
                && peak > short && peak > long) "YES" else "NO / WEAK"))

saveRDS(list(runs           = meta,
             horizons       = HORIZONS,
             agg_bold_aggro = agg_bold_aggro,
             agg_exp_bold   = agg_exp_bold,
             agg_exp_aggro  = agg_exp_aggro,
             agg_mean_x     = agg_mean_x,
             agg_sd_x       = agg_sd_x,
             elapsed_min    = as.numeric(elapsed)),
        "dev/audit/fidelity/paper_mcelreath_2007.rds")
cat("\nSaved: dev/audit/fidelity/paper_mcelreath_2007.rds\n")
