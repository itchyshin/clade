# Scenario: Brain size evolution (parental provisioning hypothesis)

## 1. Theory
- **Primary sources.** van Schaik et al. (2023); Griesser et al.
  (2023); Song et al. (2025). Expensive-brain hypothesis (Aiello &
  Wheeler 1995).
- **Core prediction.** Without parental care, brain size drifts
  downward (cost > benefit for naïve newborns). With parental
  care, brains can evolve upward.

## 2. Implementation
- clade Julia: `brain_size_evolution` + `parental_care`; alifeR:
  partial (no explicit brain_size_evolution module). MATLAB: N/A.

## 3. Protocol
- 4 seeds × 2 conditions (care vs no-care) × 400 ticks,
  `brain_size_cost_scale = 2.0`.

## 4. Observed dynamics

| Condition | init → final brain | Δ from init |
|---|---|---|
| With parental care | 1.100 → 1.097 | **−0.003 ± 0.022** |
| No parental care | 1.102 → 1.091 | **−0.012 ± 0.016** |

- **P1 PASS (directionally).** Care drift > no-care drift
  (Δ-delta = +0.009), matching the parental provisioning
  prediction direction.
- **Magnitudes are tiny.** The vignette's prior "+0.7 with care,
  −0.25 no-care" is not reproduced. Both conditions hover near
  the init value with small stochastic drift.

### Diagnosis

Two possible causes:
1. `brain_size_cost_scale = 2.0` still not strong enough to
   produce a clear cost gradient vs the foraging-signal benefit
   from the `brain_size_sensing_exponent = 0.3` term. Raising
   cost further or removing the sensing bonus would sharpen the
   contrast.
2. Care duration = 15 ticks may not be long enough to fully
   buffer the neonatal foraging deficit.

## 5. Verdict
- [ ] Matches theory
- [x] **Consistent but underpowered.** Direction correct, magnitude
  weak. The care-no-care contrast is only ~0.009 units over 400
  ticks, below practical detection. Needs kernel-level
  re-parameterisation or longer runs.

Cross-reference:
| Aspect | Theory | MATLAB | alifeR | clade |
|---|---|---|---|---|
| No care → brain ↓ | Yes | N/A | Not modelled | ✓ weak (−0.012) |
| Care → brain ↑ | Yes | N/A | N/A | ✗ still slight decline (−0.003) |
| care > no_care | Yes | N/A | Expected | ✓ Δdelta +0.009 |

## 6. Actions
- Vignette: retract the "care = +0.7, no-care = −0.25" claim.
- Runner: `brain_size.R`.
- Figure: `figs/brain_size.png`.
