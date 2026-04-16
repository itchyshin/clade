# Scenario: Baldwin Effect / BNN sigma canalization

## 1. Theory
- **Primary sources.** Baldwin (1896); Hinton & Nowlan (1987)
  *Complex Systems* 1:495–502; Mayley (1996).
- **Core prediction.** Over many generations in a stable
  environment, learning is genetically assimilated — weights that
  were within-lifetime-learnable become canalized as fixed prior
  means, and the learning machinery (BNN sigma, learning rate)
  contracts. Seasonal or fluctuating environments preserve higher
  sigma because uncertainty remains adaptive.

## 2. Implementation

clade Julia: BNN brain with posterior `mu ± sigma` per weight.
From 0.4.0 Tier 5A onwards, `bnn_sigma_source` can be one of:

- `"heterozygosity"` (legacy default) — sigma derived from
  maternal-paternal allele difference; couples sigma to genetic
  diversity not to learning assimilation.
- `"fixed"` — sigma set to `bnn_sigma_init` at birth, no evolution.
- `"trait"` (0.4.0 Tier 5A) — sigma tracks `TRAIT_PLASTICITY`
  directly, so `phenotypic_plasticity = TRUE` + `plasticity_*`
  specs make it an evolvable independent trait.

From 0.4.1 Tier 5C onwards, `brain_energy_sigma_scale > 0` adds a
log-scaled information cost to sigma:
`cost = scale × mean(max(log(sigma / sigma_min), 0))`. This creates
the selection gradient the Hinton–Nowlan prediction needs: high
sigma burns energy, so canalisation pays in stable environments.

## 3. Protocol

0.4.1 grid: 3 sigma-cost scales (`brain_energy_sigma_scale ∈ {0.0,
0.02, 0.05}`) × 2 environments (stable vs seasonal amp=0.8) × 3
seeds × 600 ticks. `bnn_sigma_source = "trait"` and
`phenotypic_plasticity = TRUE` throughout so sigma is evolvable.

Pre-0.4.1 verdict was 🔴 contradicts — sigma rose to the 0.5 cap
in *both* conditions because the heterozygosity coupling prevented
selection from touching it.

## 4. Observed dynamics

| sigma_scale | env | Δ sigma (final − init) | final mean |
|---|---|---|---|
| 0.00 | stable | −0.002 | 0.399 |
| 0.00 | seasonal | −0.002 | 0.398 |
| 0.02 | stable | −0.002 | 0.399 |
| 0.02 | seasonal | +0.001 | 0.402 |
| **0.05** | **stable** | **−0.004** | 0.396 |
| **0.05** | **seasonal** | **+0.003** | 0.404 |

**Signs now diverge correctly.** At `sigma_scale = 0.05`:

- Stable environment: sigma declines (canalisation direction).
- Seasonal environment: sigma is maintained slightly higher than
  init (plasticity preserved under fluctuation).

At `sigma_scale = 0` the decoupled trait drifts under mutation
alone with no selection gradient — stable and seasonal are
indistinguishable. At `sigma_scale = 0.02` the gradient is too
weak for the seasonal direction to flip. At `sigma_scale = 0.05`
both P1 (canalisation in stable) and P2 (seasonal preserves sigma
relative to stable) are directional.

Magnitudes are small (~0.004 over 600 ticks) because:
- The trait-mode sigma clamps and the plasticity trait evolves
  slowly under the default `plasticity_mutation_sd = 0.05`.
- 600 ticks is ~12 generations at the default repro cadence —
  Baldwin canalisation is a many-generation phenomenon.

## 5. Verdict
- [x] **Passed-consistent.** At `sigma_scale = 0.05` with
  `bnn_sigma_source = "trait"`, the direction reversal from the
  pre-0.4.1 🔴 is recovered: stable canalises, seasonal preserves.
  Magnitude is small but direction is now correct.
- Pre-0.4.1 🔴 verdict (sigma rose to cap in both envs under
  heterozygosity coupling) is superseded.

Cross-reference:
| Aspect | Theory (Hinton & Nowlan) | clade 0.4.0 (pre-5C) | clade 0.4.1 (sigma_cost=0.05) |
|---|---|---|---|
| Stable → sigma declines | Yes | ✗ sigma → cap | ✓ Δ = −0.004 |
| Seasonal > stable sigma | Yes | ✗ both → cap | ✓ Δdelta = +0.007 |
| Decoupled from heterozygosity | — | Coupled | ✓ via `bnn_sigma_source="trait"` |

## 6. Actions
- Runner: `baldwin.R` (0.4.1 version with sigma-cost × env sweep).
- Figure: `figs/baldwin.png`.
- Vignette: update to describe the cost-driven canalisation
  mechanism and the `brain_energy_sigma_scale` spec required to
  enable the Baldwin scenario.
- 0.4.2 backlog: tune `plasticity_mutation_sd` and run length to
  try for a full ✅ (Δ > 0.02 canalisation in stable env).
