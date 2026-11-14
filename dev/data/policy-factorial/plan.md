# Matched food and founder-age factorial

The objective is to separate how food limitation and staggered founder ages
change the population advantage of mixed behavioural policies. Each seed
block supplies eight policies and nine groups: 48 founders containing six
copies of each policy, plus eight 48-founder monocultures. The benchmark is
the equal mean across the eight controls. Source policies are from the
corrected high-mutation SD .20 campaign; new mutation is disabled.

The factorial crosses fixed age 50 versus ages 25 through 72 with three food
regimes: initial grass probability .50 and regrowth .05; .25 and .025; and
.25 and .0125. The staggered ages have mean 48.5, so the age treatment
changes mean age by 1.5 ticks as well as age spread. The food regime changes
initial availability and regrowth together. It does not isolate those two
components of food limitation. Fixed ploidy groups are analyzed separately.

Within each of 100 source seed blocks, use the same policy panel, positions,
seed and treatment-independent initialization machinery across the six cells.
All populations, including extinct and nonviable populations, are retained.
Every run lasts up to 1,000 ticks and records 50-tick windows. A 108-run pilot
must pass conservation and reproduce the 36 matching earlier staggered cases.

For each seed, define D = mixture final population minus the average final
population across all eight controls. The paired age effect at a food regime
is D(staggered) - D(fixed); the paired food effect within an age treatment
is D(limited) - D(original); the interaction compares those age effects across
food regimes. Use 100 matched blocks for means, t intervals and bootstrap
sensitivity. Repeat on the extinction indicator, with differences in
percentage points. All-nine viability is reported by cell; factorial main
contrasts do not discard blocks with failing controls. Do not infer separate
initial-grass versus regrowth effects, fixed-mean age-variance effects,
lifetime fitness, complementarity or generality beyond these worlds.

A 54-second pilot passed. Eight isolated workers of four Julia threads and one
BLAS thread each are capped below Totoro's 150-core limit. The estimated full
run is 15 minutes; the wrapper terminates its own process groups if that
bound is exceeded. Exact source, the isolated age-treatment patch, raw
outcomes and validation receipts must be archived.

A second food contrast compares .0125 with .025 while holding initial grass
probability at .25. Its age interaction compares the age effects in those two
regrowth regimes. These contrasts isolate the regrowth-rate change within the
reduced-initial-grass setting. A two-seed synthetic fixture, derived by
copying the pilot, exercises the full factorial analyzer and independent mean
reconstruction. It is a computational check and supplies no biological
replication.
