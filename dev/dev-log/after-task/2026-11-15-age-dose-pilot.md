# After Task: Young-parent reproduction dose-response pilot

## 1. Goal

Test whether blocking young reproductive opportunities produces postponement, tracking individual opportunities and energy in matched worlds from new source seeds.

## 2. Implemented

Ran five doses from zero to complete blocking for 900 assays on five source seeds, plus 36 matched sham replay assays on an earlier source. The research copy uses the preceding private gate; the package kernel and public API are unchanged.

## 3a. Decisions and Rejected Alternatives

Focused on young parents, where earlier work suggested compensation. Blocking happens before local-space and mate checks, so a blocked opportunity is not a guaranteed birth. Five source blocks are a pilot, not a powered causal mediation analysis.

## 4. Files Touched

Added `dev/data/age-dose-pilot/`, including plan, driver, launch and audit scripts, summary results, source checks, raw-data location and findings. Appended the check log and this after-task report. Large individual records remain on Totoro.

## 5. Checks Run

The 12-run, 60-tick smoke passed in the research copy. Totoro completed 900 pilot and 36 replay assays in 116.01 seconds, using six workers, four Julia threads and one BLAS thread. The independent Python audit checked 1,609,561 opportunity rows, keyed decisions, birth and death ledgers, follow-up, initial matching, source panel hashes and exact replay of eight fields in 36 prior runs. Five source panels each contained eight distinct policies with positive behavioural disagreement. All 900 assay endpoints were viable; 340 had an every-tick minimum below 20. Thirty raw-file SHA-256 checks passed.

## 6. Tests of the Tests

Python independently reproduced gate decisions; the 100% arm confirmed all subsequent births occurred after age 50. Follow-up fixtures cover a missing event near the horizon, a complete negative observation, death and a later birth. The sham matched eight prior-run fields. The Python and R summaries use the same underlying event table; confidence intervals were not independently recomputed.

## 7a. Issue Ledger

The initial follow-up audit used tick 1001 as the missing-event sentinel and falsely classified some censored parents as births. Replaced the sentinel, added explicit censoring fixtures and a 100% dose age invariant, then reran the full audit and summaries. Proportions condition on outcome observation and are descriptive, not a formal survival analysis.

## 8. Consistency Audit

Searched `repro|age|food|threshold|gate` in the earlier findings and pilot plan. The experiment uses the existing research patches and exactly the previous source hashes. The previous finding concerned opportunity blocking; this pilot follows actual parents but does not identify natural mediation. No package source or documentation changed, so package checks and site rendering were not applicable.

## 9. What Did Not Go Smoothly

The first audit exposed an end-of-run sentinel error. It affected only preliminary follow-up summaries, not simulation data. Corrected results and checks are retained; the outcome-dependent censoring limitation remains.

## 10. Known Residuals

Five independent source seeds limit precision. Many high-threshold runs bottlenecked. Age, density and policy frequencies can diverge after intervention. Energy changes between ticks are not attributable solely to reproduction. The individual blocked-to-later-birth observation does not establish a counterfactual postponement for that individual.

## 11. Team Learning

Gate decisions and successful births are distinct. Track parent identity, observation windows, energy and competing end states, and test censoring at the exact final-tick boundary.

## 12. Cross-Product Coverage

Covers five young-gate doses in the specified two food and two threshold settings, 48 equal-age haploid founders, mixture and eight controls. It does not cover older-parent restriction, staggered founder ages, alternate ploidy or natural populations.

## Next Actions

If the population question remains a priority, preregister a larger independent-seed study with explicit survival analysis and a viability criterion that addresses transient bottlenecks.
