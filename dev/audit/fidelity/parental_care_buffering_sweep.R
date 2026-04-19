# s-parental-care buffering sweep — does Clutton-Brock 1991
# variance-buffering emerge under tighter scarcity?
#
# Citation-audit ⚠️ for s-parental-care: default parameters reproduce
# the P1 graduation-pathway prediction (juveniles persist with care,
# 0 without) but NOT the P2 variance-buffering prediction (variance
# 4625 with care vs 4548 no-care — null).
#
# The s-parental-care vignette's own hypothesis for why P2 fails:
# "tighter resource scarcity or higher `care_cost_per_tick` needed
# to express visibly." This sweep tests that hypothesis directly.
#
# Clutton-Brock 1991 claim: parental care buffers offspring against
# environmental stochasticity, so the variance of population size
# should be LOWER under care, especially when the environment is
# stochastic enough to matter.
#
# Design: 3 grass_rate × parental_care ∈ {FALSE, TRUE} × 8 seeds
# = 48 runs at 40×40 grid, care_cost = 3.0 (higher than default 1.0
# per the vignette hypothesis), 2000 ticks.

suppressPackageStartupMessages({
  library(clade)
})

cat("Loaded clade — Julia will boot on first run_alife()\n")

grass_rates <- c(0.05, 0.08, 0.12)
care_conditions <- c(FALSE, TRUE)
seeds <- 1:8L

make_specs <- function(grass, care, seed) {
  s <- default_specs()
  s$grid_rows       <- 40L
  s$grid_cols       <- 40L
  s$n_agents_init   <- 100L
  s$max_agents      <- 400L
  s$max_ticks       <- 2000L
  s$grass_rate      <- grass

  # No predators — we want demographic stochasticity coming from
  # resource limitation, not external mortality
  s$n_predators_init <- 0L

  # Parental care setup per vignette hypothesis
  s$parental_care                 <- care
  s$juvenile_independence_age     <- 10L
  s$juvenile_independence_energy  <- 50.0
  s$care_cost_per_tick            <- 3.0   # higher than default 1.0
  s$feeding_rate                  <- 5.0

  s$random_seed <- as.integer(seed)
  s
}

spec_list <- list()
for (gr in grass_rates) for (cc in care_conditions) for (sd in seeds) {
  nm <- sprintf("g%.2f_care%d_seed%d", gr, as.integer(cc), sd)
  spec_list[[nm]] <- make_specs(gr, cc, sd)
}
cat(sprintf("Built %d specs (3 grass × 2 care × 8 seeds × 2000 ticks, care_cost=3.0)\n",
            length(spec_list)))

# --- Run ------------------------------------------------------------
n_cores <- min(48L, length(spec_list))
t_start <- Sys.time()
results <- batch_alife(spec_list, n_cores = n_cores, verbose = FALSE)
t_elapsed <- difftime(Sys.time(), t_start, units = "mins")
cat(sprintf("Sweep complete in %.1f min\n", as.numeric(t_elapsed)))

# --- Collect --------------------------------------------------------
collect_row <- function(env, name) {
  d <- get_run_data(env)$ticks
  last_window <- tail(d, 500L)
  parts <- strsplit(name, "_")[[1]]
  gr   <- as.numeric(sub("^g", "", parts[1]))
  care <- as.integer(sub("^care", "", parts[2])) == 1
  seed <- as.integer(sub("^seed", "", parts[3]))
  data.frame(
    grass       = gr,
    care        = care,
    seed        = seed,
    mean_n      = mean(last_window$n_agents, na.rm = TRUE),
    var_n       = var(last_window$n_agents, na.rm = TRUE),
    cv_n        = sd(last_window$n_agents, na.rm = TRUE) / mean(last_window$n_agents, na.rm = TRUE),
    mean_juv    = mean(last_window$n_juveniles, na.rm = TRUE),
    final_n     = d$n_agents[nrow(d)],
    crashed     = d$n_agents[nrow(d)] < 10,
    stringsAsFactors = FALSE
  )
}
rows <- mapply(collect_row, results, names(results), SIMPLIFY = FALSE)
df   <- do.call(rbind, rows); rownames(df) <- NULL
cat("\n--- Per-run results ---\n"); print(df, row.names = FALSE)

# --- Aggregate: variance comparison at each grass rate ---
cat("\n--- Variance buffering: care vs no-care at each grass rate ---\n")
results_summary <- data.frame()
for (gr in grass_rates) {
  no_care <- df$var_n[df$grass == gr & !df$care]
  w_care  <- df$var_n[df$grass == gr &  df$care]
  delta <- mean(w_care) - mean(no_care)
  se    <- sqrt(var(w_care)/length(w_care) + var(no_care)/length(no_care))
  tval  <- delta / se
  # Also compare CV (coefficient of variation)
  no_care_cv <- df$cv_n[df$grass == gr & !df$care]
  w_care_cv  <- df$cv_n[df$grass == gr &  df$care]
  cv_delta <- mean(w_care_cv) - mean(no_care_cv)
  cv_se    <- sqrt(var(w_care_cv)/length(w_care_cv) + var(no_care_cv)/length(no_care_cv))
  cv_tval  <- cv_delta / cv_se
  # Mean populations for context
  no_care_mean_n <- mean(df$mean_n[df$grass == gr & !df$care])
  w_care_mean_n  <- mean(df$mean_n[df$grass == gr &  df$care])
  results_summary <- rbind(results_summary, data.frame(
    grass = gr,
    no_care_mean_n = no_care_mean_n,
    w_care_mean_n  = w_care_mean_n,
    no_care_var = mean(no_care),
    w_care_var  = mean(w_care),
    delta_var = delta,
    var_t = tval,
    no_care_cv = mean(no_care_cv),
    w_care_cv  = mean(w_care_cv),
    delta_cv = cv_delta,
    cv_t = cv_tval
  ))
}
print(results_summary, row.names = FALSE)

cat("\nClutton-Brock 1991 prediction: variance (and CV) should be LOWER under parental care.\n")
cat("So we want delta_var < 0 and delta_cv < 0 (t negative).\n")

saveRDS(list(df = df, summary = results_summary,
             design = list(grass_rates = grass_rates,
                           seeds = seeds,
                           ticks = 2000L,
                           grid = "40x40",
                           care_cost = 3.0,
                           n_predators = 0L)),
        "dev/audit/fidelity/parental_care_buffering_sweep.rds")
cat("\nSaved: dev/audit/fidelity/parental_care_buffering_sweep.rds\n")
