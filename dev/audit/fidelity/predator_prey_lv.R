# s-predator-prey discovery experiment: do we get textbook LV when
# predator evolution is frozen?
#
# Hypothesis: textbook Lotka-Volterra cycles require non-evolving
# predators with a per-capita attack rate that depends only on prey
# density (not on accumulated hunting skill). clade's evolving
# predators saturate at cap within ~30 ticks, so LV is not achievable
# in the default regime. Freezing predator evolution
# (predator_mutation_sd = 0) should expose LV-like cycles.
#
# Design: realistic_specs() with predators on. Two conditions:
#   - evolving: predator_mutation_sd = 0.1 (default)
#   - frozen:   predator_mutation_sd = 0.0
# 5 seeds each. Measure autocorrelation of prey (LV signature) and
# cross-correlation of prey × predator (quarter-cycle lag).

suppressPackageStartupMessages({
  .libPaths(c("~/R/lib", .libPaths()))
  if (file.exists("DESCRIPTION")) devtools::load_all(".", quiet = TRUE)
  else                            library(clade)
  library(ggplot2)
  library(patchwork)
})

SEEDS <- c(1L, 7L, 13L, 19L, 25L)

build_spec <- function(pred_mut_sd, pred_max_age, pred_cap, seed) {
  s <- realistic_specs()
  s$n_predators_init          <- 30L
  s$predator_max_agents       <- as.integer(pred_cap)
  s$predator_energy_gain      <- 15.0    # tighter food budget than default
  s$predator_min_repro_energy <- 150.0   # reproduction harder; more turnover
  s$predator_attack_strength  <- 40.0
  s$predator_max_age           <- as.integer(pred_max_age)
  s$predator_mutation_sd      <- pred_mut_sd
  s$random_seed               <- as.integer(seed)
  s
}

# Four conditions. Each removes the max_agents cap so predator
# population tracks food availability instead of saturating.
#   1. evolving : default pred mutation, moderate lifespan.
#   2. frozen   : predator_mutation_sd = 0 — closest to "fixed attack".
#   3. longlived: predator_max_age = 300 (slow-pace-of-life predator,
#                 lynx>hare, owl>mouse). Slower evolution per tick.
#   4. fast_turnover : short-lived predators (max_age=20) with easy
#                 reproduction (min_repro_energy=60). Classical LV
#                 requires fast turnover so deaths track prey density
#                 rather than brain quality.
specs_list <- c(
  lapply(SEEDS, function(sd) build_spec(0.1, 60L,  9999L, sd)),
  lapply(SEEDS, function(sd) build_spec(0.0, 60L,  9999L, sd)),
  lapply(SEEDS, function(sd) build_spec(0.1, 300L, 9999L, sd))
)
# Fast-turnover condition overrides min_repro_energy and max_age via a
# separate builder.
build_fast_turnover <- function(seed) {
  s <- realistic_specs()
  s$n_predators_init          <- 40L
  s$predator_max_agents       <- 9999L
  s$predator_energy_gain      <- 30.0
  s$predator_min_repro_energy <- 60.0    # easy reproduction
  s$predator_attack_strength  <- 40.0
  s$predator_max_age          <- 20L     # short-lived (below prey life)
  s$predator_mutation_sd      <- 0.0     # frozen
  s$random_seed               <- as.integer(seed)
  s
}
specs_list <- c(specs_list, lapply(SEEDS, build_fast_turnover))
conditions <- c(rep("evolving",      length(SEEDS)),
                rep("frozen",        length(SEEDS)),
                rep("longlived",     length(SEEDS)),
                rep("fast_turnover", length(SEEDS)))

message(sprintf("Running %d specs (2 conds x 5 seeds)...", length(specs_list)))
t0 <- Sys.time()
results <- batch_alife(specs_list, n_cores = length(specs_list))
message(sprintf("  batch wall: %.1f min",
                as.numeric(difftime(Sys.time(), t0, units = "mins"))))

# Extract per-tick series from every run.
per_tick <- do.call(rbind, lapply(seq_along(results), function(i) {
  env <- results[[i]]
  rd  <- get_run_data(env)
  d   <- rd$ticks
  data.frame(
    condition = conditions[i],
    seed      = specs_list[[i]]$random_seed,
    t         = d$t,
    prey      = d$n_agents,
    pred      = d$n_predators
  )
}))
saveRDS(per_tick, "dev/audit/fidelity/predator_prey_lv.rds")

# ── Oscillation diagnostics (post-bootstrap, t >= 500) ───────────────
diag_rows <- list()
for (cnd in unique(per_tick$condition)) for (sd in unique(per_tick$seed)) {
  sub <- per_tick[per_tick$condition == cnd & per_tick$seed == sd &
                  per_tick$t >= 500, ]
  if (nrow(sub) < 200 || var(sub$pred) == 0) {
    prey_osc <- NA_real_; pred_osc <- NA_real_; max_ccf <- NA_real_
    lag_max <- NA_integer_
  } else {
    prey_ac <- acf(sub$prey, lag.max = 300, plot = FALSE)$acf[, 1, 1]
    pred_ac <- acf(sub$pred, lag.max = 300, plot = FALSE)$acf[, 1, 1]
    prey_osc <- -min(prey_ac[21:201])
    pred_osc <- -min(pred_ac[21:201])
    ccf_vals <- ccf(sub$prey, sub$pred, lag.max = 100, plot = FALSE)$acf[, 1, 1]
    max_ccf  <- max(ccf_vals)
    lag_max  <- which.max(ccf_vals) - 101
  }
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(
    condition = cnd, seed = sd,
    prey_osc = prey_osc, pred_osc = pred_osc,
    max_ccf  = max_ccf,  lag_at_max_ccf = lag_max,
    prey_var = var(sub$prey), pred_var = var(sub$pred)
  )
}
diag <- do.call(rbind, diag_rows)
saveRDS(diag, "dev/audit/fidelity/predator_prey_lv_diag.rds")

message("\n── Oscillation diagnostics (t >= 500) ──")
print(diag)

message("\n── Per-condition summary ──")
for (cnd in c("evolving", "frozen")) {
  sub <- diag[diag$condition == cnd, ]
  message(sprintf(
    "  %-9s prey_osc=%.2f ± %.2f | pred_osc=%.2f ± %.2f | pred_var=%.0f",
    cnd,
    mean(sub$prey_osc, na.rm = TRUE), sd(sub$prey_osc, na.rm = TRUE),
    mean(sub$pred_osc, na.rm = TRUE), sd(sub$pred_osc, na.rm = TRUE),
    mean(sub$pred_var, na.rm = TRUE)))
}

# ── Figure: time series + phase plot for one exemplar seed ───────────
exemplar_seed <- SEEDS[1]
ts_df <- per_tick[per_tick$seed == exemplar_seed, ]

p_ts <- ggplot(ts_df, aes(x = t)) +
  geom_line(aes(y = prey, colour = "Prey"),     linewidth = 0.4) +
  geom_line(aes(y = pred, colour = "Predator"), linewidth = 0.4) +
  facet_wrap(~ condition, ncol = 1, scales = "free_y",
             labeller = as_labeller(c(
               evolving      = "evolving predators (default): arms-race to cap",
               frozen        = "frozen: predator_mutation_sd = 0",
               longlived     = "longlived: slow-pace-of-life predator (max_age=300)",
               fast_turnover = "fast turnover: short-lived, easy reproduction (LV-canonical)"))) +
  scale_colour_manual(values = c("Prey" = "#2196F3", "Predator" = "#F44336"),
                      name = NULL) +
  labs(x = "Tick", y = "Population",
       title = sprintf("Predator-prey: evolving vs frozen predators (seed %d)",
                       exemplar_seed),
       subtitle = "If LV cycles emerge, expect both series to oscillate with a ~quarter-cycle predator lag") +
  theme_classic(base_size = 11) +
  theme(legend.position = "top")

# Phase plot of the fast-turnover condition (LV attractor if cycle forms)
ph_df <- ts_df[ts_df$condition == "fast_turnover" & ts_df$t > 500, ]
p_phase <- ggplot(ph_df, aes(x = prey, y = pred, colour = t)) +
  geom_path(linewidth = 0.3, alpha = 0.7) +
  scale_colour_viridis_c(option = "plasma") +
  labs(x = "Prey population", y = "Predator population",
       title = "Phase plot — fast-turnover predators (t > 500)",
       subtitle = "LV attractor = closed loops; saturation = horizontal line") +
  theme_classic(base_size = 11)

fig <- p_ts / p_phase + plot_layout(heights = c(3, 2))
ggsave("vignettes/figures/showcase_14b_predators_lv_comparison.png",
       fig, width = 9, height = 11, dpi = 110)
message("\nWrote vignettes/figures/showcase_14b_predators_lv_comparison.png")
