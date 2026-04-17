# Baldwin v3: fix the viability issue at the working epsilon (0.10).
# v2 showed eps=0.10 gives Δdelta = +0.029 (above threshold, classic
# Hinton-Nowlan) but 10/10 crashed. Bump grass_rate and agent density
# to buffer against the deterministic-action-driven population decline.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L)

.base <- function(seed) {
  s <- fast_specs()
  s$n_agents_init <- 250L   # up from 180
  s$max_agents    <- 1200L  # up from 800
  s$grid_rows     <- 40L
  s$grid_cols     <- 40L
  s$grass_rate    <- 0.40   # up from 0.25 — buffer against epsilon-greedy waste
  s$random_seed   <- as.integer(seed)
  s
}

one_run <- function(amp, epsilon, seed) {
  s <- .base(seed)
  s$brain_type                  <- "bnn"
  s$bnn_sigma_source            <- "trait"
  s$bnn_action_noise_scale      <- 0.0
  s$action_exploration_epsilon  <- epsilon
  s$brain_energy_sigma_scale    <- 0.05
  s$plasticity_init_mean        <- 0.5
  s$plasticity_mutation_sd      <- 0.05
  s$phenotypic_plasticity       <- TRUE
  s$seasonal_amplitude          <- amp
  s$season_length               <- 10L
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  sig <- if ("mean_prior_sigma" %in% names(d)) d$mean_prior_sigma
         else d$mean_plasticity
  vr  <- viability_report(d, n_agents_init = s$n_agents_init)
  list(init = sig[1L], final = tail(sig, 1L),
       n_final = vr$n_final, verdict = vr$verdict)
}

t0 <- Sys.time()
message("=== baldwin v3: buffered world at epsilon = 0.10 ===")

res <- data.frame()
for (amp in c(0.0, 0.35)) {
  for (sd in SEEDS) {
    r <- one_run(amp, 0.10, sd)
    cond <- if (amp > 0) "seasonal" else "stable"
    res <- rbind(res, data.frame(
      cond = cond, seed = sd,
      init = r$init, final = r$final,
      delta = r$final - r$init,
      n_final = r$n_final, verdict = r$verdict))
    message(sprintf("  amp=%.2f seed=%2d → Δ=%+.3f n=%d (%s)",
                    amp, sd, r$final - r$init, r$n_final, r$verdict))
  }
}

stab <- res[res$cond == "stable", ]
seas <- res[res$cond == "seasonal", ]
p1 <- mean(seas$final) > mean(stab$final)
dd <- mean(seas$delta) - mean(stab$delta)
se <- sqrt(sd(stab$delta)^2 / 5 + sd(seas$delta)^2 / 5)

message("\n── v3 summary ──")
message(sprintf("  stable   Δ = %+.4f ± %.4f", mean(stab$delta), sd(stab$delta)))
message(sprintf("  seasonal Δ = %+.4f ± %.4f", mean(seas$delta), sd(seas$delta)))
message(sprintf("  Δdelta     = %+.4f, SE = %.4f, t ≈ %.2f",
                dd, se, dd / se))
message(sprintf("  P1 direction: %s", if (p1) "PASS" else "FAIL"))
message(sprintf("  viability: viable=%d weak=%d crashed=%d",
                sum(res$verdict == "viable"),
                sum(res$verdict == "weak"),
                sum(res$verdict == "crashed")))

saveRDS(res, "dev/audit/fidelity/baldwin_sigma_decoupled_v3.rds")
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
message(sprintf("\n=== Done in %.1f min ===", elapsed))
