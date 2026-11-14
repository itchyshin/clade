# After Task: last_action contract for behavioural diversity (#164)

## Goal

Finish the Julia groundwork Bhavya started in #179: every real decision
path records `last_action`, with the rules set on #164 (0 only for "no
action yet"; death stays `alive = false`). No metric and no R API yet.

## Implemented

- Encoding equals the brain's output index: 0 = no action yet, 1 to 4 =
  N, E, S, W, 5 = stay (idle for prey; stay-and-attack for predators).
- `tick_agents!` sets `ag.last_action` after epsilon exploration, so a
  random exploratory action is recorded as taken.
- `tick_predators!` sets `pred.last_action` after `argmax`.
- Founder, offspring, predator founder and predator offspring
  constructors start at 0 (the #179 draft used 5).
- Field docstring in `types.jl` states the contract.

## Files Changed

See the 2026-09-27 #164 entry in `dev/dev-log/check-log.md`.

## Checks Run

Julia contract testset 24/24; seeded parity with `main` in four
configurations. R code is untouched, so the R suite was not rerun.

## Tests Of The Tests

Before the implementation, 10 of the new assertions failed with
`5 == k` (constructors at 5, no updates). A test-only brain,
`_FixedActionBrain`, forces each output so every code is exercised
directly rather than hoped for from random brains.

## Consistency Audit

- Eat, reproduce and attack are not brain decisions in clade (eating
  happens on the cell reached; reproduction runs in
  `create_offspring!`; predators attack when they choose to stay), so
  they have no codes. This departs from the 8-code proposal on #164.
- Module moves after the decision (`apply_responsive_personalities!`,
  dispersal, habitat preference) do not change `last_action`.
- `_agents_to_records()` lists fields explicitly, so `last_action` is
  not exported to R, as #164 asked.
- No NEWS entry: no user-facing change until the metric lands.

## What Did Not Go Smoothly

The #179 placeholder test was placed after a testset that already fails
on `main`, so it never ran. The mock brain needed `n_inputs`, and had to
be swapped back before predator reproduction, which mutates a copy of
the parent brain.

## Team Learning

In `runtests.jl`, a failing top-level `@testset` stops the script. New
testsets must sit above the known-failing unit block until it is fixed.

## Known Limitations

Only the most recent action is stored; a diversity metric will need
either per-tick aggregation or a history. The three pre-existing Julia
failures remain.

## Next Actions

Review and merge. Then design the metric (for example Shannon entropy
of `last_action` over living agents per tick) and its R extraction in a
separate PR, and fix the pre-existing failing unit block.
