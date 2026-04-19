# Allee effect — extending clade via initial-density sweep
#
# Courchamp, F., Clutton-Brock, T. & Grenfell, B. (1999). Inverse
# density dependence and the Allee effect. Trends in Ecology &
# Evolution 14(10):405-410.
#
# Claim: below a critical density, per-capita fitness drops —
# mate-finding failure, reduced cooperative benefits, etc. —
# producing extinction-prone dynamics.
#
# Pragmatic extension pattern: clade exhibits density-dependent
# dynamics *already* through its movement / grass-regeneration /
# reproduction machinery. We measure the Allee signature by
# varying n_agents_init and looking at extinction rate.
#
# This sidesteps the `register_module()` stub (documented in the
# vignette) and demonstrates the principle: check what clade
# ALREADY does before building a custom module.

suppressPackageStartupMessages({
  if (requireNamespace("devtools", quietly = TRUE))
    devtools::load_all(quiet = TRUE)
  else
    library(clade)
})

base <- default_specs()
base$grid_rows        <- 40L
base$grid_cols        <- 40L
base$max_agents       <- 300L
base$max_ticks        <- 1500L
base$grass_rate       <- 0.05       # scarce grass
base$n_predators_init <- 5L         # predator pressure added — amplifies
                                    # density dependence (predation +
                                    # resource limitation both at play)
base$predator_max_age  <- 60L

# Sweep n_agents_init — the "founding-population-size" lever.
# Courchamp predicts: smaller founding populations extinct more often.
initial_densities <- c(very_low = 3L, low = 6L, medium = 15L,
                        high = 40L, very_high = 100L)

conds <- setNames(
  lapply(initial_densities, function(n) list(n_agents_init = n)),
  names(initial_densities)
)

cat("=== Allee signature via n_agents_init sweep ===\n")
sweep <- hypothesis_sweep(
  base_specs = base,
  conditions = conds,
  seeds = 1:12L,           # 12 seeds per condition — extinctions are stochastic
  metrics = list(
    extinct      = function(t) tail(t$n_agents, 1L) < 5L,
    final_n      = function(t) tail(t$n_agents, 1L),
    min_n        = function(t) min(t$n_agents, na.rm = TRUE),
    equilibrium_n = function(t) mean(tail(t$n_agents, 500L), na.rm = TRUE)
  ),
  n_cores = 40L
)
print(sweep)

# --- Extinction rates per condition ---
cat("\n=== Extinction rates (Courchamp prediction: lower density → more extinctions) ===\n")
ext_tbl <- do.call(rbind, lapply(names(initial_densities), function(cn) {
  sub <- sweep$runs[sweep$runs$condition == cn, ]
  data.frame(
    condition   = cn,
    n_init      = initial_densities[[cn]],
    n_seeds     = nrow(sub),
    extinct     = sum(sub$extinct),
    ext_rate    = mean(sub$extinct),
    equil_n     = mean(sub$equilibrium_n, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}))
print(ext_tbl, row.names = FALSE)

# --- Fisher's exact: very_low vs very_high ---
cat("\n=== Fisher's exact: very_low vs very_high ===\n")
vl <- ext_tbl[ext_tbl$condition == "very_low", ]
vh <- ext_tbl[ext_tbl$condition == "very_high", ]
ft <- fisher.test(matrix(c(vl$extinct, vl$n_seeds - vl$extinct,
                           vh$extinct, vh$n_seeds - vh$extinct),
                         byrow = TRUE, nrow = 2L))
cat(sprintf("  very_low   extinctions: %d/%d\n", vl$extinct, vl$n_seeds))
cat(sprintf("  very_high  extinctions: %d/%d\n", vh$extinct, vh$n_seeds))
cat(sprintf("  Fisher p = %.4g, OR = %.2f\n", ft$p.value,
            if (is.finite(ft$estimate)) ft$estimate else NA))

# --- Spearman: n_init vs extinction_rate ---
n_init_vec <- initial_densities[sweep$runs$condition]
sp <- cor(n_init_vec, as.integer(sweep$runs$extinct), method = "spearman")
cat(sprintf("\nSpearman(n_init, extinct) = %+.3f\n", sp))
cat("Courchamp 1999 predict NEGATIVE (lower density → more extinctions).\n")

saveRDS(list(sweep = sweep, extinction_table = ext_tbl,
             fisher = ft, spearman = sp,
             initial_densities = initial_densities),
        "dev/audit/fidelity/custom_allee_effect.rds")
cat("\nSaved: dev/audit/fidelity/custom_allee_effect.rds\n")
