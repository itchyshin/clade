# Fuller, Houle & Travis (2005) — sensory bias + mate-preference evolution
#
# Fuller, R. C., Houle, D. & Travis, J. (2005). Sensory bias as an
# explanation for the evolution of mate preferences. American
# Naturalist 166(4):437-446.
#
# Part of a cluster with Ryan 1990, Ryan et al. 1990 Nature
# (túngara frog chuck preference), Endler & Basolo 1998.
#
# Fuller's theoretical point: "sensory bias" and "Fisherian
# coevolution" are NOT mutually exclusive — both mechanisms can
# contribute simultaneously. Genetic correlations between sensory
# systems and mate preferences mean that selection on the sensory
# system (for non-mating functions) spills into mate-preference
# evolution, and vice versa.
#
# What clade can test directly:
#   - Does preference-based mate choice drive signal elaboration
#     beyond neutral drift? (the outcome: elaborate signals)
#   - How does `signal_cost` modulate that elaboration?
#
# What clade CAN'T test here:
#   - Signal-direction vs preference-direction alignment
#     (clade logs scalar `mean_signal_magnitude` only)
#   - Pre-existing bias signatures without a per-agent trait dump
#   - Genetic correlations between sensory and preference systems
#     (no preference trait in default log output)
#
# The vignette will be honest about this split.

suppressPackageStartupMessages({
  if (requireNamespace("devtools", quietly = TRUE))
    devtools::load_all(quiet = TRUE)
  else
    library(clade)
})

base <- default_specs()
base$grid_rows       <- 40L
base$grid_cols       <- 40L
base$n_agents_init   <- 120L
base$max_agents      <- 500L
base$max_ticks       <- 3000L
base$grass_rate      <- 0.15
base$n_predators_init <- 0L
base$signal_dims     <- 3L
base$signal_evolution_drift <- TRUE
base$signal_drift_sd <- 0.05   # larger drift so selection has room to act

# Fuller's point: elaborate signals can arise from multiple
# selection regimes. Test 2x3 factorial on mate-choice mode x cost.
# - random + cost=0        : null (drift alone)
# - random + cost>0        : cost without mate-choice — signals should erode
# - preference + cost=0    : pure Fisherian coevolution (runaway regime)
# - preference + cost=0.1  : Fisher + mild cost (pre-Zahavi)
# - preference + cost=0.3  : Fisher + strong cost (handicap regime)
# (+ null for sanity: signal_dims=0 baseline)

cat("=== Fuller 2005 — mate choice x cost signal-elaboration sweep ===\n")

sweep <- hypothesis_sweep(
  base_specs = base,
  conditions = list(
    null_no_signals    = list(signal_dims = 0L, signal_cost = 0.0,
                               mate_choice_mode = "random"),
    random_no_cost     = list(signal_cost = 0.0,
                               mate_choice_mode = "random"),
    random_with_cost   = list(signal_cost = 0.2,
                               mate_choice_mode = "random"),
    preference_no_cost = list(signal_cost = 0.0,
                               mate_choice_mode = "preference",
                               mate_choice_strength = 1.0),
    preference_mild    = list(signal_cost = 0.1,
                               mate_choice_mode = "preference",
                               mate_choice_strength = 1.0),
    preference_strong  = list(signal_cost = 0.3,
                               mate_choice_mode = "preference",
                               mate_choice_strength = 1.0)
  ),
  seeds = 1:8,
  metrics = list(
    final_signal  = function(t) mean(utils::tail(t$mean_signal_magnitude, 500L),
                                     na.rm = TRUE),
    final_n       = function(t) mean(utils::tail(t$n_agents, 500L), na.rm = TRUE),
    mean_energy   = function(t) mean(utils::tail(t$mean_energy, 500L), na.rm = TRUE)
  ),
  n_cores = 48L
)
print(sweep)

# Pairwise contrasts: does preference-mate-choice beat random at the
# same cost level?
rpt <- hypothesis_report(
  sweep,
  contrasts = list(
    # Fuller's core comparison: does mate-choice regime drive
    # signal elaboration beyond drift?
    pref_vs_random_nocost = c("random_no_cost", "preference_no_cost"),
    # And under cost? (the Zahavi-ish regime)
    pref_vs_random_mildcost = c("random_with_cost", "preference_mild")
  ),
  metric = "final_signal"
)
cat("\n=== Signal-elaboration contrasts ===\n")
print(rpt)

# How much does signal grow under each regime?
cat("\n=== Per-condition signal magnitudes ===\n")
agg <- aggregate(final_signal ~ condition, data = sweep$runs,
                 FUN = function(x) sprintf("%.3f ± %.3f",
                                           mean(x, na.rm = TRUE),
                                           sd(x, na.rm = TRUE) / sqrt(length(x))))
print(agg, row.names = FALSE)

# Save
saveRDS(list(sweep = sweep, report = rpt),
        "dev/audit/fidelity/paper_fuller_2005.rds")
cat("\nSaved: dev/audit/fidelity/paper_fuller_2005.rds\n")
