# Check Log

This is an append-only log for validation evidence, handoff notes, and
important project state. Keep entries concise and concrete.

## 2026-06-08 - Sex foundation (0.8.0 first slice)

- Branch: `claude/sex-mating-system` (off `main` at `9af0fa4`).
- Goal: Ship persistent sex identity on agents (sticky `Agent.sex`,
  three new specs, opposite-sex mate filter, role-contract decoupling)
  as the foundation for the Rees-Baylis 2026 paper-reproduction work.
- Files changed:
  - Kernel: `inst/julia/src/types.jl`, `inst/julia/src/reproduce.jl`,
    `inst/julia/src/Clade.jl`.
  - R: `R/config.R`, `R/utils.R`.
  - Tests / vignette: `tests/testthat/test-sex-labels.R` (new),
    `vignettes/s-sex-labels.Rmd` (new).
  - Docs: `NEWS.md`, `man/default_specs.Rd` (regenerated),
    `dev/dev-log/decisions.md`, `dev/dev-log/after-task/2026-06-08-sex-foundation.md`.
  - Env fix: `inst/julia/Manifest.toml` (pre-existing Statistics
    v1.11.1 / Julia 1.10 mismatch; resolved to v1.10.0).
- Checks run:
  - `Rscript -e 'devtools::load_all(); print specs'`: three new
    specs visible at expected defaults (`sex_labels = FALSE`,
    `sex_determination = "random"`, `sex_ratio_primary = 0.5`).
  - `Rscript -e 'devtools::document()'`: clean; `man/default_specs.Rd`
    regenerated with the new Sex foundation `\describe{}` block.
  - `testthat::test_file("test-sex-labels.R")`: **21 PASS, 0 FAIL, 0 SKIP** (Julia available).
  - `testthat::test_file("test-spec-wiring.R")`: 2 PASS — all three
    new specs consumed in `inst/julia/src/*.jl` (no allowlist needed).
  - `testthat::test_file("test-no-internal-leaks.R")`: 1 PASS —
    after scrubbing two `Phase A` / `Phase B` tokens from the roxygen
    and vignette prose.
  - `testthat::test_file("test-default-specs-docstring-coverage.R")`: 14 PASS.
  - `testthat::test_file("test-vignette-field-references.R")`: 1 PASS.
  - `devtools::test()` full pass: see after-task report for the
    final tally (running at time of this entry; partial output shows
    aging-rate, analysis, ann, bad-science, batch, biological-calibration,
    body-size, brain-size-evolution, brains, calibration-harness,
    cell-occupancy, clutch-size, complex-landscape, config,
    cooperative-breeding, default-specs-docstring-coverage,
    dispersal, ..., search, seasons, sense-env, sex-labels (21 PASS),
    signals-matechoice, spatial-sorting, spec-groups-coverage,
    spec-wiring, speciation, specs, stream-submit, test-default-value-assertions,
    test-field-assertions, tick-order all clean or with pre-existing
    warnings only).
- Stale-claim searches:
  - `rg -nE 'Phase [AB]\b|Sergio|v0\.8-core|CLAUDE\.md|Tier [AB][0-5]?\b|PR #[0-9]+'`
    over `vignettes/s-sex-labels.Rmd`, `R/config.R`, `R/utils.R`,
    `inst/julia/src/types.jl`, `inst/julia/src/reproduce.jl`,
    `inst/julia/src/Clade.jl`: only one match each in
    `R/config.R` line 1611 (plain code comment, exempt from leak
    test) and `inst/julia/src/Clade.jl` (Julia error message,
    subsequently rephrased to "in the 0.8.0 sex foundation release").
- Final full-test pass: ran `devtools::test()` after fixing two
  formerly-missed `Agent(...)` constructor sites in
  `inst/julia/src/modules/tick_predators.jl` (`seed_predators!` at
  line 85 and the offspring constructor at line 471 — both needed
  the new trailing `Int8(0)` sex argument). Single residual failure:
  `test-pace-of-life.R:48` — `expect_gt(d_steep, d_flat, info =
  sprintf(...))` raises "unused argument (info = ...)" when the
  comparison fails. The underlying senescence-shape comparison is a
  fragile small-population run that sometimes crashes under full
  `devtools::test()` ordering (two warnings 16/17 in the same run
  show both `run_one()` calls crashed with `n_final = 0`,
  triggering `d_steep = d_flat = 0`). Pre-existing fragility, not
  caused by sex-foundation changes — verified:
  - On my branch in isolation: 12 PASS, 0 FAIL, 2 WARN.
  - On `main` (stashed) in isolation with `NOT_CRAN = "true"`: 10
    PASS, 0 FAIL, 0 SKIP.
  - In the pre-fix full run on my branch the same failure appeared
    as one of the 10 (alongside 9 predator constructor errors).
  - The `info =` argument to `expect_gt` was removed from testthat's
    public API in 3.x; using a non-fatal `label =` argument or
    dropping it is the appropriate fix, but that change belongs in a
    separate small PR and not in the sex-foundation diff.
- Not run:
  - Full re-run of `dev/audit/fidelity/*.R` scripts. The kernel
    changes are guarded by `sex_labels = FALSE` (control-flow no-op);
    the unit test suite covers the active code paths. If a cached
    `.rds` regression surfaces later, the affected
    `dev/audit/fidelity/<name>.R` script can be re-run on demand.
  - `devtools::check()` and `pkgdown::build_site()` — local sanity
    pass deferred. Recommend running before opening a PR for review.
- Next safest action: commit the branch in focused chunks (kernel,
  R API, tests + vignette, docs, Julia env refresh) and either open
  a draft PR for visibility / Sergio coordination or stop here for
  user review.

## 2026-06-08 - Sex-specific trait expression + mating-system module + Rees-Baylis 2026 paper reproduction

- Branch: `claude/sex-mating-system` (continues from the
  sex-foundation slice on the same branch).
- Goal: ship the remaining two layers of the sex / mating-system
  subsystem and the validating Rees-Baylis 2026 paper-reproduction
  vignette in one branch.
- Files changed (highlights — see after-task report at
  [dev/dev-log/after-task/2026-06-08-sex-mating-subsystem.md](https://github.com/itchyshin/clade/blob/main/dev/dev-log/after-task/2026-06-08-sex-mating-subsystem.md)
  for the full table): kernel changes in `types.jl`, `genome.jl`,
  `reproduce.jl`, `Clade.jl`, `modules/tick_predators.jl`; R-side in
  `R/config.R`, `R/utils.R`; tests in `test-sex-specific-traits.R`
  and `test-pair-bonds.R`; vignettes
  `paper-rees-baylis-2026.Rmd` and `s-pair-bonds.Rmd`.
- Checks run (final targeted pass after all Phase C edits):
  - 14 test files × `testthat::test_file()`: **195 PASS / 0 FAIL /
    2 SKIP** total. Includes all three sex-related test files
    (21 + 15 + 15 PASS) and the four structural guards
    (`test-spec-wiring.R`, `test-no-internal-leaks.R`,
    `test-default-specs-docstring-coverage.R`,
    `test-spec-groups-coverage.R`) all green.
  - `devtools::document()` clean.
- Stale-claim searches:
  - `rg -nE 'Phase [AB]\b|Sergio|v0\.8-core|CLAUDE\.md|Tier [AB][0-5]?\b|PR #[0-9]+'`
    over the new vignettes, R/config.R, and inst/julia/src/*.jl:
    only matches are in plain code comments or Julia error messages
    (both exempt from the leak guard).
- Not run:
  - Full `devtools::test()` after Phase C — targeted pass exercises
    every file at risk; recommend before opening a PR.
  - `devtools::check()` and `pkgdown::build_site()` — recommend
    before opening a PR.
  - Full multi-seed sweep of `paper-rees-baylis-2026.Rmd`'s Stage 2
    — chunks are gated `eval = FALSE` pending the
    `aging_rate ↔ M_i` calibration follow-up. Vignette documents
    the workflow and the calibration gap.
- Next safest action: commit Phase C in focused chunks
  (kernel-trait, kernel-mating, R-specs, tests + vignettes, docs),
  recommend `devtools::check()` before opening a PR, and either push
  + open draft PR or stop here for user review.



## Template

```md
## YYYY-MM-DD - <short task title>

- Branch: `<branch>`
- Goal: <one sentence>
- Files changed: `<path>`, `<path>`
- Checks run:
  - `<command>`: <exact outcome>
  - `<command>`: <exact outcome>
- Stale-claim searches:
  - `<rg pattern>` over `<paths>`: <outcome>
- Not run: <commands or checks skipped, with reason>
- Next safest action: <one sentence>
```

## 2026-05-16 - Install Agent Operating Kit (drmTMB-kit, adapted for clade)

- Branch: `claude/track-B-kit-install` (off `main` at `2d364a1`).
- Goal: Install the drmTMB-derived agent operating kit, adapted for clade's
  R+Julia split, lab values, and Sergio's parallel kernel-review track. Establish
  the canonical AGENTS.md, vision doc, after-task protocol, check-log discipline,
  and local skills before starting the Track B R-API walk planned in
  `~/.claude/plans/purring-honking-dove.md`.
- Files changed (five commits, oldest first):
  - `d706e0c chore(agent-kit): install scaffolding (step 1 of 5)` — copied
    kit templates with `<PROJECT>` → `clade`, moved `docs/` → `dev/` to fit
    clade's existing convention (clade's `/docs/` is gitignored for pkgdown
    output), updated all internal cross-references.
  - `98723e8 docs(vision): fill in clade vision doc (step 2 of 5)` —
    `dev/design/00-vision.md` with purpose + 6 user categories + 4 lab
    values (transparency / reproducibility / accessibility / inclusiveness) +
    4 differentiators (R-Julia speed; evolvable worlds for mechanism AND
    climate prediction; paper-reproduction-driven structure; MATLAB-ancestor
    lineage) + 16-row Core Contracts table + evidence-standard rules tied
    back to values.
  - `984dcaf docs(agents): adapt AGENTS.md + reduce CLAUDE.md to a stub
    (step 3 of 5)` — created canonical AGENTS.md by merging current CLAUDE.md
    content (Karpathy 4 principles, repo map, conventions, resource limits)
    with kit template (design rules, standing roles, after-task pointer)
    plus clade-specific R+Julia split and Sergio's parallel-track flag.
    CLAUDE.md reduced to one-paragraph stub pointing at AGENTS.md.
    Standing roles narrowed to 6: Ada, Gauss, Noether, Fisher, Pat, Rose.
  - `ab89ee7 docs(after-task): absorb AFTER_TASK.md into
    dev/design/10-after-task-protocol.md (step 4 of 5)` — migrated the
    clade-specific work discipline (two-people framing, 5-step checklist,
    biology consistency, Do-NOT list, "don't start next task until user
    confirms") into the kit's after-task-protocol file. Root-level
    AFTER_TASK.md deleted.
  - (this commit) `step 5 of 5`: first real check-log entry.
- Files NOT changed: no R source, no Julia source, no tests, no vignettes,
  no `inst/`. This is documentation-discipline installation only.
- Checks run:
  - `git status --short --branch`: clean working tree on
    `claude/track-B-kit-install`.
  - `grep -rn "<PROJECT>" docs/ .agents/ MEMORY.seed.md`: no remaining
    placeholders (substitution succeeded in step 1).
  - `grep -rn "docs/design\|docs/dev-log" dev/ .agents/ MEMORY.seed.md`: no
    remaining `docs/` references (path migration succeeded in step 1).
- Stale-claim searches:
  - `rg "AFTER_TASK" -- R/ tests/ vignettes/ dev/ inst/`: only references in
    its absorbed migration commit; no orphaned mentions outside the new
    `dev/design/10-after-task-protocol.md` location.
- Not run:
  - `devtools::check()`: setup-only change; no R or Julia code touched.
  - `devtools::test()`: setup-only change.
  - `pkgdown::build_site()`: setup-only change; the new docs are in `dev/`
    (intentionally not part of pkgdown's article tree).
- Next safest action: open PR `feat(agent-kit): adopt drmTMB-derived
  operating kit (adapted for clade)`, merge to main, then start Phase A
  item 1 (`default_specs()` walk) on a fresh `claude/track-B-walk` branch
  off the new main, with after-task report under `dev/dev-log/after-task/`.

## 2026-05-16 - Phase A drift-guard sweep

- Branch: `claude/drift-guard-sweep` (off `main` at `47c2fe4`, post
  Tier-A0 PR #128 merge).
- Goal: ship the structural fix for the Rose class that recurred across
  Phase A items 1, 2, 3, and 6: "API or default change leaves stale
  assertions/fixtures in tests." Three commits.
- Files changed:
  - `tests/testthat/test-spec-groups-coverage.R` (new, +51) — ghost +
    orphan bijection check for `.SPEC_GROUPS` ⇔ `default_specs()`.
  - `tests/testthat/test-life-history.R` (-32) — removed 4 stale
    assertions on `repro_senescence` / `life_history_evolution` (deleted
    by PR #114); updated `senescence_shape` 2.0→1.0 (same bug as
    test-config.R fixed in item 1); refreshed file header.
  - `tests/testthat/test-parental-investment.R` (-14) — removed 4 stale
    assertions on `parental_investment_init_mean` (deleted by PR #114);
    refreshed file header.
  - `tests/testthat/test-test-field-assertions.R` (new, +171) — drift
    guard scanning `expect_true("<x>" %in% names(default_specs()))`
    (direct) and per-test_that indirect patterns; deliberately ignores
    `expect_false(...)` absence assertions. Three tests-of-the-test
    self-checks on synthetic fixtures.
- Checks run:
  - `test_file("test-spec-groups-coverage.R")`: 2 pass.
  - `test_file("test-test-field-assertions.R")`: 8 pass.
  - `test_file("test-life-history.R")`: 22 pass (Julia errors observed
    are pre-existing manifest-resolved warnings on edits and un-edited
    state alike).
  - `test_file("test-parental-investment.R")`: 17 pass (same Julia
    note).
  - Existing structural drift guards (`test-spec-wiring.R`,
    `test-version-strings.R`, `test-readme-flag-names.R`,
    `test-pkgdown-consistency.R`, `test-config.R`, `test-specs.R`):
    all green.
- Stale-claim searches:
  - `rg "repro_senescence|life_history_evolution|parental_investment_init_mean"
     tests/testthat/test-life-history.R tests/testthat/test-parental-investment.R`:
    only references remaining are in comments documenting the removal.
  - `rg "max_carried" tests/testthat/test-parental-care.R`: surviving
    reference is the correct `expect_false(...)` absence assertion at
    line 118 — kept by design.
- Not run:
  - Full `devtools::check()` / `devtools::test()`: skipped to keep the
    drift-guard sweep scoped. Per-file `test_file` runs cover the
    affected files exhaustively. PR #128's CI already passed on the
    main-merged Tier-A0 baseline.
- Next safest action: open PR `Phase A drift-guard sweep: SPEC_GROUPS
  bijection + stale-assertion cleanup + scan`, wait for CI, merge; then
  rebase `claude/track-B-walk` (carries Phase A items 5 e701d21 + 6
  23946d3) onto the new main and continue with item 7 (`print_specs()`).

## 2026-08-05 - Remove dead predators from the live population

- Branch: `codex/remove-dead-predators`, from `origin/main` at `45a27e3`
  (`feat(julia): normalize partial specs with native defaults (#173)`).
- Goal: ensure predators that die during `tick_predators!()` are removed
  before reproduction and do not prevent the #165 extinction guard from
  observing total extinction.
- Files changed:
  - `inst/julia/src/modules/tick_predators.jl`: filters dead predators before
    rebuilding `predator_map` and calling predator reproduction.
  - `inst/julia/test/runtests.jl`: adds a one-tick zero-prey case where the
    seeded predator loses more energy than it has and must be absent from the
    result.
  - `dev/dev-log/after-task/2026-08-05-remove-dead-predators.md`: task record.
- Checks run:
  - `git diff --check`: pass.
  - static call-site review: predator-map reconstruction and predator
    reproduction follow the new filter; no reseeding occurs after tick 1.
- Stale-claim searches:
  - `rg -n -C 2 'filter!\\(.*alive|predator_map|env\\.predators'
    inst/julia/src/modules/tick_predators.jl inst/julia/src/death.jl
    inst/julia/src/Clade.jl`: agents were filtered but predators were not;
    the new filter is immediately before map rebuild and reproduction.
  - `rg -n -i 'dead predators|remove.*predator|predator.*die|population
    extinct' README.md NEWS.md vignettes dev R tests inst/julia/test`: no
    public wording promises the former stale-predator behaviour.
- Not run:
  - `julia --project=inst/julia ...`: Julia is not installed or on `PATH` in
    this Codex environment. The focused runtime test must run in CI or a
    Julia-equipped checkout before merge.
  - R tests and `devtools::check()`: no R code changed.
- Next safest action: open this focused cleanup PR, then rebase #177 onto the
  two small predecessor fixes and rerun all #165 scenarios.

## 2026-08-05 - Predator-only max-age fallback

- Branch: `codex/fix-predators-only`, from `origin/main` at `45a27e3`
  (`feat(julia): normalize partial specs with native defaults (#173)`).
- Goal: fix the Julia crash in a predators-only run when the documented
  `predator_max_age = nothing` / R `NA` default means “use prey max_age”.
- Files changed:
  - `inst/julia/src/modules/tick_predators.jl`: explicitly coalesce an
    absent or `nothing` predator maximum age to `max_age` before `Int32`
    conversion.
  - `inst/julia/test/runtests.jl`: adds a one-tick, no-prey, one-predator
    regression test before the legacy testsets.
  - `dev/dev-log/after-task/2026-08-05-predator-only-max-age-fallback.md`:
    task record.
- Checks run:
  - `git diff --check`: pass.
  - source inspection confirms the former `Int32(get(...))` converted the
    explicit `nothing` Julia default, matching the `Int32(::Nothing)` trace
    reported on issue #165.
- Stale-claim searches:
  - `rg -n -i 'predator_max_age|predators.*prey|predators-only|no prey'
    README.md NEWS.md vignettes dev R tests inst/julia/test`: the public R
    contract consistently states that `NA` means the prey maximum age.
  - `rg -n -C 2 'predator_max_age.*nothing|Int32\\(get\\(specs, "[^\"]+"'
    inst/julia/src`: this explicit-`nothing` conversion was the relevant
    direct instance.
- Not run:
  - `julia --project=inst/julia ...`: Julia is not installed or on `PATH`
    in this Codex environment. The focused runtime test must run in CI or a
    Julia-equipped checkout before merge.
  - R tests and `devtools::check()`: no R code changed.
- Next safest action: open the focused PR, then repair #177 separately so it
  covers predators that die after initialization as well as an initially empty
  predator population.

## 2026-09-27 - Movement-logging defaults in default_specs()

- Branch: `fix/log-movement-freq-default` (off `main` at `6797b53`).
- Goal: Fix the bug Bhavya reported on #167: setting only
  `specs$log_movement = TRUE` stopped the run with a Julia `KeyError`
  for `log_movement_freq`.
- Cause: `run_clade()` validated the frequency with
  `get(specs, "log_movement_freq", 1)`, but `log_movement!()` read
  `env.specs["log_movement_freq"]` with no fallback, and
  `default_specs()` supplied neither key.
- Files changed: `R/config.R`, `R/utils.R` (`.SPEC_GROUPS`),
  `man/default_specs.Rd`, `inst/julia/src/logging.jl`,
  `inst/julia/test/runtests.jl`, `tests/testthat/test-movement.R`,
  `NEWS.md`, this log, and
  `dev/dev-log/after-task/2026-09-27-log-movement-freq-default.md`.
- Checks run:
  - Julia repro script (`log_movement = true`, no frequency): `KeyError`
    before the fix; ticks `1, 2, 3` recorded after it.
  - Julia `test/runtests.jl`: "Movement Logging Contract (#176)" 17/17
    pass, including the new no-frequency case. The suite as a whole
    still reports 1 fail and 2 errors (ANN regularization, Lamarckian
    genome update); the same three appear on unchanged `main`.
  - `devtools::document()`: `man/default_specs.Rd` regenerated.
  - `devtools::test()`: FAIL 0, PASS 1093, SKIP 648. JuliaConnectoR is
    not installed in this R library, so Julia-gated R tests (including
    the new end-to-end one) were skipped.
- Next safest action: run the Julia-gated R tests on a machine with
  JuliaConnectoR, then merge. Separately triage the three pre-existing
  Julia failures.

## 2026-09-27 - grass_growth_mode toggle and grass_density column

- Branch: `feat/grass-growth-mode` (off `main` at `e008b85`).
- Goal: Answer #167 (Bhavya, Sergio): offer A-life's deterministic grass
  regrowth, `min(grass + rate, gmax)`, as an opt-in mode, and add a
  grass measure that does not saturate under it.
- Files changed: `inst/julia/src/Clade.jl` (`grow_grass!`, new
  `_grown_cell`), `inst/julia/src/defaults.jl`,
  `inst/julia/src/logging.jl`, `R/config.R`, `R/run.R`, `R/utils.R`,
  `R/search.R`, `R/analysis.R`, `man/default_specs.Rd`,
  `man/get_run_data.Rd`, `inst/julia/test/runtests.jl`,
  `tests/testthat/test-grass-growth-mode.R` (new), `NEWS.md`, this log,
  and `dev/dev-log/after-task/2026-09-27-grass-growth-mode.md`.
- Checks run:
  - Julia `test/runtests.jl`: "Grass growth mode (#167)" 12/12,
    movement contract 15/15. The same three pre-existing failures as
    on `main` (ANN regularization, Lamarckian) remain.
  - Seeded parity against `main` (`e008b85` worktree): progress tables
    and agents identical over 60 ticks for the default, niche
    construction, and seasonal spatial bias branches.
  - `devtools::document()`: `default_specs.Rd`, `get_run_data.Rd`.
  - `devtools::test()`: FAIL 0, PASS 1095, SKIP 648 (JuliaConnectoR
    not installed; Julia-gated R tests skipped).
  - Indicative comparison, 5 seeds x 300 ticks, default specs: tick 1
    coverage 0.52 stochastic vs 0.97 deterministic, density 0.48 in
    both; ticks 201 to 300 density 0.28 vs 0.25, mean `n_agents` 47 vs
    52. Not a calibrated result.
- Next safest action: merge when green; Sergio and Shinichi decide
  whether deterministic should become the default.

## 2026-09-27 - last_action contract for behavioural diversity (#164)

- Branch: `claude/behavioral-diversity-actions` (off `main` at
  `595069f`), carrying Bhavya's two #179 commits (authorship kept).
- Goal: implement the recording contract agreed on #164 before any
  metric or R API: code 0 only for "no action yet", death stays
  `alive = false`, every real decision path updates `last_action`.
- Encoding: the brain's output index. 0 = no action yet, 1 = N, 2 = E,
  3 = S, 4 = W, 5 = stay (idle for prey, stay-and-attack for predators).
  Eat and reproduce are automatic in clade, not decisions, so the
  8-code proposal on #164 was reduced to these six.
- Files changed: `inst/julia/src/types.jl`, `inst/julia/src/tick.jl`,
  `inst/julia/src/modules/tick_predators.jl`, `inst/julia/src/Clade.jl`,
  `inst/julia/src/reproduce.jl` (constructors start at 0, not 5),
  `inst/julia/test/runtests.jl`, this log, and
  `dev/dev-log/after-task/2026-09-27-last-action-contract.md`.
- Checks run:
  - Julia "last_action contract (#164)" 24/24: founders 0; each code
    1 to 5 recorded with the matching move; blocked move records intent;
    offspring 0; predator founders 0, chosen codes recorded, predator
    offspring 0. Same three pre-existing failures as `main` remain.
  - Seeded parity against `main` (`595069f` worktree), 60 ticks:
    identical progress tables and agents (excluding the new field) for
    default, predators, niche construction, seasonal spatial bias.
  - Test order fix: the new testset sits before "Clade Julia unit
    tests". That block fails on `main` and aborts the script, so any
    testset after it (including the #179 placeholder) never ran.
- Next safest action: review; then design the metric and R extraction.

## 2026-09-27 - Warn on unknown spec names (R and Julia)

- Branch: `fix/warn-unknown-spec-keys` (off `main` at `b8bfe34`).
- Goal: stop unknown spec keys passing silently. Trigger: #185 sampled
  `repro_threshold` in 500 DRAC runs; the kernel never reads it (the
  spec is `min_repro_energy`), so one design axis was a no-op.
- Files changed: `inst/julia/src/defaults.jl` (warning in
  `normalize_specs`, name hint, `log_movement` and `log_movement_freq`
  defaults), `R/run.R` (`.validate_specs` warning),
  `inst/julia/test/runtests.jl`, `tests/testthat/test-unknown-specs.R`
  (new), `tests/testthat/test-scenario-signals.R`, `NEWS.md`, this log,
  `dev/dev-log/after-task/2026-09-27-warn-unknown-spec-keys.md`.
- R vs Julia defaults: R had `log_movement` and `log_movement_freq`
  that Julia lacked (added); Julia has no names R lacks. All nine
  zero-argument presets use only default names.
- Checks run:
  - Julia `test/runtests.jl`: "Unknown spec keys warn (#185)" 8/8;
    movement contract 19/19 (2 new no-births checks); grass 12/12;
    last_action 24/24. The three pre-existing failures on `main` remain.
  - Test of the new no-births check: `min_repro_energy = 10` gives 7
    births in the parity setup, 9999 gives 0.
  - `devtools::test()`: FAIL 0, WARN 0, PASS 1109, SKIP 649
    (JuliaConnectoR not installed).
  - Speciation test settings run directly in Julia (`speciation = true`,
    80 ticks, 60 agents): completes, `n_species` 0 to 1.
- Next safest action: review; Julia-gated R tests on a Julia machine.

## 2026-09-27 - Repair the three failing Julia unit tests

- Branch: `fix/julia-unit-test-failures` (off `main` at `9f047a6`).
- Goal: make `inst/julia/test/runtests.jl` pass end to end. The
  "Clade Julia unit tests" block failed on `main` and, because a failing
  top-level testset aborts the script, hid anything placed after it.
- Root causes (all in the tests; source code unchanged):
  - `test_ann_regularization.jl`: asserted `sum(|w|) > n_nonzero` for
    standard-normal weights on the premise that mean |w| > 1. It is
    sqrt(2/pi) ~ 0.80, so the claim is false (observed 54.4 vs 67).
  - `test_lamarckian.jl` (2 tests): `DiploidGenome` gained
    `n_chromosomes` after the test was written; behind that error, the
    test also used an `Agent` keyword constructor that does not exist.
- Fixes: the ANN test now checks both measures against an independent
  computation at three weight scales and asserts the direction only
  where it is true (x3: magnitude > count; x0.3: magnitude < count).
  The Lamarckian tests take a real haploid ANN agent from
  `create_environment()` and replace only `brain` and `genome`, the two
  fields `lamarck_genome_update!` reads.
- Checks run:
  - Julia `test/runtests.jl`: all testsets pass, exit code 0 (unit
    block 19/19).
  - Mutation checks: making `lamarck_genome_update!` a no-op fails the
    write-back test; dropping biases from `_ann_weight_magnitude` fails
    4 assertions.
  - R code untouched; R suite not rerun.
- Finding: no CI workflow runs the Julia suite (`tests.yaml` skips
  Julia; `fidelity-matrix.yaml` runs paper scripts), which is how these
  failures went unnoticed.
- Next safest action: review; consider a PR-triggered Linux job for
  `runtests.jl`.

## 2026-09-27 - julia-tests CI workflow

- Branch: `ci/julia-tests`.
- Goal: run `inst/julia/test/runtests.jl` on pull requests. No workflow
  ran it before (`tests.yaml` skips Julia; `fidelity-matrix.yaml` runs
  paper scripts), which is how three unit tests broke unnoticed (#192).
- File: `.github/workflows/julia-tests.yaml`. Triggers:
  `workflow_dispatch`, and `pull_request` only when `inst/julia/**` or
  the workflow file changes. `ubuntu-latest`, Julia 1.10 (the manifest's
  minor version), `julia-actions/cache`, 20-minute timeout, PR-scoped
  `cancel-in-progress`, threads capped.
- Checks run:
  - YAML parses (actionlint not installed locally).
  - Local dry run from an empty depot (`JULIA_DEPOT_PATH` fresh):
    `Pkg.instantiate()` + precompile 18 s, test suite 20 s. On `main`
    before #192 the suite exits 1, so the job fails when tests fail.
  - The job's first real run is on this PR itself.
- Next safest action: confirm the first run is green, then decide
  whether to make `julia-tests` a required check (a settings change).

## 2026-10-18 - Grass density in plot_run (#167)

- Branch: codex/grass-dashboard-density, isolated from the dirty main checkout.
- Keep stochastic grass growth as the default. Plot both recorded coverage
  and density in the existing grass panel, with older-data coverage fallback.
- Files: R/visualization.R, tests/testthat/test-visualization.R,
  generated man/plot_run.Rd, NEWS.md, after-task report.
- Rscript -e 'devtools::document(); devtools::test(filter="^visualization$")':
  visualization PASS 47, FAIL 0, WARN 0, SKIP 0. Documentation regenerated;
  existing missing-JuliaConnectoR reference messages remain.
- Rscript -e 'devtools::test(reporter="summary")': exit 0, no reported
  failures; 649 skipped tests, predominantly JuliaConnectoR unavailable.
- New density test failed three assertions before implementation.
- git diff --check passed. Searched plot_run and grass_coverage in
  tests/testthat/test-visualization.R; inspected callers through graft.
- Kernel unchanged; no simulation, full package check or site build run.
- Next: review focused PR; Bhavya retains corrected #185 sampling rerun.

## 2026-11-08 - Codecov first pass (R + Julia existing suites, OIDC)

- Branch: `cursor/codecov-first-pass-8e02` off `main` at
  `b1f7934ab9238b2731d7451c9d74f580d2d748f8`.
- Goal: honest existing-suite coverage for R and Julia in this
  repository, language flags, one uploader, documented OIDC least
  privilege. No scientific src/tests/fixtures changes. No merge.
- Files changed: `.github/workflows/coverage.yaml` (new),
  `.github/codecov.yml` (new), `.github/coverage.md` (new),
  `.gitignore`, `AGENTS.md`, `dev/dev-log/decisions.md`, this log,
  `dev/dev-log/after-task/2026-11-08-codecov-first-pass.md`.
- Unchanged on purpose: `.github/workflows/tests.yaml`,
  `julia-tests.yaml`, `R-CMD-check.yaml`, `fidelity-matrix.yaml`,
  `pkgdown.yaml`, `R/`, `inst/julia/`, `tests/`, `vignettes/`.
- Layout: both languages live here (`R/` + `inst/julia/`). pigauto
  and GLLVModels were not opened.
- Checks run:
  - `python3` PyYAML load of `coverage.yaml`, `codecov.yml`, and the
    five existing workflows: parse OK. Coverage jobs: `use_oidc: true`,
    no `token` input, flags `r` / `julia`, `disable_search: true`,
    checkout has no `ref:` override.
  - `git diff --check`: clean.
  - `git diff -- .github/workflows/tests.yaml` (and the other four
    existing workflows): empty.
- Stale-claim searches:
  - `rg -n 'CODECOV_TOKEN|token:.*GITHUB_TOKEN' .github AGENTS.md`:
    comments only; codecov-action steps have no `token:` key.
  - `rg -n 'covr::codecov|Codecov.submit' .github AGENTS.md`:
    prohibition comments only.
  - `rg -n 'codecov.io/.*/badge' README.md AGENTS.md .github`: no
    matches.
  - `rg -n '^ignore:|file_exclusions|line_exclusions' .github`: no
    matches.
- Not run (runtimes unavailable in this environment):
  - `Rscript` / `covr::package_coverage()` — Rscript not on PATH.
  - `julia --project=inst/julia --code-coverage=user inst/julia/test/runtests.jl`
    — julia not on PATH.
  - `actionlint` — not installed.
  - Codecov upload reception, processed report, default-main baseline.
- Next safest action: open the PR, let CI run, subscribe for
  evidence-only wakes. Do not merge. Coordinator before any further
  edit. If codecov-action logs a real OIDC/upload failure, the owner
  may grant App OIDC or a dedicated Codecov token; dashboard
  Configure/API unknown is not that proof.

## 2026-11-08 - Codecov r-coverage: use source-tree test_dir

- Branch: `cursor/codecov-first-pass-8e02` (follow-up on PR #195).
- CI wake on `bf4478c08a74def326151820fec9acc4cd4d5577`: 1 of 4
  checks failed (`r-coverage`). `tests`, `R-CMD-check`, and
  `julia-coverage` passed.
- Checkout identity (both coverage jobs):
  `checkout_kind=synthetic-merge`, `tested_equals_exact_head=false`,
  `git_HEAD=8623234881d0821ab00072acedc35f1886dee36d`,
  `pr_head_sha=bf4478c08a74def326151820fec9acc4cd4d5577`,
  `pr_base_sha=b1f7934ab9238b2731d7451c9d74f580d2d748f8`.
- Julia stage 2: `percent_coverage=39.2507` (`lines_hit=1320` /
  `lines_found=3363`). Artifact `coverage-julia` id `13636388950`.
- Julia stage 3: OIDC token minted (`Get OIDC token` success).
  codecov-action tagged the upload to exact head `bf4478c` (not the
  merge SHA). HTTP 200, queued:
  https://app.codecov.io/github/itchyshin/clade/commit/bf4478c08a74def326151820fec9acc4cd4d5577
  Not a processed-report claim. No owner token used.
- R stage 2 failed before percent/artifact/upload. Default
  `covr::package_coverage()` ran installed `testthat.R` /
  `test_check()`. FAIL 2 / SKIP 650 / PASS 1109:
  `test-vignette-field-references.R` and
  `test-no-internal-leaks.R` — `unlist(lapply(...))` is `NULL` when
  `vignettes/*.Rmd` are absent from the temp install, vs
  `character(0)` on the source tree. `tests.yaml` (`devtools::test()`)
  passed the same commit. Not a scientific-test defect; not an OIDC
  failure.
- Fix (CI only): `type = "none"` plus `library(clade)` and
  `testthat::test_dir("tests/testthat")` from the checkout. Do not
  call `devtools::test()` inside covr (`load_all()` drops traces).
  Tests and Julia source untouched.
- Next safest action: push, let CI run, subscribe wake. Do not merge.
  Do not add a Codecov token.

## 2026-11-08 - Codecov r-coverage: root cause of the `test_dir` failure; run with package namespace

- Branch: `cursor/codecov-first-pass-8e02` (PR #195, follow-up on
  `196373c`). CI-only change; tests and `inst/julia/src/` untouched.
- Failure on `196373c` (run 42529873753, job 128881480156): covr
  `Failure in .../clade-commands.Rout.fail`; the log hides the test
  output. Reproduced locally (R 4.3.3, same env vars): bare
  `testthat::test_dir("tests/testthat")` (no `package=`) after
  `library(clade)` errors in `test-stream-submit.R` (5 errors,
  `local_mocked_bindings()` -> `dev_package()`: "No packages loaded
  with pkgload"). Cause: the previous fix dropped the package
  namespace, i.e. not equivalent to `test_check()` or `devtools::test()`.
- Default `covr::package_coverage()` (`test_check()` from the install)
  failed 2 tests on `bf4478c` (run 42529230191): `.find_repo_root()` in
  `test-vignette-field-references.R` / `test-no-internal-leaks.R`
  resolves to the installed package dir (has DESCRIPTION, R, tests) with
  no `vignettes/`. Source-tree assumption in tests, not a kernel bug.
- Fix: `test_dir("tests/testthat", package = "clade",
  load_package = "installed", stop_on_failure = FALSE)` inside the covr
  `code`, then write per-test CSV + SummaryReporter log, then `stop()`
  on any failed/error. This is test_check()'s namespace/install setting
  run from the checkout.
- Equivalence evidence (local, `CLADE_SKIP_JULIA_TESTS=true`):
  `devtools::test()` vs covr run: 1158 tests / 1763 expectations /
  0 failed / 648 skipped / 0 errors / 0 warnings in both;
  per-test `file,test,nb,failed,skipped,error,warning` tables
  `all.equal` TRUE. covr `percent_coverage=61.9490`.
- Negative control: a temporary failing test in a scratch copy made the
  step exit 1 (`testthat failures under coverage`).
- Not run: CI (pending push), Julia-enabled tests.
- Next safest action: push, confirm `r-coverage` and all PR checks.
  Do not merge. Do not add a Codecov token.

## 2026-11-14: Weighted directional sensing and exact R snapshots

- Branch: codex/weighted-directional-sensing; resolves #120.
- Added sense_mode to R/Julia defaults and spec groups; per_cell remains
  default. Weighted channels sum value/distance. Updated Core Contract and
  decisions; generated help with devtools::document.
- Corrected predator bounded-grid lookup. New run results return exact final
  sensory snapshots; R sense_env reads them without a per-tick bridge.
- Julia suite: exit 0, 174 assertions pass. Live R snapshot 14 pass and schema
  2 pass, no skips. Portable R suite exit 0, 644 Julia skips, no failures or
  warnings. Five-seed default source parity: 10 equality checks pass.
- Tests of tests: four invalid-radius checks failed before validation.
  Independent review identified and verified optional tails, boundaries,
  graded predator weighting and the misleading R legacy reconstruction.
- Searches: sense_mode|input_radius|sense_env|_compute_n_inputs across source,
  tests/help/design. Default schema count checked in R: 312.
- Limits: no biological calibration/full MATLAB parity or performance study.
  Legacy serialized environments retain a documented approximate fallback.
- Report: after-task/2026-11-14-directional-sensing.md.
- Next: integrate current main, rerun affected tests, open focused PR.


## 2026-11-14: Kernel ownership and mutation-path decision

- Branch: codex/kernel-maintenance-decisions, main d012fe0.
- Goal: record Shinichi's ownership correction and resolve #111's mutation
  duplication question using current source.
- Changed AGENTS.md and added dev/design/mutation-paths.md; decision and
  after-task records explain why the two mutation paths remain separate.
- Reviewed meiosis calls in genome.jl, predator reproduction in
  modules/tick_predators.jl, and mutate methods in brains/{ann,bnn,ctrnn,grn}.jl.
- Searches: `Sergio|Track A|Track B|coordination` in AGENTS.md;
  `_mutate_weights|mutate\(` in Julia source. Only historical ownership
  context remains. No source code or public API changed.
- Checks: git diff --check clean; after-task structure and prose checks
  passed. No simulation or package suite rerun for this documentation change.
- Next: merge the decision record, then close #111 with the source rationale
  in the final issue sweep. Do not infer a v0.8 reset from this record.

## 2026-11-14: Action entropy and distinct genetic pairs

- Branch: codex/diversity-metrics, based on main d012fe0 (includes #200).
- Goal: finish #164 and correct the genetic self-pair denominator bias
  found during #185 review. R documentation and Core Contract updated.
- Checks: Julia 1.10.0 `julia --project=inst/julia inst/julia/test/runtests.jl`
  exit 0, 143 assertions pass. Focused R extractor/live five-seed and
  no-predator tests: 41 pass, zero fail/warn/skip. `devtools::document()`
  regenerated get_run_data.Rd. Full R portable tier with
  CLADE_SKIP_JULIA_TESTS=true: exit 0, no fail/warn, 644 skips.
- Tests of tests: old genetic sampler fails exact two-agent and all-pair
  checks. Independent review requested guaranteed undefined entropy across
  the connector; the added real no-predator test passes with is.nan().
- Searches: `progress.*==|==.*progress` identified two whole-table equality
  assertions needing isequal for NaNs; `behavioral_diversity|n_behavioral|
  _sample_genetic_diversity` checked source/help/contract consistency.
- Limit: no biological calibration or historical cache regeneration.
  Genetic sampling changes RNG draws and seeded trajectories. Historical
  #185 data must remain separate from results generated after this fix.
- Report: after-task/2026-11-14-diversity-logging.md.
- Next: settled green PR merge, then replay-safe #185 rerun.

## 2026-11-14: Replay-safe diversity campaign driver

- Branch: codex/campaign-replay, includes merged #201 and Bhavya's #185 history.
- Driver now uses isolated Xoshiro(42), round-trip input precision, actual
  final tick, and NA for snapshots after termination. Invalid counts/seeds
  fail before opening the output file. Both entry scripts are include-safe.
- Julia 1.10.0 full suite: exit 0, 166 assertions pass, including driver 23.
  The test first caught invalid arguments overwriting an existing file.
- Integration found `using Clade` tried to redefine a locally included module;
  entry scripts now load the package only when Clade is not already bound.
- Searches: `repro_threshold|full_drac_results|sample_environments` in scripts
  and data README. Both submitted CSV files remain byte-for-byte unchanged.
- Next: commit the exact driver, run a timed one-environment Totoro pilot,
  inspect output before the full 100 by five rerun, record revision/checksums.


## 2026-11-14: Corrected diversity rerun and review

- Driver/source d00ae6f on Totoro, Julia +1.10.0. Pilot five runs took
  10.32 s; full 500 runs took 74.29 s, max RSS 405500 KiB, exit 0.
- New verified_results.csv has 500 unique pairs, 100 environments and seeds
  101:105. 309 survive, 191 go extinct, four end with one agent. All 672
  post-termination snapshot fields are NA; no missing observed snapshots.
- Both submitted CSVs are byte-identical to origin/diversity-vald. New CSV
  SHA256 5d72d3ee0789fe0a3ff2db7eea401ee51eb2f655d92b2cacfe6dd10119df6ae5
  matches Totoro. Exact source, commands, timing and hashes in verified-run.json.
- Same-host input replay: one survivor and one extinction, eight assertions
  pass (tick, counts, diversity at saved six-decimal precision).
- Independent audit agrees. Exploratory lme4 two-stage models converge
  without warnings and are nonsingular. Gaussian conditional model has a
  negative fitted minimum and asymmetric residuals; coefficients are
  exploratory. Genetic distance is nonnegative, not constrained to [0,1].
- Reproducible review and raw output saved under dev/data/diversity-vald/.
  No global optimum, biological calibration or causal claim is supported.
- Report: after-task/2026-11-14-diversity-campaign.md. Full driver suite
  passed 166 assertions before integration of sensing changes.
- Next: merge current main, rerun integrated checks, update #185, and only
  after settled green integration send the consolidated Bhavya reply.


### Integration verification for weighted sensing

Merged main c3c0731 (#201). Resolved append-only conflicts by retaining
both log/decision/NEWS sections and all three Julia test includes. Julia
suite now passes 202 assertions. Live R snapshot 14 and entropy 41 pass;
config/spec-groups/spec-wiring/sense-mode pass 64. No failures or skips.


### Saved-spec compatibility review

Independent review reproduced R validation rejecting saved spec lists that
predate sense_mode. The added regression failed before the fix. Validation
now accepts an absent field (Julia defaults it to per_cell), while explicit
invalid modes still fail. No saved-spec migration is required.


### Final campaign integration checks

Integrated main f69b38c (#203). Preserved append-only histories while resolving
check-log conflict; all Julia includes retained. Full Julia suite: 225 pass,
exit 0. Portable R suite: exit 0, no fail/warn, 647 gated skips. Reproduced
both exploratory models with the saved R script and data assertions. Trimmed
trailing whitespace from captured output; numeric results unchanged.
The source metric is RMS genome-weight distance, nonnegative without a fixed
upper bound of one; removed the review script's unsupported upper-bound
assertion. Saved-spec compatibility fix is included from #203.


## 2026-11-14: Matched-founder experiment setup

- User authorized a matched-founder experiment on Totoro. Branch:
  codex/matched-founder-experiment, base main 13430c1; narrow file lease.
- Minimal private _run_clade initializer seam reuses the canonical loop.
  Public functions/defaults unchanged. Runner holds reference scalar traits
  fixed, rescales founder alleles, then restores offspring mutation specs.
- Design: 2 worlds x 3 founder SDs x 3 mutation SDs x 2 BNN exploration
  modes x 100 seeds = 3600 runs. Fixed exploration is primary; default
  heterozygosity is sensitivity. Plan and analysis in dev/data/matched-founders/.
- Checks: Julia suite 277 assertions pass, exit 0. Independent prior-source
  five-seed full-result parity 5/5. Live R entropy/extractor 41 and sensory
  snapshot 14 pass. Tiny 72-run output/analysis smoke passes.
- Tests of tests: missing initializer first failed; zero-founder/zero-M
  control remains zero and positive-M offspring generate variation.
  Initial state hashes agree across M. An incomplete-world CSV fixture is
  rejected by the exact Cartesian design check. Existing-output guard passes.
- First numeric check incorrectly compared normalized Float32 mutation to a
  Float64 literal; assertion now checks the actual Float32 contract.
- Independent review required fixed-exploration control and complete run/
  trajectory keys. Both addressed. No scientific campaign started yet.
- Next: commit exact source, timed 72-run Totoro pilot at 1000 ticks,
  inspect match/data/viability checks, estimate and run full campaign.

## 2026-11-14: Matched-founder campaign completed on Totoro

- Branch codex/matched-founder-experiment; draft PR #204. Simulation source
  07bc4949b9ff9fe64119335736897dbe7e960af8. Source archive and canonical
  outputs: ~/sim-archive/clade/2026-11-14-matched-founders on Totoro.
- Command: OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 julia +1.10.0
  --project=inst/julia inst/julia/scripts/matched_founders.jl 100 OUTDIR 1000.
  The 72-run pilot took 31.27 seconds; estimate stated before full launch:
  30 minutes. Full 3600 runs completed in 16:25.48, peak 429372 KiB, exit 0.
- All 36 cells, 1200 complete matched-state hash blocks and 400 zero/zero
  controls passed. Independent raw-data audit: 26 checks pass; 193 extinct,
  13 singleton, 3394 pairwise-measurable endpoints; 39792 trace rows with
  all 238 post-termination rows correctly missing. Audit checker corrected
  its expected founder-scaling stratum count from 360 to 1200 before rerun.
- Final Rscript dev/data/matched-founders/analyze.R OUTDIR 100 and plot.R
  OUTDIR passed. Added direct singleton intervals after pilot review.
  Actual viability_report: fixed low-cost 900 viable, high-cost 0 viable;
  usual exploration low-cost 899 viable/1 weak, high-cost 2 viable.
- Separate-process seed10001 replay of all 36 conditions: all 19 columns
  in 36 run rows and all 9 columns in 396 trajectory rows exactly identical.
- Full local Julia suite now 278 pass after independent three-genome exact
  distance fixture. Portable R suite passes with 647 gated skips; live R
  boundary 55 assertions pass. Independent previous-source parity 5/5.
- devtools::check(document=FALSE,args="--no-manual",error_on="error"):
  0 errors, 3 warnings, 5 notes; includes vignette rebuild and passing tests.
  Warnings are unchanged non-ASCII R source and undeclared optional NLMR/
  yaml dependencies. Notes include temporary graft cache and existing
  docs findings. This is not a clean release check; cache not committed.
- Scientific review: scope founder attenuation to the low-cost world.
  High-cost default interaction interval includes zero and both-viable
  paired diversity has no eligible pairs. No fitness or ancestry-fraction
  claim. Compressed raw evidence, summary contrasts and checksums saved
  under dev/data/matched-founders/results; findings explain denominators.
- Searches: rg 'matched.founder|founder.*mutation|mutation.*founder' and
  rg 'TODO|FIXME|not implemented|planned.*implemented' over experiment,
  runner and tests; no stale implementation claims. git diff --check clean.
- No public API/default/spec changes; no roxygen generation needed. No
  other architectures, optional modules, longer horizons or biological
  calibration tested. After-task report records limits and next action.
- Next safest action: review PR #204 and interpret behavioural consequences
  in viable populations with ploidy controlled. No new Bhavya message.

## 2026-11-14: Behavioural consequences with fixed ploidy, setup

- User approved Totoro follow-up. Branch codex/behaviour-ploidy builds on
  prior matched-founder source. New private research script only; no public
  API, spec, defaults or kernel loop changes. Narrow file lease acquired.
- Plan in dev/data/behaviour-ploidy/plan.md: six cells, 100 matched seeds,
  F=.05, M0/.05/.20, fixed haploid or diploid with selfing fallback, fixed
  BNN sigma .5. Actual viability_report gates paired behavioural contrasts.
- Independent design/source review required actual argmax frequencies,
  fixed exploration, matched noise across treatments, independent banks
  to remove finite-draw squared-distance inflation, and within-agent noise
  separate from between-agent differences. Implemented those conditions.
- Local default Julia launcher points to missing1.10.0 installation; use
  installed +1.10 (1.10.12) locally, pin Totoro+1.10.0 for campaign/replay.
  A misspelled action_epsilon spec triggered a kernel warning; corrected
  to existing action_exploration_epsilon before campaign source is pinned.
- No simulations launched on Totoro yet. Next: local tests/toy output,
  timed12-run full-horizon pilot, actual viability, then measured full estimate.
- Local Julia suite295 assertions pass; six-run two-tick output and R
  analysis smoke pass. Independent-bank arithmetic recovers the known
  opposite-bias value1 and cloned-brain value0; negative finite-draw
  cross-products are retained. Threshold flags remain provisional until
  the same both-viable first10 pairs pass the fourfold-draw precision check.
- Totoro pilot12 runs at1000 ticks: exit0,21.60 seconds,peak440732 KiB.
  All12 viable, four initial-state blocks matched, exact fixed endpoint
  ploidy and sigma .5. Full600 plus first10-block reassay launched at
  source7a2d78b9fa4efbd6f6ab5553f00f0422491ffa80, estimate25 minutes.

## 2026-11-14: Fixed-ploidy behavioural campaign completed

- Totoro source 7a2d78b9fa4efbd6f6ab5553f00f0422491ffa80, Julia 1.10.0,
  OPENBLAS_NUM_THREADS=1,JULIA_NUM_THREADS=4. Full 600 runs: 6:16.18,
  peak 466712 KiB,exit 0. Fourfold reassay 60 endpoint populations: 44.87s,
  peak 340556 KiB,exit 0. Both finish within the 25-minute estimate.
- Rscript dev/data/behaviour-ploidy/analyze.R OUTDIR 100 passes complete
  Cartesian design, 200 matched founder blocks, 600 fixed-ploidy endpoints,
  28800 complete assay rows and independent integer-statistic reconstruction.
  Actual viability_report:600/600 viable, 100/100 in each cell; no exclusions.
- Primary paired deltaB at M.20: haploid .214551 [.207282,.221821],
  diploid .151711 [.148049,.155372], each 100 viable seed pairs. Moderate
  mutation also exceeds .00625. All four first 10-block precision checks
  pass; max mean numerical change .0006433, max numerical MCSE .0004475,
  both below .0015625. Full source and boundaries are in findings.md.
- Independent mechanical audit agrees on all keys, ploidy, context counts,
  sufficient-statistic reconstruction, viable denominators and intervals.
  Exact separate-process seed20001 replay: six run rows x19 fields and
  288 assay rows x20 fields identical. Compressed evidence plus 600-state
  checksum manifest saved; full endpoint states retained on Totoro.
- R proportion intervals corrected after review to exact binomial limits;
  all-success lower bound checked independently as .025^(1/100). Full
  intervals do not imply100% survival certainty. Plot regenerated using
  segments for subpixel intervals, avoiding zero-arrow warnings.
- Source tests 295 assertions pass. Local six-run toy and low-replication
  reassay branch pass and retain provisional importance flags. A missing-
  treatment fixture is rejected; no full R package check repeated because
  public R code, signatures/defaults and Julia kernel are unchanged.
- PR #204 merged only after exact-head settled green checks. Its main R
  check and coverage pass; pkgdown status is tracked separately. New work
  in PR #205, based on merged main. No new message to Bhavya.
- Consistency searches: rg 'action_epsilon|operationally_meaningful|ploidy'
  over the new runner/tests/analysis; rg 'TODO|FIXME|not implemented|planned.*implemented'
  over the experiment scope; git diff --check. Correct field is
  action_exploration_epsilon; the earlier typo remains only in this history.
- No ecological importance, adaptation, temporal personality, or pure
  copy-number claim. Within-agent repeated-choice disagreement changed;
  Gaussian exploration sigma stayed .5. Exact prose assessment and the
  after-task report record the scientific and factual review.
- Next scientific action: assess foraging and reproduction under the same
  controls. No further campaign started; report awaits user review.

- Main a9a7ad4 after PR204 completed R-CMD-check, coverage and pkgdown
  successfully. Final scientific review found no blocker in findings.md.

## 2026-11-14: Foraging and reproductive consequences, setup

- User approved Totoro follow-up with the same controls. Branch
  codex/foraging-reproduction; narrow lease includes the private loop seam.
  Plan: replay the same 600 populations, observe actual intake/net foraging
  energy, births and pre-action agent-time; primary ticks501:1000.
- Existing endpoint brains receive a separate ten-case common-garden assay
  through canonical tick_agents!, with fresh copied caches and independent
  trial resets. Recruitment follows birth IDs for100 ticks, with censoring.
- Private no-op observer phases before/after agents and after logging,
  before extinction break. Public signature/defaults and R boundary stay.
- TDD red: unsupported observe keyword. Focused tests then pass: exact
  full returned-result equality in five seeds, known food/cost and cache
  fixtures, population conservation and extinction-tick death counts.
- Source review found standard logged death counters omit the extinction
  tick; this experiment reads actual counters through the observer. It
  does not claim population intake alone measures inherent foraging skill.
- Next: full Julia suite, tiny output/analysis, pinned-source Totoro pilot,
  then measured full-run estimate. No Totoro performance run started yet.
- Full local Julia suite326 assertions pass, including an oracle policy
  that obtains five times uniform-choice intake and independent cohort
  censoring/death fixtures. Live R-to-Julia entropy41 and sensory14 pass.
- Totoro pilot12 runs:21.54 seconds,peak431076 KiB,exit0; all12 viable,
  four matched founder blocks, all endpoint brains exactly match prior
  archived states. Analysis validates4857 birth cohorts and120 garden rows.
- Full600 replay and60-population256-draw reassay launched at source
  121b0a4b9d12e02881e7ef004a0f740319ab414f, estimate25 minutes. Progress
  meter uses completion receipt; actual row counts provide run progress.
- PR205 merged only after all exact-head checks settled green. Its main
  R-CMD-check,coverage and pkgdown workflows all completed successfully.

### Performance assay numerical refinement, before interpreting benefit

- All600 population replays complete and exactly match prior endpoints.
  Independent audit passes raw design, exposure, cohort and energy ledgers.
  Initial garden precision fails all4 gates; max numerical MCSE .00654,
  with one first10 classification changing. No garden benefit/equivalence
  claim is accepted from that version. Raw64/256 outputs are preserved.
- Independent review approves independent RNG across brain indices for
  linear mean reward, still paired by index/case/repetition across M.
  This is a numerical variance change, not an intervention or agent match.
  Old population simulations and behavioural-distance assay are untouched.
- Repeat only all600 gardens at256 trials and first10 blocks at1024.
  Frozen bit-packed keys exclude M and are collision-tested. Same5%
  margin and precision/classification gates. Estimate20 minutes from
  measured57.58s for60 populations at256 trials, before this phase starts.
- Analysis initially rebuilt cohort string keys repeatedly; stopped only
  that analysis process, cached group indices and reran. No simulation or
  raw output was interrupted or replaced.

### Critical reproduction qualification found during performance work

- Source review and energy-budget discrepancy exposed reproduced=true
  never being cleared. create_offspring! therefore permits only one focal
  episode/lifetime even for iteroparous agents. Mate contributions are a
  separate pathway. Independent review confirms the bug and recommends
  clearing surviving flags after mortality, before reproduction.
- Legacy600 results are source-bound diagnostics and cannot establish
  intended iteroparous performance. Preserve them and failed precision
  outputs. Do not refine/interpret legacy brains as corrected populations.
- No full numerical refinement was launched; only six-population probe.
  Next: focused fix/regressions, then corrected-source pilot and fresh
  endpoint archives under the same exogenous controls.

## 2026-11-14: Iteroparous focal-reproduction gate correction

- Branch codex/iteroparous-reset, based on main660a4b8. Source defect:
  reproduce.jl skips reproduced=true and sets it after a successful focal
  episode; no reset existed. Red regression: founder births1 versus3
  expected on three eligible ticks (two assertions fail).
- Clear surviving flags after kill_dead/remove_dead, before reproduction.
  Preserve same-tick guard and next-tick semel mortality. No default or
  public signature change. Counterpart code/type/R docs/NEWS updated;
  man/default_specs.Rd generated with devtools::document().
- Full Julia suite308 assertions pass, including13 new life-history
  assertions: successive ticks, same-tick duplicate guard, failed attempt,
  multi-offspring semel clutch and death at next mortality phase.
- Earlier matched-founder, behavioural and diversity-campaign README/
  findings now carry source-bound legacy qualifications; raw outputs are
  retained. Decisions log records phase ordering and campaign boundary.
- Corrected populations and endpoint brains will be generated for the
  performance task after a fresh viability/runtime pilot; legacy600 is
  not used as corrected reproductive evidence.

- Live R life-history tests:29 pass,0 failures/skips,2 viability-crash
  warnings from existing semelparous fixtures. No warning-free release
  claim. Linked after-task report exists; direct legacy analysis.md also
  receives the source qualification. Independent source review approves
  reset placement and distinguishes focal/mate contributions.

### Corrected performance protocol after reproduction repair

- Integrated focused reproduction reset fix into the performance branch.
  Preserve mortality before flag clearing and shared canonical loop.
- Driver now generates/saves corrected endpoint brains, assays those same
  brains, and rechecks between/within policy metrics. Removed the invalid
  legacy-brain equality dependency. Added capacity ticks to output.
- Original600 replay, original numerical failures and six-brain-set probe
  remain legacy receipts. No full legacy numerical refinement was launched.
- Same biological controls, seed blocks,primary time windows/cohorts and5%
  margins. Corrected garden uses independent brain-index trials64/256,
  with the same numerical/classification gates; refine draws only if needed.
- Corrected tiny six-run two-tick output/analysis passes. Next: full combined
  Julia checks and six-run full-horizon corrected pilot, estimate<5 minutes.
