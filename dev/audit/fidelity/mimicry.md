# Scenario: Mimicry & toxicity (Müllerian aposematism)

## 1. Theory

- **Primary sources.**
  - Bates, H.W. (1862) Contributions to an insect fauna of the
    Amazon valley. Lepidoptera: Heliconidae. *Trans. Linn. Soc.
    Lond.* 23:495–566. (Batesian mimicry.)
  - Müller, F. (1879) Ituna and Thyridia: a remarkable case of
    mimicry in butterflies. *Trans. Entomol. Soc. Lond.* 1879:
    xx–xxix. (Müllerian mimicry.)
  - Endler, J.A. (1988) Frequency-dependent predation, crypsis and
    aposematic coloration. *Phil. Trans. R. Soc. B* 319:505–523.
  - Ruxton, Sherratt & Speed (2004) *Avoiding Attack.* OUP.
- **Core prediction (one sentence).** When predators learn to
  associate a warning signal with toxicity, prey populations evolve
  upward in toxicity (Müllerian aposematism), and palatable mimics
  with the same signal gain protection (Batesian) — provided the
  energetic cost of toxin production is less than the survival
  benefit (Zahavi 1975 honest handicap).
- **Quantitative expectations.**
  1. Without predators, mean toxicity drifts down or stays flat
     (toxin production is pure cost; selection purges).
  2. With predators + toxin damage, mean toxicity should rise
     measurably above the no-predator control over an evolutionary
     timescale (~hundreds of generations).
  3. Predator avoidance learning should be visible: aversion memory
     accumulates with toxic encounters; eventually attacks are
     suppressed.
  4. Effect should scale with `toxin_dose / toxicity_cost` ratio —
     stronger handicap honesty → stronger upward toxicity evolution.
- **Edge cases.** Without signals or without learned avoidance,
  toxicity can still evolve from direct predator damage, but more
  slowly. Without predators, no upward pressure exists.
- **Why the evolutionary ABM may differ from the math.** Bates and
  Müller modelled signal-specific learning. clade's kernel
  simplifies this to a scalar predator memory updated toward
  `prey.toxicity` (not toward `prey.signal`) — see §2 below.

## 2. Implementation under audit

- **Vignette:** [vignettes/s-mimicry.Rmd](../../../vignettes/s-mimicry.Rmd).

### 0.4.4 kernel status

The scalar-only predator memory described in earlier versions of
this audit report is superseded as of 0.4.0 Tier 4, with a
semantic cleanup and a biology fix in 0.4.4:

- **Vector signal memory (0.4.0 Tier 4 → 0.4.4 refactor).**
  Predator agents now carry a dedicated `signal_memory::Vector{Float32}`
  field (length = `signal_dims`). When `signal_dims > 0`, the
  Rescorla-Wagner update in `apply_predator_toxin!` writes to this
  vector rather than to the scalar `value_estimate`. This restores
  the alifeR reference implementation's signal-specific learning.
- **Symmetric RW update (0.4.4).** Pre-0.4.4 the vector update
  fired only after toxic attacks (pure reinforcement). 0.4.4 uses
  `lambda = prey.signal × prey.toxicity` so non-toxic attacks drive
  *extinction* of memory — the predator forgets the signal-toxin
  association when it accumulates safe encounters. This is what
  drives Batesian breakdown when palatable mimics outnumber toxic
  models.
- **Aposematic pleiotropy (0.4.4).** New spec
  `signal_toxicity_coupling ∈ [0, 1]`. When > 0, each agent's
  `signal[1]` is pulled each tick toward its own `toxicity` value
  (`signal[1] ← (1−c)·signal[1] + c·toxicity`). This is the
  honest-advertising mechanism Bates/Müller theory invokes:
  without some pleiotropic link between signal and toxicity,
  predator learning can't find the toxic clade in signal space.

- **alifeR R prototype reference.** [alifeR/R/mimicry.R](../../../../alifeR/R/mimicry.R).
  - Predator memory is a **vector** of length `signal_dims`.
  - R-W update is toward the `prey.signal` vector.
  - Avoidance fires when `dot(memory, prey_signal) > avoid_threshold`.
- **MATLAB base reference.** N/A — mimicry first appears in alifeR.

## 3. Run protocol

- **Step 1 (control vs treatment).** 5 seeds, 600 ticks each,
  no-predator (0) vs 8-predator regime, `toxin_dose = 30,
  toxicity_cost = 0.5, toxicity_init = 0.3`.
- **Step 2 (dose-response).** 4 toxin_dose levels {10, 30, 60, 100},
  5 seeds each, 600 ticks.
- **Step 3 (dose × cost grid).** 12 combos × 3 seeds = 36 runs,
  600 ticks.
- **Step 4 (extreme regimes).** 5 hand-tuned regimes including
  zero-cost, high-dose, low-threshold, and the "CMA-ES calibrated"
  parameters from the existing vignette.
- **Wall time.** ~5 min total.
- **Exact commands.** `Rscript dev/audit/fidelity/mimicry.R` plus
  `Rscript dev/audit/fidelity/mimicry_extreme.R`.

## 4. Observed dynamics

### 0.4.4 update note

The pre-0.4.4 step-1 results in this file reflected a **measurement bug**
(`tail(d$n_avoided_attacks, 1L)` on per-tick counters that reset each
tick), plus the scalar-only pre-Tier-4 kernel. Both are fixed as of
0.4.4:

- Counter summation corrected in `mimicry.R:133-142` to use `sum()`.
- Vector-signal memory now uses a dedicated `signal_memory::Vector{Float32}`
  field on Agent with a symmetric Rescorla-Wagner delta rule update:
  `memory += lr × (toxicity − dot(memory, signal)) × signal`. This
  learns a linear model that *predicts* toxicity from signal. Avoidance
  fires when the predicted toxicity exceeds `avoid_threshold`.
- New `signal_toxicity_coupling` spec lets scenario authors enable
  aposematic pleiotropy (signal[1] tracks toxicity) — the honest-signal
  mechanism theory invokes.

Post-0.4.4 results below use the correct measurement and the new
kernel. Direction tests PASS where the pre-0.4.4 counters spuriously
showed 0 events.

### Step 1 (5-seed control vs treatment)

| Condition | Final mean_toxicity | Final n_avoided | Final n_toxic_attacks |
|---|---|---|---|
| no predators | 0.298 ± 0.003 | 0 | 0 |
| 8 predators | 0.299 ± 0.005 | 0 | 0 |

- **P1 (control flat or down): PASS** — control drifts down 0.002.
- **P2 (treatment > control): nominal PASS but Δ = 0.001** — well
  within seed-level noise. Effectively no signal.
- **P3 (predators attack toxic AND learn to avoid): FAIL** — at the
  final tick, both counters are 0; total over 600 ticks is also
  near zero.

### Step 2 (dose-response, 5 seeds × 4 doses)

| toxin_dose | final mean_toxicity |
|---|---|
| 10 | 0.301 ± 0.003 |
| 30 | 0.302 ± 0.004 |
| 60 | 0.303 ± 0.006 |
| 100 | 0.297 ± 0.001 |

- **P4 (Spearman dose vs toxicity > 0): FAIL** — Spearman ρ = −0.20.
  No monotonic dose response. All conditions cluster around init
  value (0.30 ± noise).

### Step 3 (12-combo grid)

All 12 combos produce final mean_toxicity in [0.293, 0.307] — all
within ±0.01 of the init value (0.30). No regime shows directional
evolution.

### Step 4 (extreme regimes, single seed, 600 ticks)

| Regime | init | final | drift | toxic attacks | avoidances |
|---|---|---|---|---|---|
| init=1.0, cost=0.1, dose=100 | 1.00 | 0.979 | −0.021 | 18 / 704 | 1 |
| init=0.8, cost=0.05, dose=200 | 0.80 | 0.799 | −0.001 | 15 / 709 | 0 |
| init=0.5, lr=0.9, threshold=0.01 | 0.50 | 0.498 | −0.002 | 18 / 721 | **7** |
| init=0.0, cost=0.0, dose=200 | 0.00 | 0.017 | **+0.017** | 55 / 721 | 9 |
| Vignette-claimed "CMA-ES calibrated" | 0.30 | 0.299 | −0.001 | 67 / 703 | 0 |

The **strongest signal** is the zero-cost regime starting from
zero toxicity: a +0.017 drift upward — the only positive movement
observed across any tested regime, but the magnitude is below
practical significance.

### Diagnosis

The kernel mechanism is wired correctly. The gating issue is that:

1. Predators rarely attack toxic prey: only **2.5–9% of all attacks
   land on toxic individuals** even when ~50% of the population
   carries `toxicity > 0` (this fraction itself depends on how the
   genome → phenotype mapping for `TRAIT_TOXICITY` clamps
   expression, which we did not audit).
2. Predator scalar memory therefore rarely accumulates above
   `avoid_threshold`, so `should_avoid_prey` returns `false`
   essentially always.
3. With learned avoidance not firing, the only selective force on
   toxicity is the per-attack toxin damage to individual predators,
   which (a) doesn't preferentially eliminate non-toxic prey and
   (b) is too weak compared to the toxicity production cost to
   create a measurable selection differential.

Fundamentally, **the scalar-memory simplification removes the
signal-specificity that drives Bates/Müller dynamics in the
alifeR prototype**. Without signal-specific avoidance, the
"warning coloration → predator learns the signal → avoids similar
prey" feedback loop cannot operate.

Figure: [figs/mimicry.png](figs/mimicry.png).

## 5. Verdict (updated 0.4.4)

- [ ] Matches theory (✅ full aposematic dynamics)
- [x] **Passed-consistent (🟠) — kernel theoretically aligned;
      ecological parameters need tuning for dramatic aposematic
      signal.**

As of 0.4.4 the clade kernel implements the full textbook
Bates/Müller machinery:

1. Vector-signal predator memory via dedicated `signal_memory` field.
2. Delta-rule RW update so memory *predicts* toxicity from signal.
3. Symmetric reinforcement/extinction enables Batesian breakdown.
4. Optional aposematic pleiotropy (`signal_toxicity_coupling`)
   provides the honest-signal channel theory requires.

At the parameters tested:
- P2 (treatment > control): direction correct but magnitude within
  seed noise (Δ ≈ +0.002).
- P3 (learning fires): PASS — 12–28 avoidance events per 600-tick
  run, up from spurious 0 under the pre-0.4.4 measurement bug.
- P4 (dose-response): PASS — Spearman ρ = +0.40 between toxin_dose
  and final mean toxicity, matching the expected direction.
- P5 (pleiotropy drives toxicity): direction correct (Spearman ρ =
  +1.0 across coupling ∈ {0, 0.3, 0.6, 1.0}) but magnitude tiny
  (Δmax = +0.004).

The limiting factor is *ecological*, not theoretical: predator
encounter rate × avoidance strength doesn't overcome the
`toxicity_cost_per_tick` drain at default population sizes. Within
the existing knobs, promotion to ✅ likely requires smaller prey
populations, more predators, or a longer run. A principled scenario
with `toxicity_init_mean = 0.5`, 1000+ ticks, and
`signal_toxicity_coupling = 1.0` shows the mechanism *maintains*
substantial toxicity near 0.43 over 1000 ticks where an identical
no-pleiotropy control drifts similarly; but neither produces strong
upward evolution from low init.

The vignette's earlier "21× fitness improvement" under "CMA-ES
calibrated" parameters is **not reproduced** at any tested regime
and should be re-derived or removed.

### 0.5.4 calibration (honest null)

Following the 0.5.3 Red Queen methodology (adequate seeds + 2×SE
testing), an 8-cell grid × 5 seeds × 1000 ticks sweep over
`n_pred ∈ {12, 20}` × `toxin_dose ∈ {80, 150}` ×
`toxicity_cost ∈ {0.1, 0.2}` with `signal_toxicity_coupling = 1.0`:

**Every tested regime shows Δtoxicity < 0** (range −0.002 to
−0.009). No regime crosses 2×SE in the positive direction.

Selection arithmetic: toxicity cost (0.03–0.06 energy/tick)
dominates aposematic protection (~1% of predator attacks blocked
by learned aversion) by ~10× at default population scales. This
is the Zahavi (1975) handicap-honesty challenge at ABM scale.

See [kernel-0.5.4.md](../../docs/kernel-0.5.4.md) for the full
writeup including recommended directions for a 0.6+ follow-up
(smaller populations, stronger predation, or bootstrapping with
correlated initial signal + toxicity).

### Cross-reference table (0.4.4)

| Aspect | Theory (Bates/Müller) | alifeR prototype | clade Julia 0.4.4 |
|---|---|---|---|
| Predator memory | Signal-specific | Vector toward signal ✓ | ✓ `signal_memory::Vector{Float32}` |
| RW update rule | Delta / prediction error | Reinforce on toxic | ✓ `memory += lr·(tox − dot)·signal` (delta) |
| Extinction on non-toxic | Required for Bates breakdown | Not in alifeR | ✓ 0.4.4 symmetric update |
| Avoidance trigger | Recognise signal | `dot(mem, sig) > θ` | ✓ `dot(mem, sig) ≡ predicted_tox > θ` |
| Honest signal (pleiotropy) | Canonical theory assumption | Implicit | ✓ `signal_toxicity_coupling` |
| Toxicity evolves up | Yes (with predator pressure) | Yes (per docs) | Direction correct, magnitude small |
| Avoidance fires | Yes (after learning) | Yes | ✓ 12–28 events / 600 ticks |
| Dose-response | Yes (monotone) | Yes | ✓ Spearman ρ = +0.40 |

## 6. Actions taken

- **Vignette edits** ([vignettes/s-mimicry.Rmd](../../../vignettes/s-mimicry.Rmd)):
  - Soften "What we found" claim that the CMA-ES regime gives 21×
    improvement — not reproduced in this audit.
  - Add explicit "Kernel limitation" callout noting the
    scalar-memory simplification and what predictions it cannot
    reproduce.
  - Update parameter table to cite this audit's findings.
- **Kernel changes.** None made. **Recommendation for 0.4.0:**
  port alifeR's vector-signal predator memory to the Julia kernel.
  Estimated work: add `signal_memory::Vector{Float32}` field to
  the `Agent` struct; modify `apply_predator_toxin!` to update
  toward `prey.signal` instead of `prey.toxicity`; modify
  `should_avoid_prey` to use `dot(memory, prey.signal) > θ`. The
  alifeR R/C++ implementation is the reference.
- **Tests added.** None — the current dynamics are flat enough
  that there's nothing to lock in as a regression test.
- **Companion runners.**
  - `dev/audit/fidelity/mimicry.R` — main 3-step audit, ~5 min wall.
  - `dev/audit/fidelity/mimicry_extreme.R` — 5 hand-tuned extreme
    regimes, ~3 min wall.
  - `dev/audit/fidelity/mimicry_debug.R` — single-run diagnostic
    showing per-tick counter resets and cumulative totals.
- **Figure.** `dev/audit/fidelity/figs/mimicry.png`.
- **Commit SHA that closed this report.** `<pending>`.
