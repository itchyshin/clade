# Emlen (1982) reproduction
# "The evolution of helping. I. An ecological constraints model",
# American Naturalist 119(1):29-39
#
# Core claim: cooperative breeding (helping at the nest) evolves
# when ecological constraints limit independent breeding
# opportunities. Helpers stay home because they CANNOT breed
# independently — not because of kin altruism per se. Habitat
# saturation + limited breeding sites → helping is the only
# option.
#
# clade test: we don't have explicit "habitat saturation" but
# we can approximate ecological constraints by varying resource
# scarcity (grass_rate). Sweep grass_rate × cooperative_breeding
# and measure helper_tendency evolution + helping events.
#
# Toolkit demo: hypothesis_sweep with the helper_tendency metric;
# the s-kin invasion honest null from PR #90 predicts we may
# find that helper_tendency *doesn't* invade even under
# ecological constraints — a documented kernel limitation.

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
base$max_agents      <- 400L
base$max_ticks       <- 3000L
base$n_predators_init <- 0L

# Cooperative breeding machinery
base$parental_care                  <- TRUE
base$juvenile_independence_age      <- 10L
base$cooperative_breeding           <- TRUE
base$helper_tendency_init_mean      <- 0.2   # start moderate — give invasion a head start
base$helper_tendency_mutation_sd    <- 0.02
base$helper_min_energy              <- 60.0
base$helper_kin_threshold           <- 0.25
base$helper_transfer                <- 3.0

# ---------------------------------------------------------------
# Emlen's ecological-constraints sweep: grass_rate varies from
# abundant (low constraint) to scarce (high constraint)
# ---------------------------------------------------------------
cat("=== Emlen 1982: ecological-constraints sweep ===\n")
conds <- list(
  abundant       = list(grass_rate = 0.25),
  moderate_abund = list(grass_rate = 0.15),
  scarce         = list(grass_rate = 0.10),
  very_scarce    = list(grass_rate = 0.06)
)

sweep <- hypothesis_sweep(
  base_specs = base,
  conditions = conds,
  seeds = 1:8,
  metrics = list(
    final_helper_tendency = function(t) mean(tail(t$mean_helper_tendency, 500), na.rm = TRUE),
    total_helper_events   = function(t) sum(t$n_helpers, na.rm = TRUE),
    final_n               = function(t) mean(tail(t$n_agents, 500), na.rm = TRUE),
    crashed               = function(t) tail(t$n_agents, 1L) < 10L
  ),
  n_cores = 32L
)
print(sweep)

# ---------------------------------------------------------------
# Contrasts: does ecological constraint (scarcity) elevate
# helper_tendency relative to abundant resources?
# ---------------------------------------------------------------
contrasts <- list(
  moderate_vs_abundant    = c("abundant", "moderate_abund"),
  scarce_vs_abundant      = c("abundant", "scarce"),
  very_scarce_vs_abundant = c("abundant", "very_scarce")
)
rpt <- hypothesis_report(sweep, contrasts, metric = "final_helper_tendency")
cat("\n=== Emlen contrasts: helper_tendency vs ecological constraint ===\n")
print(rpt)

# Spearman across all runs
grass_vals <- c(abundant = 0.25, moderate_abund = 0.15,
                scarce = 0.10, very_scarce = 0.06)
sp <- cor(grass_vals[sweep$runs$condition],
          sweep$runs$final_helper_tendency,
          method = "spearman", use = "complete.obs")
cat(sprintf("\nSpearman(grass_rate, final_helper_tendency) = %+.3f\n", sp))
cat("Emlen 1982 predict: NEGATIVE — scarcer resources → more helping.\n")

# Also check absolute helping-event counts — Emlen's actual observable
# behaviour.
rpt_events <- hypothesis_report(sweep, contrasts, metric = "total_helper_events")
cat("\n=== Total helping events (Emlen's observable behaviour) ===\n")
print(rpt_events)

saveRDS(list(sweep = sweep, report_tendency = rpt,
             report_events = rpt_events, spearman = sp),
        "dev/audit/fidelity/paper_emlen_1982.rds")
cat("\nSaved: dev/audit/fidelity/paper_emlen_1982.rds\n")
