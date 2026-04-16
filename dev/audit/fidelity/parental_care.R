#!/usr/bin/env Rscript
# Fidelity audit: parental care (Clutton-Brock 1991).
# Predictions:
#   P1. With care ON, n_juveniles > 0 (graduation pathway works).
#   P2. Population dynamics more buffered with care (lower variance).
#   P3. Longer care_duration → smaller clutch / fewer births but
#       higher juvenile survival.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(care_on, care_duration, seed, max_ticks = 400L) {
  s <- default_specs()
  s$parental_care       <- care_on
  s$care_duration       <- as.integer(care_duration)
  s$care_cost_per_tick  <- 1.0
  s$feeding_rate        <- 5.0
  s$n_agents_init       <- 100L
  s$grid_rows           <- 30L; s$grid_cols <- 30L
  s$grass_rate          <- 0.15
  s$max_agents          <- 400L
  s$max_ticks           <- as.integer(max_ticks)
  s$random_seed         <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$care_on <- care_on; d$care_duration <- care_duration; d$seed <- seed
  d
}

seeds <- 1L:3L
cat("── baseline vs care (3 seeds, 400 ticks)\n")
base <- lapply(seeds, function(sd) one_run(FALSE, 0L, sd))
care5 <- lapply(seeds, function(sd) one_run(TRUE, 5L, sd))
care10 <- lapply(seeds, function(sd) one_run(TRUE, 10L, sd))

summarise <- function(runs, label) {
  d <- do.call(rbind, runs)
  post <- d[d$t > 100, ]
  cat(sprintf("  %s: mean_n=%.0f  var_n=%.0f  mean_juv=%.2f  mean_births=%.2f\n",
              label,
              mean(aggregate(n_agents ~ seed, post, mean)$n_agents),
              mean(aggregate(n_agents ~ seed, post, var)$n_agents),
              mean(post$n_juveniles, na.rm = TRUE),
              mean(post$n_births)))
  list(mean_n = mean(post$n_agents),
       var_n  = mean(aggregate(n_agents ~ seed, post, var)$n_agents),
       mean_juv = mean(post$n_juveniles, na.rm = TRUE))
}

s_base  <- summarise(base,  "baseline   (no care)")
s_care5 <- summarise(care5, "care_dur=5 ")
s_car10 <- summarise(care10,"care_dur=10")

p1_pass <- s_care5$mean_juv > 0.5
cat(sprintf("\nP1 (care ON produces juveniles > 0): %s (mean_juv=%.2f)\n",
            if (p1_pass) "PASS" else "FAIL", s_care5$mean_juv))
p2_pass <- s_care5$var_n < s_base$var_n
cat(sprintf("P2 (care reduces pop variance): %s (%.0f vs %.0f)\n",
            if (p2_pass) "PASS" else "FAIL",
            s_care5$var_n, s_base$var_n))

all_ticks <- do.call(rbind, c(base, care5, care10))
all_ticks$cond <- ifelse(all_ticks$care_on,
                          paste0("care_dur=", all_ticks$care_duration),
                          "baseline")
saveRDS(all_ticks, "dev/audit/fidelity/parental_care_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
p_pop <- ggplot(all_ticks, aes(t, n_agents, colour = cond,
                                group = interaction(cond, seed))) +
  geom_line(alpha = 0.45, linewidth = 0.4) +
  stat_summary(aes(group = cond), fun = mean, geom = "line",
               linewidth = 1.1) +
  labs(title = "Population under parental care",
       x = "Tick", y = "n_agents") + theme_minimal(base_size = 11)
p_juv <- ggplot(subset(all_ticks, care_on),
                aes(t, n_juveniles, colour = cond,
                    group = interaction(cond, seed))) +
  geom_line(alpha = 0.45, linewidth = 0.4) +
  stat_summary(aes(group = cond), fun = mean, geom = "line",
               linewidth = 1.1) +
  labs(title = "Juveniles present (care ON only)",
       x = "Tick", y = "n_juveniles") + theme_minimal(base_size = 11)
p <- p_pop | p_juv
ggsave("dev/audit/fidelity/figs/parental_care.png", p,
       width = 12, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/parental_care.png\n")
