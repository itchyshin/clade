# Scenario: Seasonal dynamics

## 1. Theory
- No single primary source; the model implements a sinusoidal
  multiplier on grass growth rate (Fretwell 1972 seasonality; many
  ecology textbooks). Expected signature: grass_coverage shows
  half-period anti-correlation at lag = season_length / 2.

## 2. Implementation
- clade Julia: seasonal modulation in `Clade.jl:428–433`.
  alifeR: same mechanism. MATLAB: `seasonLength` flag.

## 3. Protocol
- 3 seeds × 3 amplitudes {0.0, 0.4, 0.8} × 400 ticks,
  `season_length = 50`.

## 4. Observed dynamics

| `seasonal_amplitude` | lag-25 autocorr | variance(grass_coverage) |
|---|---|---|
| 0.0 | **+0.629** (stable, no cycle) | 0.004 |
| 0.4 | −0.096 (moderate cycle) | 0.008 |
| 0.8 | **−0.581** (strong half-period anti-corr) | 0.018 |

Classic sinusoidal signature: at amp=0.8, grass coverage at lag 25
(half the 50-tick season) is strongly anti-correlated with the peak,
exactly the textbook prediction. Variance scales monotonically.

## 5. Verdict
- [x] **Matches theory.** Seasonal modulation produces the
  expected half-period anti-correlation with clean scaling across
  three amplitude levels.

## 6. Actions
- Runner: `seasonal_and_landscape.R`.
- Figure: `figs/seasonal_landscape.png` (combined with complex landscape).
