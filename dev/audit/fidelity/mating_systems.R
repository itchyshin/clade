#!/usr/bin/env Rscript
# Fidelity audit: mating systems (Maynard Smith 1978; Williams 1975).
# Prediction: diploid sexual with recombination maintains higher genetic
#            diversity than haploid asexual in stable environments.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(ploidy, crossover_rate, seed, max_ticks = 500L) {
  s <- default_specs()
  s$ploidy         <- as.integer(ploidy)
  s$crossover_rate <- crossover_rate
  s$n_agents_init  <- 100L
  s$grid_rows      <- 30L; s$grid_cols <- 30L
  s$grass_rate     <- 0.15
  s$max_agents     <- 400L
  s$max_ticks      <- as.integer(max_ticks)
  s$random_seed    <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$ploidy <- ploidy; d$crossover_rate <- crossover_rate; d$seed <- seed
  d
}

seeds <- 1L:4L
cat("── mating systems: haploid asex vs diploid sex (4 seeds, 500 ticks)\n")
asex <- lapply(seeds, function(sd) {
  cat(sprintf("  haploid (ploidy=1) seed %d\n", sd))
  one_run(1, 0.0, sd)
})
sex <- lapply(seeds, function(sd) {
  cat(sprintf("  diploid (ploidy=2) seed %d\n", sd))
  one_run(2, 0.1, sd)
})

fin_metric <- function(runs, col) {
  vapply(runs, function(d) mean(d[[col]][d$t > 100], na.rm = TRUE),
         numeric(1L))
}

asex_div <- fin_metric(asex, "genetic_diversity")
sex_div  <- fin_metric(sex,  "genetic_diversity")
asex_n   <- fin_metric(asex, "n_agents")
sex_n    <- fin_metric(sex,  "n_agents")

cat(sprintf("\nHaploid asex: diversity = %.3f ± %.3f, n = %.0f\n",
            mean(asex_div), sd(asex_div), mean(asex_n)))
cat(sprintf("Diploid sex:  diversity = %.3f ± %.3f, n = %.0f\n",
            mean(sex_div), sd(sex_div), mean(sex_n)))
p1_pass <- mean(sex_div) > mean(asex_div)
cat(sprintf("P1 (sex > asex in diversity): %s (delta = %+.3f)\n",
            if (p1_pass) "PASS" else "FAIL",
            mean(sex_div) - mean(asex_div)))

all_ticks <- do.call(rbind, c(asex, sex))
all_ticks$cond <- ifelse(all_ticks$ploidy == 1,
                          "haploid_asex", "diploid_sex")
saveRDS(all_ticks, "dev/audit/fidelity/mating_systems_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p <- ggplot(all_ticks, aes(t, genetic_diversity, colour = cond,
                            group = interaction(cond, seed))) +
  geom_line(alpha = 0.45, linewidth = 0.4) +
  stat_summary(aes(group = cond), fun = mean, geom = "line",
               linewidth = 1.1) +
  scale_colour_manual(values = c(haploid_asex = "#377eb8",
                                  diploid_sex = "#e41a1c"),
                      name = NULL) +
  labs(title = "Mating systems: genetic diversity over time",
       subtitle = sprintf("4 seeds × 500 ticks. Asex=%.3f, Sex=%.3f",
                          mean(asex_div), mean(sex_div)),
       x = "Tick", y = "genetic_diversity") +
  theme_minimal(base_size = 12)
ggsave("dev/audit/fidelity/figs/mating_systems.png", p,
       width = 9, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/mating_systems.png\n")
