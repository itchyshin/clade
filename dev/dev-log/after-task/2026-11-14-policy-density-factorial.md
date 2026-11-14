# After Task: Founder-density and reproduction factorial

## 1. Goal

Separate the effects of founder density and reproductive threshold on the food-dependent policy-mixture pattern.

## 2. Implemented

Ran a matched four-factor experiment in 100 independent source seed blocks on Totoro: founder count, reproductive threshold, food and founder-age schedule. Each seed supplies one source panel to all 144 assays. The pilot used three separate blocks. Research-only source and assay patches preserve distinct cells and check occupancy each tick; package source and API are unchanged.

## 3a. Decisions and Rejected Alternatives

Source generation is fixed at the lower-bottleneck threshold-80 setup so factorial changes concern assay conditions. The main food estimand is the paired difference between mixture-versus-control contrasts in limited and original food. All runs remain in the analysis, including bottlenecks and extinction. Food treatments jointly change initial grass and regrowth.

## 4. Files Touched

Added `dev/data/policy-density-factorial/` with plan, isolated patch, driver, analysis, audit, figure, raw data and findings. Appended the check log and this report. No public package documentation, NEWS or site changes were needed.

## 5. Checks Run

Pilot: 3 source and 432 assay runs in 98.02 seconds. The pilot and final audit independently reconstructed 84 summary means. The final 100-block Totoro run completed in 536.52 seconds using 24 workers, four Julia threads and one BLAS thread each. R and Python checked 14,400 assay rows and 288,000 window ledgers, including physical and source-panel matching. Per-tick occupancy assertions passed. One hundred and twenty independent initialization assertions and 100 source-state hash checks passed. Source minimum range was 47–74; assay endpoints included 14,359 viable, 40 weak and one extinct. No run hit the cap.

## 6. Tests of the Tests

Python independently reconstructed cell, food, threshold, density, interaction and time-change means from raw windows and checked each population ledger. T intervals and bootstrap intervals were computed in R and were not independently calculated in Python. A pilot with independent seeds tested the same analysis and output invariants.

## 7a. Issue Ledger

At threshold 120, 5,286 of 7,200 assays fell below 20 at least once; at threshold 80, 19 did. This is a treatment outcome, not an exclusion. The food contrast does not separate initial grass from regrowth. High population peaks can produce crowding despite no cap contact.

## 8. Consistency Audit

Searched `threshold|density|bottleneck|food` in the previous findings and current plan. The earlier report correctly identified the joint change as confounded; the new assay factorial varies those factors while holding source generation and cap fixed. The older source setup and cap are not reproduced exactly. No package-source change means package checks, generated documentation and site builds were not run.

## 9. What Did Not Go Smoothly

Several factorial cells intentionally reproduced population bottlenecks, so endpoint viability alone would conceal their instability. One population went extinct; it was retained in all comparisons.

## 10. Known Residuals

Intervals for many planned contrasts are unadjusted for multiplicity. The threshold and density effects interact and can alter other demographic processes. The study cannot attribute the food effect to bottlenecks alone or infer genetic stability from population counts.

## 11. Team Learning

A matched factorial allows direct comparison of food-effect differences and avoids interpreting overlapping intervals as a test. Record source-policy ancestry, source settings, every-tick minima and cap contact alongside endpoint viability.

## 12. Cross-Product Coverage

This covers specified haploid clonal source policies, two founder counts, two thresholds, two food regimes and two age schedules. It does NOT cover isolation of initial grass from regrowth, variation in source-generation conditions or generality to diploid or natural populations.

## Next Actions

A targeted follow-up could track reproduction, deaths and food intake by age and policy under the four density-threshold cells to test which demographic pathways accompany the factorial effects.
