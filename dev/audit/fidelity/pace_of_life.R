#!/usr/bin/env Rscript
# Fidelity audit: pace-of-life syndromes (Réale et al. 2010).
# Prediction: higher metabolic rate → younger mean_age, more births,
#            more volatile population.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(rate, seed, max_ticks = 500L) {
  s <- default_specs()
  s$metabolic_rate_init_mean <- rate
  s$metabolic_rate_evolution <- FALSE
  s$n_agents_init   <- 100L
  s$grid_rows       <- 30L; s$grid_cols <- 30L
  s$grass_rate      <- 0.15
  s$max_agents      <- 400L
  s$max_ticks       <- as.integer(max_ticks)
  s$random_seed     <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$rate <- rate; d$seed <- seed
  d
}

rates <- c(0.5, 1.0, 1.5, 2.0, 3.0)
seeds <- 1L:3L
cat("── metabolic_rate sweep (3 seeds, 500 ticks)\n")
results <- lapply(rates, function(r) {
  stats <- vapply(seeds, function(sd) {
    d <- one_run(r, sd)
    d2 <- d[d$t > 200, ]
    c(mean_age    = mean(d2$mean_age, na.rm = TRUE),
      mean_n      = mean(d2$n_agents),
      mean_births = mean(d2$n_births),
      var_n       = var(d2$n_agents))
  }, numeric(4L))
  s_means <- rowMeans(stats)
  cat(sprintf("  rate=%.1f: age=%.1f  n=%.0f  births=%.2f  var=%.0f\n",
              r, s_means["mean_age"], s_means["mean_n"],
              s_means["mean_births"], s_means["var_n"]))
  data.frame(rate = r, t(s_means))
})
df <- do.call(rbind, results)

rho_age    <- cor(df$rate, df$mean_age,    method = "spearman")
rho_births <- cor(df$rate, df$mean_births, method = "spearman")
rho_var    <- cor(df$rate, df$var_n,       method = "spearman")
cat(sprintf("\nSpearman(rate, mean_age)    = %.2f (expect negative): %s\n",
            rho_age, if (rho_age < -0.5) "PASS" else "FAIL"))
cat(sprintf("Spearman(rate, mean_births) = %.2f (Réale gives either)\n",
            rho_births))
cat(sprintf("Spearman(rate, var_n)       = %.2f (expect positive)\n",
            rho_var))

saveRDS(df, "dev/audit/fidelity/pace_of_life_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p1 <- ggplot(df, aes(rate, mean_age)) +
  geom_line(linewidth = 0.8, colour = "#377eb8") +
  geom_point(size = 3, colour = "#377eb8") +
  labs(title = "Slow-fast: mean age",
       x = "metabolic_rate", y = "mean_age") + theme_minimal()
p2 <- ggplot(df, aes(rate, mean_births)) +
  geom_line(linewidth = 0.8, colour = "#e41a1c") +
  geom_point(size = 3, colour = "#e41a1c") +
  labs(title = "Slow-fast: births per tick",
       x = "metabolic_rate", y = "mean_births") + theme_minimal()
p3 <- ggplot(df, aes(rate, var_n)) +
  geom_line(linewidth = 0.8, colour = "#4daf4a") +
  geom_point(size = 3, colour = "#4daf4a") +
  labs(title = "Population volatility",
       x = "metabolic_rate", y = "var(n_agents)") + theme_minimal()

p <- p1 | p2 | p3
p <- p + plot_annotation(
  title = "Pace-of-life audit (Réale et al. 2010)",
  subtitle = sprintf("3 seeds × 500 ticks. ρ(rate,age)=%.2f, ρ(rate,var)=%.2f",
                     rho_age, rho_var),
  theme = theme(plot.title = element_text(face = "bold")))
ggsave("dev/audit/fidelity/figs/pace_of_life.png", p,
       width = 12, height = 4, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/pace_of_life.png\n")
