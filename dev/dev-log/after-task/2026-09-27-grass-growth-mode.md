# After Task: grass_growth_mode toggle and grass_density column

## Goal

Resolve the design question in #167. Clade regrows grass as a lottery
(one unit with probability `grass_rate`); A-life adds `grass_rate` to
every cell each tick. The agreed answer was an opt-in toggle with the
current rule as default, plus a new density column instead of
redefining `grass_coverage`.

## Implemented

- New spec `grass_growth_mode`, `"stochastic"` (default) or
  `"deterministic"`, in R `default_specs()` and Julia `defaults.jl`,
  documented, registered in `.SPEC_GROUPS`, and validated with
  `check_choice()`. Julia also rejects an unknown mode with an
  `ArgumentError`.
- `grow_grass!` routes all three branches through one helper,
  `_grown_cell()`. Stochastic makes exactly the RNG draws it made
  before; deterministic makes none. Seasonal and niche modifiers scale
  the per-cell rate in both modes.
- New per-tick column `grass_density = sum(grass) / (N * grass_max)`,
  listed in `.valid_descriptor_columns()` and the `get_run_data()` docs.

## Files Changed

See the 2026-09-27 grass entry in `dev/dev-log/check-log.md`.

## Checks Run

Julia grass testset 12/12; seeded parity with `main` in all three
branches; R suite FAIL 0. Details in the check-log.

## Tests Of The Tests

Before the implementation the new Julia testset failed on the
deterministic cases and errored on the missing column and on the
unknown-mode check; the R tests failed on the missing default and on
validation. The stochastic-parity case passed before and after, as it
should: its job is to catch a change to the default path, which the
separate comparison against `main` confirms did not happen.

## Consistency Audit

`grass_coverage` keeps its meaning, so `search.R` descriptors,
`plot_*` functions and vignettes that read it are unaffected.
`plot_run()` still plots coverage only (`R/visualization.R`);
switching it to density under deterministic mode is left for review.
`grass_density` can exceed 1 only when `fixed_patch_value > grass_max`,
which the docs state.

## What Did Not Go Smoothly

My first Julia test indexed `res.progress` as a Dict; it is a
NamedTuple. JuliaConnectoR is not installed locally, so the R-to-Julia
path was not exercised from R.

## Team Learning

A behavioural toggle is easiest to trust when the default path is
checked against the previous commit directly, not only against itself.
A seeded side-by-side with a worktree of `main` takes under a minute.

## Known Limitations

`grass_rate` is still bounded to [0, 1] in both modes. That is natural
for a probability and harmless for an increment, but a deterministic
rate above one unit per tick is not expressible. The comparison of the
two modes is 5 seeds only and says nothing about evolutionary outcomes.

## Next Actions

Merge when green. Ask Sergio whether deterministic should become the
default, and whether `plot_run()` should show density.
