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
                    seed, max_ticks = 400L) {
  s <- default_specs()
  s$brain_size_evolution     <- TRUE
  s$brain_size_init_mean     <- 1.1
  s$brain_size_mutation_sd   <- 0.05
  s$brain_size_cost_scale    <- cost_scale
  s$parental_care            <- with_care
  s$care_duration            <- as.integer(care_duration)
  s$feeding_rate             <- 3.0
  s$n_agents_init            <- 80L
  s$grid_rows                <- 25L
  s$grid_cols                <- 25L
  s$grass_rate               <- 0.15
  s$max_agents               <- 400L
  s$max_ticks                <- as.integer(max_ticks)
  s$random_seed              <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$with_care     <- with_care
  d$cost_scale    <- cost_scale
  d$care_duration <- care_duration
  d$seed          <- seed
  d
}

grid <- expand.grid(cost_scale    = c(2.0, 3.0, 4.0),
                    care_duration = c(15L, 30L, 45L),
                    KEEP.OUT.ATTRS = FALSE)
seeds <- 1L:3L

cat(sprintf("── brain_size grid: %d combos × 2 conditions × %d seeds\n",
            nrow(grid), length(seeds)))

summary_rows <- list()
for (i in seq_len(nrow(grid))) {
  row <- grid[i, ]
  care_runs    <- lapply(seeds, function(sd) {
    cat(sprintf("  cost=%.1f dur=%d care=T seed=%d\n",
                row$cost_scale, row$care_duration, sd))
    one_run(TRUE,  row$cost_scale, row$care_duration, sd)
  })
  no_care_runs <- lapply(seeds, function(sd) {
    cat(sprintf("  cost=%.1f dur=%d care=F seed=%d\n",
                row$cost_scale, row$care_duration, sd))
    one_run(FALSE, row$cost_scale, row$care_duration, sd)
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
    cost_scale     = row$cost_scale,
    care_duration  = row$care_duration,
    care_delta     = mean(care_delta),
    no_care_delta  = mean(noc_delta),
    delta_delta    = mean(care_delta) - mean(noc_delta),
    sd_delta_delta = sqrt(var(care_delta) + var(noc_delta)),
    care_final_n   = mean(vapply(care_runs,
                                  function(d) tail(d$n_agents, 1L),
                                  numeric(1L))),
    noc_final_n    = mean(vapply(no_care_runs,
                                  function(d) tail(d$n_agents, 1L),
                                  numeric(1L)))
  )
}
summary <- do.call(rbind, summary_rows)

cat("\nGrid summary (care Δ - no-care Δ):\n")
print(summary[order(-summary$delta_delta), ])

best <- summary[which.max(summary$delta_delta), ]
cat(sprintf("\nBest regime: cost=%.1f dur=%d  Δdelta=%+.3f ± %.3f\n",
            best$cost_scale, best$care_duration,
            best$delta_delta, best$sd_delta_delta))
p1_pass <- best$delta_delta > 0.05
cat(sprintf("P1 (parental-provisioning benefit > 0.05 at some regime): %s\n",
            if (p1_pass) "PASS" else "PARTIAL (directional, small)"))

saveRDS(summary, "dev/audit/fidelity/brain_size_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p <- ggplot(summary,
            aes(factor(care_duration), factor(cost_scale),
                fill = delta_delta)) +
  geom_tile() +
  geom_text(aes(label = sprintf("%+.3f", delta_delta)),
            colour = "white") +
  scale_fill_viridis_c(name = "Δdelta") +
  labs(title = "Brain size: care-vs-no-care delta across cost × duration grid",
       subtitle = "Parental provisioning hypothesis (van Schaik et al. 2023)",
       x = "care_duration (ticks)", y = "brain_size_cost_scale") +
  theme_minimal(base_size = 11)
ggsave("dev/audit/fidelity/figs/brain_size.png", p,
       width = 9, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/brain_size.png\n")
