# Tier C re-audit batch 2 — the remaining at-risk ✅ scenarios with
# direction claims that can be checked with 8-seed paired comparisons
# at default_specs.
#
# Scenarios + canonical claims:
#   s-brain-size          — brain_size_evolution + parental_care ON:
#                           mean_brain_size ↑ vs no-parental-care control
#   s-parental-investment — female_investment HI (0.9) vs EQ (0.5):
#                           per-offspring energy differs
#   s-parental-care       — parental_care ON: juvenile survival ↑ vs OFF
#   s-complex-landscape   — complex_landscape ON: n_canopy_agents > 0,
#                           vs 0 when OFF (module fires)
#   s-rl                  — rl_mode = actor_critic vs none: mean_energy ↑
#                           (within-life learning improves foraging)
#   s-seasonal            — seasonal_amplitude 0.7 vs 0: grass oscillates
#                           (population tracks grass cycle — demographic)
#
# All at default_specs to avoid fast_specs crash artefacts.
# viability_report() guard on every run.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L)

.run <- function(s) {
  env <- suppressWarnings(run_alife(s, verbose = FALSE))
  d   <- get_run_data(env)$ticks
  vr  <- viability_report(d, n_agents_init = s$n_agents_init)
  list(d = d, vr = vr)
}

.t_test <- function(on, off, label) {
  on  <- on [!is.na(on)];  off <- off[!is.na(off)]
  delta <- mean(on) - mean(off)
  se <- sqrt(sd(on)^2 / length(on) + sd(off)^2 / length(off))
  t  <- delta / se
  message(sprintf("  %s: on = %.3f ± %.3f, off = %.3f ± %.3f",
                  label, mean(on), sd(on), mean(off), sd(off)))
  message(sprintf("  Δ = %+.3f, SE = %.3f, t ≈ %.2f → %s",
                  delta, se, t,
                  if (abs(t) >= 2.0) "PASS (t ≥ 2)" else "RECHECK (t < 2)"))
  list(delta = delta, se = se, t = t, on_n = length(on), off_n = length(off))
}

t0 <- Sys.time()
results <- list()

# ── 1. brain-size: parental_care unlocks brain_size evolution ──────────────
message("=== [1/6] brain-size ===")
bs_make <- function(care, seed) {
  s <- default_specs()
  s$brain_size_evolution   <- TRUE
  s$brain_size_init_mean   <- 1.2
  s$brain_size_mutation_sd <- 0.08
  s$brain_size_cost_scale  <- 5.0
  s$parental_care          <- care
  s$n_agents_init          <- 100L
  s$max_agents             <- 400L
  s$max_ticks              <- 500L
  s$random_seed            <- as.integer(seed)
  s
}
bs_on <- numeric(); bs_off <- numeric(); bs_crash <- 0L
for (sd in SEEDS) {
  on  <- .run(bs_make(TRUE,  sd));  on_v  <- tail(on$d$mean_brain_size, 1L)
  off <- .run(bs_make(FALSE, sd));  off_v <- tail(off$d$mean_brain_size, 1L)
  if (on$vr$verdict == "crashed" || off$vr$verdict == "crashed") bs_crash <- bs_crash + 1L
  bs_on  <- c(bs_on,  on_v);  bs_off <- c(bs_off, off_v)
  message(sprintf("  seed %2d: care=on → %.3f (n=%d %s) | care=off → %.3f (n=%d %s)",
                  sd, on_v, on$vr$n_final, on$vr$verdict,
                  off_v, off$vr$n_final, off$vr$verdict))
}
results$brain_size <- c(.t_test(bs_on, bs_off, "mean_brain_size"),
                        list(crashes = bs_crash))

# ── 2. parental-investment: female_investment HI vs EQ ────────────────────
message("\n=== [2/6] parental-investment ===")
pi_make <- function(fi, seed) {
  s <- default_specs()
  s$parental_care                 <- TRUE
  s$parental_investment_evolution <- TRUE
  s$female_investment             <- fi
  s$male_repro_cost               <- 0.3
  s$max_ticks                     <- 400L
  s$random_seed                   <- as.integer(seed)
  s
}
pi_on <- numeric(); pi_off <- numeric(); pi_crash <- 0L
for (sd in SEEDS) {
  on  <- .run(pi_make(0.9, sd));  on_v  <- mean(tail(on$d$n_births, 50L), na.rm = TRUE)
  off <- .run(pi_make(0.5, sd));  off_v <- mean(tail(off$d$n_births, 50L), na.rm = TRUE)
  if (on$vr$verdict == "crashed" || off$vr$verdict == "crashed") pi_crash <- pi_crash + 1L
  pi_on  <- c(pi_on,  on_v);  pi_off <- c(pi_off, off_v)
  message(sprintf("  seed %2d: fi=0.9 → %.1f births/t | fi=0.5 → %.1f",
                  sd, on_v, off_v))
}
results$parental_investment <- c(.t_test(pi_on, pi_off, "births/tick (high vs equal)"),
                                  list(crashes = pi_crash))

# ── 3. parental-care: juvenile buffering ──────────────────────────────────
message("\n=== [3/6] parental-care ===")
pc_make <- function(care, seed) {
  s <- default_specs()
  s$parental_care      <- care
  s$juvenile_independence_age <- 5L
  s$care_cost_per_tick <- 2.0
  s$max_ticks          <- 400L
  s$random_seed        <- as.integer(seed)
  s
}
pc_on <- numeric(); pc_off <- numeric(); pc_crash <- 0L
for (sd in SEEDS) {
  on  <- .run(pc_make(TRUE,  sd));  on_v  <- mean(tail(on$d$n_juveniles, 50L), na.rm = TRUE)
  off <- .run(pc_make(FALSE, sd));  off_v <- mean(tail(off$d$n_juveniles, 50L), na.rm = TRUE)
  if (on$vr$verdict == "crashed" || off$vr$verdict == "crashed") pc_crash <- pc_crash + 1L
  pc_on  <- c(pc_on,  on_v);  pc_off <- c(pc_off, off_v)
  message(sprintf("  seed %2d: care=on → %.2f juv | care=off → %.2f",
                  sd, on_v, off_v))
}
results$parental_care <- c(.t_test(pc_on, pc_off, "mean n_juveniles"),
                            list(crashes = pc_crash))

# ── 4. complex-landscape: module fires ────────────────────────────────────
message("\n=== [4/6] complex-landscape ===")
cl_make <- function(cl, seed) {
  s <- default_specs()
  s$complex_landscape <- cl
  s$shrub_density     <- 0.35
  s$canopy_density    <- 0.15
  s$max_ticks         <- 400L
  s$random_seed       <- as.integer(seed)
  s
}
cl_on <- numeric(); cl_off <- numeric(); cl_crash <- 0L
for (sd in SEEDS) {
  on  <- .run(cl_make(TRUE,  sd))
  on_v  <- mean(tail(on$d$n_canopy_agents + on$d$n_shrub_agents, 50L), na.rm = TRUE)
  off <- .run(cl_make(FALSE, sd))
  off_v <- mean(tail(off$d$n_canopy_agents + off$d$n_shrub_agents, 50L), na.rm = TRUE)
  if (on$vr$verdict == "crashed" || off$vr$verdict == "crashed") cl_crash <- cl_crash + 1L
  cl_on <- c(cl_on, on_v); cl_off <- c(cl_off, off_v)
  message(sprintf("  seed %2d: cl=on → %.1f layered | cl=off → %.1f",
                  sd, on_v, off_v))
}
results$complex_landscape <- c(.t_test(cl_on, cl_off, "layered agents"),
                                list(crashes = cl_crash))

# ── 5. rl: within-life learning improves energy ──────────────────────────
message("\n=== [5/6] rl ===")
rl_make <- function(mode, seed) {
  s <- default_specs()
  s$rl_mode         <- mode
  s$rl_update_freq  <- 5L
  s$n_agents_init   <- 80L
  s$grass_rate      <- 0.15
  s$max_ticks       <- 400L
  s$random_seed     <- as.integer(seed)
  s
}
rl_on <- numeric(); rl_off <- numeric(); rl_crash <- 0L
for (sd in SEEDS) {
  on  <- .run(rl_make("actor_critic", sd))
  on_v  <- mean(tail(on$d$mean_energy, 50L), na.rm = TRUE)
  off <- .run(rl_make("none",         sd))
  off_v <- mean(tail(off$d$mean_energy, 50L), na.rm = TRUE)
  if (on$vr$verdict == "crashed" || off$vr$verdict == "crashed") rl_crash <- rl_crash + 1L
  rl_on  <- c(rl_on,  on_v);  rl_off <- c(rl_off, off_v)
  message(sprintf("  seed %2d: rl=on → %.1f | rl=off → %.1f",
                  sd, on_v, off_v))
}
results$rl <- c(.t_test(rl_on, rl_off, "mean_energy (last 50 t)"),
                list(crashes = rl_crash))

# ── 6. seasonal: grass oscillates under seasonal_amplitude > 0 ────────────
message("\n=== [6/6] seasonal ===")
se_make <- function(amp, seed) {
  s <- default_specs()
  s$seasonal_amplitude <- amp
  s$season_length      <- 100L
  s$n_agents_init      <- 80L
  s$max_ticks          <- 500L
  s$random_seed        <- as.integer(seed)
  s
}
# Metric: range of grass_coverage across the last 300 ticks (oscillation test)
se_on <- numeric(); se_off <- numeric(); se_crash <- 0L
for (sd in SEEDS) {
  on  <- .run(se_make(0.7, sd))
  on_v  <- diff(range(tail(on$d$grass_coverage, 300L), na.rm = TRUE))
  off <- .run(se_make(0.0, sd))
  off_v <- diff(range(tail(off$d$grass_coverage, 300L), na.rm = TRUE))
  if (on$vr$verdict == "crashed" || off$vr$verdict == "crashed") se_crash <- se_crash + 1L
  se_on <- c(se_on, on_v); se_off <- c(se_off, off_v)
  message(sprintf("  seed %2d: amp=0.7 → grass swing %.3f | amp=0.0 → %.3f",
                  sd, on_v, off_v))
}
results$seasonal <- c(.t_test(se_on, se_off, "grass oscillation amplitude"),
                      list(crashes = se_crash))

saveRDS(results, "dev/audit/fidelity/tier_c_batch2.rds")

message("\n── Batch 2 summary ──")
for (nm in names(results)) {
  r <- results[[nm]]
  verdict <- if (abs(r$t) >= 2.0) "PASS (t ≥ 2)" else "RECHECK (t < 2)"
  message(sprintf("  %-22s | Δ = %+8.3f | t = %6.2f | crashes: %d/8 | %s",
                  nm, r$delta, r$t, r$crashes, verdict))
}
message(sprintf("\n=== Batch 2 done in %.1f min ===",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))
