# No equal-density foraging gain; a demographic mixing effect

Mixing different policies produces no material improvement in short-term food
intake or net energy in this world. Over 300 ticks, mixtures made from the
high-mutation haploid policies do support larger populations than their
balanced single-policy benchmark. That longer-term response includes changing
policy frequencies and density; it does not establish a general fitness benefit.

## The controlled foraging test

The full experiment contains 10,800 runs:600 source policy sets, each with one
mixture and eight monocultures in each of two phases. Every group starts with
48 agents. All 5,400 foraging groups remain viable and retain exactly 48 agents
for all 50 ticks. The mixture contains six copies of each of eight sampled
policies. The benchmark averages eight complete monocultures equally, matching
the mixture's initial policy composition. Each cell has 100 seed-block contrasts.

| Source mutation SD | Haploid food change | Diploid food change |
|---|---:|---:|
| 0 | +0.40% (-0.16 to +0.94) | -0.11% (-0.66 to +0.44) |
| .05 | +0.26% (-0.23 to +0.79) | -0.18% (-0.78 to +0.42) |
| .20 | -0.24% (-0.69 to +0.18) | -0.08% (-0.60 to +0.45) |

Values are mixture versus the mean of all eight monocultures, with 95%paired-
seed bootstrap intervals. Every interval lies well within the prespecified
+/-5% practical margin. This supports small effects at this scale, rather than
an absence-of-significance argument for equality.

Actual net-energy differences are also small. For high-mutation source
policies, the haploid difference is -.00169 energy units per agent tick
(95%interval -.00471 to +.00133); the diploid difference is -.00228
(-.00663 to +.00206). Across all six cells, whole intervals lie within the
prespecified +/-.05 energy-unit margin and include zero. These are seed-level
t intervals. A 4,000 resample bootstrap sensitivity also gives intervals
including zero for all twelve primary absolute food/energy contrasts.

The energy ceiling is active, so actual net energy cannot reveal unused
surplus above that ceiling. Clipping removes about 46% of
calculated food-minus-cost return on average across primary worlds. The
saved uncapped food-minus-cost return provides an accounting check: high-mutation differences are -.01483 haploid and -.00535
diploid, with 95%intervals -.04233 to +.01266 and -.03835 to +.02766.
It is computed from recorded actions; behaviour without a ceiling remains
untested. Those intervals also provide no clear mixing benefit. This conclusion concerns the
specified short assay, not every possible form of complementarity.

## Demographic consequences over 300 ticks

The secondary phase allows reproduction and death, with mutation disabled.
Initial density is matched; subsequent density and policy frequencies can
change. Haploids clone parental policies. Diploids can recombine them, because
the transplant represents each source mean as identical starting alleles.

For policies from source mutation SD .20:

| Outcome | Haploid mixing effect | Diploid mixing effect |
|---|---:|---:|
| Births per agent time | +3.57% (2.99 to 4.19) | +0.97% (0.26 to 1.64) |
| Final population size | +22.07% (17.99 to 26.26) | +3.99% (0.50 to 7.69) |
| Survival 100 ticks after birth | -1.82 points (-2.27 to -1.37) | -0.42 points (-0.92 to +0.07) |
| Surviving recruits per aligned agent time | -0.02% (-0.53 to +0.46) | +0.90% (0.46 to 1.37) |

Percent changes use paired-seed bootstrap intervals; survival changes are
percentage points with seed-level t intervals. All 100 blocks enter these
contrasts, including weak and crashed controls. Haploid endpoint means are
56.85 agents in mixtures versus 46.57 in balanced controls; diploid means are
47.50 versus 45.68. Birth yield covers 300 ticks, whereas survival/recruit yield
uses births through tick 200 and 100 ticks of follow-up, with exposure aligned
to that birth window. Their relative contrasts need not multiply together.

The high-mutation haploid endpoint advantage persists among the 77 blocks in
which all nine demographic groups are viable: +20.85% (16.18 to 25.44).
The corresponding diploid sensitivity has 97 blocks and gives+4.01%
(0.37 to 7.56). These are selected sensitivities, not replacements for the
all-block estimates. Across all six cells, full-nine viable block counts are
30/31/77 for haploids and 89/87/97 for diploids at source SD 0/.05/.20.

## Interpretation and limits

The evidence supports a mixing effect relative to the balanced monoculture
benchmark in the demographic phase, especially for high-mutation haploid
policies. It does not show that mixed groups immediately forage more
efficiently at equal density. Selection among policies, changing frequencies
and density feedback can produce a demographic advantage without improving
average short-term foraging. The experiment does not distinguish selection
from complementary resource use or show that mixtures outperform the best
single policy.

Founder age is synchronized at 50, and final population is measured at one
300 tick endpoint. Cohort waves may affect that endpoint; it is not a long-run
population growth or persistence estimate. Offspring survival declines in
high-mutation haploid mixtures, and recruit yield per aligned agent time does
not clearly rise. More endpoint agents alone therefore do not establish
higher lifetime fitness. Secondary intervals are exploratory and unadjusted.

Source mutation labels describe where policies evolved; every transplant
has mutation 0 and fixed exploration sigma.5. Synthetic genotypes preserve
initial policy means, not original genetic diversity or linked traits.
The causal intervention is mixing this sampled set relative to its balanced
uniform-group benchmark, in this world. Generality across food regimes,
densities, policy-set sizes and longer time spans remains untested.
