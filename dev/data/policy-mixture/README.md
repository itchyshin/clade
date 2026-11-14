# Does mixing behavioural policies help?

This experiment compares groups of different policies with balanced
single-policy groups at equal density. It follows the corrected
[performance study](../performance-ploidy/README.md). The question is whether
policies perform differently when they live together, beyond their average
performance in uniform groups. Estimates and limits are in [findings.md](findings.md).

Each source population contributes eight endpoint policies sampled uniformly
without replacement. A mixture contains six copies of each policy, giving
48 founders. Its eight controls each contain 48 copies of one sampled policy.
The benchmark is the equally weighted mean of all eight control outcomes.
Thus the starting policy composition is matched across mixture and benchmark.
There are 100 independent source-seed blocks in each of six ploidy/source-
mutation cells. Individuals and monocultures are not independent replicates
of the mixing contrast.

## Two experiments

The primary experiment runs 50 ticks with reproduction disabled and exactly
48 living agents throughout. Food maps, unique starting positions, age 50,
energy 70, scalar traits, exploration sigma.5 and initial RNG state are
identical across all nine groups in a block. Policy copies are randomly
assigned to positions. Food intake and net energy per agent tick measure
the short-term effect of living together at equal density. The energy
ceiling remains active; uncapped food-minus-cost return and clipping loss
are recorded separately.

The secondary experiment runs 300 ticks with canonical reproduction and no
new mutation. It follows offspring born through tick 200 for 100 ticks. Birth,
death and surviving-recruit yields use their aligned agent-time exposures.
Density can change in this phase; diploid offspring can recombine policies.
Its results therefore describe the demographic consequences of mixing
founder policies, including inheritance and density feedback.

The source archives contain brains rather than complete original genotypes.
We transplant their expressed mean weights into haploid alleles or identical
diploid allele pairs, with shared scalar traits. These are synthetic
genotypes preserving the initial policies. The source mutation labels refer
to the evolution that produced the policies; mutation is 0 in every transplant.
The six cells are analyzed separately. No cross-ploidy causal claim follows.

The protocol, outcome scales, practical margins and pilot are recorded in
[plan.md](plan.md). The mixing effect for a seed is the mixture outcome
minus the mean of all eight monocultures. Main estimates retain all blocks;
a sensitivity requires all nine groups viable. A failed control is never
silently removed from the benchmark. Missing rates remain explicit.

## Reproduce

From a source checkout with Julia 1.10.0, and the corrected endpoint archives
recorded in results/run.json:

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 julia +1.10.0 --project=inst/julia \
  inst/julia/scripts/mixture_assay.jl 100 /tmp/clade-mixture-new STATE_DIR
Rscript dev/data/policy-mixture/analyze.R /tmp/clade-mixture-new 100
Rscript dev/data/policy-mixture/plot.R /tmp/clade-mixture-new
```

The output directory must be empty. The recorded full run used four isolated
25-seed processes through run_totoro.py, capped at4Julia threads and1BLAS
thread per process. Simulation uses the canonical Julia loop with a private
initializer and a passive observer. Public defaults, APIs and tick ordering
are unchanged.

Compressed raw tables, summaries, independent review, exact replay, timing
receipts and source/checksum bindings are included in results. To repeat
analysis, decompress all six CSV archives into a fresh directory and run
analyze.R and plot.R there. Full raw outputs, source archive and final review
bundle also remain on Totoro. Source brain files are bound to their original
600-file manifest; the driver records each file's hash and sampled policy
indices. Julia Serialization is bound to the recorded runtime version.
