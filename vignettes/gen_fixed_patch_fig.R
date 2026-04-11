#!/usr/bin/env Rscript
# gen_fixed_patch_fig.R  — v3 (clean two-panel design)
#
# Problem with v2:
#   - grass_rate=0.05 with 150 agents on 25x25 caused a population bottleneck
#     (~tick 200-250), which made sigma jump sharply to 0.5 in the baseline
#     (bottleneck artifact, not exploration ESS).
#   - fixed_patch (9 cells, radius=1) too small for 150 agents: population
#     crashed completely at tick 250.
#
# Fix:
#   - Condition 1 (baseline): grass_rate=0.10 → stable population, clean
#     gradual sigma rise to 0.5 (genuine exploration ESS, no bottleneck).
#   - Condition 2 (epigenetics): same stable environment + TEI.
#   - Condition 3 (fixed patch): sparse background (grass_rate=0.02) +
#     large patch (radius=3, 7x7=49 cells) → patch is essential for survival,
#     creating genuine selection for patch-navigation genetics, but enough
#     cells to support the population without crash.
#   All three conditions share n_agents=150, 25x25 grid, 1000 ticks.
#
# Two-panel figure:
#   Top panel: mean_prior_sigma (the assimilation readout)
#   Bottom panel: genetic_diversity (pairwise genome distance)

library(clade)
library(ggplot2)
library(dplyr)
library(patchwork)

message("Starting clade Julia session...")

# ── Shared base specs ─────────────────────────────────────────────────────────
base <- default_specs()
base$brain_type    <- "bnn"
base$n_agents_init <- 150L
base$max_ticks     <- 1000L
base$grid_rows     <- 25L
base$grid_cols     <- 25L
base$random_seed   <- 42L

# ── Condition 1: BNN baseline (stable environment) ───────────────────────────
# grass_rate=0.10: abundant food, stable population (~100-200 agents),
# sigma rises gradually to 0.5 ceiling — clean exploration ESS.
message("Running condition 1: BNN baseline (grass_rate=0.10)...")
s1 <- base
s1$grass_rate <- 0.10
env1 <- run_alife(s1, verbose = TRUE)
d1   <- get_run_data(env1)$ticks
d1$condition <- "BNN baseline"
message(sprintf("  n_agents range: %d–%d | final sigma: %.3f | final GD: %.3f",
                min(d1$n_agents), max(d1$n_agents),
                tail(d1$mean_prior_sigma, 1),
                tail(d1$genetic_diversity, 1)))

# ── Condition 2: BNN + epigenetics (stable environment) ──────────────────────
message("Running condition 2: BNN + epigenetics (grass_rate=0.10)...")
s2 <- s1
s2$epigenetics            <- TRUE
s2$epigenetic_inheritance <- 0.5
s2$methylation_rate       <- 0.2
env2 <- run_alife(s2, verbose = TRUE)
d2   <- get_run_data(env2)$ticks
d2$condition <- "BNN + epigenetics"
message(sprintf("  n_agents range: %d–%d | final sigma: %.3f | final GD: %.3f",
                min(d2$n_agents), max(d2$n_agents),
                tail(d2$mean_prior_sigma, 1),
                tail(d2$genetic_diversity, 1)))

# ── Condition 3: BNN + fixed_patch (sparse background) ───────────────────────
# grass_rate=0.02: sparse background → patch is essential for survival.
# radius=3 → 7x7 = 49 cells of value=5.0 → enough food for ~50 agents/tick.
# This creates selection for genetically-encoded patch navigation, not just
# exploration as survival strategy.
message("Running condition 3: BNN + fixed_patch (grass_rate=0.02, radius=3)...")
s3 <- base
s3$grass_rate         <- 0.02
s3$fixed_patch        <- TRUE
s3$fixed_patch_value  <- 5.0
s3$fixed_patch_x      <- 13L   # centre of 25-col grid
s3$fixed_patch_y      <- 13L   # centre of 25-row grid
s3$fixed_patch_radius <- 3L    # 7×7 = 49 cells
env3 <- run_alife(s3, verbose = TRUE)
d3   <- get_run_data(env3)$ticks
d3$condition <- "BNN + fixed patch"
message(sprintf("  n_agents range: %d–%d | final sigma: %.3f | final GD: %.3f",
                min(d3$n_agents), max(d3$n_agents),
                tail(d3$mean_prior_sigma, 1),
                tail(d3$genetic_diversity, 1)))

# ── Save RDS ──────────────────────────────────────────────────────────────────
saveRDS(list(d1=d1, d2=d2, d3=d3),
        "Rdata/baldwin_fixed_patch_demo.rds")
message("RDS saved to Rdata/baldwin_fixed_patch_demo.rds")

# ── Build plot data ───────────────────────────────────────────────────────────
df <- bind_rows(d1, d2, d3)
df$condition <- factor(df$condition,
                       levels = c("BNN baseline",
                                  "BNN + fixed patch",
                                  "BNN + epigenetics"))

pal <- c("BNN baseline"      = "#377eb8",
         "BNN + fixed patch" = "#4daf4a",
         "BNN + epigenetics" = "#e6550d")
lty <- c("BNN baseline"      = "dashed",
         "BNN + fixed patch" = "solid",
         "BNN + epigenetics" = "solid")

# ── Panel A: sigma ────────────────────────────────────────────────────────────
pA <- ggplot(df, aes(t, mean_prior_sigma,
                     colour = condition, linetype = condition)) +
  geom_hline(yintercept = 0.5, colour = "grey70", linetype = "dotted",
             linewidth = 0.5) +
  geom_line(linewidth = 0.9, na.rm = TRUE) +
  scale_colour_manual(values = pal, name = NULL) +
  scale_linetype_manual(values = lty, name = NULL) +
  scale_x_continuous(labels = scales::comma) +
  scale_y_continuous(limits = c(0, 0.55)) +
  labs(x = NULL, y = expression("Mean prior " * sigma)) +
  theme_classic(base_size = 11) +
  theme(legend.position = "bottom", legend.key.width = unit(1.4, "cm"))

# ── Panel B: genetic diversity ────────────────────────────────────────────────
pB <- ggplot(df, aes(t, genetic_diversity,
                     colour = condition, linetype = condition)) +
  geom_line(linewidth = 0.9, na.rm = TRUE) +
  scale_colour_manual(values = pal, name = NULL) +
  scale_linetype_manual(values = lty, name = NULL) +
  scale_x_continuous(labels = scales::comma) +
  labs(x = "Tick", y = "Genetic diversity\n(mean pairwise genome distance)") +
  theme_classic(base_size = 11) +
  theme(legend.position = "none")

# ── Combine with patchwork ────────────────────────────────────────────────────
p <- pA / pB +
  plot_annotation(
    title    = "The Baldwin Effect: stable landscape enables genetic assimilation",
    subtitle = paste(
      "Top: BNN prior sigma (exploration vs. canalization readout).",
      "Baseline stays at 0.5 ceiling; fixed patch and epigenetics drive sigma down.",
      "Bottom: pairwise genome distance — canalized populations converge genetically.",
      sep = " "
    ),
    theme = theme(
      plot.title    = element_text(size = 12, face = "bold"),
      plot.subtitle = element_text(size = 8.5, colour = "grey30")
    )
  )

# ── Save ──────────────────────────────────────────────────────────────────────
outname <- "showcase_bnn_fixed_patch_demo.png"
ggsave(file.path("inst/figures",      outname), p,
       width = 8, height = 6, dpi = 150)
ggsave(file.path("vignettes/figures", outname), p,
       width = 8, height = 6, dpi = 150)
message("Saved: ", outname)
message("Done.")
