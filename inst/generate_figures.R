# generate_figures.R ─────────────────────────────────────────────────────────
#
# Run this script once (with Julia available) to produce the pre-built PNG
# figures used in vignettes/showcase.Rmd.
#
# Usage:
#   cd "<path-to-clade>"
#   Rscript vignettes/generate_figures.R
#
# Output: man/figures/showcase_XX_<name>.png
#
# Requirements: devtools::load_all() or an installed clade; Julia ≥ 1.9.
# ─────────────────────────────────────────────────────────────────────────────

library(ggplot2)
library(patchwork)

if (!requireNamespace("clade", quietly = TRUE)) {
  message("Loading clade from source…")
  devtools::load_all(quiet = TRUE)
} else {
  library(clade)
}

dir.create("inst/figures", showWarnings = FALSE, recursive = TRUE)

.save <- function(p, name, w = 8, h = 4.5, dpi = 150) {
  path <- file.path("inst/figures", paste0("showcase_", name, ".png"))
  ggplot2::ggsave(path, plot = p, width = w, height = h, dpi = dpi)
  message("  saved: ", path)
  invisible(path)
}

message("─── clade showcase figure generation ───────────────────────────────")

# ── Section 1: Core world ─────────────────────────────────────────────────────
message("[1/12] Core world…")
base <- default_specs()
base$grid_rows     <- 40L
base$grid_cols     <- 40L
base$n_agents_init <- 30L
base$max_ticks     <- 500L
base$random_seed   <- 42L
env  <- run_alife(base, verbose = FALSE)
data <- get_run_data(env)

.save(plot_environment(env),
      "01_world_grid",    w = 5, h = 5)
.save(plot_run(data),
      "01_run_dashboard", w = 9, h = 6)

# ── Section 2: Natural selection ─────────────────────────────────────────────
message("[2/12] Natural selection…")
tk <- data$ticks

p_age <- ggplot(tk, aes(x = t)) +
  geom_ribbon(aes(ymin = mean_age - sd_age, ymax = mean_age + sd_age),
              fill = "#d95f02", alpha = 0.2) +
  geom_line(aes(y = mean_age), colour = "#d95f02", linewidth = 1) +
  labs(title = "Rising mean age — a signature of natural selection",
       x = "Tick", y = "Mean agent age (ticks)") +
  theme_minimal()

p_gdiv <- ggplot(tk, aes(x = t, y = genetic_diversity)) +
  geom_line(colour = "#1b7837", linewidth = 1) +
  labs(title = "Genetic diversity over time",
       x = "Tick", y = "Mean pairwise genome distance") +
  theme_minimal()

.save(p_age | p_gdiv, "02_selection", w = 9, h = 4)

# ── Section 3: Food scarcity ──────────────────────────────────────────────────
message("[3/12] Food scarcity…")
run_grass <- function(rate) {
  s <- default_specs()
  s$grid_rows     <- 20L; s$grid_cols     <- 20L
  s$n_agents_init <- 20L; s$max_ticks     <- 300L
  s$max_agents    <- 400L; s$grass_rate   <- rate
  s$random_seed   <- 1L
  cbind(get_run_data(run_alife(s, verbose = FALSE))$ticks,
        grass_rate = rate)
}
grass_results <- rbind(run_grass(0.5), run_grass(0.1), run_grass(0.02))
grass_results$condition <- factor(
  paste0("grass_rate = ", grass_results$grass_rate),
  levels = c("grass_rate = 0.5", "grass_rate = 0.1", "grass_rate = 0.02"))
cols3 <- c("#1b7837", "#4dac26", "#d6604d")

p_g1 <- ggplot(grass_results, aes(x = t, y = n_agents, colour = condition)) +
  geom_line(linewidth = 1) + scale_colour_manual(values = cols3) +
  labs(title = "Population size", x = "Tick", y = "N agents",
       colour = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
p_g2 <- ggplot(grass_results, aes(x = t, y = mean_age, colour = condition)) +
  geom_line(linewidth = 1) + scale_colour_manual(values = cols3) +
  labs(title = "Mean agent age", x = "Tick", y = "Age (ticks)",
       colour = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
.save(p_g1 | p_g2, "03_food_scarcity", w = 9, h = 4)

# ── Section 4: Body size evolution ───────────────────────────────────────────
message("[4/12] Body size evolution…")
bs <- default_specs()
bs$grid_rows           <- 30L; bs$grid_cols    <- 30L
bs$n_agents_init       <- 30L; bs$max_ticks    <- 500L
bs$random_seed         <- 7L;  bs$grass_rate   <- 0.2
bs$body_size_evolution <- TRUE; bs$body_size_init_mean <- 1.0
env_bs   <- run_alife(bs, verbose = FALSE)
data_bs  <- get_run_data(env_bs)
tk_bs    <- data_bs$ticks

p_bs <- ggplot(tk_bs[tk_bs$n_agents > 0, ], aes(x = t)) +
  geom_ribbon(aes(ymin = mean_body_size - sd_body_size,
                  ymax = mean_body_size + sd_body_size),
              fill = "#7b3294", alpha = 0.25) +
  geom_line(aes(y = mean_body_size), colour = "#7b3294", linewidth = 1) +
  geom_hline(yintercept = 1.0, linetype = "dashed", colour = "grey60") +
  annotate("text", x = 50, y = 1.03, label = "reference (1.0)",
           colour = "grey60", size = 3) +
  coord_cartesian(ylim = c(0.3, 3.0)) +
  labs(title = "Body size evolution (mean ± 1 SD)",
       x = "Tick", y = "Mean body size") +
  theme_minimal()
.save(p_bs, "04_body_size", w = 8, h = 4)

# ── Section 5: Dispersal ──────────────────────────────────────────────────────
message("[5/12] Natal dispersal…")
disp <- default_specs()
disp$grid_rows          <- 40L; disp$grid_cols    <- 40L
disp$n_agents_init      <- 30L; disp$max_ticks    <- 300L
disp$random_seed        <- 15L; disp$grass_rate   <- 0.3
disp$dispersal_evolution <- TRUE; disp$dispersal_init_mean <- 0.3
env_disp  <- run_alife(disp, verbose = FALSE)
data_disp <- get_run_data(env_disp)
tk_d      <- data_disp$ticks

p_nd <- ggplot(tk_d, aes(x = t, y = n_dispersal_events)) +
  geom_col(fill = "#762a83", alpha = 0.5, width = 1) +
  geom_smooth(method = "loess", se = TRUE, fill = "#762a83",
              colour = "#762a83", span = 0.3, alpha = 0.3) +
  labs(title = "Dispersal events per tick",
       x = "Tick", y = "N events") +
  theme_minimal()
p_env_d <- plot_environment(env_disp)
.save(p_nd | p_env_d, "05_dispersal", w = 9, h = 4.5)

# ── Section 6: Disease ───────────────────────────────────────────────────────
message("[6/12] Disease (SIR)…")
dis <- default_specs()
dis$grid_rows          <- 30L; dis$grid_cols           <- 30L
dis$n_agents_init      <- 40L; dis$max_ticks           <- 400L
dis$random_seed        <- 3L;  dis$disease             <- TRUE
dis$disease_seed_prob  <- 0.05; dis$transmission_prob  <- 0.3
dis$disease_duration   <- 20L; dis$immune_duration     <- 100L
dis$disease_energy_cost <- 2.0
env_dis   <- run_alife(dis, verbose = FALSE)
data_dis  <- get_run_data(env_dis)
tk_dis    <- data_dis$ticks

p_sir <- ggplot(tk_dis, aes(x = t)) +
  geom_area(aes(y = n_infected, fill = "Infected"), alpha = 0.4) +
  geom_line(aes(y = n_new_infections * 5,
                colour = "New infections \u00d7 5"), linewidth = 0.7) +
  scale_fill_manual(values = c(Infected = "#d73027")) +
  scale_colour_manual(values = c("New infections \u00d7 5" = "#4575b4")) +
  labs(title = "Disease dynamics (SIR model)",
       x = "Tick", y = "Agent count", fill = NULL, colour = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
.save(p_sir, "06_disease", w = 8, h = 4)

# ── Section 7: Kin selection ─────────────────────────────────────────────────
message("[7/12] Kin selection…")
kin_on <- default_specs()
kin_on$grid_rows <- 20L; kin_on$grid_cols    <- 20L
kin_on$n_agents_init <- 20L; kin_on$max_ticks <- 300L
kin_on$random_seed <- 8L; kin_on$grass_rate   <- 0.15
kin_on$kin_selection <- TRUE; kin_on$kin_altruism_r_min <- 0.25
kin_off <- kin_on; kin_off$kin_selection <- FALSE

combined_kin <- rbind(
  cbind(get_run_data(run_alife(kin_on,  verbose = FALSE))$ticks,
        condition = "Kin selection ON"),
  cbind(get_run_data(run_alife(kin_off, verbose = FALSE))$ticks,
        condition = "Kin selection OFF")
)
p_kin <- ggplot(combined_kin, aes(x = t, y = n_agents, colour = condition)) +
  geom_line(linewidth = 1) +
  scale_colour_manual(values = c("Kin selection ON"  = "#1b7837",
                                 "Kin selection OFF" = "grey60")) +
  labs(title = "Kin selection stabilises population size",
       x = "Tick", y = "N agents", colour = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
.save(p_kin, "07_kin_selection", w = 8, h = 4)

# ── Section 8: Cooperation ───────────────────────────────────────────────────
message("[8/12] Cooperation (PGG)…")
coop <- default_specs()
coop$grid_rows             <- 25L; coop$grid_cols     <- 25L
coop$n_agents_init         <- 30L; coop$max_ticks     <- 500L
coop$random_seed           <- 11L; coop$grass_rate    <- 0.2
coop$cooperation_evolution <- TRUE; coop$cooperation_init_mean <- 0.5
env_coop  <- run_alife(coop, verbose = FALSE)
data_coop <- get_run_data(env_coop)
tk_coop   <- data_coop$ticks

p_coop_lvl <- ggplot(tk_coop, aes(x = t, y = mean_cooperation_level)) +
  geom_line(colour = "#e08214", linewidth = 1) +
  geom_hline(yintercept = 0.5, linetype = "dashed", colour = "grey60") +
  labs(title = "Mean cooperation level",
       x = "Tick", y = "Cooperation level (0\u20131)") +
  theme_minimal()
p_coop_act <- ggplot(tk_coop, aes(x = t, y = n_cooperation_acts)) +
  geom_line(colour = "#b35806", linewidth = 0.8) +
  geom_smooth(method = "loess", se = FALSE, colour = "#b35806", span = 0.3) +
  labs(title = "Cooperation acts per tick", x = "Tick", y = "N acts") +
  theme_minimal()
.save(p_coop_lvl | p_coop_act, "08_cooperation", w = 9, h = 4)

# ── Section 9: Niche construction ────────────────────────────────────────────
message("[9/12] Niche construction…")
niche <- default_specs()
niche$grid_rows          <- 30L; niche$grid_cols     <- 30L
niche$n_agents_init      <- 25L; niche$max_ticks     <- 400L
niche$random_seed        <- 20L; niche$grass_rate    <- 0.3
niche$niche_construction <- TRUE
niche$shelter_build_prob <- 0.2; niche$shelter_max_depth <- 5L
env_niche  <- run_alife(niche, verbose = FALSE)
data_niche <- get_run_data(env_niche)
tk_niche   <- data_niche$ticks

p_shel <- ggplot(tk_niche, aes(x = t, y = n_shelters_built)) +
  geom_col(fill = "#8c510a", alpha = 0.6, width = 1) +
  labs(title = "Shelter building events per tick",
       x = "Tick", y = "N shelters built") +
  theme_minimal()
.save(p_shel | plot_environment(env_niche), "09_niche", w = 9, h = 4.5)

# ── Section 10: Reinforcement learning ───────────────────────────────────────
message("[10/12] Within-lifetime RL…")
rl_on <- default_specs()
rl_on$grid_rows <- 20L; rl_on$grid_cols    <- 20L
rl_on$n_agents_init <- 15L; rl_on$max_ticks <- 400L
rl_on$random_seed <- 33L; rl_on$grass_rate  <- 0.15
rl_on$rl_mode <- "actor_critic"; rl_on$rl_update_freq <- 5L
rl_off <- rl_on; rl_off$rl_mode <- "none"

combined_rl <- rbind(
  cbind(get_run_data(run_alife(rl_on,  verbose = FALSE))$ticks,
        condition = "RL on (actor-critic)"),
  cbind(get_run_data(run_alife(rl_off, verbose = FALSE))$ticks,
        condition = "RL off (evolution only)")
)
p_rl <- ggplot(combined_rl,
               aes(x = t, y = mean_energy, colour = condition)) +
  geom_line(linewidth = 1, alpha = 0.85) +
  scale_colour_manual(
    values = c("RL on (actor-critic)" = "#2166ac",
               "RL off (evolution only)" = "grey60")) +
  labs(title = "Within-lifetime RL boosts foraging energy",
       x = "Tick", y = "Mean energy", colour = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
.save(p_rl, "10_rl", w = 8, h = 4)

# ── Section 11: Social learning ───────────────────────────────────────────────
message("[11/12] Social learning…")
soc_on <- default_specs()
soc_on$grid_rows          <- 20L; soc_on$grid_cols    <- 20L
soc_on$n_agents_init      <- 15L; soc_on$max_ticks    <- 400L
soc_on$random_seed        <- 44L; soc_on$grass_rate   <- 0.15
soc_on$social_learning    <- TRUE; soc_on$social_learning_freq <- 20L
soc_off <- soc_on; soc_off$social_learning <- FALSE

combined_soc <- rbind(
  cbind(get_run_data(run_alife(soc_on,  verbose = FALSE))$ticks,
        condition = "Social learning ON"),
  cbind(get_run_data(run_alife(soc_off, verbose = FALSE))$ticks,
        condition = "Social learning OFF")
)
soc_cols <- c("Social learning ON" = "#e66101", "Social learning OFF" = "grey60")
p_sdiv <- ggplot(combined_soc,
                 aes(x = t, y = genetic_diversity, colour = condition)) +
  geom_line(linewidth = 1) + scale_colour_manual(values = soc_cols) +
  labs(title = "Genetic diversity", x = "Tick",
       y = "Genome distance", colour = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
p_sen <- ggplot(combined_soc,
                aes(x = t, y = mean_energy, colour = condition)) +
  geom_line(linewidth = 1, alpha = 0.8) + scale_colour_manual(values = soc_cols) +
  labs(title = "Mean energy", x = "Tick",
       y = "Mean energy", colour = NULL) +
  theme_minimal() + theme(legend.position = "bottom")
.save(p_sdiv | p_sen, "11_social_learning", w = 9, h = 4)

# ── Section 12: Kitchen sink ──────────────────────────────────────────────────
message("[12/12] Kitchen-sink run…")
ks <- default_specs()
ks$grid_rows            <- 40L; ks$grid_cols          <- 40L
ks$n_agents_init        <- 50L; ks$max_ticks          <- 500L
ks$random_seed          <- 99L; ks$grass_rate         <- 0.25
ks$body_size_evolution  <- TRUE; ks$dispersal_evolution <- TRUE
ks$dispersal_init_mean  <- 0.2;  ks$kin_selection      <- TRUE
ks$social_learning      <- TRUE; ks$social_learning_freq <- 25L
env_ks  <- run_alife(ks, verbose = FALSE)
data_ks <- get_run_data(env_ks)

.save(plot_run(data_ks), "12_kitchen_sink", w = 9, h = 6)
.save(visualize_progress(env_ks, data_ks),
      "12_kitchen_dashboard", w = 10, h = 7)

message("─── Done. Figures saved to man/figures/ ─────────────────────────────")
message("Now re-build the vignette: devtools::build_vignettes()")
