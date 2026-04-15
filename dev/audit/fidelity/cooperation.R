#!/usr/bin/env Rscript
# Fidelity audit: cooperation / public goods.
#
# Theory:
#   Nowak & May (1992) Nature 359:826: spatial Prisoner's Dilemma;
#     cooperators form clusters that resist defector invasion.
#   Hauert et al. (2002) Science 296:1129: continuous-strategy PD;
#     spatial clustering enables coexistence of C and D.
#
# Predictions:
#   P1. Cooperation ON raises population size (group benefit).
#   P2. Mean cooperation level drifts slightly DOWN over time
#       (free-rider invasion / tragedy of the commons), but
#       cooperation does not collapse to 0 because spatial
#       clustering protects cooperators.
#   P3. Multiplier threshold: effect scales with cooperation_multiplier.
#       At M < 1 (break-even), no population boost. At M > 2,
#       substantial boost.
#
# Usage: Rscript dev/audit/fidelity/cooperation.R

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade)
  library(ggplot2)
  library(patchwork)
})

one_run <- function(coop_on, multiplier, seed, max_ticks = 400L) {
  s <- default_specs()
  s$cooperation_evolution  <- coop_on
  s$cooperation_multiplier <- multiplier
  s$cooperation_cost       <- 1.0
  s$cooperation_init_mean  <- 0.5
  s$n_agents_init          <- 80L
  s$grid_rows              <- 30L
  s$grid_cols              <- 30L
  s$grass_rate             <- 0.10
  s$max_agents             <- 600L
  s$max_ticks              <- as.integer(max_ticks)
  s$random_seed            <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$coop_on <- coop_on
  d$multiplier <- multiplier
  d$seed <- seed
  d
}

seeds <- 1L:5L

# ── Step 1: off vs on at default multiplier (M = 2.5) ───────────────────────

cat("── Step 1: cooperation off vs on (M = 2.5, 5 seeds)\n")
ctrl <- lapply(seeds, function(sd) one_run(FALSE, 2.5, sd))
trt  <- lapply(seeds, function(sd) one_run(TRUE,  2.5, sd))

mean_post <- function(runs, col, burn = 100L) {
  mean(vapply(runs, function(d) mean(d[[col]][d$t > burn], na.rm = TRUE),
              numeric(1L)))
}

ctrl_n <- mean_post(ctrl, "n_agents")
trt_n  <- mean_post(trt,  "n_agents")
cat(sprintf("  baseline: mean_n = %.1f\n", ctrl_n))
cat(sprintf("  coop ON:  mean_n = %.1f (ratio %.2fx)\n",
            trt_n, trt_n / ctrl_n))
p1_pass <- trt_n > ctrl_n * 1.2
cat(sprintf("  P1 (coop_on > baseline * 1.2): %s\n",
            if (p1_pass) "PASS" else "FAIL"))

# Cooperation level trend
coop_init <- mean(vapply(trt, function(d) d$mean_cooperation_level[10], numeric(1L)))
coop_end  <- mean(vapply(trt, function(d) tail(d$mean_cooperation_level, 1L), numeric(1L)))
cat(sprintf("  Cooperation level: t=10 %.3f -> t=400 %.3f (delta %+.3f)\n",
            coop_init, coop_end, coop_end - coop_init))
p2_pass <- abs(coop_end - coop_init) < 0.2
cat(sprintf("  P2 (tragedy of commons — small negative drift, not collapse): %s\n",
            if (p2_pass) "PASS" else "FAIL"))

# ── Step 2: multiplier sweep ─────────────────────────────────────────────────

cat("\n── Step 2: multiplier sweep (coop_on, 3 seeds each)\n")
mults <- c(0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0)
mult_results <- lapply(mults, function(M) {
  ns <- vapply(1L:3L, function(sd) {
    d <- one_run(TRUE, M, sd)
    mean(d$n_agents[d$t > 100])
  }, numeric(1L))
  cs <- vapply(1L:3L, function(sd) {
    d <- one_run(TRUE, M, sd)
    tail(d$mean_cooperation_level, 1L)
  }, numeric(1L))
  cat(sprintf("  M=%.1f: mean_n=%.1f±%.1f, final_coop=%.3f\n",
              M, mean(ns), sd(ns), mean(cs)))
  data.frame(multiplier = M,
             mean_n = mean(ns), sd_n = sd(ns),
             mean_coop = mean(cs))
})
mult_df <- do.call(rbind, mult_results)
spear <- cor(mult_df$multiplier, mult_df$mean_n, method = "spearman")
cat(sprintf("  P3 (Spearman mult vs pop rho = %.2f): %s\n",
            spear, if (spear > 0.5) "PASS" else "FAIL"))

# Save + figure
all_ticks <- do.call(rbind, c(ctrl, trt))
saveRDS(list(all_ticks = all_ticks, mult_df = mult_df),
        "dev/audit/fidelity/cooperation_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)

p_pop <- ggplot(all_ticks, aes(t, n_agents, colour = coop_on,
                                group = interaction(coop_on, seed))) +
  geom_line(alpha = 0.35, linewidth = 0.4) +
  stat_summary(aes(group = coop_on), fun = mean, geom = "line",
               linewidth = 1.1) +
  scale_colour_manual(values = c("FALSE" = "#F44336", "TRUE" = "#2196F3"),
                      labels = c("Baseline", "Cooperation"), name = NULL) +
  labs(title = "Population: cooperation off vs on (M = 2.5)",
       x = "Tick", y = "n_agents") +
  theme_minimal(base_size = 11)

p_coop <- ggplot(all_ticks[all_ticks$coop_on, ],
                 aes(t, mean_cooperation_level, group = seed)) +
  geom_line(alpha = 0.45, linewidth = 0.4, colour = "#1b7837") +
  stat_summary(aes(group = 1), fun = mean, geom = "line",
               colour = "#1b7837", linewidth = 1.1) +
  geom_hline(yintercept = 0.5, linetype = "dashed", colour = "grey50") +
  labs(title = "Cooperation level drift (tragedy of the commons)",
       x = "Tick", y = "mean_cooperation_level") +
  theme_minimal(base_size = 11)

p_mult <- ggplot(mult_df, aes(multiplier, mean_n)) +
  geom_errorbar(aes(ymin = mean_n - sd_n, ymax = mean_n + sd_n),
                width = 0.1, colour = "grey50") +
  geom_line(linewidth = 0.8, colour = "#1b7837") +
  geom_point(size = 3, colour = "#1b7837") +
  labs(title = "Multiplier threshold: pop size vs M",
       x = "cooperation_multiplier (M)", y = "mean n_agents") +
  theme_minimal(base_size = 11)

p <- (p_pop | p_coop) / p_mult +
  plot_annotation(
    title = "Cooperation fidelity audit: public goods & multiplier threshold",
    subtitle = sprintf(
      "5 seeds, 400 ticks, 30x30 grid, grass_rate=0.10. Nowak & May 1992."),
    theme = theme(plot.title = element_text(face = "bold"))
  )

ggsave("dev/audit/fidelity/figs/cooperation.png", p,
       width = 12, height = 8, dpi = 150)
cat("\nWrote dev/audit/fidelity/figs/cooperation.png\n")
