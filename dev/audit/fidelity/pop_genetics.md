# Scenario: Population genetics / heritability (Fisher-Wright)

## 1. Theory
- **Primary sources.** Falconer & Mackay (1996) *Introduction to
  Quantitative Genetics.* Lynch & Walsh (1998) *Genetics and
  Analysis of Quantitative Traits.*
- **Core prediction.** Heritable traits show high lag-1
  autocorrelation in their mean-trajectory as generations slowly
  turn over — the simulated proxy for narrow-sense heritability
  h².

## 2. Implementation
- clade Julia: trait evolution via body_size_evolution flag.
  alifeR: identical. MATLAB: base has ANN weight mutation but no
  explicit trait-heritability calculation.

## 3. Protocol
- 3 seeds × 500 ticks with `body_size_evolution = TRUE`.

## 4. Observed dynamics

| Metric | Value |
|---|---|
| Lag-1 autocorrelation | **0.992 ± 0.001** |
| Mean body_size drift | +0.107 ± 0.018 |

## 5. Verdict
- [x] **Matches theory.** Extremely high lag-1 autocorrelation
  (0.992) indicates strong parent-offspring resemblance — the
  heritability proxy is cleanly positive and reproducible
  (SD = 0.001 across 3 seeds).

Cross-reference:
| Aspect | Theory (Falconer) | MATLAB | alifeR | clade |
|---|---|---|---|---|
| Heritable trait traces | High lag-1 ac | partial | Yes | ✓ 0.992 |
| Directional drift | Yes (under selection) | N/A | Yes | ✓ +0.107 |

## 6. Actions
- Vignette: keep existing "What we found" — already matches.
- Runner: `pop_genetics.R`.
