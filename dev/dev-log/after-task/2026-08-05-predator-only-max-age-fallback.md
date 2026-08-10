# After Task: Predator-only max-age fallback

## Goal

Fix the predators-only `Int32(::Nothing)` crash reported while testing issue
#165, without changing the extinction-stop implementation.

## Implemented

`tick_predators!()` now treats `predator_max_age = nothing` as “use
`max_age`”, matching the documented R `NA` contract. A focused Julia test runs
one predator with no prey and the default `predator_max_age`.

## Files Changed

- `inst/julia/src/modules/tick_predators.jl`
- `inst/julia/test/runtests.jl`
- `dev/dev-log/check-log.md`
- This report

## Checks Run

- `git diff --check`: pass.
- Source review: the previous conversion was `Int32(get(...))`; the Julia
  default supplies `nothing`, which directly explains the reported exception.

## Tests Of The Tests

The new test reproduces the failing boundary: zero prey, one seeded predator,
and no explicit predator maximum age. It would enter the former
`Int32(nothing)` path. It could not be executed locally because Julia is not
available in this environment.

## Consistency Audit

The R default and its test define `NA` as “same as prey max_age”; the Julia
default is `nothing` for the same meaning. The implementation now agrees with
that contract. No user-facing documentation needs revision.

## What Did Not Go Smoothly

`julia` is absent from `PATH` and no local Julia executable was found, so this
task lacks local runtime confirmation.

## Team Learning

When a configuration uses `nothing` as a sentinel, a nested `get()` fallback
does not handle it: `get()` returns the present `nothing` value. Coalesce the
sentinel before numeric conversion.

## Known Limitations

`remove_dead!()` filters agents but not predators. That is a separate issue:
the #177 guard cannot terminate after an initialized predator later dies.
This task does not change it.

## Next Actions

Run the focused Julia suite in CI or a Julia-equipped checkout, open this
two-code-file PR, then amend #177 with a case where initialized predators die.
