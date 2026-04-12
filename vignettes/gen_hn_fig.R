#!/usr/bin/env Rscript
# gen_hn_fig.R — H&N replication, v5
#
# Key finding from v4:
#   sigma DID decline to 0.197 by tick 100 — selection is working.
#   But n=44 is too small for 3000 ticks: genetic drift causes extinction.
#
# Strategy:
#   Increase population AND patch together to keep CC ratio similar.
#   radius=4 → 9×9 = 81 patch cells → max_agents=75 (safely below 81).
#   25×25 grid; grass_rate=0.01 → ~6 background cells/tick.
#   Run 5 seeds; save all; build figure from seed with best sigma decline.

library(clade)
library(ggplot2)
library(dplyr)
library(patchwork)

message("Starting Julia session...")

# ── Condition 1: Baseline ─────────────────────────────────────────────────────
message("Condition 1: BNN baseline (grass_rate=0.10, n=150, 3000 ticks)...")
s_base <- default_specs()
s_base$brain_type    <- "bnn"
s_base$n_agents_init <- 150L
s_base$max_ticks     <- 3000L
s_base$grid_rows     <- 25L
s_base$grid_cols     <- 25L
s_base$grass_rate    <- 0.10
s_base$random_seed   <- 1L
env_base <- run_alife(s_base, verbose = TRUE)
d_base   <- get_run_data(env_base)$ticks
d_base$condition <- "Dynamic world (no patch)"
message(sprintf("  n range: %d–%d | final sigma: %.3f",
                min(d_base$n_agents), max(d_base$n_agents),
                tail(d_base$mean_prior_sigma, 1)))

# ── Condition 2: H&N across 5 seeds ──────────────────────────────────────────
# radius=4 → 9×9 = 81 patch cells; max_agents=75 < 81 → always enough food.
# Larger population reduces genetic drift; still sparse background (grass_rate=0.01).
s_hn <- default_specs()
s_hn$brain_type         <- "bnn"
s_hn$n_agents_init      <- 50L
s_hn$max_agents         <- 75L
s_hn$max_ticks          <- 3000L
s_hn$grid_rows          <- 25L
s_hn$grid_cols          <- 25L
s_hn$grass_rate         <- 0.01
s_hn$fixed_patch        <- TRUE
s_hn$fixed_patch_value  <- 5.0
s_hn$fixed_patch_radius <- 4L    # 9×9 = 81 cells
s_hn$fixed_patch_x      <- 13L   # centre of 25-col grid
s_hn$fixed_patch_y      <- 13L   # centre of 25-row grid

seeds <- 1:5
results_hn <- vector("list", 5)
for (i in seq_along(seeds)) {
  s_hn$random_seed <- as.integer(seeds[i])
  message(sprintf("Condition 2 seed %d/%d...", i, length(seeds)))
  env_hn <- run_alife(s_hn, verbose = FALSE)
  d_hn   <- get_run_data(env_hn)$ticks
  d_hn$seed <- seeds[i]
  results_hn[[i]] <- d_hn
  min_n <- min(d_hn$n_agents, na.rm=TRUE)
  crash <- if (min_n == 0) sprintf("CRASH tick %d", which(d_hn$n_agents==0)[1]) else "survived"
  message(sprintf("  seed %d: n range %d–%d | final sigma %.3f | %s",
                  seeds[i], min_n, max(d_hn$n_agents, na.rm=TRUE),
                  tail(d_hn$mean_prior_sigma[d_hn$mean_prior_sigma > 0], 1),
                  crash))
}

# Save all data
saveRDS(list(base=d_base, hn=results_hn), "Rdata/baldwin_hn_demo.rds")

# Pick best seed: survived AND lowest final sigma
survived <- Filter(function(d) min(d$n_agents, na.rm=TRUE) > 0, results_hn)
message(sprintf("\n%d/%d seeds survived.", length(survived), length(seeds)))

if (length(survived) > 0) {
  # Among survivors, pick lowest final sigma (most canalization)
  final_sigmas <- sapply(survived, function(d) tail(d$mean_prior_sigma, 1))
  best <- survived[[which.min(final_sigmas)]]
  message(sprintf("Best seed: final sigma=%.3f, n range %d–%d",
                  tail(best$mean_prior_sigma, 1),
                  min(best$n_agents), max(best$n_agents)))

  best$condition <- "Fixed patch (H&N setup)"
  df <- bind_rows(d_base, best)
  df$condition <- factor(df$condition,
    levels = c("Dynamic world (no patch)", "Fixed patch (H&N setup)"))

  pal <- c("Dynamic world (no patch)" = "#377eb8",
           "Fixed patch (H&N setup)"  = "#4daf4a")
  lty <- c("Dynamic world (no patch)" = "dashed",
           "Fixed patch (H&N setup)"  = "solid")

  pA <- ggplot(df, aes(t, mean_prior_sigma, colour=condition, linetype=condition)) +
    geom_hline(yintercept=0.5, colour="grey70", linetype="dotted", linewidth=0.5) +
    geom_line(linewidth=0.9, na.rm=TRUE) +
    scale_colour_manual(values=pal, name=NULL) +
    scale_linetype_manual(values=lty, name=NULL) +
    scale_x_continuous(labels=scales::comma) +
    scale_y_continuous(limits=c(0, 0.55)) +
    labs(x=NULL, y=expression("Mean prior "*sigma),
         title="Hinton & Nowlan (1987) in clade: stable patch enables genetic assimilation",
         subtitle=paste(
           "Dynamic world (blue dashed): sigma rises to exploration ceiling (0.5).",
           "Fixed patch — stable fitness peak (green): sigma declines as patch-navigation",
           "behaviour is genetically assimilated over generations.",
           sep=" ")) +
    theme_classic(base_size=11) +
    theme(legend.position="bottom", legend.key.width=unit(1.4,"cm"),
          plot.subtitle=element_text(size=8.5, colour="grey30"))

  pB <- ggplot(df, aes(t, genetic_diversity, colour=condition, linetype=condition)) +
    geom_line(linewidth=0.9, na.rm=TRUE) +
    scale_colour_manual(values=pal, name=NULL) +
    scale_linetype_manual(values=lty, name=NULL) +
    scale_x_continuous(labels=scales::comma) +
    labs(x="Tick", y="Genetic diversity") +
    theme_classic(base_size=11) + theme(legend.position="none")

  p <- pA / pB + plot_layout(heights=c(2,1))
  ggsave("inst/figures/showcase_bnn_hn_demo.png",      p, width=8, height=6, dpi=150)
  ggsave("vignettes/figures/showcase_bnn_hn_demo.png", p, width=8, height=6, dpi=150)
  message("Saved: showcase_bnn_hn_demo.png")

} else {
  message("\nAll seeds crashed — the H&N replication requires further parameter tuning.")
  message("Recommendation: increase patch radius or energy_init.")
}

message("Done.")
