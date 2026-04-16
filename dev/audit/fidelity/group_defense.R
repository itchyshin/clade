#!/usr/bin/env Rscript
# Fidelity audit: group defense / selfish herd (Hamilton 1971).
# Prediction: group defense ON reduces effective predation → larger
#             population than no-defense baseline under same predator pressure.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(gd_on, seed, max_ticks = 500L) {
  s <- default_specs()
  s$group_defense           <- gd_on
  s$group_defense_radius    <- 2L
  s$group_defense_strength  <- 0.5
  s$n_predators_init        <- 15L
  s$predator_attack_strength <- 60
  s$predator_max_agents     <- 50L
  s$n_agents_init           <- 100L
  s$grid_rows               <- 30L; s$grid_cols <- 30L
  s$grass_rate              <- 0.15
  s$max_agents              <- 400L
  s$max_ticks               <- as.integer(max_ticks)
  s$random_seed             <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$gd_on <- gd_on; d$seed <- seed
  d
}

seeds <- 1L:4L
cat("── group_defense ± (4 seeds, 500 ticks, 15 predators, strength=0.5)\n")
no_gd <- lapply(seeds, function(sd) {
  cat(sprintf("  no_gd seed %d\n", sd))
  one_run(FALSE, sd)
})
gd <- lapply(seeds, function(sd) {
  cat(sprintf("  gd seed %d\n", sd))
  one_run(TRUE, sd)
})

fin_n <- function(runs) {
  vapply(runs, function(d) mean(d$n_agents[d$t > 100]), numeric(1L))
}
n_no <- fin_n(no_gd); n_gd <- fin_n(gd)
cat(sprintf("\nNo group defense:   mean n = %.1f ± %.1f\n",
            mean(n_no), sd(n_no)))
cat(sprintf("Group defense on:   mean n = %.1f ± %.1f\n",
            mean(n_gd), sd(n_gd)))
p1_pass <- mean(n_gd) > mean(n_no) * 1.05
cat(sprintf("P1 (gd boosts population > 5%%): %s (ratio=%.2fx)\n",
            if (p1_pass) "PASS" else "FAIL",
            mean(n_gd) / mean(n_no)))

all_ticks <- do.call(rbind, c(no_gd, gd))
all_ticks$cond <- ifelse(all_ticks$gd_on, "group_defense", "baseline")
saveRDS(all_ticks, "dev/audit/fidelity/group_defense_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p <- ggplot(all_ticks, aes(t, n_agents, colour = cond,
                            group = interaction(cond, seed))) +
  geom_line(alpha = 0.45, linewidth = 0.4) +
  stat_summary(aes(group = cond), fun = mean, geom = "line",
               linewidth = 1.1) +
  scale_colour_manual(values = c(baseline = "#E53935",
                                  group_defense = "#43A047"),
                      name = NULL) +
  labs(title = "Group defense: population under 15 predators",
       subtitle = sprintf("4 seeds × 500 ticks. Baseline n=%.0f, GD n=%.0f",
                          mean(n_no), mean(n_gd)),
       x = "Tick", y = "n_agents") +
  theme_minimal(base_size = 12)
ggsave("dev/audit/fidelity/figs/group_defense.png", p,
       width = 9, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/group_defense.png\n")
