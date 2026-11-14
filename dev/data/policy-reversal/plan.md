# Why does the policy-mixture advantage reverse?

Trace the original food, fixed-age, haploid, high-mutation source condition
for the same 100 seed blocks and nine groups as the factorial study. Follow
all eight founder policy identities through haploid clonal reproduction with
new mutation disabled. At each 50-tick checkpoint record policy counts,
births, deaths and agent-time exposure, total population, available grass,
food consumed and policy-specific total energy. Identity is verified against
the exact inherited brain means at every birth and checkpoint.

A passive observer must reproduce all prior 50-tick population, birth, death
and exposure windows. Use the original eight monocultures as the matched
benchmark. Describe policy-frequency concentration, the number of surviving
policies, population density (agents per 900 cells), grass per cell and
mixture-minus-control population through time. Each seed is one independent
block. No source agent or stochastic draw is treated as a replicate.

At each seed and tick, denote mixture frequency by f_j and the population of
monoculture j by M_j. Decompose mixture advantage algebraically as
N_mix - mean(M_j) = [sum(f_j M_j) - mean(M_j)] +
[N_mix - sum(f_j M_j)]. The first term summarizes association between
surviving mixture composition and contemporaneous monoculture population;
the second is the remaining discrepancy. This is an accounting identity,
not a causal decomposition: frequencies and monocultures are outcomes of
separate interacting populations. A policy's labels are exact haploid clones;
this identity does not extend unchanged to diploid recombination.

Test the pre-run hypotheses that founder-policy concentration increases and
that density and resource levels change around the reversal. These are
observational descriptions; they do not prove selection or density caused
the reversal. Use paired seed-level 95% intervals and report the counts of
extinct mixtures. If the trace indicates a feasible causal intervention,
design it separately, without altering the passive record or treating an
artificial policy-frequency reset as natural evolution.

The pilot reproduces 180 prior windows and their counts, births, deaths and
exposures. The full 900-run replay uses eight isolated processes, each four
Julia threads and one BLAS thread, with an eight-minute time bound. A seed
is retained even if its population collapses. Source, trace data, checksums,
independent reconstruction and all incomplete paths must remain inspectable.

## Matched resource intervention

The original trace showed lower available grass and large policy-frequency
shifts as the advantage reversed. Test environmental sensitivity by doubling
grass regrowth from .05 to .10 while retaining the same starting grass map,
positions, policies and seeds. Repeat all 100 mixtures and eight controls.
The primary contrast is the seed-paired change in mixture advantage at tick
1,000. This intervention can change both density and policy frequencies, so
it identifies the effect of the changed regrowth regime, not an isolated
within-density effect of food or of policy composition.

The one-seed pilot matched starting physical hashes and reproduced exactly
when capacity instrumentation was added. It encountered the 500-agent cap
for five ticks across nine runs. Record cap ticks and maxima for every full
run; report the proportion of runs and seed blocks exposed, and a cap-free
sensitivity where it exists. Use the actual R viability verdict on final
population, and retain nonviable outcomes in the primary comparison. Pilot
22 seconds; estimate eight minutes for the full eight-worker intervention.

## Pre-reproduction age and energy audit

A separate passive replay records age, energy and the number of agents meeting
energy/age thresholds immediately after the movement-and-feeding phase and
before mortality and reproduction. It also records the number aged at least
150. Threshold-ready is a proxy: age mortality, space and population caps
can still prevent birth. The replay must match every original trace field,
and it must not draw random numbers or change simulation state. Compare
within-seed mixture fractions with the equally weighted monoculture fractions.
This measures age and energy composition; it does not by itself identify a
causal pathway.
