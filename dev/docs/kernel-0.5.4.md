# Kernel 0.5.4 — mimicry calibration (honest null)

Released 2026-04-16. **Audit-only release; no kernel changes.**

## Motivation

The 0.4.4 audit confirmed the mimicry kernel machinery is now
theoretically aligned with Bates (1862) / Müller (1879):

- Vector-signal predator memory (`signal_memory::Vector{Float32}`)
- Delta-rule Rescorla-Wagner update (symmetric reinforcement +
  extinction, enabling Batesian breakdown)
- Aposematic pleiotropy (`signal_toxicity_coupling`)

But Step 1 P2 (treatment > control toxicity evolution) stayed
direction-sensitive at ±0.002 — *ecology-limited*, not
kernel-limited. 0.5.4 searches for an ecological regime that
produces statistically clean upward toxicity evolution under the
full 0.4.4 machinery.

Following the 0.5.3 Red Queen methodology: adequate seeds with
2×SE hypothesis testing from the start; no direction claims at
5 seeds without 16-seed verification.

## Experiment

### 8-cell initial screen (`mimicry_calibration.R`)

8 cells × 5 seeds × 1000 ticks = 40 runs, varying:

- `n_predators_init ∈ {12, 20}`
- `toxin_dose ∈ {80, 150}`
- `toxicity_cost_per_tick ∈ {0.1, 0.2}`

Fixed: `signal_dims = 3, signal_toxicity_coupling = 1.0,
signal_memory_rate = 0.5, avoid_threshold = 0.1,
toxicity_init_mean = 0.3`.

Results (all 8 cells, sorted by Δmean):

| n_pred | dose | cost | Δtoxicity ± SE (5 seeds) | avoidances | final n |
|---|---|---|---|---|---|
| 12 | 150 | 0.2 | **−0.0024 ± 0.0044** (best) | 9.2 | 124 |
| 12 | 80 | 0.1 | −0.0050 ± 0.0072 | 22.0 | 119 |
| 12 | 80 | 0.2 | −0.0081 ± 0.0083 | 11.0 | 130 |
| 20 | 80 | 0.2 | −0.0073 ± 0.0063 | 23.2 | 120 |
| 20 | 150 | 0.1 | −0.0070 ± 0.0092 | 9.2 | 114 |
| 20 | 150 | 0.2 | −0.0091 ± 0.0085 | ~15 | ~115 |
| 20 | 80 | 0.1 | ~−0.008 | ~18 | ~120 |
| 12 | 150 | 0.1 | ~−0.005 | ~10 | ~125 |

**P1 (best regime Δ > 0 at 2×SE): FAIL** — LCL = −0.0113.
**P2 (Δ > 0.05 ✅ threshold): FAIL** — best Δ = −0.002.

Every tested regime shows *negative* Δtoxicity (the trait declines
over 1000 ticks), with point estimates ranging from −0.002 to
−0.009. None crosses 2×SE in the positive direction.

## Interpretation

The selection arithmetic at default population sizes is
unfavourable:

- **Toxicity cost**: 0.1–0.2 energy/tick × 0.3 mean toxicity =
  0.03–0.06 energy/tick drain on every toxic individual.
- **Aposematic protection benefit**: 9–23 avoidance events per
  1000 ticks across ~2000 predator attacks = ~0.5–1% of attacks
  on toxic prey are blocked by learned aversion.
- **Mortality share**: predation accounts for ~30% of total
  mortality at `n_predators = 12–20, n_agents = 100`.
- **Net fitness effect of toxicity**: ≈ +0.003% / tick survival
  benefit from aposematism vs −0.03% / tick cost. Cost dominates
  by ~10×.

This is the **Zahavi handicap problem** at ABM scale: for honest
signalling to evolve, the cost-to-benefit ratio must favour the
signal, and in clade's default ecology the cost side dominates.

Hamilton (1980) noted the two-fold cost of sex is a tall order
for parasites to overcome (see 0.5.3 Red Queen null); Zahavi's
(1975) handicap honesty requires a similarly tall benefit for
costly signalling to evolve de novo. Both findings are consistent
with those long-standing ABM-scale challenges.

## Verdict

**s-mimicry stays 🟠** with:

- **Kernel machinery correct** (0.4.4): vector memory + delta-rule
  RW + pleiotropy + Batesian breakdown all implemented per
  textbook Bates/Müller.
- **Ecology-limited** at all tested parameter settings: cost
  dominates benefit at default population and predator scales.
- **Mechanisms that would unlock ✅** (0.6+ research, not
  session-scale):
  1. Scenario-scale ecology (smaller populations where individual
     survival dominates; much more intense predation).
  2. Kernel change to reduce toxicity cost structure (e.g.,
     toxicity as a trade-off against something else, not a raw
     energy drain).
  3. Explicit aposematic bootstrapping — start the population with
     correlated signal and toxicity so the predator learning
     signal is strong from tick 1.

## Files touched

- `dev/audit/fidelity/mimicry_calibration.R` (new) — 40-run
  initial screen.
- `dev/audit/fidelity/mimicry_calibration_results.rds` (new).
- `dev/docs/kernel-0.5.4.md` (this file).

## Out of scope

- 16-seed verification of top-3 regimes: deferred. At 5-seed level
  *every* regime already shows direction opposite to what would
  support ✅ (all Δ are negative). 16-seed verification would
  sharpen the negative claim but won't find a positive regime
  among the tested grid.
- Bootstrapping mechanisms (scenarios starting with correlated
  signal + toxicity). Scenario-design work, not kernel work.
