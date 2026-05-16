# R-function walk (Phase A)

One entry per public R function reviewed under the Phase A protocol
(`~/.claude/plans/purring-honking-dove.md`). Each entry follows the
per-session template: TREE → FOREST → TEST → ROSE → BIO. Fixes shipped
in the same commit are listed; fixes deferred to later phases are
flagged at the bottom.

## 1/28 — `default_specs()` (2026-05-16, `claude/track-B-walk`)

**TREE.** `R/config.R:1048-1632`. Pure list literal: 296 named fields
organised into ~40 thematic sections with inline comments and a
~1000-line preceding roxygen block. No arguments, no logic, no
validation. Sister helpers: `.validate_specs()` (`R/run.R:779`) does
type/range checks; `.specs_to_julia()` (`R/run.R:871`) coerces integer
fields and drops `NULL`/`NA`/zero-length entries before crossing the
JuliaConnectoR boundary; `.is_sendable_to_julia()` is the per-value
filter used inside `.specs_to_julia()`. Existing dedicated tests:
`test-config.R` (20 assertions), `test-specs.R` (24 assertions),
`test-spec-wiring.R` (2 structural guards). Side-channel coverage:
`test-cell-occupancy.R:53` asserts `max_agents_per_cell` is *not* a
field (deliberately removed in 0.7.0 — one-per-cell is enforced in
Julia movement, not a tunable knob).

**FOREST.** 296 fields, all referenced in at least one Julia file (the
`test-spec-wiring.R` allowlist remains the three reserved
brain-architecture placeholders: `transformer_history`,
`transformer_heads`, `synthesis_max_rules`). Only one *functional*
R-side caller: `.param_table(group, specs = default_specs())` in
`R/utils.R:280`. Every other R-side reference (≈ 30 sites in
`R/visualization.R`, `R/clade-package.R`, `R/hypothesis.R`, `R/maps.R`)
is a roxygen example, exercised by `R CMD check`. Vignettes: ~35 files
in `vignettes/` start from `default_specs()`. Tests: ~60 files load it
in setup.

**TEST.** One pre-existing failure caught and fixed: PR #116
(`feat(0.7.x): wire senescence_shape`) changed
`default_specs()$senescence_shape` from 2.0 → 1.0 with proper
docstring and inline-comment update ("Default 1.0 = classic
Gompertz"), but `tests/testthat/test-config.R:156-158` continued to
assert `expect_equal(..., 2.0)`. This was a silent failure since
0.7.x. Updated the test to `1.0` with a `# PR #116 …` comment so the
next reader sees the history. After the fix: `test-config.R` is
all-green again (was 1F before).

**SPEC_GROUPS prune** (in scope per the plan's item-1 mandate "verify
no Tier-3 ghost fields snuck back"). Found 13 names in
`R/utils.R::.SPEC_GROUPS` that do not exist in `default_specs()` —
all silently skipped by `.param_table()` so they did no immediate
damage, but they pollute the introspection surface and mislead
anyone reading the groupings as a contract. Removed: `max_agents_per_cell`
(deliberately removed; `test-cell-occupancy.R:53` asserts non-existence),
`brain_size_extra_grass_exponent`, `signal_mortality_per_unit`,
`signal_mutation_sd` (likely an old name for `signal_drift_sd`),
`mutation_sd_mutation_sd`, `carrion_decay` (real field is
`carrion_decay_rate`), `carrion_max`, `scavenge_gain` (real field is
`carrion_eat_gain`), `ann_l1_coefficient`, `ann_l0_coefficient`
(`ann_regularization_lambda` is the implemented single-scale knob),
`personality_antipred_radius`, `log_deaths`, `verbose_julia`
(`verbose` is a `run_alife()` argument, not a spec field). After the
prune: `length(setdiff(unlist(.SPEC_GROUPS), names(default_specs())))
== 0` and `length(setdiff(names(default_specs()), unlist(.SPEC_GROUPS)))
== 0` — perfect bijection.

**ROSE.** Two classes of mistake recurred during this walk:

1. **"Default changed in implementation, test not updated"** —
   senescence_shape 2.0 → 1.0 silently broke `test-config.R`. Cousin
   risk: every `expect_equal(default_specs()$<field>, <literal>)` in
   `test-config.R` and `test-specs.R` is a manual contract that has
   to be hand-kept in sync. A structural fix is feasible (a single
   test that snapshots `default_specs()` and diffs against a
   committed JSON), but it would conflict with Sergio's v0.8-core
   reshape, so defer to post-merge.

2. **"Group/allowlist references a removed or never-implemented
   field name"** — the 13 SPEC_GROUPS ghosts plus
   `parameter-reference.Rmd:59` plus
   `dev/design/10-after-task-protocol.md:145` all still mention
   `max_agents_per_cell`. The docstring of `.SPEC_GROUPS` ("Names
   that don't exist in `default_specs()` are silently skipped") makes
   this class invisible by design — which is the source of the drift.
   `test-spec-wiring.R` catches the *reverse* direction (R field with
   no Julia consumer) but not this direction (group entry with no R
   field). A drift-guard test that enforces
   `setdiff(unlist(.SPEC_GROUPS), names(default_specs())) ==
   character(0)` would close the loop and is the same shape as the
   four existing drift guards. Flagging for a near-term standalone
   commit.

**BIO.** Spot-checked the most consequential defaults: `grid_rows =
grid_cols = 30L`, `n_agents_init = 50L`, `max_agents = 500L` give an
initial density of 0.055 agents/cell and a saturation density of
0.55 agents/cell — both well below the one-per-cell invariant (0.99
would be the hard ceiling). `personality_alpha = 0.005` matches Wolf
2007's published value. `senescence_shape = 1.0` is classic Gompertz
h(t) = a·exp(b·t), the standard zero-curvature-correction
formulation. `repro_cost_mode = "proportional"` defaults to Smith &
Fretwell (1974) per the inline comment, which is the right modern
default. All evolution-module flags (`*_evolution`, plus `mimicry`,
`disease`, `kin_selection`, etc.) default to FALSE — correct
opt-in semantics for a reproducibility-first package.

**Deferred fixes (flagged for separate work):**

- `vignettes/parameter-reference.Rmd:59` still describes
  `max_agents_per_cell = 1L (default)`. Defer to Phase B (vignette
  walk) so the multi-seed re-render and the text fix land together.
- `dev/design/10-after-task-protocol.md:145` describes the one-per-cell
  invariant using the removed spec-field name. The principle ("one
  agent per cell") is correct and enforced in Julia movement; only
  the spec-field reference is stale. Flag for the user — they may
  prefer to keep the spec-field framing for memorability or rewrite
  it as "the one-per-cell rule (enforced in `inst/julia/src/movement.jl`)".
- Drift-guard test for `setdiff(unlist(.SPEC_GROUPS),
  names(default_specs()))`. One short test in a new file
  `test-spec-groups-coverage.R` would prevent the ghost class from
  re-accumulating. Defer because it would mean five drift guards
  instead of four and is worth a separate commit + check-log entry.
