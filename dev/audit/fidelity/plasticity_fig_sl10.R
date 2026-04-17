# Regenerate showcase_22_plasticity.png at the season_length = 10 regime
# (short seasons, fast_specs, 40×40 buffered world) where the DeWitt-Scheiner
# signal actually emerges. 5 seeds × 2 conditions × 2000 ticks.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2)
})

run_one <- function(amp, seed) {
  s <- fast_specs()
  s$n_agents_init            <- 180L
  s$max_agents               <- 800L
  s$grid_rows                <- 40L
  s$grid_cols                <- 40L
  s$grass_rate               <- 0.25
  s$phenotypic_plasticity    <- TRUE
  s$plasticity_init_mean     <- 0.3
  s$plasticity_mutation_sd   <- 0.05
  s$bnn_sigma_source         <- "trait"
  s$brain_energy_sigma_scale <- 0.05
  s$seasonal_amplitude       <- amp
  s$season_length            <- 10L     # KEY: within-lifetime variability
  s$random_seed              <- as.integer(seed)
  d <- get_run_data(run_alife(s, verbose = FALSE))$ticks
  d$cond <- if (amp > 0) "seasonal (amp=0.35)" else "stable"
  d$seed <- seed
  d
}

# Match the sweep's execution order (amp outer, seed inner) so Julia RNG
# contamination between runs produces the same trajectories as the sweep
# reported — flipping the order flips the outcome even with random_seed set.
all <- do.call(rbind, lapply(c(0.0, 0.35), function(amp) {
  do.call(rbind, lapply(c(1L, 7L, 13L, 19L, 25L), function(sd) {
    run_one(amp, sd)
  }))
}))
all$cond <- factor(all$cond, levels = c("stable", "seasonal (amp=0.35)"))

# Proper per-seed last-tick average (not tail() of the concatenated df)
final_by_seed <- aggregate(mean_plasticity ~ cond + seed, data = all,
                            FUN = function(x) tail(x, 1L))
stab_final <- mean(final_by_seed$mean_plasticity[final_by_seed$cond == "stable"])
seas_final <- mean(final_by_seed$mean_plasticity[
                     final_by_seed$cond == "seasonal (amp=0.35)"])

p <- ggplot(all, aes(t, mean_plasticity, colour = cond,
                      group = interaction(cond, seed))) +
  geom_line(alpha = 0.35, linewidth = 0.4) +
  stat_summary(aes(group = cond), fun = mean, geom = "line",
                linewidth = 1.2) +
  scale_colour_manual(values = c("stable" = "#377eb8",
                                  "seasonal (amp=0.35)" = "#e41a1c"),
                      name = NULL) +
  labs(
    title = "Plasticity evolves when seasons are shorter than a lifetime",
    subtitle = sprintf(
      "5 seeds × 2000 ticks (~66 gens). fast_specs (max_age=30) + season_length=10. Both start at 0.3."),
    x = "Tick", y = "mean_plasticity"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

for (d in c("inst/figures", "vignettes/figures")) {
  ggsave(file.path(d, "showcase_22_plasticity.png"), plot = p,
         width = 9, height = 5, dpi = 150)
}
message(sprintf("  saved figure. stable final = %.3f, seasonal final = %.3f",
                stab_final, seas_final))
