# After task: Long, food-limited policy mixtures

## 1. Goal

Test whether the earlier policy-mixture population advantage persists for
1,000 ticks with limited food and staggered founder ages on Totoro.

## 2. Implemented

Ran 3,600 simulations in 100 matched seed blocks per ploidy and food regime.
At regrowth .025 all populations remain viable; the haploid mixture has
3.55% more agents at tick 1,000 and the diploid interval includes zero.
At .0125, mixtures have fewer agents on average but go extinct less often.
Findings and intervals are in dev/data/policy-long/findings.md.

## 3a. Decisions and Rejected Alternatives

Use the same eight-policy balanced monoculture benchmark, fixed ploidy and
high-mutation source brains as the preceding study. Spread founder ages from
25 through 72. Reduce initial grass probability to .25 and compare regrowth
.025 and .0125 against the preceding .05. These two changes are simultaneous;
no separate causal attribution to food or age is supported. Retain all
populations, including crashes and extinctions, in main contrasts.

## 4. Files Touched

Research-only driver, isolated staggered-age patch, launcher, initialization
check, analysis, raw-table audit, plot and source-bound evidence live under
dev/data/policy-long. The public kernel, API and defaults are unchanged.
Check log and this report record the campaign.

## 5. Checks Run

Pilot 36 runs: 20 seconds and 427484 KiB peak. All 18 groups at .025 were
viable; at .0125, 12 of 18 crashed and 3 were weak in that one-seed pilot.
Full 3,600 runs: 270.04 seconds on four Totoro workers, 4 Julia threads and
one BLAS thread per worker. The recorded 15-minute estimate was not exceeded.

Forty-eight initialization assertions passed across ploidies and food levels.
The first-seed driver check exactly reproduced all 36 pilot run rows, and its
720 window rows exactly match the production campaign. The R analysis checks
complete keys, 72,000 windows, population and exposure balances and actual
viability_report outcomes. An independent Python audit reconstructs all-block
means and population, exposure, birth and death ledgers. Raw files, summary,
plot, execution metadata, scripts and checksums are retained.

## 6. Tests of the Tests

The initialization test checks all eight controls against each mixture's
physical-state digest, 48 unique positions, ages 25 through 72, fixed ploidy
and phenotype/genome agreement. Exact replay and independent raw-table
reconstruction provide separate checks against reported summaries.

## 7a. Issue Ledger

No kernel defect or public-interface change was found. The prior policy
mixture PR remains a separate dependency. No external message was sent.

## 8. Consistency Audit

Balanced seed-block comparisons and complete control sets match the prior
study. Extinctions remain in the all-block analysis. At severe food shortage
no block has all nine groups viable, so a selected viable-only estimate is
unavailable. The patch changes age in an isolated source copy only. No public
vignette, package documentation or release note is required. Exact search:
`rg 'viable|extinct|regrowth|age|1000' dev/data/policy-long`.

## 9. What Did Not Go Smoothly

The first remote attempt to inspect timing used rg, unavailable on Totoro;
the timing file was read directly. No simulation was repeated or interrupted.
The pilot and production driver use a pinned repository source plus an
explicit one-line age patch, rather than changing the installed kernel.

## 10. Known Residuals

This does NOT cover food and age effects separately, longer than 1,000 ticks,
lifetime fitness, complementarity or effects relative to the best policy.
Extinction and abundance are different endpoints and secondary comparisons
are unadjusted. The one-seed pilot is diagnostic, not a biological estimate.
No package-wide checks were rerun for these research-only scripts; the source
branch's prior Julia and CI checks are documented in its own report.

## 11. Team Learning

Fisher: report both extinction and abundance, with all controls retained.
Gauss: use exact replay and independent ledger checks for the new age schedule.
Rose: simultaneous environmental changes limit attribution to one mechanism.

## 12. Cross-Product Coverage

This phase covers the research driver, age patch, raw tables, analysis, plot,
validation receipts, findings, check log and this report. It does NOT cover
new public APIs, package release, other source mutation levels or other food
worlds. The source policies and preceding experiment remain separately bound.
