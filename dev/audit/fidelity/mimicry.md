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
- **Specs explored (this audit):**

  ```r
  s$mimicry              <- TRUE
  s$toxicity_init_mean   <- 0.0 to 1.0  (5 levels tested)
  s$toxin_dose           <- 10 to 200   (4 levels tested)
  s$toxicity_cost_per_tick <- 0.0 to 2.0 (5 levels tested)
  s$signal_memory_rate   <- 0.3 / 0.5 / 0.9
  s$avoid_threshold      <- 0.01 to 0.5
  s$n_predators_init     <- 0 / 8 / 15  (no-pred control + 2 high)
  ```

- **clade Julia kernel.** [inst/julia/src/modules/mimicry.jl](../../../inst/julia/src/modules/mimicry.jl).
  Three functions:
  - `apply_toxicity_costs!` — per-tick metabolic drain proportional
    to toxicity (cost × toxicity).
  - `apply_predator_toxin!` — toxin damage to predator (`dose × tox`)
    AND scalar memory update: `value_estimate ← (1−lr)·old + lr·tox`.
  - `should_avoid_prey` — fires when `value_estimate ≥
    avoid_threshold` (and `prey.toxicity > 0` in Müllerian mode).
- **alifeR R prototype reference.** [alifeR/R/mimicry.R](../../../../alifeR/R/mimicry.R).
  - Predator memory is a **vector** of length `signal_dims`.
  - R-W update is toward the `prey.signal` vector, not `prey.toxicity`.
  - Avoidance fires when `dot(memory, prey_signal) > avoid_threshold`.
  - This is genuinely **signal-specific** learning: predators learn
    "this signal pattern = bad" and can avoid mimics that share
    signals with toxic models.
- **MATLAB base reference.** N/A — mimicry first appears in alifeR.
- **Formula fidelity — KEY DIVERGENCE FLAG.** clade's kernel
  collapsed alifeR's signal-vector predator memory into a scalar
  toxicity-memory:

  | | alifeR R prototype | clade Julia kernel |
  |---|---|---|
  | Predator memory type | `numeric(signal_dims)` vector | `value_estimate` scalar |
  | R-W update target | `prey.signal` (vector) | `prey.toxicity` (scalar) |
  | Avoidance trigger | `dot(memory, signal) > θ` (signal-specific) | `value_estimate ≥ θ` (recent-toxin generic) |
  | Batesian via signal sharing | Yes (mimic shares signal → triggers learned avoidance) | **No** (no signal channel; "Batesian" mode is just always-avoid-once-learned) |
  | Identifies Müllerian convergence | Yes | **No — degenerates to "predator avoids when recently poisoned"** |

  This is documented in the kernel itself
  ([mimicry.jl:96](../../../inst/julia/src/modules/mimicry.jl#L96)):
  *"multi-dimensional signal memory would require a dedicated field.
  The scalar value_estimate is used for computational efficiency."*

  **Practical consequence:** clade's mimicry mechanism is
  qualitatively a "general aversion learning" rule, not the
  textbook signal-specific Bates/Müller model. The audit tests
  what the implemented kernel actually predicts within its own
  semantics; flag this divergence for any future kernel work.

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

## 5. Verdict

- [ ] Matches theory
- [x] **Consistent but underpowered (mechanism wired, dynamics inert
      at all tested parameters).**
- [ ] Contradicts theory — kernel bug
- [ ] Contradicts theory — vignette overclaim
- [ ] Contradicts theory — formula mismatch

The clade kernel correctly implements a simplified version of the
mechanism — toxic prey damage attacking predators, predator memory
updates after toxic encounters, avoidance can in principle fire.
The simplification (scalar memory toward `prey.toxicity` instead
of vector memory toward `prey.signal`) removes the signal-specific
learning that produces textbook aposematic dynamics.

The existing vignette claims a "21x fitness improvement" under
"CMA-ES calibrated" parameters with `toxin_dose = 23, cost = 0.28,
lr = 0.30`. This audit ran exactly that regime and observed
mean_toxicity drift of −0.001 over 600 ticks, not measurable
upward evolution. The vignette claim is **not reproduced** here
and should be either re-derived (CMA-ES targeting toxicity
evolution rather than generic fitness, longer runs, larger
populations) or removed.

### Cross-reference table

| Aspect | Theory (Bates/Müller) | MATLAB base | alifeR prototype | clade Julia |
|---|---|---|---|---|
| Predator memory | Signal-specific | N/A | Vector toward signal ✓ | **Scalar toward toxicity** ✗ |
| Avoidance trigger | Recognise signal | N/A | `dot(mem, sig) > θ` | `value_estimate > θ` |
| Batesian (mimic w/ signal) | Predicted | N/A | Implemented | Degraded — no signal channel |
| Müllerian convergence | Predicted | N/A | Implemented | Degraded — no shared-signal mechanism |
| Toxicity evolves up | Yes (with predator pressure) | N/A | Yes (per docs) | **No (max drift +0.02 at extreme params)** |
| Avoidance fires | Yes (after learning) | N/A | Yes (when dot > θ) | Rarely (max 9 events / 600 ticks) |

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
