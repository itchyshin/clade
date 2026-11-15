# Reproductive timing in a lower-bottleneck setting

## Main findings

Restricting reproduction before age 50 delayed subsequent births in a clear dose response. It did not produce a consistent dose-dependent change in the population difference between policy mixtures and balanced single-policy controls. These results describe a specific simulated world; they do not establish that age-specific reproduction has no effect on populations in other worlds.

For the mixture with same-age founders and original food, the estimated probability of a first birth within 50 ticks of the first eligible young opportunity fell from 99.9% with no restriction to 84.0% with complete restriction. The paired difference across 100 source seeds was -15.8 percentage points, with a 95% interval from -16.3 to -15.4. This is an estimate of a treatment-world cohort outcome, rather than a paired counterfactual for the same individuals.

| Young opportunities blocked | Birth within 50 ticks | Average births per run |
| --- | ---: | ---: |
| 0% | 99.9% | 1,417 |
| 25% | 99.2% | 1,412 |
| 50% | 98.3% | 1,407 |
| 75% | 96.1% | 1,389 |
| 100% | 84.0% | 1,339 |

Full restriction therefore made timely birth less likely and reduced total births in this setting by 78.1 per run, or 5.5%, on average. The paired 95% interval for the total-birth change was -82.9 to -73.2. A birth outside the 50-tick window is not counted as a timely birth and may still occur later.

At entry, mean parent energy was approximately 83.7 with no restriction and 83.6 with complete restriction. Among parents who gave birth within 50 ticks, average energy immediately before birth was 83.8 without restriction and 118.1 with complete restriction. These are different post-intervention cohorts. Feeding, metabolism, selection into the cohort and other interactions contribute to the energy difference, so it is not an isolated estimate of reproductive costs.

## Mixtures versus controls

The population contrast is the mixture's final population minus the equally weighted mean of eight single-policy controls. At complete restriction, the change in that contrast compared with sham was:

| Founders and food | Change in mixture contrast | Paired 95% interval |
| --- | ---: | ---: |
| Same age, original food | +0.49 | -1.28 to +2.26 |
| Same age, limited food | -1.11 | -2.58 to +0.36 |
| Staggered ages, original food | +0.25 | -1.38 to +1.89 |
| Staggered ages, limited food | +0.57 | -0.91 to +2.04 |

Across all four food and age settings, these complete-block intervals include zero. Intermediate doses did not produce a consistent monotone pattern. One of the 16 dose-by-world comparisons, 75% blocking with staggered ages and limited food, had an unadjusted interval narrowly above zero: +1.58, interval +0.02 to +3.14. The intervals are exploratory and unadjusted for multiple comparisons. Neither an interval containing zero nor the absence of a clear trend proves equivalence.

The current study fixes the reproductive threshold at 80 to obtain a lower-bottleneck world. It cannot directly reproduce or resolve the earlier food-by-threshold interaction, which required thresholds 80 and 120. The food treatments also change initial grass and regrowth together. Initial density, ages and physical conditions were matched across interventions and policies within each world; density, age structure, policy frequencies and random trajectories could diverge afterward.

## Time-to-birth method and checks

Each agent entered the cohort at its first energy-, age- and cap-eligible opportunity while younger than 50, whether the gate blocked that opportunity or not. The no-block sham therefore has a cohort too. We estimated the cumulative incidence of first birth by 50 ticks using the Aalen-Johansen competing-risk estimator, with death before birth as the competing event and the end of simulation as right censoring. A birth on the entry tick has elapsed time zero. The independent units for uncertainty are source seeds; each control policy is weighted equally within a seed.

Across 3,668,870 recorded agent cohorts, no death before first birth occurred within the 50-tick window. There were 6,986 observations censored before 50 ticks. Censoring depends on when a parent enters the simulation window, and the estimator's censoring assumption may not hold if late entrants differ systematically. A sensitivity analysis restricted to entrants with a full 50 ticks available gave 83.9% rather than 84.0% at complete restriction in the same-age, original-food mixture. This is a selected cohort sensitivity, not proof of an unbiased causal estimate.

A five-source pilot passed the preset stability and matching checks: 896 of 900 assays stayed at or above 20 agents, 895 ended viable and none reached the cap. Its 36-run no-block replay exactly matched ten fields from the earlier stable-world study. An independent reconstruction checked 1,936,800 pilot opportunities against the recorded individual cohorts and gate decisions. The final study used 100 disjoint source seeds and 18,000 assays. Of these, 17,954 stayed at or above 20 agents throughout; 17,930 ended viable, 70 ended weak, and none crashed or became extinct. No source or assay touched the 700-agent cap. All 100 source populations stayed above 20, with minima from 44 to 75. Every outcome was retained. This threshold is an operational population-size check, not evidence of stable genetic diversity.

All 100 source panels had eight distinct policies and positive deterministic behavioural disagreement. The audit checked each full cohort's first keyed gate decision, birth/death ordering, population conservation and initial-state matching. An independent `survival::survfit` reconstruction matched 24 pilot and 24 full run/cohort estimates. Source, run, cohort and death records are archived on Totoro, with 500 checked raw-file hashes in `results/raw.sha256`.

## Interpretation

Parents can compensate for restricted early opportunities, but compensation is incomplete within 50 ticks and total births also decline. In this setting, the intervention affected reproductive timing similarly in mixtures and controls, and there is no consistent evidence that it changed the population contrast. Treatment cohorts arise after populations begin diverging, so this analysis is not a natural mediation study. It does not rule out a role for age-specific reproduction at other thresholds, founder densities, species systems or times.
