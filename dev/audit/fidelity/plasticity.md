# Scenario: Phenotypic plasticity (Pigliucci 2001; DeWitt & Scheiner 2004)

## 1. Theory
- **Primary sources.** Pigliucci (2001) *Phenotypic Plasticity.*
  DeWitt & Scheiner (2004) *Phenotypic Plasticity: Functional and
  Conceptual Approaches.*
- **Core prediction.** Plasticity evolves to track environmental
  variability: stable environments favour canalisation (low
  plasticity); predictably variable environments maintain
  intermediate-to-high plasticity.

## 2. Implementation
- clade Julia: `plasticity.jl`; alifeR: partial. MATLAB: N/A.

## 3. Protocol
- 4 seeds × 2 conditions (stable vs seasonal amp=0.7) × 500 ticks.

## 4. Observed dynamics

| Condition | init → final plasticity | Δ |
|---|---|---|
| Stable | 0.300 → 0.298 | −0.001 |
| Seasonal (amp=0.7) | 0.300 → 0.299 | −0.002 |

Both conditions flat. Seasonal is numerically *lower* (Δ = −0.002)
than stable (Δ = −0.001), opposite to DeWitt-Scheiner prediction —
but both within 0.2% of init, so the sign is meaningless.

### Diagnosis
Same family as `s-pace-of-life` and others: the `plasticity` trait
is not strongly coupled to fitness at default parameters. Plastic
agents gain no clear advantage over canalised agents in the
foraging environment; selection signal is near-zero.

## 5. Verdict
- [ ] Matches theory
- [x] **Consistent but underpowered.** No directional signal
  within 500 ticks at default couplings. Needs stronger
  plasticity-fitness linkage in the kernel.

Cross-reference:
| Aspect | Theory | MATLAB | alifeR | clade |
|---|---|---|---|---|
| Stable → canalise | Yes | N/A | Expected | Flat (Δ=-0.001) |
| Seasonal → maintain | Yes | N/A | Expected | Flat (Δ=-0.002) |

## 6. Actions
- Vignette: update with flat-signal finding.
- Runner: `plasticity.R`.
- Figure: `figs/plasticity.png`.
