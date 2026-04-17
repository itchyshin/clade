# Why does body_size_evolution crash at fast_specs?
#
# crash_audit showed n_final ≈ 7 across 5 seeds at fast_specs +
# body_size_evolution = TRUE. Diagnosing the mechanism.
#
# Hypothesis tree:
#   H1: body_size mutation variance creates trait extremes that
#       can't survive the short fast_specs lifespan
#   H2: the fast_specs grass carrying capacity is borderline for
#       any additional mortality pressure, not body_size-specific
#   H3: the body_size foraging/metabolic coupling is asymmetric —
#       large agents pay metabolic cost but their foraging bonus
#       is capped at grass availability
#
# Test 1: vary body_size_mutation_sd (H1 check)
# Test 2: fix body_size = 1.0 (no evolution) vs evolving (H2 check)
# Test 3: log body_size trajectory in crashing runs (H3 observation)

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L)

.base <- function(seed) {
  s <- fast_specs()
  s$random_seed <- as.integer(seed)
  s
}

.run_report <- function(s) {
  env  <- run_alife(s, verbose = FALSE)
  d    <- get_run_data(env)$ticks
  vr   <- viability_report(d, n_agents_init = s$n_agents_init)
  bs_final   <- tail(d$mean_body_size, 1L)
  bs_sd_last <- tail(d$sd_body_size,   1L)
  list(verdict = vr$verdict,
       n_final = vr$n_final,
       bs_mean_final = bs_final,
       bs_sd_final   = bs_sd_last,
       tick_of_min   = vr$tick_of_min,
       n_min         = vr$n_min)
}

message("=== body_size crash diagnosis at fast_specs ===")

# Test 1: mutation_sd sweep
message("\n[H1] Vary body_size_mutation_sd")
mut_sds <- c(0.0, 0.005, 0.02, 0.05, 0.10)
res1 <- data.frame()
for (msd in mut_sds) {
  for (sd in SEEDS) {
    s <- .base(sd)
    s$body_size_evolution   <- TRUE
    s$body_size_init_mean   <- 1.0
    s$body_size_mutation_sd <- msd
    r <- .run_report(s)
    res1 <- rbind(res1, data.frame(
      test = "H1_mut_sd", param = msd, seed = sd,
      verdict = r$verdict, n_final = r$n_final, n_min = r$n_min,
      bs_mean = r$bs_mean_final, bs_sd = r$bs_sd_final))
    message(sprintf("  mut_sd=%.3f seed=%2d → %s (n_final=%d, bs=%.2f ± %.2f)",
                    msd, sd, r$verdict, r$n_final, r$bs_mean_final, r$bs_sd_final))
  }
}

# Test 2: evolution off
message("\n[H2] body_size_evolution = FALSE (baseline check)")
res2 <- data.frame()
for (sd in SEEDS) {
  s <- .base(sd)
  s$body_size_evolution <- FALSE
  r <- .run_report(s)
  res2 <- rbind(res2, data.frame(
    test = "H2_no_evo", param = 0.0, seed = sd,
    verdict = r$verdict, n_final = r$n_final, n_min = r$n_min,
    bs_mean = r$bs_mean_final, bs_sd = r$bs_sd_final))
  message(sprintf("  evo=FALSE seed=%2d → %s (n_final=%d)",
                  sd, r$verdict, r$n_final))
}

# Test 3: grass bump
message("\n[H2'] body_size_evolution = TRUE, grass_rate = 0.35 (food bump)")
res3 <- data.frame()
for (sd in SEEDS) {
  s <- .base(sd)
  s$body_size_evolution   <- TRUE
  s$body_size_mutation_sd <- 0.02   # moderate mutation
  s$grass_rate            <- 0.35
  r <- .run_report(s)
  res3 <- rbind(res3, data.frame(
    test = "H2p_more_grass", param = 0.35, seed = sd,
    verdict = r$verdict, n_final = r$n_final, n_min = r$n_min,
    bs_mean = r$bs_mean_final, bs_sd = r$bs_sd_final))
  message(sprintf("  grass=0.35 seed=%2d → %s (n_final=%d, bs=%.2f)",
                  sd, r$verdict, r$n_final, r$bs_mean_final))
}

all_res <- rbind(res1, res2, res3)
saveRDS(all_res, "dev/audit/fidelity/body_size_crash_diagnosis.rds")

message("\n── Summary ──")
for (t in unique(all_res$test)) {
  sub <- all_res[all_res$test == t, ]
  for (p in unique(sub$param)) {
    subp <- sub[sub$param == p, ]
    n_crashed <- sum(subp$verdict == "crashed")
    message(sprintf("  %-16s param=%.3f | crashed: %d/5 | mean n_final=%.0f, mean bs=%.2f",
                    t, p, n_crashed, mean(subp$n_final), mean(subp$bs_mean)))
  }
}
