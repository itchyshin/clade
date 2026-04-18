# s-plasticity re-audit at realistic scale.
#
# Previous audit: sigma-coupling kernel limitation makes the
# DeWitt & Scheiner 2004 prediction (seasonal envs select higher
# plasticity than stable envs) marginal at 8 seeds.
# At realistic scale, 66 generations with an explicit seasonal
# environment may lift the magnitude.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L)

build_spec <- function(env_type, seed) {
  s <- realistic_specs()
  s$phenotypic_plasticity   <- TRUE
  s$plasticity_evolution    <- TRUE
  s$plasticity_mutation_sd  <- 0.05
  # --- BNN sigma decoupling (priority-1 activation, light) ---
  # Light decoupling: action noise 0.7*sigma (mostly legacy),
  # sigma-lr at 0.3 (a gentle lift for plastic agents). Slower RL
  # (lr=0.005, update every 5 ticks) keeps populations viable even
  # under seasonal perturbation.
  s$bnn_action_noise_scale  <- 0.7
  s$bnn_sigma_lr_scale      <- 0.3
  s$bnn_sigma_lr_ref        <- 0.5
  s$bnn_sample_freq         <- 5L
  s$rl_mode                 <- "actor_critic"
  s$rl_update_freq          <- 5L
  s$learning_rate_init_mean <- 0.005
  if (env_type == "seasonal") {
    s$seasonal_amplitude <- 0.5   # gentler than 0.8 to avoid crash
    s$season_length      <- 50L
  }
  s$random_seed <- as.integer(seed)
  s
}

specs_list <- c(
  lapply(SEEDS, function(sd) build_spec("stable",   sd)),
  lapply(SEEDS, function(sd) build_spec("seasonal", sd))
)
conditions <- c(rep("stable", length(SEEDS)), rep("seasonal", length(SEEDS)))

message(sprintf("Running %d specs (2 envs x 8 seeds) at realistic scale...",
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
  delta_col <- if ("mean_plasticity" %in% names(d)) "mean_plasticity"
               else if ("mean_plasticity_delta" %in% names(d)) "mean_plasticity_delta"
               else                                        NA_character_
  data.frame(
    condition    = conditions[i],
    seed         = specs_list[[i]]$random_seed,
    verdict      = via$verdict,
    mean_delta   = if (is.na(delta_col)) NA_real_ else mean(d[[delta_col]][keep], na.rm = TRUE),
    n_agents     = mean(d$n_agents[keep], na.rm = TRUE)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/plasticity_realistic.rds")

viable <- tbl[tbl$verdict != "crashed" & !is.na(tbl$mean_delta), ]
message("\n── Per-condition summary (viable) ──")
for (cnd in c("stable", "seasonal")) {
  sub <- viable[viable$condition == cnd, ]
  message(sprintf("  %-8s n=%d | delta=%.4f \u00b1 %.4f | pop=%.1f",
                  cnd, nrow(sub),
                  mean(sub$mean_delta), sd(sub$mean_delta) / max(1, sqrt(nrow(sub))),
                  mean(sub$n_agents)))
}
seas <- viable[viable$condition == "seasonal", ]
stab <- viable[viable$condition == "stable",   ]
if (nrow(seas) >= 2L && nrow(stab) >= 2L) {
  d_ <- mean(seas$mean_delta) - mean(stab$mean_delta)
  se <- sqrt(var(seas$mean_delta) / nrow(seas) + var(stab$mean_delta) / nrow(stab))
  t_ <- d_ / se
  v <- if (!is.finite(t_)) "NA" else if (abs(t_) >= 2) "PASS" else "recheck"
  message(sprintf("  \u0394(seasonal - stable) = %+7.4f \u00b1 %.4f   t = %+5.2f   %s",
                  d_, se, t_, v))
}
