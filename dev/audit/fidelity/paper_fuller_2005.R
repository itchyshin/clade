# Fuller, Houle & Travis (2005) — sensory bias + mate-preference evolution
#
# Fuller, R. C., Houle, D. & Travis, J. (2005). Sensory bias as an
# explanation for the evolution of mate preferences. American
# Naturalist 166(4):437-446.
#
# Part of a cluster with Ryan 1990, Ryan et al. 1990 Nature
# (túngara frog chuck preference), Endler & Basolo 1998.
#
# Fuller's quantitative-genetic framework Δz̄ = G(β_N + β_S) + u
# separates three mechanisms by which β and G terms take non-zero
# values:
#   - Sensory bias (Ryan 1990)       — preferences shaped by β_N
#                                       on sensory system, then signals
#                                       evolve to exploit them
#   - Fisher runaway (Fisher 1930)   — signal-preference coevolution,
#                                       C_tp > 0 in the G-matrix
#   - Zahavi handicap (Zahavi 1975)  — β_Sv < 0, viability cost on
#                                       display
#
# Kernel coverage as of 0.6.3:
#   - Zahavi handicap: implemented via `signal_cost_mortality` (added
#     0.6.3 — direct per-tick mortality scaling with signal magnitude).
#     THIS VIGNETTE demonstrates the dose-response signature.
#   - Fisher runaway: blocked. `mate_choice_mode` is a documented-but-
#     unwired spec field; reproduce.jl always uses preference-based
#     mate choice when signal_dims > 0 (see reproduce.jl:260-283).
#     The Fisher-vs-drift contrast is not currently testable.
#   - Sensory bias (sensu stricto): not implemented. Requires a
#     mechanism that installs preferences independently of mate choice
#     (e.g., coupling preferences to a non-mating fitness gradient).
#
# This script audits the Zahavi dose-response only. Both Fisher and
# sensory bias remain documented kernel-limit nulls in the vignette.

suppressPackageStartupMessages({
  library(clade)
})

base <- default_specs()
base$grid_rows              <- 40L
base$grid_cols              <- 40L
base$n_agents_init          <- 120L
base$max_agents             <- 500L
base$max_ticks              <- 3000L
base$grass_rate             <- 0.15
base$n_predators_init       <- 0L
base$signal_dims            <- 3L
base$signal_evolution_drift <- TRUE
base$signal_drift_sd        <- 0.05

cat("=== Fuller 2005 — Zahavi β_Sv dose-response audit ===\n")
cat("    (0.6.2 framework metrics + 0.6.3 signal_cost_mortality)\n\n")

sweep <- hypothesis_sweep(
  base_specs = base,
  conditions = list(
    null_no_signals = list(signal_dims = 0L),
    zahavi_off      = list(signal_cost_mortality = 0.000),
    zahavi_weak     = list(signal_cost_mortality = 0.001),
    zahavi_mild     = list(signal_cost_mortality = 0.002),
    zahavi_moderate = list(signal_cost_mortality = 0.003)
  ),
  seeds = 1:8,
  metrics = list(
    final_signal  = function(t) mean(utils::tail(t$mean_signal_magnitude, 500L),
                                     na.rm = TRUE),
    final_pref    = function(t) mean(utils::tail(t$mean_preference_magnitude, 500L),
                                     na.rm = TRUE),
    final_sp_dist = function(t) mean(utils::tail(t$mean_signal_preference_dist, 500L),
                                     na.rm = TRUE),
    final_sig_sd  = function(t) mean(utils::tail(t$sd_signal_magnitude, 500L),
                                     na.rm = TRUE),
    final_n       = function(t) mean(utils::tail(t$n_agents, 500L), na.rm = TRUE)
  ),
  n_cores = 40L
)
print(sweep)

cat("\n=== Dose-response: mortality × signal magnitude (mean ± SE, 8 seeds) ===\n")
agg <- aggregate(cbind(final_signal, final_pref, final_sp_dist,
                       final_sig_sd, final_n) ~ condition,
                 data = sweep$runs,
                 FUN = function(x) sprintf("%.3f ± %.3f",
                                           mean(x, na.rm = TRUE),
                                           sd(x, na.rm = TRUE) / sqrt(length(x))))
print(agg, row.names = FALSE)

cat("\n=== Zahavi β_Sv signature: signal declines with mortality ===\n")
rpt <- hypothesis_report(
  sweep,
  contrasts = list(
    weak_vs_off     = c("zahavi_off", "zahavi_weak"),
    mild_vs_off     = c("zahavi_off", "zahavi_mild"),
    moderate_vs_off = c("zahavi_off", "zahavi_moderate")
  ),
  metric = "final_signal"
)
print(rpt)
cat("\nPASS verdicts → handicap mechanism reproducibly shrinks display.\n")

# -----------------------------------------------------------------------------
# 0.6.4 Fisher C_tp test — direction-wrong finding
# -----------------------------------------------------------------------------
# With `mate_choice_mode` wired (0.6.4), we can now contrast random mating
# (drift_only) against preference-argmax mating (fisher_pure). Fisher runaway
# predicts final_sp_dist SHRINKS under preference mating (C_tp > 0 builds up).
# Result: direction-wrong — clade has no genetic linkage between signal and
# preference loci, so C_tp cannot accumulate via mate choice alone.
cat("\n=== Fisher C_tp test (0.6.4 — mate_choice_mode wired) ===\n")
sweep_fisher <- hypothesis_sweep(
  base_specs = base,
  conditions = list(
    drift_only  = list(mate_choice_mode = "random"),
    fisher_pure = list(mate_choice_mode = "preference",
                       mate_choice_strength = 1.0)
  ),
  seeds = 1:8,
  metrics = list(
    final_signal  = function(t) mean(utils::tail(t$mean_signal_magnitude, 500L),
                                     na.rm = TRUE),
    final_sp_dist = function(t) mean(utils::tail(t$mean_signal_preference_dist, 500L),
                                     na.rm = TRUE)
  ),
  n_cores = 16L
)
rpt_fisher <- hypothesis_report(
  sweep_fisher,
  contrasts = list(fisher_ctp = c("drift_only", "fisher_pure")),
  metric    = "final_sp_dist"
)
print(rpt_fisher)
cat("\nFisher prediction: Δ final_sp_dist < 0 (preference mating builds C_tp > 0).\n")
cat("Observed: Δ > 0 (direction-wrong) — kernel has no genetic linkage between\n")
cat("signal and preference loci, so C_tp cannot accumulate via mate choice.\n")

saveRDS(list(sweep        = sweep,
             report       = rpt,
             sweep_fisher = sweep_fisher,
             rpt_fisher   = rpt_fisher),
        "dev/audit/fidelity/paper_fuller_2005.rds")
cat("\nSaved: dev/audit/fidelity/paper_fuller_2005.rds\n")
