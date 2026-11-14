# After Task: Matched policy-frequency intervention

## 1. Goal

Test whether restoring founder-policy frequencies at matched population density and age structure prevents the observed late population reversal.

## 2. Implemented

Ran 100 matched seed blocks with natural, sham-shuffled and frequency-restored arms on Totoro. The intervention is a research-only hook in an isolated source copy. It preserves physical state at tick 600 and lets demographic trajectories evolve afterward.

## 3a. Decisions and Rejected Alternatives

The sham preserves evolved policy counts and randomizes assignment; restoring founder frequencies may reintroduce extinct types. This answers a specific intervention question, rather than attributing a natural mechanism from a correlation. The number of changed policy identities differs between arms.

## 4. Files Touched

Added the plan, intervention and analysis scripts, findings, execution receipts and results under `dev/data/policy-frequency/`; appended the check log and this report. Package code, API, vignettes and site were not changed.

## 5. Checks Run

The 300 runs completed in 36.02 seconds with eight workers, four Julia threads each and one BLAS thread. The R analysis verified all 6,000 rows, physical-state hashes, assignments, and replay of the earlier natural trajectories. Independent Python audit reconstructed all 240 summary means. All 300 endpoint viability checks returned viable. A second pilot retained all 60 rows after adding an extinction-output safeguard. Source hook and driver hashes matched execution metadata. Primary balanced-minus-sham at tick 1,000 was -1.56 agents, 95% paired interval -3.14 to 0.02; bootstrap interval -3.05 to 0.02.

## 6. Tests of the Tests

Natural-arm population and grass were checked against the independently retained earlier trajectories at all 20 checkpoints for 100 seeds. A separate Python implementation checks assignment and physical-state invariants and reconstructs summary means. It does not independently check confidence intervals. No package tests were changed.

## 7a. Issue Ledger

The intervention changes different numbers of policies in the two shuffled arms and can restore lost policies. Later density and age are not fixed. Neither limitation permits an unqualified attribution of the original reversal to natural policy frequency change.

## 8. Consistency Audit

The research hook is confined to a source copy; no public contract or Julia kernel change was made. Searched `frequency|density|age structure` in the previous findings and current plan. The previous report correctly treats causal mechanisms as unresolved; this report narrows one intervention question. Design, NEWS and site changes are unnecessary for this private research experiment. Full package tests and package check were not run because package code was unchanged.

## 9. What Did Not Go Smoothly

The original pilot required an extinction-output safeguard before the full campaign; the revised pilot reproduced all 60 rows. Endpoint viability does not test the within-run minimum.

## 10. Known Residuals

The primary confidence interval includes zero, with no prespecified equivalence margin. The tick-800 contrast is exploratory and unadjusted. This artificial haploid clonal intervention does not model natural policy switching. Reassignment counts differ between groups and density and ages are matched only at intervention.

## 11. Team Learning

Exact state branching and an active shuffle control make a causal intervention more informative than a correlation while retaining the limits of the manipulation. Track switched identities and restored extinct types explicitly.

## 12. Cross-Product Coverage

This covers the original-food, fixed-founder-age setting at the tick-600 intervention. It does NOT cover continuous density or age control, other food regimes, ploidies or later intervention times.

## Next Actions

If the user wants a further mechanism test, design an intervention that matches the number of switched policies while varying their frequency distribution, and track age and density afterward.
