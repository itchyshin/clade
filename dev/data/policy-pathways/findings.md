# Births, deaths and food by age and policy

The replay points to a shift in the age distribution of reproduction, but it does not identify a single proven cause of the food-dependent mixture pattern. For 48 same-age founders, lowering the reproductive threshold changed the food effect on the mixture population contrast by -7.67 individuals. This is exactly the sum of a -4.85 birth component and a -2.82 death component. Their separate 95% intervals, -10.84 to 1.15 for births and -8.73 to 3.09 for the sign-reversed death component, are wide. The two components should not be ranked as definitively more or less important from these estimates.

Here, a food effect is the mixture-minus-average-control contrast under limited food minus the same contrast under original food. The threshold change is that food effect at threshold 80 minus the food effect at 120. The numbers below are therefore changes in these matched contrasts, not raw changes in the number of births.

| Parent age | Birth component of the threshold change | 95% interval |
| --- | ---: | ---: |
| Under 50 | -21.29 | -27.75 to -14.84 |
| 50–99 | -3.82 | -8.32 to 0.69 |
| 100–149 | +3.10 | -1.58 to 7.77 |
| 150 or older | +17.16 | 12.38 to 21.94 |

The negative young-parent and positive older-parent contributions largely offset one another. The same direction appeared with staggered founder ages: -20.16 for parents under 50 and +11.14 for parents 150 or older. In the fixed-age condition, the age-specific difference in births per 1,000 pre-mortality agent-ticks was -0.34 (-0.55 to -0.14) for the younger band and +0.51 (0.25 to 0.76) for the oldest band. These exposure-normalized comparisons reduce the influence of the number of individuals present, but still combine differences within each age band and do not establish mediation. The corresponding death components for the four age bands were +4.54, -1.91, -1.29 and +1.49; each paired interval includes zero.

## Food and policy lineages

For the same 48-founder, fixed-age threshold comparison, total grass consumption contributed -123.93 units to the change in the food-related mixture contrast (95% interval -195.90 to -51.96). The corresponding exposure contrast was -472.01 agent-ticks (-727.60 to -216.41). The average difference in grass intake per 1,000 agent-ticks was +0.18 (-0.62 to 0.98). Total intake depends on how many agents are present and for how long; these summaries do not prove that a per-agent foraging change caused the population pattern. Control rates pool the eight control populations' food and exposure before taking their ratio. By age, the same threshold change in the food-related intake-rate contrast was -6.21 grass units per 1,000 agent-ticks (-9.63 to -2.79) under age 50 and +3.81 (0.75 to 6.88) at age 150 or older. These are exploratory age-stratified contrasts; they do not establish why intake or reproduction differed.

Policy labels identify the eight selected source policies within each seed and are not the same policies across seeds. In the 48-founder, threshold-120, fixed-age mixtures, the most prolific policy accounted for an average 43.9% of cumulative births under limited food and 37.4% under original food. The corresponding shares of cumulative grass intake were 43.8% and 39.2%. These are descriptive shares of the policy that ranks highest within each population, selected after observing the run; the identity of that policy can differ between conditions.

Across the 16 factorial conditions, the policy with the most cumulative births also had the most cumulative grass intake in 95–100 of the 100 seed blocks per condition, with rare ties resolved by the first index. A more abundant or longer-lived lineage has more opportunity to accumulate both food and births. This association is therefore not evidence that greater foraging ability caused greater reproduction. The full policy-by-age records are archived on Totoro for further analysis; their path and checksum are recorded with the tracked summaries.

All age-band, lineage and demographic comparisons are exploratory follow-ups to the previously observed factorial result. Their intervals are not adjusted for the many comparisons. The within-age rates may be undefined if exposure is zero; in this dataset all 100 paired values were defined for every reported rate.

## Validation and scope

The observer measured grass bites in an isolated research copy of the Julia kernel, with no package API change. Its tick-level food sums matched grass depletion, event counts matched kernel birth and death counters, and occupancy was checked every tick. All 288,000 50-tick records reproduced the preceding factorial's population, births, deaths, food and exposure, including its extinction. An independent audit checked policy and age contributions and reconstructed 648 summary means; a separate check reproduced all 18 original population factorial contrasts and intervals. The dominance calculation was independently reconstructed from 32,000 mixture windows, and all pooled-control and mixture rates were reconstructed from the raw windows.

The 100 source panels and 14,400 simulations are the same trajectories as the preceding study, not an independent replication. The method tracks clonal haploid policy identities with mutation disabled during the assay; source panels differ by seed. Food treatments change both initial grass and regrowth. The observer measures grass consumption in this setting and does not claim coverage of additional resource layers. The full replay took 414.79 seconds on Totoro with 24 workers, four Julia threads and one BLAS thread each.
