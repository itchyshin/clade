# Baldwin deeper lift v1: bnn_sigma_lr_scale. Couples BNN effective
# learning rate to sigma — canalised agents learn slowly, plastic
# agents learn fast. Should preserve the exploration channel (sigma
# still drives action noise at bnn_action_noise_scale = 1) while
# creating a differential cost for carrying plasticity that only
# matters if you actually use it.
#
# Sweep: bnn_sigma_lr_scale ∈ {0.0, 0.3, 0.7, 1.0} × seasonal {0, 0.35}
# × 5 seeds. fast_specs settings, season_length = 10.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L)
SCALES <- c(0.0, 0.3, 0.7, 1.0)

.base <- function(seed) {
  s <- fast_specs()
  s$n_agents_init <- 180L
  s$max_agents    <- 800L
  s$grid_rows     <- 40L
  s$grid_cols     <- 40L
  s$grass_rate    <- 0.25
  s$random_seed   <- as.integer(seed)
  s
}

one_run <- function(amp, lr_scale, seed) {
  s <- .base(seed)
  s$brain_type                  <- "bnn"
  s$bnn_sigma_source            <- "trait"
  s$bnn_sigma_lr_scale          <- lr_scale
  s$bnn_sigma_lr_ref             <- 0.5
  s$brain_energy_sigma_scale    <- 0.05
  s$plasticity_init_mean        <- 0.5
  s$plasticity_mutation_sd      <- 0.05
  s$phenotypic_plasticity       <- TRUE
  s$seasonal_amplitude          <- amp
  s$season_length               <- 10L
  # Critical: the bnn_sigma_lr_scale mechanism only activates inside
  # bnn_update!, which is only called when rl_mode != "none". Enable
  # actor-critic learning so the Hinton-Nowlan scenario actually has
  # a within-life learning channel to modulate.
  s$rl_mode                     <- "actor_critic"
  s$rl_update_freq              <- 5L
  env <- suppressWarnings(run_alife(s, verbose = FALSE))
  d   <- get_run_data(env)$ticks
  sig <- if ("mean_prior_sigma" %in% names(d)) d$mean_prior_sigma
         else d$mean_plasticity
  vr  <- viability_report(d, n_agents_init = s$n_agents_init)
  list(init = sig[1L], final = tail(sig, 1L),
       n_final = vr$n_final, verdict = vr$verdict)
}

t0 <- Sys.time()
message("=== Baldwin × bnn_sigma_lr_scale sweep ===")

res <- data.frame()
for (scale in SCALES) {
  for (amp in c(0.0, 0.35)) {
    for (sd in SEEDS) {
      r <- one_run(amp, scale, sd)
      cond <- if (amp > 0) "seasonal" else "stable"
      res <- rbind(res, data.frame(
        lr_scale = scale, cond = cond, seed = sd,
        init = r$init, final = r$final,
        delta = r$final - r$init,
        n_final = r$n_final, verdict = r$verdict))
      message(sprintf("  lr_scale=%.1f amp=%.2f seed=%2d → Δ=%+.3f n=%d (%s)",
                      scale, amp, sd, r$final - r$init, r$n_final, r$verdict))
    }
  }
}

message("\n── Summary per lr_scale ──")
for (scale in SCALES) {
  sub  <- res[res$lr_scale == scale, ]
  stab <- sub[sub$cond == "stable", ]
  seas <- sub[sub$cond == "seasonal", ]
  # Hinton-Nowlan direction: seasonal > stable in final sigma
  p1 <- mean(seas$final) > mean(stab$final)
  dd <- mean(seas$delta) - mean(stab$delta)
  n_crashed <- sum(sub$verdict == "crashed")
  n_viable  <- sum(sub$verdict == "viable")
  message(sprintf(
    "  lr_scale=%.1f | stable Δ=%+.3f | seasonal Δ=%+.3f | Δdelta=%+.3f | P1 %s | viable=%d crashed=%d",
    scale, mean(stab$delta), mean(seas$delta), dd,
    if (p1) "PASS" else "FAIL", n_viable, n_crashed))
}

saveRDS(res, "dev/audit/fidelity/baldwin_sigma_lr_test.rds")
message(sprintf("\n=== Done in %.1f min ===",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))
