# Baldwin sigma decoupling v2: combine bnn_action_noise_scale = 0 (pure
# canalisation) with action_exploration_epsilon > 0 (epsilon-greedy
# exploration). The v1 test (baldwin_sigma_decoupled.R) showed the
# direction finally flips to Hinton-Nowlan at noise = 0 but populations
# crash without sigma-driven exploration. Sweep epsilon to find a value
# that keeps populations viable while preserving the canalisation signal.
#
# Sweep: epsilon ∈ {0.05, 0.10, 0.20, 0.50} × seasonal_amplitude ∈
# {0.0, 0.35} × 5 seeds × 2000 ticks with bnn_action_noise_scale = 0
# throughout.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS    <- c(1L, 7L, 13L, 19L, 25L)
EPSILONS <- c(0.05, 0.10, 0.20, 0.50)

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

one_run <- function(amp, epsilon, seed) {
  s <- .base(seed)
  s$brain_type                  <- "bnn"
  s$bnn_sigma_source            <- "trait"
  s$bnn_action_noise_scale      <- 0.0       # sigma decoupled from actions
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
message("=== baldwin × action_exploration_epsilon sweep (at noise_scale=0) ===")

res <- data.frame()
for (eps in EPSILONS) {
  for (amp in c(0.0, 0.35)) {
    for (sd in SEEDS) {
      r <- one_run(amp, eps, sd)
      cond <- if (amp > 0) "seasonal" else "stable"
      res <- rbind(res, data.frame(
        epsilon = eps, cond = cond, seed = sd,
        init = r$init, final = r$final,
        delta = r$final - r$init,
        n_final = r$n_final, verdict = r$verdict))
      message(sprintf(
        "  eps=%.2f amp=%.2f seed=%2d → Δ=%+.3f n=%d (%s)",
        eps, amp, sd, r$final - r$init, r$n_final, r$verdict))
    }
  }
}

message("\n── Summary per epsilon ──")
for (eps in EPSILONS) {
  sub  <- res[res$epsilon == eps, ]
  stab <- sub[sub$cond == "stable", ]
  seas <- sub[sub$cond == "seasonal", ]
  p1 <- mean(seas$final) > mean(stab$final)
  dd <- mean(seas$delta) - mean(stab$delta)
  n_crashed <- sum(sub$verdict == "crashed")
  n_viable  <- sum(sub$verdict == "viable")
  message(sprintf(
    "  eps=%.2f | stable Δ=%+.3f | seasonal Δ=%+.3f | Δdelta=%+.3f | P1 %s | viable=%d crashed=%d",
    eps, mean(stab$delta), mean(seas$delta), dd,
    if (p1) "PASS" else "FAIL", n_viable, n_crashed))
}

saveRDS(res, "dev/audit/fidelity/baldwin_sigma_decoupled_v2.rds")
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
message(sprintf("\n=== Done in %.1f min ===", elapsed))
