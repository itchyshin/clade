# Critical-review synthesis

Four parallel critical reviews of the clade codebase, focused on biological
correctness and numerical integrity. Source reviews:

- [`brains.md`](brains.md) — BNN / ANN / CTRNN / GRN / RL / epigenetics
- [`social.md`](social.md) — kin / cooperation / parental care / social
  learning / genome / reproduce
- [`ecology.md`](ecology.md) — disease / dispersal / spatial sorting /
  landscape / seasonal / predators / sense / tick loop
- [`traits.md`](traits.md) — body size / brain size / plasticity / signals
  / mimicry / speciation / niche + defaults audit

## Headline

**11 critical issues.** 5 are narrow bug fixes. 3 are calibration (parameter
defaults). 3 are design gaps (missing biology). None of these invalidates the
audit we just completed — those were vignette-level; these are kernel-level.

## Critical issues (fix queue)

Ranked by *impact × tractability*:

### Code fixes (surgical, non-controversial)

1. **BNN REINFORCE score function is wrong** ([brains.md §1](brains.md),
   [bnn.jl:192-195](../../inst/julia/src/brains/bnn.jl#L192)).
   Current: `mu[i] += lr * advantage * sigma[i]`. Correct (Williams 1992 +
   Gaussian policy): `mu[i] += lr * advantage * (w_sampled[i] - mu[i]) / sigma[i]^2`.
   The current form throws away the sampled weight and divides by the wrong
   power of sigma, biasing the update for high-uncertainty weights.
   **This is likely a real contributor to the Baldwin-effect non-emergence.**
   Fix: cache sampled `w` in forward pass, use it in update.

2. **Parliament-of-genes condition is inverted**
   ([social.md §2](social.md), [kin.jl:224-241](../../inst/julia/src/modules/kin.jl#L224)).
   Current counts `n_cooperators` across *all* neighbours, not just kin,
   so a defector is penalised only when surrounded by *non-relative*
   cooperators — the opposite of Haig (2000) intragenomic suppression.
   Fix: split counters `n_coop_relatives` / `n_coop_nonrelatives` and
   gate the penalty on `n_coop_relatives > n_relatives - n_coop_relatives`.

3. **Seasonal amplitude can drive grass rate negative**
   ([ecology.md §3](ecology.md), [seasonal.jl:10](../../inst/julia/src/modules/seasonal.jl#L10)).
   `grass_rate * (1 + amplitude * sin(...))` goes negative when
   `amplitude >= 1`. No guard. Would silently pass zero-grass cells into
   downstream math and eventually NaN. Fix: `amplitude = clamp(amplitude, 0, 0.99)`.

4. **Habitat-preference corrupts `env.agent_map`**
   ([ecology.md §2](ecology.md), [habitat_preference.jl:84-99](../../inst/julia/src/modules/habitat_preference.jl#L84)).
   Sets a placeholder agent_map cell to 1 before a global rebuild, breaking
   the invariant that `agent_map[x,y]` is a valid agent index. Any code
   between move and rebuild that reads the map sees a phantom agent. Fix:
   remove the placeholder write; rebuild once after all moves.

5. **Predator sensory vector hard-coded to 15 elements**
   ([ecology.md §4](ecology.md), [tick_predators.jl:208-273](../../inst/julia/src/modules/tick_predators.jl#L208)).
   Prey use dynamic input size (3 + 8*radius + optional module inputs), so
   when `input_radius=2` or optional modules are on, predators' 15-element
   input vector doesn't match their brain's expected input. Silent size
   mismatch → wrong forward-pass math. Fix: reuse `sense_agent()` or
   introduce a dedicated predator sense function.

6. **Mutation-rate evolution ignores the per-agent trait**
   ([social.md §1](social.md), [genome.jl:443-450](../../inst/julia/src/genome.jl#L443),
   [reproduce.jl:96-103](../../inst/julia/src/reproduce.jl#L96)).
   When `mutation_rate_evolution = TRUE`, each agent expresses a per-agent
   `mutation_sd` trait, but meiosis reads the global `specs["mutation_sd"]`
   — the evolved trait never propagates. Also: stress hypermutation mutates
   `specs["mutation_sd"]` globally (thread-safety hazard). Fix: pass
   `parent.mutation_sd` through meiosis; remove the transient `specs`
   assignment.

### Calibration (parameter tuning — user judgement)

7. **`toxicity_cost_per_tick = 0.5` is lower than `idle_cost = 0.5`**
   ([traits.md §10](traits.md#10-critical-biology-code-mismatches)). Honest
   aposematism (Zahavi 1975) requires toxicity to be costly relative to
   baseline. At current defaults, being toxic is ~free. Recommend raising
   to 2.0–5.0, or scale as a fraction of `idle_cost`.

8. **`isolation_threshold = 0.5` for speciation has no calibration**
   ([traits.md §6](traits.md)). Genome distance is dimensionally ambiguous
   (weight units? SDs?) and 0.5 wasn't fit against observed speciation
   rates. Recommend a calibration run: sweep 0.1–0.8 against population
   scenarios and pick the value that produces ~1 speciation event per
   1000 ticks at default mutation rates.

9. **Body-size metabolic scaling is linear, docstring claims Kleiber 0.75**
   ([traits.md §1](traits.md)). At `body_size = 0.3`, linear gives a
   *refund* (negative cost); Kleiber gives ~0.41× cost. For dwarf
   phenotypes the direction is wrong. Either switch to
   `cost *= body_size ^ 0.75` (accurate; one line) or update the docstring
   to say "linear simplification".

### Design gaps (require spec discussion before code)

10. **Niche construction lacks inheritance** ([traits.md §7](traits.md)).
    Current `niche.jl` is a local public good, not Odling-Smee et al.
    (2003) niche construction. To fix, shelters would need to persist
    beyond the builder's lifetime and confer benefits to subsequent
    occupants (already partially there via `shelter_decay_prob`) *and* be
    discoverable as heritable environments — that last part is missing.

11. **Mimicry module is Müllerian-only; Batesian is blocked by design**
    ([traits.md §5](traits.md#5-mimicry-mimicryjl)). Palatable mimics
    (`toxicity = 0`) are never avoided even when they share a toxic
    signal. Needs a signal-based (not toxicity-based) avoidance decision
    for Batesian mimicry to emerge.

## Subtle issues (not blocking, but worth fixing)

Roughly 20 of these across the four reviews. Highest-value samples:

- **BNN forward pass doesn't cache its sample** (brains §1 follow-on) — the
  update currently can't see which `w_sampled` produced the action. Needed
  to fix critical #1.
- **Spatial sorting on a torus is a category error** (ecology §1) — Shine
  et al. 2011 requires a bounded grid with a moving front. On a torus,
  there is no front; centroid wraps. Either warn when
  `toroidal=TRUE && spatial_sorting=TRUE`, or auto-disable one.
- **SIR disease is density-dependent without documentation** (ecology,
  disease.jl) — β * S * I rather than β * S * I / N. Fine, but users may
  assume frequency-dependent. Document.
- **`idle_cost = 0.5` is low enough that agents survive ~400 ticks unfed**
  (traits §8). `max_age = 200` then becomes the binding constraint, not
  starvation — inverts the ecological pressure the defaults intend.
- **Fisher runaway needs standing genetic correlation at init**
  (traits §4, signals.jl). Currently signal and preference are independent
  at init; correlation has to emerge from drift, which is slow.

## Proposed fix order

Phase 6a — code fixes (items 1–6 above). All six are surgical. Estimated
~2–3 hours, no design decisions needed. Each gets:
- a Julia (or R) patch
- a rerun of the affected vignette via our audit harness
- a line in NEWS.md

Phase 6b — calibration (items 7–9). Present defaults-diff; user approves
before bumping.

Phase 6c — design (items 10–11). Scope for 0.3.0; write design docs, not
code.

**Recommendation:** proceed with Phase 6a now. The BNN REINFORCE fix (item
1) may well be the root cause of several vignettes' weak Baldwin signal,
which would make it the single highest-impact change of the whole audit.

## Links back

- [Baseline scenario audit (Phases 1–4)](../_artifacts/REVIEW.md)
- [Consolidation refactor report (Phase 5d)](../consolidation_report.md)
- [Scenario oracle](../scenario_oracle.R)
