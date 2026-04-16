#!/usr/bin/env Rscript
# Fidelity audit: brain size evolution under parental provisioning hypothesis.
# Prediction: without parental care, brain size drifts DOWN (cost > benefit
#             for naïve newborns). With parental care, brain size can evolve up.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(with_care, seed, max_ticks = 400L,
                    cost_scale = 2.0) {
  s <- default_specs()
  s$brain_size_evolution     <- TRUE
  s$brain_size_init_mean     <- 1.1
  s$brain_size_mutation_sd   <- 0.05
  s$brain_size_cost_scale    <- cost_scale
  s$parental_care            <- with_care
  s$care_duration            <- 15L
  s$feeding_rate             <- 3.0
  s$n_agents_init            <- 80L
  s$grid_rows                <- 25L; s$grid_cols <- 25L
  s$grass_rate               <- 0.15
  s$max_agents               <- 400L
  s$max_ticks                <- as.integer(max_ticks)
  s$random_seed              <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$with_care <- with_care; d$seed <- seed
  d
}

seeds <- 1L:4L
cat("── brain_size evolution ± parental_care (4 seeds, 400 ticks, cost=2.0)\n")
care <- lapply(seeds, function(sd) {
  cat(sprintf("  care seed %d\n", sd))
  one_run(TRUE, sd)
})
no_care <- lapply(seeds, function(sd) {
  cat(sprintf("  no_care seed %d\n", sd))
  one_run(FALSE, sd)
})

fin_bs <- function(runs) {
  vapply(runs, function(d) tail(d$mean_brain_size, 1L), numeric(1L))
}
care_bs <- fin_bs(care); noc_bs <- fin_bs(no_care)
care_init <- vapply(care, function(d) d$mean_brain_size[1], numeric(1L))
noc_init  <- vapply(no_care, function(d) d$mean_brain_size[1], numeric(1L))

cat(sprintf("\nWith care:    init=%.3f → final=%.3f (Δ=%+.3f ± %.3f)\n",
            mean(care_init), mean(care_bs),
            mean(care_bs - care_init), sd(care_bs - care_init)))
cat(sprintf("No care:      init=%.3f → final=%.3f (Δ=%+.3f ± %.3f)\n",
            mean(noc_init), mean(noc_bs),
            mean(noc_bs - noc_init), sd(noc_bs - noc_init)))
p1_pass <- mean(care_bs - care_init) > mean(noc_bs - noc_init)
cat(sprintf("P1 (care > no_care brain drift): %s (Δdelta=%+.3f)\n",
            if (p1_pass) "PASS" else "FAIL",
            mean(care_bs - care_init) - mean(noc_bs - noc_init)))

all_ticks <- do.call(rbind, c(care, no_care))
all_ticks$cond <- ifelse(all_ticks$with_care, "care", "no_care")
saveRDS(all_ticks, "dev/audit/fidelity/brain_size_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p <- ggplot(all_ticks, aes(t, mean_brain_size, colour = cond,
                            group = interaction(cond, seed))) +
  geom_line(alpha = 0.45, linewidth = 0.4) +
  stat_summary(aes(group = cond), fun = mean, geom = "line",
               linewidth = 1.1) +
  scale_colour_manual(values = c(care = "#2196F3", no_care = "#F44336"),
                      name = NULL) +
  geom_hline(yintercept = 1.0, linetype = "dashed", colour = "grey50") +
  labs(title = "Brain size evolution: parental provisioning unlocks bootstrap",
       subtitle = sprintf("4 seeds × 400 ticks. Care Δ=%+.3f, no-care Δ=%+.3f",
                          mean(care_bs - care_init),
                          mean(noc_bs - noc_init)),
       x = "Tick", y = "mean_brain_size") +
  theme_minimal(base_size = 12)
ggsave("dev/audit/fidelity/figs/brain_size.png", p,
       width = 9, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/brain_size.png\n")
