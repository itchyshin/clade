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

saveRDS(list(sweep = sweep, report = rpt_n,
             interaction = list(delta = int_delta, se = int_se, t = int_t)),
        "dev/audit/fidelity/kokko_brooks_2003.rds")
cat("\nSaved: dev/audit/fidelity/kokko_brooks_2003.rds\n")
