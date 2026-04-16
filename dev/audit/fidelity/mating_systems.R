#!/usr/bin/env Rscript
# Fidelity audit: mating systems (Maynard Smith 1978; Williams 1975).
# Prediction: diploid sexual with recombination maintains higher genetic
#            diversity than haploid asexual — effect should be strongest
#            under fluctuating selection (Red Queen) where recombination
#            helps track a moving optimum.
#
# 0.4.1 update: pre-0.4.1 audit showed sex and asex producing similar
# diversity in a single stable environment. This version runs the
# contrast under THREE environments — stable, disease, seasonal — to
# probe where recombination pays its maintenance cost.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(ploidy, crossover_rate, env_label, seed,
                    max_ticks = 500L) {
  s <- default_specs()
  s$ploidy         <- as.integer(ploidy)
  s$crossover_rate <- crossover_rate
  s$n_agents_init  <- 100L
  s$grid_rows      <- 30L; s$grid_cols <- 30L
  s$grass_rate     <- 0.15
  s$max_agents     <- 400L
  s$max_ticks      <- as.integer(max_ticks)
  s$random_seed    <- as.integer(seed)
  if (env_label == "disease") {
    s$disease             <- TRUE
    s$disease_init_rate   <- 0.05
    s$virulence_init_mean <- 0.4
  } else if (env_label == "seasonal") {
    s$seasonal_amplitude <- 0.8
    s$season_length      <- 50L
  } else if (env_label == "parasite") {
    # 0.5.0 Hamilton 1980 Red Queen: genotype-matched coevolving parasites.
    # Reuses the signal vector as the host genotype-matching channel.
    s$signal_dims             <- 5L
    s$signal_evolution_drift  <- TRUE
    s$signal_drift_sd         <- 0.04
    s$coevolving_parasites    <- TRUE
    s$parasite_pressure       <- 3.0
    s$parasite_virulence_rate <- 0.05
    s$parasite_distance_scale <- 0.4
  }
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$ploidy         <- ploidy
  d$crossover_rate <- crossover_rate
  d$env_label      <- env_label
  d$seed           <- seed
  d
}

seeds <- 1L:3L
envs  <- c("stable", "disease", "seasonal", "parasite")
conds <- list(
  list(ploidy = 1, crossover_rate = 0.0, label = "haploid_asex"),
  list(ploidy = 2, crossover_rate = 0.1, label = "diploid_sex")
)

cat(sprintf("── mating systems: 2 ploidies × %d envs × %d seeds = %d runs\n",
            length(envs), length(seeds),
            length(conds) * length(envs) * length(seeds)))

all_runs <- list()
for (envl in envs) {
  for (cd in conds) {
    for (sd in seeds) {
      cat(sprintf("  env=%s cond=%s seed=%d\n", envl, cd$label, sd))
      all_runs[[length(all_runs) + 1L]] <-
        one_run(cd$ploidy, cd$crossover_rate, envl, sd)
    }
  }
}

fin_metric <- function(runs, col) {
  vapply(runs, function(d) mean(d[[col]][d$t > 100], na.rm = TRUE),
         numeric(1L))
}

summary_rows <- list()
for (envl in envs) {
  for (cd in conds) {
    subset <- Filter(function(d) d$env_label[1] == envl &&
                                   d$ploidy[1]    == cd$ploidy,
                     all_runs)
    divs <- fin_metric(subset, "genetic_diversity")
    ns   <- fin_metric(subset, "n_agents")
    summary_rows[[length(summary_rows) + 1L]] <- data.frame(
      env        = envl,
      cond       = cd$label,
      div_mean   = mean(divs),
      div_sd     = sd(divs),
      n_mean     = mean(ns),
      n_sd       = sd(ns)
    )
  }
}
summary <- do.call(rbind, summary_rows)

cat("\nSummary (post-burn-in t>100):\n")
print(summary)

cat("\nΔ diploid-sex - haploid-asex per env:\n")
env_deltas <- numeric()
for (envl in envs) {
  sx <- summary[summary$env == envl & summary$cond == "diploid_sex", ]
  ax <- summary[summary$env == envl & summary$cond == "haploid_asex", ]
  d  <- sx$div_mean - ax$div_mean
  env_deltas[envl] <- d
  cat(sprintf("  %-9s: Δdiv=%+6.3f  Δn=%+6.1f\n",
              envl, d, sx$n_mean - ax$n_mean))
}

p1_pass <- any(env_deltas > 0.01)
cat(sprintf("\nP1 (sex > asex in diversity in some env): %s\n",
            if (p1_pass) "PASS" else "FAIL"))
best_env <- names(which.max(env_deltas))
cat(sprintf("Best env: %s (Δdiv=%+.3f)\n", best_env, env_deltas[best_env]))

all_ticks <- do.call(rbind, all_runs)
all_ticks$cond <- ifelse(all_ticks$ploidy == 1,
                          "haploid_asex", "diploid_sex")
saveRDS(list(all_ticks = all_ticks, summary = summary),
        "dev/audit/fidelity/mating_systems_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p <- ggplot(all_ticks,
            aes(t, genetic_diversity, colour = cond,
                group = interaction(cond, seed))) +
  geom_line(alpha = 0.45, linewidth = 0.4) +
  stat_summary(aes(group = cond), fun = mean, geom = "line",
               linewidth = 1.0) +
  facet_wrap(~env_label) +
  scale_colour_manual(values = c(haploid_asex = "#377eb8",
                                  diploid_sex = "#e41a1c"),
                      name = NULL) +
  labs(title = "Mating systems × environment (Maynard Smith 1978; Williams 1975)",
       subtitle = sprintf("best env=%s, Δdiv=%+.3f", best_env,
                          env_deltas[best_env]),
       x = "Tick", y = "genetic_diversity") +
  theme_minimal(base_size = 11)
ggsave("dev/audit/fidelity/figs/mating_systems.png", p,
       width = 11, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/mating_systems.png\n")
