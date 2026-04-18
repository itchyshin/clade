# s-plasticity audit with the CORRECT metric.
#
# Prior audits measured mean_plasticity (the scalar plasticity trait)
# which — under default bnn_sigma_source = "heterozygosity" — is a
# neutral genomic marker with no phenotypic effect. That gave Δ ≈ 0
# by construction.
#
# The quantity Hinton & Nowlan's Baldwin-effect prediction actually
# addresses is BNN POSTERIOR SIGMA. Under "heterozygosity" mode,
# sigma at each weight = |maternal_weight − paternal_weight| / 2.
# Selection at the brain-weight level (not on any scalar trait)
# canalizes sigma down in stable envs; seasonal envs should keep
# sigma high.
#
# Metric: mean_prior_sigma (population mean of BNN posterior sigma,
# averaged across weights). Already logged — we were just reading
# the wrong column.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L,
           51L, 57L, 63L, 71L, 79L, 89L, 101L, 107L)

build_spec <- function(env_type, seed) {
  s <- realistic_specs()
  # Enable self-fertilization fallback (0.5.9) so mate-finding failure
  # on the sparse 60x60 grid doesn't silently convert diploid offspring
  # to effectively-haploid (which pegs sigma at bnn_sigma_init). With
  # selfing = TRUE, the second gamete is drawn from parent1, preserving
  # diploidy and letting sigma evolve from real heterozygosity.
  s$self_fertilization_fallback <- TRUE
  if (env_type == "seasonal") {
    s$seasonal_amplitude <- 0.3   # mild perturbation; selfing reduces resilience
    s$season_length      <- 100L  # longer seasons → less churn
  }
  s$random_seed <- as.integer(seed)
  s
}

specs_list <- c(
  lapply(SEEDS, function(sd) build_spec("stable",   sd)),
  lapply(SEEDS, function(sd) build_spec("seasonal", sd))
)
conditions <- c(rep("stable", length(SEEDS)), rep("seasonal", length(SEEDS)))

message(sprintf("Running %d specs (2 envs x 16 seeds) at realistic scale...",
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
  sigma_col <- if ("mean_prior_sigma" %in% names(d)) "mean_prior_sigma"
               else NA_character_
  data.frame(
    condition         = conditions[i],
    seed              = specs_list[[i]]$random_seed,
    verdict           = via$verdict,
    mean_prior_sigma  = if (is.na(sigma_col)) NA_real_
                        else mean(d[[sigma_col]][keep], na.rm = TRUE),
    n_agents          = mean(d$n_agents[keep], na.rm = TRUE)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/plasticity_sigma.rds")

# Selfing keeps populations small (~35 agents at equilibrium → "weak"
# verdict from viability_report). Include weak runs: mean_prior_sigma
# is a trait-mean, interpretable for populations ≥ 20.
viable <- tbl[tbl$verdict != "crashed" & !is.na(tbl$mean_prior_sigma) & tbl$n_agents >= 20, ]
message("\n── Per-condition summary (viable) ──")
for (cnd in c("stable", "seasonal")) {
  sub <- viable[viable$condition == cnd, ]
  message(sprintf("  %-8s n=%d | mean_prior_sigma=%.4f \u00b1 %.4f | pop=%.1f",
                  cnd, nrow(sub),
                  mean(sub$mean_prior_sigma),
                  sd(sub$mean_prior_sigma) / max(1, sqrt(nrow(sub))),
                  mean(sub$n_agents)))
}
seas <- viable[viable$condition == "seasonal", ]
stab <- viable[viable$condition == "stable",   ]
if (nrow(seas) >= 2L && nrow(stab) >= 2L) {
  d_ <- mean(seas$mean_prior_sigma) - mean(stab$mean_prior_sigma)
  se <- sqrt(var(seas$mean_prior_sigma) / nrow(seas) +
             var(stab$mean_prior_sigma) / nrow(stab))
  t_ <- d_ / se
  v <- if (!is.finite(t_)) "NA"
       else if (d_ > 0 && abs(t_) >= 2) "PASS \u2014 seasonal > stable (plasticity maintained)"
       else if (abs(t_) >= 2)           "PASS (wrong direction)"
       else                              "recheck"
  message(sprintf("  \u0394(seasonal - stable) = %+7.4f \u00b1 %.4f   t = %+5.2f   %s",
                  d_, se, t_, v))
}
