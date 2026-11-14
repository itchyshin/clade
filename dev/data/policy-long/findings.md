# Longer, food-limited policy mixtures

At half the original food-regrowth rate, mixed haploid populations retain a
small advantage at tick 1,000. Under the more severe food shortage, mixtures
have fewer agents on average, but fewer mixtures go extinct. These results
apply to the high-mutation source policies and the two specified food worlds.

Each comparison uses eight sampled policies from one corrected source
population. A mixture starts with six copies of each policy; the benchmark
is the equal mean of eight 48-agent single-policy populations. There are
100 matched seed blocks per ploidy and food level. Founders start at ages
25 through 72, with the same positions, food map and ages in each group of
a block. All runs have 1,000 ticks, mutation SD 0 and fixed exploration .5.
Source mutation SD .20 identifies where the policies evolved.

Both limited-food worlds start with grass on 25% of cells, compared with 50%
in the earlier study. Regrowth rates are .025 and .0125, compared with .05
before. Food supply and founder age were changed together, so this experiment
does not attribute differences from the earlier study to either change alone.
The synthetic diploid starting genotypes are homozygous for each transplanted
policy; subsequent reproduction can recombine policies.

## Population size at tick 1,000

| Food regrowth | Ploidy | Mixture mean | Balanced control mean | Relative difference, 95% interval |
|---|---|---:|---:|---:|
| .025 | Haploid | 63.64 | 61.46 | +3.55% (1.85 to 5.19) |
| .025 | Diploid | 57.65 | 56.74 | +1.60% (-0.35 to 3.40) |
| .0125 | Haploid | 13.85 | 16.80 | -17.54% (-29.70 to -3.64) |
| .0125 | Diploid | 20.47 | 22.89 | -10.58% (-19.58 to -1.44) |

Percentages compare the mean across the 100 mixtures with the mean of the
balanced control means. Intervals use paired seed-block bootstrap resampling.
All 1,800 worlds at regrowth .025 met the actual R viability guard. At .0125,
none of the 100 blocks in either ploidy had all nine groups viable. The table
retains all blocks, including weak, crashed and extinct populations; a
full-nine viable subset cannot be estimated in the more severe world.

## Extinction and time course

At .0125, 18% of haploid mixtures went extinct by tick 1,000, versus an
average of 27.75% of their monoculture controls. The paired difference is
-9.75 percentage points (95% t interval -17.73 to -1.77). For diploids,
the corresponding figures are 6% versus 12.13%, a difference of -6.13 points
(-11.14 to -1.11). These group-level contrasts use the 100 seed blocks as
replicates. Fewer extinctions can coexist with a lower mean population among
all worlds; the two measures answer different questions.

At .025, the haploid mixture difference was +5.79% at tick 300, +1.77% at
600 and +3.55% at 1,000. The interval at tick 600 includes zero. The
population advantage is therefore not uniformly detectable at every measured
time. Diploid differences were +10.04%, +2.80% and +1.60%, respectively,
with the final interval including zero. Intervals and absolute contrasts at
all three times are in results/summary.csv and the figure.

The 3,600 runs completed on Totoro in 270 seconds. An independent raw-table
recalculation checked all 72,000 population windows, exposure and birth/death
balances, and every all-block mean. A separate first-seed driver run exactly
reproduced all 36 run rows and 720 window rows. Forty-eight initialization
assertions checked age, ploidy, genome/brain alignment, unique positions and
matching physical state for both food levels. No claim is made about lifetime
fitness, complementarity, or persistence beyond tick 1,000. The comparison
is against the average of the eight controls, not the best single policy.
