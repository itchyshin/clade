# Test the 0.5.5 `bnn_action_noise_scale` spec for s-baldwin.
#
# Infrastructure was added to the kernel in 0.5.5 but never used in the
# audit. At action_noise_scale = 0, sigma only affects learning/cost,
# not action sampling — the "pure learning cost" decoupling the 0.4.3
# plan-file item called for. If this decoupling works, Hinton-Nowlan
# canalisation (stable > seasonal sigma drop) should emerge.
#
# Sweep: bnn_action_noise_scale ∈ {1.0 legacy, 0.5, 0.0 decoupled} ×
# seasonal_amplitude ∈ {0.0, 0.35} × 5 seeds × 2000 ticks at fast_specs
# settings (season_length = 10, within-lifetime variability).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS   <- c(1L, 7L, 13L, 19L, 25L)
SCALES  <- c(1.0, 0.5, 0.0)

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

one_run <- function(amp, noise_scale, seed) {
  s <- .base(seed)
  s$brain_type               <- "bnn"
  s$bnn_sigma_source         <- "trait"
  s$bnn_action_noise_scale   <- noise_scale
  s$brain_energy_sigma_scale <- 0.05
  s$plasticity_init_mean     <- 0.5
  s$plasticity_mutation_sd   <- 0.05
  s$phenotypic_plasticity    <- TRUE
  s$seasonal_amplitude       <- amp
  s$season_length            <- 10L       # within-lifetime variability
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  sig <- if ("mean_prior_sigma" %in% names(d)) d$mean_prior_sigma
         else d$mean_plasticity
  vr  <- viability_report(d, n_agents_init = s$n_agents_init)
  list(init = sig[1L], final = tail(sig, 1L),
       n_final = vr$n_final, verdict = vr$verdict)
}

t0 <- Sys.time()
message("=== baldwin × bnn_action_noise_scale sweep ===")

res <- data.frame()
for (scale in SCALES) {
  for (amp in c(0.0, 0.35)) {
    for (sd in SEEDS) {
      r <- one_run(amp, scale, sd)
      cond <- if (amp > 0) "seasonal" else "stable"
      res <- rbind(res, data.frame(
        noise_scale = scale, cond = cond, seed = sd,
        init = r$init, final = r$final,
        delta = r$final - r$init,
        n_final = r$n_final, verdict = r$verdict))
      message(sprintf(
        "  noise=%.1f amp=%.2f seed=%2d → Δ=%+.3f n=%d (%s)",
        scale, amp, sd, r$final - r$init, r$n_final, r$verdict))
    }
  }
}

message("\n── Summary per noise_scale ──")
for (scale in SCALES) {
  sub  <- res[res$noise_scale == scale, ]
  stab <- sub[sub$cond == "stable", ]
  seas <- sub[sub$cond == "seasonal", ]
  # Hinton-Nowlan: stable canalises MORE (delta more negative),
  # seasonal preserves (delta less negative or positive).
  # Classical reading: seasonal > stable in final sigma.
  p1 <- mean(seas$final) > mean(stab$final)
  dd <- mean(seas$delta) - mean(stab$delta)
  n_crashed <- sum(sub$verdict == "crashed")
  message(sprintf(
    "  noise=%.1f | stable Δ=%+.3f | seasonal Δ=%+.3f | Δdelta=%+.3f | P1 %s | crashed=%d",
    scale, mean(stab$delta), mean(seas$delta), dd,
    if (p1) "PASS" else "FAIL", n_crashed))
}

saveRDS(res, "dev/audit/fidelity/baldwin_sigma_decoupled.rds")
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
message(sprintf("\n=== Done in %.1f min ===", elapsed))
