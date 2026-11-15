# After Task: Stable-world reproductive timing

## 1. Goal

Run a larger new-seed study of young-parent reproductive timing and matched policy-mixture population contrasts in a lower-bottleneck setting.

## 2. Implemented

Ran five reproductive-opportunity doses, both food regimes, same-age and staggered founders, a mixture and eight balanced monocultures using 100 new source panels. Followed each agent from its first eligible young opportunity through first birth, death or administrative censoring. The research-only kernel hook, package code and public API are unchanged.

## 3a. Decisions and Rejected Alternatives

Used 96 founders, threshold 80 and cap 700 from the prior independent stability study. The pilot retained all outcomes and had preset endpoint, minimum-population, cap, matching and replay checks. The time-to-birth cohort includes sham and unblocked individuals, unlike the prior blocked-only descriptive pilot. The threshold was held at 80, so the earlier food-by-threshold interaction is outside this study's scope.

## 4. Files Touched

Added `dev/data/stable-time-birth/` with plan, isolated research driver, launch and audit scripts, survival cross-check, source checks, analysis, figure, results and findings. Appended this report and the check log. Raw individual and source data remain on Totoro with SHA-256 manifests.

## 5. Checks Run

A 12-assay smoke test ran for 60 ticks. The five-seed pilot completed 900 assays plus 36 sham replay assays in 124.01 seconds. It passed 95% endpoint and no-bottleneck gates, cap and physical matching checks, all 36 ten-field prior-run replays, five distinct source panel checks and independent reconstruction of 1,936,800 individual opportunity records. The final campaign ran 100 source seeds and 18,000 assays in 630.15 seconds on Totoro, 24 workers with four Julia threads and one BLAS thread. The final audit checked 3,668,870 individual cohorts, all first gate decisions and death/birth ordering, initial matching and run-level population conservation. There were 17,954 no-bottleneck and 17,930 endpoint-viable assays, 70 weak, no crashed or extinct and no cap contact. All 100 panels had eight distinct policies and positive deterministic disagreement. All 500 raw and three compressed-summary checksums passed. The saved run and timing tables regenerated all 880 effect and 4,000 seed-summary rows on the local machine. Aalen-Johansen estimates matched `survival::survfit` on 24 pilot and 24 full run/cohort combinations. Figure generation was rerun without warnings and the image was visually inspected.

## 6. Tests of the Tests

The gate's zero and complete-dose boundary conditions and a hand-calculated time-zero birth, competing death and censoring case are asserted. The pilot reconstructs each cohort's entry, first gate decision and subsequent birth independently from raw opportunity events and verifies run birth totals. The prior-seed sham matches ten earlier-run fields. The competing-risk implementation is separately checked against R's `survival` package. Full opportunity events were not retained, so full-run later-event reconciliation relies on driver assertions and the recorded cohort and death ledgers.

## 7a. Issue Ledger

One unadjusted intermediate-dose population interval barely excludes zero among 16 dose-by-world comparisons. It is exploratory and does not form a consistent monotone pattern. The 50-tick cumulative incidence is a treatment-world cohort estimand; cohort membership changes after treatment and is not an individual causal postponement estimate.

## 8. Consistency Audit

Searched `repro|censor|age|food|threshold|gate` in the previous findings and new plan. Results preserve the actual fixed-threshold scope, operational stability definition and censoring limits. No package source, exported interfaces, generated documentation or site changed, so package checks were not run.

## 9. What Did Not Go Smoothly

The original plot produced zero-length error-bar warnings for near-identical endpoints. Replaced the arrow-based bars with line segments and regenerated the figure without warnings. Administrative censoring can depend on cohort-entry timing; a full-window sensitivity is reported.

## 10. Known Residuals

Death was modeled as a competing event but did not occur before first birth within the recorded 50-tick follow-up. No-random-censoring assumptions, post-treatment cohort selection, the absence of a threshold-120 arm, coupled food changes and unadjusted multiple comparisons limit inference. Some runs bottlenecked and all were retained.

## 11. Team Learning

Include sham individuals at their first eligible opportunity, use source blocks for uncertainty, verify time-zero events and competing-risk estimates independently, and distinguish temporary population stability from genetic or ecological stability.

## 12. Cross-Product Coverage

Covers five young-gate doses, two food regimes, two founder-age schedules, 96 assay founders, eight single-policy controls, 100 haploid source panels and a threshold of 80. It does not cover older-parent gating, threshold 120, other ploidies or natural populations.

## Next Actions

If the previous food-by-threshold reversal remains the main question, design an independent stable-world test that varies threshold while monitoring transient bottlenecks and reproductive timing.
