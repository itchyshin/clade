# Re-run the baseline under the parameters the vignette's
# "What we found" prose actually reports (seed=42, 500 ticks, 100 agents,
# 30x30, grass_rate=0.15) to see if those numbers reproduce.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
})

s <- default_specs()
s$grid_rows     <- 30L
s$grid_cols     <- 30L
s$n_agents_init <- 100L
s$max_ticks     <- 500L
s$grass_rate    <- 0.15
s$random_seed   <- 42L

env   <- run_alife(s)
rd    <- get_run_data(env)
ticks <- rd$ticks

cat("\n=== Prose-stated conditions (seed 42, 500 ticks, 100 agents, 30x30, grass_rate=0.15) ===\n")
cat(sprintf("n_agents  range: [%d, %d], mean %.1f\n",
            min(ticks$n_agents), max(ticks$n_agents), mean(ticks$n_agents)))
cat(sprintf("mean_energy tick 50: %.1f  tick 450: %.1f\n",
            ticks$mean_energy[ticks$t == 50],
            ticks$mean_energy[ticks$t == 450]))
cat(sprintf("genetic_diversity tick 50: %.3f  tick 450: %.3f\n",
            ticks$genetic_diversity[ticks$t == 50],
            ticks$genetic_diversity[ticks$t == 450]))
cat(sprintf("total births:  %d\n", sum(ticks$n_births)))
cat(sprintf("total deaths:  %d\n", sum(ticks$n_deaths)))
cat(sprintf("grass_coverage range: [%.2f, %.2f]\n",
            min(ticks$grass_coverage), max(ticks$grass_coverage)))
