# Regenerate scenario figures by running each vignette's *displayed* code
# chunk verbatim, so the figure below the chunk matches the code above it
# and the prose below it.
#
# This replaces the earlier one-size-fits-all quick-fill approach
# (dev/audit/fidelity/quickfill_figures.R) whose generic plot_run()
# dashboards did not match the custom plots vignettes actually describe.
#
# Usage:  Rscript dev/audit/fidelity/regen_vignette_figures.R
# Time:   ~15-25 min (most runs are 300-500 ticks, a few are 1000).
#
# One Julia session, serial runs. Respects the 200-core/300 GB cap
# (we do not fork).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
  library(ggplot2)
  library(patchwork)
  library(tidyr)
})

.save_pair <- function(p, name, w = 8, h = 4.5, dpi = 150) {
  for (d in c("inst/figures", "vignettes/figures")) {
    ggsave(file.path(d, paste0("showcase_", name, ".png")),
           plot = p, width = w, height = h, dpi = dpi)
  }
  message(sprintf("  saved: showcase_%s.png", name))
}

# ── 14_predators ─ s-predator-prey.Rmd ───────────────────────────────────────
{
  message("[14_predators]")
  s <- default_specs()
  s$n_predators_init <- 5L
  s$n_agents_init    <- 100L
  s$grid_rows        <- 30L
  s$grid_cols        <- 30L
  s$grass_rate       <- 0.3
  s$max_ticks        <- 500L
  env  <- run_alife(s, verbose = FALSE)
  d    <- get_run_data(env)$ticks
  p <- ggplot(d, aes(x = t)) +
    geom_line(aes(y = n_agents,    colour = "Prey"),     linewidth = 0.8) +
    geom_line(aes(y = n_predators, colour = "Predators"), linewidth = 0.8) +
    scale_colour_manual(values = c(Prey = "#2196F3", Predators = "#F44336"),
                        name = NULL) +
    labs(x = "Tick", y = "Population size",
         title = "Predator-prey dynamics (5 predators, 100 prey, 500 ticks)") +
    theme_minimal(base_size = 12)
  .save_pair(p, "14_predators")
}

# ── 15_group_defense ─ s-group-defense.Rmd (two conditions) ──────────────────
{
  message("[15_group_defense]")
  base_specs <- function() {
    s <- default_specs()
    s$n_predators_init <- 5L
    s$n_agents_init    <- 100L
    s$grid_rows        <- 30L
    s$grid_cols        <- 30L
    s$max_ticks        <- 400L
    s
  }
  s_no <- base_specs(); s_no$group_defense <- FALSE
  s_gd <- base_specs()
  s_gd$group_defense          <- TRUE
  s_gd$group_defense_radius   <- 2L
  s_gd$group_defense_strength <- 0.3
  d_no <- get_run_data(run_alife(s_no, verbose = FALSE))$ticks
  d_gd <- get_run_data(run_alife(s_gd, verbose = FALSE))$ticks
  df <- rbind(cbind(d_no[, c("t", "n_agents")], condition = "No group defense"),
              cbind(d_gd[, c("t", "n_agents")], condition = "Group defense"))
  p <- ggplot(df, aes(t, n_agents, colour = condition)) +
    geom_line(linewidth = 0.8) +
    scale_colour_manual(values = c("No group defense" = "#E53935",
                                   "Group defense"    = "#1E88E5"),
                        name = NULL) +
    labs(x = "Tick", y = "Population size",
         title = "Group defense under predation (5 predators)") +
    theme_minimal(base_size = 12)
  .save_pair(p, "15_group_defense")
}

# ── 16_habitat_preference ─ s-complex-landscape.Rmd ──────────────────────────
{
  message("[16_habitat_preference]")
  s <- default_specs()
  s$complex_landscape   <- TRUE
  s$shrub_density       <- 0.35
  s$canopy_density      <- 0.15
  s$canopy_energy       <- 55.0
  s$canopy_threshold    <- 0.15
  s$wing_size_init_mean <- 0.08
  s$max_ticks           <- 400L
  env  <- run_alife(s, verbose = FALSE)
  d    <- get_run_data(env)$ticks
  p <- ggplot(d, aes(t, mean_wing_size)) +
    geom_line(colour = "#2c7fb8", linewidth = 0.8) +
    labs(x = "Tick", y = "Mean wing size",
         title = "Wing size evolution in the forest world",
         subtitle = "canopy_threshold = 0.15; canopy_energy = 55") +
    theme_minimal(base_size = 12)
  .save_pair(p, "16_habitat_preference")
}

# ── 17_seasons ─ s-seasonal.Rmd ──────────────────────────────────────────────
{
  message("[17_seasons]")
  s <- default_specs()
  s$seasonal_amplitude <- 0.8
  s$season_length      <- 100L
  s$winter_death_prob  <- 0.05
  s$n_agents_init      <- 100L
  s$grid_rows          <- 30L
  s$grid_cols          <- 30L
  s$max_ticks          <- 500L
  env <- run_alife(s, verbose = FALSE)
  tks <- get_run_data(env)$ticks
  tks$grass_scaled <- tks$grass_coverage /
    max(tks$grass_coverage, na.rm = TRUE) * max(tks$n_agents, na.rm = TRUE)
  long <- pivot_longer(tks[, c("t", "n_agents", "grass_scaled")],
                       cols = c("n_agents", "grass_scaled"),
                       names_to = "variable", values_to = "value")
  p <- ggplot(long, aes(t, value, colour = variable)) +
    geom_line(linewidth = 0.7) +
    scale_colour_manual(values = c(n_agents = "#2c7fb8",
                                    grass_scaled = "#31a354"),
                        labels = c("Agents", "Grass (scaled)"),
                        name = NULL) +
    labs(x = "Tick", y = "Count / scaled grass",
         title = "Seasonal dynamics: population tracks grass cycle",
         subtitle = "season_length = 100, seasonal_amplitude = 0.8") +
    theme_minimal(base_size = 12)
  .save_pair(p, "17_seasons")
}

# ── 18_speciation ─ s-speciation.Rmd ─────────────────────────────────────────
{
  message("[18_speciation]")
  s <- default_specs()
  s$speciation                  <- TRUE
  s$isolation_threshold         <- 0.15
  s$mutation_sd                 <- 0.15
  s$speciation_cluster_interval <- 10L
  s$max_ticks                   <- 1000L
  s$random_seed                 <- 55L
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  p <- ggplot(d, aes(t, n_species)) +
    geom_step(colour = "#ff7f00", linewidth = 0.9) +
    scale_y_continuous(breaks = seq_len(max(8L, max(d$n_species, na.rm = TRUE)))) +
    labs(x = "Tick", y = "Number of species (clusters)",
         title = "Speciation: distinct genetic clusters over time",
         subtitle = "isolation_threshold = 0.15, mutation_sd = 0.15") +
    theme_minimal(base_size = 12)
  .save_pair(p, "18_speciation")
}

# ── 19_parental_care ─ s-parental-care.Rmd (chunk has no plot; synthesise) ───
{
  message("[19_parental_care]")
  s <- default_specs()
  s$parental_care      <- TRUE
  s$care_duration      <- 5L
  s$care_cost_per_tick <- 2.0
  s$max_ticks          <- 300L
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  long <- pivot_longer(d[, c("t", "n_agents", "n_juveniles")],
                       cols = c("n_agents", "n_juveniles"),
                       names_to = "variable", values_to = "value")
  p <- ggplot(long, aes(t, value, colour = variable)) +
    geom_line(linewidth = 0.8) +
    scale_colour_manual(values = c(n_agents = "#4575b4",
                                    n_juveniles = "#d73027"),
                        labels = c("Total agents", "Juveniles"),
                        name = NULL) +
    labs(x = "Tick", y = "Count",
         title = "Parental care: juveniles buffered by adult provisioning",
         subtitle = "care_duration = 5, care_cost_per_tick = 2") +
    theme_minimal(base_size = 12)
  .save_pair(p, "19_parental_care")
}

# ── 20_cooperative_breeding ─ s-kin.Rmd (iffolk chunk) ───────────────────────
{
  message("[20_cooperative_breeding]")
  s <- default_specs()
  s$iffolk_selection          <- TRUE
  s$iffolk_r_min              <- 0.125
  s$iffolk_transfer           <- 3.0
  s$parliament_suppression    <- TRUE
  s$parliament_cost           <- 0.5
  s$cooperative_breeding      <- TRUE
  s$helper_tendency_init_mean <- 0.2
  s$max_ticks                 <- 400L
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  p <- ggplot(d, aes(t, mean_helper_tendency)) +
    geom_line(colour = "#6a3d9a", linewidth = 0.8) +
    labs(x = "Tick", y = "Mean helper tendency",
         title = "Helper tendency under IFfolk + parliament suppression") +
    theme_minimal(base_size = 12)
  .save_pair(p, "20_cooperative_breeding")
}

# ── 21_mimicry ─ s-mimicry.Rmd (chunk has no plot; synthesise) ───────────────
{
  message("[21_mimicry]")
  s <- default_specs()
  s$mimicry            <- TRUE
  s$n_predators_init   <- 5L
  s$toxicity_init_mean <- 0.1
  s$max_ticks          <- 300L
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  p <- ggplot(d, aes(t, mean_toxicity)) +
    geom_line(colour = "#e41a1c", linewidth = 0.8) +
    labs(x = "Tick", y = "Mean toxicity",
         title = "Toxicity evolution under predator pressure",
         subtitle = "5 predators, mimicry = TRUE") +
    theme_minimal(base_size = 12)
  .save_pair(p, "21_mimicry")
}

# ── 22_plasticity ─ s-plasticity.Rmd (chunk has no plot; synthesise) ─────────
{
  message("[22_plasticity]")
  s <- default_specs()
  s$phenotypic_plasticity <- TRUE
  s$max_ticks             <- 300L
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  p <- ggplot(d, aes(t, mean_plasticity)) +
    geom_line(colour = "#2c7fb8", linewidth = 0.8) +
    labs(x = "Tick", y = "Mean plasticity",
         title = "Phenotypic plasticity trajectory") +
    theme_minimal(base_size = 12)
  .save_pair(p, "22_plasticity")
}

# ── bnn_uncertainty ─ s-baldwin.Rmd (first chunk) ────────────────────────────
{
  message("[bnn_uncertainty]")
  s <- default_specs()
  s$brain_type  <- "bnn"
  s$max_ticks   <- 600L
  s$random_seed <- 42L
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  p <- ggplot(d, aes(t, mean_prior_sigma)) +
    geom_line(colour = "#2166ac", linewidth = 0.8, alpha = 0.7) +
    geom_smooth(method = "lm", se = TRUE, colour = "#d6604d",
                fill = "#f4a582", alpha = 0.4, formula = y ~ x) +
    labs(title    = "Genetic assimilation of learned behaviour (Baldwin Effect)",
         subtitle = "BNN prior sigma — declining = canalization, rising = flexibility",
         x = "Tick", y = expression("Mean prior " * sigma)) +
    theme_minimal(base_size = 12)
  .save_pair(p, "bnn_uncertainty")
}

# ── clutch_size ─ s-clutch-size.Rmd (rich vs scarce) ─────────────────────────
{
  message("[clutch_size]")
  make_s <- function(gr) {
    s <- default_specs()
    s$clutch_size_evolution   <- TRUE
    s$clutch_size_min         <- 1L
    s$clutch_size_max         <- 5L
    s$clutch_size_mutation_sd <- 0.3
    s$grass_rate              <- gr
    s$max_ticks               <- 400L
    s$random_seed             <- 3L
    s
  }
  d_rich <- get_run_data(run_alife(make_s(0.4),  verbose = FALSE))$ticks
  d_scar <- get_run_data(run_alife(make_s(0.05), verbose = FALSE))$ticks
  df <- rbind(cbind(d_rich[, c("t", "n_births")], environment = "Rich (0.4)"),
              cbind(d_scar[, c("t", "n_births")], environment = "Scarce (0.05)"))
  p <- ggplot(df, aes(t, n_births, colour = environment)) +
    geom_line(linewidth = 0.8, alpha = 0.85) +
    scale_colour_manual(values = c("Rich (0.4)" = "#31a354",
                                    "Scarce (0.05)" = "#de2d26"),
                        name = NULL) +
    labs(x = "Tick", y = "Births per tick",
         title = "Clutch size evolution: rich vs scarce environments") +
    theme_minimal(base_size = 12)
  .save_pair(p, "clutch_size")
}

# ── life_history ─ s-life-history.Rmd (semel vs itero) ───────────────────────
{
  message("[life_history]")
  s_sem <- default_specs()
  s_sem$life_history <- "semelparous"; s_sem$max_ticks <- 400L; s_sem$random_seed <- 7L
  s_ite <- default_specs()
  s_ite$life_history <- "iteroparous"; s_ite$max_ticks <- 400L; s_ite$random_seed <- 7L
  d_sem <- get_run_data(run_alife(s_sem, verbose = FALSE))$ticks
  d_ite <- get_run_data(run_alife(s_ite, verbose = FALSE))$ticks
  df <- rbind(cbind(d_sem[, c("t", "mean_age")], strategy = "Semelparous"),
              cbind(d_ite[, c("t", "mean_age")], strategy = "Iteroparous"))
  p <- ggplot(df, aes(t, mean_age, colour = strategy)) +
    geom_line(linewidth = 0.8) +
    scale_colour_manual(values = c(Semelparous = "#e41a1c",
                                    Iteroparous = "#4daf4a"),
                        name = NULL) +
    labs(x = "Tick", y = "Mean age (ticks)",
         title = "Life history: semelparous vs iteroparous") +
    theme_minimal(base_size = 12)
  .save_pair(p, "life_history")
}

# ── mating_systems ─ s-mating-systems.Rmd (asex vs sex) ──────────────────────
{
  message("[mating_systems]")
  s_asex <- default_specs()
  s_asex$ploidy <- 1L; s_asex$crossover_rate <- 0.0
  s_asex$max_ticks <- 400L; s_asex$random_seed <- 42L
  s_sex <- default_specs()
  s_sex$ploidy <- 2L; s_sex$crossover_rate <- 0.1
  s_sex$max_ticks <- 400L; s_sex$random_seed <- 42L
  d_asex <- get_run_data(run_alife(s_asex, verbose = FALSE))$ticks
  d_sex  <- get_run_data(run_alife(s_sex,  verbose = FALSE))$ticks
  df <- rbind(cbind(d_asex[, c("t", "genetic_diversity")], system = "Asexual (haploid)"),
              cbind(d_sex[,  c("t", "genetic_diversity")], system = "Sexual (diploid)"))
  p <- ggplot(df, aes(t, genetic_diversity, colour = system)) +
    geom_line(linewidth = 0.8) +
    scale_colour_manual(values = c("Asexual (haploid)" = "#de2d26",
                                    "Sexual (diploid)"  = "#3182bd"),
                        name = NULL) +
    labs(x = "Tick", y = "Genetic diversity",
         title = "Mating systems: asexual vs sexual") +
    theme_minimal(base_size = 12)
  .save_pair(p, "mating_systems")
}

# ── pace_of_life ─ s-pace-of-life.Rmd (3 metabolic rates) ────────────────────
{
  message("[pace_of_life]")
  make_run <- function(rate) {
    s <- default_specs()
    s$metabolic_rate_init_mean <- rate
    s$metabolic_rate_evolution <- FALSE
    s$max_ticks                <- 400L
    s$random_seed              <- 99L
    get_run_data(run_alife(s, verbose = FALSE))$ticks
  }
  d_slow <- make_run(0.5); d_base <- make_run(1.0); d_fast <- make_run(2.0)
  df <- rbind(cbind(d_slow[, c("t", "mean_age")], pace = "Slow (0.5)"),
              cbind(d_base[, c("t", "mean_age")], pace = "Baseline (1.0)"),
              cbind(d_fast[, c("t", "mean_age")], pace = "Fast (2.0)"))
  p <- ggplot(df, aes(t, mean_age, colour = pace)) +
    geom_line(linewidth = 0.8) +
    scale_colour_manual(values = c("Slow (0.5)" = "#1a9850",
                                    "Baseline (1.0)" = "#878787",
                                    "Fast (2.0)" = "#d73027"),
                        name = NULL) +
    labs(x = "Tick", y = "Mean age",
         title = "Pace of life: fast vs slow metabolic rates") +
    theme_minimal(base_size = 12)
  .save_pair(p, "pace_of_life")
}

# ── parental_investment ─ s-parental-investment.Rmd (hi vs eq) ───────────────
{
  message("[parental_investment]")
  make_s <- function(fi) {
    s <- default_specs()
    s$parental_care                 <- TRUE
    s$parental_investment_evolution <- TRUE
    s$female_investment             <- fi
    s$male_repro_cost               <- 0.3
    s$max_ticks                     <- 400L
    s$random_seed                   <- 11L
    s
  }
  d_hi <- get_run_data(run_alife(make_s(0.9), verbose = FALSE))$ticks
  d_eq <- get_run_data(run_alife(make_s(0.5), verbose = FALSE))$ticks
  df <- rbind(cbind(d_hi[, c("t", "n_births")], condition = "High maternal (0.9)"),
              cbind(d_eq[, c("t", "n_births")], condition = "Equal (0.5)"))
  p <- ggplot(df, aes(t, n_births, colour = condition)) +
    geom_line(alpha = 0.7) +
    geom_smooth(method = "loess", se = FALSE, linewidth = 1.2, formula = y ~ x) +
    scale_colour_manual(values = c("High maternal (0.9)" = "#e41a1c",
                                    "Equal (0.5)"         = "#377eb8"),
                        name = NULL) +
    labs(x = "Tick", y = "Births per tick",
         title = "Parental investment: maternal allocation vs equal") +
    theme_minimal(base_size = 12)
  .save_pair(p, "parental_investment")
}

# ── population_genetics ─ s-pop-genetics.Rmd (body size trajectory) ──────────
{
  message("[population_genetics]")
  s <- default_specs()
  s$body_size_evolution <- TRUE
  s$max_ticks           <- 500L
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  p <- ggplot(d, aes(t, mean_body_size)) +
    geom_line(colour = "#6a3d9a", linewidth = 0.8) +
    labs(x = "Tick", y = "Mean body size",
         title = "Body size evolution (population mean)") +
    theme_minimal(base_size = 12)
  .save_pair(p, "population_genetics")
}

# ── scavenging ─ s-scavenging.Rmd (ON vs OFF) ────────────────────────────────
{
  message("[scavenging]")
  base_specs <- function() {
    s <- default_specs()
    s$n_agents_init <- 100L
    s$grid_rows     <- 30L
    s$grid_cols     <- 30L
    s$grass_rate    <- 0.15
    s$max_ticks     <- 400L
    s
  }
  s_no <- base_specs(); s_no$scavenging <- FALSE
  s_sc <- base_specs()
  s_sc$scavenging         <- TRUE
  s_sc$carrion_fraction   <- 0.5
  s_sc$carrion_decay_rate <- 0.1
  s_sc$carrion_eat_gain   <- 3.0
  d_no <- get_run_data(run_alife(s_no, verbose = FALSE))$ticks; d_no$condition <- "No scavenging"
  d_sc <- get_run_data(run_alife(s_sc, verbose = FALSE))$ticks; d_sc$condition <- "Scavenging"
  dat <- rbind(d_no, d_sc)
  p <- ggplot(dat, aes(t, mean_energy, colour = condition)) +
    geom_line(linewidth = 0.8) +
    scale_colour_manual(values = c("No scavenging" = "#E53935",
                                    "Scavenging"    = "#FB8C00"),
                        name = NULL) +
    labs(x = "Tick", y = "Mean agent energy",
         title = "Scavenging sustains energy under scarcity") +
    theme_classic(base_size = 12)
  .save_pair(p, "scavenging")
}

# ── signals_matechoice ─ s-signals.Rmd (two-panel) ───────────────────────────
{
  message("[signals_matechoice]")
  s <- default_specs()
  s$signal_dims          <- 3L
  s$signal_cost          <- 0.05
  s$mate_choice_mode     <- "preference"
  s$mate_choice_strength <- 0.7
  s$max_ticks            <- 400L
  s$random_seed          <- 21L
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  p1 <- ggplot(d, aes(t, mean_signal_magnitude)) +
    geom_line(colour = "#984ea3", linewidth = 0.8) +
    labs(title = "Signal elaboration under sexual selection",
         x = "Tick", y = "Mean signal magnitude") +
    theme_minimal(base_size = 11)
  p2 <- ggplot(d, aes(mean_energy, mean_signal_magnitude)) +
    geom_point(alpha = 0.4, size = 0.8, colour = "#984ea3") +
    geom_smooth(method = "lm", se = FALSE, colour = "#333333",
                linewidth = 0.7, formula = y ~ x) +
    labs(title = "Signal magnitude vs mean energy (honest signalling check)",
         x = "Mean energy", y = "Mean signal magnitude") +
    theme_minimal(base_size = 11)
  .save_pair(p1 / p2, "signals_matechoice", w = 8, h = 7)
}

# ── stress_hypermutation ─ s-stress-hypermutation.Rmd (baseline vs on) ───────
{
  message("[stress_hypermutation]")
  make_s <- function(hypermut) {
    s <- default_specs()
    s$stress_hypermutation       <- hypermut
    s$stress_threshold           <- 20.0
    s$stress_mutation_multiplier <- 5.0
    s$grass_rate                 <- 0.05
    s$max_ticks                  <- 500L
    s
  }
  d_base <- get_run_data(run_alife(make_s(FALSE), verbose = FALSE))$ticks
  d_hyp  <- get_run_data(run_alife(make_s(TRUE),  verbose = FALSE))$ticks
  df <- rbind(
    data.frame(t = d_base$t, genetic_diversity = d_base$genetic_diversity,
               condition = "baseline"),
    data.frame(t = d_hyp$t,  genetic_diversity = d_hyp$genetic_diversity,
               condition = "hypermutation"))
  p <- ggplot(df, aes(t, genetic_diversity, colour = condition)) +
    geom_line(linewidth = 0.7, alpha = 0.85) +
    scale_colour_manual(values = c(baseline = "#878787",
                                    hypermutation = "#d6604d"),
                        name = "Condition") +
    labs(x = "Tick", y = "Genetic diversity",
         title = "Stress hypermutation and diversity under scarcity",
         subtitle = "grass_rate = 0.05; stress_mutation_multiplier = 5") +
    theme_minimal(base_size = 12)
  .save_pair(p, "stress_hypermutation")
}

# ── vadim_experiment ─ s-predation-neural.Rmd (0 vs 10 predators) ────────────
{
  message("[vadim_experiment]")
  make_s <- function(n_pred) {
    s <- default_specs()
    s$n_agents_init    <- 80L
    s$n_predators_init <- n_pred
    s$max_ticks        <- 500L
    s
  }
  d0  <- get_run_data(run_alife(make_s(0L),  verbose = FALSE))$ticks
  d10 <- get_run_data(run_alife(make_s(10L), verbose = FALSE))$ticks
  df <- rbind(
    data.frame(t = d0$t,  genetic_diversity = d0$genetic_diversity,
               mean_energy = d0$mean_energy,  condition = "no_predators"),
    data.frame(t = d10$t, genetic_diversity = d10$genetic_diversity,
               mean_energy = d10$mean_energy, condition = "predators"))
  cols <- c(no_predators = "#4dac26", predators = "#d01c8b")
  p1 <- ggplot(df, aes(t, genetic_diversity, colour = condition)) +
    geom_line(linewidth = 0.7) +
    scale_colour_manual(values = cols, name = NULL) +
    labs(title = "Predation and neural genome diversity",
         x = "Tick", y = "Genetic diversity") +
    theme_minimal(base_size = 11)
  p2 <- ggplot(df, aes(t, mean_energy, colour = condition)) +
    geom_line(linewidth = 0.7) +
    scale_colour_manual(values = cols, name = NULL) +
    labs(x = "Tick", y = "Mean energy") +
    theme_minimal(base_size = 11)
  .save_pair(p1 / p2, "vadim_experiment", w = 8, h = 7)
}

message("\nAll per-scenario figures regenerated.")
