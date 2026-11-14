# After Task: Warn on unknown spec names

## Goal

Make clade say so when it is given a spec name it never reads. In #185 a
500-run DRAC sweep sampled `repro_threshold`; the kernel ignored it, and
nothing told anyone.

## Implemented

- Julia `normalize_specs()` warns for each key that is not in
  `get_default_specs()` and does not start with `_`. Each key warns once
  per session (`maxlog = 1`), so a sweep does not repeat it per run. The
  key is still passed through; this is a warning, not an error.
- A small hint table maps `repro_threshold` to `min_repro_energy`; the
  name is easy to reach for because the agent trait and the output
  column are both called `repro_threshold`.
- R `.validate_specs()` gives one R `warning()` naming every unknown
  spec, with the same hint. This catches the problem before the Julia
  call and in a form R users can handle.
- Julia defaults gain `log_movement` and `log_movement_freq`.

## Files Changed

See the 2026-09-27 unknown-spec entry in `dev/dev-log/check-log.md`.

## Checks Run

Julia new testset 8/8, other contract testsets green; R suite FAIL 0,
WARN 0. Details in the check-log.

## Tests Of The Tests

The Julia testset failed before the change (0 warnings where 1 and 2
were expected); the R tests failed 3 of 4. The added no-births check in
the movement parity test was confirmed to fire: with
`min_repro_energy = 10` the same setup produces 7 births.

## Consistency Audit

- The movement parity test used `repro_threshold = 9999` to stop
  reproduction. It passed only because 50 starting energy cannot reach
  the default 120 in two ticks. It now uses `min_repro_energy` and
  asserts zero births.
- `test-scenario-signals.R` set `speciation_threshold`, also not a
  clade spec, so the "speciation metric" test ran with speciation off.
  It now sets `speciation = TRUE`.
- Scans of R code, R tests, vignettes, Julia tests and presets found no
  other dead names.

## What Did Not Go Smoothly

On Julia 1.10.0 a failing `@test_logs` crashes while recording the
failure (`Test.scrub_backtrace` MethodError), which hides the cause.
The tests collect warnings through `Test.TestLogger` instead.

## Team Learning

When a key is merged into a defaults dictionary, an unknown key is a
silent no-op. Validate names at the boundary, and look for tests that
depend on a no-op without knowing it.

## Known Limitations

Whether Julia's `@warn` reaches the R console through JuliaConnectoR
was not checked here (JuliaConnectoR not installed); the R-side warning
covers R users regardless. Keys set by hand in Julia after
`normalize_specs` are not checked.

## Next Actions

Review and merge. Bhavya's #185 rerun should now surface any other
naming slip immediately.
