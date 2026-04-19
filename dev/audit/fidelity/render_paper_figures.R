# Render ggplot figures for each paper-reproduction vignette from
# the stored .rds outputs. PNGs written to vignettes/figures-papers/
# and referenced in the Rmds via knitr::include_graphics.

suppressPackageStartupMessages({
  library(ggplot2)
})

dir.create("vignettes/figures-papers", recursive = TRUE, showWarnings = FALSE)
fig_dir <- "vignettes/figures-papers"
png_opts <- list(width = 7, height = 4.5, dpi = 150, units = "in")

save_gg <- function(p, name) {
  path <- file.path(fig_dir, paste0(name, ".png"))
  ggsave(path, plot = p, width = png_opts$width,
         height = png_opts$height, dpi = png_opts$dpi,
         units = png_opts$units, bg = "white")
  cat(sprintf("  wrote %s\n", path))
}

my_theme <- function() {
  theme_minimal(base_size = 12) +
    theme(panel.grid.minor = element_blank(),
          plot.title.position = "plot",
          legend.position = "bottom")
}

# ---------- K&B 2003 ----------
cat("=== Kokko & Brooks 2003 ===\n")
kb <- readRDS("dev/audit/fidelity/kokko_brooks_2003.rds")
kb_df <- kb$stage2_sweep$runs
kb_df$signals <- ifelse(grepl("with_signals", kb_df$condition),
                        "Signals ON", "Signals OFF")
kb_df$grass <- gsub("_(no|with)_signals$", "", kb_df$condition)
kb_df$grass <- factor(kb_df$grass,
                      levels = c("abundant", "mid", "scarce", "very_scarce"),
                      labels = c("0.20", "0.12", "0.08", "0.05"))

p_kb <- ggplot(kb_df, aes(x = grass, y = final_n,
                          fill = signals, colour = signals)) +
  geom_boxplot(alpha = 0.7, width = 0.6) +
  geom_point(position = position_jitterdodge(jitter.width = 0.15), size = 1.8) +
  scale_fill_manual(values = c("Signals OFF" = "#4575b4",
                               "Signals ON"  = "#d73027")) +
  scale_colour_manual(values = c("Signals OFF" = "#4575b4",
                                 "Signals ON"  = "#d73027")) +
  labs(x = "Grass rate (environmental stress →)",
       y = "Final population size (last 500 ticks)",
       fill = NULL, colour = NULL,
       title = "Kokko & Brooks 2003 — signals × stress 2×4 factorial",
       subtitle = "signals_effect SHRINKS as grass drops (opposite of K&B's interaction)") +
  my_theme()
save_gg(p_kb, "kokko-brooks-2003")

# ---------- Griesser 2023 ----------
cat("\n=== Griesser 2023 ===\n")
gr <- readRDS("dev/audit/fidelity/paper_griesser_2023.rds")
# Stage 1: grid heatmap
g1 <- gr$stage1_grid
p_gr1 <- ggplot(g1, aes(x = factor(care_dur), y = factor(cost_scale),
                        fill = final_brain)) +
  geom_tile(colour = "white", linewidth = 0.8) +
  geom_text(aes(label = sprintf("%.3f", final_brain)),
            size = 3.5, colour = "black") +
  scale_fill_gradient2(low = "#313695", mid = "#ffffbf",
                       high = "#a50026", midpoint = 1.0,
                       name = "evolved\nbrain size") +
  labs(x = "juvenile_independence_age",
       y = "brain_size_cost_scale",
       title = "Griesser 2023 — Stage 1: grid search (single seed)",
       subtitle = "cost_scale = 1.5 gives the strongest monotone gradient across care duration") +
  my_theme() +
  theme(panel.grid = element_blank())
save_gg(p_gr1, "griesser-2023-stage1")

# Stage 2: boxplot of evolved brain at best cost_scale
if (!is.null(gr$stage2_sweep)) {
  gr2 <- gr$stage2_sweep$runs
  gr2$condition <- factor(gr2$condition,
                           levels = c("very_short", "short", "medium", "long"))
  p_gr2 <- ggplot(gr2, aes(x = condition, y = final_brain)) +
    geom_boxplot(fill = "#91cf60", alpha = 0.7) +
    geom_point(size = 2, alpha = 0.7) +
    labs(x = "Care duration (juvenile_independence_age)",
         y = "Mean evolved brain size",
         title = "Griesser 2023 — Stage 2: multi-seed validation at cost_scale = 1.5",
         subtitle = sprintf("Spearman = %+.3f — direction-correct sub-threshold",
                            gr$stage2_spearman)) +
    my_theme()
  save_gg(p_gr2, "griesser-2023-stage2")
}

# ---------- Dieckmann & Doebeli 1999 ----------
cat("\n=== Dieckmann & Doebeli 1999 ===\n")
dd <- readRDS("dev/audit/fidelity/paper_dieckmann_doebeli_1999.rds")
dd_sw <- dd$sweep
dd2 <- dd_sw$runs
dd_spear <- dd$spearman
dd2$condition <- factor(dd2$condition,
                         levels = c("stringent_th50", "moderate_th30",
                                    "permissive_th15", "very_permissive_th05"),
                         labels = c("stringent (0.50)", "moderate (0.30)",
                                    "permissive (0.15)", "very permissive (0.05)"))
p_dd <- ggplot(dd2, aes(x = condition, y = final_species)) +
  geom_boxplot(fill = "#fc8d59", alpha = 0.7) +
  geom_point(size = 2, alpha = 0.7) +
  labs(x = "isolation_threshold",
       y = "Final number of species",
       title = "Dieckmann & Doebeli 1999 — sympatric speciation",
       subtitle = sprintf("Clean ✅: permissive vs stringent t = +3.32 PASS, Spearman = %+.2f",
                          dd_spear)) +
  my_theme() +
  theme(axis.text.x = element_text(angle = 15, hjust = 1))
save_gg(p_dd, "dieckmann-doebeli-1999")

# ---------- Réale 2010 ----------
cat("\n=== Réale 2010 ===\n")
re <- readRDS("dev/audit/fidelity/paper_reale_2010.rds")
re_df <- re$sweep$runs
rates <- c(slow = 0.5, mid_slow = 0.8, mid = 1.0, mid_fast = 1.5, fast = 2.0)
re_df$rate <- as.numeric(rates[re_df$condition])

# Four-panel: mean_age, births, energy, final_n
re_long <- tidyr::pivot_longer(re_df,
                               cols = c(mean_age, births_per_tick,
                                        mean_energy, final_n),
                               names_to = "trait", values_to = "value")
re_long$trait <- factor(re_long$trait,
                         levels = c("mean_age", "births_per_tick",
                                    "mean_energy", "final_n"),
                         labels = c("mean_age (lifespan)",
                                    "births_per_tick",
                                    "mean_energy",
                                    "final_n (population)"))
p_re <- ggplot(re_long, aes(x = rate, y = value)) +
  geom_smooth(method = "loess", se = TRUE, colour = "#4575b4",
              fill = "#abd9e9", alpha = 0.4, linewidth = 0.8) +
  geom_point(alpha = 0.6, size = 1.6) +
  facet_wrap(~ trait, scales = "free_y") +
  labs(x = "Metabolic rate",
       y = "Trait value",
       title = "Réale 2010 — pace-of-life syndrome",
       subtitle = sprintf("Core lifespan claim: Spearman = %+.3f (decisive ✅)",
                          re$spearmans$age)) +
  my_theme()
save_gg(p_re, "reale-2010")

# ---------- Emlen 1982 ----------
cat("\n=== Emlen 1982 ===\n")
em <- readRDS("dev/audit/fidelity/paper_emlen_1982.rds")
em_df <- em$sweep$runs
em_df$grass <- as.numeric(c(abundant = 0.25, moderate_abund = 0.15,
                             scarce = 0.10, very_scarce = 0.06)[em_df$condition])
# Two-panel: raw events + per-capita
em_df$per_capita <- em_df$total_helper_events /
                    (em_df$final_n * 3000) * 1000
em_long <- data.frame(
  grass = rep(em_df$grass, 2L),
  value = c(em_df$total_helper_events, em_df$per_capita),
  metric = rep(c("Raw total helper events\n(aggregate — inverts Emlen's direction)",
                  "Per-capita rate\n(events / agent / 1000 ticks — recovers Emlen)"),
                each = nrow(em_df))
)
p_em <- ggplot(em_long, aes(x = grass, y = value)) +
  geom_smooth(method = "loess", se = TRUE, colour = "#d73027",
              fill = "#fdae61", alpha = 0.4, linewidth = 0.8) +
  geom_point(alpha = 0.6, size = 1.8) +
  facet_wrap(~ metric, scales = "free_y") +
  scale_x_reverse() +
  labs(x = "Resource abundance (grass_rate) — scarce is right, abundant is left",
       y = "Value",
       title = "Emlen 1982 — ecological constraints on helping",
       subtitle = "Aggregate vs per-capita split: units matter for interpretation") +
  my_theme()
save_gg(p_em, "emlen-1982")

cat("\nAll figures rendered to", fig_dir, "\n")
