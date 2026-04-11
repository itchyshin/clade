#!/usr/bin/env Rscript
# gen_fixed_patch_fig.R  — revised
#
# 3-condition Baldwin Effect gallery figure:
#   (1) BNN baseline:         grass_rate=0.05, no patch → σ → 0.5 (exploration ESS)
#   (2) BNN + fixed_patch:    grass_rate=0.05, patch=TRUE → σ declines (genetic assimilation)
#   (3) BNN + epigenetics:    grass_rate=0.05, epi=TRUE   → σ → 0 (TEI shortcut)
#
# grass_rate=0.05 is the same value used in the working canalization_demo
# figure, where the baseline reliably shows σ rising to 0.5.
# The fixed patch adds a permanent high-value cell that creates a stable
# fitness peak (Hinton & Nowlan 1987), allowing genetic assimilation
# without epigenetic inheritance.

library(clade)
library(ggplot2)
library(dplyr)

message("Starting clade Julia session...")

# ── Shared base specs ─────────────────────────────────────────────────────────
base <- default_specs()
base$brain_type    <- "bnn"
base$n_agents_init <- 150L
base$max_ticks     <- 1000L
base$grid_rows     <- 25L
base$grid_cols     <- 25L
base$grass_rate    <- 0.05    # same as canalization_demo — baseline gives σ→0.5
base$random_seed   <- 42L

# ── Condition 1: BNN baseline ─────────────────────────────────────────────────
message("Running condition 1: BNN baseline (grass_rate=0.05)...")
env1 <- run_alife(base, verbose = TRUE)
d1   <- get_run_data(env1)$ticks
d1$condition <- "BNN baseline"

# ── Condition 2: BNN + fixed_patch ───────────────────────────────────────────
# A 3×3 permanent patch of value 8.0 at the grid centre.
# High patch value (8 vs grass_max≈2) creates a clear fitness peak —
# agents that consistently navigate there outcompete random explorers.
message("Running condition 2: BNN + fixed_patch...")
s2 <- base
s2$fixed_patch        <- TRUE
s2$fixed_patch_value  <- 8.0
s2$fixed_patch_x      <- 13L   # column (centre of 25-col grid)
s2$fixed_patch_y      <- 13L   # row    (centre of 25-row grid)
s2$fixed_patch_radius <- 1L    # 3×3 = 9 cells
env2 <- run_alife(s2, verbose = TRUE)
d2   <- get_run_data(env2)$ticks
d2$condition <- "BNN + fixed patch"

# ── Condition 3: BNN + epigenetics ───────────────────────────────────────────
message("Running condition 3: BNN + epigenetics...")
s3 <- base
s3$epigenetics            <- TRUE
s3$epigenetic_inheritance <- 0.5
s3$methylation_rate       <- 0.2
env3 <- run_alife(s3, verbose = TRUE)
d3   <- get_run_data(env3)$ticks
d3$condition <- "BNN + epigenetics"

# ── Save RDS for inspection ───────────────────────────────────────────────────
saveRDS(list(d1=d1, d2=d2, d3=d3),
        "Rdata/baldwin_fixed_patch_demo.rds")
message("RDS saved to Rdata/baldwin_fixed_patch_demo.rds")

# Print final sigma values
message(sprintf("Final sigma — baseline: %.3f | fixed_patch: %.3f | epigenetics: %.3f",
                tail(d1$mean_prior_sigma, 1),
                tail(d2$mean_prior_sigma, 1),
                tail(d3$mean_prior_sigma, 1)))

# ── Combine and plot ──────────────────────────────────────────────────────────
df <- bind_rows(d1, d2, d3)
df$condition <- factor(df$condition,
                       levels = c("BNN baseline",
                                  "BNN + fixed patch",
                                  "BNN + epigenetics"))

pal <- c("BNN baseline"      = "#377eb8",
         "BNN + fixed patch" = "#4daf4a",
         "BNN + epigenetics" = "#e6550d")

p <- ggplot(df, aes(x = t, y = mean_prior_sigma,
                    colour = condition, linetype = condition)) +
  geom_hline(yintercept = 0.5, colour = "grey70", linetype = "dotted",
             linewidth = 0.6) +
  geom_line(linewidth = 0.95) +
  annotate("text", x = max(df$t) * 0.75, y = 0.52,
           label = "Exploration ceiling (σ = 0.5)",
           colour = "grey50", size = 3, hjust = 0) +
  scale_colour_manual(values = pal) +
  scale_linetype_manual(values = c("BNN baseline"      = "dashed",
                                   "BNN + fixed patch" = "solid",
                                   "BNN + epigenetics" = "solid")) +
  scale_x_continuous(labels = scales::comma) +
  labs(
    x        = "Tick",
    y        = expression("Mean prior " * sigma),
    colour   = NULL,
    linetype = NULL,
    title    = "The Baldwin Effect: stable landscape enables genetic assimilation",
    subtitle = paste(
      "Baseline (blue dashed): exploration ESS — no canalization in shifting landscape.",
      "Fixed patch (green): stable resource peak → genetic assimilation (σ declines).",
      "Epigenetics (orange): TEI shortcut → rapid canalization without stable landscape.",
      sep = "\n"
    )
  ) +
  theme_classic(base_size = 12) +
  theme(
    legend.position  = "bottom",
    plot.subtitle    = element_text(size = 8.5, colour = "grey30", lineheight = 1.3),
    legend.key.width = unit(1.5, "cm")
  )

# Save to both inst/figures and vignettes/figures
outname <- "showcase_bnn_fixed_patch_demo.png"
ggsave(file.path("inst/figures",      outname), p, width = 8, height = 4.5, dpi = 150)
ggsave(file.path("vignettes/figures", outname), p, width = 8, height = 4.5, dpi = 150)
message("Saved: ", outname)
message("Done.")
