# After Task: Movement-logging defaults in default_specs()

## Goal

Fix the bug Bhavya reported on #167: with only `log_movement = TRUE`
set, the run stopped with a Julia `KeyError` for `log_movement_freq`.

## Implemented

`default_specs()` now carries `log_movement = FALSE` and
`log_movement_freq = 1L`, documented in the Logging block and registered
in `.SPEC_GROUPS`. `log_movement!()` reads the frequency with
`get(env.specs, "log_movement_freq", 1)`, matching the validation in
`run_clade()`, so a hand-built Julia specs dict cannot hit the error
either.

## Files Changed

- `R/config.R`, `R/utils.R`, `man/default_specs.Rd`
- `inst/julia/src/logging.jl`
- `inst/julia/test/runtests.jl`, `tests/testthat/test-movement.R`
- `NEWS.md`, `dev/dev-log/check-log.md`, this report

## Checks Run

See the 2026-09-27 check-log entry. In short: Julia movement testset
17/17; R suite FAIL 0; three pre-existing Julia failures unrelated to
this change and present on `main`.

## Tests Of The Tests

The new Julia case was run as a standalone script before the fix and
raised the reported `KeyError`; after the fix it records ticks 1 to 3.
The new R test on `default_specs()` failed before the R change (both
fields `NULL`) and passes after it. The R end-to-end test is gated on
Julia and was skipped here.

## Consistency Audit

All 95 keys that Julia reads with `specs["..."]` were compared with
`names(default_specs())`. The only keys missing from R are internal
ones Julia sets itself (`_fixed_patch_cells`, `_movement_log`,
`_parasite_optimum`), so no other spec has the same failure mode.

## What Did Not Go Smoothly

JuliaConnectoR is not installed in the local R library, so the R-to-Julia
round trip was not exercised from R.

## Team Learning

When a Julia spec is validated with a `get(..., default)` fallback,
every later read of the same key needs the same fallback, or the R
default must exist. A default in one place and a bare index in another
is the pattern to look for.

## Known Limitations

The three Julia failures in `test_ann_regularization.jl` and
`test_lamarckian.jl` remain; they predate this change.

## Next Actions

Run the Julia-gated R tests where JuliaConnectoR is available, merge,
then triage the pre-existing Julia failures as a separate issue.
