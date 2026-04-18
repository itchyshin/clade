# Baseline world

### Baseline world

**What it models.** Agents forage on a renewable grass resource and
reproduce when energy exceeds a threshold. The neural-network genome
(brain weights) evolves under natural selection with no additional
modules. This is the simplest demonstration that evolution can occur.

**Key parameters.**

| Parameter     | Default | Effect                                        |
|---------------|---------|-----------------------------------------------|
| `grass_rate`  | 0.10    | Probability that empty cell regrows per tick  |
| `mutation_sd` | 0.05    | Gaussian noise on brain weights per offspring |
| `brain_type`  | `"bnn"` | Neural architecture                           |
| `ploidy`      | 2       | Haploid (1) or diploid (2)                    |

**Expected output.** Population stabilises well below `max_agents`.
Genetic diversity is maintained: neither fixation nor unbounded growth.

``` r
library(clade)

s <- default_specs()
s$grid_rows     <- 30L
s$grid_cols     <- 30L
s$n_agents_init <- 100L
s$max_ticks     <- 500L
s$grass_rate    <- 0.15
s$random_seed   <- 42L

env  <- run_alife(s)
data <- get_run_data(env)
plot_run(data)
```

![Expected output: six-panel run summary showing population dynamics,
mean energy, genetic diversity, births/deaths, grass coverage, and BNN
sigma.](figures/showcase_01_run_dashboard.png)

Expected output: six-panel run summary showing population dynamics, mean
energy, genetic diversity, births/deaths, grass coverage, and BNN sigma.

**What we found (10-seed audit, 2026-04-15).** Running 10 seeds × 500
ticks at 100 agents init, 30×30 grid, `grass_rate = 0.15`:

| Metric                      | Mean ± SD     | Notes                                           |
|-----------------------------|---------------|-------------------------------------------------|
| `n_agents`                  | 256.9 ± 3.5   | Strong carrying capacity                        |
| `mean_energy`               | 129.2 ± 1.1   | 65% of `energy_max = 200`                       |
| `mean_age`                  | 98.3 ± 0.3    | Steady-state age structure                      |
| `genetic_diversity`         | 0.341 ± 0.002 | Rises 0.07 → 0.34 (mutation outpaces selection) |
| `mean_ann_weight_magnitude` | 27.3 ± 0.2    | Init ~5 → evolved 27                            |
| `n_births` per tick         | 1.43 ± 0.03   | Balanced against ~1.43 deaths                   |
| `n_starvations` per tick    | 0.003         | Negligible                                      |
| `grass_coverage`            | 0.385 ± 0.006 | Active grazing equilibrium                      |

Seed-to-seed variability is \< 2% on every metric — the baseline is
exceptionally reproducible.

**Kernel lineage note.** clade’s baseline kernel has diverged
substantially from its MATLAB ancestor (Bulitko 2023,
[alifeR/alife_matlab/codebase/alife.m](https://github.com/itchyshin/alifeR/tree/main/alife_matlab))
and from the alifeR R port. Intentional improvements include diploid
genomes with full meiosis, a Bayesian-NN default brain, input
normalisation to \[0,1\], and scalar trait evolution. A handful of
undocumented changes (eating semantics, grass-to-energy ratio, always-on
age cap, fixed repro cost) are worth flagging for 0.4.0 review. The full
three-way diff is in
[dev/audit/fidelity/baseline.md](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/baseline.md)
§3 and §6.

### Discovery experiments

The baseline result demonstrates that evolution can occur: neural
genomes diverge under selection for foraging. To go beyond:

1.  **Ploidy under crashes** Switch `ploidy = 1L`. Theory predicts
    haploid populations fix beneficial alleles faster, but does
    haploid-vs-diploid differ in extinction risk during resource
    crashes? Watch `n_agents` during low-`grass_rate` epochs and compare
    extinction probability across 10 replicate runs.

    *Tried it.* With `ploidy = 1L` vs `ploidy = 2L`,
    `grass_rate = 0.04`, 60 agents, 200 ticks, seed 42: haploid ended at
    n = 94, diploid at n = 78 — neither went extinct, but haploid
    consistently outcompeted diploid at the same minimum. Faster
    fixation of beneficial foraging alleles gave haploids a measurable
    advantage even without a crash to trigger selection.

2.  **Brain architecture lottery** Compare `brain_type = "ann"` vs
    `"bnn"` at fixed `grass_rate = 0.05`. Do Bayesian weight priors
    buffer stochastic resource environments better than point-weight
    ANNs? Watch `genetic_diversity` and `mean_energy` over 500 ticks
    using
    [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md).

    *Tried it.* Four architectures tested (50 agents, 200 ticks,
    grass_rate = 0.05, seed 42): BNN supported the largest population (n
    = 113, gd = 0.183); ANN and CTRNN showed similar intermediate
    performance (n = 74/78, gd = 0.187); GRN reached the highest mean
    energy (133.1) but the smallest population (n = 64). No single
    architecture dominates. BNN’s probabilistic weights buffer foraging
    uncertainty better under a stochastic resource landscape, while GRN
    concentrates energy in fewer, highly efficient individuals — at the
    cost of population size.

3.  **Hypermutation availability** Add `stress_hypermutation = TRUE` and
    `mutation_rate_evolution = TRUE`. Does the population evolve a lower
    baseline `mutation_sd` when stress-induced hypermutation is
    available as a contingency? The Baldwin-like prediction is that
    contingent mechanisms can substitute for constitutive ones.

    *Tried it.* Adding both flags (50 agents, 200 ticks, seed 42) raised
    genetic diversity slightly (gd = 0.192 vs 0.185 without; from
    multi-seed gallery). The `mean_mutation_rate` column returned NA —
    the Julia backend does not log evolved mutation rate — so the
    Baldwin-like canalization prediction (contingent hypermutation
    reduces constitutive mutation) cannot be confirmed with current
    metrics. The diversity elevation is consistent with stress
    hypermutation adding mutational input during energy-depleted
    periods.

------------------------------------------------------------------------
