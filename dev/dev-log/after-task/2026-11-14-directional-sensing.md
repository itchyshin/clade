# After Task: Directional sensing and R inspection

## 1. Goal

Resolve #120 by offering inverse-distance directional sensing while
preserving the current default, and make R inspection reflect kernel inputs.

## 2. Implemented

The new sense_mode has per_cell as its unchanged default and weighted_sum
as an option. Each directional grass, occupancy and predator channel sums
its existing cell values divided by distance. The weighted base has eleven
inputs at any radius. Care and signal tails retain their positions.

Final sensory vectors are computed in Julia and returned with the existing
simulation result. sense_env reads those exact snapshots. Older hand-built
lists retain the documented legacy display; weighted sensing requires a
snapshot. Predator lookup now respects bounded grids consistently with
other channels. Invalid modes and nonpositive radii fail explicitly.

## 3a. Decisions and Rejected Alternatives

Keep default behavior rather than changing the biological model for all
existing scenarios. The weighted formula follows the ancestor, but clade
retains its energy, age and bias slots. A complete MATLAB input layout
would require a separate decision. Snapshots describe final state, not a
past stochastic decision.

## 4. Files Touched

R configuration, spec groups, validation, inspector and result conversion;
Julia defaults, sensing, input sizing and result export; focused R and
Julia tests, generated help, NEWS, vision, decisions, check log and report.

## 5. Checks Run

- Julia 1.10.0 full suite: 174 assertions pass, exit 0.
- Live Julia-to-R snapshot tests: 14 pass; spec tests: 2 pass. No skips.
- Portable full R suite: exit 0, no failures or warnings, 644 Julia skips.
- Five seeds at radius two: default progress and agents match the previous
  sensing source exactly, ten equality checks pass.
- devtools::document regenerated help. Default schema has 312 fields.
- git diff --check and after-task structure check pass.

## 6. Tests of the Tests

The absent mode failed the initial R schema tests. Four nonpositive-radius
assertions failed before validation was added. Known directional values,
nonzero care and signal inputs, predator offsets and bounded/toroidal edges
are checked explicitly. Live R tests verify both 19-value per-cell and
11-value weighted vectors at radius two, including normalised energy.

## 7a. Issue Ledger

#120 has implementation and local checks complete; review and merge remain.
The R inspector mismatch and predator boundary discrepancy were found
while tracing the same sensory contract and are included here.

## 8. Consistency Audit

Searched `sense_mode|input_radius|sense_env|_compute_n_inputs` across R,
Julia, tests, help and design. Added the field to both default lists and
.SPEC_GROUPS. The core schema and new inspector contracts are recorded.
Graded predator inputs already contain 1/(d+1), so weighted contributions
are presence/[d(d+1)]; docs state this explicitly.

## 9. What Did Not Go Smoothly

Independent review caught invalid radii, a predator boundary mismatch and
the misleading legacy R inspector. These were corrected and tested. The
app restart preserved all worktrees. Transfer copies remain recoverable
in the original task worktree and a temporary archive.

## 10. Known Residuals

The optional mode allocates an intermediate per-cell vector. No performance
campaign was run. Earlier serialized environments lack exact snapshots.
The legacy R fallback remains an approximation, labelled in help. Final
snapshots cannot replay earlier random brain choices.

## 11. Team Learning

Test inspection helpers against actual returned kernel data. Equal vector
length alone does not establish matching sensory meanings or ordering.

## 12. Cross-Product Coverage

Covered ANN, BNN, random, CTRNN and GRN input dimensions; radius one and
two, weighted/per-cell, predators, care, signals and bounded/toroidal edges.
This task does NOT cover full MATLAB model parity, biological calibration,
large-radius performance or every optional biological module combination.

## Provenance and Documentation

Inverse-distance aggregation follows alifeR R/sense_env.R::dir_sense and
MATLAB alife_matlab/codebase/dirSense.m::weightedSum. Local source was checked
in the sibling alifeR repository. The ancestor includes centre grass and a
different input order. R help contains a weighted-mode example.

Self-review of this technical report: perceived AI-like style 2/10,
moderate confidence; named test cases and explicit limits keep the account
concrete. Science and facts checked against source and logs; references
are repository source paths. Exact-draft completion check NOTASSESSED.
Self-review, 14 November 2026.
