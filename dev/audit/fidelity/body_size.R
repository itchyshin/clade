#!/usr/bin/env Rscript
# Fidelity audit: body size evolution (Cope's rule, Shine et al. 2011).
# Predictions:
#   P1. With body_size_evolution=TRUE, mean_body_size drifts above 1.0
#       under general foraging selection (Cope's rule).
#   P2. Predation accelerates upward drift (predator-mediated size
#       selection for larger, harder-to-catch bodies).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(n_pred, seed, max_ticks = 600L) {
  s <- default_specs()
  s$body_size_evolution <- TRUE
  s$body_size_init_mean <- 1.0
  s$body_size_mutation_sd <- 0.08
  s$n_agents_init       <- 100L
  s$grid_rows           <- 30L; s$grid_cols <- 30L
  s$n_predators_init    <- as.integer(n_pred)
  s$predator_max_agents <- max(10L, as.integer(n_pred * 3L))
  s$grass_rate          <- 0.15
  s$max_agents          <- 500L
  s$max_ticks           <- as.integer(max_ticks)
  s$random_seed         <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$n_pred <- n_pred; d$seed <- seed
  d
}

seeds <- 1L:5L
cat("── Step 1: body_size evolution (5 seeds, 600 ticks)\n")
no_pred <- lapply(seeds, function(sd) {
  cat(sprintf("  no_pred seed %d\n", sd))
  one_run(0, sd)
})
with_pred <- lapply(seeds, function(sd) {
  cat(sprintf("  w_pred  seed %d\n", sd))
  one_run(10, sd)
})

fin_bs <- function(runs) {
  vapply(runs, function(d) tail(d$mean_body_size, 1L), numeric(1L))
}
delta_bs <- function(runs) {
  vapply(runs, function(d) tail(d$mean_body_size, 1L) - d$mean_body_size[1],
         numeric(1L))
}

nop_final <- fin_bs(no_pred); wp_final <- fin_bs(with_pred)
nop_delta <- delta_bs(no_pred); wp_delta <- delta_bs(with_pred)
cat(sprintf("\nNo predators:  final body=%.3f±%.3f  Δ=%.3f±%.3f\n",
            mean(nop_final), sd(nop_final),
            mean(nop_delta), sd(nop_delta)))
cat(sprintf("10 predators:  final body=%.3f±%.3f  Δ=%.3f±%.3f\n",
            mean(wp_final), sd(wp_final),
            mean(wp_delta), sd(wp_delta)))
p1_pass <- mean(nop_delta) > 0.01
p2_pass <- mean(wp_delta) > mean(nop_delta)
cat(sprintf("P1 (body size drifts up with evolution on): %s\n",
            if (p1_pass) "PASS" else "FAIL"))
cat(sprintf("P2 (predation accelerates drift): %s (Δratio=%.2f)\n",
            if (p2_pass) "PASS" else "FAIL",
            mean(wp_delta) / max(abs(mean(nop_delta)), 1e-3)))

all_ticks <- do.call(rbind, c(no_pred, with_pred))
all_ticks$cond <- ifelse(all_ticks$n_pred == 0, "no_pred", "10_pred")
saveRDS(all_ticks, "dev/audit/fidelity/body_size_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p <- ggplot(all_ticks, aes(t, mean_body_size, colour = cond,
                           group = interaction(cond, seed))) +
  geom_line(alpha = 0.4, linewidth = 0.4) +
  stat_summary(aes(group = cond), fun = mean, geom = "line",
               linewidth = 1.1) +
  geom_hline(yintercept = 1.0, linetype = "dashed", colour = "grey50") +
  scale_colour_manual(values = c(no_pred = "#4CAF50", `10_pred` = "#E91E63"),
                      name = NULL) +
  labs(title = "Body size evolution: predator-accelerated directional selection",
       subtitle = sprintf("5 seeds × 600 ticks. no_pred Δ=%.3f, pred Δ=%.3f",
                          mean(nop_delta), mean(wp_delta)),
       x = "Tick", y = "mean_body_size") +
  theme_minimal(base_size = 12)
ggsave("dev/audit/fidelity/figs/body_size.png", p,
       width = 9, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/body_size.png\n")
