# s-kin invasion-dynamics sweep — does helper_tendency invade from
# rare under Hamilton-satisfying regimes?
#
# The current s-kin ✅ verdict tests population-level *consequences*
# of deterministic kin altruism (kin_selection = TRUE). This sweep
# tests the *invasion* claim Hamilton 1964 actually makes: does a
# heritable altruism allele (helper_tendency) rise from rare when
# r × B > C, and stay rare when r × B < C?
#
# Mechanism: cooperative_breeding = TRUE enables stochastic
# alloparental helping. A candidate helper with energy >
# helper_min_energy and relatedness >= helper_kin_threshold to a
# nearby carrying parent transfers helper_transfer energy with
# probability = helper_tendency. The helper pays the transfer; the
# parent (a relative) gains it, passing part to the carried juvenile.
#
# Hamilton's rule in this module: r * B > C where r ≥ 0.25 (siblings)
# or 0.5 (parent-offspring), B = energy-that-reaches-juvenile (bounded
# by helper_transfer), C = helper_transfer. So the critical question
# is whether the indirect fitness benefit through the relative's
# offspring outweighs helper_transfer.
#
# Design: start helper_tendency low (init_mean = 0.05, mutation_sd =
# 0.02). Vary helper_transfer across 4 levels to shift effective C.
# Measure final mean_helper_tendency. If invasion dynamics hold,
# low C → rise; high C → stay rare / decline.

suppressPackageStartupMessages({
  library(clade)
})

cat("Loaded clade; Julia will boot on first run_alife() call\n")

# --- Sweep design -----------------------------------------------------
helper_transfers <- c(2.0, 5.0, 10.0, 20.0)  # C values (donor energy cost)
seeds <- 1:8L

make_specs <- function(transfer, seed) {
  s <- default_specs()
  # 60×60 grid for stability (realistic_specs scale without the
  # extra complexity — kin dynamics work best on a familiar scale)
  s$grid_rows       <- 40L
  s$grid_cols       <- 40L
  s$n_agents_init   <- 100L
  s$max_agents      <- 400L
  s$max_ticks       <- 2000L
  s$grass_rate      <- 0.15

  # Parental care is a prerequisite for cooperative_breeding —
  # helpers transfer energy to parents carrying offspring
  s$parental_care                 <- TRUE
  s$juvenile_independence_age     <- 10L
  s$care_cost_per_tick            <- 1.0
  s$feeding_rate                  <- 5.0

  # Cooperative breeding (heritable helper_tendency)
  s$cooperative_breeding          <- TRUE
  s$helper_tendency_init_mean     <- 0.05   # start rare
  s$helper_tendency_mutation_sd   <- 0.02
  s$helper_min_energy             <- 80.0
  s$helper_kin_threshold          <- 0.25   # siblings and closer
  s$helper_transfer               <- transfer

  s$random_seed <- as.integer(seed)
  s
}

# Build the spec grid: one spec per (transfer, seed) pair
spec_list <- list()
idx <- 1L
for (tr in helper_transfers) {
  for (sd in seeds) {
    nm <- sprintf("C%.0f_seed%d", tr, sd)
    spec_list[[nm]] <- make_specs(tr, sd)
    idx <- idx + 1L
  }
}
cat(sprintf("Built %d specs: %d transfer levels × %d seeds\n",
            length(spec_list), length(helper_transfers), length(seeds)))

# --- Run the sweep ----------------------------------------------------
# PSOCK via batch_alife; each worker gets its own R+Julia session
n_cores <- min(32L, length(spec_list))
cat(sprintf("Launching batch_alife on %d cores — expect ~3–5 min after Julia compile\n", n_cores))

t_start <- Sys.time()
results <- batch_alife(spec_list, n_cores = n_cores, verbose = FALSE)
t_elapsed <- difftime(Sys.time(), t_start, units = "mins")
cat(sprintf("Sweep complete in %.1f min\n", as.numeric(t_elapsed)))

# --- Collect results --------------------------------------------------
collect_row <- function(env, name) {
  d <- get_run_data(env)$ticks
  # Averaged over the last 500 ticks to reduce end-of-run noise
  last_window <- tail(d, 500L)
  # Parse the name: "C5_seed3" → transfer=5, seed=3
  parts <- strsplit(name, "_")[[1]]
  transfer <- as.numeric(sub("^C", "", parts[1]))
  seed     <- as.integer(sub("^seed", "", parts[2]))
  data.frame(
    name                  = name,
    transfer              = transfer,
    seed                  = seed,
    final_helper_tendency = mean(last_window$mean_helper_tendency, na.rm = TRUE),
    init_helper_tendency  = d$mean_helper_tendency[1],
    delta_helper          = mean(last_window$mean_helper_tendency, na.rm = TRUE) -
                            d$mean_helper_tendency[1],
    final_n               = mean(last_window$n_agents, na.rm = TRUE),
    n_helpers_total       = sum(d$n_helpers, na.rm = TRUE),
    stringsAsFactors      = FALSE
  )
}

rows <- mapply(collect_row, results, names(results),
               SIMPLIFY = FALSE)
df   <- do.call(rbind, rows)
rownames(df) <- NULL

cat("\n--- Per-run results ---\n")
print(df, row.names = FALSE)

# --- Aggregate across seeds -------------------------------------------
agg <- aggregate(cbind(final_helper_tendency, delta_helper, final_n, n_helpers_total) ~ transfer,
                 data = df, FUN = mean)
agg_se <- aggregate(cbind(final_helper_tendency, delta_helper) ~ transfer,
                    data = df, FUN = function(x) sd(x) / sqrt(length(x)))
agg$final_helper_se <- agg_se$final_helper_tendency
agg$delta_helper_se <- agg_se$delta_helper
agg$t_delta <- agg$delta_helper / agg$delta_helper_se

cat("\n--- Aggregated across seeds ---\n")
print(agg, row.names = FALSE)

# --- Spearman correlation: transfer vs final helper_tendency ----------
sp <- cor(df$transfer, df$final_helper_tendency, method = "spearman")
cat(sprintf("\nSpearman(transfer, final_helper_tendency) = %.3f\n", sp))

# --- Verdict ----------------------------------------------------------
# Hamilton's rule: invasion when r*B > C. Lower transfer (C) makes
# it easier; expect final_helper_tendency to decline monotonically
# with transfer.
cat("\n--- Verdict logic ---\n")
cat("If Hamilton invasion dynamics hold:\n")
cat("  - Lower helper_transfer → higher final_helper_tendency (invasion)\n")
cat("  - Higher helper_transfer → lower final_helper_tendency (no invasion)\n")
cat(sprintf("  - Spearman should be negative (is %.3f)\n", sp))
cat(sprintf("  - |t| for the lowest-transfer Δ should exceed 2 (is %.2f)\n",
            abs(agg$t_delta[which.min(agg$transfer)])))

# --- Save -------------------------------------------------------------
out_rds <- "dev/audit/fidelity/kin_invasion_sweep.rds"
saveRDS(list(df = df, agg = agg, spearman = sp,
             design = list(helper_transfers = helper_transfers,
                           seeds = seeds,
                           ticks = 2000L,
                           grid = "40x40",
                           helper_kin_threshold = 0.25,
                           init_helper_tendency = 0.05)),
        out_rds)
cat(sprintf("\nSaved: %s\n", out_rds))
