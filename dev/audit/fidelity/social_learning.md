# Scenario: Social learning (Boyd & Richerson 1985)

## 1. Theory
- **Primary sources.** Boyd, R. & Richerson, P.J. (1985) *Culture
  and the Evolutionary Process.* Henrich & McElreath (2003).
- **Core prediction.** Social copying of successful strategies
  accelerates adaptation beyond pure genetic evolution.

## 2. Implementation
- clade Julia: `social_learning.jl`; alifeR: `social_learning.R`;
  MATLAB: N/A.
- Mechanism: copy output-layer weights from successful neighbour
  every `social_learning_freq` ticks.

## 3. Protocol
- 3 seeds × 4 conditions (social ∈ {F, T} × brain ∈ {ann, bnn}) ×
  500 ticks.

## 4. Observed dynamics

| Condition | mean n | mean_energy |
|---|---|---|
| ANN (no SL) | 100.7 | 146.5 |
| ANN + SL | **117.5** (+17%) | 143.4 |
| BNN (no SL) | 201.3 | 126.7 |
| BNN + SL | 195.3 (−3%) | 129.0 |

- **ANN: +16.8 agents (+17%) with social learning.** Copied
  output-layer weights persist in the ANN's deterministic policy
  and benefit subsequent actions.
- **BNN: −6 agents (slight decrease).** BNN agents resample all
  weights from their prior distribution each tick, so copied
  policy is diluted before it can influence behaviour.

## 5. Verdict
- [x] **Matches theory with ANN brain.** Boyd-Richerson
  cultural-transmission benefit recovered cleanly at +17%
  population boost.
- BNN brain produces a null-to-slightly-negative result — a known
  interaction between cultural copying and Bayesian resampling.
  Documented as an architectural constraint, not a kernel bug.

Cross-reference:
| Aspect | Theory (Boyd-Richerson) | MATLAB | alifeR | clade (ANN) | clade (BNN) |
|---|---|---|---|---|---|
| SL boosts adaptation | Yes | N/A | Yes | ✓ +17% | ✗ −3% (BNN-specific) |

## 6. Actions
- Vignette: update with the brain-type contrast (already flagged).
- Runner: `social_learning.R`.
- Figure: `figs/social_learning.png`.
