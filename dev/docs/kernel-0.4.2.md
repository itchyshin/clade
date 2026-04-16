# Kernel 0.4.2 — sensory and mortality polish + longer-run audits

Released 2026-04-16.

## Motivation

The kernel-as-biology documentation (landed in 0.4.1 via PR #13)
surfaced four simplifications that the original design didn't flag as
issues but that subsequent audit work showed were constraining
scenario fidelity:

1. `_pred_dist` in `sense.jl` had a docstring promising a graded
   `1/(distance+1)` signal but the implementation returned a binary
   presence value (`sense.md §6`).
2. Signal sensory inputs in `sense.jl` were the only sensory channel
   not clamped to [0, 1] — an unbounded trait could dominate the
   brain's input layer (`sense.md §8` reader-guide note).
3. The hard `max_age` cap applied even when `senescence_rate > 0`,
   preventing the stochastic Gompertz curve from governing late-life
   mortality cleanly (`death.md §3.2`).
4. The s-baldwin and s-plasticity audits had directionally-correct
   but magnitude-modest signals at 0.4.1 — the plan (and the audit
   reports) predicted that longer runs and a slightly stronger
   sigma cost would push them to ✅.

All four items are addressed here. No new modules; purely kernel
polish and audit tuning.

## Changes

### 1. Graded predator-distance signal

**File:** `inst/julia/src/sense.jl`.

`_pred_dist(env, x, y)` becomes
`_pred_dist(env, x, y, d, graded)`:

- `graded = true` (0.4.2 default): returns `1/(d+1)` when a predator
  occupies the cell, else 0.
- `graded = false`: legacy binary behaviour — returns 1 when present,
  0 otherwise.

**New spec:** `predator_sense_graded = TRUE` in `R/config.R`. Default
`TRUE` is a behaviour change from 0.4.1; legacy users can opt into the
binary signal by setting it to `FALSE`.

**Biology.** Distance-graded predator inputs let the brain learn
distance-aware anti-predator responses without having to rely on
slot-position alone. Closer predators produce stronger alarms; farther
ones fade toward zero. This matches what ethologists expect of
threat-level perception (Cooper & Frederick 2007 risk-assessment
framework).

### 2. Signal inputs clamped to [0, 1]

**File:** `inst/julia/src/sense.jl`.

Before: `inp[pos] = s` for each component of `ag.signal`.
After: `inp[pos] = clamp(s, 0.0f0, 1.0f0)`.

The signal trait itself still evolves freely (via mutation); only the
sensory projection into the brain is bounded. This matches the
convention already applied to grass/energy/age/care inputs and the
documented "inputs in [0, 1]" note in `sense.md §8`.

### 3. `max_age` deferred to senescence when active

**File:** `inst/julia/src/death.jl`.

In `_death_cause`, the `ag.age >= max_age && return :age` branch now
only fires when `senes_r <= 0`. When Gompertz senescence is active
(`senescence_rate > 0`), the hard cap is skipped and late-life
mortality is governed by the stochastic curve. Agents die from the
Gompertz tail well before runaway ages, so no safety ceiling is
needed.

**Backward compatibility.** Scenarios using `senescence_rate = 0`
(the default) see zero behaviour change — the hard cap still
applies. Only users who explicitly enabled senescence gain the new
semantics.

**Documentation:** `R/config.R` roxygen for `max_age` and
`senescence_rate` updated. `dev/docs/kernel-as-biology/death.md` no
longer flags this as a design limitation.

### 4. Longer-run audit reruns

**Files:** `dev/audit/fidelity/{baldwin,plasticity,brain_size}.R`.

- **s-baldwin** — 1500 ticks (from 600), `plasticity_mutation_sd =
  0.08` (from 0.05), `brain_energy_sigma_scale ∈ {0, 0.05, 0.10}`.
- **s-plasticity** — 1500 ticks (from 500), `plasticity_mutation_sd =
  0.08`, `brain_energy_sigma_scale = 0.05` (from 0.02).
- **s-brain-size** — sweep `brain_energy_base ∈ {0.001, 0.005, 0.01}`
  at the best 0.4.1 cell (cost_scale=3.0, care_duration=15). Tests
  whether the 0.4.1 🟠 magnitude limitation was parameter-tuneable or
  needs the deeper kernel work deferred to 0.4.3.

## Audit impact

Results written into the individual audit md files and summarised in
`STATUS.md`. The magnitude of each impact is recorded in the
kernel-0.4.2 commit message and PR body; see those artefacts for the
final numbers.

## Files touched

- `inst/julia/src/sense.jl` — predator graded + signal clamp.
- `inst/julia/src/death.jl` — senescence supersedes `max_age` cap.
- `R/config.R` — new `predator_sense_graded` default + updated
  `max_age` / `senescence_rate` docstrings.
- `dev/audit/fidelity/{baldwin,plasticity,brain_size}.R` — 0.4.2
  sweep parameters.
- `dev/audit/fidelity/{baldwin,plasticity,brain_size}.md` — updated
  verdicts.
- `dev/audit/fidelity/STATUS.md` — promotions.
- `dev/docs/kernel-as-biology/{sense,death}.md` — strike the flagged
  notes.

## Out of scope for 0.4.2

- Super-linear brain-size cost scaling (0.4.3).
- `max_bite ↔ body_size` coupling (0.4.3).
- Neonatal foraging deficit (0.4.3).
- Coevolving parasite module (0.5.0).
- Vector-signal predator memory (0.5.0).
