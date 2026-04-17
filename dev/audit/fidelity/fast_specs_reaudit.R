# Multi-seed re-audit of the three "easy-win" 🟠 scenarios at fast_specs()
# to see if the single-seed promotions hold: plasticity, baldwin,
# dispersal-ifd.
#
# Per PRIORITY_ROADMAP.md §2.1: single-seed fast_specs already showed
# 61×, 11×, 18× stronger signals respectively. Target per scenario:
# Δ > 0.02 in the theory-predicted direction, across ≥ 5 seeds, with
# P1 PASS (treatment > control direction) and the effect size outside
# the ±2×SE noise band.
#
# Usage:  Rscript dev/audit/fidelity/fast_specs_reaudit.R
# Output: dev/audit/fidelity/fast_specs_reaudit.rds
#
# Runtime estimate: 5 seeds × 2 conditions × 3 scenarios = 30 runs at
# 2000 ticks each. ~10-15 min wall clock (one Julia session).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L)

t0 <- Sys.time()

# ── 1. Plasticity: stable vs seasonal (DeWitt & Scheiner 2004) ──────────────
# Prediction: seasonal environments maintain higher plasticity than stable
# environments, because plasticity is costly only when conditions are
# predictable.
message("=== [1/3] Plasticity: stable vs seasonal ===")
one_plasticity <- function(seasonal_amp, seed) {
  s <- fast_specs()                   # max_ticks = 2000, ~66 generations
  s$phenotypic_plasticity    <- TRUE
  s$plasticity_init_mean     <- 0.3
  s$plasticity_mutation_sd   <- 0.05
  s$bnn_sigma_source         <- "trait"
  s$brain_energy_sigma_scale <- 0.05
  s$seasonal_amplitude       <- seasonal_amp
  s$season_length            <- 50L
  s$random_seed              <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  list(init  = d$mean_plasticity[1L],
       final = tail(d$mean_plasticity, 1L),
       n_final = tail(d$n_agents, 1L))
}

plast <- data.frame()
for (sd in SEEDS) {
  for (amp in c(0.0, 0.7)) {
    r <- one_plasticity(amp, sd)
    cond <- if (amp > 0) "seasonal" else "stable"
    plast <- rbind(plast, data.frame(seed = sd, cond = cond,
                                      init = r$init, final = r$final,
                                      delta = r$final - r$init,
                                      n_final = r$n_final))
    message(sprintf("  amp=%.1f seed=%2d → init=%.3f final=%.3f Δ=%+.3f n=%d",
                    amp, sd, r$init, r$final, r$final - r$init, r$n_final))
  }
}

summ_plast <- aggregate(cbind(init, final, delta) ~ cond, data = plast,
                        FUN = function(x) c(mean = mean(x), sd = sd(x)))
message("\n  Plasticity summary (mean ± sd across 5 seeds):")
print(summ_plast)
p1_plast <- mean(plast$final[plast$cond == "seasonal"]) >
            mean(plast$final[plast$cond == "stable"])
ddelta_plast <- mean(plast$delta[plast$cond == "seasonal"]) -
                mean(plast$delta[plast$cond == "stable"])
message(sprintf("  P1 (seasonal > stable final): %s",
                if (p1_plast) "PASS" else "FAIL"))
message(sprintf("  Δdelta (seasonal - stable) = %+.3f (target > 0.02)",
                ddelta_plast))

# ── 2. Baldwin Effect: stable canalises BNN sigma more than seasonal ────────
# Hinton & Nowlan 1987: learned behaviour buffers selection at first, but
# once plasticity becomes costly, genetic assimilation replaces learning.
# Stable environments assimilate more; seasonal preserve more flexibility.
message("\n=== [2/3] Baldwin: stable vs seasonal (BNN prior sigma) ===")
one_baldwin <- function(seasonal_amp, seed) {
  s <- fast_specs()
  s$brain_type               <- "bnn"
  s$bnn_sigma_source         <- "trait"
  s$brain_energy_sigma_scale <- 0.05
  s$plasticity_init_mean     <- 0.5    # high initial sigma
  s$plasticity_mutation_sd   <- 0.05
  s$phenotypic_plasticity    <- TRUE
  s$seasonal_amplitude       <- seasonal_amp
  s$season_length            <- 50L
  s$random_seed              <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  sig <- if ("mean_prior_sigma" %in% names(d)) d$mean_prior_sigma
         else d$mean_plasticity
  list(init  = sig[1L],
       final = tail(sig, 1L),
       n_final = tail(d$n_agents, 1L))
}

bald <- data.frame()
for (sd in SEEDS) {
  for (amp in c(0.0, 0.7)) {
    r <- one_baldwin(amp, sd)
    cond <- if (amp > 0) "seasonal" else "stable"
    bald <- rbind(bald, data.frame(seed = sd, cond = cond,
                                    init = r$init, final = r$final,
                                    delta = r$final - r$init,
                                    n_final = r$n_final))
    message(sprintf("  amp=%.1f seed=%2d → init=%.3f final=%.3f Δ=%+.3f n=%d",
                    amp, sd, r$init, r$final, r$final - r$init, r$n_final))
  }
}

summ_bald <- aggregate(cbind(init, final, delta) ~ cond, data = bald,
                       FUN = function(x) c(mean = mean(x), sd = sd(x)))
message("\n  Baldwin summary (mean ± sd across 5 seeds):")
print(summ_bald)
# Prediction: seasonal preserves more sigma (final higher in seasonal vs stable)
p1_bald <- mean(bald$final[bald$cond == "seasonal"]) >
           mean(bald$final[bald$cond == "stable"])
ddelta_bald <- mean(bald$delta[bald$cond == "seasonal"]) -
               mean(bald$delta[bald$cond == "stable"])
message(sprintf("  P1 (seasonal > stable final sigma): %s",
                if (p1_bald) "PASS" else "FAIL"))
message(sprintf("  Δdelta (seasonal - stable) = %+.3f (target > 0.02)",
                ddelta_bald))

# ── 3. Dispersal-IFD: high-grass preference evolves higher with grass gradient ─
# Fretwell & Lucas 1970: under ideal free distribution, dispersal should
# concentrate individuals toward resource-rich patches. In clade, this is
# measured as evolved habitat preference strength.
message("\n=== [3/3] Dispersal-IFD: flat vs patchy grass gradient ===")
one_dispersal <- function(complex_landscape, seed) {
  s <- fast_specs()
  s$dispersal_evolution      <- TRUE
  s$dispersal_init_mean      <- 0.3
  s$habitat_preference_evolution <- TRUE
  s$habitat_preference_init_mean <- 0.0
  s$complex_landscape        <- complex_landscape
  if (complex_landscape) {
    s$shrub_density  <- 0.35
    s$canopy_density <- 0.10
  }
  s$random_seed              <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  pref_col <- intersect(c("mean_habitat_preference", "mean_hab_pref",
                          "mean_dispersal"),
                        names(d))[1]
  vec <- d[[pref_col]]
  list(init  = vec[1L],
       final = tail(vec, 1L),
       n_final = tail(d$n_agents, 1L),
       col = pref_col)
}

disp <- data.frame()
for (sd in SEEDS) {
  for (cl in c(FALSE, TRUE)) {
    r <- one_dispersal(cl, sd)
    cond <- if (cl) "patchy" else "flat"
    disp <- rbind(disp, data.frame(seed = sd, cond = cond,
                                    init = r$init, final = r$final,
                                    delta = r$final - r$init,
                                    n_final = r$n_final))
    message(sprintf("  cl=%s seed=%2d → init=%.3f final=%.3f Δ=%+.3f n=%d (col=%s)",
                    cl, sd, r$init, r$final, r$final - r$init, r$n_final, r$col))
  }
}

summ_disp <- aggregate(cbind(init, final, delta) ~ cond, data = disp,
                       FUN = function(x) c(mean = mean(x), sd = sd(x)))
message("\n  Dispersal summary (mean ± sd across 5 seeds):")
print(summ_disp)
p1_disp <- mean(disp$final[disp$cond == "patchy"]) >
           mean(disp$final[disp$cond == "flat"])
ddelta_disp <- mean(disp$delta[disp$cond == "patchy"]) -
               mean(disp$delta[disp$cond == "flat"])
message(sprintf("  P1 (patchy > flat): %s",
                if (p1_disp) "PASS" else "FAIL"))
message(sprintf("  Δdelta (patchy - flat) = %+.3f (target > 0.02)",
                ddelta_disp))

# ── Save ────────────────────────────────────────────────────────────────────
saveRDS(list(plasticity = plast,
             baldwin    = bald,
             dispersal  = disp,
             summary = list(
               plasticity = list(p1 = p1_plast, ddelta = ddelta_plast),
               baldwin    = list(p1 = p1_bald,  ddelta = ddelta_bald),
               dispersal  = list(p1 = p1_disp,  ddelta = ddelta_disp))),
        "dev/audit/fidelity/fast_specs_reaudit.rds")

elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
message(sprintf("\n=== Done in %.1f min ===", elapsed))

cat(sprintf("\n\n── VERDICT SUMMARY ──\n"))
cat(sprintf("plasticity: %s (Δdelta = %+.3f)\n",
            if (p1_plast && abs(ddelta_plast) > 0.02) "PROMOTABLE ✅"
            else "STILL 🟠", ddelta_plast))
cat(sprintf("baldwin:    %s (Δdelta = %+.3f)\n",
            if (p1_bald && abs(ddelta_bald) > 0.02) "PROMOTABLE ✅"
            else "STILL 🟠", ddelta_bald))
cat(sprintf("dispersal:  %s (Δdelta = %+.3f)\n",
            if (p1_disp && abs(ddelta_disp) > 0.02) "PROMOTABLE ✅"
            else "STILL 🟠", ddelta_disp))
