# After Task: Age-specific reproduction interventions

## 1. Goal

Test whether reducing young or old reproductive opportunities changes the food-dependent policy-mixture population pattern, using matched controls and new source seeds.

## 2. Implemented

Ran a four-arm young-by-old gating factorial, crossed with founder density, reproduction threshold, food and founder ages, on 100 new source panels. A research-only Julia gate blocks approximately half of targeted eligible opportunities using a separate keyed pseudorandom function. The four arms include a no-block sham. Package source and public API are unchanged.

## 3a. Decisions and Rejected Alternatives

The gate is applied before space, mate and reproductive-cost checks, so a blocked opportunity is not necessarily a foregone birth and parents retain potential cost. The main diagnostic is the gate-induced change in the food-dependent threshold effect on mixture-minus-control population. Both-gate and 96-founder comparisons are secondary. All outcomes are retained.

## 4. Files Touched

Added `dev/data/age-reproduction-causal/` with plan, source patches, driver, analysis, audit, pilot records, findings and raw-data manifest. Appended the check log and this report. The full raw tables and source states remain on Totoro with tracked SHA-256 manifests.

## 5. Checks Run

Pilot: four interventions on a new seed, 576 assays, plus 144 no-op reference assays. All intervention endpoints viable; targeted gates blocked 50.0–50.4% of eligible opportunities; all 2,880 no-op windows and 144 runs matched the previous source. Independent synthetic key balance and four Julia-versus-Python hash fixtures passed. Full: 100 new source seeds, 57,600 assays, 1,152,000 windows, 1,726.28 seconds on Totoro, 24 workers, four Julia threads and one BLAS thread. R and independent Python reconstructed 640 factorial and 384 realized-birth means, initial-state matches, opportunity counts and all population and age-birth ledgers. A deliberately corrupted sham counter was rejected. 100 source-state and raw-data SHA-256 checks passed. The figure was rendered and visually inspected.

## 6. Tests of the Tests

The no-op gate matched a prior independent run and source hash. Separate Python reconstructs every block, gate count, age-birth table, viability summary and reported factorial mean from raw windows. A negative fixture with an impossible sham blocked count failed as expected. The hash implementation matched independent Python fixtures. Confidence and bootstrap intervals were calculated in R and were not independently recomputed in Python.

## 7a. Issue Ledger

The 50% opportunity intervention produced much smaller realized birth reductions in some settings. Parents can retain energy and may reproduce later; the observer does not follow individual postponement. The single-gate age-staggered older-parent estimate had a nominal unadjusted interval excluding zero but a post hoc Holm four-comparison p-value of 0.084. The age gates do not directly isolate natural mediation.

## 8. Consistency Audit

Searched `repro|age|food|threshold|gate` in prior findings and the current plan. The previous observational shift is accurately described and the new trial tests a specific intervention. No package source, R–Julia boundary, API, generated documentation or site changed; package checks were not run.

## 9. What Did Not Go Smoothly

Opportunity-level blocking is not equivalent to halving successful births. Simulation random trajectories diverge after blocked reproduction even though the gate itself draws no simulation RNG. High-threshold populations often bottlenecked; these outcomes remained in the estimand.

## 10. Known Residuals

The result does not establish equivalence or rule out stronger interventions. Parent age and other demographics can change after the gate. The design concerns haploid clonal policies, the specified food worlds and a 50% opportunity gate. Primary intervals are unadjusted; Holm adjustment is post hoc. Source trajectories and events are archived on Totoro, not committed as large generated files.

## 11. Team Learning

Measure both the randomized opportunity intervention and realized births: demographic compensation and pre-birth constraints can greatly reduce the effective perturbation. A causal gate effect is not proof of mediation by the naturally observed age shift.

## 12. Cross-Product Coverage

This covers two targeted age bands, four gate conditions, two founder densities, thresholds, food regimes and age schedules for the specified clonal source panels. It does NOT cover individual postponement, other ploidies, isolation of food initialization from regrowth or natural-population generality.

## Next Actions

If causal resolution is still desired, design a dose-response intervention with individually tracked reproductive events and energy costs, predefine its viable operating range, and test on separate source seeds.
