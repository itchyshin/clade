# Independent food-by-age replication

The new-seed experiment reproduces the earlier food-dependent pattern. Under the original food regime, mixtures had fewer individuals than the mean of the eight single-policy controls at both ticks 800 and 1,000. Under moderate food limitation, mixtures were below their controls at tick 800 but above them at tick 1,000. The reversal therefore depends on the environmental regime and the time measured in this experiment.

| Food and founder ages | Tick 800 | Tick 1,000 | Change from 800 to 1,000 |
| --- | ---: | ---: | ---: |
| Original, fixed | -1.51 (-2.90, -0.11) | -3.94 (-5.08, -2.80) | -2.44 (-4.38, -0.49) |
| Original, staggered | -2.89 (-4.26, -1.52) | -4.33 (-5.53, -3.13) | -1.44 (-3.47, 0.59) |
| Limited, fixed | -3.91 (-5.25, -2.57) | 1.66 (0.65, 2.67) | 5.57 (3.72, 7.42) |
| Limited, staggered | -4.94 (-6.25, -3.63) | 2.16 (1.13, 3.19) | 7.10 (5.28, 8.92) |

Entries are the mixture population minus the equal mean of eight controls, in individuals, followed by 95% paired-seed t intervals. The final column is the paired change in that difference. The four conditions and two endpoints were specified before the pilot; intervals are not multiplicity-adjusted and should not be interpreted as simultaneous confirmatory tests. Bootstrap sensitivity intervals are retained in `results/summary.csv`.

At tick 1,000, changing from original to moderate food increased the mixture contrast by 5.60 individuals (95% interval 4.00 to 7.20) with fixed ages, and 6.49 (4.90 to 8.07) with staggered ages. At tick 800 the corresponding differences were -2.41 and -2.05. The age effects at tick 1,000 were -0.39 (-2.03 to 1.25) in original food and 0.50 (-0.91 to 1.91) under limitation. These intervals do not establish that age has no effect.

The preceding 100-seed experiment estimated tick-1,000 contrasts of -4.42 and -3.47 under original food, and 2.09 and 2.18 under moderate food, for fixed and staggered ages respectively. The present results use new source seeds and preserve the direction and approximate magnitude of those four results. This compares whole mixtures with monocultures; it does not directly replicate the earlier within-population policy-frequency intervention.

## Design and viability

Each of 100 new, independent source seed blocks supplied eight distinct policy means, all with measurable deterministic disagreement across the 48-context common garden. For each block, one mixture and eight monocultures began with 48 individuals in each of four food-by-age worlds. All 3,600 outcomes were retained. The first five blocks were piloted and included in the final analysis, as planned. The mean ages in the staggered treatment are 48.5 versus 50 in the fixed treatment. The food contrast changes both initial grass availability and regrowth; the individual effects of those two factors are not separated.

Endpoint viability does not imply continuous stability. All 100 source populations and 3,595 of 3,600 assay populations were viable at the endpoint under `viability_report()`. Three assay populations were weak and two were extinct at the endpoint. Yet 78 source populations fell below 20 individuals during their training history, with a median minimum of 15; 2,929 assay populations fell below 20 during the experiment. These minima are recorded every tick. The source bottlenecks may restrict policy ancestry, and the assay bottlenecks limit generalization to continuously stable populations. Restricting the moderate-food comparison to blocks where all nine groups were viable at the endpoint gives tick-1,000 estimates 1.42 for fixed age (98 blocks) and 1.96 for staggered age (97 blocks); this is a sensitivity analysis rather than the primary comparison.

All policies come from one haploid clonal simulation setting with founder mutation SD .05, source mutation SD .20 and assay mutation disabled. The comparison does not establish complementarity or identify which birth, death or behavioural mechanism generates the contrasts. Other policy populations, food regimes, ages and ploidies remain outside this replication.

## Validation

The pilot comprised five source blocks and 180 assay runs. Every source and assay was viable at the endpoint, and an independent audit checked matching, 3,600 interval ledgers and all reported summary means. The full result includes 100 source simulations, 3,600 assay runs and 72,000 windows. The independent audit reconstructed every summary mean and checked demographic ledgers and matched physical hashes. Fourteen initialization assertions checked age schedules, positions, grass, RNG, policies and ploidy. All 100 source-state file checksums passed on Totoro. The 95-block continuation took 262.11 seconds, following a 36.01-second pilot. Source and data hashes, code and raw outcomes are retained in `results/` and on Totoro.
