# Brain-type benchmark — how do the 7 clade brain architectures compare
# when placed in the same ecology?
#
# clade ships seven brain types (bnn, ann, ctrnn, grn, transformer,
# synthesis, random) but has never had a side-by-side benchmark. This
# script runs the same foraging scenario with each brain type in
# parallel across 5 seeds and compares:
#
#   - final population size (viability)
#   - mean energy trajectory (foraging efficiency)
#   - genetic diversity trajectory (exploration/exploitation)
#   - final trajectory stability (within-run variance of n_agents)
#
# Uses the 0.5.6 PSOCK parallel path (7 brain types × 5 seeds = 35
# independent runs dispatched across 35 R+Julia worker sessions).
#
# Usage:  Rscript dev/benchmarks/brain_comparison.R
# Output:
#   dev/benchmarks/brain_comparison.rds
#   vignettes/figures/showcase_brain_comparison.png
#   inst/figures/showcase_brain_comparison.png

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
  library(ggplot2)
  library(patchwork)
})

# Five implemented brain types as of 0.5.6. `transformer` and
# `synthesis` are documented as supported in `?default_specs` but
# the Julia kernel still errors with "planned for later phases" —
# flagged as a doc inconsistency (CLAUDE.md has "don't claim
# unimplemented features" in spirit). Filed for future vs
# silent-success.
BRAIN_TYPES <- c("bnn", "ann", "ctrnn", "grn", "random")
SEEDS       <- c(1L, 7L, 13L, 19L, 25L)

# Build the full 7 × 5 = 35 specs_list using the new grid_specs helper
base <- default_specs()
base$n_agents_init <- 80L
base$max_agents    <- 400L
base$grid_rows     <- 30L
base$grid_cols     <- 30L
base$grass_rate    <- 0.15
base$max_ticks     <- 500L

specs_list <- grid_specs(base,
                         brain_type  = BRAIN_TYPES,
                         random_seed = SEEDS)
message(sprintf("Built %d specs (%d brain types × %d seeds)",
                length(specs_list), length(BRAIN_TYPES), length(SEEDS)))

t0 <- Sys.time()
message(sprintf("Running %d specs across %d cores...",
                length(specs_list), length(specs_list)))
results <- batch_alife(specs_list, n_cores = length(specs_list))
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
message(sprintf("  batch: %.1f min wall clock", elapsed))

# Extract per-run summary rows
rows <- lapply(seq_along(results), function(i) {
  env <- results[[i]]
  s   <- specs_list[[i]]
  d   <- get_run_data(env)$ticks
  data.frame(
    brain_type        = s$brain_type,
    seed              = s$random_seed,
    n_final           = tail(d$n_agents, 1L),
    n_mean_last100    = mean(tail(d$n_agents, 100L), na.rm = TRUE),
    n_sd_last100      = sd  (tail(d$n_agents, 100L), na.rm = TRUE),
    energy_final      = tail(d$mean_energy, 1L),
    diversity_final   = tail(d$genetic_diversity, 1L),
    age_final         = tail(d$mean_age, 1L),
    viability         = viability_report(d, n_agents_init = s$n_agents_init)$verdict,
    stringsAsFactors  = FALSE
  )
})
summary_tbl <- do.call(rbind, rows)

# Also extract per-tick trajectories for the plot
traj <- do.call(rbind, lapply(seq_along(results), function(i) {
  env <- results[[i]]
  s   <- specs_list[[i]]
  d   <- get_run_data(env)$ticks
  d$brain_type <- s$brain_type
  d$seed       <- s$random_seed
  d[, c("t", "n_agents", "mean_energy", "genetic_diversity",
        "brain_type", "seed")]
}))

saveRDS(list(summary = summary_tbl, trajectories = traj),
        "dev/benchmarks/brain_comparison.rds")

message("\n── Summary (mean ± sd across 5 seeds) ──")
agg <- aggregate(cbind(n_final, energy_final, diversity_final, age_final)
                  ~ brain_type, data = summary_tbl,
                 FUN = function(x) c(mean = mean(x), sd = sd(x)))
print(agg)

# Viability tally
message("\n── Viability per brain type ──")
print(table(summary_tbl$brain_type, summary_tbl$viability))

# Plot: mean trajectories per brain type (faceted)
brain_order <- c("bnn", "ann", "ctrnn", "grn",
                 "transformer", "synthesis", "random")
traj$brain_type <- factor(traj$brain_type, levels = brain_order)

p_pop <- ggplot(traj, aes(t, n_agents,
                           colour = brain_type,
                           group  = interaction(brain_type, seed))) +
  geom_line(alpha = 0.35, linewidth = 0.4) +
  stat_summary(aes(group = brain_type), fun = mean, geom = "line",
               linewidth = 1.0) +
  facet_wrap(~ brain_type, ncol = 4L) +
  scale_colour_brewer(palette = "Set2", guide = "none") +
  labs(title = "Population size over time, by brain type",
       subtitle = "5 seeds each; bold line = seed-mean",
       x = "Tick", y = "N agents") +
  theme_minimal(base_size = 11)

p_eng <- ggplot(traj, aes(t, mean_energy,
                           colour = brain_type,
                           group  = interaction(brain_type, seed))) +
  geom_line(alpha = 0.35, linewidth = 0.4) +
  stat_summary(aes(group = brain_type), fun = mean, geom = "line",
               linewidth = 1.0) +
  facet_wrap(~ brain_type, ncol = 4L) +
  scale_colour_brewer(palette = "Set2", guide = "none") +
  labs(title = "Mean energy over time, by brain type",
       x = "Tick", y = "Mean energy") +
  theme_minimal(base_size = 11)

p <- p_pop / p_eng + plot_annotation(
  title = sprintf(
    "Brain-type benchmark: %d architectures × %d seeds at default_specs",
    length(BRAIN_TYPES), length(SEEDS)),
  subtitle = sprintf(
    "Parallelised across %d PSOCK workers (0.5.6 batch_alife)",
    length(specs_list))
)

for (d in c("inst/figures", "vignettes/figures")) {
  ggsave(file.path(d, "showcase_brain_comparison.png"),
         plot = p, width = 12, height = 7, dpi = 150)
}
message("  saved: showcase_brain_comparison.png")
