# Mutation input and the founder signature

The matched-start experiment shows that subsequent mutation can generate
substantial inherited-weight diversity from identical founder weights.
In the low-cost world, starting variation leaves a much stronger endpoint
signature when mutation is absent. This separates two mechanisms that the preceding 500-run study
could not separate because mutation_sd controlled both.

## Primary comparison: fixed exploration, low movement cost

Every cell has 100 seeds, all reaching tick 1000 with at least 31 agents.
Every paired endpoint diversity comparison therefore retains all 100 seeds.

| Founder weight SD | Initial D | Final D, mutation SD 0 | Final D, mutation SD .05 | Final D, mutation SD .20 |
| --- | ---: | ---: | ---: | ---: |
| 0 | 0 | 0 | .2340 | .9274 |
| .05 | .0499 | .0551 | .2397 | .9247 |
| .20 | .1995 | .2157 | .3203 | .9505 |

D is the exact mean pairwise RMS distance in expressed inherited weights.
Values are cell means, not fractions of ancestral material.

The paired founder effect, F=.20 minus F=0, falls from .2157 without
mutation (95% Monte Carlo interval .2134 to .2181), to .0863 with mutation
SD .05 (.0827 to .0899), and .0230 with mutation SD .20 (.0113 to .0348).
The predeclared four-cell interaction is -.1927 (-.2048 to -.1805).
These intervals describe Monte Carlo variation across paired seeds.

Mutation therefore attenuates the founder-spread signature in this metric
by the endpoint. The metric is nonlinear, so its changes cannot be divided
into additive percentages due to founders and mutation. Nor do the results
show that original alleles disappeared. With no mutation, segregation,
drift and changing ploidy can still change expressed-weight distances.
Final populations here average roughly two-thirds haploid.

## Diversity and population performance answer different questions

With fixed exploration and low movement cost, mutation SD .20 produces
higher diversity but lowers
mean final population size by approximately 3 to 6 agents relative to zero
mutation, depending on founder spread. The paired intervals exclude zero.
That does not establish a particular fitness mechanism, and higher D is
not evidence of adaptation or a benefit to population persistence.

The high movement-cost world leaves much smaller populations. Its
conditional diversity contrasts must be read alongside survival,
singleton frequency and viability, with their eligible denominators.
There is no claim of an optimal mutation setting or environment.

## Costly world and exploration sensitivity

All 900 fixed-exploration, low-cost runs pass viability_report. Under the
usual heterozygosity-based exploration rule, 899 of 900 low-cost runs are
viable and one is weak; all survive. The founder attenuation pattern is
similar: the four-cell interaction is -.1861 (95% Monte Carlo interval
-.1975 to -.1747), using all 100 seed blocks. Changing founder spread also
changes starting exploration in this sensitivity arm, so it is not the
primary isolated-weight comparison.

At high movement cost, only 0 of 900 fixed-exploration runs and 2 of 900
usual-exploration runs are viable. Survival ranges from 79 to 94 of 100
seeds per cell, with 0 to 3 singleton populations. Most populations that
survive still fail the viability guard. These outcomes remain in the
all-seed population summaries.

High mutation raises endpoint diversity among co-eligible high-cost pairs:
for mutation SD .20 versus zero, fixed-exploration differences range
from .475 to .592, using 76 to 80 of 100 pairs. Every corresponding
both-viable contrast has zero eligible pairs. These are diagnostic
selected-population results, not a biological validation result.

The high-cost four-cell interaction is -.1348 (-.2289 to -.0406; n=64)
with fixed exploration, but .0239 (-.0667 to .1145; n=57) with the usual
rule. Therefore the clear low-cost founder attenuation result cannot be
generalized to the costly world under both exploration modes.

## Execution and reproducibility

Totoro completed all 3600 runs in 16 minutes 25.48 seconds, with peak memory
429372 KiB (about 419 MiB), using Julia 1.10.0 and source 07bc494.
All 1200 founder-state blocks matched exactly across mutation treatments.
Every measurable zero-founder/zero-mutation endpoint stayed at zero.
A separate-process replay of seed 10001 across all 36 conditions reproduced
every field in 36 run rows and 396 trajectory rows exactly on the same
machine and Julia version. Compressed raw outputs, contrasts, session
information, checksums and timings accompany this report.

## What to do next

Use independent founder and offspring-mutation controls in future genetic
diversity sweeps. For a biological follow-up, measure whether the extra
weight variation produces meaningful behavioural differences in viable
populations, while controlling ploidy. If the question is how much founder
material persists, explicit ancestry or allele tracking is needed;
pairwise distances cannot supply that decomposition.
