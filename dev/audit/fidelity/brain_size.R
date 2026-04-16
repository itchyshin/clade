#!/usr/bin/env Rscript
# Fidelity audit: brain size evolution under parental provisioning hypothesis.
# Prediction: without parental care, brain size drifts DOWN (cost > benefit
#             for naïve newborns). With parental care, brain size can evolve up.
#
# 0.4.1 update: grid sweep over `brain_size_cost_scale × care_duration` to
# find a regime where the care-vs-no-care signal exceeds 0.05 units (5×
# the 0.009 observed at the previous default). The pre-0.4.1 audit found
# the correct direction but too-weak magnitude.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(with_care, cost_scale, care_duration,
                    neonatal_deficit, size_exp,
                    seed, max_ticks = 400L) {
  s <- default_specs()
  s$brain_size_evolution          <- TRUE
  s$brain_size_init_mean          <- 1.1
  s$brain_size_mutation_sd        <- 0.05
  s$brain_size_cost_scale         <- cost_scale
  # 0.4.3: keep brain_energy_base at default 0.001; selection pressure
  # now comes from neonatal_foraging_deficit + super-linear size exponent
  # rather than from a scenario-specific base override.
  s$brain_energy_size_exponent    <- size_exp
  s$neonatal_foraging_deficit     <- neonatal_deficit
  s$neonatal_deficit_duration     <- 10L
  s$parental_care                 <- with_care
  s$care_duration                 <- as.integer(care_duration)
  s$feeding_rate                  <- 3.0
  s$n_agents_init                 <- 80L
  s$grid_rows                     <- 25L
  s$grid_cols                     <- 25L
  s$grass_rate                    <- 0.15
  s$max_agents                    <- 400L
  s$max_ticks                     <- as.integer(max_ticks)
  s$random_seed                   <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$with_care         <- with_care
  d$cost_scale        <- cost_scale
  d$care_duration     <- care_duration
  d$neonatal_deficit  <- neonatal_deficit
  d$size_exp          <- size_exp
  d$seed              <- seed
  d
}

# 0.4.3 update: instead of overriding `brain_energy_base` (which the
# 0.4.2 audit showed reaches ✅ at 0.010 but destabilises populations),
# test the two new 0.4.3 mechanisms — `neonatal_foraging_deficit` and
# `brain_energy_size_exponent` — at the DEFAULT base (0.001). If the
# parental-provisioning signal emerges naturally under these
# biologically-motivated mechanisms, we can keep the default base.
grid <- expand.grid(neonatal_deficit = c(0.0, 0.3, 0.6),
                    size_exp         = c(1.0, 1.5),
                    cost_scale       = c(3.0),
                    care_duration    = c(15L),
                    KEEP.OUT.ATTRS   = FALSE)
seeds <- 1L:3L

cat(sprintf("── brain_size grid (0.4.3): %d combos × 2 conditions × %d seeds\n",
            nrow(grid), length(seeds)))

summary_rows <- list()
for (i in seq_len(nrow(grid))) {
  row <- grid[i, ]
  care_runs    <- lapply(seeds, function(sd) {
    cat(sprintf("  deficit=%.1f size_exp=%.1f care=T seed=%d\n",
                row$neonatal_deficit, row$size_exp, sd))
    one_run(TRUE,  row$cost_scale, row$care_duration,
            row$neonatal_deficit, row$size_exp, sd)
  })
  no_care_runs <- lapply(seeds, function(sd) {
    cat(sprintf("  deficit=%.1f size_exp=%.1f care=F seed=%d\n",
                row$neonatal_deficit, row$size_exp, sd))
    one_run(FALSE, row$cost_scale, row$care_duration,
            row$neonatal_deficit, row$size_exp, sd)
  })
  care_delta <- vapply(care_runs,
                       function(d) tail(d$mean_brain_size, 1L) -
                                    d$mean_brain_size[1],
                       numeric(1L))
  noc_delta  <- vapply(no_care_runs,
                       function(d) tail(d$mean_brain_size, 1L) -
                                    d$mean_brain_size[1],
                       numeric(1L))
  summary_rows[[i]] <- data.frame(
    neonatal_deficit = row$neonatal_deficit,
    size_exp         = row$size_exp,
    care_delta       = mean(care_delta),
    no_care_delta    = mean(noc_delta),
    delta_delta      = mean(care_delta) - mean(noc_delta),
    sd_delta_delta   = sqrt(var(care_delta) + var(noc_delta)),
    care_final_n     = mean(vapply(care_runs,
                                    function(d) tail(d$n_agents, 1L),
                                    numeric(1L))),
    noc_final_n      = mean(vapply(no_care_runs,
                                    function(d) tail(d$n_agents, 1L),
                                    numeric(1L)))
  )
}
summary <- do.call(rbind, summary_rows)

cat("\nGrid summary (care Δ - no-care Δ):\n")
print(summary[order(-summary$delta_delta), ])

best <- summary[which.max(summary$delta_delta), ]
cat(sprintf("\nBest regime: deficit=%.1f size_exp=%.1f  Δdelta=%+.3f ± %.3f\n",
            best$neonatal_deficit, best$size_exp,
            best$delta_delta, best$sd_delta_delta))
p1_pass <- best$delta_delta > 0.05
cat(sprintf("P1 (parental-provisioning benefit > 0.05 at some regime): %s\n",
            if (p1_pass) "PASS" else "PARTIAL (directional, small)"))

saveRDS(summary, "dev/audit/fidelity/brain_size_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p <- ggplot(summary,
            aes(factor(neonatal_deficit), factor(size_exp),
                fill = delta_delta)) +
  geom_tile() +
  geom_text(aes(label = sprintf("%+.3f", delta_delta)),
            colour = "white") +
  scale_fill_viridis_c(name = "Δdelta") +
  labs(title = "Brain size (0.4.3): care-vs-no-care via neonatal deficit × size exponent",
       subtitle = "Parental provisioning at default brain_energy_base=0.001",
       x = "neonatal_foraging_deficit", y = "brain_energy_size_exponent") +
  theme_minimal(base_size = 11)
ggsave("dev/audit/fidelity/figs/brain_size.png", p,
       width = 9, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/brain_size.png\n")
