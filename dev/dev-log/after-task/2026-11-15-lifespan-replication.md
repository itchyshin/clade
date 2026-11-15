# After Task: Independent lifespan replication

## 1. Goal

Repeat the food-by-threshold population and birth-age comparison at a separately validated lifespan, and summarize the accumulated work for Bhavya.

## 2. Implemented

Validated lifespan 400 on five new source panels, then ran 100 source blocks paired with the earlier lifespan-300 experiment and 100 independent new blocks. Added a synthesis that distinguishes legacy-kernel results from corrected-model studies. The package and public API were not changed.

## 3a. Decisions and Rejected Alternatives

The earlier 400-tick candidate screen had passed its stability criteria. Fresh validation used separate seeds and retained all outcomes. Matching the earlier 100 source seeds permitted direct paired lifespan comparisons; the additional 100 were an independent replication. A planned full age-band replay was stopped at the user's request to finish soon before any replay block completed. No partial replay outcomes were analyzed. The five-seed validation's age-bin split is descriptive only.

## 4. Files Touched

Added `dev/data/lifespan-replication/` with plan, launch and analysis scripts, audits, results, figures, synthesis and findings. Appended the check log and this report. Source states and cohort records remain on Totoro with raw hashes.

## 5. Checks Run

Fresh validation: 360 assays, all endpoint viable, no sub-20 dip and no cap contact; 72 earlier seed assays replayed with 20 matching run fields. The pilot event reconstruction, source-panel and 20 normalized-start checks passed; 16 competing-risk estimates matched `survival::survfit`. The 200-block main study ran 14,400 assays in 572.24 seconds using 24 workers, four Julia threads and one BLAS thread. All 14,400 remained above 20 and ended viable, with no cap contact. The full audit checked 1,529,909 individual cohorts and demographic accounting. All 200 panels were distinct and behaviourally differing; 800 normalized cross-threshold starts matched. All 7,200 earlier-lifespan matched starts had identical physical and policy-panel hashes, and all 100 paired source-state files had identical SHA-256 hashes. Sixteen full competing-risk checks matched `survival::survfit`. One thousand main, 36 validation and three summary checksums passed. The comparison figure was visually inspected.

## 6. Tests of the Tests

Pilot individual opportunities independently reconstructed first-birth cohorts, age-band births, death records and tick-by-tick population histories. The replay matched all 20 specified earlier run fields. A hand-calculated competing-risk fixture and R's separate survival implementation verified timing calculations. Full opportunity records were not retained; full-run first-birth and age-birth event validity relies on driver assertions and cohort, death and run records.

## 7a. Issue Ledger

The original 500-run, matched-founder and first behavioural analyses use a legacy reproduction implementation and need corrected-model replication before interpretation as current-model evidence. The 400-tick 150-or-older birth band includes ages 300–399, unavailable in the earlier lifespan. Five validation seeds show this is a substantial component, but the user-directed stop left no full age-band split. No partial replay output was analyzed.

## 8. Consistency Audit

Searched `legacy|repro|diversity|lifespan|threshold` in prior findings and the current synthesis. Checked primary interaction direction, source identity, stability, cohort selection and band limits. No package source, exports, generated documentation or site changed, so package checks were not run.

## 9. What Did Not Go Smoothly

The older-parent category changed support when maximum age increased. A detailed replay was started and stopped early to honor the user's request to finish. The initial 500-run conclusions also require the visible legacy-kernel qualification rather than a claim that the corrected model has replicated them.

## 10. Known Residuals

The cross-lifespan paired comparison holds the initial source and physical state fixed, while density, age structure, policy frequencies and random trajectories may subsequently diverge. Age-band findings are exploratory and unadjusted; no natural mediation or equivalence has been established. Food initialization and regrowth remain coupled.

## 11. Team Learning

When lifespan changes, a broad age band can cover a different biological range even if it has the same label. Bind claims to the kernel version and keep the user's requested stopping point ahead of optional analysis.

## 12. Cross-Product Coverage

Covers two thresholds, two food regimes, two founder-age schedules, 96 founders, eight controls, 200 source blocks and lifespan 400; 100 sources are paired with lifespan 300. Does not cover other ploidies, separately varied food components, a complete 150–299 versus 300-plus split or natural populations.

## Next Actions

Share the synthesis with Bhavya on issue 182; hold further experiments unless requested.
