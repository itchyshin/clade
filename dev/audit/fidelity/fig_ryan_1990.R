# Ryan 1990 figure — sensory bias dose-response on preferences
# (and null on signals — the linkage-gap signature).

suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
})

audit <- readRDS("dev/audit/fidelity/paper_ryan_1990.rds")
runs  <- audit$runs

agg <- aggregate(cbind(mean_pref_d1, mean_sig_d1) ~ bias_strength,
                 data = runs,
                 FUN = function(x) c(mean = mean(x),
                                     se   = sd(x) / sqrt(length(x))))
df <- data.frame(
  bias_strength = agg$bias_strength,
  pref_mean = agg$mean_pref_d1[, "mean"],
  pref_se   = agg$mean_pref_d1[, "se"],
  sig_mean  = agg$mean_sig_d1[, "mean"],
  sig_se    = agg$mean_sig_d1[, "se"]
)

p1 <- ggplot(df, aes(x = bias_strength, y = pref_mean)) +
  geom_hline(yintercept = 1, linetype = "dashed", colour = "grey60") +
  geom_errorbar(aes(ymin = pref_mean - pref_se,
                    ymax = pref_mean + pref_se),
                width = 0.004, colour = "grey40") +
  geom_line(colour = "#2c7bb6", linewidth = 0.6) +
  geom_point(size = 3, colour = "#2c7bb6") +
  annotate("text", x = 0.10, y = 1.02, label = "target = 1",
           hjust = 1, colour = "grey50", size = 3) +
  scale_x_continuous(breaks = sort(unique(df$bias_strength))) +
  ylim(-0.1, 1.1) +
  labs(
    title    = "H1 ✅ Preference tracks pre-existing bias (β_N installed)",
    subtitle = "t = 4.75, p = 0.0003 — Fuller β_N mechanism reproduced",
    x        = expression("Bias strength κ  (" * italic(preference_bias_strength) * ")"),
    y        = expression("Mean preference, dimension 1")
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title.position = "plot",
        panel.grid.minor    = element_blank())

p2 <- ggplot(df, aes(x = bias_strength, y = sig_mean)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey60") +
  geom_errorbar(aes(ymin = sig_mean - sig_se,
                    ymax = sig_mean + sig_se),
                width = 0.004, colour = "grey40") +
  geom_line(colour = "#d7191c", linewidth = 0.6) +
  geom_point(size = 3, colour = "#d7191c") +
  scale_x_continuous(breaks = sort(unique(df$bias_strength))) +
  ylim(-0.1, 1.1) +
  labs(
    title    = "H2 ❌ Signal response null (direction-correct, sub-threshold)",
    subtitle = "t = -0.36, p = 0.73 — linkage-gap bottleneck, Ryan punch-line not closed",
    x        = expression("Bias strength κ  (" * italic(preference_bias_strength) * ")"),
    y        = expression("Mean signal, dimension 1")
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title.position = "plot",
        panel.grid.minor    = element_blank())

fig <- p1 + p2 +
  patchwork::plot_annotation(
    caption = "4 seeds per condition; 3000 ticks; bias_target = [1, 0, 0]. Ryan 1990 Oxford Surv Evol Biol 7:157-195."
  )

out <- "vignettes/figures-papers/ryan-1990.png"
ggsave(out, fig, width = 10, height = 4.2, dpi = 150)
cat("Wrote:", out, "\n")
