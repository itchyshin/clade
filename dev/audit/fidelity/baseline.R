# Fidelity runner for scenario: baseline foraging world.
#
# Reproduces the baseline scenario across 10 seeds and writes summary
# statistics + a single composite figure. Deterministic given the
# seed list below.
#
# Usage:
#   Rscript dev/audit/fidelity/baseline.R
#
# Writes:
#   dev/audit/fidelity/figs/baseline.png
#   dev/audit/fidelity/baseline_results.rds

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
  library(ggplot2)
  library(patchwork)
})

# Match the vignette's displayed code exactly so the audit reproduces
# what users see, not a special tuning.
.run_one <- function(seed) {
  s <- default_specs()
  s$grid_rows     <- 20L
  s$grid_cols     <- 20L
  s$n_agents_init <- 40L
  s$max_ticks     <- 300L
  s$random_seed   <- as.integer(seed)

  env   <- run_alife(s)
  rd    <- get_run_data(env)
  ticks <- rd$ticks
  ticks$seed <- seed
  ticks
}

seeds <- 1L:10L
message(sprintf("[baseline] running %d seeds × 300 ticks × 20×20 grid × 40 agents ...",
                length(seeds)))

t0 <- Sys.time()
per_seed <- lapply(seeds, function(sd) {
  message(sprintf("  seed %d", sd))
  .run_one(sd)
})
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
message(sprintf("[baseline] all seeds done in %.1f s (%.1f s/seed)",
                elapsed, elapsed / length(seeds)))

all_runs <- do.call(rbind, per_seed)
saveRDS(all_runs, "dev/audit/fidelity/baseline_results.rds")

# Summary statistics per tick (mean ± SD across seeds)
ticks_of_interest <- c(1, 50, 100, 150, 200, 250, 300)
summarise_tick <- function(t) {
  sub <- all_runs[all_runs$t == t, , drop = FALSE]
  if (nrow(sub) == 0) return(NULL)
  data.frame(
    tick         = t,
    n_agents_m   = mean(sub$n_agents,        na.rm = TRUE),
    n_agents_sd  = stats::sd  (sub$n_agents, na.rm = TRUE),
    energy_m     = mean(sub$mean_energy,     na.rm = TRUE),
    energy_sd    = stats::sd  (sub$mean_energy,     na.rm = TRUE),
    gd_m         = mean(sub$genetic_diversity, na.rm = TRUE),
    gd_sd        = stats::sd  (sub$genetic_diversity, na.rm = TRUE),
    grass_m      = mean(sub$grass_coverage,  na.rm = TRUE),
    grass_sd     = stats::sd  (sub$grass_coverage,  na.rm = TRUE)
  )
}
summary_tbl <- do.call(rbind, lapply(ticks_of_interest, summarise_tick))
print(summary_tbl, row.names = FALSE)
saveRDS(summary_tbl, "dev/audit/fidelity/baseline_summary.rds")

# Figure: four panels (population, mean energy, genetic diversity, grass)
# with one line per seed + bold mean overlay.
.panel <- function(var, ylab, title) {
  mean_df <- aggregate(all_runs[[var]],
                       by = list(t = all_runs$t),
                       FUN = mean, na.rm = TRUE)
  names(mean_df)[2] <- "mean"
  ggplot(all_runs, aes(t, .data[[var]], group = seed)) +
    geom_line(colour = "grey70", linewidth = 0.3, alpha = 0.7) +
    geom_line(data = mean_df, aes(t, mean), inherit.aes = FALSE,
              colour = "#d73027", linewidth = 0.9) +
    labs(title = title, x = "Tick", y = ylab) +
    theme_minimal(base_size = 11)
}

p <- (.panel("n_agents",          "Population size",     "Population") |
      .panel("mean_energy",       "Mean energy",         "Mean energy")) /
     (.panel("genetic_diversity", "Genetic diversity",   "Genetic diversity") |
      .panel("grass_coverage",    "Grass coverage",      "Grass coverage")) +
     patchwork::plot_annotation(
       title    = "Baseline world: 10 seeds, 300 ticks, 20×20 grid, 40 initial agents",
       subtitle = "Grey lines per seed; red = across-seed mean",
       theme    = ggplot2::theme(plot.title = ggplot2::element_text(face = "bold"))
     )

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
ggsave("dev/audit/fidelity/figs/baseline.png", p,
       width = 10, height = 7, dpi = 150)
message("[baseline] wrote dev/audit/fidelity/figs/baseline.png")
