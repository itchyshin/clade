# Coverage CI (Codecov, first pass)

clade's R package and Julia kernel both live in this repository
(`R/`, `tests/testthat/`, `inst/julia/`). Coverage is collected from
the suites GitHub Actions already runs, then uploaded once per language
flag. pigauto, GLLVModels, and other repositories are out of scope.

## What is measured

| Flag | Existing suite | Honest meaning |
| --- | --- | --- |
| `r` | `.github/workflows/tests.yaml`: `devtools::test()` with `CLADE_SKIP_JULIA_TESTS=true` | covr instruments the installed package, then `testthat::test_dir("tests/testthat", package = "clade", load_package = "installed")` from the checkout (same files, namespace and skip as `tests.yaml`; any failure or error fails the job). Default `package_coverage()` / `test_check()` runs from the install, where repo-root scanners resolve to the installed dir with no `vignettes/*.Rmd` and fail `NULL` vs `character(0)` (2 failures). Bare `test_dir()` without `package=` fails `test-stream-submit.R` (`local_mocked_bindings` needs a package). Per-test results are in artifact `coverage-r` (`coverage-r-results.csv`). Do not use `devtools::test()` inside covr (`load_all()` drops instrumentation). Julia-dependent R tests skip, so kernel-driven R paths are uncovered here on purpose. |
| `julia` | `.github/workflows/julia-tests.yaml`: `julia --project=inst/julia inst/julia/test/runtests.jl` | line coverage of `inst/julia/src` from that unit suite (`--code-coverage=user` added only for instrumentation). |

`R-CMD-check.yaml` uses `--no-tests` and does not produce coverage.
`fidelity-matrix.yaml` is a manual reproduction harness, not the
existing PR suite.

The `tests` and `julia-tests` jobs remain the assertion gates. This
workflow does not change their skip rules, expectations, or timeouts.

## Who uploads

Only `.github/workflows/coverage.yaml`. Do not add:

- `covr::codecov()`
- Coverage.jl `Codecov.submit` / `Codecov.submit_local`
- a second GitHub workflow that posts the same files
- `token: ${{ secrets.GITHUB_TOKEN }}` or `token: ${{ secrets.GH_TOKEN }}`

Each job uploads one file with `disable_search: true` (`coverage-r.xml`
or `lcov.info`) so the two flags cannot pick up each other's reports.

## OIDC, least privilege

Authentication is GitHub Actions OIDC (`codecov-action` `use_oidc:
true`). There is no Codecov upload token in this repository.

Permissions are job-scoped, not workflow-wide write:

```yaml
permissions:
  contents: read   # checkout
  id-token: write  # request an OIDC JWT for Codecov; not repo write
```

`GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}` on the R job is only for
r-lib package install. It must never be passed to `codecov-action` as
`token`.

Owner action after a **real** uploader failure (codecov-action log
showing OIDC rejected or upload HTTP error): install/enable the
Codecov GitHub App with OIDC for `itchyshin/clade`, or add a dedicated
Codecov upload token secret. A Codecov dashboard "Configure" screen or
an API response of unknown/empty is not that proof. Do not reuse
`GH_TOKEN` / `GITHUB_TOKEN` as the Codecov token.

Fork PRs cannot mint OIDC tokens; same-repo branches can.

## Checkout identity

`pull_request` jobs use `actions/checkout@v4` with no `ref:` override,
so they test the synthetic merge commit (`github.sha`), not the exact
PR head, unless the job log prints `tested_equals_exact_head=true`.
Exact head and base SHAs are printed in "Record coverage checkout
identity". `push` to `main` tests that ref exactly.

## Stages of evidence

Keep these separate. Passing one is not passing the next.

1. **Config** — this document, `coverage.yaml`, `.github/codecov.yml`.
2. **Coverage execution / percent** — job logs and the
   `coverage-r` / `coverage-julia` artifacts (`percent_coverage=…`).
3. **Upload reception** — codecov-action log (OIDC, commit, flag, HTTP).
4. **Processed report** — Codecov UI for this SHA/flags.
5. **Default-main baseline** — authorized owner merge to `main` plus a
   successful `coverage` workflow on `main`. Do not merge from the
   coverage agent. Do not add README badges before stage 5.

Status checks in `.github/codecov.yml` are informational so a missing
baseline cannot look like a coverage-gate failure.

## Local runtimes

This workflow needs R (`covr`) and Julia 1.10. If those are missing on
a given machine, say so and rely on CI for execution-stage numbers.
