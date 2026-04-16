#!/usr/bin/env Rscript
# Fidelity audit: within-lifetime RL (Williams 1992 REINFORCE).
# Prediction: RL-enabled agents achieve higher mean energy and/or
#            population via within-lifetime adaptation.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(rl, seed, max_ticks = 500L) {
  s <- default_specs()
  s$rl_mode         <- if (rl) "actor_critic" else "none"
  s$rl_update_freq  <- 5L
  s$learning_rate_init_mean <- 0.01
  s$brain_type      <- "bnn"
  s$n_agents_init   <- 100L
  s$grid_rows       <- 30L; s$grid_cols <- 30L
  s$grass_rate      <- 0.12
  s$max_agents      <- 400L
  s$max_ticks       <- as.integer(max_ticks)
  s$random_seed     <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$rl <- rl; d$seed <- seed
  d
}

seeds <- 1L:4L
cat("── RL on vs off (BNN, 4 seeds, 500 ticks)\n")
no_rl <- lapply(seeds, function(sd) one_run(FALSE, sd))
rl_on <- lapply(seeds, function(sd) one_run(TRUE,  sd))

mn <- function(runs, col) {
  vapply(runs, function(d) mean(d[[col]][d$t > 100], na.rm = TRUE),
         numeric(1L))
}
no_n <- mn(no_rl, "n_agents"); rl_n <- mn(rl_on, "n_agents")
no_e <- mn(no_rl, "mean_energy"); rl_e <- mn(rl_on, "mean_energy")

cat(sprintf("\nNo RL:  n=%.0f±%.0f  energy=%.1f±%.1f\n",
            mean(no_n), sd(no_n), mean(no_e), sd(no_e)))
cat(sprintf("RL on:  n=%.0f±%.0f  energy=%.1f±%.1f\n",
            mean(rl_n), sd(rl_n), mean(rl_e), sd(rl_e)))
p1_pass <- mean(rl_n) > mean(no_n) || mean(rl_e) > mean(no_e)
cat(sprintf("P1 (RL raises pop or energy): %s (Δn=%+.1f, Δe=%+.2f)\n",
            if (p1_pass) "PASS" else "FAIL",
            mean(rl_n) - mean(no_n), mean(rl_e) - mean(no_e)))

all_ticks <- do.call(rbind, c(no_rl, rl_on))
all_ticks$cond <- ifelse(all_ticks$rl, "rl_on", "no_rl")
saveRDS(all_ticks, "dev/audit/fidelity/rl_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p <- ggplot(all_ticks, aes(t, n_agents, colour = cond,
                            group = interaction(cond, seed))) +
  geom_line(alpha = 0.4, linewidth = 0.4) +
  stat_summary(aes(group = cond), fun = mean, geom = "line",
               linewidth = 1.1) +
  scale_colour_manual(values = c(no_rl = "#9E9E9E", rl_on = "#9C27B0"),
                      name = NULL) +
  labs(title = "Within-lifetime RL (Williams 1992 REINFORCE): BNN brain",
       subtitle = sprintf("4 seeds × 500 ticks. No-RL n=%.0f, RL n=%.0f",
                          mean(no_n), mean(rl_n)),
       x = "Tick", y = "n_agents") +
  theme_minimal(base_size = 12)
ggsave("dev/audit/fidelity/figs/rl.png", p,
       width = 9, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/rl.png\n")
