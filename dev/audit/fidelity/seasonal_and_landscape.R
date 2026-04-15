#!/usr/bin/env Rscript
# Fidelity audit: seasonal dynamics + complex-landscape.
# Both scenarios lack a primary biological-theory citation; we verify
# that the mechanism produces the expected qualitative signatures
# (seasonal: grass_coverage oscillation; landscape: multi-layer usage).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_seasonal <- function(amp, seed, max_ticks = 400L) {
  s <- default_specs()
  s$seasonal_amplitude <- amp
  s$season_length      <- 50L
  s$n_agents_init      <- 100L
  s$grid_rows          <- 30L; s$grid_cols <- 30L
  s$grass_rate         <- 0.15
  s$max_agents         <- 400L
  s$max_ticks          <- as.integer(max_ticks)
  s$random_seed        <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$amp <- amp; d$seed <- seed
  d
}

one_landscape <- function(complex, seed, max_ticks = 400L) {
  s <- default_specs()
  s$complex_landscape <- complex
  s$n_agents_init     <- 100L
  s$grid_rows         <- 30L; s$grid_cols <- 30L
  s$grass_rate        <- 0.15
  s$max_agents        <- 400L
  s$max_ticks         <- as.integer(max_ticks)
  s$random_seed       <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$complex <- complex; d$seed <- seed
  d
}

# ── Seasonal ───────────────────────────────────────────────────────────────

cat("── seasonal amp sweep (3 seeds, 400 ticks)\n")
seeds <- 1L:3L
amps <- c(0.0, 0.4, 0.8)
seasonal_runs <- list()
for (amp in amps) {
  for (sd in seeds) {
    cat(sprintf("  amp=%.1f seed %d\n", amp, sd))
    seasonal_runs[[length(seasonal_runs) + 1L]] <- one_seasonal(amp, sd)
  }
}

# Measure grass_coverage autocorrelation at lag = season_length / 2 = 25
# which should be negative under strong seasonality (trough vs peak)
lag_ac <- function(d, lag = 25L) {
  x <- d$grass_coverage[d$t > 50]
  if (length(x) < lag + 10L) return(NA_real_)
  ac <- stats::acf(x, lag.max = lag + 5L, plot = FALSE)
  ac$acf[lag + 1L]
}

seasonal_df <- do.call(rbind, lapply(seasonal_runs, function(d) {
  data.frame(amp = d$amp[1], seed = d$seed[1],
             lag25_ac = lag_ac(d),
             var_grass = var(d$grass_coverage[d$t > 50]))
}))
cat("\nSeasonal summary:\n")
print(aggregate(cbind(lag25_ac, var_grass) ~ amp, data = seasonal_df, FUN = mean))

# ── Complex landscape ──────────────────────────────────────────────────────

cat("\n── complex_landscape ± (3 seeds, 400 ticks)\n")
base_runs <- lapply(seeds, function(sd) one_landscape(FALSE, sd))
comp_runs <- lapply(seeds, function(sd) one_landscape(TRUE, sd))

n_ground <- function(runs) {
  vapply(runs, function(d) mean(d$n_ground_agents[d$t > 100], na.rm = TRUE),
         numeric(1L))
}
n_shrub <- function(runs) {
  vapply(runs, function(d) mean(d$n_shrub_agents[d$t > 100], na.rm = TRUE),
         numeric(1L))
}
n_canopy <- function(runs) {
  vapply(runs, function(d) mean(d$n_canopy_agents[d$t > 100], na.rm = TRUE),
         numeric(1L))
}

cat(sprintf("\nBaseline:  n_ground=%.1f  n_shrub=%.1f  n_canopy=%.1f\n",
            mean(n_ground(base_runs)),
            mean(n_shrub(base_runs)),
            mean(n_canopy(base_runs))))
cat(sprintf("Complex:   n_ground=%.1f  n_shrub=%.1f  n_canopy=%.1f\n",
            mean(n_ground(comp_runs)),
            mean(n_shrub(comp_runs)),
            mean(n_canopy(comp_runs))))

all_seasonal <- do.call(rbind, seasonal_runs)
all_landscape <- do.call(rbind, c(base_runs, comp_runs))

saveRDS(list(seasonal = all_seasonal, landscape = all_landscape,
             seasonal_summary = seasonal_df),
        "dev/audit/fidelity/seasonal_landscape_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)

p_seas <- ggplot(all_seasonal,
                  aes(t, grass_coverage, colour = factor(amp),
                      group = interaction(amp, seed))) +
  geom_line(alpha = 0.4, linewidth = 0.35) +
  stat_summary(aes(group = amp), fun = mean, geom = "line",
               linewidth = 1.0) +
  labs(title = "Seasonal amplitude × grass_coverage",
       x = "Tick", y = "grass_coverage", colour = "amp") +
  theme_minimal(base_size = 11)

p_land <- ggplot(all_landscape,
                  aes(t, n_canopy_agents, colour = complex,
                      group = interaction(complex, seed))) +
  geom_line(alpha = 0.4, linewidth = 0.35) +
  stat_summary(aes(group = complex), fun = mean, geom = "line",
               linewidth = 1.0) +
  scale_colour_manual(values = c("FALSE" = "#9E9E9E", "TRUE" = "#4CAF50"),
                      labels = c("simple", "complex"), name = NULL) +
  labs(title = "Complex landscape: canopy occupancy",
       x = "Tick", y = "n_canopy_agents") +
  theme_minimal(base_size = 11)

p <- p_seas | p_land
ggsave("dev/audit/fidelity/figs/seasonal_landscape.png", p,
       width = 12, height = 5, dpi = 150)
cat("\nWrote dev/audit/fidelity/figs/seasonal_landscape.png\n")
