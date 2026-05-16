# McElreath 2007 16-seed verification of the surprise PASS-negative
# at 2000 ticks (cor(exp, aggro) = -0.172 +/- 0.042, t = -4.12 at 8 seeds).
#
# Hypothesis: this signal survives at 16 seeds with tightened SE.
# If yes, it's the only robust positive finding across the three Wolf
# 2007 reproductions and worth flagging as a real candidate for
# Sergio's v0.8-core review.
#
# Run via: Rscript /tmp/mcelreath_16seed.R
# Wall-clock estimate: ~45-50 min (2x the 8-seed run = ~48 min serial).

suppressPackageStartupMessages({
  if (requireNamespace("devtools", quietly = TRUE))
    devtools::load_all(quiet = TRUE)
  else
    library(clade)
})

base <- wolf_personality_specs()
base$n_agents_init                   <- 200L
base$max_agents                      <- 800L
base$personality_hawkdove_per_tick   <- 0.3
base$personality_hawkdove_radius     <- 2L
base$n_predators_init                <- 10L
base$predator_max_agents             <- 30L

# Only the 2000-tick horizon (where the surprise PASS-negative landed).
# Skip 5000 and 15000 — they were null at 8 seeds, no reason to expect
# they harden at 16 seeds.
spec_list <- list()
for (sd in 1:16) {
  spec <- base
  spec$max_ticks    <- 2000L
  spec$random_seed  <- as.integer(sd)
  key <- paste0("seed", sd)
  spec_list[[key]] <- spec
}

cat("=== McElreath 16-seed verification: cor(exp, aggro) at 2000 ticks ===\n")
cat(sprintf("Seeds: 1..16\nTicks per run: %d\nTotal runs: %d\n",
            2000L, length(spec_list)))

cat("Running 16 simulations (~25-30 min serial)...\n")
t_start <- Sys.time()
envs <- batch_alife(spec_list, n_cores = 1L, verbose = FALSE)
elapsed <- difftime(Sys.time(), t_start, units = "mins")
cat(sprintf("Done. Elapsed: %.1f min.\n", as.numeric(elapsed)))

.trait_summary <- function(env) {
  recs  <- env$agents
  if (is.null(recs) || length(recs) == 0L) {
    return(c(NA_real_, NA_real_, NA_real_, NA_integer_))
  }
  alive <- vapply(seq_along(recs),
                  function(i) as.logical(recs[[i]]$alive),
                  logical(1L))
  if (sum(alive) < 30L) {
    return(c(NA_real_, NA_real_, NA_real_, as.integer(sum(alive))))
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
    n_alive        = as.integer(sum(alive)))
}

per_run <- do.call(rbind, lapply(envs, .trait_summary))
rownames(per_run) <- paste0("seed", 1:16)

cat("\n=== Per-seed correlations + n_alive ===\n")
print(round(per_run, 4))

# Aggregate
cor_ea <- per_run[, "cor_exp_aggro"]
ok     <- !is.na(cor_ea)
n      <- sum(ok)
mn     <- mean(cor_ea[ok])
se     <- sd(cor_ea[ok]) / sqrt(n)
tval   <- mn / se
verdict <- if (abs(tval) >= 2) "PASS" else if (abs(tval) >= 1.5) "marginal" else "null"

cat(sprintf("\n=== cor(exp, aggro) at 2000 ticks, 16 seeds ===\n"))
cat(sprintf("  n   = %d\n", n))
cat(sprintf("  mean= %+.4f\n", mn))
cat(sprintf("  SE  = %.4f\n", se))
cat(sprintf("  t   = %+.2f\n", tval))
cat(sprintf("  verdict (2σ) = %s\n", verdict))

cat("\n--- Comparison to 8-seed result (PR #141) ---\n")
cat(sprintf("  8-seed:  mean = -0.1716, SE = 0.0417, t = -4.12 (PASS-negative)\n"))
cat(sprintf("  16-seed: mean = %+.4f, SE = %.4f, t = %+.2f (%s)\n",
            mn, se, tval, verdict))

saveRDS(list(per_run       = per_run,
             cor_exp_aggro = list(mean = mn, se = se, t = tval, verdict = verdict),
             elapsed_min   = as.numeric(elapsed),
             max_ticks     = 2000L,
             n_seeds       = 16L,
             follow_up_to  = "PR #141 (McElreath 8-seed PASS-negative finding)"),
        "dev/audit/fidelity/paper_mcelreath_2007_16seed.rds")
cat("\nSaved: dev/audit/fidelity/paper_mcelreath_2007_16seed.rds\n")
