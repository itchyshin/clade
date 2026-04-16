#!/usr/bin/env Rscript
# Fidelity audit: dispersal & IFD (Fretwell & Lucas 1970; Shine 2011).
# Predictions:
#   P1. habitat_preference_evolution=TRUE → mean_habitat_preference
#       drifts from 0 to positive (agents evolve preference for
#       high-grass cells). Magnitude should grow with preference
#       strength (higher selection gradient).
#   P2. spatial_sorting=TRUE → mean_front_dispersal > mean_rear_dispersal
#       at the invasion front.
#
# 0.4.1 update: pre-0.4.1 P1 gave Δ≈+0.01 (directional but under the
# 0.02 promotion threshold) at strength=0.5. This audit sweeps
# `habitat_preference_strength ∈ {0.5, 1, 2, 4}` × `max_ticks ∈
# {500, 1000}` to find a regime where the IFD signal exceeds 0.02.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

run_ifd <- function(pref_strength, max_ticks, seed) {
  s <- default_specs()
  s$habitat_preference_evolution   <- TRUE
  s$habitat_preference_init_mean   <- 0.0
  s$habitat_preference_mutation_sd <- 0.03
  s$habitat_preference_strength    <- pref_strength
  s$n_agents_init       <- 100L
  s$grid_rows           <- 30L; s$grid_cols <- 30L
  s$grass_rate          <- 0.15
  s$max_agents          <- 400L
  s$max_ticks           <- as.integer(max_ticks)
  s$random_seed         <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$seed          <- seed
  d$pref_strength <- pref_strength
  d$run_ticks     <- max_ticks
  d$cond          <- "ifd"
  d
}

run_sort <- function(seed, max_ticks = 500L) {
  s <- default_specs()
  s$dispersal_evolution   <- TRUE
  s$dispersal_init_mean   <- 0.3
  s$dispersal_mutation_sd <- 0.04
  s$spatial_sorting       <- TRUE
  s$sorting_mating_boost  <- 3.0
  s$toroidal              <- FALSE   # invasion front needs an edge
  s$n_agents_init         <- 80L
  s$grid_rows             <- 40L; s$grid_cols <- 40L
  s$grass_rate            <- 0.12
  s$max_agents            <- 400L
  s$max_ticks             <- as.integer(max_ticks)
  s$random_seed           <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$seed <- seed; d$cond <- "sort"
  d
}

# ---------- P1: habitat_preference_strength × max_ticks grid -----------
grid <- expand.grid(
  pref_strength = c(0.5, 1.0, 2.0, 4.0),
  run_ticks     = c(500L, 1000L),
  KEEP.OUT.ATTRS = FALSE
)
seeds <- 1L:2L
cat(sprintf("── IFD grid: %d combos × %d seeds = %d runs\n",
            nrow(grid), length(seeds), nrow(grid) * length(seeds)))

ifd_runs <- list()
for (i in seq_len(nrow(grid))) {
  row <- grid[i, ]
  for (sd in seeds) {
    cat(sprintf("  strength=%.1f ticks=%d seed=%d\n",
                row$pref_strength, row$run_ticks, sd))
    ifd_runs[[length(ifd_runs) + 1L]] <-
      run_ifd(row$pref_strength, row$run_ticks, sd)
  }
}

summary_rows <- list()
for (i in seq_len(nrow(grid))) {
  row <- grid[i, ]
  subset <- Filter(function(d) d$pref_strength[1] == row$pref_strength &&
                                 d$run_ticks[1]     == row$run_ticks,
                   ifd_runs)
  deltas <- vapply(subset,
                   function(d) tail(d$mean_habitat_preference, 1L) -
                                d$mean_habitat_preference[1],
                   numeric(1L))
  summary_rows[[i]] <- data.frame(
    pref_strength = row$pref_strength,
    run_ticks     = row$run_ticks,
    delta_mean    = mean(deltas),
    delta_sd      = sd(deltas),
    n_seeds       = length(deltas)
  )
}
summary <- do.call(rbind, summary_rows)

cat("\nIFD grid summary (Δ = final - init habitat_preference):\n")
print(summary[order(-summary$delta_mean), ])

best <- summary[which.max(summary$delta_mean), ]
cat(sprintf("\nBest regime: strength=%.1f ticks=%d  Δ=%+.3f ± %.3f\n",
            best$pref_strength, best$run_ticks,
            best$delta_mean, best$delta_sd))
p1_pass <- best$delta_mean > 0.02
cat(sprintf("P1 (habitat preference evolves upward, Δ > 0.02): %s\n",
            if (p1_pass) "PASS" else "PARTIAL (directional, small)"))

# ---------- P2: spatial sorting (legacy, unchanged) -----------
cat("\n── Spatial sorting (2 seeds, 500 ticks, non-toroidal)\n")
sort_seeds <- 1L:2L
sort_runs <- lapply(sort_seeds, function(sd) {
  cat(sprintf("  sort seed %d\n", sd))
  run_sort(sd)
})
fin_front <- vapply(sort_runs,
                    function(d) tail(d$mean_front_dispersal, 1L),
                    numeric(1L))
fin_rear  <- vapply(sort_runs,
                    function(d) tail(d$mean_rear_dispersal, 1L),
                    numeric(1L))
cat(sprintf("\nFront dispersal: %.3f ± %.3f\n",
            mean(fin_front, na.rm=TRUE), sd(fin_front, na.rm=TRUE)))
cat(sprintf("Rear  dispersal: %.3f ± %.3f\n",
            mean(fin_rear,  na.rm=TRUE), sd(fin_rear,  na.rm=TRUE)))
p2_pass <- mean(fin_front, na.rm=TRUE) > mean(fin_rear, na.rm=TRUE)
cat(sprintf("P2 (front > rear dispersal): %s (Δ=%+.3f)\n",
            if (p2_pass) "PASS" else "FAIL",
            mean(fin_front, na.rm=TRUE) - mean(fin_rear, na.rm=TRUE)))

saveRDS(list(ifd_summary = summary,
             ifd_runs    = ifd_runs,
             sort_runs   = sort_runs),
        "dev/audit/fidelity/dispersal_ifd_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
ifd_all <- do.call(rbind, ifd_runs)
ifd_all$cond_label <- sprintf("str=%.1f / %d-tick",
                               ifd_all$pref_strength,
                               ifd_all$run_ticks)
p_ifd <- ggplot(ifd_all,
                aes(t, mean_habitat_preference,
                    colour = factor(pref_strength),
                    group = interaction(pref_strength, run_ticks, seed))) +
  geom_line(alpha = 0.45, linewidth = 0.4) +
  stat_summary(aes(group = factor(pref_strength)), fun = mean,
               geom = "line", linewidth = 1.0) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
  facet_wrap(~run_ticks, labeller = label_both) +
  scale_colour_viridis_d(name = "pref_strength") +
  labs(title = "IFD grid: habitat_preference evolution",
       subtitle = "Fretwell & Lucas (1970): preference strength × run length",
       x = "Tick", y = "mean_habitat_preference") +
  theme_minimal(base_size = 11)

df_sort <- do.call(rbind, sort_runs)
df_sort_long <- rbind(
  data.frame(t = df_sort$t, disp = df_sort$mean_front_dispersal,
             seed = df_sort$seed, zone = "front"),
  data.frame(t = df_sort$t, disp = df_sort$mean_rear_dispersal,
             seed = df_sort$seed, zone = "rear")
)
p_sort <- ggplot(df_sort_long,
                 aes(t, disp, colour = zone,
                     group = interaction(zone, seed))) +
  geom_line(alpha = 0.4, linewidth = 0.4) +
  stat_summary(aes(group = zone), fun = mean, geom = "line",
               linewidth = 1.0) +
  scale_colour_manual(values = c(front = "#E91E63", rear = "#2196F3"),
                      name = NULL) +
  labs(title = "Spatial sorting: front vs rear dispersal",
       x = "Tick", y = "mean dispersal") +
  theme_minimal(base_size = 11)

p <- p_ifd / p_sort
p <- p + plot_annotation(
  title = "Dispersal / IFD audit (Fretwell & Lucas 1970; Shine 2011) — 0.4.1 grid",
  theme = theme(plot.title = element_text(face = "bold")))
ggsave("dev/audit/fidelity/figs/dispersal_ifd.png", p,
       width = 12, height = 8, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/dispersal_ifd.png\n")
