#!/usr/bin/env Rscript
# Fidelity audit: Baldwin Effect / BNN uncertainty canalization.
# Prediction: mean_prior_sigma declines over time in stable environments
#            (genetic assimilation of learned behaviour).
#
# 0.4.1 update: pair Tier 5A `bnn_sigma_source = "trait"` with the new
# Tier 5C `brain_energy_sigma_scale > 0` plasticity cost. Together they
# decouple sigma from heterozygosity and give sigma an energetic cost,
# which is what selection needs to canalise behaviour (Baldwin 1896;
# Hinton & Nowlan 1987). Pre-0.4.1 verdict was 🔴 contradicts — sigma
# rose to the cap instead of falling.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  library(clade); library(ggplot2); library(patchwork)
})

one_run <- function(seasonal_amp, sigma_scale, seed, max_ticks = 800L) {
  s <- default_specs()
  s$brain_type                 <- "bnn"
  # 0.4.1: use trait-mode sigma with phenotypic_plasticity on so the
  # prior width is evolvable. Add the Tier 5C cost.
  s$bnn_sigma_source           <- "trait"
  s$phenotypic_plasticity      <- TRUE
  s$plasticity_init_mean       <- 0.4
  s$plasticity_mutation_sd     <- 0.05   # keep 0.4.1 value; 0.08 reversed direction at 1500 ticks
  s$brain_energy_sigma_scale   <- sigma_scale
  s$seasonal_amplitude         <- seasonal_amp
  s$season_length              <- 50L
  s$n_agents_init              <- 100L
  s$grid_rows                  <- 30L
  s$grid_cols                  <- 30L
  s$grass_rate                 <- 0.12
  s$max_agents                 <- 400L
  s$max_ticks                  <- as.integer(max_ticks)
  s$random_seed                <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d <- get_run_data(env)$ticks
  d$seasonal_amp <- seasonal_amp
  d$sigma_scale  <- sigma_scale
  d$seed         <- seed
  d
}

seeds  <- 1L:3L
# 0.4.2 update: longer runs + stronger cost. Pre-0.4.1 was at 0.05 max with
# direction-correct but tiny magnitude (~0.004). Plan expects 3× magnitude
# growth at 0.10 cost over 1500 ticks (2.5× the ticks × 2× the cost gradient).
scales <- c(0.0, 0.05, 0.10)
TICKS  <- 1500L
cat(sprintf("── Baldwin audit (0.4.2): %d scales × 2 envs × %d seeds × %d ticks\n",
            length(scales), length(seeds), TICKS))

all_runs <- list()
for (sc in scales) {
  for (amp in c(0.0, 0.8)) {
    for (sd in seeds) {
      cat(sprintf("  scale=%.2f amp=%.1f seed=%d\n", sc, amp, sd))
      all_runs[[length(all_runs) + 1L]] <- one_run(amp, sc, sd,
                                                   max_ticks = TICKS)
    }
  }
}

fin_s  <- function(d) tail(d$mean_prior_sigma, 1L)
init_s <- function(d) d$mean_prior_sigma[1]

summary_rows <- list()
for (sc in scales) {
  for (amp in c(0.0, 0.8)) {
    subset <- Filter(function(d) d$sigma_scale[1] == sc &&
                                  d$seasonal_amp[1] == amp, all_runs)
    deltas <- sapply(subset, function(d) fin_s(d) - init_s(d))
    summary_rows[[length(summary_rows) + 1L]] <- data.frame(
      sigma_scale = sc, amp = amp,
      delta_mean = mean(deltas), delta_sd = sd(deltas),
      final_mean = mean(sapply(subset, fin_s))
    )
  }
}
summary <- do.call(rbind, summary_rows)

cat("\nSummary (Δ = final - init sigma, 3 seeds):\n")
print(summary)

# P1: at sigma_scale > 0 in stable env, Δ should be negative
#     (canalization — sigma declines).
p1_pass <- FALSE
for (sc in scales[scales > 0]) {
  row <- summary[summary$sigma_scale == sc & summary$amp == 0, ]
  if (row$delta_mean < -0.02) { p1_pass <- TRUE; break }
}
cat(sprintf("\nP1 (canalization in stable env at some sigma_scale>0): %s\n",
            if (p1_pass) "PASS" else "FAIL"))

# P2: at sigma_scale > 0, seasonal should preserve sigma better than stable
p2_pass <- FALSE
for (sc in scales[scales > 0]) {
  stab_row <- summary[summary$sigma_scale == sc & summary$amp == 0,   ]
  seas_row <- summary[summary$sigma_scale == sc & summary$amp == 0.8, ]
  if (seas_row$delta_mean > stab_row$delta_mean + 0.01) {
    p2_pass <- TRUE; break
  }
}
cat(sprintf("P2 (seasonal preserves sigma vs stable): %s\n",
            if (p2_pass) "PASS" else "FAIL"))

all_ticks <- do.call(rbind, all_runs)
all_ticks$cond <- sprintf("sc=%.2f_%s", all_ticks$sigma_scale,
                           ifelse(all_ticks$seasonal_amp == 0,
                                  "stable", "seasonal"))
saveRDS(list(all_ticks = all_ticks, summary = summary),
        "dev/audit/fidelity/baldwin_results.rds")

dir.create("dev/audit/fidelity/figs", showWarnings = FALSE, recursive = TRUE)
all_ticks$env_label <- ifelse(all_ticks$seasonal_amp == 0,
                                "stable", "seasonal (amp=0.8)")
p <- ggplot(all_ticks,
            aes(t, mean_prior_sigma, colour = env_label,
                group = interaction(cond, seed))) +
  geom_line(alpha = 0.4, linewidth = 0.35) +
  stat_summary(aes(group = env_label), fun = mean, geom = "line",
               linewidth = 1.0) +
  facet_wrap(~sigma_scale, labeller = label_both) +
  scale_colour_manual(values = c(stable = "#2166ac",
                                  `seasonal (amp=0.8)` = "#e41a1c"),
                      name = NULL) +
  labs(title = "Baldwin Effect (0.4.1): sigma-cost dose-response",
       subtitle = "sigma declines under energetic cost; seasonal env preserves sigma",
       x = "Tick", y = "mean_prior_sigma") +
  theme_minimal(base_size = 11)
ggsave("dev/audit/fidelity/figs/baldwin.png", p,
       width = 12, height = 5, dpi = 150)
cat("Wrote dev/audit/fidelity/figs/baldwin.png\n")
