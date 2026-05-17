# Griesser, Drobniak, Graber et al. (2023) reproduction
# "Parental provisioning drives brain size in birds", PNAS 120(9)
# DOI: 10.1073/pnas.2121467120
#
# Comparative claim: among bird species, longer parental
# provisioning explains variation in relative brain size. Longer
# care lets big-brained newborns survive the early-life energy
# deficit ("expensive brain + costly newborn" bootstrap problem).
#
# clade test: sweep juvenile_independence_age under
# brain_size_evolution = TRUE. Griesser predicts a positive
# monotone slope.
#
# *Methodology demo*: this script uses three clade tools:
#   1. grid_specs()  — coarse 2-D regime search over (cost_scale,
#                      care_duration) to find where the signal emerges
#   2. batch_alife() — parallel execution
#   3. hypothesis_sweep() + hypothesis_report()
#                    — clean per-cell validation at the found regime

suppressPackageStartupMessages({
  if (requireNamespace("devtools", quietly = TRUE))
    devtools::load_all(quiet = TRUE)
  else
    library(clade)
})

source("dev/audit/fidelity/_helper.R")

base <- default_specs()
base$grid_rows       <- 40L
base$grid_cols       <- 40L
base$n_agents_init   <- 150L
base$max_agents      <- 500L
base$max_ticks       <- 3000L
base$grass_rate      <- 0.20
base$n_predators_init <- 0L

base$brain_size_evolution        <- TRUE
base$brain_size_init_mean        <- 1.0
base$brain_size_mutation_sd      <- 0.05
base$neonatal_foraging_deficit   <- 0.4
base$parental_care               <- TRUE
base$feeding_rate                <- 5.0
base$care_cost_per_tick          <- 1.0

# ---------------------------------------------------------------
# Stage 1: 2-D coarse grid search over (cost_scale, care_duration)
# ---------------------------------------------------------------
cat("=== Stage 1: grid search ===\n")
cost_scales <- c(1.5, 2.0, 2.5, 3.0)
care_durs   <- c(2L, 8L, 15L, 25L)

specs_list <- grid_specs(base,
                          brain_size_cost_scale     = cost_scales,
                          juvenile_independence_age = care_durs,
                          seed_from                 = 1L)
cat(sprintf("  Grid: %d cost x %d care = %d cells, 1 seed each\n",
            length(cost_scales), length(care_durs), length(specs_list)))

t0 <- Sys.time()
results <- batch_alife(specs_list, n_cores = .fidelity_cores(default = 16L))
cat(sprintf("  Grid complete in %.1fs\n", as.numeric(difftime(Sys.time(), t0, units = "secs"))))

# Extract each run's final brain size + population + extinction
grid_tbl <- do.call(rbind, mapply(function(env, s) {
  d <- get_run_data(env)$ticks
  data.frame(
    cost_scale   = s$brain_size_cost_scale,
    care_dur     = s$juvenile_independence_age,
    final_brain  = mean(tail(d$mean_brain_size, 500L), na.rm = TRUE),
    final_n      = mean(tail(d$n_agents, 500L), na.rm = TRUE),
    crashed      = tail(d$n_agents, 1L) < 10L,
    stringsAsFactors = FALSE
  )
}, results, specs_list, SIMPLIFY = FALSE))

cat("\n  Grid results (final_brain, larger = bigger evolved brain):\n")
pivoted <- reshape(grid_tbl[, c("cost_scale", "care_dur", "final_brain")],
                   idvar = "cost_scale", timevar = "care_dur",
                   direction = "wide")
names(pivoted) <- c("cost_scale", paste0("care=", care_durs))
print(pivoted, row.names = FALSE)

cat("\n  Grid viability (final_n, crashes = near 0):\n")
pivoted_n <- reshape(grid_tbl[, c("cost_scale", "care_dur", "final_n")],
                     idvar = "cost_scale", timevar = "care_dur",
                     direction = "wide")
names(pivoted_n) <- c("cost_scale", paste0("care=", care_durs))
print(pivoted_n, row.names = FALSE)

# Select the cost_scale with the cleanest positive care_dur slope and
# no crashes. Rank by correlation(care_dur, final_brain) within each
# cost_scale row.
slope_by_cost <- do.call(rbind, lapply(cost_scales, function(cs) {
  sub <- grid_tbl[grid_tbl$cost_scale == cs, ]
  sub <- sub[order(sub$care_dur), ]
  any_crash <- any(sub$crashed)
  sp <- if (any(sub$final_brain > 0, na.rm = TRUE)) {
    cor(sub$care_dur, sub$final_brain, use = "complete.obs")
  } else NA_real_
  data.frame(cost_scale = cs, any_crash = any_crash, care_brain_cor = sp)
}))
cat("\n  Signal by cost_scale:\n")
print(slope_by_cost, row.names = FALSE)

best_cost <- slope_by_cost$cost_scale[!slope_by_cost$any_crash][
  which.max(slope_by_cost$care_brain_cor[!slope_by_cost$any_crash])
]
if (length(best_cost) == 0L || is.na(best_cost))
  best_cost <- slope_by_cost$cost_scale[which.max(slope_by_cost$care_brain_cor)]
cat(sprintf("\n  Selected regime: brain_size_cost_scale = %.1f\n", best_cost))

# ---------------------------------------------------------------
# Stage 2: hypothesis_sweep() at the found regime, 8 seeds
# ---------------------------------------------------------------
cat("\n=== Stage 2: hypothesis_sweep at selected regime ===\n")
final_base <- base
final_base$brain_size_cost_scale <- best_cost

care_levels <- c(very_short = 2L, short = 8L, medium = 15L, long = 25L)
conds <- setNames(
  lapply(care_levels, function(dur) {
    list(juvenile_independence_age = dur)
  }),
  names(care_levels)
)

sweep <- hypothesis_sweep(
  base_specs = final_base,
  conditions = conds,
  seeds = 1:8,
  metrics = list(
    final_brain = function(ticks) mean(tail(ticks$mean_brain_size, 500L), na.rm = TRUE),
    final_n     = function(ticks) mean(tail(ticks$n_agents, 500L), na.rm = TRUE),
    crashed     = function(ticks) tail(ticks$n_agents, 1L) < 10L
  ),
  n_cores = .fidelity_cores(default = 32L)
)
print(sweep)

contrasts <- list(
  short_vs_very_short  = c("very_short", "short"),
  medium_vs_very_short = c("very_short", "medium"),
  long_vs_very_short   = c("very_short", "long")
)
rpt <- hypothesis_report(sweep, contrasts, metric = "final_brain")
cat("\n=== Brain-size effects at best cost_scale ===\n")
print(rpt)

sp <- cor(as.integer(care_levels[sweep$runs$condition]),
          sweep$runs$final_brain,
          method = "spearman", use = "complete.obs")
cat(sprintf("\nSpearman(care_duration, final_brain) = %+.3f\n", sp))
cat("Griesser predict: POSITIVE monotone across the care-duration gradient.\n")

# ---------------------------------------------------------------
# Save everything
# ---------------------------------------------------------------
saveRDS(list(
  stage1_grid   = grid_tbl,
  stage1_slopes = slope_by_cost,
  best_cost     = best_cost,
  stage2_sweep  = sweep,
  stage2_report = rpt,
  stage2_spearman = sp
), "dev/audit/fidelity/paper_griesser_2023.rds")
cat("\nSaved: dev/audit/fidelity/paper_griesser_2023.rds\n")
