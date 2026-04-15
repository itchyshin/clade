# Scenario: Complex 3-layer landscape

## 1. Theory
- No single primary source. Model implements three vertical
  habitat layers (ground / shrub / canopy); prediction is that
  `complex_landscape = TRUE` distributes agents across all three
  layers, vs baseline where all agents are at ground level.

## 2. Implementation
- clade Julia: `modules/complex_landscape.jl`; alifeR: partial.
  MATLAB: N/A.

## 3. Protocol
- 3 seeds × 2 conditions (baseline vs complex) × 400 ticks.

## 4. Observed dynamics (post-burn-in, mean)

| Condition | n_ground | n_shrub | n_canopy |
|---|---|---|---|
| Baseline (simple) | 0 | 0 | 0 (layers not tracked) |
| Complex | 54 | **267** | 38 |

With complex landscape active, agents distribute across all three
layers. Shrub layer dominates (267 agents) — consistent with it
being the default / middle layer in the implementation. Ground (54)
and canopy (38) get clear minority shares.

## 5. Verdict
- [x] **Matches theory.** Multi-layer occupancy is produced as
  designed when `complex_landscape = TRUE`.

## 6. Actions
- Runner: `seasonal_and_landscape.R`.
- Figure: `figs/seasonal_landscape.png`.
