# Kokko & Brooks (2003) reproduction — "Sexy to die for?"
#
# Kokko, H. & Brooks, R. (2003). Sexy to die for? Sexual selection
# and the risk of extinction. Annales Zoologici Fennici 40:207-219.
#
# Core claim: evolutionary "suicide" from costly sexual traits is
# UNLIKELY in stable environments; it becomes possible under
# environmental stress. Testable as a 2×2 interaction.
#
# Design: signal_cost ∈ {none, high} × grass_rate ∈ {high, low}
#   C1 stable_no_signals   — control (baseline survival)
#   C2 stable_with_signals — sexual selection, stable env
#   C3 stress_no_signals   — env stress alone
#   C4 stress_with_signals — both (K&B prediction: worst)
#
# Expected K&B signature:
#   signals_effect @ stable ≈ 0        (Δ C2 − C1, stable)
#   signals_effect @ stress < 0        (Δ C4 − C3, stressed)
#   |signals@stress| > |signals@stable| — the interaction

suppressPackageStartupMessages({
  # Use devtools::load_all() to pick up in-development R/hypothesis.R
  # helpers; switch to library(clade) once merged to main.
  if (requireNamespace("devtools", quietly = TRUE)) {
    devtools::load_all(quiet = TRUE)
  } else {
    library(clade)
  }
})
cat("Loaded clade\n")

base <- default_specs()
base$grid_rows       <- 40L
base$grid_cols       <- 40L
base$n_agents_init   <- 120L
base$max_agents      <- 500L
base$max_ticks       <- 2000L
# n_predators_init = 0 — we want demographic stress coming from
# resource limitation, not external mortality (clean env-stress signal)
base$n_predators_init <- 0L

SIGNAL_COST <- 0.2   # "high cost" arm — above audit-observed cost-of-drift
SIGNAL_DIMS <- 3L

# ---------------------------------------------------------------
# Stage 1: grid search across (signal_cost × grass_rate)
# ---------------------------------------------------------------
# Before the validation sweep, use grid_specs + batch_alife to scan
# a wider cost × stress space. This tests whether the K&B interaction
# *ever* goes the predicted direction (negative) at any cost level.
# If it never does, the contradiction we find in Stage 2 is robust.
cat("=== Stage 1: 5 × 4 grid search over (signal_cost × grass_rate) ===\n")
COST_LEVELS  <- c(0.0, 0.1, 0.2, 0.4, 0.8)
GRASS_LEVELS <- c(0.20, 0.12, 0.08, 0.05)

make_grid_spec <- function(cost, grass) {
  s <- base
  if (cost > 0) {
    s$signal_dims            <- SIGNAL_DIMS
    s$signal_cost            <- cost
    s$signal_evolution_drift <- TRUE
    s$signal_drift_sd        <- 0.01
    s$mate_choice_mode       <- "preference"
    s$mate_choice_strength   <- 0.7
  } else {
    s$signal_dims      <- 0L
    s$signal_cost      <- 0.0
    s$mate_choice_mode <- "random"
  }
  s$grass_rate <- grass
  s
}

# Build 5×4=20 cells; 1 seed each for fast regime-mapping
grid_spec_list <- list()
grid_meta      <- data.frame(cost = numeric(0), grass = numeric(0),
                             stringsAsFactors = FALSE)
for (c in COST_LEVELS) for (g in GRASS_LEVELS) {
  grid_spec_list[[sprintf("c%.1f_g%.2f", c, g)]] <- make_grid_spec(c, g)
  grid_meta <- rbind(grid_meta, data.frame(cost = c, grass = g))
}
grid_spec_list <- lapply(seq_along(grid_spec_list), function(i) {
  s <- grid_spec_list[[i]]
  s$random_seed <- 7L
  s
})
names(grid_spec_list) <- paste0(grid_meta$cost, "_", grid_meta$grass)

t0 <- Sys.time()
grid_envs <- batch_alife(grid_spec_list, n_cores = 20L, verbose = FALSE)
cat(sprintf("  Grid complete in %.1fs\n",
            as.numeric(difftime(Sys.time(), t0, units = "secs"))))

grid_tbl <- do.call(rbind, mapply(function(env, i) {
  d <- get_run_data(env)$ticks
  data.frame(
    cost = grid_meta$cost[i],
    grass = grid_meta$grass[i],
    final_n = mean(utils::tail(d$n_agents, 500L), na.rm = TRUE)
  )
}, grid_envs, seq_along(grid_envs), SIMPLIFY = FALSE))

cat("\n  Grid — final_n at each (cost, grass) cell (1-seed):\n")
grid_wide <- reshape(grid_tbl, idvar = "cost", timevar = "grass",
                     direction = "wide")
names(grid_wide) <- c("signal_cost", paste0("grass=", GRASS_LEVELS))
print(grid_wide, row.names = FALSE)

# Compute signals-effect slope at each grass level: Δn(cost>0) − Δn(cost=0)
# Then see if it gets MORE negative at lower grass (K&B prediction).
cat("\n  Signals-effect (mean of cost>0 cells minus cost=0 cell) per grass:\n")
slopes <- do.call(rbind, lapply(GRASS_LEVELS, function(g) {
  ref <- grid_tbl$final_n[grid_tbl$cost == 0.0 & grid_tbl$grass == g]
  test_mean <- mean(grid_tbl$final_n[grid_tbl$cost > 0.0 & grid_tbl$grass == g],
                    na.rm = TRUE)
  data.frame(grass_rate = g, signals_effect_mean = test_mean - ref)
}))
print(slopes, row.names = FALSE)
cat("\n  K&B predict: signals_effect grows MORE NEGATIVE as grass drops.\n")
cat("  A positive or flat trend across the grass gradient CONTRADICTS K&B.\n")

# ---------------------------------------------------------------
# Stage 2: multi-seed validation — original 2 × 4 factorial
# ---------------------------------------------------------------
cat("\n=== Stage 2: hypothesis_sweep 2 × 4 factorial, 8 seeds ===\n")

# Dose-response: 4 stress levels, not just 2. K&B's interaction
# claim is that the signal-effect curve should *steepen* as stress
# intensifies. A proper 4-level sweep lets the interaction emerge
# (or not) as a gradient, rather than rely on a single binary stress.
GRASS_LEVELS <- c(abundant = 0.20, mid = 0.12, scarce = 0.08, very_scarce = 0.05)

# Helper: generate condition list for one grass level × one signal state
make_cond <- function(grass, signals_on) {
  if (signals_on) {
    list(
      signal_dims            = SIGNAL_DIMS,
      signal_cost            = SIGNAL_COST,
      signal_evolution_drift = TRUE,
      signal_drift_sd        = 0.01,
      mate_choice_mode       = "preference",
      mate_choice_strength   = 0.7,
      grass_rate             = grass
    )
  } else {
    list(
      signal_dims      = 0L,
      signal_cost      = 0.0,
      mate_choice_mode = "random",
      grass_rate       = grass
    )
  }
}

conds <- list()
for (level_name in names(GRASS_LEVELS)) {
  g <- GRASS_LEVELS[[level_name]]
  conds[[sprintf("%s_no_signals",   level_name)]] <- make_cond(g, FALSE)
  conds[[sprintf("%s_with_signals", level_name)]] <- make_cond(g, TRUE)
}

sweep <- hypothesis_sweep(
  base_specs = base,
  conditions = conds,
  seeds = 1:8,
  metrics = list(
    final_n     = function(ticks) mean(utils::tail(ticks$n_agents, 500L),
                                       na.rm = TRUE),
    crashed     = function(ticks) utils::tail(ticks$n_agents, 1L) < 10L,
    mean_energy = function(ticks) mean(utils::tail(ticks$mean_energy, 500L),
                                       na.rm = TRUE)
  ),
  n_cores = 32L
)

cat("\n=== Sweep summary ===\n")
print(sweep)

cat("\n=== Signals effect at each stress level ===\n")
# One "signals vs no signals" contrast per grass level
signals_contrasts <- setNames(
  lapply(names(GRASS_LEVELS), function(ln) {
    c(sprintf("%s_no_signals", ln), sprintf("%s_with_signals", ln))
  }),
  sprintf("signals_effect_%s", names(GRASS_LEVELS))
)
rpt_n <- hypothesis_report(sweep, signals_contrasts, metric = "final_n")
print(rpt_n)

# K&B interaction: does the signals-effect slope get STEEPER as grass
# drops (more negative)? Test this by comparing signals_effect at the
# extremes.
tbl <- rpt_n$table
abundant_delta <- tbl$delta[tbl$contrast == "signals_effect_abundant"]
abundant_se    <- tbl$se[tbl$contrast    == "signals_effect_abundant"]
vs_delta <- tbl$delta[tbl$contrast == "signals_effect_very_scarce"]
vs_se    <- tbl$se[tbl$contrast    == "signals_effect_very_scarce"]

int_delta <- vs_delta - abundant_delta
int_se    <- sqrt(vs_se^2 + abundant_se^2)
int_t     <- int_delta / int_se
verdict   <- if (abs(int_t) >= 2) "PASS" else if (abs(int_t) >= 1.5) "marginal" else "null"

cat(sprintf("\n=== K&B interaction test ===\n"))
cat(sprintf("  signals_effect @ abundant    = %+.2f ± %.2f\n",
            abundant_delta, abundant_se))
cat(sprintf("  signals_effect @ very_scarce = %+.2f ± %.2f\n",
            vs_delta, vs_se))
cat(sprintf("  Δ(very_scarce − abundant)    = %+.2f ± %.2f, t = %+.2f [%s]\n",
            int_delta, int_se, int_t, verdict))
cat("  K&B predict: Δ NEGATIVE (signals hurt MORE under stress).\n")
cat("  A POSITIVE Δ would mean signals hurt LESS under stress (clade contradicts K&B).\n")

# Also check extinction rate (K&B's primary outcome)
cat("\n=== Extinction rates ===\n")
ext_tbl <- aggregate(crashed ~ condition, data = sweep$runs,
                     FUN = function(x) sprintf("%d/%d", sum(x), length(x)))
print(ext_tbl, row.names = FALSE)

# ---------------------------------------------------------------
# Stage 3: viability check at the most extreme (very_scarce + signals)
# ---------------------------------------------------------------
# Uses viability_report() to confirm the stressed+signals condition
# isn't sitting at a pathological fitness floor.
cat("\n=== Stage 3: viability_report at stress+signals ===\n")
s_check <- base
s_check$signal_dims            <- SIGNAL_DIMS
s_check$signal_cost            <- SIGNAL_COST
s_check$signal_evolution_drift <- TRUE
s_check$signal_drift_sd        <- 0.01
s_check$mate_choice_mode       <- "preference"
s_check$mate_choice_strength   <- 0.7
s_check$grass_rate             <- 0.05
s_check$random_seed            <- 1L
env_check <- run_alife(s_check, verbose = FALSE)
vr <- viability_report(get_run_data(env_check))
print(vr)

saveRDS(list(
  stage1_grid   = grid_tbl,
  stage1_slopes = slopes,
  stage2_sweep  = sweep,
  stage2_report = rpt_n,
  stage2_interaction = list(delta = int_delta, se = int_se, t = int_t),
  stage3_viability = vr
), "dev/audit/fidelity/kokko_brooks_2003.rds")
cat("\nSaved: dev/audit/fidelity/kokko_brooks_2003.rds\n")
