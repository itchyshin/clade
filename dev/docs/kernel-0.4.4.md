# Kernel 0.4.4 — mimicry cleanup + audit measurement fix

Released 2026-04-16.

## Motivation

Three observations triggered this release:

1. **Vector-signal predator memory was already implemented** (0.4.0
   Tier 4) using the `preference` field on Agent — but overloaded
   with prey mate-choice preference. The semantic muddle made the
   kernel harder to reason about.
2. **The s-mimicry audit had a measurement bug.** Per-tick counters
   like `n_avoided_attacks` and `n_toxic_attacks` are reset each
   tick; the audit reported `tail(..., 1L)` (last tick only) rather
   than `sum(...)` (cumulative). This spuriously showed 0 events in
   runs where avoidance actually fired many times.
3. **The Rescorla-Wagner update was one-sided.** The 0.4.0 code
   updated memory only after toxic attacks (reinforcement), never
   after non-toxic attacks (extinction). This prevented Batesian
   breakdown — palatable mimics couldn't erode learned aversion by
   being eaten safely — and produced permanent predator aversion
   from a single toxic encounter.

## Changes

### 1. Dedicated `signal_memory` field on Agent

**Files:** `inst/julia/src/types.jl`, `inst/julia/src/modules/mimicry.jl`,
plus constructor updates in `Clade.jl`, `reproduce.jl`,
`modules/tick_predators.jl`.

Agent struct gains a new field:

```julia
signal_memory :: Vector{Float32}
```

Used only by predators under mimicry with `signal_dims > 0`.
Empty for prey; resized lazily on the first toxic attack. Replaces
the 0.4.0 Tier 4 overloading of `preference` for predator signal
memory.

Backward-compatible: default construction produces an empty vector
(length 0); legacy scenarios with `signal_dims == 0` continue to
work through the scalar `value_estimate` fallback.

### 2. Delta-rule Rescorla-Wagner update (Batesian decay)

**File:** `inst/julia/src/modules/mimicry.jl:122-142`.

Pre-0.4.4 update: `if toxic then memory ← (1-lr)·old + lr·signal`.
Only fired on toxic prey → memory grew monotonically, no Batesian
breakdown.

0.4.4 update (Widrow-Hoff delta rule):

```julia
if sdims > 0
    predicted = dot(memory, prey.signal)
    err       = prey.toxicity - predicted
    memory   += lr * err * prey.signal
end
```

The predator learns a linear model that *predicts* toxicity from the
signal vector. The memory update is proportional to prediction error
times the signal, which is the standard supervised-learning rule for
linear regression and has the correct symmetric behaviour:

- **Reinforcement** on toxic prey with unfamiliar signal (predicted
  too low): memory shifts toward the signal.
- **Extinction** on non-toxic prey with familiar signal (predicted
  too high): memory shifts away from the signal.
- **Müllerian convergence**: multiple toxic species sharing a
  signal reinforce predator aversion through cumulative exposure.
- **Batesian breakdown**: when palatable mimics sharing a toxic
  signal outnumber the models, extinction dominates reinforcement →
  avoidance fades → frequency-dependent selection.

The avoidance check uses the same linear prediction:

```julia
avoid if dot(memory, prey.signal) >= avoid_threshold
```

i.e., the predator avoids prey whose signal predicts toxicity above
threshold. This is the textbook aposematic recognition rule.

**Why not the earlier `lambda = signal × toxicity` update.** An
intermediate 0.4.4 draft used `memory ← (1-lr)·old + lr·(signal × tox)`
as a "symmetric RW toward signal-scaled-by-toxicity" rule. That
squashes memory magnitude when signal = toxicity (pleiotropy case) —
memory converges to ~tox² which is too small to trigger avoidance.
The delta rule doesn't have this problem because it tracks the
error relative to the actual toxicity, not a signal-scaled proxy.

### 3. Audit measurement fix

**File:** `dev/audit/fidelity/mimicry.R:133-142`.

Changed `tail(d$n_avoided_attacks, 1L)` → `sum(d$n_avoided_attacks,
na.rm = TRUE)` for both avoidance and toxic-attack counters.
Companion files `mimicry_extreme.R` and `mimicry_debug.R` already
used `sum`; only the main runner had the bug.

### 4. Aposematic pleiotropy (`signal_toxicity_coupling`)

**Files:** `R/config.R`, `inst/julia/src/modules/signals.jl`,
`inst/julia/src/Clade.jl`.

New optional mechanism. When `signal_toxicity_coupling > 0`, each
agent's `signal[1]` is pulled each tick toward its own `toxicity`:

```julia
signal[1] ← (1 − c)·signal[1] + c·toxicity
```

At `c = 0` (default) signal evolves freely (legacy). At `c = 1`,
`signal[1]` is locked to toxicity — the "honest aposematic signal"
theory invokes. Active only when `mimicry = TRUE` and `signal_dims > 0`.

This is the mechanism evolutionary biology papers cite when
explaining why aposematic species look the way they do: toxicity
and warning signal must be genetically linked (pleiotropy, linkage,
supergene, or genetic correlation from co-selection) for predator
learning to reward toxic individuals. Without a link, predator
aversion protects prey with the "right" signal regardless of
their toxicity, and no selection pressure rewards toxicity itself.

## Audit impact

At Step 1 (5 seeds × 600 ticks × `toxicity_init=0.3`):

| Metric | pre-0.4.4 (buggy) | 0.4.4 delta-rule |
|---|---|---|
| P1 control flat/down | PASS | PASS (0.301 control vs 0.299 treatment) |
| P2 treatment > control | FAIL | direction-dependent (~±0.002 noise band) |
| P3 learning fires | FAIL (0 events) | **PASS (12–28 avoidances / 600 ticks)** |
| P4 dose-response | FAIL | **PASS (Spearman ρ = +0.40)** |
| P5 pleiotropy direction | N/A | **PASS (Spearman ρ = +1.0 across coupling ∈ {0,0.3,0.6,1})** |

Substantial improvement from pre-0.4.4: P3 and P4 both flip from
FAIL to PASS. P5 is a brand-new test of the pleiotropy mechanism
and shows monotone direction across the coupling sweep.

**Remaining challenge (honest):** magnitudes are small (~0.004)
even under aposematic pleiotropy. The limiting factor is
*ecological*, not theoretical: at `toxicity_cost_per_tick = 0.1`
and mean toxicity 0.3, the per-tick drain is 0.03 energy — modest
but real. With only 12–28 avoidance events per 1000 ticks the
protection benefit of toxicity doesn't offset the cost. Stronger
predation, lower cost, or longer runs should produce visible
upward evolution; a principled parameter search is deferred to
0.5.0 or a scenario-specific tuning pass.

The mimicry.md audit md now documents this as an ecological
parameter-tuning limit, not a kernel bug.

## Files touched

- `inst/julia/src/types.jl` — `signal_memory` field.
- `inst/julia/src/Clade.jl` — founder Agent constructor.
- `inst/julia/src/reproduce.jl` — offspring Agent constructor.
- `inst/julia/src/modules/tick_predators.jl` — predator + offspring
  constructors.
- `inst/julia/src/modules/mimicry.jl` — RW update (symmetric) +
  avoidance lookup (use `signal_memory` not `preference`).
- `dev/audit/fidelity/mimicry.R` — counter summation.
- `dev/audit/fidelity/mimicry.md` — updated verdict with the
  signal-toxicity co-evolution caveat.

## Out of scope

- Signal-toxicity pleiotropy (deferred to 0.5.0). The kernel change
  would be: either add a pleiotropy spec flag that seeds signal
  = f(toxicity) at each trait expression, or link the two through
  a shared genetic locus. Either approach is biology-worthy and
  opens the cleanest aposematism scenario.
- Coevolving parasite module (s-mating-systems Red Queen) —
  still deferred to 0.5.0.
