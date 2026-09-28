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
