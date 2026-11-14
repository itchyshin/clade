# After Task: Birth and death decomposition

## 1. Goal

Track births and deaths by age in the matched policy-switch experiment and provide a coordinated plan for remaining mechanisms.

## 2. Implemented

Passively replayed 100 seed blocks in three arms on Totoro with event counts and pre-mortality age-specific agent-ticks. Documented the demographic decomposition and a staged future research plan. No package kernel or public API changed.

## 3a. Decisions and Rejected Alternatives

Events are counted by parent age for births and individual age for deaths after the tick's age increment. Demographic comparisons follow a previously observed tick-800 pattern and remain exploratory. Counts alone cannot identify mediation or separate age composition from rates.

## 4. Files Touched

Added the plan, research plan, source, analysis, independent audit, findings and receipts under `dev/data/policy-demography/`; appended the check log and this report.

## 5. Checks Run

The second pilot passed in 11.90 seconds and reproduced all 60 earlier checkpoint rows. Full Totoro replay finished in 38.03 seconds, with eight workers, four Julia threads and one BLAS thread each. The observer asserted kernel birth and death counters and population conservation each tick. R checked all 6,000 checkpoint rows against prior shared fields; Python independently checked interval conservation and reconstructed 248 summary means. All 300 endpoints were viable using `viability_report()`; the sampled minimum was 24. From ticks 600 to 800 treatment had 2.94 additional births and 0.97 additional deaths, giving a 1.97 population difference.

## 6. Tests of the Tests

Independent replay used the previously archived trajectories as a fixture. Python re-derived demographic totals directly from the raw age-bin counts and verified the accounting; confidence intervals were computed in R and not independently checked. Per-tick assertions compare events with kernel counters and require population conservation.

## 7a. Issue Ledger

The study describes the original matched-switch intervention and does not identify a unique biological cause. Parent age counts conflate population composition and reproduction rate. Age-band and time-window comparisons are exploratory.

## 8. Consistency Audit

Searched `age|birth|death|density|food` in the previous findings and current plan. Previous reported population and age trajectories are exactly reproduced. No user-facing package, site or design contract changed, so package checks and documentation generation were not run.

## 9. What Did Not Go Smoothly

The first pilot exposed a dictionary membership error before any full campaign. The corrected pilot passed the replay and per-tick conservation checks. The sampled minimum does not cover every tick.

## 10. Known Residuals

The research observer assumes newborn parent IDs refer to agents present in the post-movement snapshot; the driver asserts this in each run. It retains extinction padding, but all full-run endpoints were viable. Artificial policy reassignment can restore extinct policy types, and density and age are matched only at intervention.

## 11. Team Learning

Birth–death accounting localizes demographic contributions without establishing a causal mediator. Independent seed panels and factorial environmental interventions are needed to test generality and mechanism.

## 12. Cross-Product Coverage

This covers one haploid clonal world and the tick-600 matched-switch intervention. It does NOT cover different intervention times, ploidies or continuous demographic control.

## Next Actions

Review the staged research plan, then pilot a seed-disjoint factorial food and founder-age replication if requested.
