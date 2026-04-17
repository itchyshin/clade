# Discovery experiments for s-predator-prey.
#
# The scenario is already ✅ in the fidelity audit (damped LV oscillations,
# prey oscillation score ~0.39 ± 0.14 at the calibrated regime). The goal
# here is to populate the vignette's "Discovery experiments" section with
# *Tried it* blocks that match other scenario vignettes (body_size,
# mimicry, mating_systems).
#
# Three experiments:
#
#   A. grass_rate × n_predators_init — does LV damping depend on resource
#      density? (memory-flagged as priority)
#   B. group_defense × LV — Hamilton (1971) dilution: does group defense
#      dampen oscillations by reducing per-prey attack risk?
#   C. spatial refugia — Huffaker (1958): do a non-toroidal complex
#      landscape + larger grid sustain oscillations the toroidal default
#      damps?
#
# Usage:  Rscript dev/audit/fidelity/predator_prey_discovery.R
# Output: dev/audit/fidelity/predator_prey_discovery.rds
#         dev/audit/fidelity/predator_prey_discovery_figs/

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
  library(ggplot2)
  library(patchwork)
})

# ── Oscillation score (same definition as predator_prey.R) ──────────────────
oscillation_score <- function(prey, burn = 100L, lag_range = 20L:100L) {
  x <- prey[seq.int(burn + 1L, length(prey))]
  if (length(x) < max(lag_range) + 10L) return(NA_real_)
  if (sd(x) < 1)                         return(0)
  ac <- stats::acf(x, lag.max = max(lag_range), plot = FALSE)$acf[-1L]
  min_ac_in_range <- min(ac[lag_range])
  if (is.na(min_ac_in_range) || min_ac_in_range >= 0) return(0)
  -min_ac_in_range
}

.base_specs <- function(seed) {
  s <- default_specs()
  s$n_agents_init             <- 100L
  s$n_predators_init          <- 10L
  s$grid_rows                 <- 30L
  s$grid_cols                 <- 30L
  s$predator_energy_gain      <- 30
  s$predator_min_repro_energy <- 50
  s$predator_max_agents       <- 100L
  s$grass_rate                <- 0.20
  s$max_ticks                 <- 800L
  s$random_seed               <- as.integer(seed)
  s
}

.run_and_score <- function(s) {
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  list(ticks = d,
       prey_osc = oscillation_score(d$n_agents),
       pred_osc = oscillation_score(d$n_predators),
       prey_mean_last = mean(tail(d$n_agents,    100L), na.rm = TRUE),
       pred_mean_last = mean(tail(d$n_predators, 100L), na.rm = TRUE),
       prey_sd_last   = sd(  tail(d$n_agents,    100L), na.rm = TRUE))
}

t0 <- Sys.time()
message("─── Predator-prey discovery experiments ─────────────")

# ── Exp A: grass_rate × n_predators_init ────────────────────────────────────
message("[A] grass_rate × n_predators_init (3 grass × 2 preds × 5 seeds = 30 runs)")
grid_A <- expand.grid(
  grass_rate       = c(0.05, 0.15, 0.30),
  n_predators_init = c(5L, 20L),
  seed             = c(1L, 7L, 13L, 19L, 25L)
)
res_A <- vector("list", nrow(grid_A))
for (i in seq_len(nrow(grid_A))) {
  row <- grid_A[i, ]
  s   <- .base_specs(row$seed)
  s$grass_rate       <- row$grass_rate
  s$n_predators_init <- row$n_predators_init
  r   <- .run_and_score(s)
  res_A[[i]] <- cbind(row, prey_osc = r$prey_osc, pred_osc = r$pred_osc,
                     prey_mean = r$prey_mean_last,
                     pred_mean = r$pred_mean_last,
                     prey_sd   = r$prey_sd_last)
  message(sprintf("  grass=%.2f pred=%2d seed=%2d → prey_osc=%.3f prey_mean=%.0f",
                  row$grass_rate, row$n_predators_init, row$seed,
                  r$prey_osc, r$prey_mean_last))
}
res_A <- do.call(rbind, res_A)

summary_A <- aggregate(cbind(prey_osc, prey_mean, pred_mean) ~
                         grass_rate + n_predators_init,
                       data = res_A,
                       FUN  = function(x) c(mean = mean(x, na.rm = TRUE),
                                            sd   = sd(  x, na.rm = TRUE)))
message("\n[A] Summary (mean ± sd across 5 seeds):")
print(summary_A)

# ── Exp B: group_defense × LV ───────────────────────────────────────────────
message("\n[B] group_defense × LV (2 conditions × 5 seeds = 10 runs)")
seeds_B <- c(1L, 7L, 13L, 19L, 25L)
res_B <- list()
for (gd in c(FALSE, TRUE)) {
  for (sd in seeds_B) {
    s <- .base_specs(sd)
    s$n_predators_init <- 20L   # moderate predation so group defense matters
    s$group_defense <- gd
    if (gd) {
      s$group_defense_radius   <- 2L
      s$group_defense_strength <- 0.3
    }
    r <- .run_and_score(s)
    res_B[[length(res_B) + 1L]] <-
      data.frame(group_defense = gd, seed = sd,
                 prey_osc = r$prey_osc, pred_osc = r$pred_osc,
                 prey_mean = r$prey_mean_last,
                 pred_mean = r$pred_mean_last,
                 prey_sd   = r$prey_sd_last)
    message(sprintf("  gd=%s seed=%2d → prey_osc=%.3f prey_mean=%.0f",
                    gd, sd, r$prey_osc, r$prey_mean_last))
  }
}
res_B <- do.call(rbind, res_B)

summary_B <- aggregate(cbind(prey_osc, prey_mean, pred_mean) ~ group_defense,
                       data = res_B,
                       FUN  = function(x) c(mean = mean(x, na.rm = TRUE),
                                            sd   = sd(  x, na.rm = TRUE)))
message("\n[B] Summary:")
print(summary_B)

# ── Exp C: spatial refugia — Huffaker (1958) with toroidal = FALSE ──────────
# The 2026-04-17 first pass missed that toroidal is a first-class spec.
# Re-running the experiment properly: 2×2 factorial of
# (toroidal ∈ {TRUE, FALSE}) × (complex_landscape ∈ {FALSE, TRUE})
# on a 50×50 grid with max_agents lifted to 1000 so population cap
# doesn't confound the cycling measurement.
message("\n[C] Spatial refugia (4 conditions × 5 seeds = 20 runs, 50×50 grid, max_agents=1000)")
seeds_C <- c(1L, 7L, 13L, 19L, 25L)
res_C <- list()
for (tor in c(TRUE, FALSE)) {
  for (cl in c(FALSE, TRUE)) {
    for (sd in seeds_C) {
      s <- .base_specs(sd)
      s$grid_rows           <- 50L
      s$grid_cols           <- 50L
      s$n_agents_init       <- 250L     # scale population with area
      s$max_agents          <- 1000L    # lift cap so cycling isn't clipped
      s$n_predators_init    <- 25L
      s$predator_max_agents <- 250L
      s$toroidal            <- tor
      s$complex_landscape   <- cl
      if (cl) {
        s$shrub_density  <- 0.35
        s$canopy_density <- 0.10
      }
      r <- .run_and_score(s)
      res_C[[length(res_C) + 1L]] <-
        data.frame(toroidal = tor, complex_landscape = cl, seed = sd,
                   prey_osc = r$prey_osc, pred_osc = r$pred_osc,
                   prey_mean = r$prey_mean_last,
                   pred_mean = r$pred_mean_last,
                   prey_sd   = r$prey_sd_last)
      message(sprintf("  tor=%s cl=%s seed=%2d → prey_osc=%.3f prey_mean=%.0f",
                      tor, cl, sd, r$prey_osc, r$prey_mean_last))
    }
  }
}
res_C <- do.call(rbind, res_C)

summary_C <- aggregate(cbind(prey_osc, prey_mean, pred_mean) ~
                         toroidal + complex_landscape,
                       data = res_C,
                       FUN  = function(x) c(mean = mean(x, na.rm = TRUE),
                                            sd   = sd(  x, na.rm = TRUE)))
message("\n[C] Summary (2x2 factorial):")
print(summary_C)

# ── Save all results ────────────────────────────────────────────────────────
saveRDS(list(A = res_A, B = res_B, C = res_C,
             summary_A = summary_A,
             summary_B = summary_B,
             summary_C = summary_C),
        "dev/audit/fidelity/predator_prey_discovery.rds")

elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
message(sprintf("\n─── Discovery experiments done in %.1f min ───", elapsed))
