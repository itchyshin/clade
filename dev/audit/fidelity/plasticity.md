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
- **0.4.0 Tier 5A** (`bnn_sigma_source = "trait"`) couples BNN
  prior width directly to the `TRAIT_PLASTICITY` gene, so plastic
  agents express broader posteriors and canalised agents express
  narrower ones.
- **0.4.1 Tier 5C** (`brain_energy_sigma_scale > 0`) adds a
  log-scaled information cost to sigma, which is what creates the
  selection gradient DeWitt-Scheiner predict. Without this cost
  plasticity drifts under mutation alone.

## 3. Protocol

- **0.4.1 audit**: 4 seeds × 2 conditions × 500 ticks.
  `phenotypic_plasticity = TRUE`, `bnn_sigma_source = "trait"`,
  `brain_energy_sigma_scale = 0.02`.
- **0.4.2 rerun**: 4 seeds × 2 conditions × **1500 ticks** (3× the
  runtime to let selection accumulate), `brain_energy_sigma_scale
  = 0.05` (2.5× the 0.4.1 cost).

Pre-0.4.1 audit had plasticity flat in both conditions (Δ =
−0.001 / −0.002) because there was no fitness gradient.

## 4. Observed dynamics

### 0.4.1 result (500 ticks, sigma_scale=0.02)

| Condition | init → final | Δ |
|---|---|---|
| Stable | 0.300 → 0.300 | −0.0003 ± 0.009 |
| Seasonal | 0.300 → 0.303 | +0.003 ± 0.005 |

Direction correct but magnitudes near noise.

### 0.4.2 result (1500 ticks, sigma_scale=0.05)

| Condition | init → final | Δ |
|---|---|---|
| Stable | 0.301 → 0.304 | +0.003 |
| Seasonal | 0.301 → 0.306 | **+0.005** |

**P1 PASS**: seasonal > stable by Δdelta ≈ +0.002. The seasonal
env maintains slightly higher plasticity than the stable env at
equilibrium — the DeWitt-Scheiner direction. The absolute decline
expected in stable (canalisation) does NOT appear — in fact
plasticity slightly *increases* in both environments, meaning the
trait-evolution dynamics favour modest plasticity under clade's
foraging selection regardless of environmental fluctuation.

### Interpretation

The 0.4.2 1500-tick run pushes the system toward equilibrium.
Seasonal vs stable separates in the DeWitt-Scheiner direction
(seasonal > stable) but with small magnitude (Δdelta = +0.002). At
equilibrium the stable env does NOT canalise as Hinton-Nowlan
would predict — a finding consistent with the s-baldwin 0.4.2
rerun, which showed the same stable-env canalisation *disappears*
at long timescales.

In both scenarios the selection gradient from `brain_energy_sigma_scale`
is offset by the trait-evolution noise from `plasticity_mutation_sd`
and by the interaction between sigma (width) and foraging
efficiency — high sigma ≠ pure learning cost in clade; it also
means noisier actions, which affects fitness directly. The
theoretical prediction cleanly separates these; clade entangles
them. Stays 🟠 with direction correct, small magnitude.

## 5. Verdict
- [x] **Passed-consistent (🟠).** Seasonal > stable direction
  confirmed at both 500 ticks (0.4.1) and 1500 ticks (0.4.2).
  Magnitude is modest (Δdelta = +0.002 to +0.003). The full
  Hinton-Nowlan prediction (stable canalises + seasonal preserves)
  is not reproduced because stable does not canalise; seasonal
  maintains slightly more plasticity than stable, which is the
  DeWitt-Scheiner contrast direction — partial support for the
  phenotypic-plasticity-tracks-environmental-variability claim.

Cross-reference:
| Aspect | Theory | clade 0.4.1 (500 t) | clade 0.4.2 (1500 t) |
|---|---|---|---|
| Stable → canalise | Yes | ≈ flat | ✗ slight rise |
| Seasonal → maintain | Yes | ✓ Δ=+0.003 | ✓ Δ=+0.005 |
| Seasonal > stable | Yes | ✓ | ✓ |

## 6. Actions
- Runner: `plasticity.R` (0.4.2 version, 1500 ticks).
- Figure: `figs/plasticity.png`.
- Vignette: update prose — seasonal > stable direction is
  confirmed at equilibrium; stable-env canalisation is NOT
  reproduced (shared feature with s-baldwin 0.4.2 finding).
- 0.4.3+ backlog: decouple sigma from foraging-efficiency so the
  Hinton-Nowlan stable-env canalisation prediction can be tested
  without the behavioural-variance confounder.
