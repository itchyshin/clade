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
# Parameters match the displayed code in vignettes/s-baseline.Rmd and the
# "What we found" prose so a reader running the chunk sees the same dynamics
# this figure records.
message("[1/12] Core world…")
base <- default_specs()
base$grid_rows     <- 30L
base$grid_cols     <- 30L
base$n_agents_init <- 100L
base$max_ticks     <- 500L
base$grass_rate    <- 0.15
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

# ── Section 35: Cephalopod learning paradox ──────────────────────────────────
message("[35] Cephalopod learning paradox…")
ages   <- c(20L, 40L, 80L, 160L, 300L)
n_reps <- 3L

results_ceph <- lapply(ages, function(ma) {
  reps <- lapply(seq_len(n_reps), function(rep) {
    s <- default_specs()
    s$grid_rows               <- 20L
    s$grid_cols               <- 20L
    s$n_agents_init           <- 60L
    s$max_agents              <- 300L
    s$max_ticks               <- 400L
    s$max_age                 <- ma
    s$complex_landscape       <- TRUE
    s$shrub_density           <- 0.4
    s$shrub_energy            <- 30.0
    s$shrub_growth_rate       <- 0.05
    s$learning_rate_evolution <- TRUE
    s$learning_rate_init_mean <- 0.05
    s$learning_rate_min       <- 0.001
    s$learning_rate_max       <- 0.5
    s$random_seed             <- as.integer(rep * 100L + ma)
    env  <- run_alife(s, verbose = FALSE)
    data <- get_run_data(env)
    active <- data$ticks$n_agents > 0
    tail_lr <- tail(data$ticks$mean_learning_rate[active], 50)
    data.frame(max_age = ma, rep = rep, mean_learning = mean(tail_lr))
  })
  do.call(rbind, reps)
})

df_ceph <- do.call(rbind, results_ceph)
agg_ceph <- aggregate(mean_learning ~ max_age, data = df_ceph, FUN = mean)
agg_ceph$sd <- aggregate(mean_learning ~ max_age, data = df_ceph,
                          FUN = sd)$mean_learning

p_ceph <- ggplot(agg_ceph, aes(max_age, mean_learning)) +
  geom_ribbon(aes(ymin = mean_learning - sd, ymax = mean_learning + sd),
              alpha = 0.2, fill = "steelblue") +
  geom_line(colour = "steelblue", linewidth = 1) +
  geom_point(size = 3, colour = "steelblue") +
  labs(
    title    = "Cephalopod paradox: short lifespans can select for fast learning",
    subtitle = paste0("Complex landscape (shrubs); ", n_reps,
                      " replicates per lifespan"),
    x        = "Maximum lifespan (ticks)",
    y        = "Evolved learning rate (mean \u00b1 SD)"
  ) +
  theme_minimal(base_size = 13)

.save(p_ceph, "cephalopod_paradox", w = 8, h = 4.5)

# ── Section 36: Evolution of bad science ─────────────────────────────────────
# Uses 10 seeds per condition because the 10%-replication result is close to
# the no-replication baseline and needs multi-seed averaging to be meaningful.
message("[36] Evolution of bad science (10 seeds × 3 conditions)…")
rep_rates  <- c(0.0, 0.1, 0.5)
rep_labels <- c("No replication", "10% replication", "50% replication")
bs_seeds   <- 1L:10L

bs_results <- do.call(rbind, lapply(seq_along(rep_rates), function(k) {
  rr  <- rep_rates[k]
  lab <- rep_labels[k]
  do.call(rbind, lapply(bs_seeds, function(sd) {
    df      <- run_bad_science(n_ticks = 500L, replication_rate = rr, seed = sd)
    df$rate <- lab
    df$seed <- sd
    df
  }))
}))

df_bs <- aggregate(
  cbind(mean_fpr, mean_effort) ~ t + rate,
  data = bs_results, FUN = mean
)
df_bs$rate <- factor(df_bs$rate, levels = rev(rep_labels))
bs_cols <- c("No replication"  = "#d73027",
             "10% replication" = "#fc8d59",
             "50% replication" = "#4575b4")

p_fpr <- ggplot(df_bs, aes(t, mean_fpr, colour = rate)) +
  geom_line(linewidth = 0.9) +
  scale_colour_manual(values = bs_cols, name = NULL) +
  labs(title = "False-positive rate rises under publication pressure",
       x = "Tick", y = "Mean false-positive rate") +
  theme_minimal(base_size = 12)

p_eff <- ggplot(df_bs, aes(t, mean_effort, colour = rate)) +
  geom_line(linewidth = 0.9) +
  scale_colour_manual(values = bs_cols, name = NULL) +
  labs(title = "Research effort declines over evolutionary time",
       x = "Tick", y = "Mean research effort") +
  theme_minimal(base_size = 12)

.save(p_fpr / p_eff + patchwork::plot_layout(guides = "collect") &
        ggplot2::theme(legend.position = "bottom"),
      "bad_science", w = 8, h = 6)

# ── Section 37: Baldwin Effect experiments ───────────────────────────────────
# Loads pre-computed RDS files from Rdata/ — no Julia required for this section.
message("[37] Baldwin Effect experiments…")

# Helper: save to both inst/figures/ and vignettes/figures/ (for local preview)
.save_baldwin <- function(p, name, w = 8, h = 4.5) {
  dir.create("vignettes/figures", showWarnings = FALSE, recursive = TRUE)
  for (dir in c("inst/figures", "vignettes/figures")) {
    ggplot2::ggsave(
      file.path(dir, paste0("showcase_", name, ".png")),
      plot = p, width = w, height = h, dpi = 150
    )
  }
  message("  saved: showcase_", name, ".png")
  invisible(name)
}

# ── Exp 1: Environmental stability gradient ───────────────────────────────────
exp1 <- readRDS("Rdata/baldwin_exp1_slopes.rds")

# Scale slope to ×10⁻⁴ for readability
exp1$slope_scaled <- exp1$mean_slope * 1e4
exp1$grass_label  <- paste0("grass = ", exp1$grass_rate)
exp1$seas_label   <- paste0("seasonal = ", exp1$seasonal_amplitude)

p_exp1 <- ggplot(exp1,
    aes(x = factor(grass_rate), y = factor(seasonal_amplitude),
        fill = slope_scaled)) +
  geom_tile(colour = "white", linewidth = 0.5) +
  geom_text(aes(label = sprintf("%.2f", slope_scaled)), size = 3.5,
            fontface = "bold") +
  scale_fill_gradient2(
    low    = "#1a9850", mid = "white", high = "#d73027",
    midpoint = 0, name = expression(sigma~"slope \u00d7 10"^-4)
  ) +
  labs(
    title    = "Baldwin Effect phase diagram: all conditions select for exploration",
    subtitle = "Slope of mean_prior_sigma ~ tick (green = canalization, red = exploration selected)",
    x = "Resource abundance (grass_rate)",
    y = "Temporal variability (seasonal_amplitude)"
  ) +
  theme_minimal(base_size = 13) +
  theme(panel.grid = element_blank(),
        legend.position = "right")

.save_baldwin(p_exp1, "bnn_exp1_stability", w = 7, h = 5)

# ── Exp 2: Run length — ceiling saturation ────────────────────────────────────
exp2 <- readRDS("Rdata/baldwin_exp2_runlength.rds")

# Extract per-tick sigma from each env object; compute mean ± se across 5 seeds
traj_list <- lapply(names(exp2$results), function(rlen) {
  seeds    <- exp2$results[[rlen]]
  tick_dfs <- lapply(seeds, function(env) get_run_data(env)$ticks)
  # Compute mean sigma at each tick
  max_t  <- max(sapply(tick_dfs, nrow))
  common <- Reduce(intersect, lapply(tick_dfs, function(d) d$t))
  agg    <- do.call(rbind, lapply(tick_dfs, function(d) d[d$t %in% common, ]))
  stats  <- aggregate(mean_prior_sigma ~ t, data = agg,
                      FUN = function(x) c(mu = mean(x), se = sd(x) / sqrt(length(x))))
  data.frame(
    t          = stats$t,
    mu         = stats$mean_prior_sigma[, "mu"],
    se         = stats$mean_prior_sigma[, "se"],
    run_length = as.integer(rlen)
  )
})
traj_df <- do.call(rbind, traj_list)
traj_df$run_label <- factor(
  paste0(traj_df$run_length, " ticks"),
  levels = paste0(sort(unique(traj_df$run_length)), " ticks")
)

rl_cols <- c("1000 ticks" = "#4575b4",
             "2000 ticks" = "#74add1",
             "5000 ticks" = "#f46d43")

p_exp2 <- ggplot(traj_df, aes(x = t, y = mu, colour = run_label, fill = run_label)) +
  geom_ribbon(aes(ymin = mu - se, ymax = mu + se), alpha = 0.15, colour = NA) +
  geom_line(linewidth = 0.8) +
  geom_hline(yintercept = 0.5, linetype = "dashed", colour = "grey50",
             linewidth = 0.5) +
  annotate("text", x = max(traj_df$t) * 0.05, y = 0.50,
           label = "\u03c3 ceiling (0.50)", hjust = 0, vjust = -0.4,
           colour = "grey50", size = 3.5) +
  scale_colour_manual(values = rl_cols, name = NULL) +
  scale_fill_manual(values = rl_cols, name = NULL) +
  scale_y_continuous(limits = c(0, 0.55)) +
  labs(
    title    = "Ceiling saturation, not canalization: longer runs do not produce decline",
    subtitle = "Stable abundant environment (grass = 0.20, seasonal = 0.8); mean \u00b1 SE across 5 seeds",
    x = "Tick", y = expression("Mean prior " * sigma)
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "top")

.save_baldwin(p_exp2, "bnn_exp2_runlength", w = 8, h = 4.5)

# ── Exp 3: Brain architecture ─────────────────────────────────────────────────
exp3 <- readRDS("Rdata/baldwin_exp3_brains.rds")

# Panel A: sigma trajectories for BNN-only and BNN+RL (seed 1 each)
bnn_traj <- lapply(c("BNN only", "BNN + RL"), function(cond) {
  d <- get_run_data(exp3$results[[cond]]$seed_1)$ticks
  data.frame(t = d$t, mean_prior_sigma = d$mean_prior_sigma, condition = cond)
})
bnn_traj_df <- do.call(rbind, bnn_traj)

p3a <- ggplot(bnn_traj_df, aes(x = t, y = mean_prior_sigma, colour = condition)) +
  geom_line(linewidth = 0.8) +
  geom_hline(yintercept = 0.5, linetype = "dashed", colour = "grey60") +
  scale_colour_manual(values = c("BNN only" = "#2166ac", "BNN + RL" = "#d6604d"),
                      name = NULL) +
  scale_y_continuous(limits = c(0, 0.55)) +
  labs(title = "RL has no effect on \u03c3 dynamics",
       x = "Tick", y = expression("Mean prior " * sigma)) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top")

# Panel B: final energy by condition (from summary)
energy_df <- exp3$summary[exp3$summary$condition %in%
                            c("BNN only", "BNN + RL", "ANN + RL", "ANN null"), ]
energy_df$condition <- factor(
  energy_df$condition,
  levels = c("ANN + RL", "ANN null", "BNN + RL", "BNN only")
)
energy_df$brain_type <- ifelse(grepl("BNN", energy_df$condition), "BNN", "ANN")

p3b <- ggplot(energy_df, aes(x = final_energy, y = condition, fill = brain_type)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = round(final_energy, 1)), hjust = -0.1, size = 3.5) +
  scale_fill_manual(values = c("BNN" = "#92c5de", "ANN" = "#f4a582"), name = NULL) +
  scale_x_continuous(limits = c(0, 180)) +
  labs(title = "BNN pays 17% energy cost yet exploration is still the ESS",
       x = "Final mean energy", y = NULL) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top", panel.grid.major.y = element_blank())

.save_baldwin(p3a + p3b, "bnn_exp3_brains", w = 10, h = 4)

# ── Exp 4: Social modifiers ───────────────────────────────────────────────────
exp4 <- readRDS("Rdata/baldwin_exp4_social.rds")

# Order modules for display
module_order <- c("BNN + epigenetics", "BNN + kin select",
                  "BNN + social learn", "BNN baseline")
exp4$module  <- factor(exp4$module, levels = module_order)
exp4$env_lab <- factor(exp4$env,
                        levels = c("Scarce stable", "Stable abundant"))

# Colour: epigenetics highlighted
exp4$highlight <- exp4$module == "BNN + epigenetics"

p_exp4 <- ggplot(exp4, aes(x = final_sigma, y = module, colour = highlight)) +
  geom_vline(xintercept = 0.5, linetype = "dashed", colour = "grey70") +
  geom_segment(aes(xend = 0, yend = module), linewidth = 0.5, alpha = 0.5) +
  geom_point(aes(size = highlight)) +
  geom_text(aes(label = sprintf("%.2f", final_sigma)),
            hjust = -0.25, size = 3.2) +
  scale_colour_manual(values = c("TRUE" = "#d6604d", "FALSE" = "#4575b4"),
                      guide = "none") +
  scale_size_manual(values = c("TRUE" = 4, "FALSE" = 2.5), guide = "none") +
  scale_x_continuous(limits = c(0, 0.65)) +
  facet_wrap(~env_lab, ncol = 2) +
  labs(
    title    = "Epigenetic inheritance is the only mechanism that substantially reduces \u03c3",
    subtitle = "Red = epigenetics condition; dashed line = \u03c3 ceiling (0.50)",
    x = expression("Final mean prior " * sigma), y = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.major.y = element_blank(),
        strip.text = element_text(face = "bold"))

.save_baldwin(p_exp4, "bnn_exp4_social", w = 9, h = 4.5)

# ── Exp 5: MAP-Elites ─────────────────────────────────────────────────────────
exp5        <- readRDS("Rdata/baldwin_exp5_mapelites.rds")
archive_df  <- exp5$archive_df

# Background: show grid of all 121 archive cells, filled cells highlighted
# Create a full grid for context
grid_df <- expand.grid(
  sigma_bin = seq(0, 0.5, by = 0.05),
  gd_bin    = seq(0, 0.5, by = 0.05)
)

p_exp5 <- ggplot() +
  # Unfilled archive cells (background)
  geom_tile(data = grid_df,
            aes(x = sigma_bin, y = gd_bin),
            fill = "grey93", colour = "white", linewidth = 0.3) +
  # Filled cells — colour by score (= genetic diversity)
  geom_point(data = archive_df,
             aes(x = sigma, y = gd, colour = gd, size = score),
             alpha = 0.9) +
  # Threshold lines
  geom_vline(xintercept = 0.30, linetype = "dashed", colour = "#d6604d",
             linewidth = 0.6) +
  geom_hline(yintercept = 0.20, linetype = "dashed", colour = "#4575b4",
             linewidth = 0.6) +
  annotate("text", x = 0.29, y = 0.48,
           label = "low \u03c3\nzone", hjust = 1, size = 3, colour = "#d6604d") +
  annotate("text", x = 0.48, y = 0.21,
           label = "high gd zone\n(Baldwin Effect\nrequires this + low \u03c3)",
           hjust = 1, vjust = 0, size = 2.8, colour = "#4575b4") +
  scale_colour_viridis_c(name = "Genetic\ndiversity", option = "plasma") +
  scale_size_continuous(name = "Score\n(gd)", range = c(1.5, 6)) +
  labs(
    title    = "MAP-Elites: low \u03c3 only with low genetic diversity (drift, not canalization)",
    subtitle = paste0(exp5$filled, "/121 cells filled   |   \u03c3-gd correlation = +0.59   |   ",
                      "No low-\u03c3 + high-gd cells found"),
    x        = expression("Mean prior " * sigma * " (archive dimension)"),
    y        = "Genetic diversity (archive dimension)"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "right")

.save_baldwin(p_exp5, "bnn_exp5_mapelites", w = 7.5, h = 5.5)

message("─── Done. Figures saved to inst/figures/ ─────────────────────────────")
message("Now re-build the vignette: devtools::build_vignettes()")
