# After Task: Batch C5 — Julia coverage lane (flag `julia`)

## Goal

Make `inst/julia/src` count in Codecov: run the existing Julia unit
suite with `--code-coverage=user`, process hits to `lcov.info`, upload
with flag `julia` so Codecov merges Julia lines with the R (`r`) report.

## Implemented

- `julia-coverage` job in `.github/workflows/coverage.yaml` (already
  wired on `main` via #195): mirrors `julia-tests.yaml` test command
  with coverage instrumentation, `julia-actions/julia-processcoverage`
  on `inst/julia/src`, OIDC upload via `codecov-action` with
  `flags: julia` and `disable_search: true`.
- Flag merge: `.github/codecov.yml` maps `julia` → `inst/julia/src/`
  with carryforward alongside flag `r` → `R/`.
- C5 hardening: explicit `set -euo pipefail` on the Julia test step so
  any failed testset stops the job before lcov or upload.

## Files Changed

- `.github/workflows/coverage.yaml`
- `.github/coverage.md`
- `dev/dev-log/check-log.md`
- This file

## Checks Run

- `python3 -c 'import yaml; yaml.safe_load(open(".github/workflows/coverage.yaml"))'` — OK.
- `gh pr list` — noted #196 (C1 tests, draft), did not touch.
- Not run: Julia locally (no `julia` on PATH).

## Tests Of The Tests

- N/A (CI-only batch; `inst/julia/test/` untouched per handoff).

## Consistency Audit

- Julia assertion gate remains `julia-tests.yaml`; coverage does not
  change skips or expectations.
- Sole Codecov uploader rule preserved (no second workflow, no token).

## What Did Not Go Smoothly

- Julia coverage infrastructure landed with #195 before this C5 branch;
  this PR is documentation plus fail-fast shell, not a greenfield job.

## Team Learning

- Codecov project percent on `main` requires both flags; Julia-only
  execution was ~39.25% of `inst/julia/src` lines on the existing
  three-file suite.

## Known Limitations

- R covr job still sets `CLADE_SKIP_JULIA_TESTS=true`; kernel-driven
  R paths stay uncovered until a separate Julia-enabled R coverage
  batch (full C5 plan item beyond this CI PR).
- Processed Codecov UI remains informational until default-main baseline
  stage 5 per `.github/coverage.md`.

## Next Actions

- Let CI run `coverage` workflow on this branch; confirm `julia-coverage`
  green and upload queued.
- C1 (#196) and remaining Julia module tests are out of scope here.
