#!/usr/bin/env Rscript
# Fidelity audit: social learning (Boyd & Richerson 1985, Henrich & McElreath).
# Prediction: social learning of successful strategies raises mean
#            energy and/or population size.
# Caveat: known interaction with BNN brains (sampled each tick).
# Test with brain_type="ann" for clearer signal.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(social, brain, seed, max_ticks = 500L) {
  s <- default_specs()
  s$social_learning        <- social
  s$social_learning_freq   <- 10L
  s$social_learning_radius <- 3L
  s$brain_type             <- brain
  s$n_agents_init          <- 150L
  s$grid_rows              <- 30L; s$grid_cols <- 30L
  s$grass_rate             <- 0.12
  s$max_agents             <- 400L
  s$max_ticks              <- as.integer(max_ticks)
  s$random_seed            <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$social <- social; d$brain <- brain; d$seed <- seed
  d
}

seeds <- 1L:3L
cat("── social_learning × brain_type (3 seeds, 500 ticks)\n")
conds <- expand.grid(social = c(FALSE, TRUE),
                     brain = c("ann", "bnn"),
                     stringsAsFactors = FALSE)
all_runs <- list()
for (i in seq_len(nrow(conds))) {
  row <- conds[i, ]
  for (sd in seeds) {
    cat(sprintf("  social=%s brain=%s seed %d\n", row$social, row$brain, sd))
    d <- one_run(row$social, row$brain, sd)
    all_runs[[length(all_runs) + 1L]] <- d
  }
}
all_ticks <- do.call(rbind, all_runs)

summary_df <- aggregate(
  cbind(n_agents, mean_energy) ~ social + brain,
  data = all_ticks[all_ticks$t > 200, ], FUN = mean)
cat("\nMeans (post-burn-in):\n")
print(summary_df)

# compute deltas
ann_no <- summary_df$n_agents[!summary_df$social & summary_df$brain == "ann"]
ann_sl <- summary_df$n_agents[ summary_df$social & summary_df$brain == "ann"]
bnn_no <- summary_df$n_agents[!summary_df$social & summary_df$brain == "bnn"]
bnn_sl <- summary_df$n_agents[ summary_df$social & summary_df$brain == "bnn"]
cat(sprintf("\nANN: social→%+.1f, BNN: social→%+.1f\n",
            ann_sl - ann_no, bnn_sl - bnn_no))

saveRDS(list(all_ticks = all_ticks, summary = summary_df),
        "dev/audit/fidelity/social_learning_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
all_ticks$cond <- paste0(all_ticks$brain, ifelse(all_ticks$social, "+SL", ""))
p <- ggplot(all_ticks, aes(t, n_agents, colour = cond,
                            group = interaction(cond, seed))) +
  geom_line(alpha = 0.35, linewidth = 0.35) +
  stat_summary(aes(group = cond), fun = mean, geom = "line",
               linewidth = 1.0) +
  labs(title = "Social learning × brain_type",
       subtitle = sprintf("ANN Δ=%+.1f, BNN Δ=%+.1f agents",
                          ann_sl - ann_no, bnn_sl - bnn_no),
       x = "Tick", y = "n_agents") +
  theme_minimal(base_size = 11)
ggsave("dev/audit/fidelity/figs/social_learning.png", p,
       width = 10, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/social_learning.png\n")
