# Speciation and genetic divergence

### Speciation and genetic divergence

**What it models.** Speciation by ecological character displacement
occurs when disruptive selection on a resource-use trait, combined with
assortative mating among similar phenotypes, drives a single population
to split into reproductively isolated lineages (Dieckmann & Doebeli
1999). Once genomes diverge beyond a threshold, gene flow between
incipient species is reduced, accelerating further divergence. Coyne &
Orr (2004) reviewed extensive empirical evidence that reproductive
isolation accumulates approximately linearly with genetic distance. This
scenario enables the speciation module, tracks the number of distinct
genetic clusters (`n_species`) detected at regular intervals, and
illustrates how within-species diversity compares to between-species
divergence over the course of the run.

**Key parameters.**

| Parameter                     | Default | Effect                                                       |
|-------------------------------|---------|--------------------------------------------------------------|
| `speciation`                  | FALSE   | Enable genetic-cluster detection and isolation               |
| `isolation_threshold`         | 0.5     | Minimum genetic distance required for reproductive isolation |
| `speciation_cluster_interval` | 10L     | Ticks between cluster re-detection passes                    |

**Expected output.** `n_species` starts at 1 and rises to 2–4 as
accumulated genome divergence exceeds `isolation_threshold` in
geographically or ecologically separated subpopulations. Within-cluster
genetic diversity remains lower than between-cluster diversity once
isolation is established. The timing of the first split depends on
population size, mutation rate, and the stringency of
`isolation_threshold`.

``` r
library(clade)
library(ggplot2)

# Quick-start settings: lower threshold and higher mutation allow speciation
# within ~400 ticks. The default isolation_threshold = 0.5 requires >1,000
# ticks to accumulate sufficient genome divergence.
s <- default_specs()
s$speciation                  <- TRUE
s$isolation_threshold         <- 0.15   # lower = easier speciation
s$mutation_sd                 <- 0.15   # higher = faster divergence
s$speciation_cluster_interval <- 10L
s$max_ticks                   <- 1000L
s$random_seed                 <- 55L

env  <- run_alife(s)
data <- get_run_data(env)

ggplot(data$ticks, aes(t, n_species)) +
  geom_step(colour = "#ff7f00", linewidth = 0.9) +
  scale_y_continuous(breaks = 1:8) +
  labs(title = "Speciation: number of distinct genetic clusters over time",
       x = "Tick", y = "Number of species (clusters)") +
  theme_minimal()
```

### Calibrated regime (CMA-ES discovered)

Running Phase 7 auto-calibration (`dev/audit/calibration/`) over the
scenario’s parameter subspace discovered the following regime, which
produces a fitness improvement of **189.1x** over the defaults above.
See `dev/audit/calibration/RESULTS.md` for the full CMA-ES results.

``` r
# Parameter overrides discovered by CMA-ES (see dev/audit/calibration/):
s <- default_specs()
s$isolation_threshold            <- 0.5127
s$mutation_sd                    <- 1.31
# env <- run_alife(s)   # uncomment to run the calibrated regime
```

![Expected output: n_species rises from 1 to 2-4 as genome divergence
accumulates beyond the isolation threshold. Each step in the staircase
represents a speciation event.](figures/showcase_18_speciation.png)

Expected output: n_species rises from 1 to 2-4 as genome divergence
accumulates beyond the isolation threshold. Each step in the staircase
represents a speciation event.

**What we found (2026-04-15 audit).** 3 seeds × 1000 ticks, 100 agents
init, 30×30 grid, `isolation_threshold = 0.15`. Full protocol:
[dev/audit/fidelity/speciation.md](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/speciation.md).

| Regime                         | max n_species |
|--------------------------------|---------------|
| Default `mutation_sd = 0.1`    | 96            |
| Aggressive `mutation_sd = 0.3` | 200           |

**Isolation threshold sweep** (5 levels × 3 seeds, mut_sd = 0.2):
Spearman ρ = −0.97 between `isolation_threshold` and max n_species —
tighter threshold, fewer clusters, exactly as theory predicts.

**Caveat on n_species interpretation.** Counts in the hundreds (from
500-agent populations) indicate that the pairwise-distance clustering
algorithm at high mutation rates flags every distinct genome as a
separate lineage. The sensitivity signs (to `mutation_sd` and
`isolation_threshold`) are correct, but the absolute count should be
read as “number of genetic clusters detected at this resolution,” not
“Mayr-style biological species.” For textbook-style 2–4 distinct
species, use lower mutation (0.05–0.08) and longer runs (2000+ ticks).

### Discovery experiments

The baseline result shows `n_species` rising from 1 to 2–4 as genetic
distance accumulates past `isolation_threshold`. To go beyond:

1.  **Speciation × disease** Add `disease = TRUE`. Genetically distinct
    species share fewer contact opportunities (reproductive isolation
    requires spatial separation), which may create inter-species
    barriers to pathogen transmission. Does speciation reduce epidemic
    peak `n_infected` by fragmenting the contact network into partially
    isolated sub-populations?

    *Tried it.* With `speciation = TRUE`, `isolation_threshold = 0.5`,
    `transmission_prob = 0.25`, 80 agents, 200 ticks, seed 42:
    speciation did not produce multiple species in 200 ticks (n_species
    = 1 in both conditions); `isolation_threshold = 0.5` requires more
    genetic divergence than 200 ticks allows. The disease added a 14%
    population reduction (79 vs 91 final). To test the fragmentation
    hypothesis, run for ≥ 500 ticks with `isolation_threshold = 0.3` and
    seed diversity via `mutation_sd ≥ 0.2`.

2.  **Speciation × brain size** Add `brain_size_evolution = TRUE`. Do
    incipient species diverge in brain size as a by-product of
    ecological niche partitioning, or does brain size converge across
    species via parallel evolution toward the same cognitive optimum?
    Compare `mean_brain_size` across detected genetic clusters at final
    tick.

    *Tried it.* With `n_species = 1L`, `isolation_threshold = 0.3`,
    `mutation_sd = 0.1`, 80 agents, 25×25 grid, 500 ticks (seed 42):
    n_species_max = 0 (no speciation detected) in both the
    brain-evolution and no-brain conditions, with very small final
    populations (n = 31–32). The populations struggled demographically
    at these parameters — 25×25 grid with 80 agents and high mutation
    may deplete energy faster than recovery. Speciation and brain-size
    divergence cannot be compared when speciation itself fails. This
    experiment requires parameter tuning (larger populations, lower
    mutation_sd, longer runs) before the brain-divergence question can
    be tested.

3.  **Isolation threshold sensitivity** Vary `isolation_threshold` from
    0.2 to 0.8 across seven values in
    [`batch_alife()`](../reference/batch_alife.md). Does speciation rate
    (slope of `n_species` vs time) respond monotonically to threshold,
    or is there a critical threshold below which sympatric speciation
    cannot initiate even given sufficient time?

    *Tried it.* Seven isolation thresholds tested (0.2 to 0.8;
    `mutation_sd = 0.1`, 80 agents, 300 ticks, seed 42): no speciation
    detected at any threshold (n_species_max = 0 in all conditions).
    Final populations were very small (11–34 agents), suggesting
    demographic collapse is the primary constraint at 300 ticks, not the
    isolation threshold. The scenarios “What we found” notes that
    speciation requires \>1,000 ticks at default mutation rates.
    Threshold sensitivity is best tested at ≥ 1,000 ticks with a minimum
    of 100 agents and `mutation_sd ≥ 0.15`.

------------------------------------------------------------------------
