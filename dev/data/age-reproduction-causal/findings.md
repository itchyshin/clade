# Does age-specific reproduction drive the population pattern?

The specified interventions did not consistently remove the population pattern. In the primary 48-founder comparisons, halving eligible reproductive opportunities for parents under 50 or aged 150 and older generally produced uncertain changes in the food-dependent threshold effect. One estimate for older parents with staggered founder ages suggested a change in the opposite direction to removal of the pattern, but its interpretation is sensitive to multiple comparisons. These results do not establish that age-specific reproduction has no causal role: realized birth reductions were much smaller than the 50% opportunity blocks.

The measured population pattern is defined in three steps. First, D is the mixture population minus the average of eight single-policy controls. Second, F is D under limited food minus D under original food. Third, T is F at reproductive threshold 80 minus F at threshold 120. The table reports the change in T caused by each single age gate relative to its matched sham, at tick 1,000. Positive values shift the negative sham pattern toward zero; negative values make it more negative.

| Founder ages | Reproductive opportunities blocked | Gate minus sham change in T | 95% interval |
| --- | --- | ---: | ---: |
| Same age | Under 50 | +1.60 | -1.22 to +4.41 |
| Same age | 150 or older | +0.53 | -2.37 to +3.43 |
| Staggered | Under 50 | -0.55 | -3.73 to +2.62 |
| Staggered | 150 or older | -3.30 | -6.09 to -0.51 |

Each comparison uses 100 independent, matched source seed blocks with 48 founders. In the sham, T was -8.84 with same-age founders and -5.84 with staggered founders; the older-parent gate in the staggered condition changed the latter to -9.14. The displayed intervals are unadjusted paired t intervals. As a post hoc sensitivity check across the four primary single-gate comparisons, Holm-adjusted two-sided p-values were 0.79, 1.00, 1.00 and 0.084 in table order. This does not prove the effects are zero. The joint gate and 96-founder comparisons were secondary: for example, the same-age joint-gate change was +3.00 with an unadjusted t interval 0.05 to 5.96, while its bootstrap interval was -0.01 to 5.93. Full estimates are in `results/summary.csv`.

## Did the interventions alter reproduction?

Yes, but blocking half of eligible opportunities did not halve realized births. For example, with 48 same-age founders, threshold 80, original food and a mixed policy population, the young gate reduced mean births to parents under 50 from 460.36 to 436.79 per simulation, a reduction of about 5%. Mean births to parents aged 50–99 increased from 446.98 to 458.17. Those are population-level counts; they do not establish that the same individuals postponed reproduction. Some blocked opportunities might not have produced a birth because the gate acts before local-space and mate checks, and blocked parents retain the potential reproductive cost.

Across the full experiment, the young gate blocked 49.99% of recorded young eligible opportunities; the old gate blocked 50.04% of old eligible opportunities. The combined gate blocked about 50% in both bands. No untargeted opportunities were blocked. Counts of realized births by parent age and matched gate effects are retained in `results/age-births-by-cell.csv` and `results/gate-birth-effects.csv`.

## Design and population viability

The experiment used 100 new source seeds, separate from the pilot and prior studies. Each source panel was reused across founder counts 48 and 96, thresholds 120 and 80, original and limited food, same and staggered founder ages, four gate conditions, one mixture and eight monocultures. Starting physical states matched within each world. Later density, age structure, policy frequencies and RNG trajectories could respond to the intervention. The keyed gate itself consumes no simulation RNG, although skipped reproduction naturally changes subsequent simulation random-number use.

All 57,600 assay outcomes were retained. Source populations never fell below 44 individuals, and all 100 were viable at the endpoint. Assay endpoints included 57,427 viable, 170 weak and three crashed populations; none were extinct at the endpoint. The high-threshold worlds intentionally reproduced many transient bottlenecks: across the four gates, 5,207 to 5,607 of 7,200 threshold-120 runs per gate fell below 20 at some point. No run touched the 700-agent cap. The 20-individual threshold does not establish genetic stability.

The results are causal for the specified intervention on opportunities within these artificial haploid clonal worlds. They are not a direct test of natural mediation by age, do not isolate initial food from regrowth, and do not exclude other interventions or stronger realized changes. The primary intervals and secondary comparisons are not multiplicity-adjusted; the Holm calculation is a clearly labelled sensitivity analysis.

## Validation

A five-worker pilot used one new source seed across four gates and separately replayed a prior source seed with a no-op gate. All 576 intervention pilot endpoints were viable; targeted gates blocked 50.0–50.4% of recorded opportunities and untargeted blocks were zero. The no-op gate reproduced all 144 earlier runs and 2,880 windows checked. An independent hash fixture confirmed the deterministic gate key implementation.

The full run used 100 source simulations and 57,600 assays on Totoro. The independent audit checked all 1,152,000 windows, initial-state and panel matching, gate counts, age-specific birth ledgers, viability summaries, 640 factorial means and 384 paired realized-birth means. The full run took 1,726.28 seconds using 24 workers, four Julia threads and one BLAS thread. Source-state and raw-data checksums passed. The large raw tables and source states are archived on Totoro; tracked aggregates, source code, pilot records and checksums support review.
