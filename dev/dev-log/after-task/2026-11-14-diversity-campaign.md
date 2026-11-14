# After Task: Replay-safe diversity campaign

## 1. Goal

Finish the review and repair of Bhavya's #185 campaign, linked to #182,
preserving submitted data and recording a reproducible corrected rerun.

## 2. Implemented

The sampler uses a dedicated Xoshiro(42), full-precision input fields and
actual final ticks. Snapshots after termination are NA. Invalid environment
counts or seed lists fail before opening the output. Both scripts can be
included without launching work. The kernel's distinct-pair correction
from merged #201 is included in the rerun.

## 3a. Decisions and Rejected Alternatives

Preserve both submitted CSV files byte-for-byte. Add verified_results.csv
separately, because the old estimator's changed random draws also change
simulation trajectories. Repairing labels alone cannot correct old values.
The zero genetic distance for fewer than two agents remains a documented
convention. Treat extinction and conditional diversity separately.

## 4. Files Touched

Both Julia campaign entry scripts, a replay checker, driver tests and the
test runner; data README, new results, timing and JSON provenance; check log
and this report. No public R function or default changed in this phase.

## 5. Checks Run

- Julia 1.10.0 integrated test runner: 166 assertions pass, exit 0.
- Timed Totoro pilot: one environment by five seeds, 10.32 seconds, valid output.
- Full Totoro run: 100 environments by five seeds, 74.29 seconds,
  405500 KiB maximum RSS, exit 0. Four Julia threads, one BLAS thread.
- CSV: 500 unique pairs, all environments 1:100 and seeds 101:105;
  309 surviving runs, 191 extinct, four with one remaining agent.
- All 672 fields after termination are NA. Extinction flags match final
  population counts. Original submitted file bytes are unchanged.
- Replay from saved inputs on the same host/version: one surviving and one
  extinct run, eight endpoint assertions pass, including six-decimal output.
- CSV SHA256 agrees between Totoro and the repository copy. Exact hashes,
  command, code revision and machine details are in verified-run.json.

## 6. Tests of the Tests

The initial tests reproduced invalid arguments overwriting an existing file.
Known fake output verifies exact Float64 input recording and NA after an
extinction tick; a real short-lived simulation tests the same behavior.
Changing seed count or consuming global random draws does not change the
sampled environmental design. Standalone tests pass when included in the
full runner after avoiding a second Clade module import.

## 7a. Issue Ledger

#185 has corrected driver and results ready for integration. #182 receives
the reproducibility and exploratory-analysis review. #164 was resolved in
#201 and #199 in #200. Sensing and mutation decisions are separate PRs.

## 8. Consistency Audit

Searched `repro_threshold|sample_environments|full_drac_results|verified_results`
in scripts, tests and data docs. The legacy no-op parameter remains only in
historical data and its explanation. README no longer promises an absent
file. New specs use min_repro_energy, with explicit stochastic grass growth.
The exact driver revision is d00ae6fdf6279fa4984e5ce103c5f2d9a39de3c6.

## 9. What Did Not Go Smoothly

The submitted README had control characters and stale run status. Rounded
inputs and post-termination zeros prevented exact interpretation. Full-suite
integration exposed a duplicate module import absent from standalone tests.
The app restart preserved source and results. A cleanup guard rejected
restoring temporary transfer copies; those copies remain backed up, and a
fresh isolated checkout continued the work without discarding them.

## 10. Known Residuals

This is a bounded exploratory design with five seeds per environment and
1000 ticks. Surviving populations are selected by environmental dynamics.
No global optimum, biological calibration or causal effect beyond population
size is established. Snapshots have gaps by design. Cross-platform bitwise
replay is untested; the checked replay used Totoro and Julia 1.10.0.
Earlier results remain historical and cannot be compared as if their
measurement algorithm and trajectories were unchanged.

## 11. Team Learning

Record parameters exactly as simulated and distinguish an unobserved future
from observed extinction. Run standalone scripts inside the suite too.
Record a code revision before compute, then store output checksums beside it.

## 12. Cross-Product Coverage

Covered the agreed five environmental axes, 100 environments and five fixed
seeds, final endpoints and five snapshots. This phase does NOT cover new
biological mechanisms, behavioural-diversity campaigns, other grass modes,
other brain architectures or a published-prediction reproduction claim.

## Documentation, Review and Next Actions

The data README and JSON give commands, source, resources and limitations.
A separate read-only data audit checks the same invariants and evaluates the
agreed exploratory two-stage model. Finish PR checks before merging and
send Bhavya a consolidated update after the issue sweep.

Self-review of the technical report: perceived AI-like style 2/10,
moderate confidence, with concrete file and run evidence. Science and facts
checked against code, logs and data; references are repository and PR paths.
Exact-draft completion check NOTASSESSED. Self-review, 14 November 2026.
