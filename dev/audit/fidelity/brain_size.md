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

- **0.4.1 grid**: 3 cost scales × 3 care durations × 2 conditions ×
  3 seeds × 400 ticks. Best Δdelta = +0.005 at grid-max, below the
  0.05 ✅ threshold.
- **0.4.2 sweep**: fix the best 0.4.1 cell (cost_scale=3.0,
  care_duration=15) and sweep `brain_energy_base ∈ {0.001, 0.005,
  0.010}`. Tests whether the kernel-as-biology doc's diagnosis —
  "brain-energy cost too shallow at default 0.001" — actually
  explains the pre-0.4.2 magnitude limit.

## 4. Observed dynamics

### 0.4.2 cost sweep (cost_scale=3.0, care_duration=15)

| brain_energy_base | care Δ | no-care Δ | **Δdelta** | care n | no-care n |
|---|---|---|---|---|---|
| 0.001 (default) | −0.010 | −0.018 | +0.009 | 171 | 159 |
| 0.005 | −0.018 | −0.021 | +0.003 | 88 | 81 |
| **0.010** | **+0.011** | **−0.108** | **+0.118** | **41** | **30** |

At `brain_energy_base = 0.010` (10× the default) the parental
provisioning signal emerges sharply: Δdelta = +0.118 ± 0.073,
well above the 0.05 ✅ threshold.

### Mechanism

At `brain_energy_base = 0.010` the cost per synaptic weight is
~10× higher than default. Unprovisioned newborns can't afford the
brain cost — they starve and brain size **crashes** (Δ = −0.108).
With parental care (feeding_rate=3.0 for 15 ticks), newborns are
buffered past the critical window, survive, and brain size *rises*
slightly (Δ = +0.011). The parental-provisioning channel matters
most when the metabolic gradient is steep; at default
`brain_energy_base = 0.001`, it's too shallow for the care
intervention to produce a visible shift.

Population cost: at base=0.010 final n drops from ~160 (default) to
~35. The signal is real but comes at the price of a smaller
population under the heavier metabolic load. This is biologically
sensible — expensive brains are only maintained in high-provision
regimes (van Schaik et al. 2023).

## 5. Verdict
- [x] **Matches theory (✅) at elevated `brain_energy_base`.** At
  `brain_energy_base = 0.010` the parental-provisioning signal
  exceeds the 0.05 threshold by >2×. Direction is robust across
  all 3 seeds.
- Default (0.001) keeps the audit result at 🟠 magnitude — scenario
  authors wanting a visible care-vs-no-care contrast should
  override `brain_energy_base` accordingly. A super-linear cost
  scaling in 0.4.3 would let the default reach the same gradient
  without needing manual override.

Cross-reference:
| Aspect | Theory | clade 0.4.1 (default base) | clade 0.4.2 (base=0.010) |
|---|---|---|---|
| care > no-care | Yes | ✓ Δdelta +0.009 | ✓ Δdelta +0.118 |
| Δdelta > 0.05 (✅) | — | ✗ | ✓ |

## 6. Actions
- Runner: `brain_size.R` (0.4.2 cost sweep).
- Figure: `figs/brain_size.png` (base × cost_scale heatmap).
- Vignette: update with 0.4.2 finding and recommend `base=0.010`
  for brain-size scenarios.
- 0.4.3 backlog: super-linear brain-size cost gradient
  (`brain_energy ∝ brain_size^1.5`) so the default base reaches
  the same selection strength without scenario-specific override.
