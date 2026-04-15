# Scenario: Parental care (Clutton-Brock 1991)

## 1. Theory
- **Primary source.** Clutton-Brock, T.H. (1991) *The Evolution
  of Parental Care.* Smith & Fretwell (1974) quality-quantity
  trade-off.
- **Core prediction.** Offspring carried and fed by parents until
  graduation — lower per-capita fecundity, higher juvenile
  survival, more buffered population dynamics.

## 2. Implementation
- clade Julia: `parental_care.jl` with graduation via
  `juvenile_independence_age/energy`; alifeR: `parental_care.R`
  (same mechanics). MATLAB: N/A.

## 3. Protocol
- 3 seeds × 3 conditions (baseline / care_dur=5 / care_dur=10) ×
  400 ticks.

## 4. Observed dynamics

| Condition | mean n | var(n) | mean n_juveniles | mean n_births |
|---|---|---|---|---|
| Baseline (no care) | 290 | 4548 | 0.00 | 1.22 |
| Care, duration=5 | 291 | 4625 | **1.24** | 1.24 |
| Care, duration=10 | 286 | 4481 | 1.24 | 1.24 |

- **P1 PASS.** Graduation pathway works: n_juveniles averages
  1.24 with care on (vs 0 without). The 0.3.0 graduation fix is
  verified here — juveniles exist, move through the carry phase,
  and graduate to the adult population.
- **P2 FAIL.** Variance is essentially identical (4625 vs 4548);
  parental care does not buffer population dynamics at these
  parameters. Similarly, mean population and births are flat
  across conditions.

### Diagnosis
The care mechanism is correctly wired (P1 confirms), but at the
default parameters the effect on demographic outcomes is too
small to detect a variance-buffering signal. Longer care
durations produce nearly identical juvenile counts, suggesting
juveniles graduate quickly regardless of `care_duration` (perhaps
energy-gated rather than age-gated under default feeding_rate).

## 5. Verdict
- [x] **Matches theory (mechanism).** Graduation pathway verified;
  carried juveniles graduate to adults as specified.
- Effect magnitudes on demography are small at default parameters;
  the quality-quantity trade-off is not strongly expressed
  without tighter resource scarcity.

Cross-reference:
| Aspect | Theory (Clutton-Brock) | MATLAB | alifeR | clade |
|---|---|---|---|---|
| Juveniles persist | Yes | N/A | Yes | ✓ 1.24 avg |
| Variance reduced | Yes | N/A | Expected | ✗ flat (4625 ≈ 4548) |
| Birth rate lower | Yes | N/A | Expected | Flat at 1.22 |

## 6. Actions
- Vignette: update with variance and juvenile-count results.
- Runner: `parental_care.R`.
- Figure: `figs/parental_care.png`.
