# Mutation changes individual action preferences at fixed ploidy

Mutation produced large differences between individuals' action preferences
in this model, even with ploidy and exploration controlled. All 600 runs
passed viability_report, retaining all 100 paired seeds for every contrast.
The result describes endpoint action policies under shared conditions.
Ecological benefits and personality differences need separate tests.

## Size of the behavioural difference

Each individual faced the same 48 combinations of energy, age, grass and
neighbour occupancy. Repeated sampled-weight trials estimated its
probabilities of choosing four movements or staying. Exploration sigma
remained .5 in every treatment. Initial states matched exactly across
mutation treatments within each ploidy and seed block.

The table shows RMS differences between individuals' per-action choice
probabilities, averaged over contexts and pairs, in percentage points.
These values transform the cell mean policy-distance B as sqrt(2B/5).
They are not percentages of individuals that changed behaviour.

| Fixed ploidy | Mutation SD 0 | Mutation SD .05 | Mutation SD .20 |
| --- | ---: | ---: | ---: |
| Haploid | 1.70 | 8.63 | 29.34 |
| Diploid, selfing fallback | 1.40 | 6.31 | 24.67 |

The primary paired increase in B at mutation SD .20 versus zero was
.2146 in haploids (95% Monte Carlo interval .2073 to .2218) and .1517 in
diploids (.1480 to .1554). Both intervals exceed the prespecified practical
margin .00625. Mutation SD .05 also exceeds that margin: .01788 (.01707
to .01870) in haploids and .00946 (.00901 to .00990) in diploids.
Each estimate uses 100 paired seed blocks. Agents and contexts are not
counted as independent experimental replicates.

The margin is an assay convention. A B value of .00625 corresponds to
five-percentage-point RMS differences when starting from zero. Its use
for an increase in B does not imply a five-point increase in RMS at every
baseline. The continuous effects and intervals remain the main evidence;
no empirical ecological importance threshold has been established.

## Individual policies and population entropy tell different stories

Independent repeated choices by the same individual disagreed about
79.9% of the time without mutation. At mutation SD .20, disagreement fell
to 56.4% in haploids and 63.0% in diploids. Individuals therefore had more
concentrated and distinct choice preferences, despite the Gaussian
weight-noise scale remaining unchanged. The assay uses independent repeated choices. Consecutive-action
repeatability requires a separate test.

Realized population action entropy over the last 100 ticks stayed high:
about 1.57 nats without mutation and 1.53 with high mutation, against a
five-action maximum of log(5)=1.609. Such aggregate entropy cannot separate
similar individuals making random choices from individuals with different
preferences. It also depends on encountered contexts and sample size.
The standardized individual-policy assay supplies that missing comparison.

## Behavioural differences do not establish better performance

All populations remained viable at tick 1000, with at least 36 agents.
The high-mutation treatment nevertheless left fewer agents on average:
5.37 fewer in haploids (paired95% interval 3.62 to 7.12 fewer) and 3.24
fewer in diploids (1.69 to 4.79 fewer). This study does not identify a
fitness mechanism or establish that more policy diversity is adaptive.

Ploidy was fixed by existing settings: haploid reproduction or diploid
reproduction with self-fertilization when no mate was found. Because these
regimes also differ in reproduction and initial expressed-weight variance,
comparisons between their absolute levels are not pure copy-number effects.
The supported conclusions are mutation contrasts within each regime.
How the scalar genetic-distance metric mediates behavioural changes
remains untested.

## Numerical and source checks

Two independent noise banks estimate between-agent squared differences
without finite-draw inflation. Noise is shared across agents and paired
mutation treatments; different seed blocks receive independent assay
banks. Negative finite-draw estimates are retained. Cloned brains give
exactly zero between-agent signal, and constructed opposite-choice brains
give the known maximum of one. Actual kernel ANN forward and argmax
semantics are reused without changing simulation RNG or brain state.

All four prespecified precision checks passed on the same first ten
viable paired seeds, using 256 rather than 64 repetitions per bank.
The largest mean change in a mutation contrast was .000643 in B, with
largest numerical MCSE .000447, each below the .001563 precision limit.
Every interval remained above the practical margin. Independent raw-data
reconstruction and an exact separate-process replay support reproducibility.

Totoro ran the 600 simulations and primary assays in 6:16.18, followed by
44.87 seconds for reassay. Peak memory was about 456 MiB. Julia was pinned
to 1.10.0 and simulation source to 7a2d78b9fa4efbd6f6ab5553f00f0422491ffa80.
Results concern one world, architecture, horizon and frozen context panel.

The next scientific step is to assess foraging and reproductive performance
under the same controls, to test the consequences of these preferences.
