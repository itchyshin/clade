#!/usr/bin/env Rscript
# Fidelity audit: clutch size evolution (Lack 1947, Smith & Fretwell 1974).
# Prediction: evolved clutch size correlates with resource availability
#   (rich -> r-strategy = larger clutches; scarce -> K-strategy = smaller).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(grass_rate, seed, max_ticks = 600L) {
  s <- default_specs()
  s$clutch_size_evolution   <- TRUE
  s$clutch_size_init_mean   <- 3
  s$clutch_size_min         <- 1L
  s$clutch_size_max         <- 6L
  s$clutch_size_mutation_sd <- 0.3
  s$grass_rate              <- grass_rate
  s$n_agents_init           <- 100L
  s$grid_rows               <- 30L; s$grid_cols <- 30L
  s$max_agents              <- 500L
  s$max_ticks               <- as.integer(max_ticks)
  s$random_seed             <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$grass_rate <- grass_rate; d$seed <- seed
  d
}

seeds <- 1L:3L
grass_grid <- c(0.05, 0.10, 0.15, 0.20, 0.30, 0.40)
cat("── Clutch size × grass_rate sweep (3 seeds, 600 ticks)\n")
results <- lapply(grass_grid, function(gr) {
  finals <- vapply(seeds, function(sd) {
    d <- one_run(gr, sd)
    mean(d$mean_clutch_size[d$t > 200], na.rm = TRUE)
  }, numeric(1L))
  pops <- vapply(seeds, function(sd) {
    d <- one_run(gr, sd)
    mean(d$n_agents[d$t > 200])
  }, numeric(1L))
  cat(sprintf("  grass=%.2f: clutch=%.2f±%.2f  n=%.0f±%.0f\n",
              gr, mean(finals, na.rm=TRUE), sd(finals, na.rm=TRUE),
              mean(pops), sd(pops)))
  data.frame(grass_rate = gr,
             mean_clutch = mean(finals, na.rm=TRUE),
             sd_clutch   = sd(finals, na.rm=TRUE),
             mean_pop    = mean(pops))
})
df <- do.call(rbind, results)

# Spearman: grass_rate vs mean_clutch; prediction positive (richer -> larger)
rho <- suppressWarnings(cor(df$grass_rate, df$mean_clutch,
                             method = "spearman", use = "pairwise.complete"))
cat(sprintf("\nSpearman(grass_rate, mean_clutch) = %.2f (expect positive)\n", rho))

saveRDS(df, "dev/audit/fidelity/clutch_size_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p <- ggplot(df, aes(grass_rate, mean_clutch)) +
  geom_errorbar(aes(ymin = mean_clutch - sd_clutch,
                    ymax = mean_clutch + sd_clutch), width = 0.01) +
  geom_line(linewidth = 0.8, colour = "#2E7D32") +
  geom_point(size = 3, colour = "#2E7D32") +
  labs(title = "Clutch size evolution vs resource availability (Lack 1947)",
       subtitle = sprintf("3 seeds × 600 ticks. Spearman ρ = %.2f", rho),
       x = "grass_rate", y = "evolved mean_clutch_size (post-burn-in)") +
  theme_minimal(base_size = 12)
ggsave("dev/audit/fidelity/figs/clutch_size.png", p,
       width = 9, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/clutch_size.png\n")
