# Matched policy-frequency intervention

Test whether restoring an even founder-policy mix at tick 600 changes the
subsequent population reversal. Use the previous original-food, fixed-age,
haploid populations and the same 100 source seed blocks. Each starts with
eight founder policies and follows the canonical loop to tick 600.

Run three matched arms per seed: untouched natural evolution; a sham that
randomly reassigns the current policy multiset across individuals, preserving
its evolved frequencies; and a treatment using the same random reassignment
procedure but restoring the eight founder policies to equal counts, within
one individual. The treatment can reintroduce founder policies that have
already disappeared. Both shuffled arms reset the brain sampling cache and
randomize policy assignment independently of the simulation RNG. They may
change different numbers of individuals; record those counts. This tests
policy-frequency restoration plus its associated policy reassignment, not an
unqualified effect of genetic diversity or a natural evolutionary process.

The isolated research copy adds an intervention callback after the tick-600
observation. At intervention, a digest verifies identical grass, agent map,
RNG and every agent field except policy brain and genome, including population
size, age, energy and position. Source policy means and shared scalar traits
are preserved. This controls density and age structure exactly at the
intervention; they can change afterward as outcomes of the intervention.
The sham also disrupts policy-to-individual associations, helping control for
that disruption, though the numbers of switches may differ. A no-op natural
arm checks the hook and matches the previous full trajectory.

Primary outcome is balanced minus sham population at tick 1,000 across 100
matched seed blocks, reported as mean difference and paired t and bootstrap
intervals. The prior mean of eight monocultures supplies an unchanged benchmark
for whether each arm remains above or below its control. Track populations,
policy frequencies and grass at each 50-tick checkpoint; retain extinctions.
Report the number of restored absent policies, switches and the sham-versus-
untouched contrast. Density and age structure beyond tick 600 are mediators,
not held-fixed design factors, so no claim of an effect at fixed post-
intervention density is supported.

The one-seed pilot verifies identical pre/post physical-state hashes, exact
counts, prior replay through tick 600 and the full natural trajectory. A
second pilot confirms the extinction-output safeguard leaves all 60 pilot
rows unchanged. The 300-run campaign uses eight isolated Totoro processes,
four Julia threads and one BLAS thread each, with an eight-minute deadline.
The research hook, data, source hashes and exact commands will be archived.
