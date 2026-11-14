# Performance study: reproduction bug pivot

User authorized foraging/reproduction experiments on Totoro with the same
controls. Branch codex/foraging-reproduction, HEAD71e0df8, PR206 draft.
Legacy600 population replay source121b0a4 completed with exact old endpoint
brain parity; raw /tmp/clade-performance-full and Totoro archive
~/sim-archive/clade/2026-11-14-performance-ploidy/full-100. Analysis valid for
that source, but not intended iteroparity. Food assay64/256 precision failed;
independent-brain-noise refinement source71e0df8 has only a six-population
256-draw probe, not a full refinement. No compute job is currently live.

Critical discovery: create_offspring skips reproduced=true and sets it,
with no clearing assignment anywhere. Standard iteroparous agents get one
focal episode/lifetime; mates can still contribute. Clear flags AFTER
kill_dead/remove_dead, before reproduction, preserving next-tick semel
mortality. Independent numerical/scientific reviewer confirmed this.

Next: narrow separate bug-fix branch from main, regressions for successive
iteroparous ticks, same-tick block, failed attempts, semel multi-clutch/death.
Then merge that fix into performance branch, archive corrected endpoint
brains (never compare/assay old brains for corrected populations), pilot
same6 controls, measure viability/runtime, complete corrected performance
and behavioural verification. Preserve all legacy outputs and add warnings.

Existing checks: Julia329 pass before reset fix; live R55 pass; source
observer exact-result parity5 seeds; canonical-death audit2482 birth IDs
in first-seed6 replay. /tmp/clade-performance-replay helper remote archive
replay-1 has raw replay/cohort_truth.csv, not yet fetched/compared locally.
PR205 merged as660a4b8; main R check/coverage/pkgdown green.
