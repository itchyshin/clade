# After Task: Independent policy-mixture factorial replication

## 1. Goal

Pilot and, if checks pass, replicate the food-by-founder-age policy-mixture experiment with new seed blocks on Totoro.

## 2. Implemented

Generated 100 new source populations and tested 3,600 matched assay populations in four haploid worlds. The five-block pilot passed and was retained. Added the plan, research-only driver, analysis, raw results, figure and findings. No package kernel or API changed.

## 3a. Decisions and Rejected Alternatives

Used source seeds 40001–40100, disjoint from earlier campaigns. All 100 blocks and all 3,600 assay runs enter the primary analysis. Endpoint viability is reported separately from every-tick minima; excluding low-population histories would change the estimand. The early bottlenecks mean these are not continuously stable populations.

## 4. Files Touched

Added `dev/data/policy-replication/`, appended the check log and wrote this after-task report. Site, NEWS and package documentation were not changed.

## 5. Checks Run

Pilot: 5 source populations and 180 assay runs, 36.01 seconds; all endpoint viable and behavioural checks passed. Full continuation: 95 source populations and 3,420 assay runs, 262.11 seconds, eight workers, four Julia threads and one BLAS thread. `Rscript dev/data/policy-replication/analyze.R /tmp/clade-replication/combined` checked all 3,600 runs and 72,000 window ledgers. The separate Python audit reconstructed all summary means and checked initial physical and panel matching. Fourteen independent initialization assertions passed; 100 source-state SHA-256 checks passed on Totoro. All 100 source endpoints and 3,595 assay endpoints were viable; 2 assay endpoints extinct, 3 weak. The figure was rendered and visually inspected.

## 6. Tests of the Tests

An independent Python implementation reconstructs cell, change, food, age and interaction means from the raw 50-tick tables. Interval balances are independently rechecked against endpoints. The pilot and full use the same predeclared analysis; t intervals and bootstrap intervals were computed in R and not independently reproduced in Python. The pilot used five blocks and does not establish power.

## 7a. Issue Ledger

Source and assay populations often dip below 20 individuals despite viable endpoints. These bottlenecks may affect ancestry and limit inference to continuously viable populations. Food treatment changes initial grass and regrowth together; staggered founder mean age differs by 1.5 ticks. The whole-mixture comparison does not isolate the prior within-population intervention.

## 8. Consistency Audit

Searched `viab|food|age|reversal|800` in the earlier factorial findings and coordinated plan. The new estimates support the same tick-1,000 directional pattern, with independent seeds. No site, design contract, public documentation or package source changed; package checks and documentation generation were not run.

## 9. What Did Not Go Smoothly

The pilot exposed substantial transient bottlenecks in source populations. The pilot met its stated endpoint-viability and behavioural gates; no block was replaced or excluded. Reported endpoint viability must not be confused with stability throughout the run.

## 10. Known Residuals

Two primary endpoints in four conditions are reported with unadjusted 95% intervals. The fixed set of 100 blocks matches the earlier sample size but does not guarantee statistical power. Results are limited to these haploid, clonal policy sources and specified worlds.

## 11. Team Learning

A seed-disjoint replication can test a previously observed environmental pattern, but trajectories and ancestry matter alongside endpoint viability. Report every-tick bottlenecks and source survival explicitly.

## 12. Cross-Product Coverage

This covers two food regimes and two founder-age schedules for haploid clonal policy mixtures. It does NOT cover severe food shortage, diploidy, isolated grass versus regrowth effects or continuous population stability.

## Next Actions

Review whether to pursue a seed-disjoint matched intervention on policy frequencies and food or first construct a stable-population design that avoids severe transient bottlenecks.
