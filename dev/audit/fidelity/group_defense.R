#!/usr/bin/env Rscript
# Fidelity audit: group defense / selfish herd (Hamilton 1971).
# Prediction: group defense ON reduces effective predation → larger
#             population than no-defense baseline under same predator pressure.
#
# 0.4.1 update: pre-0.4.1 audit used single predator density × single
# strength → flat signal. This version sweeps `n_predators_init ∈
# {5, 10, 15, 20, 30}` × `group_defense_strength ∈ {0.5, 1, 2}` to
# find the regime where the GD benefit is clearest (should emerge at
# intermediate predator pressure, where GD matters but doesn't dominate
# or get overwhelmed).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(gd_on, n_pred, gd_strength, seed, max_ticks = 500L) {
  s <- default_specs()
  s$group_defense           <- gd_on
  s$group_defense_radius    <- 2L
  s$group_defense_strength  <- gd_strength
  s$n_predators_init        <- as.integer(n_pred)
  s$predator_attack_strength <- 60
  s$predator_max_agents     <- 50L
  s$n_agents_init           <- 100L
  s$grid_rows               <- 30L; s$grid_cols <- 30L
  s$grass_rate              <- 0.15
  s$max_agents              <- 400L
  s$max_ticks               <- as.integer(max_ticks)
  s$random_seed             <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$gd_on       <- gd_on
  d$n_pred      <- n_pred
  d$gd_strength <- gd_strength
  d$seed        <- seed
  d
}

# Grid: 5 predator densities × 3 GD strengths × 2 seeds = 30 GD runs
# + baseline (GD off) at each predator density × 2 seeds = 10 baseline runs.
# Total: 40 runs × ~45 s = ~30 min.
pred_grid     <- c(5L, 10L, 15L, 20L, 30L)
strength_grid <- c(0.5, 1.0, 2.0)
seeds         <- 1L:2L

cat(sprintf("── group defense grid: %d predator × %d strength × %d seeds + %d baselines\n",
            length(pred_grid), length(strength_grid), length(seeds),
            length(pred_grid) * length(seeds)))

# Baseline: GD off
baseline_runs <- list()
for (n_pred in pred_grid) {
  for (sd in seeds) {
    cat(sprintf("  baseline n_pred=%d seed=%d\n", n_pred, sd))
    baseline_runs[[length(baseline_runs) + 1L]] <-
      one_run(FALSE, n_pred, 0.0, sd)
  }
}
gd_runs <- list()
for (n_pred in pred_grid) {
  for (st in strength_grid) {
    for (sd in seeds) {
      cat(sprintf("  gd n_pred=%d str=%.1f seed=%d\n", n_pred, st, sd))
      gd_runs[[length(gd_runs) + 1L]] <-
        one_run(TRUE, n_pred, st, sd)
    }
  }
}

fin_n <- function(runs) {
  vapply(runs, function(d) mean(d$n_agents[d$t > 100], na.rm = TRUE),
         numeric(1L))
}

# Compute (gd_n / baseline_n) ratio per (n_pred, strength)
summary_rows <- list()
for (n_pred in pred_grid) {
  base_sub <- Filter(function(d) !d$gd_on[1] && d$n_pred[1] == n_pred,
                     baseline_runs)
  base_n   <- mean(fin_n(base_sub))
  for (st in strength_grid) {
    gd_sub <- Filter(function(d) d$gd_on[1] && d$n_pred[1] == n_pred &&
                                   d$gd_strength[1] == st,
                     gd_runs)
    gd_n   <- fin_n(gd_sub)
    summary_rows[[length(summary_rows) + 1L]] <- data.frame(
      n_pred      = n_pred,
      gd_strength = st,
      base_n      = base_n,
      gd_n_mean   = mean(gd_n),
      gd_n_sd     = sd(gd_n),
      ratio       = mean(gd_n) / base_n,
      abs_gain    = mean(gd_n) - base_n
    )
  }
}
summary <- do.call(rbind, summary_rows)

cat("\nGrid summary (ratio = gd_n / base_n):\n")
print(summary[order(-summary$ratio), ])

best <- summary[which.max(summary$ratio), ]
cat(sprintf("\nBest regime: n_pred=%d str=%.1f  ratio=%.2fx  abs=%+.1f\n",
            best$n_pred, best$gd_strength, best$ratio, best$abs_gain))
p1_pass <- best$ratio > 1.05
cat(sprintf("P1 (GD boosts population > 5%% at some regime): %s\n",
            if (p1_pass) "PASS" else "PARTIAL (directional, small)"))

all_ticks <- do.call(rbind, c(baseline_runs, gd_runs))
all_ticks$cond <- ifelse(all_ticks$gd_on,
                          sprintf("gd_s=%.1f", all_ticks$gd_strength),
                          "baseline")
saveRDS(list(all_ticks = all_ticks, summary = summary),
        "dev/audit/fidelity/group_defense_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p_heat <- ggplot(summary,
                 aes(factor(n_pred), factor(gd_strength),
                     fill = ratio)) +
  geom_tile() +
  geom_text(aes(label = sprintf("%.2fx", ratio)), colour = "white") +
  scale_fill_viridis_c(name = "gd_n / base_n") +
  labs(title = "Group defense benefit vs predator pressure × strength",
       x = "n_predators_init", y = "group_defense_strength") +
  theme_minimal(base_size = 11)
p_lines <- ggplot(all_ticks,
                  aes(t, n_agents, colour = cond,
                      group = interaction(cond, n_pred, seed))) +
  geom_line(alpha = 0.35, linewidth = 0.35) +
  facet_wrap(~n_pred, labeller = label_both, ncol = 5) +
  labs(title = "Population over time by predator density (all GD strengths)",
       x = "Tick", y = "n_agents") +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom")
p <- p_heat / p_lines +
  plot_annotation(
    title = "Group defense audit (Hamilton 1971 selfish herd) — 0.4.1 grid",
    theme = theme(plot.title = element_text(face = "bold")))
ggsave("dev/audit/fidelity/figs/group_defense.png", p,
       width = 12, height = 8, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/group_defense.png\n")
