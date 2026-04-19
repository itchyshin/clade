# s-niche heritable-feedback sweep — does `shelter_occupancy_bonus`
# close the Odling-Smee loop?
#
# Citation-audit ⚠️ for s-niche: the vignette fires the construction
# mechanism (agents build shelters, predator damage reduced on
# sheltered cells) but the full Odling-Smee et al. 2003 prediction —
# that niche construction creates a **heritable feedback** in which
# the built environment rewards the builders' lineage — is not tested
# at default parameters, because `shelter_occupancy_bonus = 0` means
# occupying a shelter confers no energy benefit.
#
# The occupancy-bonus parameter (added in v0.3.0) is exactly the
# heritable-feedback hook: when > 0, agents on sheltered cells gain
# `bonus × depth` energy per tick. Because offspring tend to appear
# near their parents (and near their parents' built shelters), this
# creates a kin-structured inheritance of the built environment —
# which is the Odling-Smee prediction.
#
# Hypothesis: population size should rise monotonically with
# `shelter_occupancy_bonus` across a reasonable range, when
# predators are present to give shelter-construction biological
# meaning. At bonus = 0, we should see mechanism-only baseline.

suppressPackageStartupMessages({
  library(clade)
})

cat("Loaded clade — Julia will boot on first run_alife()\n")

# --- Design ----------------------------------------------------------
# 5 conditions × 8 seeds = 40 runs
# C1 = no niche construction (control — no shelters at all)
# C2 = NC on, bonus = 0 (mechanism only, vignette default)
# C3 = NC on, bonus = 1 (weak heritable feedback)
# C4 = NC on, bonus = 3 (moderate)
# C5 = NC on, bonus = 5 (strong)
conditions <- list(
  control     = list(nc = FALSE, bonus = 0.0),
  nc_bonus0   = list(nc = TRUE,  bonus = 0.0),
  nc_bonus1   = list(nc = TRUE,  bonus = 1.0),
  nc_bonus3   = list(nc = TRUE,  bonus = 3.0),
  nc_bonus5   = list(nc = TRUE,  bonus = 5.0)
)
seeds <- 1:8L

make_specs <- function(cond, seed) {
  s <- default_specs()
  s$grid_rows       <- 40L
  s$grid_cols       <- 40L
  s$n_agents_init   <- 100L
  s$max_agents      <- 400L
  s$max_ticks       <- 2000L
  s$grass_rate      <- 0.15

  # Predators on — gives shelter-construction biological relevance
  s$n_predators_init <- 5L

  # Niche construction module
  s$niche_construction       <- cond$nc
  s$shelter_build_prob       <- 0.1
  s$shelter_min_energy       <- 40.0
  s$shelter_max_depth        <- 5L
  s$shelter_decay_rate       <- 0.02
  s$shelter_occupancy_bonus  <- cond$bonus  # key parameter

  s$random_seed <- as.integer(seed)
  s
}

spec_list <- list()
for (cname in names(conditions)) for (sd in seeds) {
  nm <- sprintf("%s_seed%d", cname, sd)
  spec_list[[nm]] <- make_specs(conditions[[cname]], sd)
}
cat(sprintf("Built %d specs (5 conditions × 8 seeds × 2000 ticks, 5 predators)\n",
            length(spec_list)))

# --- Run ------------------------------------------------------------
n_cores <- min(40L, length(spec_list))
t_start <- Sys.time()
results <- batch_alife(spec_list, n_cores = n_cores, verbose = FALSE)
t_elapsed <- difftime(Sys.time(), t_start, units = "mins")
cat(sprintf("Sweep complete in %.1f min\n", as.numeric(t_elapsed)))

# --- Collect --------------------------------------------------------
collect_row <- function(env, name) {
  d <- get_run_data(env)$ticks
  last_window <- tail(d, 500L)
  parts <- strsplit(name, "_seed")[[1]]
  condname <- parts[1]
  seed     <- as.integer(parts[2])
  bonus    <- conditions[[condname]]$bonus
  nc       <- conditions[[condname]]$nc
  data.frame(
    condition = condname,
    nc        = nc,
    bonus     = bonus,
    seed      = seed,
    final_n         = mean(last_window$n_agents, na.rm = TRUE),
    final_energy    = mean(last_window$mean_energy, na.rm = TRUE),
    n_shelters_built_total = sum(d$n_shelters_built, na.rm = TRUE),
    n_agents_final_tick    = d$n_agents[nrow(d)],
    stringsAsFactors = FALSE
  )
}
rows <- mapply(collect_row, results, names(results), SIMPLIFY = FALSE)
df   <- do.call(rbind, rows); rownames(df) <- NULL
cat("\n--- Per-run results ---\n"); print(df, row.names = FALSE)

# --- Aggregate -----------------------------------------------------
agg <- aggregate(cbind(final_n, final_energy, n_shelters_built_total) ~ condition + bonus + nc,
                 data = df, FUN = mean)
agg_se <- aggregate(cbind(final_n, final_energy) ~ condition + bonus + nc,
                    data = df, FUN = function(x) sd(x) / sqrt(length(x)))
agg$final_n_se <- agg_se$final_n
agg$final_energy_se <- agg_se$final_energy
agg <- agg[order(agg$nc, agg$bonus),]
cat("\n--- Aggregated across seeds ---\n"); print(agg, row.names = FALSE)

# --- Key comparison: nc_bonus0 (mechanism-only) vs nc_bonusX (heritable feedback)
base_n <- df$final_n[df$condition == "nc_bonus0"]
for (tgt in c("nc_bonus1", "nc_bonus3", "nc_bonus5")) {
  tgt_n <- df$final_n[df$condition == tgt]
  delta <- mean(tgt_n) - mean(base_n)
  se    <- sqrt((sd(tgt_n)^2 + sd(base_n)^2) / length(tgt_n))
  tval  <- delta / se
  cat(sprintf("Δn (%s − nc_bonus0) = %+.2f ± %.2f, t = %+.2f %s\n",
              tgt, delta, se, tval,
              if (abs(tval) >= 2) "PASS" else if (abs(tval) >= 1.5) "marginal" else "null"))
}

# --- Spearman across positive-bonus conditions only
nc_df <- df[df$nc == TRUE,]
sp <- cor(nc_df$bonus, nc_df$final_n, method = "spearman")
cat(sprintf("\nSpearman(bonus, final_n) across NC-on conditions: %.3f\n", sp))

saveRDS(list(df = df, agg = agg, conditions = conditions,
             design = list(seeds = seeds, ticks = 2000L,
                           grid = "40x40", n_predators = 5L)),
        "dev/audit/fidelity/niche_heritable_feedback_sweep.rds")
cat("\nSaved: dev/audit/fidelity/niche_heritable_feedback_sweep.rds\n")
