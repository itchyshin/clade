# Matched-founder experiment

## Aim and acceptance

Separate founder weight spread F from subsequent offspring mutation M using
identical starting model states within each exploration/world/F/seed block.
The user authorized execution on Totoro on 14 November 2026. Public defaults
and signatures stay unchanged. A private initializer seam reuses the actual
run_clade loop rather than copying it.

## Design

Two worlds have move_cost 1 and 6, with grass_max 20, min_repro_energy 120,
energy_init 70, a 30 by 30 grid, 50 founders and a 1000-tick horizon. Grass
is stochastic, sense_mode is per_cell, predators and optional evolution,
learning and plasticity are disabled at their defaults.

Cross F in {0, 0.05, 0.20} with M in {0, 0.05, 0.20}. Run both fixed BNN
exploration (sigma=0.5) and default heterozygosity-based exploration.
The primary mechanistic comparison uses fixed exploration. The default
version checks sensitivity and its connection with the preceding study.
There are 36 cells, with independent seed blocks 10001 through 10100,
shared across cells: 3600 runs, not 3600 independent paired replicates.

## Symbolic alignment before execution

For seed s generate reference founder alleles W_ref ~ N(0, 0.05^2), then
set W_0 = (F/0.05) W_ref for both haplotypes. Hold scalar traits, positions,
resources and the post-initialization RNG state fixed across M. Offspring
weights use the canonical inheritance/recombination and add N(0, M^2).
A founder's stored mutation-rate trait stays at the reference value; it is
inactive because mutation_rate_evolution=false. Treatment M is read from
specs after initialization. No initial matching claim is made across F or
exploration modes, which deliberately change inherited/brain state.

| Target | Implementation | Check |
| --- | --- | --- |
| Matched initial model state | Canonicalized hash excluding specs and output buffers | identical across M per block |
| Founder spread | rescaled maternal/paternal weights | exact initial D scales with F |
| Ongoing mutation | treatment specs restored before canonical loop | zero-M and positive-M offspring tests |
| Genetic distance | mean pairwise RMS expressed-weight distance | exact all-pair calculation, NA at N<2 |
| Population quality | exact trace minimum and final population | actual R viability_report, n_init=50 |
| Baseline model | F=M=0.05 | exact returned-state parity with run_clade |

Common seeds guarantee matched starting states, not eventwise matched
randomness after reproduction. In particular, zero mutation skips draws.
Default BNN heterozygosity affects exploration and offspring can change
ploidy; record initial/final sigma summaries and final haploid fraction.

## Outcomes and uncertainty

Save exact D at tick zero and the endpoint, sampled logged D and population
at scheduled times, actual final tick, exact population minimum/time,
mean population across the full horizon, total births and initial hash.
After-termination snapshots and diversity at N<2 are NA. Extinction and
singleton frequencies and final N use all seeds. Diversity summaries
include their eligible denominator. Paired M contrasts use co-survivors
with N>=2, plus a separately labelled both-viable sensitivity analysis;
these are selected-population summaries, not universal causal effects.

Means and paired differences report Monte Carlo SE=SD/sqrt(n) and t-based
95% intervals; proportions report binomial MCSE. At n=100, maximum cell
survival MCSE is 0.05. A paired diversity SD of 0.2 gives MCSE 0.02, so a
0.1 difference exceeds three MCSE. Precision will be reported, not assumed.
Also report paired F=.05/.2 versus zero at fixed M and a predeclared
2x2 difference-in-differences for F=0/.2 and M=0/.2, with four-way
co-eligible denominators. No data-dependent expansion or biological calibration claim is planned.

## Pilot and execution gates

Local known-state tests and canonical baseline parity must pass first.
The zero-founder/zero-mutation control must retain exactly zero inherited
weight diversity whenever measurable. On Totoro, run two seeds per cell
first, inspect every initial match and finite/missing outcomes, measure
runtime, then estimate the full job before launching. Pin Julia 1.10.0,
OPENBLAS_NUM_THREADS=1 and JULIA_NUM_THREADS=4. Stop and re-estimate if a run
exceeds its stated budget. Save the exact code revision, source archive,
commands, timings and checksums under ~/sim-archive/clade/.
