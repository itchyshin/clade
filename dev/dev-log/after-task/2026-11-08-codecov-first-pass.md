# After Task: Codecov first pass (R + Julia existing suites)

## Goal

Ship a bounded first-pass Codecov setup for clade only: honest
coverage of the suites CI already runs, one upload per language flag,
OIDC with job-scoped `id-token: write`, and no change to scientific
source, tests, fixtures, or existing assertion jobs.

## Implemented

A new `coverage` workflow is the only Codecov uploader. Flag `r` runs
`covr::package_coverage()` with `CLADE_SKIP_JULIA_TESTS=true` (the
same skip as `tests.yaml`). Flag `julia` runs the existing
`inst/julia/test/runtests.jl` command with `--code-coverage=user`
added for instrumentation. Each job writes a local percent summary
and an artifact, then uploads one file with `disable_search: true`.
`.github/codecov.yml` carry-forwards those flags and keeps status
informational until a default-`main` report exists. OIDC rules and
the five evidence stages are in `.github/coverage.md`.

Both languages live in this repository. pigauto, GLLVModels, and
other repos were not touched. Open work on `#122` and `#185` was not
touched. `inst/julia/src/` was not edited.

## Files Changed

- `.github/workflows/coverage.yaml` (new)
- `.github/codecov.yml` (new)
- `.github/coverage.md` (new)
- `.gitignore`
- `AGENTS.md`
- `dev/dev-log/decisions.md`
- `dev/dev-log/check-log.md`
- this report

## Checks Run

- PyYAML parse of the new workflow, `.github/codecov.yml`, and the
  five existing workflows: success. Coverage jobs have `use_oidc:
  true`, no `token` input, flags `r` and `julia`, and default
  `actions/checkout@v4` (no `ref:`).
- `git diff --check`: clean.
- Existing workflow files: empty diff.
- `Rscript`, `julia`, and `actionlint`: not on PATH.

## Tests Of The Tests

No scientific or testthat/Julia unit tests were added or edited. The
coverage jobs invoke the existing suites. `tests.yaml` remains the
R assertion gate; `julia-tests.yaml` remains the Julia assertion
gate, including its 20-minute timeout. This environment could not
execute those suites.

## Consistency Audit

Searches:

- `rg -n 'CODECOV_TOKEN|token:.*GITHUB_TOKEN' .github AGENTS.md` —
  comments only.
- `rg -n 'covr::codecov|Codecov.submit' .github AGENTS.md` —
  prohibition comments only.
- `rg -n 'codecov.io/.*/badge' README.md AGENTS.md .github` — none.
- `rg -n '^ignore:|file_exclusions|line_exclusions' .github` — none.

`AGENTS.md` now points at the single uploader so a later agent does
not add a second one.

## What Did Not Go Smoothly

This cloud environment has Python but not R or Julia, so execution
percent, upload reception, and processed reports are CI-only. Codecov
App/OIDC enablement on the GitHub org cannot be verified from
workflow files; the upload log is the proof.

## Team Learning

Keep coverage stages separate: config, local/CI percent, upload
reception, processed report, default-main baseline. A dashboard
Configure page is not an upload failure. `pull_request` coverage is
the synthetic merge unless the identity step prints
`tested_equals_exact_head=true`.

## Known Limitations

- R percent is the no-Julia testthat tier, not kernel-driven R paths.
- `julia-tests.yaml` still does not run on R-only PRs; this new
  workflow does run Julia coverage on those PRs so the `julia` flag
  is present. That is extra CI time, not a change to `julia-tests`.
- Informational Codecov status is not a coverage gate.
- No README badge.
- No default-`main` baseline until an authorized owner merge and a
  successful `coverage` run on `main`.
- Fork PRs cannot use OIDC.

## Next Actions

1. Open the PR from `cursor/codecov-first-pass-8e02` and let CI run.
2. Subscribe for evidence-only CI wakes. Do not poll. Do not merge.
3. Coordinator before any further edit.
4. Read coverage job logs for checkout identity, `percent_coverage=`,
   and codecov-action upload reception.
5. If upload fails with an OIDC/HTTP error, the owner may enable the
   Codecov GitHub App OIDC grant or add a dedicated Codecov token.
   Do not use `GH_TOKEN` as that token.
6. Do not add a badge until stage 5 (default-main processed report).
