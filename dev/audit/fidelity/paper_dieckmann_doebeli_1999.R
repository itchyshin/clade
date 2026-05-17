# Dieckmann & Doebeli (1999) reproduction
# "On the origin of species by sympatric speciation", Nature 400:354-357
# DOI: 10.1038/22521
#
# Core claim: under disruptive selection on a resource-use trait,
# combined with assortative mating based on that trait, a single
# population splits into reproductively isolated clusters — EVEN
# WITHOUT geographic isolation. Sympatric speciation works.
#
# clade test: `speciation = TRUE` enables cluster detection and
# isolation. Sweep `isolation_threshold` (the genetic-distance
# floor required for reproductive isolation) across a range.
#
# Expected: low isolation_threshold → many clusters form;
# high threshold → population stays a single species.
#
# Toolkit demo: grid_specs() across (isolation_threshold,
# mutation_sd) identifies the parameter cell where the
# speciation signal is strongest; hypothesis_sweep() validates.

suppressPackageStartupMessages({
  if (requireNamespace("devtools", quietly = TRUE))
    devtools::load_all(quiet = TRUE)
  else
    library(clade)
})

source("dev/audit/fidelity/_helper.R")

base <- fast_specs()
base$speciation                  <- TRUE
base$speciation_cluster_interval <- 10L

# ---------------------------------------------------------------
# Stage 1: grid search over (isolation_threshold, mutation_sd)
# ---------------------------------------------------------------
cat("=== Stage 1: grid search (isolation_threshold x mutation_sd) ===\n")
thresholds <- c(0.05, 0.15, 0.30, 0.50)
mut_rates  <- c(0.05, 0.10, 0.15)

specs_list <- grid_specs(base,
                          isolation_threshold = thresholds,
                          mutation_sd         = mut_rates,
                          seed_from           = 7L)
cat(sprintf("  Grid: %d thresholds x %d mutation rates = %d cells\n",
            length(thresholds), length(mut_rates), length(specs_list)))

t0 <- Sys.time()
results <- batch_alife(specs_list, n_cores = .fidelity_cores(default = 12L))
cat(sprintf("  Grid complete in %.1fs\n", as.numeric(difftime(Sys.time(), t0, units = "secs"))))

grid_tbl <- do.call(rbind, mapply(function(env, s) {
  d <- get_run_data(env)$ticks
  data.frame(
    threshold   = s$isolation_threshold,
    mutation    = s$mutation_sd,
    peak_species = max(d$n_species, na.rm = TRUE),
    final_species = tail(d$n_species, 1L),
    final_n     = tail(d$n_agents, 1L),
    stringsAsFactors = FALSE
  )
}, results, specs_list, SIMPLIFY = FALSE))

cat("\n  Grid (final n_species):\n")
tbl_final <- reshape(grid_tbl[, c("threshold", "mutation", "final_species")],
                     idvar = "threshold", timevar = "mutation",
                     direction = "wide")
names(tbl_final) <- c("threshold", paste0("mut=", mut_rates))
print(tbl_final, row.names = FALSE)

cat("\n  Grid (peak n_species across the run):\n")
tbl_peak <- reshape(grid_tbl[, c("threshold", "mutation", "peak_species")],
                    idvar = "threshold", timevar = "mutation",
                    direction = "wide")
names(tbl_peak) <- c("threshold", paste0("mut=", mut_rates))
print(tbl_peak, row.names = FALSE)

# Pick the cell with highest final_species (most persistent speciation)
best_cell <- grid_tbl[which.max(grid_tbl$final_species), ]
cat(sprintf("\n  Selected regime: threshold = %.2f, mutation_sd = %.2f (final_species = %d)\n",
            best_cell$threshold, best_cell$mutation, best_cell$final_species))

# ---------------------------------------------------------------
# Stage 2: hypothesis_sweep at the selected regime, sweeping
# threshold across 4 levels to demonstrate the D&D gradient
# ---------------------------------------------------------------
cat("\n=== Stage 2: hypothesis_sweep at best mutation_sd ===\n")
final_base <- base
final_base$mutation_sd <- best_cell$mutation

conds <- list(
  stringent_th50 = list(isolation_threshold = 0.50),
  moderate_th30  = list(isolation_threshold = 0.30),
  permissive_th15 = list(isolation_threshold = 0.15),
  very_permissive_th05 = list(isolation_threshold = 0.05)
)

sweep <- hypothesis_sweep(
  base_specs = final_base,
  conditions = conds,
  seeds = 1:8,
  metrics = list(
    final_species = function(ticks) tail(ticks$n_species, 1L),
    peak_species  = function(ticks) max(ticks$n_species, na.rm = TRUE),
    final_n       = function(ticks) tail(ticks$n_agents, 1L)
  ),
  n_cores = .fidelity_cores(default = 32L)
)
print(sweep)

rpt <- hypothesis_report(
  sweep,
  contrasts = list(
    moderate_vs_stringent     = c("stringent_th50", "moderate_th30"),
    permissive_vs_stringent   = c("stringent_th50", "permissive_th15"),
    very_permissive_vs_stringent = c("stringent_th50", "very_permissive_th05")
  ),
  metric = "final_species"
)
cat("\n=== D&D contrasts ===\n")
print(rpt)

cat("\nD&D 1999 predict: permissive thresholds should produce MORE species.\n")
cat("  All Δ should be POSITIVE (more species at lower threshold).\n")

# Spearman across all runs — threshold vs final_species.
# D&D predicts NEGATIVE: higher threshold → fewer species.
thresh_vals <- c(stringent_th50 = 0.50, moderate_th30 = 0.30,
                 permissive_th15 = 0.15, very_permissive_th05 = 0.05)
sp <- cor(thresh_vals[sweep$runs$condition], sweep$runs$final_species,
          method = "spearman", use = "complete.obs")
cat(sprintf("\nSpearman(isolation_threshold, final_species) = %+.3f\n", sp))
cat("D&D predict: NEGATIVE (lower threshold → more species → monotone).\n")

saveRDS(list(stage1_grid = grid_tbl, best_cell = best_cell,
             sweep = sweep, report = rpt, spearman = sp),
        "dev/audit/fidelity/paper_dieckmann_doebeli_1999.rds")
cat("\nSaved: dev/audit/fidelity/paper_dieckmann_doebeli_1999.rds\n")
