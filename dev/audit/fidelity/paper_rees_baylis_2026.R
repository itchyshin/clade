# Reproduction sweep for Rees-Baylis et al. 2026 (Nat Commun).
#
# Runs the three figure-set sweeps targeted by
# `vignettes/paper-rees-baylis-2026.Rmd`:
#   - Fig 2 c & f: equal-strength trade-off ∈ {0, 0.025, 0.05, 0.075, 0.1}
#   - Fig 3:       max_clutch_size ∈ {1L, 2L, 3L, 4L} at fixed s = 0.05
#   - Fig 4:       monogamous unions at s = 0.05
#
# Output: dev/audit/fidelity/paper_rees_baylis_2026.rds (single list with
# all per-(condition, seed) results) and a printed summary table.
#
# Time budget: each run is ~30-120s on a modern machine. With 5 seeds
# per condition and 8 parallel workers, total wall time is roughly
# 5-15 minutes. Reduce SEEDS / TICKS for a faster smoke run.

suppressMessages({
  # Prefer the installed clade if available, else devtools::load_all() the
  # source tree. The latter is what `devtools::test()` does under the hood
  # and is the standard development-time entry point per AGENTS.md.
  if (requireNamespace("clade", quietly = TRUE)) {
    library(clade)
  } else {
    devtools::load_all(quiet = TRUE)
  }
  library(parallel)
})

# ── Configuration ────────────────────────────────────────────────────────────

SEEDS <- 1:5
TICKS <- 5000L
N_CORES <- min(8L, parallel::detectCores() - 2L)

out_dir  <- "dev/audit/fidelity"
out_path <- file.path(out_dir, "paper_rees_baylis_2026.rds")
log_path <- file.path(out_dir, "paper_rees_baylis_2026.log")

cat("Rees-Baylis 2026 reproduction sweep\n")
cat("  seeds = ", paste(SEEDS, collapse = ","),
    " | ticks = ", TICKS, " | n_cores = ", N_CORES, "\n", sep = "")

# ── Base specs (matches vignette base_specs()) ───────────────────────────────

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
  s$max_clutch_size          <- 1L
  s
}

# ── Condition definitions ────────────────────────────────────────────────────

apply_fig2 <- function(s, s_val) {
  s$sex_specific_tradeoffs <- list(
    male_mating_vs_aging      = s_val,
    female_offspring_vs_aging = s_val
  )
  s$max_clutch_size <- 2L   # k=1 is universally extinct (see followup log)
  s
}

apply_fig3 <- function(s, k_val) {
  s$sex_specific_tradeoffs <- list(
    male_mating_vs_aging      = 0.05,
    female_offspring_vs_aging = 0.05
  )
  s$max_clutch_size <- k_val
  s
}

apply_fig4 <- function(s) {
  s$sex_specific_tradeoffs <- list(
    male_mating_vs_aging      = 0.05,
    female_offspring_vs_aging = 0.05
  )
  s$max_clutch_size          <- 2L   # k=1 extinct under monogamy too
  s$mating_system            <- "monogamous_pair"
  s$divorce_rate             <- 0.0
  s$pair_bond_persistence    <- TRUE
  s
}

# Use `lapply` so each iteration's anonymous function captures its own
# binding of `sval` / `k` (closure-over-loop-variable bug fix).
fig2_conds <- lapply(c(0.0, 0.025, 0.05, 0.075, 0.1), function(sval) {
  list(
    key = sprintf("fig2_s%g", sval),
    fig = "fig2",
    build = function(s) apply_fig2(s, sval)
  )
})
fig3_conds <- lapply(c(1L, 2L, 3L, 4L), function(k) {
  list(
    key = sprintf("fig3_k%d", k),
    fig = "fig3",
    build = function(s) apply_fig3(s, k)
  )
})
fig4_cond <- list(list(
  key = "fig4_monog",
  fig = "fig4",
  build = function(s) apply_fig4(s)
))
conditions <- c(fig2_conds, fig3_conds, fig4_cond)

# ── Per-run metric ───────────────────────────────────────────────────────────

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

# ── Build the flat (condition × seed) work list ──────────────────────────────

work <- list()
for (cond in conditions) {
  for (sd in SEEDS) {
    s <- cond$build(base_specs())
    s$random_seed <- sd
    work[[length(work) + 1L]] <- list(
      condition_key = cond$key, fig = cond$fig, seed = sd, specs = s
    )
  }
}

cat("  total work units: ", length(work), "\n", sep = "")
cat("  conditions: ", length(conditions), "\n", sep = "")

# ── Run ──────────────────────────────────────────────────────────────────────

t0 <- proc.time()
run_one <- function(w) {
  cat(sprintf("  [%s seed=%d] start\n", w$condition_key, w$seed),
      file = log_path, append = TRUE)
  local_t0 <- proc.time()
  env <- tryCatch(run_alife(w$specs, verbose = FALSE),
                  error = function(e) e)
  elapsed <- as.numeric((proc.time() - local_t0)[3])
  if (inherits(env, "error")) {
    cat(sprintf("  [%s seed=%d] ERROR: %s\n",
                w$condition_key, w$seed, conditionMessage(env)),
        file = log_path, append = TRUE)
    return(list(
      condition_key = w$condition_key, fig = w$fig, seed = w$seed,
      success = FALSE, error = conditionMessage(env),
      elapsed_seconds = elapsed
    ))
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

cat("\nLog file: ", log_path, "\n", sep = "")
file.create(log_path, showWarnings = FALSE)

# Use mclapply on macOS / Linux; falls back to sequential on Windows.
results <- if (.Platform$OS.type == "unix" && N_CORES > 1L) {
  cat("Running ", length(work), " runs across ", N_CORES, " workers...\n", sep = "")
  parallel::mclapply(work, run_one, mc.cores = N_CORES, mc.preschedule = FALSE)
} else {
  cat("Running sequentially (windows or n_cores=1)\n")
  lapply(work, run_one)
}

elapsed_total <- as.numeric((proc.time() - t0)[3])
cat(sprintf("\nAll runs done in %.1f s (%.1f min)\n",
            elapsed_total, elapsed_total / 60))

# ── Save raw results ─────────────────────────────────────────────────────────

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
saveRDS(list(
  meta = list(
    seeds = SEEDS, ticks = TICKS, n_cores = N_CORES,
    elapsed_seconds = elapsed_total,
    timestamp = as.character(Sys.time()),
    clade_version = utils::packageVersion("clade")
  ),
  conditions = conditions,
  results = results
), out_path)
cat("Saved: ", out_path, "\n", sep = "")

# ── Summary table ────────────────────────────────────────────────────────────

mk_df <- function(results) {
  do.call(rbind, lapply(results, function(r) {
    if (!isTRUE(r$success)) {
      data.frame(condition_key = r$condition_key, fig = r$fig, seed = r$seed,
                 success = FALSE, n_final = NA_integer_,
                 mean_aging_female = NA_real_, mean_aging_male = NA_real_,
                 target_lifespan_female = NA_real_,
                 target_lifespan_male = NA_real_,
                 stringsAsFactors = FALSE)
    } else {
      data.frame(condition_key = r$condition_key, fig = r$fig, seed = r$seed,
                 success = TRUE, n_final = r$n_final,
                 mean_aging_female = r$mean_aging_female,
                 mean_aging_male = r$mean_aging_male,
                 target_lifespan_female = r$target_lifespan_female,
                 target_lifespan_male = r$target_lifespan_male,
                 stringsAsFactors = FALSE)
    }
  }))
}

df <- mk_df(results)

agg <- aggregate(cbind(n_final, mean_aging_female, mean_aging_male,
                        target_lifespan_female, target_lifespan_male) ~
                 condition_key, data = df, FUN = function(x) mean(x, na.rm = TRUE))

cat("\n── Summary (mean across seeds) ─────────────────────────────────────────\n")
print(agg, row.names = FALSE, digits = 3)
cat("\nNote: target_lifespan_* = 1 / aging_rate (the documented lifespan proxy).\n")
cat("Higher aging_rate → faster aging → shorter target lifespan.\n")
