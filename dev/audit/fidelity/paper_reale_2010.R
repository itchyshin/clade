# Réale et al. (2010) reproduction
# "Personality and the emergence of the pace-of-life syndrome
# concept at the population level", Phil Trans R Soc B 365:4051-4063
# DOI: 10.1098/rstb.2010.0208
#
# Core claim: metabolic rate is the spine of a correlated
# life-history syndrome — high-metabolism organisms have shorter
# lifespan, earlier/more reproduction, and more energy throughput.
# The "pace-of-life" continuum.
#
# clade test: sweep `metabolic_rate_init_mean` with
# `max_age_scales_with_metabolism = TRUE`. Measure multiple traits
# and test for a correlated shift.
#
# Toolkit demo:
#   - hypothesis_sweep() with multiple metrics (age, births,
#     energy) captures the correlated syndrome directly.
#   - viability_report() on one run confirms agents aren't at a
#     pathological fitness edge.

suppressPackageStartupMessages({
  if (requireNamespace("devtools", quietly = TRUE))
    devtools::load_all(quiet = TRUE)
  else
    library(clade)
})

base <- default_specs()
base$grid_rows      <- 40L
base$grid_cols      <- 40L
base$n_agents_init  <- 120L
base$max_agents     <- 500L
base$max_ticks      <- 2000L
base$grass_rate     <- 0.15
base$n_predators_init <- 0L

# Fix metabolic rate at the init_mean (no evolution, no mutation) so
# the sweep is a pure dose-response — not an evolved trait.
base$metabolic_rate_evolution       <- TRUE    # must be TRUE to read init_mean
base$metabolic_rate_mutation_sd     <- 0.0     # freeze
base$max_age_scales_with_metabolism <- TRUE    # Tier-2 fix: max_age ∝ 1/rate

METABOLIC_RATES <- c(slow = 0.5, mid_slow = 0.8, mid = 1.0,
                     mid_fast = 1.5, fast = 2.0)

conds <- setNames(
  lapply(METABOLIC_RATES, function(r) {
    list(metabolic_rate_init_mean = r)
  }),
  names(METABOLIC_RATES)
)

# ---------------------------------------------------------------
# hypothesis_sweep with multi-trait metrics
# ---------------------------------------------------------------
cat("=== Réale 2010: pace-of-life syndrome sweep ===\n")
sweep <- hypothesis_sweep(
  base_specs = base,
  conditions = conds,
  seeds = 1:8,
  metrics = list(
    mean_age    = function(t) mean(tail(t$mean_age, 500L), na.rm = TRUE),
    births_per_tick = function(t) mean(tail(t$n_births, 500L), na.rm = TRUE),
    mean_energy = function(t) mean(tail(t$mean_energy, 500L), na.rm = TRUE),
    final_n     = function(t) mean(tail(t$n_agents, 500L), na.rm = TRUE)
  ),
  n_cores = 40L
)
print(sweep)

# ---------------------------------------------------------------
# Contrasts + Spearman tests for each trait
# ---------------------------------------------------------------
contrasts <- list(
  age_fast_vs_slow    = c("slow", "fast"),
  age_mid_vs_slow     = c("slow", "mid"),
  births_fast_vs_slow = c("slow", "fast")
)

cat("\n=== Mean age: fast-pace vs slow-pace ===\n")
rpt_age <- hypothesis_report(sweep, contrasts, metric = "mean_age")
print(rpt_age)

cat("\n=== Births per tick: fast-pace vs slow-pace ===\n")
rpt_births <- hypothesis_report(sweep, contrasts, metric = "births_per_tick")
print(rpt_births)

# Per-trait Spearman — the pace-of-life SYNDROME requires correlated
# shifts across multiple traits.
rates <- as.numeric(METABOLIC_RATES[sweep$runs$condition])
sp_age    <- cor(rates, sweep$runs$mean_age,        method = "spearman")
sp_births <- cor(rates, sweep$runs$births_per_tick, method = "spearman")
sp_energy <- cor(rates, sweep$runs$mean_energy,     method = "spearman")
cat(sprintf("\nSpearman(rate, mean_age)      = %+.3f  (expect NEGATIVE)\n", sp_age))
cat(sprintf("Spearman(rate, births_per_tick) = %+.3f  (expect POSITIVE)\n", sp_births))
cat(sprintf("Spearman(rate, mean_energy)   = %+.3f  (expect POSITIVE or null)\n", sp_energy))

# ---------------------------------------------------------------
# Viability check on one representative run (the mid rate)
# Demonstrates clade's viability_report tool — ensures agents are
# not at a fitness cliff.
# ---------------------------------------------------------------
cat("\n=== Viability spot-check at mid-rate, seed 1 ===\n")
s_check <- base
s_check$metabolic_rate_init_mean <- METABOLIC_RATES["mid"]
s_check$random_seed <- 1L
env_check <- run_alife(s_check, verbose = FALSE)
vr <- viability_report(get_run_data(env_check))
print(vr)

saveRDS(list(sweep = sweep,
             reports = list(age = rpt_age, births = rpt_births),
             spearmans = list(age = sp_age, births = sp_births, energy = sp_energy),
             viability = vr),
        "dev/audit/fidelity/paper_reale_2010.rds")
cat("\nSaved: dev/audit/fidelity/paper_reale_2010.rds\n")
