# v2 of the 5-seed fast_specs re-audit.
#
# v1 (fast_specs_reaudit.R) produced direction flips for plasticity
# and baldwin because severe seasonality (amp=0.7) + the 30×30 / 80-
# agent default density caused seasonal population crashes. The
# measurement got dominated by tiny surviving populations rather
# than by the underlying selection gradient.
#
# v2 changes:
#   - seasonal_amplitude 0.7 → 0.35 (milder trough)
#   - season_length      50  → 100  (longer cycles, smoother gradient)
#   - grid               30×30 → 40×40
#   - n_agents_init      80  → 180 (buffer against crashes)
#   - max_agents         400 → 800
#   - grass_rate         0.20 → 0.25 (slightly richer baseline)
#
# Still fast_specs timescale (max_age = 30, min_repro_energy = 60,
# max_ticks = 2000, ~66 generations).
#
# Target per scenario: P1 direction PASS + |Δdelta| > 0.02 across 5
# seeds with n_final > 20 in every run (viability sanity check).
#
# Usage:  Rscript dev/audit/fidelity/fast_specs_reaudit_v2.R
# Output: dev/audit/fidelity/fast_specs_reaudit_v2.rds

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L)

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

t0 <- Sys.time()

# ── 1. Plasticity ──────────────────────────────────────────────────────────
message("=== [1/3] Plasticity (calibrated v2) ===")
one_plasticity <- function(seasonal_amp, seed) {
  s <- .base(seed)
  s$phenotypic_plasticity    <- TRUE
  s$plasticity_init_mean     <- 0.3
  s$plasticity_mutation_sd   <- 0.05
  s$bnn_sigma_source         <- "trait"
  s$brain_energy_sigma_scale <- 0.05
  s$seasonal_amplitude       <- seasonal_amp
  s$season_length            <- 100L
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  list(init = d$mean_plasticity[1L],
       final = tail(d$mean_plasticity, 1L),
       n_final = tail(d$n_agents, 1L))
}
plast <- do.call(rbind, lapply(SEEDS, function(sd) {
  do.call(rbind, lapply(c(0.0, 0.35), function(amp) {
    r <- one_plasticity(amp, sd)
    cond <- if (amp > 0) "seasonal" else "stable"
    message(sprintf("  amp=%.2f seed=%2d → init=%.3f final=%.3f Δ=%+.3f n=%d",
                    amp, sd, r$init, r$final, r$final - r$init, r$n_final))
    data.frame(seed = sd, cond = cond, init = r$init, final = r$final,
               delta = r$final - r$init, n_final = r$n_final)
  }))
}))

# ── 2. Baldwin ─────────────────────────────────────────────────────────────
message("\n=== [2/3] Baldwin (calibrated v2) ===")
one_baldwin <- function(seasonal_amp, seed) {
  s <- .base(seed)
  s$brain_type               <- "bnn"
  s$bnn_sigma_source         <- "trait"
  s$brain_energy_sigma_scale <- 0.05
  s$plasticity_init_mean     <- 0.5
  s$plasticity_mutation_sd   <- 0.05
  s$phenotypic_plasticity    <- TRUE
  s$seasonal_amplitude       <- seasonal_amp
  s$season_length            <- 100L
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  sig <- if ("mean_prior_sigma" %in% names(d)) d$mean_prior_sigma
         else d$mean_plasticity
  list(init = sig[1L], final = tail(sig, 1L),
       n_final = tail(d$n_agents, 1L))
}
bald <- do.call(rbind, lapply(SEEDS, function(sd) {
  do.call(rbind, lapply(c(0.0, 0.35), function(amp) {
    r <- one_baldwin(amp, sd)
    cond <- if (amp > 0) "seasonal" else "stable"
    message(sprintf("  amp=%.2f seed=%2d → init=%.3f final=%.3f Δ=%+.3f n=%d",
                    amp, sd, r$init, r$final, r$final - r$init, r$n_final))
    data.frame(seed = sd, cond = cond, init = r$init, final = r$final,
               delta = r$final - r$init, n_final = r$n_final)
  }))
}))

# ── 3. Dispersal-IFD ───────────────────────────────────────────────────────
message("\n=== [3/3] Dispersal-IFD (calibrated v2) ===")
one_dispersal <- function(complex_landscape, seed) {
  s <- .base(seed)
  s$dispersal_evolution          <- TRUE
  s$dispersal_init_mean          <- 0.3
  s$habitat_preference_evolution <- TRUE
  s$habitat_preference_init_mean <- 0.0
  s$complex_landscape            <- complex_landscape
  if (complex_landscape) {
    s$shrub_density  <- 0.35
    s$canopy_density <- 0.10
  }
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  vec <- d[["mean_habitat_preference"]]
  list(init = vec[1L], final = tail(vec, 1L),
       n_final = tail(d$n_agents, 1L))
}
disp <- do.call(rbind, lapply(SEEDS, function(sd) {
  do.call(rbind, lapply(c(FALSE, TRUE), function(cl) {
    r <- one_dispersal(cl, sd)
    cond <- if (cl) "patchy" else "flat"
    message(sprintf("  cl=%s seed=%2d → init=%.3f final=%.3f Δ=%+.3f n=%d",
                    cl, sd, r$init, r$final, r$final - r$init, r$n_final))
    data.frame(seed = sd, cond = cond, init = r$init, final = r$final,
               delta = r$final - r$init, n_final = r$n_final)
  }))
}))

# ── Summary ───────────────────────────────────────────────────────────────
.summarise <- function(df, high_group, expected_higher = TRUE) {
  conds   <- unique(df$cond)
  low     <- setdiff(conds, high_group)
  mu_high <- mean(df$final[df$cond == high_group])
  mu_low  <- mean(df$final[df$cond == low])
  mu_dh   <- mean(df$delta[df$cond == high_group])
  mu_dl   <- mean(df$delta[df$cond == low])
  p1  <- if (expected_higher) mu_high > mu_low else mu_high < mu_low
  dd  <- mu_dh - mu_dl
  list(p1 = p1, ddelta = dd,
       high_final = mu_high, low_final = mu_low,
       high_delta = mu_dh, low_delta = mu_dl,
       min_n = min(df$n_final))
}

s_plast <- .summarise(plast, "seasonal", expected_higher = TRUE)
s_bald  <- .summarise(bald,  "seasonal", expected_higher = TRUE)
s_disp  <- .summarise(disp,  "patchy",   expected_higher = TRUE)

message("\n── Summary table ──")
tab <- data.frame(
  scenario = c("plasticity", "baldwin", "dispersal"),
  p1       = c(s_plast$p1, s_bald$p1, s_disp$p1),
  ddelta   = c(s_plast$ddelta, s_bald$ddelta, s_disp$ddelta),
  min_n    = c(s_plast$min_n, s_bald$min_n, s_disp$min_n),
  verdict  = c("", "", "")
)
for (i in seq_len(nrow(tab))) {
  tab$verdict[i] <- if (tab$p1[i] && abs(tab$ddelta[i]) > 0.02 && tab$min_n[i] > 20)
                      "PROMOTABLE ✅"
                    else if (tab$p1[i])
                      sprintf("direction OK, magnitude %.3f (< 0.02)", tab$ddelta[i])
                    else
                      sprintf("direction FAIL (Δ = %+.3f)", tab$ddelta[i])
}
print(tab, row.names = FALSE)

saveRDS(list(plasticity = plast, baldwin = bald, dispersal = disp,
             summary = list(plasticity = s_plast, baldwin = s_bald,
                            dispersal = s_disp)),
        "dev/audit/fidelity/fast_specs_reaudit_v2.rds")

elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
message(sprintf("\n=== v2 done in %.1f min ===", elapsed))
