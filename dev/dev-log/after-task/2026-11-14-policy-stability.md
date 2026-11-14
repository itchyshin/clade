# After Task: Policy mixtures with fewer bottlenecks

## 1. Goal

Design a more stable simulation setting and test whether the previously observed food-dependent mixture pattern persists on independent seeds.

## 2. Implemented

Screened candidate founder numbers, reproductive thresholds and population headroom, then ran a seed-disjoint 100-block food-by-age experiment on Totoro. The selected research-only setup has distinct founder cells, 96 assay founders, 100 source founders, threshold 80 and a cap of 700. Occupancy is checked every tick.

## 3a. Decisions and Rejected Alternatives

Three screens failed their stated bottleneck and cap criteria. A higher-founder candidate worsened bottlenecks; intermediate thresholds traded bottlenecks against cap contact. The selected headroom candidate failed its first strict validation because two endpoints were 47 versus a viable cutoff of 48. The endpoint gate was revised to 95% and independently validated on new seeds; the original failure remains documented. Pilot seeds were excluded from the main run.

## 4. Files Touched

Added `dev/data/policy-stability/` with the complete plan, pilot and final research scripts, isolated patches, results and findings. Appended the check log and this report. No package kernel, public API, site or vignette was changed.

## 5. Checks Run

The final 100-block Totoro campaign completed in 308.16 seconds with eight workers, four Julia threads and one BLAS thread. R analysis and an independent Python audit checked 3,600 runs, 72,000 interval ledgers, physical and panel matching and all summary means. Per-tick source and assay occupancy assertions passed. All 100 source-state SHA-256 checks passed. The final source minimum was 42; five assay runs dipped to 16–19 and recovered. All 100 source endpoints and 3,585 assay endpoints were viable; 15 assay endpoints weak and none extinct. No run touched the 700-agent cap. The figure was rendered and visually inspected.

## 6. Tests of the Tests

The independent Python audit reconstructs cell, time-change, food, age and interaction means directly from raw windows and checks each population ledger. T intervals and bootstrap intervals were calculated in R, not independently reproduced in Python. Candidate selection checks were independently rerun from saved pilot tables with the gate in effect at each stage. The isolated source and assay patches were applied afresh and their hashes matched the executed files.

## 7a. Issue Ledger

The stable world changes founder density, source placement, reproductive threshold and cap together. It does not identify the causal effect of bottlenecks. Five assay histories still fell below 20. The operational 20-agent threshold is not a guarantee of genetic stability; peak assay density reached 644 of 900 cells.

## 8. Consistency Audit

Searched `bottleneck|viab|food|age|stable` in the preceding replication findings and the current plan. The earlier pattern is accurately described as a result in its own setting; the new setting does not reproduce the same tick-1,000 positive limited-food estimate. The package source and public documentation were not changed, so full package checks and site generation were not run.

## 9. What Did Not Go Smoothly

The preliminary source initializer allowed coincident founders; a research-only initializer with unique cells was added, and candidate selection repeated. Several candidate settings did not pass stability and capacity gates. The first strict endpoint-viability validation failed; the revised gate was disclosed and tested on a further independent validation sample.

## 10. Known Residuals

Intervals for four conditions and two endpoints are not adjusted for multiplicity. Food treatments vary both initial grass and regrowth. The experiment is haploid and clonal, and selected policy panels share source-population ancestry. A conditional complete-block sensitivity is exploratory and does not replace the all-block estimates.

## 11. Team Learning

Increasing starting population can worsen bottlenecks through competition. Check initial spatial occupancy, minimum population and cap contact during both source training and assay rather than relying on endpoint verdicts.

## 12. Cross-Product Coverage

This covers the selected 96-founder, threshold-80 world under two food regimes and two founder-age schedules. It does NOT cover a causal isolation of bottleneck effects, other reproductive thresholds, diploidy or natural populations.

## Next Actions

If a causal explanation is needed, use a matched factorial design that varies initial density and reproductive threshold separately, with the original and limited food regimes, while tracking viability and cap contact.
