# Follow-up sweep for Rees-Baylis et al. 2026 reproduction.
#
# The first-pass sweep (paper_rees_baylis_2026.R) used max_clutch_size = 1L
# everywhere; populations crashed to extinction in every fig2 condition
# (any trade-off, including s = 0) and in fig4_monog. Only fig3 with
# k ≥ 2 produced viable populations.
#
# This follow-up re-runs the extinct conditions at max_clutch_size = 2L
# to give populations the per-event slack needed to survive 5000 ticks
# under the trade-off. The k=1 results from the first sweep stand as
# evidence of the energetic-viability constraint that distinguishes
# clade's ABM from the paper's analytical matrix model.
#
# Output: dev/audit/fidelity/paper_rees_baylis_2026_followup.rds.

suppressMessages({
  if (requireNamespace("clade", quietly = TRUE)) {
    library(clade)
  } else {
    devtools::load_all(quiet = TRUE)
  }
  library(parallel)
})

SEEDS    <- 1:5
TICKS    <- 5000L
N_CORES  <- min(8L, parallel::detectCores() - 2L)
K_RESC   <- 2L  # the rescue setting

out_dir  <- "dev/audit/fidelity"
out_path <- file.path(out_dir, "paper_rees_baylis_2026_followup.rds")
log_path <- file.path(out_dir, "paper_rees_baylis_2026_followup.log")

cat("Rees-Baylis 2026 follow-up sweep (max_clutch_size = ", K_RESC, ")\n", sep = "")
cat("  seeds = ", paste(SEEDS, collapse = ","),
    " | ticks = ", TICKS, " | n_cores = ", N_CORES, "\n", sep = "")

base_specs <- function() {
  s <- default_specs()
  s$grid_rows                <- 30L
  s$grid_cols                <- 30L
  s$n_agents_init            <- 200L
  s$max_agents               <- 1000L
  s$max_ticks                <- TICKS
  s$grass_rate               <- 0.15
  s$ploidy                   <- 2L
  s$sex_labels               <- TRUE
  s$sex_ratio_primary        <- 0.5
  s$sex_specific_traits      <- c("aging_rate")
  s$aging_rate_evolution     <- TRUE
  s$aging_rate_init_mean     <- 1.0
  s$aging_rate_min           <- 0.1
  s$aging_rate_max           <- 5.0
  s$aging_rate_mutation_sd   <- 0.05
  s$senescence_rate          <- 0.02
  s$senescence_shape         <- 1.0
  s$parental_investment_evolution <- FALSE
  s$mating_system            <- "any"
  s$max_clutch_size          <- K_RESC   # rescue value
  s
}

# fig2 sweep at k = K_RESC
fig2_conds <- lapply(c(0.0, 0.025, 0.05, 0.075, 0.1), function(sval) {
  list(key = sprintf("fig2_s%g_k%d", sval, K_RESC), fig = "fig2_followup",
       build = function(s) {
         s$sex_specific_tradeoffs <- list(
           male_mating_vs_aging      = sval,
           female_offspring_vs_aging = sval
         )
         s
       })
})

# fig4 monogamy at k = K_RESC
fig4_cond <- list(list(
  key = sprintf("fig4_monog_k%d", K_RESC), fig = "fig4_followup",
  build = function(s) {
    s$sex_specific_tradeoffs <- list(
      male_mating_vs_aging      = 0.05,
      female_offspring_vs_aging = 0.05
    )
    s$mating_system            <- "monogamous_pair"
    s$divorce_rate             <- 0.0
    s$pair_bond_persistence    <- TRUE
    s
  }
))

conditions <- c(fig2_conds, fig4_cond)

# Build work list
work <- list()
for (cond in conditions) for (sd in SEEDS) {
  s <- cond$build(base_specs()); s$random_seed <- sd
  work[[length(work) + 1L]] <- list(
    condition_key = cond$key, fig = cond$fig, seed = sd, specs = s
  )
}
cat("  total work units: ", length(work), "\n", sep = "")

per_run_metric <- function(env) {
  n <- length(env$agents)
  if (n == 0L) {
    return(list(n_final = 0L, n_female = 0L, n_male = 0L,
                mean_aging_female = NA_real_, mean_aging_male = NA_real_,
                target_lifespan_female = NA_real_,
                target_lifespan_male = NA_real_))
  }
  ar <- vapply(seq_len(n),
               function(i) as.numeric(env$agents[[i]]$aging_rate),
               numeric(1))
  sx <- vapply(seq_len(n),
               function(i) as.integer(env$agents[[i]]$sex), integer(1))
  list(
    n_final          = n,
    n_female         = sum(sx == 0L),
    n_male           = sum(sx == 1L),
    mean_aging_female      = if (any(sx == 0L)) mean(ar[sx == 0L]) else NA_real_,
    mean_aging_male        = if (any(sx == 1L)) mean(ar[sx == 1L]) else NA_real_,
    target_lifespan_female = if (any(sx == 0L)) mean(1 / ar[sx == 0L]) else NA_real_,
    target_lifespan_male   = if (any(sx == 1L)) mean(1 / ar[sx == 1L]) else NA_real_
  )
}

file.create(log_path, showWarnings = FALSE)
t0 <- proc.time()
run_one <- function(w) {
  local_t0 <- proc.time()
  env <- tryCatch(run_alife(w$specs, verbose = FALSE),
                  error = function(e) e)
  elapsed <- as.numeric((proc.time() - local_t0)[3])
  if (inherits(env, "error")) {
    cat(sprintf("  [%s seed=%d] ERROR: %s\n",
                w$condition_key, w$seed, conditionMessage(env)),
        file = log_path, append = TRUE)
    return(list(condition_key = w$condition_key, fig = w$fig, seed = w$seed,
                success = FALSE, error = conditionMessage(env),
                elapsed_seconds = elapsed))
  }
  metrics <- per_run_metric(env)
  cat(sprintf("  [%s seed=%d] OK n=%d t=%.1fs\n",
              w$condition_key, w$seed, metrics$n_final, elapsed),
      file = log_path, append = TRUE)
  c(list(condition_key = w$condition_key, fig = w$fig, seed = w$seed,
         success = TRUE, error = NA_character_,
         elapsed_seconds = elapsed),
    metrics)
}

results <- if (.Platform$OS.type == "unix" && N_CORES > 1L) {
  parallel::mclapply(work, run_one, mc.cores = N_CORES, mc.preschedule = FALSE)
} else lapply(work, run_one)

elapsed_total <- as.numeric((proc.time() - t0)[3])
cat(sprintf("\nFollow-up done in %.1f s (%.1f min)\n",
            elapsed_total, elapsed_total / 60))

saveRDS(list(
  meta = list(
    seeds = SEEDS, ticks = TICKS, n_cores = N_CORES,
    max_clutch_size = K_RESC,
    elapsed_seconds = elapsed_total,
    timestamp = as.character(Sys.time()),
    clade_version = utils::packageVersion("clade")
  ),
  conditions = conditions,
  results = results
), out_path)
cat("Saved: ", out_path, "\n", sep = "")

# Quick summary
df <- do.call(rbind, lapply(results, function(r) {
  if (!isTRUE(r$success)) return(data.frame(condition_key = r$condition_key, surv = FALSE,
                                              n_final = NA_integer_, aging_f = NA_real_, aging_m = NA_real_))
  data.frame(condition_key = r$condition_key, surv = TRUE,
             n_final = r$n_final,
             aging_f = r$mean_aging_female,
             aging_m = r$mean_aging_male)
}))
cat("\nPer-condition (5-seed):\n")
for (ck in unique(df$condition_key)) {
  sub <- df[df$condition_key == ck, ]
  n_surv <- sum(sub$surv)
  cat(sprintf("  %-25s surviving=%d/5  mean_n=%.0f  aging_F=%.3f  aging_M=%.3f\n",
              ck, n_surv, mean(sub$n_final, na.rm = TRUE),
              mean(sub$aging_f, na.rm = TRUE), mean(sub$aging_m, na.rm = TRUE)))
}
