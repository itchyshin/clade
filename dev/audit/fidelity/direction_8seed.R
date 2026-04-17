# 8-seed direction check on currently-✅ scenarios with clear Δ claims.
#
# Today's pattern: 3-5 seed direction claims often reverse under
# 8+ seed scrutiny (Red Queen, mimicry, body-size P2, plasticity,
# baldwin). Today's ✅ list was mostly audited at 2-5 seeds. This
# script runs 8 seeds × 2 conditions per scenario to check whether
# directional claims are robust.
#
# Four scenarios (chosen for clarity of Δ claim and default_specs
# viability):
#
#   clutch_size   — rich vs scarce grass; expect births higher rich
#   life_history  — iteroparous vs semelparous; expect age higher itero
#   signals       — with sexual selection, signal magnitude ↑ over time
#                   (single condition, direction = init→final positive)
#   pace_of_life  — slow vs fast metabolic_rate; expect slow age higher
#
# Each test explicitly guards on viability_report() to rule out crash-
# driven results.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L)

.check <- function(s) {
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  vr  <- viability_report(d, n_agents_init = s$n_agents_init)
  list(ticks = d, vr = vr)
}

t0 <- Sys.time()

# ── clutch_size ────────────────────────────────────────────────────────────
message("=== [1/4] clutch_size: rich vs scarce ===")
clutch_make <- function(gr, seed) {
  s <- default_specs()
  s$clutch_size_evolution   <- TRUE
  s$clutch_size_min         <- 1L
  s$clutch_size_max         <- 5L
  s$clutch_size_mutation_sd <- 0.3
  s$grass_rate              <- gr
  s$max_ticks               <- 400L
  s$random_seed             <- as.integer(seed)
  s
}
res_cl <- data.frame()
for (gr in c(0.4, 0.05)) {
  for (sd in SEEDS) {
    r <- .check(clutch_make(gr, sd))
    mean_births_last50 <- mean(tail(r$ticks$n_births, 50L))
    res_cl <- rbind(res_cl, data.frame(
      cond = if (gr > 0.1) "rich" else "scarce",
      seed = sd,
      mean_births = mean_births_last50,
      n_final = r$vr$n_final, verdict = r$vr$verdict))
  }
}
dd_cl <- mean(res_cl$mean_births[res_cl$cond == "rich"]) -
         mean(res_cl$mean_births[res_cl$cond == "scarce"])
se_cl <- sqrt(sd(res_cl$mean_births[res_cl$cond == "rich"])^2 / 8 +
              sd(res_cl$mean_births[res_cl$cond == "scarce"])^2 / 8)
message(sprintf("  rich mean births = %.2f ± %.2f",
                mean(res_cl$mean_births[res_cl$cond == "rich"]),
                sd(res_cl$mean_births[res_cl$cond == "rich"])))
message(sprintf("  scarce mean births = %.2f ± %.2f",
                mean(res_cl$mean_births[res_cl$cond == "scarce"]),
                sd(res_cl$mean_births[res_cl$cond == "scarce"])))
message(sprintf("  Δ(rich - scarce) = %+.2f, SE = %.2f, t ≈ %.2f",
                dd_cl, se_cl, dd_cl / se_cl))
message(sprintf("  crashed: %d/16", sum(res_cl$verdict == "crashed")))

# ── life_history ───────────────────────────────────────────────────────────
message("\n=== [2/4] life_history: iteroparous vs semelparous ===")
lh_make <- function(lh, seed) {
  s <- default_specs()
  s$life_history <- lh
  s$max_ticks    <- 400L
  s$random_seed  <- as.integer(seed)
  s
}
res_lh <- data.frame()
for (lh in c("iteroparous", "semelparous")) {
  for (sd in SEEDS) {
    r <- .check(lh_make(lh, sd))
    mean_age_last50 <- mean(tail(r$ticks$mean_age, 50L))
    res_lh <- rbind(res_lh, data.frame(
      cond = lh, seed = sd,
      mean_age = mean_age_last50,
      n_final = r$vr$n_final, verdict = r$vr$verdict))
  }
}
dd_lh <- mean(res_lh$mean_age[res_lh$cond == "iteroparous"]) -
         mean(res_lh$mean_age[res_lh$cond == "semelparous"])
se_lh <- sqrt(sd(res_lh$mean_age[res_lh$cond == "iteroparous"])^2 / 8 +
              sd(res_lh$mean_age[res_lh$cond == "semelparous"])^2 / 8)
message(sprintf("  itero mean age = %.2f ± %.2f, semel = %.2f ± %.2f",
                mean(res_lh$mean_age[res_lh$cond == "iteroparous"]),
                sd(res_lh$mean_age[res_lh$cond == "iteroparous"]),
                mean(res_lh$mean_age[res_lh$cond == "semelparous"]),
                sd(res_lh$mean_age[res_lh$cond == "semelparous"])))
message(sprintf("  Δ(itero - semel) = %+.2f, SE = %.2f, t ≈ %.2f",
                dd_lh, se_lh, dd_lh / se_lh))
message(sprintf("  crashed: %d/16", sum(res_lh$verdict == "crashed")))

# ── signals ────────────────────────────────────────────────────────────────
message("\n=== [3/4] signals: magnitude ↑ over time ===")
sig_make <- function(seed) {
  s <- default_specs()
  s$signal_dims          <- 3L
  s$signal_cost          <- 0.05
  s$mate_choice_mode     <- "preference"
  s$mate_choice_strength <- 0.7
  s$max_ticks            <- 400L
  s$random_seed          <- as.integer(seed)
  s
}
res_sig <- data.frame()
for (sd in SEEDS) {
  r <- .check(sig_make(sd))
  init_mag  <- r$ticks$mean_signal_magnitude[1L]
  final_mag <- tail(r$ticks$mean_signal_magnitude, 1L)
  res_sig <- rbind(res_sig, data.frame(
    seed = sd, init = init_mag, final = final_mag,
    delta = final_mag - init_mag,
    n_final = r$vr$n_final, verdict = r$vr$verdict))
}
dd_sig <- mean(res_sig$delta)
se_sig <- sd(res_sig$delta) / sqrt(nrow(res_sig))
message(sprintf("  mean init = %.3f, mean final = %.3f",
                mean(res_sig$init), mean(res_sig$final)))
message(sprintf("  Δsignal = %+.3f ± %.3f (sd), SE = %.3f, t ≈ %.2f",
                dd_sig, sd(res_sig$delta), se_sig, dd_sig / se_sig))
message(sprintf("  crashed: %d/8", sum(res_sig$verdict == "crashed")))

# ── pace_of_life ───────────────────────────────────────────────────────────
message("\n=== [4/4] pace_of_life: slow vs fast metabolic rate ===")
# Note: metabolic_rate_init_mean is ignored when metabolic_rate_evolution =
# FALSE (genome.jl hardcodes rate = 1.0 at birth). To pin the rate to the
# init_mean value, enable evolution but freeze it at init with
# mutation_sd = 0.
pol_make <- function(rate, seed) {
  s <- default_specs()
  s$metabolic_rate_init_mean    <- rate
  s$metabolic_rate_evolution    <- TRUE
  s$metabolic_rate_mutation_sd  <- 0.0
  s$max_ticks                   <- 400L
  s$random_seed                 <- as.integer(seed)
  s
}
res_pol <- data.frame()
for (rate in c(0.5, 2.0)) {
  for (sd in SEEDS) {
    r <- .check(pol_make(rate, sd))
    mean_age <- mean(tail(r$ticks$mean_age, 50L))
    res_pol <- rbind(res_pol, data.frame(
      cond = if (rate < 1) "slow" else "fast",
      seed = sd, mean_age = mean_age,
      n_final = r$vr$n_final, verdict = r$vr$verdict))
  }
}
dd_pol <- mean(res_pol$mean_age[res_pol$cond == "slow"]) -
          mean(res_pol$mean_age[res_pol$cond == "fast"])
se_pol <- sqrt(sd(res_pol$mean_age[res_pol$cond == "slow"])^2 / 8 +
               sd(res_pol$mean_age[res_pol$cond == "fast"])^2 / 8)
message(sprintf("  slow mean age = %.2f ± %.2f, fast = %.2f ± %.2f",
                mean(res_pol$mean_age[res_pol$cond == "slow"]),
                sd(res_pol$mean_age[res_pol$cond == "slow"]),
                mean(res_pol$mean_age[res_pol$cond == "fast"]),
                sd(res_pol$mean_age[res_pol$cond == "fast"])))
message(sprintf("  Δ(slow - fast) = %+.2f, SE = %.2f, t ≈ %.2f",
                dd_pol, se_pol, dd_pol / se_pol))
message(sprintf("  crashed: %d/16", sum(res_pol$verdict == "crashed")))

saveRDS(list(clutch = res_cl, life_history = res_lh,
             signals = res_sig, pace_of_life = res_pol),
        "dev/audit/fidelity/direction_8seed.rds")

message(sprintf("\n=== Done in %.1f min ===",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))
