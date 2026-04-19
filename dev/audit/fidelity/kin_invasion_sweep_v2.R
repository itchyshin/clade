# s-kin invasion sweep v2 — relaxed gate + longer runs
#
# v1 (kin_invasion_sweep.R) found direction-correct but noise-dominated
# effect (Spearman = -0.197, |t| < 2). Diagnosis: only 24-52 helping
# events per 2000-tick run at default helper_min_energy = 80 and
# helper_kin_threshold = 0.25. Selection pressure on helper_tendency
# is too weak to overcome mutation_sd = 0.02 drift noise.
#
# v2 hypothesis: lowering helper_min_energy (50 instead of 80) and
# extending runs to 4000 ticks should increase total helping events
# per run by ~10×, giving the selection signal enough samples to
# emerge from drift.

suppressPackageStartupMessages({
  library(clade)
})

cat("Loaded clade — Julia will boot on first run_alife()\n")

helper_transfers <- c(2.0, 5.0, 10.0, 20.0)
seeds <- 1:8L

make_specs <- function(transfer, seed) {
  s <- default_specs()
  s$grid_rows       <- 40L
  s$grid_cols       <- 40L
  s$n_agents_init   <- 100L
  s$max_agents      <- 400L
  s$max_ticks       <- 4000L       # 2× v1
  s$grass_rate      <- 0.15

  s$parental_care                 <- TRUE
  s$juvenile_independence_age     <- 10L
  s$care_cost_per_tick            <- 1.0
  s$feeding_rate                  <- 5.0

  s$cooperative_breeding          <- TRUE
  s$helper_tendency_init_mean     <- 0.05   # still start rare
  s$helper_tendency_mutation_sd   <- 0.02
  s$helper_min_energy             <- 50.0   # lowered from 80 → more eligible helpers
  s$helper_kin_threshold          <- 0.25
  s$helper_transfer               <- transfer

  s$random_seed <- as.integer(seed)
  s
}

spec_list <- list()
for (tr in helper_transfers) for (sd in seeds) {
  nm <- sprintf("C%.0f_seed%d", tr, sd)
  spec_list[[nm]] <- make_specs(tr, sd)
}
cat(sprintf("Built %d specs (4 transfer × 8 seeds × 4000 ticks, relaxed gate)\n",
            length(spec_list)))

n_cores <- min(32L, length(spec_list))
t_start <- Sys.time()
results <- batch_alife(spec_list, n_cores = n_cores, verbose = FALSE)
t_elapsed <- difftime(Sys.time(), t_start, units = "mins")
cat(sprintf("Sweep complete in %.1f min\n", as.numeric(t_elapsed)))

collect_row <- function(env, name) {
  d <- get_run_data(env)$ticks
  last_window <- tail(d, 1000L)
  parts <- strsplit(name, "_")[[1]]
  transfer <- as.numeric(sub("^C", "", parts[1]))
  seed     <- as.integer(sub("^seed", "", parts[2]))
  data.frame(
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
rows <- mapply(collect_row, results, names(results), SIMPLIFY = FALSE)
df   <- do.call(rbind, rows); rownames(df) <- NULL
cat("\n--- Per-run results ---\n"); print(df, row.names = FALSE)

agg <- aggregate(cbind(final_helper_tendency, delta_helper, final_n, n_helpers_total) ~ transfer,
                 data = df, FUN = mean)
agg_se <- aggregate(cbind(final_helper_tendency, delta_helper) ~ transfer,
                    data = df, FUN = function(x) sd(x) / sqrt(length(x)))
agg$final_helper_se <- agg_se$final_helper_tendency
agg$delta_helper_se <- agg_se$delta_helper
agg$t_delta <- agg$delta_helper / agg$delta_helper_se
cat("\n--- Aggregated across seeds ---\n"); print(agg, row.names = FALSE)

sp <- cor(df$transfer, df$final_helper_tendency, method = "spearman")
cat(sprintf("\nSpearman(transfer, final_helper_tendency) = %.3f\n", sp))

cat(sprintf("\nMean n_helpers per run (total events over 4000 ticks): %.1f (v1 was 24-52 per 2000 ticks)\n",
            mean(df$n_helpers_total)))
cat(sprintf("Implication: ~%.1f× more helping events per run vs v1\n",
            mean(df$n_helpers_total) / 35))

saveRDS(list(df = df, agg = agg, spearman = sp,
             design = list(helper_transfers = helper_transfers,
                           seeds = seeds,
                           ticks = 4000L,
                           grid = "40x40",
                           helper_kin_threshold = 0.25,
                           helper_min_energy = 50.0,
                           init_helper_tendency = 0.05)),
        "dev/audit/fidelity/kin_invasion_sweep_v2.rds")
cat("\nSaved: dev/audit/fidelity/kin_invasion_sweep_v2.rds\n")
