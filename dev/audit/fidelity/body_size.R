#!/usr/bin/env Rscript
# Fidelity audit: body size evolution.
# Predictions:
#   P1. With body_size_evolution=TRUE, mean_body_size drifts above 1.0
#       under general foraging selection (Cope's rule).
#   P2. Predation has a size-dependent effect. The pre-0.4.2 audit
#       (binary predator sensing) showed predation SLOWS the drift
#       (Brooks & Dodson 1965 size-efficiency hypothesis —
#       larger prey are more detectable). The 0.4.3 regression with
#       0.4.2's graded predator sensing showed direction seed-noise-
#       sensitive. 0.5.2 resolves P2 direction via 16-seed sweep
#       under BOTH graded and binary predator sensing.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(n_pred, graded, seed, max_ticks = 600L) {
  s <- default_specs()
  s$body_size_evolution   <- TRUE
  s$body_size_init_mean   <- 1.0
  s$body_size_mutation_sd <- 0.08
  s$n_agents_init         <- 100L
  s$grid_rows             <- 30L; s$grid_cols <- 30L
  s$n_predators_init      <- as.integer(n_pred)
  s$predator_max_agents   <- max(10L, as.integer(n_pred * 3L))
  s$predator_sense_graded <- graded   # 0.4.2: graded (default TRUE)
  s$grass_rate            <- 0.15
  s$max_agents            <- 500L
  s$max_ticks             <- as.integer(max_ticks)
  s$random_seed           <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$n_pred <- n_pred; d$graded <- graded; d$seed <- seed
  d
}

# 16-seed sweep across 2 predator levels × 2 sensing modes = 64 runs.
# ~30-45 min wall time.
seeds <- 1L:16L

cat("── 0.5.2 body-size P2 resolution: 16 seeds × 2 pred × 2 sensing\n")

runs <- list()
for (graded in c(FALSE, TRUE)) {
  for (n_pred in c(0L, 10L)) {
    for (sd in seeds) {
      cat(sprintf("  graded=%s n_pred=%2d seed=%2d\n", graded, n_pred, sd))
      runs[[length(runs) + 1L]] <- one_run(n_pred, graded, sd)
    }
  }
}

# Summarise per (graded, n_pred) cell.
summary_rows <- list()
for (graded in c(FALSE, TRUE)) {
  for (n_pred in c(0L, 10L)) {
    sub <- Filter(function(d) d$graded[1] == graded &&
                               d$n_pred[1] == n_pred, runs)
    deltas <- vapply(sub,
                     function(d) tail(d$mean_body_size, 1L) -
                                  d$mean_body_size[1],
                     numeric(1L))
    summary_rows[[length(summary_rows) + 1L]] <- data.frame(
      graded     = graded,
      n_pred     = n_pred,
      delta_mean = mean(deltas),
      delta_sd   = sd(deltas),
      delta_se   = sd(deltas) / sqrt(length(deltas)),
      n_seeds    = length(deltas)
    )
  }
}
summary <- do.call(rbind, summary_rows)

cat("\nCell summary (16 seeds each):\n")
print(summary)

# P1: upward drift in no-pred condition, both sensing modes
cat("\nP1 (Cope direction, upward drift without predators):\n")
for (graded in c(FALSE, TRUE)) {
  row <- summary[summary$graded == graded & summary$n_pred == 0, ]
  cat(sprintf("  graded=%s: Δ = %+.4f ± %.4f  %s\n",
              graded, row$delta_mean, row$delta_se,
              if (row$delta_mean > 0.01) "PASS" else "FAIL"))
}

# P2: predation direction under each sensing mode. Test whether the
# predator delta - no-pred delta is robustly nonzero (2 × SE criterion).
cat("\nP2 (predation effect, with 2×SE precision):\n")
for (graded in c(FALSE, TRUE)) {
  nop <- summary[summary$graded == graded & summary$n_pred == 0, ]
  wp  <- summary[summary$graded == graded & summary$n_pred == 10, ]
  diff    <- wp$delta_mean - nop$delta_mean
  diff_se <- sqrt(wp$delta_se^2 + nop$delta_se^2)
  direction <- if (diff > 2 * diff_se) "accelerates (Shine)" else
               if (diff < -2 * diff_se) "slows (Brooks-Dodson detectability)" else
               "flat within 2×SE"
  cat(sprintf("  graded=%s: Δ(wp)-Δ(nop) = %+.4f ± %.4f  [%s]\n",
              graded, diff, diff_se, direction))
}

saveRDS(list(runs = runs, summary = summary),
        "dev/audit/fidelity/body_size_results.rds")

# Plots
dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
all_ticks <- do.call(rbind, runs)
all_ticks$cond <- sprintf("graded=%s, n_pred=%d",
                           all_ticks$graded, all_ticks$n_pred)
p_bars <- ggplot(summary,
                 aes(factor(n_pred), delta_mean,
                     fill = factor(n_pred))) +
  geom_col() +
  geom_errorbar(aes(ymin = delta_mean - delta_se,
                    ymax = delta_mean + delta_se),
                width = 0.25) +
  facet_wrap(~graded, labeller = label_both) +
  scale_fill_manual(values = c("0" = "#4CAF50", "10" = "#E91E63"),
                    guide = "none") +
  labs(title = "Body-size Δ (final - init) under graded vs binary predator sensing",
       subtitle = "16 seeds, 600 ticks each; bars = 1 SE",
       x = "n_predators", y = "Δ mean_body_size") +
  theme_minimal(base_size = 11)

p_traj <- ggplot(all_ticks, aes(t, mean_body_size,
                                 colour = factor(n_pred),
                                 group = interaction(graded, n_pred, seed))) +
  geom_line(alpha = 0.25, linewidth = 0.3) +
  stat_summary(aes(group = factor(n_pred)), fun = mean, geom = "line",
               linewidth = 1.0) +
  facet_wrap(~graded, labeller = label_both) +
  geom_hline(yintercept = 1.0, linetype = "dashed", colour = "grey50") +
  scale_colour_manual(values = c("0" = "#4CAF50", "10" = "#E91E63"),
                      name = "n_predators") +
  labs(title = "Body-size trajectories (16 seeds per cell)",
       x = "Tick", y = "mean_body_size") +
  theme_minimal(base_size = 11)

p <- p_bars / p_traj +
  plot_annotation(title = "s-body-size 0.5.2: 16-seed P2 direction resolution",
                  theme = theme(plot.title = element_text(face = "bold")))
ggsave("dev/audit/fidelity/figs/body_size.png", p,
       width = 11, height = 8, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/body_size.png\n")
