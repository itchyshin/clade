#!/usr/bin/env Rscript
# 0.5.3 Red Queen firming-up audit.
#
# Motivation: the 0.5.1 mating_systems audit showed Δn = +1.1 (sex > asex
# under discrete-allele parasites) at 3 seeds. The 0.5.2 body-size P2 audit
# taught us that 3-5 seed direction claims sit inside the noise band.
# 16-seed sweep matches the body-size precedent and tells us whether the
# canonical Red Queen signal is statistically robust.
#
# Protocol: haploid asex vs diploid sex × 16 seeds × 3 predator regimes
# (none, continuous-trait parasites, discrete-allele parasites) × 500 ticks.
# 96 runs, ~30–40 min wall.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

make_s <- function(ploidy, env_label, seed, max_ticks = 500L) {
  s <- default_specs()
  s$ploidy         <- as.integer(ploidy)
  s$crossover_rate <- if (ploidy == 2) 0.5 else 0.0
  s$n_agents_init  <- 100L
  s$grid_rows      <- 30L; s$grid_cols <- 30L
  s$grass_rate     <- 0.15
  s$max_agents     <- 400L
  s$max_ticks      <- as.integer(max_ticks)
  s$random_seed    <- as.integer(seed)
  if (env_label == "parasite_continuous") {
    s$signal_dims             <- 5L
    s$signal_evolution_drift  <- TRUE
    s$signal_drift_sd         <- 0.04
    s$coevolving_parasites    <- TRUE
    s$parasite_match_mode     <- "continuous"
    s$parasite_pressure       <- 3.0
    s$parasite_virulence_rate <- 0.05
    s$parasite_distance_scale <- 0.4
  } else if (env_label == "parasite_discrete") {
    s$coevolving_parasites        <- TRUE
    s$parasite_match_mode         <- "discrete"
    s$n_parasite_loci             <- 16L
    s$parasite_pressure           <- 2.0
    s$parasite_virulence_rate     <- 0.15
    s$parasite_discrete_exponent  <- 6.0
    s$parasite_mutation_rate      <- 0.02
  }
  s
}

seeds <- 1L:16L
envs  <- c("stable", "parasite_continuous", "parasite_discrete")
ploidies <- c(1L, 2L)

cat(sprintf("── 0.5.3 Red Queen firming-up: %d ploidies × %d envs × %d seeds = %d runs\n",
            length(ploidies), length(envs), length(seeds),
            length(ploidies) * length(envs) * length(seeds)))

all_runs <- list()
for (envl in envs) {
  for (ploidy in ploidies) {
    for (sd in seeds) {
      if (sd %% 4 == 1) cat(sprintf("  env=%s ploidy=%d seed=%d\n", envl, ploidy, sd))
      s <- make_s(ploidy, envl, sd)
      env <- run_alife(s, verbose = FALSE)
      p <- env$progress
      idx <- p$t > 150
      all_runs[[length(all_runs) + 1L]] <- data.frame(
        env     = envl,
        ploidy  = ploidy,
        seed    = sd,
        n_mean  = mean(p$n_agents[idx], na.rm = TRUE),
        div_mean = mean(p$genetic_diversity[idx], na.rm = TRUE)
      )
    }
  }
}
runs_df <- do.call(rbind, all_runs)

# Summarise per cell
summary_rows <- list()
for (envl in envs) {
  for (ploidy in ploidies) {
    sub <- runs_df[runs_df$env == envl & runs_df$ploidy == ploidy, ]
    summary_rows[[length(summary_rows) + 1L]] <- data.frame(
      env      = envl,
      ploidy   = ploidy,
      label    = if (ploidy == 1) "haploid_asex" else "diploid_sex",
      n_mean   = mean(sub$n_mean),
      n_se     = sd(sub$n_mean) / sqrt(nrow(sub)),
      div_mean = mean(sub$div_mean),
      div_se   = sd(sub$div_mean) / sqrt(nrow(sub)),
      n_seeds  = nrow(sub)
    )
  }
}
summary <- do.call(rbind, summary_rows)

cat("\nCell summary (16 seeds per cell):\n")
print(summary)

# Per-env sex-minus-asex differences with 2×SE hypothesis test
cat("\nRed Queen test — Δ(sex − asex) per env:\n")
for (envl in envs) {
  sx <- summary[summary$env == envl & summary$ploidy == 2, ]
  ax <- summary[summary$env == envl & summary$ploidy == 1, ]
  dn    <- sx$n_mean - ax$n_mean
  dn_se <- sqrt(sx$n_se^2 + ax$n_se^2)
  direction <- if (dn > 2 * dn_se) "sex wins (2×SE)" else
               if (dn < -2 * dn_se) "asex wins (2×SE)" else
               "flat within 2×SE"
  cat(sprintf("  %-20s  Δn = %+6.2f ± %.2f  [%s]\n",
              envl, dn, dn_se, direction))
}

saveRDS(list(runs = runs_df, summary = summary),
        "dev/audit/fidelity/red_queen_16seeds_results.rds")

# Plot
dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
plot_df <- summary
plot_df$env_label <- factor(plot_df$env,
                             levels = c("stable", "parasite_continuous",
                                        "parasite_discrete"),
                             labels = c("Stable", "Parasite (continuous)",
                                        "Parasite (discrete, 0.5.1)"))
p <- ggplot(plot_df,
            aes(env_label, n_mean, fill = label)) +
  geom_col(position = position_dodge(0.8), width = 0.7) +
  geom_errorbar(aes(ymin = n_mean - 2 * n_se,
                    ymax = n_mean + 2 * n_se),
                position = position_dodge(0.8), width = 0.25) +
  scale_fill_manual(values = c(haploid_asex = "#377eb8",
                                diploid_sex = "#e41a1c"),
                    name = NULL) +
  labs(title = "0.5.3 Red Queen firming-up: 16 seeds × 3 envs",
       subtitle = "Error bars = 2×SE. Sex > asex in parasite_discrete = canonical Hamilton 1980 Red Queen.",
       x = NULL, y = "mean n_agents (post-burn-in t > 150)") +
  theme_minimal(base_size = 11)
ggsave("dev/audit/fidelity/figs/red_queen_16seeds.png", p,
       width = 10, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/red_queen_16seeds.png\n")
