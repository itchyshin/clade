# Small performance gains with costs

The corrected 600-run experiment gives a mixed answer: higher mutation produces
small increases in food intake and birth yield, alongside lower offspring
survival and smaller final populations. It does not establish that additional
genetic or behavioural variation improves overall fitness.

## Main contrasts

These compare mutation SD .20 with 0 within each fixed ploidy. Values in
parentheses are 95% intervals across 100 matched viable seed pairs. Percentage
changes are ratios of cell mean rates with paired-seed bootstrap intervals;
survival changes are percentage points with seed-level t intervals.

| Outcome | Haploid | Diploid |
|---|---:|---:|
| Standardized food intake | +1.86% (1.06 to 2.64) | +0.43% (0.02 to 0.85) |
| Food per agent tick, ticks 501:1000 | +1.98% (1.78 to 2.18) | +1.63% (1.37 to 1.89) |
| Births per agent time, ticks 501:1000 | +0.83% (0.23 to 1.44) | +2.62% (1.86 to 3.40) |
| Survival to 100 ticks after birth | -2.06 points (-2.64 to -1.49) | -2.83 points (-3.49 to -2.16) |
| Surviving recruits per aligned agent time | +3.36% (2.37 to 4.40) | +1.14% (0.44 to 1.86) |
| Final population size | -6.88% (-7.95 to -5.80) | -3.17% (-4.33 to -2.05) |

Recruit yield and birth yield use different, explicitly aligned windows:
recruits require births through tick 900, while late birth yield includes
births through tick 1,000. Their relative contrasts need not multiply to the
survival contrast. These are population rates, not per-parent lifetime output.

All standardized food and late birth-yield intervals lie inside the
prespecified +/-5% practical margin. Thus the primary effects are small on
that scale; this conclusion uses the whole interval, not merely failure to
cross a benefit threshold. Mutation SD .05 gives near-zero standardized food
changes and late birth changes of -0.22% in haploids and +0.67% in diploids,
with both birth intervals including zero.

## Food gain does not imply energy gain

In the standardized assay, high mutation lowers net energy by .0365 units per
trial in haploids (95% interval -.0466 to -.0264) and .0388 in diploids
(-.0447 to -.0329). More movement can consume more food while costing more
energy. This assay uses the kernel's actual food cap and movement, idle and
brain costs. Net energy includes the entire agent phase, not reproduction or
whole-life energy balance. The uniform-choice reference is .25 grass per
trial and approximately -.032 energy units for this brain size.

In interacting populations, late net energy changes by -.00859 units per
agent tick in haploids (-.01246 to -.00472) and +.00223 in diploids
(-.00260 to +.00706). The diploid interval includes zero. Density and altered
population composition remain part of these realized ecological responses.
No late ticks reach the configured population cap in any run.

## Behavioural differences persist after the fix

Between-individual squared policy distance B rises from .00057 to .13637 in haploids
and .00045 to .10385 in diploids at mutation SD .20. B is half the squared distance between individuals' choice-probability
vectors, averaged across pairs and contexts. Repeated-choice disagreement
within individuals falls from .79920 to .62516 and .79943 to .67886,
respectively. These are corrected-source estimates from the same endpoint
brains used for the performance assays. The large behavioural change therefore
does not translate into a comparably large performance gain in this world.

## What this establishes and what to test next

The manipulation changes the mutation regime, which changes both the spread
and composition of inherited brain weights. It does not isolate the causal
benefit of heterogeneity itself. Endpoint selection, age structure and density
can affect population outcomes. All populations are viable, but that is a
guard against collapse, not evidence of adaptation. Intervals describe
Monte Carlo uncertainty in this specified world, without correction for the
many exploratory secondary outcomes or extrapolation to other environments.

The next experiment should transplant equal-sized, age-standardized groups
of endpoint brains into the same resource worlds, comparing their full
mixture with replicated individual policies. Match ploidy, initial energy,
exploration and food supply, disable new mutation during the short assay,
and measure net energy plus offspring surviving to a fixed age. That would
test effects of policy mixing at matched starting density. Separating those
effects from mean-policy changes requires a balanced comparator, with single
policies sampled according to their weights in the original mixture and
replicated enough to match the initial marginal policy in expectation.
This experiment remains a proposal.
