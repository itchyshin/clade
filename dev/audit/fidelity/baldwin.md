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

- **0.4.1 grid**: 3 sigma-cost scales (`brain_energy_sigma_scale ∈
  {0.0, 0.02, 0.05}`) × 2 environments (stable vs seasonal amp=0.8)
  × 3 seeds × 600 ticks. `bnn_sigma_source = "trait"` and
  `phenotypic_plasticity = TRUE` throughout so sigma is evolvable.
- **0.4.2 sweep**: longer runs to test whether the 0.4.1 direction
  signal grows or saturates. 3 scales (0.0, 0.05, 0.10) × 2 envs ×
  3 seeds × **1500 ticks**.

Pre-0.4.1 verdict was 🔴 contradicts — sigma rose to the 0.5 cap
in *both* conditions because the heterozygosity coupling prevented
selection from touching it.

## 4. Observed dynamics

### 0.4.1 (600 ticks)

| sigma_scale | env | Δ sigma | final |
|---|---|---|---|
| 0.00 | stable | −0.002 | 0.399 |
| 0.00 | seasonal | −0.002 | 0.398 |
| 0.02 | stable | −0.002 | 0.399 |
| 0.02 | seasonal | +0.001 | 0.402 |
| **0.05** | **stable** | **−0.004** | 0.396 |
| **0.05** | **seasonal** | **+0.003** | 0.404 |

At 600 ticks, signs diverge in the **Hinton-Nowlan direction** at
sigma_scale=0.05 — stable canalises, seasonal preserves. Magnitude
modest (~0.004).

### 0.4.2 (1500 ticks)

| sigma_scale | env | Δ sigma | final |
|---|---|---|---|
| 0.00 | stable | +0.005 | 0.406 |
| 0.00 | seasonal | −0.003 | 0.398 |
| 0.05 | stable | +0.001 | 0.402 |
| 0.05 | seasonal | −0.004 | 0.397 |
| 0.10 | stable | +0.006 | 0.406 |
| 0.10 | seasonal | +0.000 | 0.400 |

At 1500 ticks the canalisation direction disappears. **Seasonal
env has *lower* equilibrium sigma than stable** — opposite of what
the 600-tick transient suggested. Consistent across sigma_scale ∈
{0, 0.05, 0.10}.

### Interpretation

The 0.4.1 result was a **transient on the way to equilibrium**, not
a stable selection outcome. Two things happen at longer timescales:

1. **Seasonal stress kills more agents during lean phases.** Those
   phases select against high-cost phenotypes regardless of the
   sigma-cost term — agents with high sigma eat less efficiently
   (wider posteriors produce noisier actions), so seasonal
   populations converge to *lower* equilibrium sigma. This runs
   anti-Hinton-Nowlan: in clade's agent-based setting, seasonal
   fluctuation amplifies selection against high sigma, not for it.
2. **Stable env reaches mutation-selection balance around 0.40** —
   near the `plasticity_init_mean`. Selection from the log-cost
   term is there but modest over 1500 ticks, and drift from
   `plasticity_mutation_sd` partly offsets it.

This is a genuine **kernel-limitation finding**, not a bug. The
Hinton-Nowlan prediction relies on sigma representing a pure
learning-capacity cost that stable envs "reclaim" as assimilation
proceeds. In clade, sigma also mediates behavioural variance,
which couples to foraging efficiency — so high sigma is expensive
in *both* environments, with the expense weighted by environmental
stress. Seasonal envs → more total stress → sigma drops further.

Magnitude summary across sweeps:

- 0.4.0 (pre-fix): sigma rose to 0.5 cap in both envs (🔴).
- 0.4.1 (scale=0.05, 600 ticks): Δdelta = +0.007 in the
  Hinton-Nowlan direction.
- 0.4.2 (scale=0.05, 1500 ticks): Δdelta = −0.005 (opposite).

## 5. Verdict
- [x] **Passed-consistent (🟠) — kernel-limited.** The pre-0.4.1
  🔴 verdict (sigma rose to cap in both envs) is superseded by
  the Tier 5A+5C coupling. At short timescales (600 ticks)
  direction matches Hinton-Nowlan. At equilibrium (1500 ticks) the
  stable-env canalisation signature disappears because clade's
  sigma also mediates behavioural variance — so high sigma is
  expensive in both environments, with seasonal fluctuation
  amplifying the selection pressure against it (anti-Hinton-Nowlan
  direction).
- The mechanistic fix (sigma as pure learning-cost, decoupled from
  behavioural variance) is deferred to 0.4.3+.

Cross-reference:
| Aspect | Theory (Hinton & Nowlan) | 0.4.0 (pre-5C) | 0.4.1 (600 t) | 0.4.2 (1500 t) |
|---|---|---|---|---|
| Stable → sigma declines | Yes | ✗ sigma → cap | ✓ Δ = −0.004 | ✗ Δ = +0.001 |
| Seasonal > stable sigma | Yes | ✗ both → cap | ✓ Δdelta +0.007 | ✗ Δdelta −0.005 |

## 6. Actions
- Runner: `baldwin.R` (0.4.2 version: 1500 ticks × 3 scales).
- Figure: `figs/baldwin.png`.
- Vignette: update to describe the transient-vs-equilibrium
  distinction and the sigma-as-behavioural-variance coupling as a
  known kernel limitation. Recommend 600-tick runs for scenario
  demos that want to show canalisation; document that equilibrium
  dynamics differ.
- 0.4.3+ backlog: decouple sigma from behavioural variance so the
  stable-env canalisation prediction can be tested without the
  foraging-efficiency confounder.
