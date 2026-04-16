#!/usr/bin/env Rscript
# Fidelity audit: scavenging (DeVault et al. 2003).
# Prediction: scavenging provides an energy buffer under scarcity →
#            higher mean energy and/or population than baseline.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(scavenging, seed, max_ticks = 500L) {
  s <- default_specs()
  s$scavenging         <- scavenging
  s$carrion_fraction   <- 0.5
  s$carrion_decay_rate <- 0.1
  s$carrion_eat_gain   <- 3.0
  s$grass_rate         <- 0.07   # scarce to make scavenging useful
  s$n_agents_init      <- 100L
  s$grid_rows          <- 30L; s$grid_cols <- 30L
  s$max_agents         <- 400L
  s$max_ticks          <- as.integer(max_ticks)
  s$random_seed        <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$scavenging <- scavenging; d$seed <- seed
  d
}

seeds <- 1L:4L
cat("── scavenging ± at grass_rate=0.07 (4 seeds, 500 ticks)\n")
no_sc <- lapply(seeds, function(sd) one_run(FALSE, sd))
sc    <- lapply(seeds, function(sd) one_run(TRUE,  sd))

mn <- function(runs, col) {
  vapply(runs, function(d) mean(d[[col]][d$t > 100], na.rm = TRUE),
         numeric(1L))
}

no_n <- mn(no_sc, "n_agents"); sc_n <- mn(sc, "n_agents")
no_e <- mn(no_sc, "mean_energy"); sc_e <- mn(sc, "mean_energy")

cat(sprintf("\nNo scavenging: n=%.0f±%.0f  energy=%.1f±%.1f\n",
            mean(no_n), sd(no_n), mean(no_e), sd(no_e)))
cat(sprintf("Scavenging on: n=%.0f±%.0f  energy=%.1f±%.1f\n",
            mean(sc_n), sd(sc_n), mean(sc_e), sd(sc_e)))
p1_pass <- mean(sc_e) > mean(no_e)
cat(sprintf("P1 (scavenging raises mean_energy): %s (delta=%+.1f)\n",
            if (p1_pass) "PASS" else "FAIL",
            mean(sc_e) - mean(no_e)))

all_ticks <- do.call(rbind, c(no_sc, sc))
all_ticks$cond <- ifelse(all_ticks$scavenging, "scavenging", "baseline")
saveRDS(all_ticks, "dev/audit/fidelity/scavenging_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p <- ggplot(all_ticks, aes(t, mean_energy, colour = cond,
                            group = interaction(cond, seed))) +
  geom_line(alpha = 0.45, linewidth = 0.4) +
  stat_summary(aes(group = cond), fun = mean, geom = "line",
               linewidth = 1.1) +
  scale_colour_manual(values = c(baseline = "#E53935",
                                  scavenging = "#FB8C00"),
                      name = NULL) +
  labs(title = "Scavenging under scarcity (grass_rate = 0.07)",
       subtitle = sprintf("4 seeds × 500 ticks. Base e=%.1f, Scav e=%.1f",
                          mean(no_e), mean(sc_e)),
       x = "Tick", y = "mean_energy") +
  theme_minimal(base_size = 12)
ggsave("dev/audit/fidelity/figs/scavenging.png", p,
       width = 9, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/scavenging.png\n")
