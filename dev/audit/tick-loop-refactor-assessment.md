# Tick-loop dispatch-table refactor — assessment (skipped)

The original 0.7.0 plan (`dev/plans/purring-honking-dove.md`, Phase 7
of the opportunistic list) proposed a tick-loop dispatch table:

> "Replace the optional-modules block with an OPTIONAL_MODULES schedule
> table. Lifts function-call overhead for disabled modules; documents
> tick order; halves the number of edit sites for adding a new module."

After examining the current `inst/julia/src/Clade.jl` post-0.7.0 merge,
this refactor is **not recommended**. Reasoning below.

## Cost-benefit

| Claimed benefit | Actual situation post-0.7.0 |
|---|---|
| "Lifts function-call overhead for disabled modules" | Modules already short-circuit at line 1 (`Bool(get(specs, "flag", false)) \|\| return`). The overhead is one Dict lookup + one branch — sub-microsecond. |
| "Documents tick order" | The current ordering *is* documented, inline, where each call sits. A dispatch table would move those comments away from the call site. |
| "Halves the number of edit sites for adding a new module" | Adding a module currently requires: (1) `include(...)` line in Clade.jl, (2) `apply_foo!(env)` call in tick loop, (3) `default_specs()` flag in config.R, (4) maybe new spec fields. A dispatch table would consolidate (1)+(2) into one entry — saving ~2 lines per new module. |

| Cost | Severity |
|---|---|
| Lose inline "why this is here" comments at each call site | High — the 0.7.0 modules have specific ordering rationale that would be hidden |
| Risk regression in 1987-test suite | Medium — refactor across 40+ call sites |
| Julia type stability: `Vector{Function}` is not type-stable, hurts the JIT | Medium — current direct calls are fully type-stable |
| Conditional modules (~10) have non-uniform gating logic that doesn't fit a uniform schema | High — would force a Procrustean schema with per-entry callbacks |

The cost-benefit is poor.

## What WOULD be worth doing

If the tick loop becomes hard to maintain in the future, the better
moves are:

1. **Group modules under labelled section comments** — already mostly
   done; could be tightened. Zero behavioural change.
2. **Extract complex inline conditionals into named helpers** —
   e.g. `_should_run_social_learning(t, specs)` instead of the inline
   `t % sl_freq == 0` test. Localised cleanup, low risk.
3. **Move toward true module registration** (a la Julia's `__init__`
   pattern) — but this is a larger architectural change that
   genuinely solves the edit-sites problem, not a dispatch-table
   half-measure.

None of these is urgent.

## Decision

Skip the refactor. The current tick loop is verbose-but-transparent.
The user's "do not be afraid of big changes" authorisation doesn't
mean "make changes that are net negative." This is one of those
cases.

Re-evaluate if/when the package adds a 6th or 7th independent
biological module to the tick loop, at which point the edit-sites
cost might cross the threshold.
