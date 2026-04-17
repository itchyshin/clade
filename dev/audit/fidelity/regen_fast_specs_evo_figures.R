# Regenerate the 10 evolutionary scenario figures still produced at
# default_specs() — upgrade them to fast_specs() so the plots show
# meaningful evolution (~66 generations) instead of ~2.6 generations.
#
# Scenarios covered (all produce figures that live under
# inst/figures/ and vignettes/figures/):
#
#   02_selection                 — rising mean age + genetic diversity
#   07_kin_selection             — kin ON vs OFF population stability
#   08_cooperation               — cooperation level + acts per tick
#   12_kitchen_sink / dashboard  — everything-on multi-module run
#   18_speciation                — species cluster count over time
#   20_cooperative_breeding      — helper tendency trajectory
#   clutch_size                  — rich vs scarce clutch evolution
#   life_history                 — semelparous vs iteroparous mean age
#   population_genetics          — body size trajectory
#   vadim_experiment             — neural diversity under predation
#
# Scenarios purposely left at default_specs (not covered here):
#
#   01, 03, 06, 09, 10, 11       — intro / ecological / within-gen
#   14, 15, 17, 19               — ecological dynamics
#   pace_of_life, scavenging     — fixed-trait comparisons / ecological
#   cephalopod_paradox           — intentionally varies max_age
#   bad_science, map_elites      — non-biological demos
#
# Figures that already use fast_specs (regenerated earlier on 2026-04-17)
# and do NOT need redoing: 04_body_size, 05_dispersal, 16_habitat_preference,
# 21_mimicry, 22_plasticity, bnn_uncertainty, brain_size, mating_systems,
# parental_investment, signals_matechoice, stress_hypermutation.
#
# Usage:  Rscript dev/audit/fidelity/regen_fast_specs_evo_figures.R
# Time:   ~20-30 min wall clock. One Julia session, serial runs.

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

t0 <- Sys.time()

# ── 02_selection ─ Core world: rising mean age + genetic diversity ───────────
# Uses fast_specs so selection signature is visible over ~66 generations
# instead of the ~2.6 generations a default_specs 500-tick run produces.
{
  message("[02_selection]")
  s <- fast_specs()
  s$random_seed <- 42L
  env  <- run_alife(s, verbose = FALSE)
  tk   <- get_run_data(env)$ticks

  p_age <- ggplot(tk, aes(x = t)) +
    geom_ribbon(aes(ymin = mean_age - sd_age, ymax = mean_age + sd_age),
                fill = "#d95f02", alpha = 0.2) +
    geom_line(aes(y = mean_age), colour = "#d95f02", linewidth = 1) +
    labs(title = "Rising mean age — a signature of natural selection",
         subtitle = "fast_specs(): ~66 generations in 2000 ticks",
         x = "Tick", y = "Mean agent age (ticks)") +
    theme_minimal()

  p_gdiv <- ggplot(tk, aes(x = t, y = genetic_diversity)) +
    geom_line(colour = "#1b7837", linewidth = 1) +
    labs(title = "Genetic diversity over time",
         x = "Tick", y = "Mean pairwise genome distance") +
    theme_minimal()

  .save_pair(p_age | p_gdiv, "02_selection", w = 9, h = 4)
}

# ── 07_kin_selection ─ kin ON vs OFF population stability ────────────────────
{
  message("[07_kin_selection]")
  kin_on  <- fast_specs()
  kin_on$kin_selection       <- TRUE
  kin_on$kin_altruism_r_min  <- 0.25
  kin_on$random_seed         <- 8L
  kin_off <- kin_on
  kin_off$kin_selection      <- FALSE

  d_on  <- get_run_data(run_alife(kin_on,  verbose = FALSE))$ticks
  d_off <- get_run_data(run_alife(kin_off, verbose = FALSE))$ticks
  df <- rbind(cbind(d_on [, c("t", "n_agents")], condition = "Kin selection ON"),
              cbind(d_off[, c("t", "n_agents")], condition = "Kin selection OFF"))
  p <- ggplot(df, aes(t, n_agents, colour = condition)) +
    geom_line(linewidth = 1) +
    scale_colour_manual(values = c("Kin selection ON"  = "#1b7837",
                                   "Kin selection OFF" = "grey60"),
                        name = NULL) +
    labs(title = "Kin selection stabilises population size",
         subtitle = "fast_specs(): ~66 generations in 2000 ticks",
         x = "Tick", y = "N agents") +
    theme_minimal() + theme(legend.position = "bottom")
  .save_pair(p, "07_kin_selection", w = 8, h = 4)
}

# ── 08_cooperation ─ cooperation level + acts ────────────────────────────────
{
  message("[08_cooperation]")
  s <- fast_specs()
  s$cooperation_evolution    <- TRUE
  s$cooperation_init_mean    <- 0.5
  s$random_seed              <- 11L
  env <- run_alife(s, verbose = FALSE)
  tk  <- get_run_data(env)$ticks

  p_lvl <- ggplot(tk, aes(t, mean_cooperation_level)) +
    geom_line(colour = "#e08214", linewidth = 1) +
    geom_hline(yintercept = 0.5, linetype = "dashed", colour = "grey60") +
    labs(title = "Mean cooperation level",
         subtitle = "fast_specs(): ~66 generations in 2000 ticks",
         x = "Tick", y = "Cooperation level (0-1)") +
    theme_minimal()
  p_act <- ggplot(tk, aes(t, n_cooperation_acts)) +
    geom_line(colour = "#b35806", linewidth = 0.8) +
    geom_smooth(method = "loess", se = FALSE, colour = "#b35806",
                span = 0.3, formula = y ~ x) +
    labs(title = "Cooperation acts per tick",
         x = "Tick", y = "N acts") +
    theme_minimal()
  .save_pair(p_lvl | p_act, "08_cooperation", w = 9, h = 4)
}

# ── 12_kitchen_sink + 12_kitchen_dashboard ─ everything-on multi-module ──────
# Note: kitchen_sink is a "modules coexisting" demo, not an evolution demo.
# Running at fast_specs() triggers malthusian overshoot-and-collapse when
# every module mutates simultaneously, which hides the intended "look at
# all these panels working" view. Stays at default_specs().
{
  message("[12_kitchen]")
  ks <- default_specs()
  ks$grid_rows            <- 40L; ks$grid_cols          <- 40L
  ks$n_agents_init        <- 50L; ks$max_ticks          <- 500L
  ks$random_seed          <- 99L; ks$grass_rate         <- 0.25
  ks$body_size_evolution  <- TRUE; ks$dispersal_evolution <- TRUE
  ks$dispersal_init_mean  <- 0.2;  ks$kin_selection      <- TRUE
  ks$social_learning      <- TRUE; ks$social_learning_freq <- 25L
  env  <- run_alife(ks, verbose = FALSE)
  data <- get_run_data(env)

  .save_pair(plot_run(data),                "12_kitchen_sink",      w = 9, h = 6)
  .save_pair(visualize_progress(env, data), "12_kitchen_dashboard", w = 10, h = 7)
}

# ── 18_speciation ─ species cluster count over time ──────────────────────────
{
  message("[18_speciation]")
  s <- fast_specs()
  s$speciation                  <- TRUE
  s$isolation_threshold         <- 0.15
  s$mutation_sd                 <- 0.15
  s$speciation_cluster_interval <- 10L
  s$random_seed                 <- 55L
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks

  p <- ggplot(d, aes(t, n_species)) +
    geom_step(colour = "#ff7f00", linewidth = 0.9) +
    scale_y_continuous(breaks = scales::pretty_breaks(n = 6)) +
    labs(title = "Speciation: distinct genetic clusters over time",
         subtitle = paste0("fast_specs() ~66 generations; ",
                           "isolation_threshold = 0.15, mutation_sd = 0.15"),
         x = "Tick", y = "Number of species (clusters)") +
    theme_minimal(base_size = 12)
  .save_pair(p, "18_speciation")
}

# ── 20_cooperative_breeding ─ helper tendency trajectory ─────────────────────
{
  message("[20_cooperative_breeding]")
  s <- fast_specs()
  s$iffolk_selection          <- TRUE
  s$iffolk_r_min              <- 0.125
  s$iffolk_transfer           <- 3.0
  s$parliament_suppression    <- TRUE
  s$parliament_cost           <- 0.5
  s$cooperative_breeding      <- TRUE
  s$helper_tendency_init_mean <- 0.2
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  p <- ggplot(d, aes(t, mean_helper_tendency)) +
    geom_line(colour = "#6a3d9a", linewidth = 0.8) +
    labs(title = "Helper tendency under IFfolk + parliament suppression",
         subtitle = "fast_specs() ~66 generations",
         x = "Tick", y = "Mean helper tendency") +
    theme_minimal(base_size = 12)
  .save_pair(p, "20_cooperative_breeding")
}

# ── clutch_size ─ rich vs scarce environments (override grass_rate) ──────────
{
  message("[clutch_size]")
  make_s <- function(gr) {
    s <- fast_specs()
    s$clutch_size_evolution   <- TRUE
    s$clutch_size_min         <- 1L
    s$clutch_size_max         <- 5L
    s$clutch_size_mutation_sd <- 0.3
    s$grass_rate              <- gr         # override fast_specs default 0.20
    s$random_seed             <- 3L
    s
  }
  d_rich <- get_run_data(run_alife(make_s(0.4),  verbose = FALSE))$ticks
  d_scar <- get_run_data(run_alife(make_s(0.05), verbose = FALSE))$ticks
  df <- rbind(cbind(d_rich[, c("t", "n_births")], environment = "Rich (0.4)"),
              cbind(d_scar[, c("t", "n_births")], environment = "Scarce (0.05)"))
  p <- ggplot(df, aes(t, n_births, colour = environment)) +
    geom_line(linewidth = 0.8, alpha = 0.85) +
    scale_colour_manual(values = c("Rich (0.4)"    = "#31a354",
                                   "Scarce (0.05)" = "#de2d26"),
                        name = NULL) +
    labs(title = "Clutch size evolution: rich vs scarce environments",
         subtitle = "fast_specs() ~66 generations",
         x = "Tick", y = "Births per tick") +
    theme_minimal(base_size = 12)
  .save_pair(p, "clutch_size")
}

# ── life_history ─ semelparous vs iteroparous (mean age trajectory) ──────────
{
  message("[life_history]")
  s_sem <- fast_specs(); s_sem$life_history <- "semelparous"; s_sem$random_seed <- 7L
  s_ite <- fast_specs(); s_ite$life_history <- "iteroparous"; s_ite$random_seed <- 7L
  d_sem <- get_run_data(run_alife(s_sem, verbose = FALSE))$ticks
  d_ite <- get_run_data(run_alife(s_ite, verbose = FALSE))$ticks
  df <- rbind(cbind(d_sem[, c("t", "mean_age")], strategy = "Semelparous"),
              cbind(d_ite[, c("t", "mean_age")], strategy = "Iteroparous"))
  p <- ggplot(df, aes(t, mean_age, colour = strategy)) +
    geom_line(linewidth = 0.8) +
    scale_colour_manual(values = c(Semelparous = "#e41a1c",
                                   Iteroparous = "#4daf4a"),
                        name = NULL) +
    labs(title = "Life history: semelparous vs iteroparous",
         subtitle = "fast_specs() ~66 generations",
         x = "Tick", y = "Mean age (ticks)") +
    theme_minimal(base_size = 12)
  .save_pair(p, "life_history")
}

# ── population_genetics ─ body size trajectory ───────────────────────────────
{
  message("[population_genetics]")
  s <- fast_specs()
  s$body_size_evolution <- TRUE
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  p <- ggplot(d, aes(t, mean_body_size)) +
    geom_line(colour = "#6a3d9a", linewidth = 0.8) +
    labs(title = "Body size evolution (population mean)",
         subtitle = "fast_specs() ~66 generations",
         x = "Tick", y = "Mean body size") +
    theme_minimal(base_size = 12)
  .save_pair(p, "population_genetics")
}

# ── vadim_experiment ─ neural diversity under predation (0 vs 10 preds) ──────
{
  message("[vadim_experiment]")
  make_s <- function(n_pred) {
    s <- fast_specs()
    s$n_predators_init <- n_pred
    s$random_seed      <- 42L
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
         subtitle = "fast_specs() ~66 generations",
         x = "Tick", y = "Genetic diversity") +
    theme_minimal(base_size = 11)
  p2 <- ggplot(df, aes(t, mean_energy, colour = condition)) +
    geom_line(linewidth = 0.7) +
    scale_colour_manual(values = cols, name = NULL) +
    labs(x = "Tick", y = "Mean energy") +
    theme_minimal(base_size = 11)
  .save_pair(p1 / p2, "vadim_experiment", w = 8, h = 7)
}

elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
message(sprintf("\nRegenerated evolutionary figures at fast_specs() in %.1f min.",
                elapsed))
