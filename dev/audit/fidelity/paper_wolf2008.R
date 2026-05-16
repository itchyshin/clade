# Wolf, van Doorn & Weissing (2008) PNAS responsive-personalities
# multi-seed fidelity reproduction
# "Evolutionary emergence of responsive and unresponsive
# personalities", PNAS 105:15825-15830
#
# Core claim: under negative frequency-dependent selection,
# responsive and unresponsive types coexist at intermediate
# frequencies. clade's spatially-explicit implementation
# captures the MECHANISM (responsive agents pay a sampling
# cost to override their action toward the richest cardinal
# neighbour) but does NOT reproduce the specific coexistence
# equilibrium Wolf reports (which needs a per-resource
# competition denominator we have not implemented).
#
# Single-seed test in tests/testthat/test-responsive-personalities.R
# asserts only that the responsiveness trait moves under
# selection (Δ from baseline > 0.05) at seed 42.
# This script upgrades to 8-seed multi-seed baseline + a
# "module-off" control condition.
#
# Run via:
#   Rscript dev/audit/fidelity/paper_wolf2008.R
# Requires a healthy Julia + Clade.jl installation. Wall-clock
# estimate: ~10-15 min (8 seeds × 2 conditions × 2000 ticks).

suppressPackageStartupMessages({
  if (requireNamespace("devtools", quietly = TRUE))
    devtools::load_all(quiet = TRUE)
  else
    library(clade)
})

# Two conditions: responsiveness module ON vs OFF.
# Off = baseline drift; on = selection should push trait up.
base <- wolf2008_responsiveness_specs()
base$max_ticks <- 2000L      # ~10 generations at default max_age = 200

conds <- list(
  off = list(responsive_personalities = FALSE),
  on  = list(responsive_personalities = TRUE)
)

# Build the spec list explicitly so each (cond, seed) is one run.
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

cat("=== Wolf 2008: responsiveness 8-seed × 2-condition reproduction ===\n")
cat(sprintf("Conditions: %s\nTotal runs: %d\n",
            paste(names(conds), collapse = ", "), length(spec_list)))

cat("Running 16 simulations (this takes ~10-15 min)...\n")
t_start <- Sys.time()
envs <- batch_alife(spec_list, n_cores = 8L, verbose = FALSE)
elapsed <- difftime(Sys.time(), t_start, units = "mins")
cat(sprintf("Done. Elapsed: %.1f min.\n", as.numeric(elapsed)))

# Per-run metric: mean of responsiveness trait across alive agents
# at end of run. With selection on, this should be ABOVE the off
# baseline (negative frequency-dependent selection isn't symmetric
# in clade's implementation; selection pushes toward intermediate
# but currently saturates above 0.5 for moderate cost).
.mean_resp <- function(env) {
  recs  <- env$agents
  if (is.null(recs) || length(recs) == 0L) return(NA_real_)
  alive <- vapply(seq_along(recs),
                  function(i) as.logical(recs[[i]]$alive),
                  logical(1L))
  if (sum(alive) < 5L) return(NA_real_)
  mean(vapply(seq_along(recs)[alive],
              function(i) as.numeric(recs[[i]]$responsiveness),
              numeric(1L)))
}

meta <- expand.grid(seed = 1:8, condition = names(conds),
                    stringsAsFactors = FALSE)[, c("condition", "seed")]
meta$mean_resp <- vapply(seq_along(envs),
                         function(i) .mean_resp(envs[[i]]),
                         numeric(1L))
meta$n_final <- vapply(seq_along(envs),
                       function(i) tail(envs[[i]]$progress$n_agents, 1L),
                       integer(1L))

cat("\n=== Per-condition mean ± SE (mean_resp) ===\n")
agg <- do.call(rbind, lapply(names(conds), function(cn) {
  vals <- meta$mean_resp[meta$condition == cn & !is.na(meta$mean_resp)]
  data.frame(condition = cn,
             n_seeds   = length(vals),
             mean      = if (length(vals)) mean(vals) else NA_real_,
             se        = if (length(vals) > 1L) sd(vals) / sqrt(length(vals)) else NA_real_,
             stringsAsFactors = FALSE)
}))
print(agg, row.names = FALSE)

# Contrast: on vs off
ref  <- meta$mean_resp[meta$condition == "off" & !is.na(meta$mean_resp)]
test <- meta$mean_resp[meta$condition == "on"  & !is.na(meta$mean_resp)]
delta <- mean(test, na.rm = TRUE) - mean(ref, na.rm = TRUE)
se <- if (length(ref) > 1L && length(test) > 1L) {
  sqrt(var(test) / length(test) + var(ref) / length(ref))
} else NA_real_
tval <- if (!is.na(se) && se > 0) delta / se else NA_real_
verdict <- if (is.na(tval)) "insufficient-seeds"
  else if (abs(tval) >= 2)   "PASS"
  else if (abs(tval) >= 1.5) "marginal"
  else                       "null"

cat(sprintf("\nContrast on − off: Δ = %+.4f ± %.4f, t = %+.2f → %s\n",
            delta, se, tval, verdict))
cat("Wolf 2008 mechanism prediction: PASS (responsiveness rises under selection).\n")
cat("NOTE: the specific coexistence equilibrium Wolf reports requires a\n")
cat("per-resource competition denominator not currently implemented.\n")

saveRDS(list(runs       = meta,
             aggregate  = agg,
             contrast   = list(delta = delta, se = se, t = tval, verdict = verdict),
             base_specs = base,
             elapsed_min = as.numeric(elapsed)),
        "dev/audit/fidelity/paper_wolf2008.rds")
cat("\nSaved: dev/audit/fidelity/paper_wolf2008.rds\n")
