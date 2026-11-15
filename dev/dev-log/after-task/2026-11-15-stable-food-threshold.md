# After Task: Stable food-by-threshold study

## 1. Goal

Test the matched food-by-reproductive-threshold population interaction in a lower-bottleneck world and track parent-age reproduction and time to first birth.

## 2. Implemented

Ran two thresholds, two food regimes, two founder-age schedules, one mixture and eight equal single-policy controls on 100 new source panels. Applied maximum age 300 to all assay arms after a preset candidate screen and a fresh validation. Source training used the previous max-age-200, threshold-80 settings. The Julia gate and observers are isolated research instrumentation; package source and public APIs are unchanged.

## 3a. Decisions and Rejected Alternatives

The prespecified first passing candidate was max age 300. The 250 candidate failed threshold-120 endpoint viability and 400 was not selected. The 300 validation passed threshold-specific endpoint and no-bottleneck gates. Lifespan changes birth and survival directly, so comparison against the prior world cannot isolate bottlenecks. Food initialization and regrowth remain coupled.

## 4. Files Touched

Added `dev/data/stable-food-threshold/` with plan, isolated driver, launcher, audit, cross-threshold start reconstruction, competing-risk check, analysis, figure, data receipts and findings. Appended the check log and this report. Raw cohorts, source states and pilot events are archived on Totoro.

## 5. Checks Run

The 8-run, 60-tick smoke passed. The five-seed three-candidate screen plus prior-seed replay completed in 62.02 seconds; the independent five-seed validation completed in 60.01 seconds. The replay matched ten fields in 36 prior threshold-80 runs. Python independently reconstructed each pilot cohort, age-band birth tally and tick-by-tick population trace from opportunity and death records; it checked 282,557 events in the selected screen, 283,991 in validation and 64,601 in replay. At max age 300 the threshold-120 screen had 176 of 180 no-bottleneck runs and 180 viable; validation had 179 of 180 no-bottleneck and 180 viable. The 100-seed final campaign ran 7,200 assays in 306.12 seconds using 24 workers, four Julia threads and one BLAS thread. The final audit checked 844,371 cohorts, age-birth and death totals, start matching within thresholds and population conservation. The reconstructed start checker verified 400 normalized cross-threshold starts and all 100 distinct source panels matched with positive behavioural disagreement. There were 7,198 viable and two weak endpoints; 77 runs dipped below 20 and none crashed, became extinct or contacted the cap. `survival::survfit` matched 16 screen, 16 validation and 16 final competing-risk estimates. Five hundred final raw, 96 screen raw, 30 validation raw and three compressed-summary checksums passed. The saved tables locally regenerated all 264 effect and 1,600 seed-summary rows. The interaction plot was generated and visually inspected.

## 6. Tests of the Tests

The independent audit reconstructed event timing and population traces for pilots and verified total births by parent age. A hand-calculated competing-death and censoring example passed and was supplemented by `survival::survfit` comparisons. No-op replay matched the earlier simulation. Exact run starts were reproduced independently and normalized only at the intended genomic threshold position. Full opportunity rows were not retained, so full-run event detail relies on driver assertions and the stored cohort and death ledgers.

## 7a. Issue Ledger

Some unadjusted age-band interaction intervals exclude zero, but the population interaction intervals do not, and the age-band counts are descriptive components rather than a causal mediation test. The high-threshold limited-food same-age group had only 836 of 900 runs without a transient sub-20 dip despite passing the preset overall threshold-specific stability gate.

## 8. Consistency Audit

Searched `repro|censor|age|food|threshold|gate` in the prior findings and current plan. Verified the genomic-threshold exception to raw fingerprint matching, exact interaction direction, cohort selection, source identities and stable-setting qualification. No package source, exports, generated documentation or site changed; package checks were not run.

## 9. What Did Not Go Smoothly

The initial audit assumed raw initial fingerprints should match across thresholds. They include the threshold value encoded in each genome, so that assertion correctly failed. A separate reconstruction checked the recorded hash and compared a normalized fingerprint with only the treatment trait removed; all 400 final worlds matched. The prespecified subgroup outcomes exposed residual bottlenecks in limited food even though the overall threshold-level gate passed.

## 10. Known Residuals

Maximum age 300 is a new world with direct demographic consequences. The two food changes remain coupled. Young-eligible cohorts are selected after treatment, and waiting time after eligibility is close to zero for most parents. Confidence intervals are unadjusted for the two age schedules and exploratory age/time outcomes. A population below 20 is retained and the operational threshold does not prove ecological or genetic stability.

## 11. Team Learning

When a treatment is encoded in a genome, raw start hashes cannot be expected to match. Verify the actual recorded fingerprint first, then remove only the intended trait for an independent cross-treatment match. Report subgroup stability even when a prespecified pooled condition passes.

## 12. Cross-Product Coverage

Covers two thresholds, two food regimes, two founder-age schedules, 96 assay founders, eight controls, 100 haploid source panels and a 300-tick assay maximum age. It does not cover alternate founder densities, other ploidies, separate grass initialization and growth changes or natural populations.

## Next Actions

If the age-band shift merits causal follow-up, design an intervention on reproductive scheduling that preserves comparable population trajectories and checks whether the shift changes mixture performance.
