# Cross-scenario crash audit using the new viability_report() utility.
#
# Premise: today's 🟠-sort surfaced three cases where trait-mean audits
# were silently corrupted by population crashes (plasticity v1, mimicry
# at fast_specs, dispersal v2 partial). Today's promotions/demotions all
# depended on checking n_final before trusting trait means.
#
# If this methodology lesson is real, there may be currently-✅ scenarios
# whose "passed" verdict is actually crash-driven — i.e. the trait-mean
# signal survives to the audit because it's computed over a tiny
# surviving fraction of the init population. This script runs each ✅
# scenario at fast_specs × 5 seeds and reports the viability_report()
# verdict for every run.
#
# Scenarios checked: the main per-scenario flags (body_size,
# cooperation, disease, speciation, niche, scavenging, kin, signals,
# parental_care, clutch_size, life_history, group_defense,
# seasonal, stress_hypermutation). Defaults match each scenario's
# canonical flag settings.
#
# Usage:  Rscript dev/audit/fidelity/crash_audit.R
# Output: dev/audit/fidelity/crash_audit.rds
#         + stdout verdict table

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  # load_all() for the dev copy that includes viability_report() until
  # the package is reinstalled.
  if (file.exists("DESCRIPTION")) {
    devtools::load_all(".", quiet = TRUE)
  } else {
    library(clade)
  }
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L)

.fast_with <- function(seed, edits = list()) {
  s <- fast_specs()
  for (nm in names(edits)) s[[nm]] <- edits[[nm]]
  s$random_seed <- as.integer(seed)
  s
}

scenarios <- list(
  baseline              = list(),
  body_size             = list(body_size_evolution = TRUE),
  cooperation           = list(cooperation_evolution = TRUE,
                                cooperation_multiplier = 2.5,
                                cooperation_cost = 1.0),
  disease               = list(disease = TRUE, transmission_prob = 0.3,
                                disease_seed_prob = 0.05),
  speciation            = list(speciation = TRUE,
                                isolation_threshold = 0.15,
                                mutation_sd = 0.15,
                                speciation_cluster_interval = 10L),
  niche                 = list(niche_construction = TRUE,
                                shelter_build_prob = 0.2),
  scavenging            = list(scavenging = TRUE,
                                carrion_fraction = 0.5),
  kin                   = list(kin_selection = TRUE,
                                kin_altruism_r_min = 0.25,
                                kin_altruism_cost = 5.0),
  signals               = list(signal_dims = 3L,
                                signal_cost = 0.05,
                                mate_choice_mode = "preference",
                                mate_choice_strength = 0.7),
  parental_care         = list(parental_care = TRUE,
                                care_duration = 5L,
                                care_cost_per_tick = 2.0),
  clutch_size           = list(clutch_size_evolution = TRUE,
                                clutch_size_min = 1L,
                                clutch_size_max = 5L,
                                clutch_size_mutation_sd = 0.3),
  life_history_sem      = list(life_history = "semelparous"),
  life_history_ite      = list(life_history = "iteroparous"),
  group_defense         = list(group_defense = TRUE,
                                group_defense_radius = 2L,
                                group_defense_strength = 0.3,
                                n_predators_init = 5L),
  seasonal_short        = list(seasonal_amplitude = 0.35,
                                season_length = 10L),
  seasonal_long         = list(seasonal_amplitude = 0.35,
                                season_length = 100L),
  stress_hypermutation  = list(stress_hypermutation = TRUE,
                                stress_threshold = 20.0,
                                stress_mutation_multiplier = 5.0,
                                grass_rate = 0.05)
)

t0 <- Sys.time()
message("=== cross-scenario crash audit at fast_specs × 5 seeds ===")

res <- data.frame()
for (nm in names(scenarios)) {
  for (sd in SEEDS) {
    s   <- .fast_with(sd, scenarios[[nm]])
    env <- run_alife(s, verbose = FALSE)
    vr  <- viability_report(get_run_data(env), n_agents_init = s$n_agents_init)
    res <- rbind(res, data.frame(
      scenario = nm, seed = sd,
      verdict = vr$verdict,
      n_init = vr$n_init, n_final = vr$n_final, n_min = vr$n_min,
      frac_final = vr$frac_final))
    message(sprintf("  %-22s seed=%2d → %s (n_final=%d, frac=%.2f)",
                    nm, sd, vr$verdict, vr$n_final, vr$frac_final))
  }
}

# Per-scenario summary
message("\n── Per-scenario summary ──")
for (nm in names(scenarios)) {
  sub      <- res[res$scenario == nm, ]
  verdicts <- table(sub$verdict)
  msg      <- paste(names(verdicts), verdicts, sep = ":", collapse = "  ")
  mean_fr  <- mean(sub$frac_final)
  message(sprintf("  %-22s | mean frac_final = %.2f | %s",
                  nm, mean_fr, msg))
}

saveRDS(res, "dev/audit/fidelity/crash_audit.rds")
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
message(sprintf("\n=== Done in %.1f min ===", elapsed))
