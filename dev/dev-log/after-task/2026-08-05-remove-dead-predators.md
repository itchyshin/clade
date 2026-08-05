# After Task: Remove dead predators from the live population

## Goal

Ensure a predator that dies during its tick is removed before reproduction and
does not block detection of total extinction.

## Implemented

`tick_predators!()` now filters dead predators immediately after the predator
loop. The filter precedes both predator-map rebuilding and predator
reproduction. A focused Julia test starts one predator with insufficient energy
and verifies that the result contains no predators.

## Files Changed

- `inst/julia/src/modules/tick_predators.jl`
- `inst/julia/test/runtests.jl`
- `dev/dev-log/check-log.md`
- This report

## Checks Run

- `git diff --check`: pass.
- Static call-site review confirms that `seed_predators!()` runs only at tick
  1, so an extinct predator population is not automatically repopulated.

## Tests Of The Tests

The test combines the zero-prey boundary with a predator energy deficit. Before
the change, the dead predator remains in `result.predators`; after the change
it must be removed. Julia is not available locally, so the test was not run.

## Consistency Audit

The change maintains the one-predator-per-cell map by rebuilding
`predator_map` only from live predators. It does not alter the public R API,
documentation, or biological parameter defaults.

## What Did Not Go Smoothly

The local Codex environment has no Julia executable, preventing focused runtime
verification.

## Team Learning

Predator and prey death paths had diverged: `remove_dead!()` only owned agents,
while predator death was marked but not compacted. The predator-specific tick is
the narrowest place to restore the matching lifecycle.

## Known Limitations

This PR does not add the #165 early-stop guard. It is designed to be merged
before rebasing the focused extinction-stop PR (#177).

## Next Actions

Run this test and #180's sentinel-fallback test in a Julia-equipped checkout;
then rebase #177 and add an assertion for an initialized predator that dies.
