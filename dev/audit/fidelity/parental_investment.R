#!/usr/bin/env Rscript
# Fidelity audit: parental investment (Trivers 1972).
# Prediction: higher female_investment shifts quality-quantity balance:
#   - fewer births
#   - higher per-offspring quality (energy) / survival

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(fi, seed, max_ticks = 500L) {
  s <- default_specs()
  s$parental_care                 <- TRUE
  s$parental_investment_evolution <- TRUE
  s$female_investment             <- fi
  s$male_repro_cost               <- 0.3
  s$feeding_rate                  <- 10
  s$n_agents_init                 <- 100L
  s$grid_rows                     <- 30L; s$grid_cols <- 30L
  s$grass_rate                    <- 0.15
  s$max_agents                    <- 400L
  s$max_ticks                     <- as.integer(max_ticks)
  s$random_seed                   <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$fi <- fi; d$seed <- seed
  d
}

seeds <- 1L:3L
fi_grid <- c(0.3, 0.5, 0.7, 0.9)
cat("── Female investment sweep (3 seeds, 500 ticks)\n")
results <- lapply(fi_grid, function(fi) {
  stats <- vapply(seeds, function(sd) {
    d <- one_run(fi, sd)
    d2 <- d[d$t > 200, ]
    c(mean_births  = mean(d2$n_births, na.rm = TRUE),
      mean_juv     = mean(d2$n_juveniles, na.rm = TRUE),
      mean_n       = mean(d2$n_agents),
      mean_energy  = mean(d2$mean_energy, na.rm = TRUE))
  }, numeric(4L))
  s_means <- rowMeans(stats)
  cat(sprintf("  fi=%.1f: births=%.2f  juv=%.1f  n=%.0f  energy=%.1f\n",
              fi, s_means["mean_births"], s_means["mean_juv"],
              s_means["mean_n"], s_means["mean_energy"]))
  data.frame(fi = fi, t(s_means))
})
df <- do.call(rbind, results)

# Predictions (0.4.0 Tier 3):
#   P1. Higher fi -> larger offspring -> longer-graduating juveniles
#       -> mean n_juveniles DROPS (Trivers' quality-quantity).
#   P2. Higher fi -> higher mean_energy because offspring graduate
#       better-provisioned and contribute more to the adult pool.
rho_juv <- suppressWarnings(cor(df$fi, df$mean_juv, method = "spearman"))
cat(sprintf("\nP1 Spearman(fi, mean_juveniles) = %.2f (Trivers: negative): %s\n",
            rho_juv, if (rho_juv < -0.5) "PASS" else "WEAK"))
rho_energy <- suppressWarnings(cor(df$fi, df$mean_energy, method = "spearman"))
cat(sprintf("P2 Spearman(fi, mean_energy) = %.2f (positive expected)\n",
            rho_energy))
rho_births <- suppressWarnings(cor(df$fi, df$mean_births, method = "spearman"))
cat(sprintf("P3 Spearman(fi, mean_births) = %.2f (Trivers allows either)\n",
            rho_births))

saveRDS(df, "dev/audit/fidelity/parental_investment_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p1 <- ggplot(df, aes(fi, mean_births)) +
  geom_line(linewidth = 0.8, colour = "#e41a1c") +
  geom_point(size = 3, colour = "#e41a1c") +
  labs(title = "Births per tick vs female_investment",
       x = "female_investment", y = "mean n_births (post-burn)") +
  theme_minimal(base_size = 11)
p2 <- ggplot(df, aes(fi, mean_juv)) +
  geom_line(linewidth = 0.8, colour = "#377eb8") +
  geom_point(size = 3, colour = "#377eb8") +
  labs(title = "Mean juveniles present",
       x = "female_investment", y = "mean n_juveniles") +
  theme_minimal(base_size = 11)
p3 <- ggplot(df, aes(fi, mean_energy)) +
  geom_line(linewidth = 0.8, colour = "#4daf4a") +
  geom_point(size = 3, colour = "#4daf4a") +
  labs(title = "Mean energy",
       x = "female_investment", y = "mean_energy") +
  theme_minimal(base_size = 11)

p <- (p1 | p2) / p3 +
  plot_annotation(title = "Parental investment (Trivers 1972): quality-quantity trade-off",
                  subtitle = sprintf("3 seeds × 500 ticks. ρ(fi, births) = %.2f",
                                     rho_births),
                  theme = theme(plot.title = element_text(face = "bold")))
ggsave("dev/audit/fidelity/figs/parental_investment.png", p,
       width = 10, height = 7, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/parental_investment.png\n")
