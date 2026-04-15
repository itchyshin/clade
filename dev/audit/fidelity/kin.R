#!/usr/bin/env Rscript
# Fidelity audit: Hamilton's rule / kin selection.
#
# Theory (Hamilton 1964):
#   Altruism is favoured by selection when r*B > C, where r is the
#   coefficient of relatedness, B is the benefit to recipient, and
#   C is the cost to the donor.
#
# IMPLEMENTATION CAVEAT: clade's kin module does not evolve a heritable
# altruism trait. It performs altruism *deterministically* when the
# gate conditions are met. So this audit tests whether the implemented
# module produces the predicted *population-level* consequences of
# Hamilton's rule — namely, altruism should increase population
# carrying capacity when rB > C, and not when rB < C.
#
# alifeR R prototype reference (alifeR/R/kinship.R):
#   Same logic as clade: pedigree-based r (0.5 parent-offspring,
#   0.25 siblings, 0 otherwise), Moore-neighbourhood scan, donor pays
#   cost, recipient gains benefit.
#
# MATLAB base reference: N/A — kin selection first appears in alifeR.
#
# Predictions to test:
#   P1. With rB > C (e.g. r_min=0.25, B=10, C=2 → rB=2.5 > 2):
#       kin-on > baseline in mean population under scarce resources.
#   P2. With rB < C (e.g. r_min=0.25, B=4, C=10 → rB=1 < 10):
#       kin-on ~= baseline OR kin-on < baseline.
#   P3. Altruistic acts (n_altruistic_acts) > 0 under rB > C regime;
#       scales down monotonically as r_min rises (fewer qualifying kin).
#   P4. Relatedness threshold r_min = 0.5 (parents only) should produce
#       fewer acts than r_min = 0.25 (siblings too) at fixed population.
#
# Usage: Rscript dev/audit/fidelity/kin.R
# Output:
#   dev/audit/fidelity/figs/kin.png
#   dev/audit/fidelity/kin_results.rds

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
  library(ggplot2)
  library(patchwork)
})

one_run <- function(kin_on, r_min, cost, benefit, seed,
                    grass_rate = 0.08, max_ticks = 400L) {
  s <- default_specs()
  s$kin_selection          <- kin_on
  s$kin_altruism_r_min     <- r_min
  s$kin_altruism_cost      <- cost
  s$kin_altruism_benefit   <- benefit
  s$kin_altruism_min_donor_energy <- 50
  s$grass_rate             <- grass_rate
  s$n_agents_init          <- 80L
  s$grid_rows              <- 30L
  s$grid_cols              <- 30L
  s$max_agents             <- 500L
  s$max_ticks              <- as.integer(max_ticks)
  s$random_seed            <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d
}

summarise_run <- function(d, burn = 100L) {
  d2 <- d[d$t > burn, ]
  list(
    mean_n   = mean(d2$n_agents),
    final_n  = tail(d2$n_agents, 1L),
    tot_acts = sum(d$n_altruistic_acts, na.rm = TRUE),
    mean_e   = mean(d2$mean_energy, na.rm = TRUE)
  )
}

seeds <- 1L:5L

# ── Step 1: kin-ON vs baseline at Hamilton-satisfying default (rB > C) ──────

cat("── Step 1: baseline vs kin-ON (r_min=0.25, B=10, C=2, rB=2.5>C)\n")
baseline <- lapply(seeds, function(sd) {
  r <- one_run(FALSE, 0.25, 2.0, 10.0, sd)
  s <- summarise_run(r); s$seed <- sd; s$cond <- "baseline"; r$cond <- "baseline"; r$seed <- sd
  list(summary = s, ticks = r)
})
kin_on <- lapply(seeds, function(sd) {
  r <- one_run(TRUE, 0.25, 2.0, 10.0, sd)
  s <- summarise_run(r); s$seed <- sd; s$cond <- "kin_rB_gt_C"; r$cond <- "kin_rB_gt_C"; r$seed <- sd
  list(summary = s, ticks = r)
})

s_base <- do.call(rbind, lapply(baseline, function(x) as.data.frame(x$summary)))
s_kin  <- do.call(rbind, lapply(kin_on,  function(x) as.data.frame(x$summary)))

cat(sprintf("  Baseline:       mean_n = %.1f ± %.1f, tot_acts = %.0f ± %.0f\n",
            mean(s_base$mean_n), sd(s_base$mean_n),
            mean(s_base$tot_acts), sd(s_base$tot_acts)))
cat(sprintf("  Kin ON (rB>C):  mean_n = %.1f ± %.1f, tot_acts = %.0f ± %.0f\n",
            mean(s_kin$mean_n), sd(s_kin$mean_n),
            mean(s_kin$tot_acts), sd(s_kin$tot_acts)))
p1_pass <- mean(s_kin$mean_n) > mean(s_base$mean_n)
cat(sprintf("  P1 (kin-on > baseline under rB>C): %s (delta = %+.1f)\n",
            if (p1_pass) "PASS" else "FAIL",
            mean(s_kin$mean_n) - mean(s_base$mean_n)))

# ── Step 2: Hamilton-violating regime (rB < C) ───────────────────────────────

cat("\n── Step 2: kin-ON with rB<C (r_min=0.25, B=4, C=10, rB=1<C)\n")
kin_violating <- lapply(seeds, function(sd) {
  r <- one_run(TRUE, 0.25, 10.0, 4.0, sd)
  s <- summarise_run(r); s$seed <- sd; s$cond <- "kin_rB_lt_C"; r$cond <- "kin_rB_lt_C"; r$seed <- sd
  list(summary = s, ticks = r)
})
s_viol <- do.call(rbind, lapply(kin_violating, function(x) as.data.frame(x$summary)))
cat(sprintf("  Kin ON (rB<C):  mean_n = %.1f ± %.1f, tot_acts = %.0f ± %.0f\n",
            mean(s_viol$mean_n), sd(s_viol$mean_n),
            mean(s_viol$tot_acts), sd(s_viol$tot_acts)))
p2_pass <- mean(s_viol$mean_n) <= mean(s_base$mean_n) * 1.02
cat(sprintf("  P2 (kin-on ~ baseline or worse when rB<C): %s (delta = %+.1f)\n",
            if (p2_pass) "PASS" else "FAIL",
            mean(s_viol$mean_n) - mean(s_base$mean_n)))

# ── Step 3: relatedness threshold sweep ──────────────────────────────────────

cat("\n── Step 3: r_min sweep (fixed B=10, C=2)\n")
rmin_grid <- c(0.0, 0.125, 0.25, 0.5)
rmin_results <- lapply(rmin_grid, function(r_min) {
  acts_and_n <- do.call(rbind, lapply(seeds, function(sd) {
    d <- one_run(TRUE, r_min, 2.0, 10.0, sd)
    data.frame(r_min = r_min, seed = sd,
               mean_n = mean(d$n_agents[d$t > 100]),
               tot_acts = sum(d$n_altruistic_acts, na.rm = TRUE))
  }))
  cat(sprintf("  r_min=%.3f: mean_n = %.1f ± %.1f, tot_acts = %.0f ± %.0f\n",
              r_min, mean(acts_and_n$mean_n), sd(acts_and_n$mean_n),
              mean(acts_and_n$tot_acts), sd(acts_and_n$tot_acts)))
  acts_and_n
})
rmin_df <- do.call(rbind, rmin_results)

# Theory: when r_min = 0, donor accepts any neighbour → many wasteful acts
#         when r_min = 0.5, only parents/offspring qualify → fewer acts
# Expectation: acts monotonically decrease with r_min
acts_by_rmin <- aggregate(tot_acts ~ r_min, rmin_df, mean)
monotone_acts <- all(diff(acts_by_rmin$tot_acts) <= 0)
cat(sprintf("  P3 (acts monotonically decrease with r_min): %s\n",
            if (monotone_acts) "PASS" else "FAIL"))

# ── Step 4: C × B grid — test the rB > C threshold more broadly ──────────────

cat("\n── Step 4: cost x benefit grid (3 seeds each, r_min=0.25)\n")
grid <- expand.grid(cost = c(2, 5, 10),
                    benefit = c(4, 10, 20),
                    KEEP.OUT.ATTRS = FALSE)
grid$rB_over_C <- 0.25 * grid$benefit / grid$cost
grid_results <- lapply(seq_len(nrow(grid)), function(i) {
  row <- grid[i, ]
  ns <- vapply(1L:3L, function(sd) {
    d <- one_run(TRUE, 0.25, row$cost, row$benefit, sd)
    mean(d$n_agents[d$t > 100])
  }, numeric(1L))
  cat(sprintf("  C=%2d B=%2d rB/C=%.2f: mean_n = %.1f ± %.1f\n",
              row$cost, row$benefit, row$rB_over_C,
              mean(ns), sd(ns)))
  data.frame(row, mean_n = mean(ns), sd_n = sd(ns))
})
grid_df <- do.call(rbind, grid_results)

# P4: mean_n should correlate with rB/C ratio
spear <- cor(grid_df$rB_over_C, grid_df$mean_n, method = "spearman")
cat(sprintf("  P4 (Spearman rB/C vs mean_n rho = %.2f): %s\n",
            spear, if (spear > 0.4) "PASS" else "WEAK"))

# ── Save results + figure ────────────────────────────────────────────────────

all_ticks <- do.call(rbind, c(
  lapply(baseline, `[[`, "ticks"),
  lapply(kin_on,   `[[`, "ticks"),
  lapply(kin_violating, `[[`, "ticks")
))

saveRDS(list(baseline = s_base, kin_on = s_kin, kin_violating = s_viol,
             rmin_df = rmin_df, grid_df = grid_df, all_ticks = all_ticks),
        "dev/audit/fidelity/kin_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
palette <- c(baseline = "#F44336",
             kin_rB_gt_C = "#2196F3",
             kin_rB_lt_C = "#9C27B0")

p_traj <- ggplot(all_ticks,
                 aes(t, n_agents, colour = cond, group = interaction(cond, seed))) +
  geom_line(alpha = 0.35, linewidth = 0.4) +
  stat_summary(aes(group = cond), fun = mean, geom = "line", linewidth = 1.1) +
  scale_colour_manual(values = palette, name = NULL) +
  labs(title = "Population under kin selection (5 seeds; bold=mean)",
       x = "Tick", y = "n_agents") +
  theme_minimal(base_size = 11)

p_rmin <- ggplot(rmin_df, aes(factor(r_min), tot_acts)) +
  geom_boxplot(fill = "#2196F3", alpha = 0.5) +
  labs(title = "Altruistic acts by r_min threshold",
       x = "kin_altruism_r_min", y = "total acts (400 ticks)") +
  theme_minimal(base_size = 11)

p_grid <- ggplot(grid_df, aes(factor(cost), factor(benefit), fill = mean_n)) +
  geom_tile() +
  geom_text(aes(label = sprintf("%.0f\nrB/C=%.1f", mean_n, rB_over_C)),
            size = 3, colour = "white") +
  scale_fill_viridis_c(name = "mean_n") +
  labs(title = "C x B grid (mean n_agents)",
       x = "cost (C)", y = "benefit (B)") +
  theme_minimal(base_size = 11)

p <- (p_traj | p_rmin) / p_grid +
  plot_annotation(
    title = "Kin selection fidelity audit: Hamilton's rule (rB > C)",
    subtitle = sprintf(
      "grass_rate=0.08, 80 agents init, 30x30 grid, 400 ticks. Default r_min=0.25."),
    theme = theme(plot.title = element_text(face = "bold"))
  )

ggsave("dev/audit/fidelity/figs/kin.png", p,
       width = 12, height = 8, dpi = 150)
cat("\nWrote dev/audit/fidelity/figs/kin.png\n")
