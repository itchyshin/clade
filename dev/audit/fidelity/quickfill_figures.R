# Quick-fill generator for orphan scenario figures.
#
# The vignettes reference ~20 showcase_<name>.png figures that no generator
# script has ever produced; the committed PNGs are placeholders saying
# "run generate_figures.R to build". This script plugs the gap: for each
# orphan, it runs the scenario's canonical flag turned on, calls
# plot_run(), and saves a real 6-panel dashboard.
#
# This is deliberately not a fidelity pass — figures show "here is what
# the current code does with this module on", not a multi-seed
# primary-source reproduction. The fidelity audit (dev/audit/fidelity/)
# will replace these figures one scenario at a time.
#
# Usage:  Rscript dev/audit/fidelity/quickfill_figures.R
# Time:   ~10 min wall clock (Julia session + ~30 s per scenario).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
  library(ggplot2)
})

.save_pair <- function(p, name, w = 9, h = 6, dpi = 150) {
  for (d in c("inst/figures", "vignettes/figures")) {
    ggsave(file.path(d, paste0("showcase_", name, ".png")),
           plot = p, width = w, height = h, dpi = dpi)
  }
  message(sprintf("  saved: showcase_%s.png", name))
}

# Canonical specs per orphan figure. Each returns a specs list with the
# scenario's defining flags set; other fields stay at default_specs().
.build <- function(flag_set) {
  s <- default_specs()
  s$grid_rows     <- 30L
  s$grid_cols     <- 30L
  s$n_agents_init <- 100L
  s$max_ticks     <- 300L
  s$random_seed   <- 42L
  for (nm in names(flag_set)) s[[nm]] <- flag_set[[nm]]
  s
}

orphans <- list(
  `13_disease`              = list(disease = TRUE, transmission_prob = 0.20,
                                    disease_seed_prob = 0.05),
  `14_predators`            = list(n_predators_init = 5L, grass_rate = 0.3,
                                    max_ticks = 500L),
  `15_group_defense`        = list(group_defense = TRUE, n_predators_init = 5L),
  `16_habitat_preference`   = list(complex_landscape = TRUE,
                                    shrub_density = 0.35,
                                    canopy_density = 0.15),
  `17_seasons`              = list(seasonal_amplitude = 0.8,
                                    season_length = 100L,
                                    winter_death_prob = 0.05,
                                    max_ticks = 500L),
  `18_speciation`           = list(speciation = TRUE,
                                    isolation_threshold = 0.15,
                                    mutation_sd = 0.15,
                                    speciation_cluster_interval = 10L,
                                    max_ticks = 1000L,
                                    random_seed = 55L),
  `19_parental_care`        = list(parental_care = TRUE,
                                    care_duration = 5L,
                                    care_cost_per_tick = 2.0),
  `20_cooperative_breeding` = list(cooperative_breeding = TRUE,
                                    helper_tendency_init_mean = 0.2,
                                    max_ticks = 400L),
  `21_mimicry`              = list(mimicry = TRUE,
                                    n_predators_init = 5L,
                                    toxicity_init_mean = 0.1),
  `22_plasticity`           = list(phenotypic_plasticity = TRUE),
  `bnn_uncertainty`         = list(brain_type = "bnn", max_ticks = 500L),
  `clutch_size`             = list(clutch_size_evolution = TRUE,
                                    max_ticks = 500L),
  `life_history`            = list(life_history = "semelparous",
                                    life_history_evolution = TRUE,
                                    max_ticks = 500L),
  `mating_systems`          = list(mate_choice_mode = "preference",
                                    mate_choice_strength = 0.7,
                                    max_ticks = 400L),
  `pace_of_life`            = list(metabolic_rate_evolution = TRUE,
                                    body_size_evolution = TRUE,
                                    max_ticks = 500L),
  `parental_investment`     = list(female_investment = 0.9,
                                    max_ticks = 400L),
  `population_genetics`     = list(body_size_evolution = TRUE,
                                    max_ticks = 500L),
  `scavenging`              = list(scavenging = TRUE),
  `signals_matechoice`      = list(signal_dims = 3L, signal_cost = 0.05,
                                    mate_choice_mode = "preference",
                                    mate_choice_strength = 0.7,
                                    max_ticks = 400L,
                                    random_seed = 21L),
  `stress_hypermutation`    = list(stress_hypermutation = TRUE,
                                    seasonal_amplitude = 0.7,
                                    max_ticks = 500L),
  `vadim_experiment`        = list(n_predators_init = 5L,
                                    brain_type = "bnn",
                                    max_ticks = 500L)
)

message(sprintf("Quick-fill: %d orphan figures to generate", length(orphans)))
t0 <- Sys.time()

for (nm in names(orphans)) {
  message(sprintf("[%s]", nm))
  s   <- .build(orphans[[nm]])
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)
  p   <- plot_run(d) + patchwork::plot_annotation(
           title = paste0("Scenario: ", nm, " (default specs + module on)"),
           subtitle = "Quick-fill figure; fidelity audit pending"
         )
  .save_pair(p, nm)
}

elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
message(sprintf("\nQuick-fill done in %.1f min.", elapsed))
