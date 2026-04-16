#!/usr/bin/env Rscript
# Fidelity audit: mimicry & toxicity (Müllerian aposematism mostly).
#
# Theory (Bates 1862, Müller 1879, Endler 1988, Ruxton et al. 2004):
#   Müllerian: multiple unpalatable species converge on a common
#     warning signal so naive predators only need to learn once;
#     all signal-sharing toxic prey benefit from shared educational
#     cost.
#   Batesian: a palatable species evolves to resemble a toxic model.
#     Mimic must be rarer than model or predators learn the signal
#     is sometimes safe and avoidance breaks down.
#   Both require: predators learn signal-specific avoidance after
#     attacking toxic prey, and the toxin cost must be less than the
#     survival benefit (Zahavi 1975 honest handicap).
#
# alifeR R prototype reference (alifeR/R/mimicry.R):
#   - Multi-dimensional signal vectors per agent (signal_dims).
#   - Predator memory is a vector; R-W update toward prey.signal.
#   - Avoidance fires when dot(memory, prey_signal) > avoid_threshold.
#   - Signal-specific: predator can avoid mimics sharing toxic
#     models' signals (Batesian) or generalise across multiple toxic
#     species sharing one signal (Müllerian).
#
# clade Julia kernel divergence (inst/julia/src/modules/mimicry.jl):
#   - Predator memory is a SCALAR (pred.value_estimate), updated
#     toward prey.toxicity (NOT toward prey.signal).
#   - Avoidance fires when value_estimate >= avoid_threshold AND
#     prey.toxicity > 0 (Müllerian) or just learned (Batesian).
#   - This is a TOXICITY-LEVEL avoidance, not a SIGNAL-SPECIFIC one.
#     Predator effectively learns "recently I've been encountering
#     toxic prey, so I'll avoid attacking until that fades."
#   - Practical consequence: clade's mimicry is best understood as
#     general aversion learning, not the textbook Bates/Müller signal
#     model. We test the predictions that ARE testable in this
#     simplified semantics; we flag what cannot be tested without a
#     signal-vector kernel change.
#
# MATLAB base reference: N/A — mimicry first appears in alifeR.
#
# Predictions tested here (within clade's scalar-memory semantics):
#   P1. Without predators, mean toxicity drifts DOWN or stays flat
#       (pure cost; selection purges the trait).
#   P2. With predators + sufficient toxin_dose vs cost ratio, mean
#       toxicity rises above the predator-free control by end of run.
#   P3. n_toxic_attacks > 0 (predators DO attack toxic prey at first)
#       AND n_avoided_attacks > 0 by end of run (avoidance learning
#       activates).
#   P4. Effect size on mean_toxicity scales with toxin_dose (sign
#       check: higher dose → larger upward shift).
#
# Usage: Rscript dev/audit/fidelity/mimicry.R
# Output:
#   dev/audit/fidelity/figs/mimicry.png
#   dev/audit/fidelity/mimicry_grid.rds
#   dev/audit/fidelity/mimicry_results.rds

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
  library(ggplot2)
  library(patchwork)
})

one_run <- function(n_predators, toxin_dose, toxicity_cost, seed,
                    toxicity_init = 0.3, max_ticks = 600L) {
  s <- default_specs()
  s$mimicry                <- TRUE
  s$toxicity_init_mean     <- toxicity_init
  s$toxin_dose             <- toxin_dose
  s$toxicity_cost_per_tick <- toxicity_cost
  # 0.4.0 Tier 4: enable signal vectors so vector predator memory activates.
  s$signal_dims            <- 3L
  s$signal_evolution_drift <- TRUE
  s$signal_drift_sd        <- 0.05
  s$signal_memory_rate     <- 0.5
  s$avoid_threshold        <- 0.1   # lower threshold so avoidance fires
  s$n_predators_init       <- as.integer(n_predators)
  s$predator_attack_strength <- 60
  s$predator_min_repro_energy <- 50
  s$predator_max_agents    <- 50L
  s$n_agents_init          <- 100L
  s$grid_rows              <- 30L
  s$grid_cols              <- 30L
  s$grass_rate             <- 0.20
  s$max_ticks              <- as.integer(max_ticks)
  s$random_seed            <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d
}

# ── Step 1: predator-free control vs predator-present treatment ──────────────

cat("── Step 1: control (no predators) vs treatment (8 predators)\n")
seeds <- 1L:5L
runs_control <- lapply(seeds, function(sd) {
  cat(sprintf("  control seed %d\n", sd))
  d <- one_run(n_predators = 0, toxin_dose = 30,
               toxicity_cost = 0.5, seed = sd)
  d$cond <- "no_predators"
  d$seed <- sd
  d
})
runs_treat <- lapply(seeds, function(sd) {
  cat(sprintf("  treatment seed %d\n", sd))
  d <- one_run(n_predators = 8, toxin_dose = 30,
               toxicity_cost = 0.5, seed = sd)
  d$cond <- "with_predators"
  d$seed <- sd
  d
})
all_ticks <- do.call(rbind, c(runs_control, runs_treat))

# Final mean toxicity per run
fin <- function(runs) {
  vapply(runs, function(d) tail(d$mean_toxicity, 1L), numeric(1L))
}
ctrl_final <- fin(runs_control)
trt_final  <- fin(runs_treat)
cat(sprintf("\nFinal mean_toxicity (mean ± sd across %d seeds):\n",
            length(seeds)))
cat(sprintf("  control (no predators):  %.3f ± %.3f\n",
            mean(ctrl_final), sd(ctrl_final)))
cat(sprintf("  treatment (8 predators): %.3f ± %.3f\n",
            mean(trt_final),  sd(trt_final)))
cat(sprintf("  P1 (control drifts down/flat): %s\n",
            if (mean(ctrl_final) <= 0.30) "PASS" else "FAIL"))
cat(sprintf("  P2 (treatment > control):       %s\n",
            if (mean(trt_final) > mean(ctrl_final)) "PASS" else "FAIL"))

# Avoidance / toxic attack counts
trt_avoid <- vapply(runs_treat,
                    function(d) tail(d$n_avoided_attacks, 1L),
                    numeric(1L))
trt_toxic <- vapply(runs_treat,
                    function(d) tail(d$n_toxic_attacks, 1L),
                    numeric(1L))
cat(sprintf("  Treatment n_avoided_attacks (final): %.0f ± %.0f\n",
            mean(trt_avoid), sd(trt_avoid)))
cat(sprintf("  Treatment n_toxic_attacks   (final): %.0f ± %.0f\n",
            mean(trt_toxic), sd(trt_toxic)))
cat(sprintf("  P3 (predators attack toxic AND learn to avoid): %s\n",
            if (mean(trt_toxic) > 0 && mean(trt_avoid) > 0) "PASS" else "FAIL"))

# ── Step 2: dose-response — does toxin_dose matter? ──────────────────────────

cat("\n── Step 2: dose-response across toxin_dose\n")
dose_grid <- c(10, 30, 60, 100)
dose_results <- lapply(dose_grid, function(td) {
  finals <- vapply(seeds, function(sd) {
    d <- one_run(n_predators = 8, toxin_dose = td,
                 toxicity_cost = 0.5, seed = sd)
    tail(d$mean_toxicity, 1L)
  }, numeric(1L))
  cat(sprintf("  toxin_dose=%3.0f: final mean_toxicity = %.3f ± %.3f\n",
              td, mean(finals), sd(finals)))
  data.frame(toxin_dose = td,
             mean_final_toxicity = mean(finals),
             sd_final_toxicity   = sd(finals))
})
dose_df <- do.call(rbind, dose_results)

slope <- cor(dose_df$toxin_dose, dose_df$mean_final_toxicity,
             method = "spearman")
cat(sprintf("  P4 (Spearman dose vs toxicity rho = %.2f): %s\n",
            slope, if (slope > 0) "PASS" else "FAIL"))

# ── Step 3: cost-benefit grid (Zahavi handicap honesty) ──────────────────────

cat("\n── Step 3: toxin_dose x toxicity_cost grid\n")
grid <- expand.grid(toxin_dose = c(10, 30, 60),
                    toxicity_cost = c(0.2, 0.5, 1.0, 2.0),
                    KEEP.OUT.ATTRS = FALSE)
t0 <- Sys.time()
grid_results <- lapply(seq_len(nrow(grid)), function(i) {
  row <- grid[i, ]
  finals <- vapply(1L:3L, function(sd) {
    d <- one_run(n_predators = 8,
                 toxin_dose = row$toxin_dose,
                 toxicity_cost = row$toxicity_cost,
                 seed = sd)
    tail(d$mean_toxicity, 1L)
  }, numeric(1L))
  cat(sprintf("  dose=%3.0f cost=%.1f -> %.3f ± %.3f\n",
              row$toxin_dose, row$toxicity_cost,
              mean(finals), sd(finals)))
  data.frame(row,
             mean_final_toxicity = mean(finals),
             sd_final_toxicity   = sd(finals))
})
grid_df <- do.call(rbind, grid_results)
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
cat(sprintf("Grid done in %.1f min.\n", elapsed))

saveRDS(list(all_ticks = all_ticks, dose_df = dose_df,
             grid_df = grid_df,
             ctrl_final = ctrl_final, trt_final = trt_final,
             trt_avoid = trt_avoid, trt_toxic = trt_toxic),
        "dev/audit/fidelity/mimicry_results.rds")

# ── Figure ──────────────────────────────────────────────────────────────────

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)

palette <- c(no_predators = "#2196F3", with_predators = "#F44336")

p_traj <- ggplot(all_ticks,
                 aes(t, mean_toxicity, colour = cond,
                     group = interaction(cond, seed))) +
  geom_line(alpha = 0.4, linewidth = 0.4) +
  stat_summary(aes(group = cond), fun = mean,
               geom = "line", linewidth = 1.2) +
  scale_colour_manual(values = palette, name = NULL) +
  labs(title = "Toxicity trajectory (5 seeds; bold = mean)",
       x = "Tick", y = "mean_toxicity") +
  theme_minimal(base_size = 11)

p_dose <- ggplot(dose_df, aes(toxin_dose, mean_final_toxicity)) +
  geom_errorbar(aes(ymin = mean_final_toxicity - sd_final_toxicity,
                    ymax = mean_final_toxicity + sd_final_toxicity),
                width = 5, colour = "grey50") +
  geom_line(linewidth = 0.8, colour = "#F44336") +
  geom_point(size = 3, colour = "#F44336") +
  labs(title = "Dose-response: toxin_dose vs final toxicity",
       x = "toxin_dose", y = "final mean_toxicity") +
  theme_minimal(base_size = 11)

p_grid <- ggplot(grid_df,
                 aes(factor(toxicity_cost), factor(toxin_dose),
                     fill = mean_final_toxicity)) +
  geom_tile() +
  geom_text(aes(label = sprintf("%.2f", mean_final_toxicity)),
            colour = "white", size = 3.5) +
  scale_fill_viridis_c(name = "tox") +
  labs(title = "Cost x dose grid (final mean_toxicity)",
       x = "toxicity_cost_per_tick", y = "toxin_dose") +
  theme_minimal(base_size = 11)

p <- (p_traj | p_dose) / p_grid +
  plot_annotation(
    title = "Mimicry fidelity audit: toxicity evolution under predator pressure",
    subtitle = sprintf(
      "5 seeds, 600 ticks. Control final %.3f vs treatment %.3f (P2 %s)",
      mean(ctrl_final), mean(trt_final),
      if (mean(trt_final) > mean(ctrl_final)) "PASS" else "FAIL"),
    theme = theme(plot.title = element_text(face = "bold"))
  )

ggsave("dev/audit/fidelity/figs/mimicry.png", p,
       width = 11, height = 8, dpi = 150)
cat("\nWrote dev/audit/fidelity/figs/mimicry.png\n")
