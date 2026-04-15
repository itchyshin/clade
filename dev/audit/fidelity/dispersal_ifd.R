#!/usr/bin/env Rscript
# Fidelity audit: dispersal & IFD (Fretwell & Lucas 1970; Shine 2011).
# Predictions:
#   P1. habitat_preference_evolution=TRUE → mean_habitat_preference
#       drifts from 0 to positive (agents evolve preference for
#       high-grass cells).
#   P2. spatial_sorting=TRUE → mean_front_dispersal > mean_rear_dispersal
#       at the invasion front.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

run_ifd <- function(seed, max_ticks = 500L) {
  s <- default_specs()
  s$habitat_preference_evolution <- TRUE
  s$habitat_preference_init_mean <- 0.0
  s$habitat_preference_mutation_sd <- 0.03
  s$habitat_preference_strength <- 0.5
  s$n_agents_init       <- 100L
  s$grid_rows           <- 30L; s$grid_cols <- 30L
  s$grass_rate          <- 0.15
  s$max_agents          <- 400L
  s$max_ticks           <- as.integer(max_ticks)
  s$random_seed         <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$seed <- seed; d$cond <- "ifd"
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

seeds <- 1L:4L
cat("── IFD sweep (4 seeds, 500 ticks, habitat_preference_evolution=TRUE)\n")
ifd_runs <- lapply(seeds, function(sd) {
  cat(sprintf("  IFD seed %d\n", sd))
  run_ifd(sd)
})
fin_pref <- vapply(ifd_runs,
                   function(d) tail(d$mean_habitat_preference, 1L),
                   numeric(1L))
init_pref <- vapply(ifd_runs,
                    function(d) d$mean_habitat_preference[1],
                    numeric(1L))
cat(sprintf("\nHabitat preference: init=%.3f → final=%.3f (Δ=%+.3f)\n",
            mean(init_pref), mean(fin_pref),
            mean(fin_pref - init_pref)))
p1_pass <- mean(fin_pref - init_pref) > 0.02
cat(sprintf("P1 (preference evolves upward): %s\n",
            if (p1_pass) "PASS" else "FAIL"))

cat("\n── Spatial sorting (4 seeds, 500 ticks, non-toroidal)\n")
sort_runs <- lapply(seeds, function(sd) {
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
            mean(fin_rear, na.rm=TRUE), sd(fin_rear, na.rm=TRUE)))
p2_pass <- mean(fin_front, na.rm=TRUE) > mean(fin_rear, na.rm=TRUE)
cat(sprintf("P2 (front > rear dispersal): %s (Δ=%+.3f)\n",
            if (p2_pass) "PASS" else "FAIL",
            mean(fin_front, na.rm=TRUE) - mean(fin_rear, na.rm=TRUE)))

all_ticks <- do.call(rbind, c(ifd_runs, sort_runs))
saveRDS(all_ticks, "dev/audit/fidelity/dispersal_ifd_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p_ifd <- ggplot(do.call(rbind, ifd_runs),
                aes(t, mean_habitat_preference, group = seed)) +
  geom_line(alpha = 0.45, colour = "#2196F3", linewidth = 0.4) +
  stat_summary(aes(group = 1), fun = mean, geom = "line",
               colour = "#2196F3", linewidth = 1.1) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
  labs(title = "IFD: habitat_preference evolution (4 seeds)",
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
               linewidth = 1.1) +
  scale_colour_manual(values = c(front = "#E91E63", rear = "#2196F3"),
                      name = NULL) +
  labs(title = "Spatial sorting: front vs rear dispersal (4 seeds)",
       x = "Tick", y = "mean dispersal") +
  theme_minimal(base_size = 11)

p <- p_ifd | p_sort
p <- p + plot_annotation(
  title = "Dispersal / IFD audit (Fretwell & Lucas 1970; Shine 2011)",
  theme = theme(plot.title = element_text(face = "bold")))
ggsave("dev/audit/fidelity/figs/dispersal_ifd.png", p,
       width = 12, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/dispersal_ifd.png\n")
