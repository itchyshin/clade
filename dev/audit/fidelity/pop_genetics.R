#!/usr/bin/env Rscript
# Fidelity audit: population genetics / heritability
# (Fisher-Wright; Falconer & Mackay 1996).
# Prediction: heritable traits show high lag-1 autocorrelation in
#            mean trait trajectory (proxy for h²).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(seed, max_ticks = 500L) {
  s <- default_specs()
  s$body_size_evolution <- TRUE
  s$n_agents_init       <- 100L
  s$grid_rows           <- 30L; s$grid_cols <- 30L
  s$grass_rate          <- 0.15
  s$max_agents          <- 500L
  s$max_ticks           <- as.integer(max_ticks)
  s$random_seed         <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$seed <- seed
  d
}

seeds <- 1L:3L
cat("── heritability proxy on body_size (3 seeds, 500 ticks)\n")
runs <- lapply(seeds, function(sd) {
  cat(sprintf("  seed %d\n", sd))
  one_run(sd)
})

# Compute lag-1 autocorrelation of mean_body_size per seed, after burn-in
h2_proxies <- vapply(runs, function(d) {
  x <- d$mean_body_size[d$t > 100]
  if (length(x) < 20) return(NA_real_)
  ac <- stats::acf(x, lag.max = 1L, plot = FALSE)
  ac$acf[2L]
}, numeric(1L))
cat(sprintf("\nLag-1 autocorrelation (h² proxy): %.3f ± %.3f across %d seeds\n",
            mean(h2_proxies), sd(h2_proxies), length(h2_proxies)))
p1_pass <- mean(h2_proxies) > 0.5
cat(sprintf("P1 (h² proxy > 0.5, strong heritability): %s\n",
            if (p1_pass) "PASS" else "FAIL"))

# Also report mean trait drift
deltas <- vapply(runs, function(d) {
  tail(d$mean_body_size, 1L) - d$mean_body_size[1]
}, numeric(1L))
cat(sprintf("Mean body_size drift over 500 ticks: %.3f ± %.3f\n",
            mean(deltas), sd(deltas)))

all_ticks <- do.call(rbind, runs)
saveRDS(list(all_ticks = all_ticks, h2_proxies = h2_proxies),
        "dev/audit/fidelity/pop_genetics_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p <- ggplot(all_ticks, aes(t, mean_body_size, group = seed)) +
  geom_line(colour = "#9C27B0", alpha = 0.4, linewidth = 0.4) +
  stat_summary(aes(group = 1), fun = mean, geom = "line",
               colour = "#9C27B0", linewidth = 1.1) +
  labs(title = "Body size evolution (heritability proxy)",
       subtitle = sprintf("3 seeds × 500 ticks. Lag-1 ac = %.3f, drift = %+.3f",
                          mean(h2_proxies), mean(deltas)),
       x = "Tick", y = "mean_body_size") +
  theme_minimal(base_size = 12)
ggsave("dev/audit/fidelity/figs/pop_genetics.png", p,
       width = 9, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/pop_genetics.png\n")
