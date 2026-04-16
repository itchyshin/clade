#!/usr/bin/env Rscript
# Fidelity audit: within-lifetime RL (Williams 1992 REINFORCE).
# Prediction: RL-enabled agents achieve higher mean energy and/or
#            population via within-lifetime adaptation.
#
# 0.4.1 update: sweep `bnn_sample_freq` as an axis. Pre-0.4.1, BNN
# resampled weights every tick which washed out RL gradient updates —
# audit result was null (Δn = +0.7, Δe = −0.6). Tier 5B lets samples
# persist across multiple forward calls; this audit tests whether
# higher freq exposes an RL benefit.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(rl, sample_freq, seed, max_ticks = 500L) {
  s <- default_specs()
  s$rl_mode                 <- if (rl) "actor_critic" else "none"
  s$rl_update_freq          <- 5L
  s$learning_rate_init_mean <- 0.01
  s$brain_type              <- "bnn"
  s$bnn_sample_freq         <- as.integer(sample_freq)
  s$n_agents_init           <- 100L
  s$grid_rows               <- 30L
  s$grid_cols               <- 30L
  s$grass_rate              <- 0.12
  s$max_agents              <- 400L
  s$max_ticks               <- as.integer(max_ticks)
  s$random_seed             <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$rl <- rl
  d$sample_freq <- sample_freq
  d$seed <- seed
  d
}

seeds <- 1L:3L
freqs <- c(1L, 5L, 20L)

cat("── RL × bnn_sample_freq sweep (3 seeds × 3 freqs × RL on/off, 500 ticks)\n")

all_runs <- list()
for (freq in freqs) {
  for (sd in seeds) {
    for (rl in c(FALSE, TRUE)) {
      cat(sprintf("  freq=%d rl=%s seed=%d\n", freq, rl, sd))
      all_runs[[length(all_runs) + 1L]] <- one_run(rl, freq, sd)
    }
  }
}

mn <- function(runs, col) {
  vapply(runs, function(d) mean(d[[col]][d$t > 100], na.rm = TRUE),
         numeric(1L))
}

summary_rows <- list()
for (freq in freqs) {
  for (rl in c(FALSE, TRUE)) {
    subset <- Filter(function(d) d$sample_freq[1] == freq &&
                                   d$rl[1] == rl, all_runs)
    ns <- mn(subset, "n_agents")
    es <- mn(subset, "mean_energy")
    summary_rows[[length(summary_rows) + 1L]] <- data.frame(
      sample_freq = freq, rl = rl,
      mean_n = mean(ns), sd_n = sd(ns),
      mean_e = mean(es), sd_e = sd(es)
    )
  }
}
summary <- do.call(rbind, summary_rows)

cat("\nSummary (post-burn-in t>100):\n")
print(summary)

cat("\nDelta RL_on - RL_off per freq:\n")
for (freq in freqs) {
  on  <- summary[summary$sample_freq == freq &  summary$rl, ]
  off <- summary[summary$sample_freq == freq & !summary$rl, ]
  cat(sprintf("  freq=%2d: Δn=%+6.1f  Δe=%+6.2f\n",
              freq, on$mean_n - off$mean_n, on$mean_e - off$mean_e))
}

# P1: at some freq >= 5, RL should produce a detectable benefit
p1_pass <- any(sapply(freqs[freqs >= 5], function(freq) {
  on  <- summary[summary$sample_freq == freq &  summary$rl, ]
  off <- summary[summary$sample_freq == freq & !summary$rl, ]
  (on$mean_e - off$mean_e) > 0.5 || (on$mean_n - off$mean_n) > 2
}))
cat(sprintf("\nP1 (RL benefit emerges at freq>=5): %s\n",
            if (p1_pass) "PASS" else "FAIL"))

all_ticks <- do.call(rbind, all_runs)
all_ticks$cond <- sprintf("freq=%02d_%s",
                          all_ticks$sample_freq,
                          ifelse(all_ticks$rl, "rl_on", "no_rl"))
saveRDS(list(all_ticks = all_ticks, summary = summary),
        "dev/audit/fidelity/rl_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
pal <- c(freq_01_no_rl = "#9E9E9E", freq_01_rl_on = "#9C27B0",
         freq_05_no_rl = "#BDBDBD", freq_05_rl_on = "#BA68C8",
         freq_20_no_rl = "#E0E0E0", freq_20_rl_on = "#CE93D8")
all_ticks$cond_key <- sprintf("freq_%02d_%s",
                               all_ticks$sample_freq,
                               ifelse(all_ticks$rl, "rl_on", "no_rl"))
p <- ggplot(all_ticks,
            aes(t, n_agents, colour = cond_key,
                group = interaction(cond_key, seed))) +
  geom_line(alpha = 0.35, linewidth = 0.35) +
  stat_summary(aes(group = cond_key), fun = mean, geom = "line",
               linewidth = 1.0) +
  scale_colour_manual(values = pal, name = NULL) +
  labs(title = "RL × BNN sample_freq (0.4.1 Tier 5B)",
       subtitle = sprintf(
         "3 seeds × 3 freqs. At freq=1 RL updates wash out; at freq=%d they accumulate.",
         max(freqs)),
       x = "Tick", y = "n_agents") +
  theme_minimal(base_size = 11)
ggsave("dev/audit/fidelity/figs/rl.png", p,
       width = 10, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/rl.png\n")
