# After Task: Phase A drift-guard sweep

## Goal

Ship the structural fix for the Rose class that recurred across
Phase A items 1, 2, 3, and 6: "API or default change leaves stale
assertions/fixtures in tests." Three commits on a fresh branch
`claude/drift-guard-sweep` off `main` (post-Tier-A0-merge at
`47c2fe4`).

## Implemented

Three commits, in order:

1. **`8da0fbe test: drift-guard for SPEC_GROUPS ⇔ default_specs()
   bijection`** — `tests/testthat/test-spec-groups-coverage.R`
   (new). Two assertions: every `.SPEC_GROUPS` name exists in
   `default_specs()` (no ghosts) and every `default_specs()` field
   appears in some `.SPEC_GROUPS` entry (no orphans). Catches the
   item-1 ghost-pruning regression class.
2. **`7b625f8 test: drop stale assertions on fields deleted by the
   spec-wiring audit`** — cleared survivors from item 2's audit:
   `repro_senescence` and `life_history_evolution` in
   `test-life-history.R` (tests 6, 7, 10, 16, 17, 24); updated
   test 19 (`senescence_shape` 2.0 → 1.0) and test 20 (round-trip
   without deleted fields); `parental_investment_init_mean` in
   `test-parental-investment.R` (tests 5, 6, 13, 17); updated tests
   16 and 18 (round-trip and numeric-type without the deleted
   field). Refreshed file-header comments and stripped two
   "NOT yet implemented" notes that were themselves stale.
3. **`d612554 test: drift-guard for stale field-presence
   assertions in test files`** —
   `tests/testthat/test-test-field-assertions.R` (new). Scans
   `tests/testthat/test-*.R` for `expect_true("<x>" %in%
   names(default_specs()))` (direct) and per-`test_that` blocks
   where a variable was `<- default_specs()` and then asserted
   via `expect_true("<x>" %in% names(<varname>))` (indirect).
   `expect_false(...)` absence assertions deliberately ignored.
   Three tests-of-the-test verify the regex on synthetic fixtures.
   Self-excludes by basename.

## Files Changed

| Commit | File | Lines |
|---|---|---|
| `8da0fbe` | `tests/testthat/test-spec-groups-coverage.R` | +51 |
| `7b625f8` | `tests/testthat/test-life-history.R` | -32 (8 tests removed, 2 updated) |
| `7b625f8` | `tests/testthat/test-parental-investment.R` | -14 (4 tests removed, 2 updated) |
| `d612554` | `tests/testthat/test-test-field-assertions.R` | +171 |

No production code (`R/`, `inst/julia/src/`, `_pkgdown.yml`) touched.

## Checks Run

- `Rscript -e 'devtools::load_all("."); test_file(...)'` per file:
  - `test-spec-groups-coverage.R`: 2 pass.
  - `test-test-field-assertions.R`: 8 pass.
  - `test-life-history.R`: 22 pass (Julia errors observed in the
    script context are pre-existing manifest-resolved warnings —
    `test-parental-care.R` shows identical errors on un-edited state).
  - `test-parental-investment.R`: 17 pass (same Julia note).
  - `test-config.R`: 56 pass.
  - `test-specs.R`: 52 pass.
  - `test-spec-wiring.R`: 2 pass.
  - `test-version-strings.R`: 4 pass.
  - `test-readme-flag-names.R`: 1 pass.
  - `test-pkgdown-consistency.R`: 2 pass.
- `git diff --stat` per commit: matches expectation.
- `parse(file = "tests/testthat/test-test-field-assertions.R")`:
  succeeds.

## Consistency Audit

- `rg "repro_senescence|life_history_evolution|parental_investment_init_mean"
   tests/testthat/test-life-history.R tests/testthat/test-parental-investment.R`:
  only references remaining are in comments documenting the removal.
- `rg "max_carried" tests/testthat/test-parental-care.R`:
  the surviving reference is the correct `expect_false(...)`
  absence assertion at line 118 — kept by design.
- `rg "Pre-0\\." R/`: item 6's flagged cousin-class candidates.
  ~40 hits not investigated in this PR; flagged for a future
  cousin-hunt session.

## Tests Of The Tests

Three included directly in `test-test-field-assertions.R` (lines
130-170):

- Direct pattern catches a synthetic stale `expect_true` on
  `"ghost_field"`.
- Direct pattern ignores `expect_false(...)` absence assertions.
- Indirect pattern fires only when the variable was `<-
  default_specs()` in the same `test_that` block; ignores
  `names(env$progress)` and similar dotted accesses.

## What Did Not Go Smoothly

- First regex pass was too greedy — caught `expect_true("foo"
  %in% names(env$progress))` etc. as false positives because the
  `names(...)` argument wasn't constrained. Tightened to require
  either `names(default_specs())` literally or
  `names(<simple_variable>)` with `<simple_variable> <-
  default_specs()` in the same `test_that` block.
- Self-scan caught the synthetic-fixture strings as real stale
  assertions. Added a one-line `basename(test_files) !=
  "test-test-field-assertions.R"` filter.
- `gregexec` returns NULL (not a 0-column matrix) when there are
  no matches; first version of the tests-of-the-test used
  `expect_equal(ncol(m), 0L)` and failed on NULL. Switched to
  `expect_equal(length(m), 0L)` which handles both.

## Team Learning

- The two drift-guards together close the *forward* leg of the
  Rose class. The *backward* leg ("behaviour shipped, no
  regression test landed") flagged in item 6 is not amenable to
  the same scan-the-source approach and would need a cousin-hunt
  on `rg "Pre-0\\." R/` followed by per-instance test additions.
  That's deferred to a future session.
- The kit's check-log discipline broke down during the Phase A
  walks: items 1–6 did not get individual check-log entries (the
  audit log `dev/audit/r-function-walk.md` was the substitute).
  This PR restores the discipline with one entry for the
  drift-guard sweep. Going forward, brief check-log entries per
  PR (not per item walk) seems like the right cadence.

## Design-doc Updates

None this task. The Rose-pattern catalogue lives implicitly in
`dev/audit/r-function-walk.md`'s per-item entries.

## Documentation Or Site Updates

None this task. The new drift-guards are internal tests; pkgdown
does not list `tests/testthat/*` content.

## Known Limitations

- The stale-assertion drift-guard scan only catches
  `expect_true("<x>" %in% names(...))` patterns. It does NOT
  catch `default_specs()$<missing_field>` direct accesses, which
  silently return NULL and may cause downstream test failures
  with confusing error messages. That second pattern is harder
  to scan robustly (many legitimate uses of `s$<field> <- ...`
  setter syntax) and is deferred.
- The "Pre-0.X.Y guard added but no regression test landed" Rose
  class is not closed by this PR. ~40 candidates remain on the
  `rg "Pre-0\\." R/` list.

## Next Actions

1. Push `claude/drift-guard-sweep` to origin and open PR.
2. After merge: rebase `claude/track-B-walk` onto the new main.
   That branch carries Phase A items 5 (`e701d21`) and 6
   (`23946d3`) which will eventually land as part of a Tier-A1
   PR after items 7 and 8 complete.
3. Continue Phase A item 7 (`print_specs()`) on the rebased
   branch.
