# After Task: Age and policy demographic pathways

## 1. Goal

Track births, deaths and food intake by age and policy in the matched founder-density and reproductive-threshold factorial.

## 2. Implemented

Replayed the 100 archived source panels and all 14,400 assay trajectories with a research-only per-bite observer in an isolated Julia source copy. Recorded births by parent age and policy, deaths by individual age and policy, grass intake and pre-mortality agent-ticks in four age bands. Package source and public API were not changed.

## 3a. Decisions and Rejected Alternatives

Use the full 1–1,000 tick population accounting identity, with age and policy contributions and exposure-normalized rates as exploratory follow-ups. The original age bands and endpoint were chosen after the earlier factorial; no mediation claim or multiple-comparison correction is implied. Control rates pool exposure across the eight controls.

## 4. Files Touched

Added `dev/data/policy-pathways/` with the plan, isolated kernel observer patch, driver, reduction and analysis code, audits, raw-data manifest, figure and findings. The full raw 50-tick table is archived on Totoro, with its checksum tracked locally. Appended the check log and this report. No package kernel, user API, site or vignette was changed.

## 5. Checks Run

Pilot: one complete block and 144 assays in 90.02 seconds; all 2,880 windows reproduced prior outputs. Full Totoro replay: 100 blocks and 14,400 assays in 414.79 seconds, 24 workers, four Julia threads and one BLAS thread. `reduce.py` checked every one of 288,000 original windows, policy-age sums and population identities. Python independently reconstructed 648 summary means, 16 policy-dominance food-contrast means and dominance from 32,000 mixture windows. A further independent audit reconstructed all age-specific mixture and pooled-control rates from the raw windows. All 18 previous population contrasts and t intervals matched. Tick-level event, food and occupancy assertions passed; 100 archived source-state hashes and isolated patch hashes matched. The figure was rendered and visually inspected.

## 6. Tests of the Tests

The previous factorial output is an independent fixture for every replayed 50-tick population, food, birth, death and exposure total and initial-state hash. Separate Python scripts reconstruct summary and policy-dominance means and age-specific rates. T intervals and bootstrap sensitivity were calculated in R and not independently recomputed, except population intervals checked against the earlier factorial.

## 7a. Issue Ledger

Age and policy patterns are observational, with unadjusted multiple comparisons and possible exposure and lineage-abundance confounding. Total birth and death components have wide individual intervals. Control rates pool exposure; they are not equal averages of individual-policy rates. Policy labels have meaning within a seed only.

## 8. Consistency Audit

Searched `threshold|bottleneck|birth|death|policy|food` in the previous factorial findings and current plan. All prior factorial population effects match. The hook is confined to a research copy and does not change the package or its R–Julia boundary. No package test suite, generated documentation, NEWS or site build was run because package source is unchanged.

## 9. What Did Not Go Smoothly

Per-agent food attribution required an isolated kernel observation hook and increased raw data size. The hook was checked against grass depletion every tick and the earlier outputs at every 50-tick checkpoint. Policy top-share comparisons select the maximum within each run and need a descriptive interpretation.

## 10. Known Residuals

This replay uses the same trajectories rather than new independent seeds. It cannot establish food intake or age structure as a causal mediator. The grass-only observer does not cover additional resource layers. One extinct assay and all other outcomes were retained. The 20-individual operational bottleneck threshold does not establish genetic stability.

## 11. Team Learning

A demographic accounting identity separates birth and death contributions without proving either mechanism. Age-specific totals and per-exposure rates can differ, and high lineage totals can reflect abundance rather than individual efficiency.

## 12. Cross-Product Coverage

This covers four age bands and eight within-seed clonal policies in the previous haploid food, founder-density and threshold factorial. It does NOT cover other resource layers, mutated assay policies, diploidy, independent replication or causal mediation.

## Next Actions

If causal mechanisms are the next priority, design matched interventions on age-specific reproduction or resource access, with falsifiable predictions and an independent panel of source seeds.
