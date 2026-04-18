# s-kitchen-sink promotion attempt: ⚪ NA → 🟠 qualitative-emergence.
#
# Latent claim: turning every module on produces emergent dynamics
# that are RICHER than any single-module run — disease waves,
# predator oscillations, shelter accumulation all co-occur and
# interact.
#
# Test at realistic_specs() scale across 8 seeds:
#   1. Does the all-modules-on run have detectable disease-wave
#      activity (≥ 3 peaks in n_infected over the run)?
#   2. Does it have detectable predator-cycle activity (prey
#      oscillation score ≥ 0.2)?
#   3. Does it have shelter accumulation (final n_shelters > 5)?
#   4. Is the run viable (population doesn't crash)?
#
# If ≥ 6/8 seeds satisfy at least 3 of the 4 conditions, the
# "emergent dynamics" claim is multi-seed robust → promote to 🟠.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L)

build_spec <- function(seed) {
  s <- realistic_specs()
  s$complex_landscape      <- TRUE
  s$n_predators_init       <- 15L
  s$disease                <- TRUE
  s$transmission_prob      <- 0.2
  s$disease_seed_prob      <- 0.05
  s$kin_selection          <- TRUE
  s$social_learning        <- TRUE
  s$social_learning_freq   <- 50L
  s$rl_mode                <- "actor_critic"
  s$niche_construction     <- TRUE
  s$random_seed            <- as.integer(seed)
  s
}

specs_list <- lapply(SEEDS, build_spec)
message(sprintf("Running %d kitchen-sink specs at realistic_specs() scale...",
                length(specs_list)))
t0 <- Sys.time()
results <- batch_alife(specs_list, n_cores = length(specs_list))
message(sprintf("  batch wall: %.1f min",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))

count_peaks <- function(x, min_height = 1, min_dist = 50) {
  if (length(x) < min_dist * 2) return(0L)
  peaks <- 0L
  last_peak <- -min_dist
  for (i in 2:(length(x) - 1)) {
    if (x[i] >= min_height && x[i] > x[i - 1] && x[i] > x[i + 1] &&
        (i - last_peak) >= min_dist) {
      peaks <- peaks + 1L
      last_peak <- i
    }
  }
  peaks
}

rows <- lapply(seq_along(results), function(i) {
  env <- results[[i]]
  rd  <- get_run_data(env)
  via <- viability_report(rd)
  d   <- rd$ticks

  n_inf <- if ("n_infected" %in% names(d)) d$n_infected else rep(NA_real_, nrow(d))
  disease_peaks <- count_peaks(as.numeric(n_inf), min_height = 3)

  keep <- d$t >= 500
  prey_ac <- tryCatch(
    acf(d$n_agents[keep], lag.max = 200, plot = FALSE)$acf[, 1, 1],
    error = function(e) rep(0, 201))
  prey_osc <- -min(prey_ac[21:101])

  n_shelters_final <- if ("n_shelters" %in% names(d)) tail(d$n_shelters, 1L) else NA_real_

  data.frame(
    seed          = specs_list[[i]]$random_seed,
    verdict       = via$verdict,
    disease_peaks = disease_peaks,
    prey_osc      = prey_osc,
    n_shelters    = n_shelters_final,
    n_final       = tail(d$n_agents, 1L),
    n_pred_final  = tail(d$n_predators, 1L)
  )
})
tbl <- do.call(rbind, rows)
saveRDS(tbl, "dev/audit/fidelity/kitchen_sink_realistic.rds")

message("\n── Per-seed emergence metrics ──")
print(tbl)

tbl$cond1_viable   <- tbl$verdict != "crashed"
tbl$cond2_disease  <- tbl$disease_peaks >= 3
tbl$cond3_cycles   <- tbl$prey_osc    >= 0.2
tbl$cond4_shelters <- !is.na(tbl$n_shelters) & tbl$n_shelters > 5

tbl$n_conds_met <- with(tbl, cond1_viable + cond2_disease +
                              cond3_cycles + cond4_shelters)

message(sprintf("\n── Emergence conditions met (out of 4) ──"))
for (i in seq_len(nrow(tbl))) {
  message(sprintf("  seed %2d: viable=%d disease=%d cycles=%d shelters=%d | met=%d/4",
                  tbl$seed[i], tbl$cond1_viable[i], tbl$cond2_disease[i],
                  tbl$cond3_cycles[i], tbl$cond4_shelters[i], tbl$n_conds_met[i]))
}

n_pass <- sum(tbl$n_conds_met >= 3L)
message(sprintf("\n  %d/%d seeds satisfy >=3/4 emergence conditions", n_pass, nrow(tbl)))
message(sprintf("  %s",
  if (n_pass >= 6L) "PASS — multi-seed emergence claim robust → 🟠 promotable"
  else              "recheck — emergence not multi-seed robust"))
