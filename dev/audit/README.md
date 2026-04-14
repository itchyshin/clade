# Scenario audit harness

Machine-assisted audit of `vignettes/s-*.Rmd` scenarios: does each figure
actually match the code that is shown, and does the claimed evolution
signal appear in the rerun?

## Files

- `parse_rmd.R` — reads an Rmd, extracts displayed code chunks, figure
  chunks (name + `fig.cap`), and the "What we found" prose section.
- `scenario_oracle.R` — table mapping each `s-*.Rmd` to its expected
  module flags, primary metric, and expected direction (where known
  from existing `tests/testthat/test-*.R` or from prose).
- `run_one_scenario.R` — evaluates a parsed scenario's displayed code
  in a warm R/Julia session; returns (recorded `specs`,
  `get_run_data()` trajectories, timing).
- `diagnose.R` — decision tree: `OK` / `STALE` / `GENERATOR_DRIFT` /
  `TOO_SMALL` / `BIOLOGY_BUG` / `PROSE_OVERSTATED`.
- `worker.R` — one warm R process handling a partition of scenarios;
  writes rows to `_artifacts/<worker-id>.csv` and per-scenario JSON.
- `run_audit.R` — partition scenarios by cost, spawn workers via
  `parallel::mcparallel()`, merge outputs into `_artifacts/scenario_audit.csv`.
- `dry_run_parse.R` — parse-only smoke test (no Julia).

## Invariants

- **Rmd chunk is the source of truth.** Generator scripts must be
  reconciled to match the displayed chunks, not the other way around.
- **Never regenerate a PNG before diagnosis.** A stale PNG can mask a
  biology bug.
- **Direction over magnitude.** Tests assert the direction of the
  expected trait change, not an exact numeric value, so they are
  robust to seed noise.

## Artifacts (all gitignored)

- `_artifacts/scenario_audit.csv` — one row per scenario.
- `_artifacts/<vignette>.json` — full rerun trajectories and parse
  output for that scenario.
- `_artifacts/<worker-id>.csv` — per-worker partial CSV, merged by
  `run_audit.R`.
