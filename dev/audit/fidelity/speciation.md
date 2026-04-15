# Scenario: Speciation & genetic divergence

## 1. Theory

- **Primary sources.**
  - Dieckmann, U. & Doebeli, M. (1999) On the origin of species by
    sympatric speciation. *Nature* 400:354–357.
  - Coyne, J.A. & Orr, H.A. (2004) *Speciation.* Sinauer.
- **Core prediction.** With sufficient mutation input and a
  genetic-distance-based isolation threshold, a single population
  fragments into multiple reproductively-isolated lineages. Number
  of lineages scales with mutation rate and inversely with
  isolation threshold.
- **Quantitative expectations.**
  1. Speciation ON + sufficient mutation + time → `n_species > 1`.
  2. Higher `mutation_sd` → more speciation events.
  3. Lower `isolation_threshold` → more species detected.

## 2. Implementation

- **clade Julia:** [inst/julia/src/modules/speciation.jl](../../../inst/julia/src/modules/speciation.jl)
  (193 lines). Genetic-distance-based clustering every
  `speciation_cluster_interval` ticks.
- **alifeR:** [alifeR/R/speciation.R](../../../../alifeR/R/speciation.R)
  (114 lines). Same clustering logic.
- **MATLAB:** N/A.

## 3. Protocol

- Step 1: 3 seeds × 2 regimes (mut=0.1 vs 0.3) × 1000 ticks at iso=0.15.
- Step 2: 3 seeds × 5 isolation thresholds {0.10, 0.15, 0.25,
  0.40, 0.60} at mut_sd = 0.2.
- Wall time: ~10 min.

## 4. Observed dynamics

### Step 1 — mutation_sd effect

| Regime | max n_species (1000 ticks) |
|---|---|
| default mut_sd = 0.1 | 96.0 ± 0.0 |
| aggressive mut_sd = 0.3 | 200.0 ± 0.0 |

**P1 PASS** (speciation fires).
**P2 PASS** (higher mut → more species).

### Step 2 — isolation threshold sweep

| `isolation_threshold` | max n_species |
|---|---|
| 0.10 | 200.0 |
| 0.15 | 200.0 |
| 0.25 | 112.3 ± 3.8 |
| 0.40 | 89.7 ± 1.5 |
| 0.60 | 79.3 ± 2.1 |

**P3 PASS, Spearman ρ = −0.97.** Monotonic: stricter threshold →
fewer species, exactly as theory predicts.

### Observation: n_species counts are unexpectedly large

A 500-agent population producing 200 species means ~40% of the
population is treated as a singleton lineage. This is an artefact
of the pairwise-distance clustering algorithm at high mutation
rates: every offspring diverges enough from siblings to be placed
in a fresh cluster. The qualitative predictions (sensitivity to
`mutation_sd` and `isolation_threshold`) all hold, but the
absolute `n_species` count should be interpreted as "number of
genetic clusters detected at this resolution," not "distinct
biological species" in Mayr's sense. For textbook-style 2–4
species outcomes, lower mutation and longer runs would be needed.

Figure: [figs/speciation.png](figs/speciation.png).

## 5. Verdict

- [x] **Matches theory (sensitivity signs correct).** All three
      qualitative predictions pass. Quantitative counts of
      `n_species` are algorithm-dependent (every distinct genome
      flagged) rather than Mayr-style biological species counts.

### Cross-reference table

| Aspect | Theory | MATLAB | alifeR | clade |
|---|---|---|---|---|
| Speciation fires | Yes | N/A | Yes | ✓ n_species > 1 |
| mut_sd ↑ → n_species ↑ | Yes | N/A | Yes | ✓ 96 → 200 |
| iso_thresh ↓ → n_species ↑ | Yes | N/A | Yes | ρ = −0.97 |
| Species = Mayr-style | Expected | N/A | Expected | **No — algorithmic clusters** |

## 6. Actions taken

- Vignette: update with 3-seed 1000-tick results + caveat about
  n_species interpretation.
- Kernel: none. A semantic-level improvement (hierarchical
  clustering producing fewer, larger clusters) would better match
  Mayr-style species counts — flag for 0.4.0.
- Runner: `dev/audit/fidelity/speciation.R`.
- Figure: `dev/audit/fidelity/figs/speciation.png`.
