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

## 2/28 — `run_alife()` / `run_clade()` (2026-05-16, `claude/track-B-walk`)

**TREE.** `R/run.R:51-92`. Six-step body: (1) `.clade_start_julia(verbose
= verbose)` (deferred Julia process start, idempotent); (2)
`.validate_specs(specs)` (early R-side type/range checks); (3) optional
`message(...)` summary; (4) `JuliaConnectoR::juliaCall("Clade.run_clade",
.specs_to_julia(specs))` — the one-and-only boundary crossing per call;
(5) `.julia_env_to_r(env_julia, specs)` deserialise; (6) attach
`viability_report()` and `warning()` on `verdict == "crashed"`.
`run_clade()` at `R/run.R:101` is an alias (`run_clade <- run_alife`).
Dependencies: `.clade_start_julia` (R/zzz.R:32) is self-guarded by
`.clade_env$julia_ready`; `.validate_specs` (R/run.R:779) covers
~15 hand-picked fields; `.specs_to_julia` (R/run.R:871) coerces
integer fields then drops un-sendable entries via
`.is_sendable_to_julia` (R/run.R:902, which rejects `NULL`,
length-0 vectors, and length-1 `NA`). Existing dedicated tests in
`test-integration.R` — *but see the parse-error finding below*.

**FOREST.** ~97 files reference `run_alife` / `run_clade`. Production
R-side use: `R/run.R` only (the function calls itself indirectly via
`batch_alife()` → `run_one()` at line 144). Roxygen examples: most
of `R/visualization.R`, `R/maps.R`, `R/hypothesis.R`,
`R/clade-package.R` — `\dontrun{}` wrapped, so `R CMD check` does not
execute them. Vignettes: every paper-* and s-* vignette (~35 files)
runs `run_alife()` directly in its main analysis block. Tests:
~60 files invoke `run_alife()` after `skip_no_julia()`, including
the heavy-lifting suite `test-integration.R`.

**TEST — critical finding.** `tests/testthat/test-integration.R`
**fails to parse** at line 337: `s$_empty_char_test  <- character(0L)`.
Underscore-prefixed names are not legal under R's `$` accessor
without backticks. Git blame: the line was renamed from
`s$world_params_to_evolve` to `s$_empty_char_test` in `2c7cf66
fix(0.7.x): delete world_evolution (Tier 2 of spec-wiring-audit)`,
which deleted the original spec field but used a synthetic name
that broke the R parser. **Net effect: every test in
`test-integration.R` (30+ tests including the run_alife() integration
suite, brain-type round-trips, batch_alife() smoke, and the very
`.specs_to_julia` NA/character(0) drop test that the Phase A item-2
mandate asked me to verify) has been silently failing to load since
the `world_evolution` deletion.** Fixed by renaming the synthetic
field to `s$synthetic_empty_char` in this commit; `parse(file =
"tests/testthat/test-integration.R")` now succeeds.

The plan's item-2 ask was "confirm `.specs_to_julia` handles NA /
character(0) correctly." Static review of `.specs_to_julia` +
`.is_sendable_to_julia` confirms the contract: `NULL`, length-0
vectors of any type, and length-1 `NA` of any type are dropped.
A length-2 `NA` vector (`c(NA, NA)`) would *not* be dropped and
would be sent to JuliaConnectoR — but this case does not occur in
`default_specs()` and is unlikely to occur in user-modified specs.
The intended dynamic verification lives at `test-integration.R:308`
(integer-vs-double type preservation) and `:330` (NA/`character(0)`
drop); both will now run (with Julia available) instead of being
skipped by the file-load error.

**Verbose path.** Verified statically: `verbose` controls
`.clade_start_julia()`'s startup message and the post-validation
summary `message()`. The viability warning fires *regardless* of
`verbose`, which is correct: a crashed run is always worth knowing
about. The summary message references `specs$n_agents_init`,
`specs$max_ticks`, `specs$brain_type`, `specs$ploidy` — four fields
guaranteed to be present after `.validate_specs()` passes.

**ROSE.** One Rose class re-surfaced (the same class as item 1):

- **"Spec field deletion leaves stale assertions or syntax in
  tests/vignettes."** Concrete cousins found:
  - `tests/testthat/test-life-history.R:64-67` asserts
    `"life_history_evolution" %in% names(s)` — false now (field deleted
    per NEWS 0.7.1).
  - `tests/testthat/test-life-history.R:39-43,46-48` assert
    `"repro_senescence" %in% names(s)` and `s$repro_senescence` —
    false now.
  - `tests/testthat/test-parental-investment.R:34` asserts
    `"parental_investment_init_mean" %in% names(default_specs())` —
    false now. The file may have other broken assertions; needs a
    full audit.
  - `tests/testthat/test-parental-care.R:118` asserts
    `"max_carried" %in% names(default_specs())` — false now.
  - The original `test-integration.R:337` parse error is the most
    severe instance of the same class — a rename of a deleted field
    that broke not just the assertion but the whole file.

  Structural fix: a one-shot drift-guard test that scans
  `tests/testthat/test-*.R` for `"<field>" %in% names(default_specs())`
  and `default_specs()$<field>` patterns and asserts every named
  `<field>` is in fact present in `default_specs()`. Same shape as the
  four existing drift guards. Defer to a standalone commit (Karpathy
  3: surgical), and bundle with the item-1 "SPEC_GROUPS coverage"
  guard so both ship together as a "Phase A drift-guard sweep".

**BIO.** `run_alife()` itself adds no biological semantics — it's
infrastructure. The one biological judgement embedded is the
crashed-run warning: trait-mean interpretations on a population that
crashed early are dominated by tiny surviving subpopulations and
therefore unreliable. This judgement is correct and the threshold
lives in `viability_report()` (audited later in Tier A1, item 6).
The verbose summary message picks the four most useful fields for a
human reader (`n_agents_init`, `max_ticks`, `brain_type`, `ploidy`) —
biologically sensible for orienting the operator before a long run.

**Deferred fixes (flagged for separate work):**

- Stale-assertion cleanup in `test-life-history.R`,
  `test-parental-investment.R`, `test-parental-care.R`. Each file
  needs deletion of its now-impossible assertions or, if the
  underlying field is supposed to come back, a `skip_if(...)` with
  an inline reference to the planned re-introduction. Estimated <100
  lines across the three files. Probably the user wants to triage
  these one at a time when reviewing each module.
- Drift-guard test `test-test-field-assertions.R` (or extend the
  existing `test-spec-wiring.R` to cover the inverse direction).
  Same recommendation as item 1's "test-spec-groups-coverage.R" —
  ship the two structural drift-guards together as one PR.
- Minor optimisation: `.validate_specs(specs)` is called *after*
  `.clade_start_julia(verbose = verbose)`, so an invalid specs list
  costs the user the full ~60 s Julia startup before the error
  arrives. Swapping the order would let validation fail fast. Not
  shipped here because (a) the cost only matters on the very first
  call of the R session, and (b) the change touches the entry
  function's call order, which is non-surgical for an item-2 walk.
  Flag for the user.

## 3/28 — `get_run_data()` (2026-05-16, `claude/track-B-walk`)

**TREE.** `R/analysis.R:38-47`. Thin wrapper that converts the raw
Julia-side `env` into a three-field list: `$ticks =
as.data.frame(lapply(env$progress, unlist))`, `$deaths =
as.data.frame(lapply(env$deaths, unlist))`, `$genomes =
.compose_genome_dataframe(env$genome_log)`. Sibling helper
`get_genome_data()` at `R/analysis.R:86` returns
`{genomes, heterozygosity, fst}` (the last two are reserved
`numeric(0L)` placeholders for documented future work). The post-#115
`.compose_genome_dataframe()` (`R/analysis.R:99-127`) iterates over
the Julia proxy array, calls `juliaGet` on each entry to extract
`(t, agent_ids, traits)`, and `rbind`s into a long
`(t, agent_id, trait_1..trait_N)` data frame.

**FOREST.** Heavily used. R-side production callers: `R/run.R:77`
(the in-`run_alife()` viability hook), `R/search.R` (search
algorithms), `R/hypothesis.R` (sweep summariser), `R/visualization.R`
(every dashboard panel). 14 vignettes call it; 12+ test files
exercise it. Dedicated test file: `tests/testthat/test-run-data.R`
(no-Julia, mock-based, 15 tests pre-walk). Julia-end-to-end coverage
for `.compose_genome_dataframe()` lives in
`tests/testthat/test-log-genomes.R` behind `skip_no_julia()`.

**TEST — two findings, both fixed.**

1. **Stale test (pre-#115).** `test-run-data.R:173-181` was the
   pre-#115 test of `get_genome_data()`: it built a mock
   `genome_log = list(matrix(...), matrix(...))` of plain R matrices
   and asserted `g$genomes[[1]] == m1`. Post-#115,
   `get_genome_data()` returns `{genomes, heterozygosity, fst}` and
   `genomes` comes from `.compose_genome_dataframe()`, which calls
   `juliaGet()` on every entry — plain R matrices are not proxies, so
   `juliaGet()` errors and `tryCatch()` swallows it, yielding `NULL`.
   The three assertions failed against the new contract. Rewrote the
   test to exercise the no-Julia surface of `.compose_genome_dataframe`
   directly: `NULL`, `list()`, and "garbage non-proxy inputs" all
   return `NULL` without crashing — the contract that matters for
   `get_run_data()`'s pipeline to remain robust. The Julia-required
   round-trip coverage is intentionally left to `test-log-genomes.R`,
   matching the no-Julia comment at the top of `test-run-data.R`.

2. **Roxygen doc-debt.** The `@return` block at `R/analysis.R:11-26`
   enumerated ~25 columns for `$ticks`. The actual
   `inst/julia/src/logging.jl::_init_progress` produces **61**
   columns (verified with `grep -cE '^\s*"[a-z_]+"\s+=> copy'`).
   So ~36 columns existed but were undocumented. Rewrote the
   `@return` to list the always-present core columns explicitly,
   describe the always-allocated module columns by group, and add a
   pointer to `inst/julia/src/logging.jl::_init_progress` plus
   `colnames(get_run_data(env)$ticks)` for the authoritative list.
   This is honest about scale without bloating the docstring with all
   61 names; readers wanting one specific column can call
   `colnames()`.

After the fixes: `test-run-data.R` passes 28/28 (was 25P + 3F).

**ROSE.** Two classes recurred:

1. **"API change leaves test fixtures pointing at the old behaviour"**
   — the pre-#115 vs post-#115 `$genomes` shape change is a fresh
   instance of the same Rose class from items 1 and 2. Cousin risk:
   any test using `.mock_env(genome_log = ...)` or similar fixtures
   should be audited after a shape-changing PR. Structural fix
   (still deferred): add a "post-#NNN shape changes" line to the PR
   template that asks the author to grep for stale fixtures.

2. **"Code grows fields/columns; roxygen `@return` doesn't"** — the
   `$ticks` doc-debt is the first instance of this distinct class.
   Cousin risk: every roxygen `@return` that enumerates a finite list
   could be undercount. Spot candidates: `get_genome_data()`,
   `viability_report()`, `plot_run()`. The structural fix is to
   pivot list-of-columns roxygen to "see `<source>` + use
   `names()` / `colnames()` for the authoritative list" wherever
   the producer is data-driven rather than hand-curated.

**BIO.** `get_run_data()` has no biological semantics — it's a
shape transformation. One judgement embedded in the design: the
log shape is **stable across specs** (module-specific columns are
always allocated, zero when the module is disabled). That decision
is the right one for downstream code — `plot_run()` and the
viability hook can rely on column presence regardless of which
modules the user enabled. The roxygen now states this explicitly.

`get_genome_data()`'s `$heterozygosity` and `$fst` placeholders
(both `numeric(0L)`) are honest about being reserved for future
work — better than fake numbers. The `@references` for Weir &
Cockerham (1984) is already in place, so when those fields land
the citation is ready.

**Deferred fixes (flagged for separate work):**

- Sibling-function doc audit. `get_genome_data()`,
  `viability_report()`, `plot_run()`, `inspect_brain()` all carry
  `@return` lists that could go stale by the same "code grows, doc
  doesn't" class. Phase A item 4 (`plot_run()`) and Tier-A1 item 6
  (`viability_report()`) cover two of them under the normal walk
  rhythm; the other two are out-of-band.
- Future `$movement` accessor — if the post-Sergio movement-log
  proposal lands, `get_run_data()` will gain a fourth field
  `$movement`. The roxygen rewrite is structured so a one-line
  insertion will suffice; no redesign needed.

## 4/28 — `plot_run()` (2026-05-16, `claude/track-B-walk`)

**TREE.** `R/visualization.R:91-187`. Standard dashboard: takes a
`get_run_data()` output, validates via `.check_run_data()`, filters
out unlogged-tick rows (`t > 0`), short-circuits to
`.plot_empty("No logged ticks")` if nothing remains, and otherwise
builds six ggplot panels combined with `patchwork::wrap_plots(ncol
= 3L)`: (1) population size, (2) mean energy ± 1 SD ribbon,
(3) genetic diversity, (4) births vs deaths per tick, (5) grass
coverage, (6) brain-type-aware sixth panel — BNN prior sigma if
`mean_prior_sigma` varies (Baldwin Effect panel; Baldwin 1896,
Hinton & Nowlan 1987), mean body size otherwise. Two helpers
(`.check_run_data`, `.plot_empty`) are reused across the entire
`R/visualization.R` plot family and were correct as-is.

**FOREST.** Lighter than item 3's. Production: the in-package
`visualize_progress()` at `R/visualization.R:1188` builds a larger
dashboard that includes the `plot_run()` panels. Roxygen: a
~dozen vignettes call `plot_run()` directly; another dozen use it
indirectly via `visualize_progress()`. Tests: dedicated coverage in
`tests/testthat/test-visualization.R` (37 tests pre-walk, 39
post-walk).

**TEST — plan's three asks, all verified.**

1. **NULL handling.** `plot_run(NULL)` and `plot_run(list())` both
   fail the `is.list(run_data) || is.null(run_data$ticks)` check in
   `.check_run_data` and `stop()` with a one-line message naming
   `get_run_data()` — already tested at `test-visualization.R:136-139`.
2. **Empty-progress handling.** Zero-row `$ticks` returns
   `.plot_empty("No logged ticks")` without erroring — already
   tested at `test-visualization.R:176-183`.
3. **Crashed-run handling — newly verified.** The plan asked
   specifically about "viable_report-flagged-crashed" runs. In
   logging.jl, `log_tick!` does `n == 0 && return` when the
   population dies out, so the pre-allocated metric vectors keep
   their initial zero values for every post-crash tick. `plot_run`'s
   `d <- d[d$t > 0L, , drop = FALSE]` filter at line 96 trims the
   zero-padded tail; the resulting plot is a truncated timeline
   ending at the last logged tick. No special-case handling needed;
   the design is correct. Added a dedicated test
   (`test-visualization.R:185-209`) that builds a mock with the
   exact post-crash shape (`t = 0, n_agents = 0, mean_energy = 0,
   ...` for the tail) and asserts `plot_run()` returns a valid
   `patchwork`/`ggplot` object. Test passes post-fix.

After the walk: `test-visualization.R` passes 39/39 (was 37/37
pre-walk; added 1 test asserting 2 expectations).

**ROSE.** This walk surfaced **no new bug or stale-assertion class
in `plot_run()` itself** — the function is well-tested and the
design holds up. The one Rose pattern worth recording is positive:

- **"Filter at the leaves, not at the source."** `plot_run()`
  trusts `get_run_data()` to return whatever Julia logged and
  applies its own `t > 0` filter at the point of use. That isolates
  it from the choices made in `log_tick!`: when Julia changes how
  unlogged ticks are represented (e.g., the hypothetical
  movement-log might want different conventions), only the leaf
  filters need to change, not the data path. Recommend the same
  pattern for any future plot_* sibling.

**BIO.** The six-panel choice is biologically thoughtful:
*demography* (pop size, births vs deaths), *individual state*
(energy ± SD), *evolutionary signal* (genetic diversity),
*environment* (grass coverage), *brain-relevant* (BNN sigma /
body size). Together they let a reader judge in 10 seconds whether
a run is viable, runaway, collapsing, or pathological in some
specific way. The conditional sixth panel (Baldwin sigma vs body
size) is the smartest part — it surfaces the most-informative
variable for the active brain type without making the user choose.

The decision to use `± 1 SD` (not `± 1.96 SD` for 95 % bands) is
honest: at the population sizes clade typically simulates
(50–500 agents), the sampling distribution of the mean is narrow
enough that a 1-SD ribbon shows *individual* heterogeneity rather
than confidence in the mean, which is what the reader actually
wants for an evolutionary-dynamics dashboard. Worth a sentence in
the docstring eventually, but not blocking.

**CONTRIBUTE — basics.Rmd is now complete.** Sections 4 and 5
added in this commit; `basics` registered as the first entry under
the pkgdown Overview articles block so it appears at the top of
the Articles navbar. The vignette is the Tier-A0 deliverable;
clicking "Articles → Basics" in the rendered site now lands the
user on the 5-minute walkthrough built from items 1–4.

**Deferred fixes (flagged for separate work):**

- `± 1 SD` vs `± 1.96 SD` clarification in the docstring (one
  sentence on what the ribbon represents). Not blocking.
- Sister-function doc audit for the rest of the `R/visualization.R`
  family (`plot_environment`, `plot_genome_diversity`,
  `plot_disease_dynamics`, `plot_module_metrics`,
  `plot_tsne_genomes`, etc.). The "code grows columns, roxygen
  doesn't" Rose class from item 3 likely applies. None are Tier-A0,
  so Tier-A3 items 18-21 will pick them up under the normal walk.

# Tier A1

## 5/28 — `batch_alife()` + `batch_seeds()` (2026-05-16, `claude/track-B-walk`)

**TREE.** `R/run.R:140-170` (`batch_alife`) and `R/run.R:199-211`
(`batch_seeds`). `batch_alife()` is a thin parallel wrapper around
`run_alife()`: validates the input is a non-empty list, coerces
`n_cores` to integer, defines `run_one(specs) =
run_alife(specs, verbose = verbose)`, and dispatches to either
`lapply(specs_list, run_one)` (serial, `n_cores <= 1L`) or a
PSOCK `parallel::makeCluster()` + `parLapply()` (parallel,
`n_cores > 1L`) with `clusterEvalQ(library(clade))` to load the
package on each worker and `on.exit(stopCluster())` cleanup.
`batch_seeds()` is the seed-sweep convenience wrapper: validates
inputs, coerces `seeds` to integer, builds a `specs_list` where
each element is `specs` with `$random_seed` overridden, names the
elements `seed_<N>`, and delegates to `batch_alife()`. The defensive
re-naming of results at line 209 is redundant (the specs_list names
are preserved by `lapply`/`parLapply`) but harmless.

The 0.5.6-vintage docstring comment on the PSOCK switch is
excellent — it names the symptom (silent deadlock in `mclapply`
because forked workers share the parent's JuliaConnectoR socket),
the design tax (per-worker ~60 s Julia JIT cost), and the
rule-of-thumb crossover (~20 scenarios) where parallel beats
serial. Keep this as-is when v0.8-core merges.

**FOREST.** 36 references across `R/`, `tests/`, `vignettes/`,
README, NEWS. Production callers: `R/hypothesis.R`
(`hypothesis_sweep()`), `R/search.R` (search algorithms),
`R/scenarios.R` (scenario harnesses). Vignettes that demonstrate
batch usage: `s-baseline.Rmd`, `s-baldwin.Rmd`, `s-cross-module.Rmd`,
~25 others. README mentions both. **Test coverage before this walk
was a single Julia-required test buried in `test-integration.R:217`
(`batch_alife() returns one env per spec`) — `batch_seeds()` had
zero dedicated coverage**, despite being the more user-facing of
the two and the canonical answer to the "≥5 seeds per claim"
discipline that every multi-seed vignette enforces.

**TEST — coverage gap closed.** Created `tests/testthat/test-batch.R`
(11 tests, 20 expectations, all no-Julia). The seed-override and
naming transformations in `batch_seeds()` and the
serial-vs-parallel dispatch + validation in `batch_alife()` are
pure R; they can be verified without a Julia session by mocking
`run_alife()` via `testthat::local_mocked_bindings()` (testthat
3.0+). The new file covers:

- `batch_seeds()` — overrides `random_seed` per replicate
  (verified by inspecting the mock's captured `(specs, verbose)`
  arguments), names results `seed_<N>` in input order, preserves
  all other spec fields, coerces non-integer seeds via
  `as.integer()`, rejects non-list specs, rejects empty seeds.
- `batch_alife()` — runs each spec in order under `n_cores = 1L`
  (verified by capturing the mock's call order), propagates the
  `verbose` flag, rejects non-list inputs and empty specs_list,
  coerces non-integer `n_cores`.

PSOCK path (`n_cores > 1L`) deliberately not duplicated: it
requires real worker R processes and Julia sessions, which the
`test-integration.R` end-to-end test already exercises behind
`skip_no_julia()`. Duplicating that here would add wall-clock cost
without new signal.

**ROSE.** One new (mild) class surfaced:

- **"Convenience wrapper has no dedicated test."** `batch_seeds()`
  is the more user-facing of the pair (every multi-seed vignette
  uses it) but had zero dedicated coverage. The same risk class
  exists for `quick_specs()`, `fast_specs()`, `realistic_specs()`,
  `ultra_realistic_specs()`, `slow_specs()`, `full_specs()`
  (Tier-A1 item 8 covers the preset family) and the
  `wolf_personality_specs()` / `trivers_reciprocity_specs()` /
  `wolf2008_responsiveness_specs()` paper presets (Tier-A2 items
  11-13). Mitigation already in plan; flagging the class for the
  reviewer's reference.

**BIO.** `batch_alife()` and `batch_seeds()` have no biological
semantics — they are infrastructure. Two design judgements
embedded that are biologically right:

1. `batch_seeds()`'s default `seeds = 1:5` matches the
   ≥5-seeds-per-claim discipline encoded throughout the
   `vignette("scenarios")` and `paper-*` workflows. The default is
   the right floor for multi-seed claims; it nudges users into
   sound practice without forcing a higher cost on quick
   exploration.
2. `batch_alife()`'s `n_cores = 1L` default is the right safe
   choice: it avoids the Julia per-worker compile cost and the
   PSOCK setup overhead, both of which dominate runtime for small
   batches. The docstring explicitly names ~20 scenarios as the
   crossover where parallel pays off — exactly the right
   information for the user to make the call.

**CONTRIBUTE.** No basics.Rmd change this item. `batch_seeds()`
and `batch_alife()` already appear in section 2 (the run_alife()
worked example notes both) and section 5 (the multi-seed
"What next" pointer). basics.Rmd is at 173 lines — slightly over
the 150-line plan target — so resisting the temptation to add
more text. Tier A1 items contributing to basics.Rmd will need to
adopt the same restraint going forward, or accept rewriting an
existing section rather than adding a new one.

**Deferred fixes (flagged for separate work):**

- The redundant `names(results) <- paste0("seed_", seeds)` at
  `R/run.R:209` could be deleted (the input names survive
  `parLapply`). Cosmetic; not worth a commit on its own. Bundle
  into a future "R/run.R cleanups" PR if one ever happens.
- An explicit `batch_alife(specs_list, n_cores = 2L)` end-to-end
  test would catch PSOCK regressions before they surface in long
  multi-seed runs. Requires Julia and ~3 minutes of wall time
  (two worker compilations); would slow `test-integration.R`
  noticeably. Defer to a separate "long-running" test file or a
  CI-only flag.

## 6/28 — `viability_report()` (2026-05-16, `claude/track-B-walk`)

**TREE.** `R/analysis.R:1069-1127`. Quality-gate function: takes
either a `$ticks` data frame or a full `get_run_data()` output;
computes `n_init` (defaults to first-tick `n_agents`), `n_final`,
`n_min`, `tick_of_min`, `frac_final`, `frac_min`; assigns a verdict
in `{"viable", "weak", "crashed"}` and returns a structured list
with class `clade_viability_report`. Print method at
`R/analysis.R:1130-1133` is a one-line `cat` of `x$message`. The
verdict rule:

```r
"crashed"  if (abs_check_applies && n_final < min_n) || frac_final < crashed_frac
"weak"     if frac_final < weak_frac
"viable"   otherwise
```

with `abs_check_applies <- n_init >= min_n` being the **0.7.0
flat-pop bypass** (line 1102) — only apply the absolute floor
when the run started above it. Without this guard, a deliberate
small-population unit test (`n_init = 5`) would always be flagged
"crashed" and the `warning()` from `run_alife()`'s viability hook
would break `expect_silent()` assertions in `test-brains.R` etc.

**FOREST.** 13 files reference `viability_report`. The only
production caller is **`R/run.R:77`** — the in-`run_alife()`
viability hook from item 2. Everything else is roxygen, tests, or
vignette uses. This single production caller is why the 0.7.0
bypass matters: every test that calls `run_alife()` indirectly
invokes `viability_report()`. Roxygen completeness check:
`@return` (line 1044-1054) lists 8 fields (`verdict`, `n_init`,
`n_final`, `n_min`, `frac_final`, `frac_min`, `tick_of_min`,
`message`); the actual return at line 1117-1126 lists exactly
those 8. **No doc-debt** — the worry flagged in item 3's audit
was unwarranted for this function.

**TEST — three of the plan's three asks already covered, one
critical gap closed, three new tests added.**

Existing coverage in `test-analysis.R:271-306`:

1. ✓ `min_n` floor (line 288-293) — `n_init = 20, n_final = 12,
   min_n = 20L` → crashed; `min_n = 0L` → viable.
2. ✓ Threshold classification (lines 271-286) — viable / weak /
   crashed runs at 90%, 40%, 5% retention.
3. ⚠ **Flat-pop bypass — NOT covered.** This is the specific
   0.7.0 behaviour the plan asks about. The existing min_n test
   uses `n_init = 20`, which is *equal* to the default `min_n`,
   so `abs_check_applies = TRUE` and the bypass does not fire.
   The case the bypass protects (`n_init < min_n`) was unverified.

Added three new tests:

- "viability_report() does NOT flag stable small-pop runs as
  crashed (0.7.0 bypass)" — `n_init = 10, n_final = 9, min_n =
  20L` → verdict must be "viable". Verifies the bypass kicks in.
- "viability_report() still crashes a small-pop run that actually
  collapses" — `n_init = 10, n_final = 1, min_n = 20L` →
  "crashed". Verifies the bypass does NOT protect a genuine
  fractional collapse (the fractional check still fires).
- "viability_report() rejects invalid crashed_frac / weak_frac /
  min_n" — exercises the `stopifnot()` block: negative or > 1
  crashed_frac, weak_frac < crashed_frac, weak_frac > 1, negative
  min_n. The `weak_frac > crashed_frac` check is biologically
  important — a weak threshold below the crashed threshold would
  invert the verdict ladder.

Plus one new test for the `tick_of_min` / `n_min` extraction on a
bottleneck shape (population drops to 20 at tick 5, recovers to
100 at tick 10) — verifies the trough is correctly identified
even when the run ultimately recovers to "viable".

After the additions: `test-analysis.R` viability_report block
covers 6 → 10 tests, with 12 → 21 expectations.

**ROSE.** Same class as item 5: a critical 0.7.0 behaviour was
shipped without a regression test. Cousin candidates:

- Every "X.Y.Z guard added" docstring comment in `R/` is a
  candidate for "behaviour added, regression test never landed."
  Spot-grep ideas for a future drift-guard PR:
  `rg "Pre-0\\.[0-9]+\\." R/` or `rg "added in 0\\." R/` — both
  return ~40+ hits; spot-checking 5 random ones would surface any
  similar gaps quickly.
- Same as item 5's "convenience wrapper has no dedicated test"
  class, just applied at a finer grain — "convenience guard
  added but not covered." Both classes share the same structural
  fix: a checklist in PR review asking "did you add a regression
  test for the behaviour this PR adds?"

**BIO.** This function IS the biology: it encodes the
"trait-mean interpretations on crashed runs are unreliable" rule
into a single reusable check. Three biologically motivated
thresholds:

1. **`crashed_frac = 0.2`**: a run that ends below 20% of init
   has experienced a population collapse. Below this fraction,
   trait-mean averages are dominated by a few lucky survivors —
   the specific crash trajectory drives the estimate, not the
   evolutionary signal. Defensible default; matches the
   "≥ 5 surviving agents per locus" rule-of-thumb in pop-gen.
2. **`weak_frac = 0.5`**: between 20% and 50% the run is
   technically viable but the user should be told confidence is
   reduced. The `"weak"` verdict is a deliberate "soft warning"
   tier — not loud enough to interrupt automated sweeps, loud
   enough that a careful reader of `viability_report` output
   sees it.
3. **`min_n = 20L`**: an absolute floor under which any trait
   mean is "dominated by a handful of individuals" (the
   docstring's exact phrasing). 20 is small but defensible:
   below 20 agents the variance of any mean estimate explodes,
   and a single death changes population fraction by 5%+.

The 0.7.0 flat-pop bypass is itself a biological judgement:
"a unit test that intentionally runs 5 agents to test some
movement code path is not crashed; it is stable at its chosen
size." Without the bypass, the biological framing of "crashed"
would conflate with the operational framing of "small," which
is a category error.

**Deferred fixes (flagged for separate work):**

- The "Pre-0.X.Y" / "added in 0.X" docstring-comment grep
  (above) — would be a one-evening cousin-hunt that could
  surface several more behaviour-without-regression-test
  candidates. Bundle with the drift-guard sweep PR if appetite
  exists.
- No basics.Rmd change this item. The viability concept is
  mentioned in section 2 (the run_alife() worked example
  surfaces `env$viability$verdict`) and section 5 (the
  multi-seed pointer mentions `viability_report` directly).
  Adding more would bloat past the 150-line plan target.
- The `weak_frac > crashed_frac` validation could carry a
  one-line error message naming the contract instead of relying
  on `stopifnot()`'s expression-formatted output. Cosmetic; not
  worth a commit on its own.

## 7/28 — `print_specs()` (2026-05-16, `claude/track-B-walk`)

**TREE.** `R/utils.R:321-367`. Pretty-printer for a specs list. Two
modes: full (every field, grouped by `.SPEC_GROUPS`) and
`diff_only = TRUE` (only fields that `!identical()` to
`default_specs()`). Flow: fetch defaults, copy `.SPEC_GROUPS` as the
local `groups`, compute `other` for ungrouped fields and append it
as an "Other" group, conditionally compute `changed`, print the
header, loop groups → loop keys → format value (logical →
`"TRUE"/"FALSE"`, length > 6 → `[a, b, c, d, e, f ...]`, length > 1
→ `[…]`, else `as.character()`) → mark with `*` if changed, return
`specs` invisibly for piping.

**FOREST.** Light footprint: roxygen examples in `R/utils.R`
itself; `vignettes/basics.Rmd` (sections 1 and 5);
`vignettes/parameter-reference.Rmd` (the introspection table page);
`vignettes/getting-started.Rmd` (a diff-only example in the
introduction). **No dedicated test coverage existed pre-walk** —
`print_specs()` was relied on only via `R CMD check`'s
example-runner. Same Rose class as item 5's "convenience wrapper
has no dedicated test", applied here to a more user-facing function.

**TEST — coverage gap closed.** Created
`tests/testthat/test-print-specs.R` (7 tests, 16 expectations, all
no-Julia). The function is pure R (a `cat()`-only printer) so
`capture.output()` is the right inspection tool. Covers:

- **No-args path**: header line shape (`"-- clade specs (N
  parameters) --"`) and invisible return of `default_specs()`.
- **Group headers**: the four always-populated groups (Grid &
  population, Energy & metabolism, Grass dynamics, Brain
  architecture) appear in the output.
- **diff_only path**: when two fields are changed
  (`n_agents_init`, `kin_selection`), the header carries the
  `"[diff only]"` tag, both changed fields appear with the `*`
  marker, and unchanged fields (`grass_rate`) do *not* appear.
- **diff_only with no changes**: prints the "(no parameters
  differ from defaults)" message.
- **`.SPEC_GROUPS` consumption**: a synthetic ungrouped field
  (added via `[[ ]]` accessor — using `$_xxx` would trip the R
  parser, the same bug that broke `test-integration.R` until
  item 2) appears under an "Other" group header.
- **Empty input edge case**: `print_specs(list())` produces no
  group headers (only the header line).
- **Invisible return**: the value returned equals the input
  argument exactly, with no warnings or messages.

Plan's two asks both verified:

- **Post-#124 `.SPEC_GROUPS` consumption** — line 326
  (`groups <- .SPEC_GROUPS`) and line 346
  (`keys <- intersect(groups[[grp]], names(specs))`). Driven from
  the same source of truth as `.param_table()`. Tested via the
  Other-group and always-populated-headers paths.
- **`diff_only = TRUE`** — line 333-339 (compute `changed` via
  `vapply` + `identical`), line 347 (filter `keys` to `changed`),
  line 362 (empty-changes message). Tested via the
  changed-fields, unchanged-fields-hidden, and no-diff-message
  paths.

After the addition: `test-print-specs.R` is 16 pass; the existing
structural drift-guards (`test-test-field-assertions.R`,
`test-spec-groups-coverage.R`) verify they do *not* false-positive
on the new file.

**ROSE.** No new bug class. The `.SPEC_GROUPS` post-#124 design
(introspection-driven, not hand-curated) is paying off here too:
the function picks up new spec fields automatically as long as they
are added to a group, and PR #129's bijection drift-guard enforces
that they always are.

Recurring class confirmation (item 5's): convenience-/utility-
function coverage gap. After items 5 (`batch_alife` + `batch_seeds`)
and 7 (`print_specs`), the remaining Tier-A1 candidate is item 8
(the preset family `quick_specs / fast_specs / realistic_specs /
ultra_realistic_specs / slow_specs / full_specs`). One audit covers
all six because they are parallel; the same Rose risk applies and
the same fix shape (mock + capture inspection) will work.

**BIO.** `print_specs()` has no biological semantics — it is
display infrastructure. One small editorial judgement: the `*`
change marker (used inline with each value) plus the `"[diff only]"`
header tag *double-signal* that the user is looking at a modified
spec list. This is the right call for a display function that is
also valuable on a *full* spec list — the marker is meaningful in
both modes; the tag clarifies the viewport. Defensible.

The vector-display cap at 6 elements (line 354,
`if (length(v) > 6) sprintf("[%s ...]", paste(head(v, 6), ...))`)
matches the same cap in `.spec_value_format()` at line 248 — two
helpers, same convention. Consistent; no drift.

**Deferred fixes (flagged for separate work):**

- Sister-function doc audit: the four `S3` methods at
  `R/utils.R:373-...` (`print.clade_env`, `summary.clade_env`,
  plus implicit `format` / `[[.clade_env`) are not dedicated-
  tested either. Tier-A3 candidate, not Tier-A1.
- The cap of 6 vector elements in display is hard-coded twice
  (`.spec_value_format()` and `print_specs()`). A
  `.SPEC_VALUE_DISPLAY_CAP <- 6L` constant + reuse would prevent
  drift if either site changes. Cosmetic; not worth a commit.
- No `vignettes/basics.Rmd` change. `print_specs()` is already
  covered in sections 1 and 5; basics.Rmd is at 173 lines (over
  the 150-line plan target).

## 8/28 — preset family (2026-05-16, `claude/track-B-walk`)

Covers `quick_specs()`, `full_specs()`, `fast_specs()`,
`realistic_specs()`, `ultra_realistic_specs()`, `slow_specs()` —
six parallel functions in `R/config.R:1650-1859`. One audit,
because the functions share a structural pattern (each takes
`default_specs()` or a sibling preset and overrides a small set
of fields).

**TREE.** The presets form a chain:

```
default_specs()
  ├─ quick_specs()
  ├─ full_specs()
  ├─ fast_specs()
  │    └─ realistic_specs()
  │         └─ ultra_realistic_specs()
  └─ slow_specs()
```

Three "lineage" presets (`fast`/`realistic`/`ultra_realistic`)
inherit pace-of-life calibration through the chain; the other
three (`quick`/`full`/`slow`) are independent overrides of
`default_specs()`. Each function simply assigns new values to
~5-10 fields and returns the modified specs list.

**FOREST.** 33 files reference the preset family. Production
callers: `tests/testthat/test-hypothesis.R`,
`tests/testthat/test-integration.R` (plus a separate
`.quick_specs()` local helper — a different function, easy to
confuse). Vignettes: most paper-* reproductions start from
`fast_specs()` or `realistic_specs()`; `s-baseline.Rmd` uses
`quick_specs()`; the slower-tempo scenarios use `slow_specs()`.
**Test coverage before this walk: zero dedicated tests for any
preset.** Same Rose class as items 5 and 7 — convenience wrapper
without a dedicated test.

**TEST + DOC findings — three roxygen-vs-code reconciliations
and one new test file.**

1. **`ultra_realistic_specs()` — roxygen lied about `n_agents_init`.**
   The roxygen `@details` table said `800L` and the
   `@return` description said "N ≈ 800–1500 equilibrium"; the
   code has always been `500L` with an inline comment
   "right-sized to ~400 equilibrium." Updated the roxygen to
   match the code (the inline comment is the truth) and the
   `@return` description to "N ≈ 400 equilibrium." This is a
   real semantic mismatch — anyone reading the rendered help
   page would expect a 60% larger initial population than they
   get.
2. **`fast_specs()` — roxygen omitted `predator_max_age = 100L`.**
   The function sets seven distinct fields from
   `default_specs()` but the `@details` table listed only six.
   The omitted line documents an intentional asymmetry (predators
   outlive 30-tick prey by ~3×, owl > mouse). Added the missing
   row to the table.
3. **`slow_specs()` — roxygen omitted three of the seven
   overridden fields.** The `@details` table listed `max_age`,
   `min_repro_energy`, `min_repro_age`, `max_ticks`; the code
   also sets `grass_rate = 0.10`, `n_agents_init = 100L`,
   `max_agents = 500L`. Added the three missing rows. The
   `grass_rate` change is biologically meaningful — slightly
   richer environment compensates for the higher
   `min_repro_energy` threshold, otherwise K-strategist
   populations starve.

Created `tests/testthat/test-presets.R` (10 tests, 73
expectations, no-Julia). Coverage:

- **Shape**: every preset has the same field names as
  `default_specs()` — no preset introduces or drops fields. The
  drift-guard from PR #129 enforces `.SPEC_GROUPS` ↔
  `default_specs()` bijection, but this test catches preset
  drift downstream.
- **Validation**: every preset passes `.validate_specs()` cleanly
  (no early-error during real use).
- **Documented values**: per-preset assertions on every value
  listed in the roxygen `@details` table. After the three
  reconciliations above, all assertions pass — and any future
  table-vs-code drift will be caught immediately.
- **Chain inheritance**: `realistic_specs()` carries
  `fast_specs()`'s pace-of-life (`max_age = 30L`,
  `min_repro_energy = 60`, `min_repro_age = 3L`,
  `grass_rate = 0.20`). `ultra_realistic_specs()` carries
  all of fast's settings plus realistic's
  `predator_max_age = 60L` override (not fast's original
  `100L`) — a critical regression-protect on the inheritance
  cascade.
- **Immutability**: calling any preset does not mutate
  `default_specs()` (rules out a shared-reference bug if anyone
  ever refactors to `<<-` accidentally).

After the additions: `test-presets.R` is 73 expectations pass;
all three regenerated man pages match the updated roxygen
exactly; PR #129's drift-guards do not false-positive.

**ROSE.** Three classes in play:

1. **Recurrence (item 5, item 7): "convenience wrapper has no
   dedicated test."** Closed for the preset family with this
   walk. Tier-A1 has now exhausted this class — items 5
   (batch_*), 7 (print_specs), and 8 (presets) all closed.
   Tier-A2 paper presets (items 11-13:
   `wolf_personality_specs()`, `trivers_reciprocity_specs()`,
   `wolf2008_responsiveness_specs()`) are the same class and
   will likely need the same fix shape.
2. **Recurrence (item 3): "code grows fields/columns; roxygen
   `@return` doesn't."** Two of the three doc-fixes
   (`fast_specs`, `slow_specs`) are this class — the function
   silently grew a parameter override that the roxygen never
   caught up with. The `test-presets.R` "documented values" tests
   make this catchable on future drift.
3. **New (item 8): "documented value disagrees with implementation
   value."** `ultra_realistic_specs()`'s `800L` was not an omission
   — it was an active claim contradicted by the code. Different
   from class 2 (omission). Cousin candidates: every roxygen
   `@return` block that quotes a specific numeric default. Spot-
   grep idea for a future cousin-hunt:
   `rg "default[s]? \\d" R/*.R | head -50` — surfaces inline
   defaults claims; spot-check each against the code.

**BIO.** The preset values are biologically defensible:

- **`quick_specs()`**: 20×20 grid + 200 ticks = exploratory; the
  smaller grid sacrifices spatial dynamics for turnaround time.
  Acceptable for prototyping.
- **`full_specs()`**: 30×30 + 200 init + 1000 ticks = publication
  scale at default pace-of-life. Right balance for figures.
- **`fast_specs()`**: max_age=30 + min_repro_energy=60 +
  min_repro_age=3 + grass_rate=0.20 gives ~30-tick generations
  and 66 generations in a 2000-tick run. Calibrated to the
  MATLAB ancestor's pace (Bulitko 2023). Right preset for
  trait-evolution studies. `predator_max_age = 100L` honours the
  owl > mouse lifespan ratio.
- **`realistic_specs()`**: 60×60 grid + 1500-agent cap +
  predator age structure. Right preset when spatial dynamics
  (dispersal gradients, predator-prey waves) need room to
  express. The 2000-tick cap is set by BNN-kernel stability
  (see docstring) — defensible engineering trade-off.
- **`ultra_realistic_specs()`**: 120×120 + 5000-agent cap for
  finite-population corrections (Red Queen advantage ~μN;
  Hamilton 1971 selfish-herd dilution ~1/√N). 2500-tick cap
  (BNN stability ceiling). Right preset for theory-vs-simulation
  audits where N matters more than wall time.
- **`slow_specs()`**: K-strategist (long max_age, high
  min_repro_energy, late min_repro_age). 10000-tick horizon for
  ~50 generations. `grass_rate = 0.10` compensates for the
  higher reproduction threshold — without it, populations would
  starve. Defensible.

The chain (ultra_realistic → realistic → fast → default) is
biologically right: each step relaxes a constraint (grid size,
agent cap, predator age structure) while preserving the upstream
pace-of-life. A user who needs "fast-pace evolution at theory
scale" composes the right semantics by calling
`ultra_realistic_specs()`.

**Deferred fixes (flagged for separate work):**

- Cousin-hunt for "documented value disagrees with implementation
  value" via `rg "default[s]? \\d" R/*.R` — ~50 candidates worth
  spot-checking. Could become a one-evening session before the
  next CRAN-style release.
- The `.quick_specs()` local helper in `test-integration.R`
  shadows the public `quick_specs()` name. Worth renaming to
  `.test_specs()` or similar in a future test-file rename PR.
  Cosmetic; not worth a commit on its own.
- No `vignettes/basics.Rmd` change this item. Presets are not
  mentioned in basics.Rmd at all by design — the 5-minute
  introduction sticks with `default_specs()` and lets the user
  discover the preset family via `vignette("getting-started")`
  or `?quick_specs`. Acceptable, but worth a sentence in a
  future basics.Rmd revision if the file gets restructured.

# Tier A2

## 9 + 10/28 — `hypothesis_sweep()` + `hypothesis_report()` (2026-05-16, `claude/track-B-tier-A2`)

Combined walk: both functions form a single research workflow
(sweep → contrast report) and were natural to audit as a pair. The
plan lists them as items 9 and 10; this commit closes both.

**TREE.** `R/hypothesis.R:78-159` (`hypothesis_sweep`),
`R/hypothesis.R:245-294` (`hypothesis_report`), plus print methods
at `:162` and `:297` and the internal `summary_hypothesis_sweep`
at `:177`. The flow:

```
base_specs + conditions × seeds + metrics
        │
        ▼  (build spec_list)
   batch_alife()
        │
        ▼  (per env, get_run_data → ticks → apply metric functions)
  hypothesis_sweep object { runs, conditions, metrics, base_specs,
                            seeds, elapsed }
        │
        ▼  (per named contrast)
  hypothesis_report object { table = (contrast, ref, test, metric,
                                       n_ref, n_test, delta, se, t,
                                       verdict), metric }
```

Default metrics on `hypothesis_sweep()` if `metrics = NULL`:
`final_n` (mean of last 500 ticks of `n_agents`) and `crashed`
(`tail(n_agents, 1) < 10L`). Default seeds `1:8`. Default
`n_cores = 1L`.

Verdict ladder on `hypothesis_report()`: `|t| ≥ 2` → `"PASS"`,
`1.5 ≤ |t| < 2` → `"marginal"`, else → `"null"`. Welch two-sample
t-statistic from the per-condition variances; `n_ref` / `n_test`
default to the seeds count.

**FOREST.** 13 references across R/, tests/, vignettes/, README,
NEWS. The pair is the canonical research-workflow surface for
paper-* vignettes: every paper-reproduction in `vignettes/paper-*`
uses `hypothesis_sweep()` to cross conditions × seeds and
`hypothesis_report()` to compute Δ ± SE / t / verdict for the
headline contrast. Test coverage before this walk: 5 tests in
`test-hypothesis.R` — 2 of them were Julia-required end-to-end
(skip_if_not(julia_is_ready())), 3 used `fake_sweep` fixtures to
test `hypothesis_report` without Julia. **`hypothesis_sweep`'s
input validation and spec-list construction had no no-Julia
coverage at all.**

**TEST — coverage gap closed (11 new tests).** Extended
`tests/testthat/test-hypothesis.R` from 5 to 16 tests (added 11),
all no-Julia. Coverage:

- **Input validation** (5 tests): rejects non-list `base_specs`,
  empty / unnamed `conditions`, empty `seeds`, unnamed `metrics`.
  Exercises the `stopifnot()` block at `:84-87` and `:100-101`
  that was previously uncovered.
- **Mocked spec-list construction** (3 tests): mocks `batch_alife`
  via `testthat::local_mocked_bindings()` (same pattern as
  `test-batch.R` from item 5), then asserts that
  `hypothesis_sweep()` builds the right `length(conditions) ×
  length(seeds)` spec list with each `random_seed` overridden and
  each condition's overrides correctly applied. Verifies the
  `hypothesis_sweep` S3 class structure has all six documented
  fields (`runs`, `conditions`, `metrics`, `base_specs`,
  `seeds`, `elapsed`).
- **Default metrics** (1 test, no-Julia version of an
  existing Julia-required test): when `metrics = NULL`, the
  output `runs` table has both `final_n` and `crashed` columns.
- **Verdict ladder boundaries** (1 test): builds two synthetic
  contrasts at `|t| ≈ 1.0` and `|t| ≈ 5.0` (using known-SE
  shaped samples) and asserts the verdict ladder returns
  `"null"` and `"PASS"` at the right boundaries. The marginal
  range (`1.5 ≤ |t| < 2`) is hard to nail with synthetic noise
  without making the test brittle, so I skipped explicitly
  testing it — the existing tests cover the PASS and the
  insufficient-seeds paths.
- **Print methods** (2 tests): `print.hypothesis_sweep` prints
  the `<hypothesis_sweep>` header, the run count, and a
  per-condition summary; `print.hypothesis_report` prints the
  `<hypothesis_report>` header naming the metric and the
  rendered table row.

After the additions: 43 expectations pass (the 2 Julia-required
end-to-end tests skip cleanly when Julia isn't ready).

**ROSE.** Two recurring classes and one new (mild) class:

1. **Recurrence (items 5, 7, 8): "convenience wrapper has no
   dedicated test."** Applied here to `hypothesis_sweep`'s
   input-validation surface. Closed with the 5 new validation
   tests + 3 mocked-spec-list tests.
2. **Recurrence (item 5's mock pattern): "function calls a
   Julia-required helper, so the existing tests skip without
   Julia and leave the pure-R logic uncovered."** Same
   `local_mocked_bindings` fix applies cleanly.
3. **New (mild): "two functions encode the same concept with
   different thresholds."** `hypothesis_sweep()`'s default
   `crashed` metric uses `tail(n_agents, 1) < 10L` (absolute,
   hardcoded 10). `viability_report()` (item 6) uses
   `frac_final < crashed_frac = 0.2` (fractional, configurable)
   *plus* `min_n = 20L` (absolute, configurable, gated by the
   0.7.0 bypass). These are *different concepts* — sweep's
   "crashed" answers "did the population effectively go
   extinct?", report's "crashed" answers "is the run
   interpretable?" — but neither docstring acknowledges the
   other. A 2-sentence cross-reference in the
   `hypothesis_sweep()` roxygen would resolve it. Flagging for
   a future doc polish, not shipping here (Karpathy 3,
   surgical).

**BIO.** `hypothesis_sweep()` is research infrastructure: it
operationalises the ≥5-seeds-per-claim discipline (default
`seeds = 1:8`) and the paired-condition contrast pattern. The
`final_n` default metric (mean over last 500 ticks) is
biologically right for "equilibrium population size" — averaging
over the tail smooths transient dynamics. `crashed` at threshold
10 is a soft floor — biologically, "10 agents" on a 30×30 grid
(0.011 density) is approaching extinction; a slightly higher
threshold (e.g., 20 matching `viability_report`'s `min_n`)
would be more conservative. The current value is defensible if
read as "essentially extinct" rather than "unreliable for
inference."

`hypothesis_report()`'s 2σ → PASS / 1.5σ → marginal threshold
ladder is the clade-wide convention (declared in the docstring
as "a screening heuristic, not a formal hypothesis test").
Defensible for behavioural-ecology audits where the publication
target is "directional effect across seeds," not p-values.
Welch's two-sample t with unequal-variance variance is the right
choice for typical N=5–8 per condition.

**Deferred fixes (flagged for separate work):**

- The `crashed` threshold inconsistency (`hypothesis_sweep`'s 10
  vs `viability_report`'s 20+) deserves a cross-reference in
  the docstring. One sentence per function. Not blocking.
- `summary_hypothesis_sweep()` (the internal helper at
  `R/hypothesis.R:177`) was not exported and is not directly
  tested, only via `print.hypothesis_sweep` which calls it. If
  it stays internal, that's fine; if it's worth promoting to
  `summary.hypothesis_sweep` (the S3 generic), that's a
  separate small refactor.
- `hypothesis_report()` reports a Welch t-statistic but does
  not currently surface degrees of freedom. For honest reporting,
  the `df` column would help. Cosmetic; not worth a commit.
- No `vignettes/basics.Rmd` change. Section 5 already points to
  paper-* vignettes which use the sweep/report pair.
