#!/usr/bin/env Rscript
# Fidelity audit: life-history strategies (semelparous vs iteroparous).
#
# Theory (Cole 1954, Williams 1966):
#   - Semelparous: one big-bang reproductive event, then death.
#   - Iteroparous: spread reproduction over many seasons.
#   - Cole's paradox: iteroparity advantage equals just one extra
#     surviving offspring under simple demography. The strategies are
#     more similar than intuition suggests.
#   - Williams (1966): semelparous trades somatic maintenance for
#     terminal reproductive effort.
#
# alifeR cross-reference: alifeR/vignettes/showcase.Rmd §8 — same
# `life_history` flag, same intended contrast, same "boom-bust"
# expected pattern for semelparous (per its caption).
#
# clade kernel cross-reference: inst/julia/src/death.jl:38, 81 —
# semelparous death triggered by `ag.reproduced` flag, same as
# alifeR/R/death.R:66.
#
# Predictions to test (signs only; magnitudes are scenario-specific):
#   1. mean_age:    semelparous < iteroparous
#   2. n_births:    semelparous > iteroparous (faster turnover)
#   3. mean_energy: semelparous < iteroparous (terminal effort)
#   4. pop var:     semelparous lower (turnover smooths fluctuations)
#                   OR semelparous higher (cohort waves)
#                   — empirical question; either is theory-consistent.
#
# Usage: Rscript dev/audit/fidelity/life_history.R
# Output:
#   dev/audit/fidelity/figs/life_history.png
#   dev/audit/fidelity/life_history_results.rds

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
  library(ggplot2)
  library(patchwork)
})

one_run <- function(strategy, seed, max_ticks = 400L) {
  s <- default_specs()
  s$life_history   <- strategy
  s$n_agents_init  <- 80L
  s$grid_rows      <- 25L
  s$grid_cols      <- 25L
  s$grass_rate     <- 0.15
  s$max_ticks      <- as.integer(max_ticks)
  s$random_seed    <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  d$strategy <- strategy
  d$seed     <- seed
  d
}

seeds <- 1L:5L
strategies <- c("semelparous", "iteroparous")

cat(sprintf("Running %d seeds x %d strategies = %d runs (400 ticks each)\n",
            length(seeds), length(strategies),
            length(seeds) * length(strategies)))
t0 <- Sys.time()
runs <- list()
for (st in strategies) {
  for (sd in seeds) {
    cat(sprintf("  %s seed %d\n", st, sd))
    runs[[length(runs) + 1L]] <- one_run(st, sd)
  }
}
all_ticks <- do.call(rbind, runs)
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
cat(sprintf("Done in %.1f s.\n\n", elapsed))

# ── Per-strategy summary across seeds ────────────────────────────────────────

burn_in <- 100L
summarise_seed <- function(d) {
  d2 <- d[d$t > burn_in, ]
  data.frame(
    strategy   = d$strategy[1],
    seed       = d$seed[1],
    mean_age   = mean(d2$mean_age, na.rm = TRUE),
    mean_n     = mean(d2$n_agents),
    var_n      = var(d2$n_agents),
    mean_births= mean(d2$n_births),
    total_births = sum(d2$n_births),
    mean_energy = mean(d2$mean_energy, na.rm = TRUE),
    final_n    = tail(d2$n_agents, 1L)
  )
}
per_seed <- do.call(rbind, lapply(runs, summarise_seed))

cat("Per-seed summary (post-burn-in t > 100):\n")
print(per_seed)

cat("\nGroup means (seeds pooled):\n")
agg <- aggregate(. ~ strategy, data = per_seed[, -2], FUN = mean)
print(agg)

# Sign tests for the four predictions
sem  <- per_seed[per_seed$strategy == "semelparous", ]
iter <- per_seed[per_seed$strategy == "iteroparous", ]
cat("\nPredictions vs observed (signs):\n")
cat(sprintf("  1. mean_age:     sem (%.1f) < iter (%.1f)  -> %s\n",
            mean(sem$mean_age), mean(iter$mean_age),
            if (mean(sem$mean_age) < mean(iter$mean_age)) "PASS" else "FAIL"))
cat(sprintf("  2. births rate:  sem (%.2f) > iter (%.2f)  -> %s\n",
            mean(sem$mean_births), mean(iter$mean_births),
            if (mean(sem$mean_births) > mean(iter$mean_births)) "PASS" else "FAIL"))
cat(sprintf("  3. mean_energy:  sem (%.1f) < iter (%.1f)  -> %s\n",
            mean(sem$mean_energy), mean(iter$mean_energy),
            if (mean(sem$mean_energy) < mean(iter$mean_energy)) "PASS" else "FAIL"))
cat(sprintf("  4. pop variance: sem (%.0f) vs iter (%.0f) — empirical\n",
            mean(sem$var_n), mean(iter$var_n)))

saveRDS(list(all_ticks = all_ticks, per_seed = per_seed, agg = agg),
        "dev/audit/fidelity/life_history_results.rds")

# ── Figure ──────────────────────────────────────────────────────────────────

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)

palette <- c(semelparous = "#e41a1c", iteroparous = "#4daf4a")

p_pop <- ggplot(all_ticks, aes(t, n_agents, colour = strategy, group = interaction(strategy, seed))) +
  geom_line(alpha = 0.45, linewidth = 0.4) +
  stat_summary(aes(group = strategy), fun = mean, geom = "line", linewidth = 1.1) +
  scale_colour_manual(values = palette, name = NULL) +
  labs(title = "Population size", x = "Tick", y = "n_agents") +
  theme_minimal(base_size = 11)

p_age <- ggplot(all_ticks, aes(t, mean_age, colour = strategy, group = interaction(strategy, seed))) +
  geom_line(alpha = 0.45, linewidth = 0.4) +
  stat_summary(aes(group = strategy), fun = mean, geom = "line", linewidth = 1.1) +
  scale_colour_manual(values = palette, name = NULL) +
  labs(title = "Mean age", x = "Tick", y = "mean_age") +
  theme_minimal(base_size = 11)

p_births <- ggplot(all_ticks, aes(t, n_births, colour = strategy, group = interaction(strategy, seed))) +
  geom_line(alpha = 0.45, linewidth = 0.4) +
  stat_summary(aes(group = strategy), fun = mean, geom = "line", linewidth = 1.1) +
  scale_colour_manual(values = palette, name = NULL) +
  labs(title = "Births per tick", x = "Tick", y = "n_births") +
  theme_minimal(base_size = 11)

p_energy <- ggplot(all_ticks, aes(t, mean_energy, colour = strategy, group = interaction(strategy, seed))) +
  geom_line(alpha = 0.45, linewidth = 0.4) +
  stat_summary(aes(group = strategy), fun = mean, geom = "line", linewidth = 1.1) +
  scale_colour_manual(values = palette, name = NULL) +
  labs(title = "Mean energy", x = "Tick", y = "mean_energy") +
  theme_minimal(base_size = 11)

p <- (p_pop | p_age) / (p_births | p_energy) +
  plot_annotation(
    title = "Life-history fidelity audit: semelparous vs iteroparous (5 seeds, 400 ticks)",
    subtitle = "80 agents init, 25x25 grid, grass_rate=0.15. Bold = mean across seeds.",
    theme = theme(plot.title = element_text(face = "bold"))
  )

ggsave("dev/audit/fidelity/figs/life_history.png", p,
       width = 11, height = 7, dpi = 150)
cat("\nWrote dev/audit/fidelity/figs/life_history.png\n")
