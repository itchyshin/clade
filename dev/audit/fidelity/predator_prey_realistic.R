# s-predator-prey re-audit at realistic_specs() scale — aims to expose
# the canonical LV double-oscillation that the 30×30 / 1000-tick figure
# could not show because the predator guild saturates at cap.
#
# Design:
#   • realistic_specs(): 60×60, 300 init prey, 2000 max prey, 5000 ticks,
#     max_age = 50, predator_max_age = 80, grass_rate = 0.15.
#   • Predator guild tuned to be resource-limited (not cap-limited) so
#     predators cycle WITH prey: smaller predator_energy_gain, lower
#     predator_max_agents, no predator-birth subsidy.
#   • 5 seeds × 1 regime for the figure; viability_report before plotting.
#   • Output: PNG with both time series on the same axes + autocorrelation
#     and cross-correlation diagnostics.

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
  library(ggplot2)
  library(patchwork)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L)

build_spec <- function(seed) {
  s <- realistic_specs()
  s$n_predators_init          <- 40L
  s$predator_max_agents       <- 200L
  s$predator_energy_gain      <- 8.0    # small reward per kill → starvation when prey sparse
  s$predator_min_repro_energy <- 180.0  # many kills needed to reproduce
  s$predator_attack_strength  <- 30.0
  s$predator_max_age          <- 30L    # same lifespan as prey → age-based turnover
  s$random_seed               <- as.integer(seed)
  s
}

specs_list <- lapply(SEEDS, build_spec)

message(sprintf("Running %d specs at realistic_specs() scale (60x60, 5000 ticks)...",
                length(specs_list)))
t0 <- Sys.time()
results <- batch_alife(specs_list, n_cores = length(SEEDS))
message(sprintf("  batch wall: %.1f min",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))

# Pull per-tick series; guard on viability first.
per_run <- lapply(seq_along(results), function(i) {
  env <- results[[i]]
  rd  <- get_run_data(env)
  via <- viability_report(rd)
  d   <- rd$ticks
  data.frame(
    seed   = specs_list[[i]]$random_seed,
    t      = d$t,
    prey   = d$n_agents,
    pred   = d$n_predators,
    verdict = via$verdict
  )
})
tbl <- do.call(rbind, per_run)
saveRDS(tbl, "dev/audit/fidelity/predator_prey_realistic.rds")

message("\n── Viability per seed ──")
for (sd in SEEDS) {
  v <- unique(tbl$verdict[tbl$seed == sd])
  message(sprintf("  seed %2d: %s", sd, v))
}

# Cycle diagnostics on the second half of the run (post-bootstrap).
message("\n── Oscillation / cross-correlation diagnostics (t > 1000) ──")
for (sd in SEEDS) {
  one <- tbl[tbl$seed == sd & tbl$t > 1000, ]
  if (nrow(one) < 200) next
  prey_ac <- acf(one$prey, lag.max = 200, plot = FALSE)$acf[, 1, 1]
  pred_ac <- acf(one$pred, lag.max = 200, plot = FALSE)$acf[, 1, 1]
  prey_osc <- -min(prey_ac[21:101])  # magnitude of most-negative lag in [20, 100]
  pred_osc <- -min(pred_ac[21:101])
  ccf_pp   <- ccf(one$prey, one$pred, lag.max = 100, plot = FALSE)$acf[, 1, 1]
  max_ccf  <- max(ccf_pp)
  lag_max  <- which.max(ccf_pp) - 101  # center at 0
  message(sprintf(
    "  seed %2d | prey_osc=%.2f pred_osc=%.2f | max_ccf=%.2f at lag=%+d",
    sd, prey_osc, pred_osc, max_ccf, lag_max))
}

# Figure: all 5 seeds, both series on shared axes (log10 for pop).
viable <- tbl[tbl$verdict != "crashed", ]
p_ts <- ggplot(viable, aes(x = t)) +
  geom_line(aes(y = prey, colour = "Prey"),     linewidth = 0.4, alpha = 0.8) +
  geom_line(aes(y = pred, colour = "Predator"), linewidth = 0.4, alpha = 0.8) +
  facet_wrap(~ seed, ncol = 1, scales = "free_y") +
  scale_colour_manual(values = c("Prey" = "#2196F3", "Predator" = "#F44336"),
                      name = NULL) +
  labs(x = "Tick", y = "Population",
       title = "Predator-prey at realistic_specs() \u2014 60x60 grid, 2000 ticks, 5 seeds",
       subtitle = "Starvation-forcing predators (energy_gain=8, repro=180, max_age=30, grass_rate=0.20)") +
  theme_classic(base_size = 11) +
  theme(legend.position = "top")

# Phase plot (prey vs predator) for the most-oscillatory seed.
best_seed <- SEEDS[1]
one <- tbl[tbl$seed == best_seed & tbl$t > 500, ]
p_phase <- ggplot(one, aes(x = prey, y = pred, colour = t)) +
  geom_path(linewidth = 0.3, alpha = 0.7) +
  scale_colour_viridis_c(option = "plasma") +
  labs(x = "Prey population", y = "Predator population",
       title = sprintf("Phase plot (seed %d, t > 500)", best_seed)) +
  theme_classic(base_size = 11)

fig <- p_ts / p_phase + plot_layout(heights = c(3, 2))
ggsave("vignettes/figures/showcase_14_predators_lv.png",
       fig, width = 9, height = 11, dpi = 110)
message("\nWrote vignettes/figures/showcase_14_predators_lv.png")
