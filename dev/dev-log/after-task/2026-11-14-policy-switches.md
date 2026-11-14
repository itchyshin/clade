# After Task: Matched policy switches

## 1. Goal

Test a frequency intervention while matching switched individuals and track subsequent age structure and population density.

## 2. Implemented

For each of 100 seeds, ran natural, frequency-preserving pair-swap and more-even-frequency arms from the same tick-600 state on Totoro. Both interventions change exactly the same individuals. A research-only hook in an isolated Julia source copy is used.

## 3a. Decisions and Rejected Alternatives

Exact restoration of the founder mix cannot always be achieved with the same number of changes as a frequency-preserving shuffle. The chosen disjoint-pair intervention matches switched identities and counts, and accepts treatment pairs that make policy counts more even. The manipulation is partial and can restore lost policies.

## 4. Files Touched

Added the plan, driver, analysis, audit, findings and results under `dev/data/policy-switches/`; appended the check log and this report. No package source, user API, vignettes or site changed.

## 5. Checks Run

A pilot finished in 12.35 seconds and matched 60 switches and physical states. The full 300-run campaign finished in 40.02 seconds with eight workers, four Julia threads and one BLAS thread each. R analysis checked 6,000 checkpoint rows, matched switch counts, physical hashes, age totals, frequency totals and natural replay. Independent Python audit reconstructed 360 summary means. The Julia driver asserts equal switched identity sets. `viability_report()` rated all 300 endpoints viable; the sampled minimum was 24 across initial and 50-tick observations. The primary difference at tick 1,000 was 0.03 agents, paired 95% interval -1.43 to 1.49.

## 6. Tests of the Tests

Natural population and grass matched the independent previous trajectories at all 20 checkpoints for every seed. The Python audit independently reconstructed summary means but did not independently calculate confidence intervals. Bootstrap sensitivity was similar to the paired t interval. The pilot tested identity and physical invariants before the full run.

## 7a. Issue Ledger

The arm difference includes target policy assignment and can reintroduce lost policies. No causal conclusion about natural selection or a continuously fixed demographic structure follows. Intermediate times and age-bin comparisons are exploratory.

## 8. Consistency Audit

Searched `frequency|density|age structure` in the preceding findings and current plan. The earlier report correctly describes its own unequal-switch treatment; this task addresses that limitation without changing the previous experiment. The isolated hook preserves the package contract. No NEWS, site or design change is needed. Package checks were not run because the package source was unchanged.

## 9. What Did Not Go Smoothly

A fully even restoration could not be guaranteed while matching switch count and individual identities. The algorithm records its actual effect and avoids claiming full balance.

## 10. Known Residuals

The endpoint interval includes zero without a prespecified equivalence margin. Age and density are matched at intervention only, and sampled viability minima are not tick-level minima. The artificial reassignment is not a model of natural policy switching.

## 11. Team Learning

Matching the switched individuals controls their number and identity, but target policies and association with individual state still define the treatment. Record intermediate age bins as exploratory outcomes rather than mediators proved causal.

## 12. Cross-Product Coverage

This covers the original-food, fixed-founder-age haploid world with intervention at tick 600. It does NOT cover continuous density or age control, other ploidies, food regimes or intervention times.

## Next Actions

A future follow-up could intervene on food availability or demographic structure at matched state, or measure births and deaths by age to understand the observed transient difference.
