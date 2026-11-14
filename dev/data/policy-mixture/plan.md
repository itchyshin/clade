# Equal-density policy mixture experiment

Approved scope: Shinichi requested the balanced mixture experiment on Totoro
on 14 November 2026, following the corrected performance campaign.

## Question and estimand

For each corrected source population, uniformly sample K=8 endpoint policies
without replacement. Let Ymix be performance of N=48 founders, six copies of
each sampled policy, and Yj be performance of 48 copies of policy j alone.
The paired mixing effect is D=Ymix-(Y 1+...+Y 8)/8. Average D over 100 independent
source seed blocks, separately within ploidy 1/2 and source mutation SD 0/.05/.20.
The experimental unit is the source seed block, not a policy or individual.
Equal policy weights match the initial marginal choice-probability function
exactly when controls are averaged, for every sensory context. Individual
control worlds need not have the same mean policy as the mixture.

## Intervention and controls

Use only600 corrected endpoint archives from source b982e9739c1064224ca49f77ff56d06ec8e0c7c4,
verified against their recorded file checksums. Restore policy mu and sigma.5
in standardized founders with body/metabolism 1, age 50, energy 70, unique random
positions and identical 30 x 30 grass worlds. Across the nine assemblages in a
block, all non-policy state and initial RNG state are exactly equal. Assign
policy copies to positions with an independent frozen random permutation.
Initial positions, food and runtime RNG are shared across source mutation
regimes within a ploidy/seed as well. Same RNG seed is variance pairing, not
a promise that divergent populations consume identical subsequent random draws.

Represent each expressed policy as a haploid allele or homozygous diploid
pair, retaining fixed ploidy. Source archives contain brains, not original
whole genotypes; this is a policy transplant, not a replay of original genomes.
All scalar traits are shared and mutation SD is 0 during transplant runs.
No learning or optional evolved traits are enabled. Normal canonical dynamics
apply; the observer only reads state and consumes no simulation randomness.

## Outcomes fixed before pilot

1. Primary foraging phase:50 ticks, reproduction disabled through min_repro_age.
   N=48 must remain constant, no deaths, no births. The worst-case fixed
   movement+brain cost leaves a positive energy balance from energy 70 over
   50 ticks; age 100 remains below max_age 200. Reject equal-density interpretation
   if any counter breaks. Measure food, actual agent-phase net energy, and
   uncapped energy return computed from food and action costs, all per agent tick.
   Record clipping loss separately. Primary practical margins: +/-5% for food
   and +/-0.05 energy units per agent tick for net energy (absolute because a
   zero or negative baseline makes relative energy changes misleading).
2. Secondary demographic phase:300 ticks with canonical reproduction. Measure
   birth and death counts, agent-time yields, final population, founder focal
   offspring count, and survival/recruit yield for births through tick 200 with
   100 ticks follow-up. Allseed absolute outcomes retained. Full-block viability
   guard requires mixture and all 8 controls viable for conditional rate contrasts;
   primary all-block contrasts remain visible to avoid survivor selection.
   Demographic results include density feedback and diploid recombination,
   rather than a fixed-policy pure foraging effect or lifetime fitness estimate.

Compute the balanced mean of per-world rates, not pooled counts/exposure.
Report seed-level mean difference, MCSE, t 95% interval and paired-seed
bootstrap interval (2000 resamples) for relative mean changes where defined.
The primary direct test is mixture versus its balanced controls within each
source regime. Any contrast across source mutation regimes is secondary.
Use whole intervals to distinguish practical benefit/harm/small/uncertain.
No multiplicity-adjusted universal adaptation claim.

## Acceptance and execution

Target Totoro, capped four isolated Julia processes of 4 threads each and one
BLAS thread each. Pilot one seed across all 6 cells and both phases=108 runs;
initial estimate<5 minutes from the preceding 600 x 1000 tick campaign (~6.5 min).
Measure pilot before setting full estimate. Full design is 10800 runs across
600 blocks, not 600 independent monoculture controls. Archive source, exact
commands, timings, raw source/selection/initialization checksums and CSVs.
Fail closed on duplicate/missing keys, state mismatch, ploidy/sigma drift,
food/energy/population balances, cohort censoring and primary density change.

Tiny deterministic tests cover exact copy counts, identical-policy null,
independent physical initialization, founder ploidy and genome/brain equality,
source brain immutability, observer-on/off replay, extinction/censoring and
negative malformed cases. Full relevant Julia suite precedes production.
Independent design and final raw-data review, same-machine first-block replay,
actual R viability_report, a standalone figure and an after-task report close
this task. No public defaults, API or kernel phase ordering change is planned.

## Pilot receipt and full-run estimate

Pilot 108 runs completed in 28.10 seconds, peak 535964 KiB, exit 0. All 54 primary
foraging worlds are viable and retain 48 agents. Secondary demographic worlds:
48 viable,5 weak,1 crashed. No design retuning or dropped controls follows.
Full-block viability sensitivity will therefore have explicit selected
counts; all-block absolute/defined-rate results remain available.
Analyzer corrected strict integer-versus-double comparison and lowercase
Julia boolean parsing; all pilot raw/energy/cohort checks pass afterward.
Full estimate 20 minutes before launch, bounded by wrapper deadline 1200 sec.
Four isolated 25-seed shards,16 Julia threads maximum and 4 BLAS threads total.
