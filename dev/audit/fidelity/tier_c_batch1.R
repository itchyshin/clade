# Tier C re-audit batch 1 — 6 scenarios × 2 conditions × 8 seeds.
#
# From EVIDENCE_REVIEW.md §Recommended (step 1): the simple-Δ
# scenarios. Each has a canonical ON/OFF flag and a direction claim
# that can be checked with a paired comparison.
#
# Scenarios + canonical claims:
#   s-cooperation      — cooperation_evolution ON: mean_cooperation_level ↑
#                        or: cooperation_on > cooperation_off in acts
#   s-speciation       — speciation ON: n_species > 1 at end
#   s-group_defense    — group_defense ON: n_agents_final higher under predation
#   s-social_learning  — social_learning ON: higher mean_energy (foraging
#                        benefit from copying successful strategies)
#   s-niche            — niche_construction ON: n_shelters_built > 0
#   s-scavenging       — scavenging ON: higher mean_energy under scarcity
#
# All runs at default_specs with viability_report() guard. Any
# "crashed" runs are excluded from the Δ computation and noted.
#
# Usage:  Rscript dev/audit/fidelity/tier_c_batch1.R
# Output: dev/audit/fidelity/tier_c_batch1.rds

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L, 31L, 37L, 43L)

# ── helper: run + viability-guarded metric extraction ──────────────────────
.run_metric <- function(s, metric_fn) {
  env <- suppressWarnings(run_alife(s, verbose = FALSE))
  d   <- get_run_data(env)$ticks
  vr  <- viability_report(d, n_agents_init = s$n_agents_init)
  list(metric = metric_fn(d), n_final = vr$n_final, verdict = vr$verdict)
}

.t_test <- function(on_vals, off_vals, label) {
  on_vals  <- on_vals [!is.na(on_vals)]
  off_vals <- off_vals[!is.na(off_vals)]
  delta <- mean(on_vals) - mean(off_vals)
  se    <- sqrt(sd(on_vals)^2 / length(on_vals) +
                sd(off_vals)^2 / length(off_vals))
  t     <- delta / se
  message(sprintf(
    "  %s: on = %.3f ± %.3f (n=%d), off = %.3f ± %.3f (n=%d)",
    label,
    mean(on_vals), sd(on_vals), length(on_vals),
    mean(off_vals), sd(off_vals), length(off_vals)))
  message(sprintf("  Δ = %+.3f, SE = %.3f, t ≈ %.2f → %s",
                  delta, se, t,
                  if (abs(t) >= 2.0) sprintf("PASS (|t|=%.1f)", abs(t))
                  else sprintf("FAIL (|t|=%.1f)", abs(t))))
  list(delta = delta, se = se, t = t, on_n = length(on_vals),
       off_n = length(off_vals))
}

t0 <- Sys.time()
results <- list()

# ── 1. cooperation — coop acts per tick, ON vs OFF ───────────────────────
message("=== [1/6] cooperation ===")
coop_make <- function(on, seed) {
  s <- default_specs()
  s$cooperation_evolution  <- on
  s$cooperation_multiplier <- 2.5
  s$cooperation_cost       <- 1.0
  s$cooperation_init_mean  <- 0.5
  s$n_agents_init          <- 80L
  s$max_ticks              <- 500L
  s$random_seed            <- as.integer(seed)
  s
}
coop_metric <- function(d) mean(tail(d$n_cooperation_acts, 100L), na.rm = TRUE)
coop_on  <- numeric(); coop_off <- numeric()
coop_crashes <- 0L
for (sd in SEEDS) {
  on  <- .run_metric(coop_make(TRUE,  sd), coop_metric)
  off <- .run_metric(coop_make(FALSE, sd), coop_metric)
  if (on$verdict == "crashed" || off$verdict == "crashed") coop_crashes <- coop_crashes + 1L
  coop_on  <- c(coop_on,  on$metric)
  coop_off <- c(coop_off, off$metric)
  message(sprintf("  seed %2d: on=%.1f (n=%d %s) off=%.1f (n=%d %s)",
                  sd, on$metric, on$n_final, on$verdict,
                  off$metric, off$n_final, off$verdict))
}
results$cooperation <- .t_test(coop_on, coop_off, "coop acts/tick (last 100 t)")
results$cooperation$crashes <- coop_crashes

# ── 2. speciation — final n_species, ON vs OFF ────────────────────────────
message("\n=== [2/6] speciation ===")
spec_make <- function(on, seed) {
  s <- default_specs()
  s$speciation                  <- on
  s$isolation_threshold         <- 0.15
  s$mutation_sd                 <- 0.15
  s$speciation_cluster_interval <- 10L
  s$max_ticks                   <- 1000L
  s$random_seed                 <- as.integer(seed)
  s
}
spec_metric <- function(d) tail(d$n_species, 1L)
spec_on  <- numeric(); spec_off <- numeric()
spec_crashes <- 0L
for (sd in SEEDS) {
  on  <- .run_metric(spec_make(TRUE,  sd), spec_metric)
  off <- .run_metric(spec_make(FALSE, sd), spec_metric)
  if (on$verdict == "crashed" || off$verdict == "crashed") spec_crashes <- spec_crashes + 1L
  spec_on  <- c(spec_on,  on$metric)
  spec_off <- c(spec_off, off$metric)
  message(sprintf("  seed %2d: on=%d off=%d",
                  sd, on$metric, off$metric))
}
results$speciation <- .t_test(spec_on, spec_off, "final n_species")
results$speciation$crashes <- spec_crashes

# ── 3. group_defense — n_agents_final under predation, ON vs OFF ──────────
message("\n=== [3/6] group_defense ===")
gd_make <- function(on, seed) {
  s <- default_specs()
  s$n_predators_init         <- 5L
  s$n_agents_init            <- 100L
  s$grid_rows                <- 30L
  s$grid_cols                <- 30L
  s$group_defense            <- on
  s$group_defense_radius     <- 2L
  s$group_defense_strength   <- 0.3
  s$max_ticks                <- 400L
  s$random_seed              <- as.integer(seed)
  s
}
gd_metric <- function(d) tail(d$n_agents, 1L)
gd_on  <- numeric(); gd_off <- numeric()
gd_crashes <- 0L
for (sd in SEEDS) {
  on  <- .run_metric(gd_make(TRUE,  sd), gd_metric)
  off <- .run_metric(gd_make(FALSE, sd), gd_metric)
  if (on$verdict == "crashed" || off$verdict == "crashed") gd_crashes <- gd_crashes + 1L
  gd_on  <- c(gd_on,  on$metric)
  gd_off <- c(gd_off, off$metric)
  message(sprintf("  seed %2d: on=%d off=%d",
                  sd, on$metric, off$metric))
}
results$group_defense <- .t_test(gd_on, gd_off, "n_agents_final under predation")
results$group_defense$crashes <- gd_crashes

# ── 4. social_learning — mean_energy, ON vs OFF ───────────────────────────
message("\n=== [4/6] social_learning ===")
sl_make <- function(on, seed) {
  s <- default_specs()
  s$n_agents_init          <- 150L   # density needed for copying
  s$grid_rows              <- 20L
  s$grid_cols              <- 20L
  s$social_learning        <- on
  s$social_learning_freq   <- 20L
  s$max_ticks              <- 400L
  s$grass_rate             <- 0.15
  s$random_seed            <- as.integer(seed)
  s
}
sl_metric <- function(d) mean(tail(d$mean_energy, 50L), na.rm = TRUE)
sl_on  <- numeric(); sl_off <- numeric()
sl_crashes <- 0L
for (sd in SEEDS) {
  on  <- .run_metric(sl_make(TRUE,  sd), sl_metric)
  off <- .run_metric(sl_make(FALSE, sd), sl_metric)
  if (on$verdict == "crashed" || off$verdict == "crashed") sl_crashes <- sl_crashes + 1L
  sl_on  <- c(sl_on,  on$metric)
  sl_off <- c(sl_off, off$metric)
  message(sprintf("  seed %2d: on=%.1f off=%.1f",
                  sd, on$metric, off$metric))
}
results$social_learning <- .t_test(sl_on, sl_off, "mean_energy (last 50 t)")
results$social_learning$crashes <- sl_crashes

# ── 5. niche — n_shelters_built ON vs OFF ─────────────────────────────────
message("\n=== [5/6] niche ===")
niche_make <- function(on, seed) {
  s <- default_specs()
  s$niche_construction <- on
  s$shelter_build_prob <- 0.2
  s$shelter_max_depth  <- 5L
  s$grid_rows          <- 30L
  s$grid_cols          <- 30L
  s$n_agents_init      <- 25L
  s$max_ticks          <- 400L
  s$random_seed        <- as.integer(seed)
  s
}
niche_metric <- function(d) sum(d$n_shelters_built, na.rm = TRUE)
niche_on  <- numeric(); niche_off <- numeric()
niche_crashes <- 0L
for (sd in SEEDS) {
  on  <- .run_metric(niche_make(TRUE,  sd), niche_metric)
  off <- .run_metric(niche_make(FALSE, sd), niche_metric)
  if (on$verdict == "crashed" || off$verdict == "crashed") niche_crashes <- niche_crashes + 1L
  niche_on  <- c(niche_on,  on$metric)
  niche_off <- c(niche_off, off$metric)
  message(sprintf("  seed %2d: on=%d off=%d",
                  sd, on$metric, off$metric))
}
results$niche <- .t_test(niche_on, niche_off, "total shelters built")
results$niche$crashes <- niche_crashes

# ── 6. scavenging — mean_energy under scarcity, ON vs OFF ─────────────────
message("\n=== [6/6] scavenging ===")
sc_make <- function(on, seed) {
  s <- default_specs()
  s$n_agents_init         <- 100L
  s$grid_rows             <- 30L
  s$grid_cols             <- 30L
  s$grass_rate            <- 0.15
  s$scavenging            <- on
  s$carrion_fraction      <- 0.5
  s$carrion_decay_rate    <- 0.1
  s$carrion_eat_gain      <- 3.0
  s$max_ticks             <- 400L
  s$random_seed           <- as.integer(seed)
  s
}
sc_metric <- function(d) mean(tail(d$mean_energy, 50L), na.rm = TRUE)
sc_on  <- numeric(); sc_off <- numeric()
sc_crashes <- 0L
for (sd in SEEDS) {
  on  <- .run_metric(sc_make(TRUE,  sd), sc_metric)
  off <- .run_metric(sc_make(FALSE, sd), sc_metric)
  if (on$verdict == "crashed" || off$verdict == "crashed") sc_crashes <- sc_crashes + 1L
  sc_on  <- c(sc_on,  on$metric)
  sc_off <- c(sc_off, off$metric)
  message(sprintf("  seed %2d: on=%.1f off=%.1f",
                  sd, on$metric, off$metric))
}
results$scavenging <- .t_test(sc_on, sc_off, "mean_energy (last 50 t)")
results$scavenging$crashes <- sc_crashes

saveRDS(results, "dev/audit/fidelity/tier_c_batch1.rds")

message("\n── Batch summary ──")
for (nm in names(results)) {
  r <- results[[nm]]
  verdict <- if (abs(r$t) >= 2.0) "PASS (t ≥ 2)" else "RECHECK (t < 2)"
  message(sprintf("  %-16s | Δ = %+7.3f | t = %5.2f | crashes: %d/8 | %s",
                  nm, r$delta, r$t, r$crashes, verdict))
}

message(sprintf("\n=== Batch done in %.1f min ===",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))
