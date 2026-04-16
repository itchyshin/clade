#!/usr/bin/env Rscript
# Fidelity audit: stress hypermutation (McKenzie & Rosenberg 2001).
# Prediction: under resource scarcity, stress hypermutation raises
#             genetic diversity compared to baseline.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(hypermut, seed, max_ticks = 500L) {
  s <- default_specs()
  s$stress_hypermutation       <- hypermut
  s$stress_threshold           <- 40.0
  s$stress_mutation_multiplier <- 5.0
  s$grass_rate                 <- 0.06
  s$n_agents_init              <- 100L
  s$grid_rows                  <- 30L; s$grid_cols <- 30L
  s$max_agents                 <- 400L
  s$max_ticks                  <- as.integer(max_ticks)
  s$random_seed                <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$hypermut <- hypermut; d$seed <- seed
  d
}

seeds <- 1L:4L
cat("── stress_hypermutation ± at grass_rate=0.06 (4 seeds, 500 ticks)\n")
base <- lapply(seeds, function(sd) {
  cat(sprintf("  baseline seed %d\n", sd))
  one_run(FALSE, sd)
})
hm <- lapply(seeds, function(sd) {
  cat(sprintf("  hypermut seed %d\n", sd))
  one_run(TRUE, sd)
})

fin_div <- function(runs) {
  vapply(runs, function(d) mean(d$genetic_diversity[d$t > 200], na.rm = TRUE),
         numeric(1L))
}
fin_n <- function(runs) {
  vapply(runs, function(d) mean(d$n_agents[d$t > 200]), numeric(1L))
}
base_div <- fin_div(base); hm_div <- fin_div(hm)
base_n <- fin_n(base); hm_n <- fin_n(hm)

cat(sprintf("\nBaseline:  diversity = %.3f ± %.3f, n = %.0f\n",
            mean(base_div), sd(base_div), mean(base_n)))
cat(sprintf("Hypermut:  diversity = %.3f ± %.3f, n = %.0f\n",
            mean(hm_div), sd(hm_div), mean(hm_n)))
p1_pass <- mean(hm_div) > mean(base_div)
cat(sprintf("P1 (hypermutation raises diversity): %s (delta = %+.3f)\n",
            if (p1_pass) "PASS" else "FAIL",
            mean(hm_div) - mean(base_div)))

all_ticks <- do.call(rbind, c(base, hm))
all_ticks$cond <- ifelse(all_ticks$hypermut, "hypermutation", "baseline")
saveRDS(all_ticks, "dev/audit/fidelity/stress_hypermutation_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p <- ggplot(all_ticks, aes(t, genetic_diversity, colour = cond,
                            group = interaction(cond, seed))) +
  geom_line(alpha = 0.45, linewidth = 0.4) +
  stat_summary(aes(group = cond), fun = mean, geom = "line",
               linewidth = 1.1) +
  scale_colour_manual(values = c(baseline = "#878787",
                                  hypermutation = "#d6604d"),
                      name = NULL) +
  labs(title = "Stress hypermutation: diversity under scarcity (grass_rate=0.06)",
       subtitle = sprintf("4 seeds × 500 ticks. Baseline=%.3f, Hypermut=%.3f",
                          mean(base_div), mean(hm_div)),
       x = "Tick", y = "genetic_diversity") +
  theme_minimal(base_size = 12)
ggsave("dev/audit/fidelity/figs/stress_hypermutation.png", p,
       width = 9, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/stress_hypermutation.png\n")
