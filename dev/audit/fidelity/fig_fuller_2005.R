# Fuller 2005 figure — Zahavi β_Sv dose-response panel
#
# Reads dev/audit/fidelity/paper_fuller_2005.rds and writes
# vignettes/figures-papers/fuller-2005.png.
#
# Two side-by-side panels:
#   (a) signal magnitude vs mortality rate (the handicap curve)
#   (b) population size vs mortality rate (viability cost is real)

suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
})

audit <- readRDS("dev/audit/fidelity/paper_fuller_2005.rds")
runs  <- audit$sweep$runs

# Map condition → mortality rate
mort_map <- c(null_no_signals = NA_real_,
              zahavi_off      = 0.000,
              zahavi_weak     = 0.001,
              zahavi_mild     = 0.002,
              zahavi_moderate = 0.003)
runs$mortality <- mort_map[as.character(runs$condition)]

# Keep only the signals-on conditions for the dose-response curve
dose <- subset(runs, !is.na(mortality))

agg <- aggregate(cbind(final_signal, final_n) ~ mortality, data = dose,
                 FUN = function(x) c(mean = mean(x),
                                     se   = sd(x) / sqrt(length(x))))
agg <- data.frame(
  mortality     = agg$mortality,
  signal_mean   = agg$final_signal[, "mean"],
  signal_se     = agg$final_signal[, "se"],
  n_mean        = agg$final_n[, "mean"],
  n_se          = agg$final_n[, "se"]
)

p1 <- ggplot(agg, aes(x = mortality, y = signal_mean)) +
  geom_errorbar(aes(ymin = signal_mean - signal_se,
                    ymax = signal_mean + signal_se),
                width = 0.00015, colour = "grey40") +
  geom_line(colour = "#c0392b", linewidth = 0.6) +
  geom_point(size = 3, colour = "#c0392b") +
  scale_x_continuous(breaks = sort(unique(agg$mortality))) +
  labs(
    title    = "Zahavi β_Sv handicap: signal shrinks with viability cost",
    subtitle = "0.6.3 signal_cost_mortality — Fuller, Houle & Travis 2005 framework",
    x        = expression("Per-tick viability cost (" * beta[Sv] * ", i.e. " *
                          italic(signal_cost_mortality) * ")"),
    y        = "Mean signal magnitude (last 500 ticks)"
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title.position = "plot",
        panel.grid.minor    = element_blank())

p2 <- ggplot(agg, aes(x = mortality, y = n_mean)) +
  geom_errorbar(aes(ymin = pmax(0, n_mean - n_se),
                    ymax = n_mean + n_se),
                width = 0.00015, colour = "grey40") +
  geom_line(colour = "#2c3e50", linewidth = 0.6) +
  geom_point(size = 3, colour = "#2c3e50") +
  scale_x_continuous(breaks = sort(unique(agg$mortality))) +
  labs(
    title    = "Cost is real: population declines with mortality rate",
    subtitle = "Handicap is honest — high-signal agents actually die",
    x        = expression("Per-tick viability cost (" * beta[Sv] * ")"),
    y        = "Mean population size (last 500 ticks)"
  ) +
  theme_minimal(base_size = 11) +
  theme(plot.title.position = "plot",
        panel.grid.minor    = element_blank())

fig <- p1 + p2 +
  patchwork::plot_annotation(
    caption = "8 seeds per condition; error bars ±1 SE. Fuller 2005 Am Nat 166:437-446."
  )

out <- "vignettes/figures-papers/fuller-2005.png"
ggsave(out, fig, width = 10, height = 4.2, dpi = 150)
cat("Wrote:", out, "\n")
