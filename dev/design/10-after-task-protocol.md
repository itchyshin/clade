# After-Task Protocol

Every meaningful task or phase should leave a compact Markdown report. The
report is part of the project memory and should make later Codex, Claude Code,
human review, and release work easier.

Use the project-local `after-task-audit` skill before closing the task.

## Location

Task reports live in:

```text
dev/dev-log/after-task/
```

Phase reports live in:

```text
dev/dev-log/after-phase/
```

## Required Sections

Each report should include:

- task goal;
- files created or changed;
- checks run and exact outcomes;
- consistency audit;
- tests of the tests, when tests changed;
- what did not go smoothly;
- team learning and process improvements;
- design-doc updates;
- documentation or site updates;
- known limitations and next actions.

## Consistency Audit

Before closing a task, check for stale names, syntax, schemas, parameter names,
planned-versus-implemented language, and unsupported examples across the
repository.

Use project-specific searches, for example:

```sh
rg "old_function|old_parameter|planned.*implemented" README.md docs vignettes R tests
rg "TODO|FIXME|not implemented yet.*implemented" README.md docs vignettes
```

Record the exact `rg` patterns used in the check log or after-task report. A
generic phrase such as "stale-wording scans" is not enough for later auditors.

## Tests Of The Tests

When adding tests, confirm that they actually exercise the intended behaviour.
Examples:

- inspect failure messages before relaxing expectations;
- check that parser tests assert parsed fields, not only object classes;
- use deterministic seeds for simulation or ML tests;
- add a negative test when a rule should reject unsupported syntax or data.

## Closing Rule

A task is not done until the after-task report says what was checked, what was
not checked, and what remains uncertain. Do NOT start the next task until the
user has reviewed the report and confirmed.

## clade-Specific Work Discipline

The kit's "required sections" above describe the WRITTEN report. Before
writing the report, do the five-step work checklist below. This is the
clade-native discipline that Rose enforces.

### The "two people" framing

While working on a task, hold both roles simultaneously:

- **A computer scientist with 25 years of coding experience** — pattern-matches
  bugs across files, sees what kinds of mistakes generalise, never trusts that
  "the bug is over there and stays over there."
- **A biology professor who believes in true biology** — insists the simulation
  be biologically meaningful. The concrete principle: **design the world for
  the biology, not the convenience.** If a fix entrenches biologically
  implausible behaviour to make code easier, flag it.

### Five-step checklist (do in order)

#### 1. Tree check — the specific change

- Re-read the diff. Is the change correct in isolation?
- Re-grep file:line references in any audit / plan / docs to confirm they
  are accurate.
- Are docstrings, comments, type annotations consistent with the change?
- If a test was added, did you actually run it (not just write it)?
- If a config was changed, did you verify it loads cleanly?

#### 2. Forest check — consequences elsewhere

- What other files / modules / vignettes / tests does this change touch
  indirectly?
- Does it conflict with any existing assertion in the docs, vignettes,
  `NEWS.md`, or roxygen comments?
- If behaviour changed, are there tests asserting the *old* behaviour that
  need updating?
- If a public API changed (R or Julia), are all callers updated?
- If a field was added to `default_specs()` or a Julia struct, are all
  consumers updated AND is there a test that exercises the new field?
  (`test-spec-wiring.R` will catch the basic gap; check for richer
  consumers too.)
- If a behaviour change is biologically meaningful, do the relevant
  `paper-*.Rmd` and `s-*.Rmd` vignettes still tell a coherent story?

#### 3. Generalisation — the Rose hunt

For every distinct issue you fixed or found, ask:

- *What class of mistake does this represent?*
- *Where else in the codebase might the same class of mistake live?*

Go look. Don't speculate. Examples of the kind of generalisation Rose would do:

- Found one tick-order bias → grep for other iteration patterns with the same
  bias (other `for ag in env.agents`, `for p in env.predators`, etc.).
- Found one R-side spec field that is not consumed by Julia (the 0.6.4
  `mate_choice_mode` incident) → audit ALL recently-added spec fields for
  the same gap.
- Found one place that assumes one-agent-per-cell → audit ALL uses of
  `agent_map`, `cell_*`, sense vectors, and biology that implicitly relies on
  uniqueness.
- Found one magic constant → check whether its companions in the same module
  also lack a citation or rationale.

If a class of mistake recurs, propose a structural fix (a new test class, a
refactor, a lint rule) — not just per-instance patches. The four
drift-guard tests (`test-spec-wiring.R`, `test-version-strings.R`,
`test-pkgdown-consistency.R`, `test-readme-flag-names.R`) are all examples
of structural fixes that came out of recurring per-instance findings.

#### 4. Biology consistency check

- Does the change respect biological plausibility?
- One agent per cell (`max_agents_per_cell = 1L`) is the default. If your
  change *entrenches* multi-occupancy ("we'll just ignore the second agent
  on this cell"), flag it. If respecting one-per-cell would require a
  larger grid for the biology to be sensible, say so explicitly — that is
  the right answer, not a problem to work around.
- Does the parameter set used in any new test or vignette remain
  biologically defensible (lifespans, energy budgets, mutation rates
  plausible for the modelled organism)?

#### 5. In-chat report structure

When checking in with the user after a completed task, use this structure
(concise; bullet form is fine):

1. **What was done** — 1-3 sentences.
2. **Tree-check findings** — anything in the immediate change worth a
   second pass.
3. **Forest-check findings** — what else this affects, including
   plan/doc updates needed.
4. **Generalisation findings (Rose)** — other instances of the same class
   of issue, with file:line where possible.
5. **Biology check** — whether the change respects biological plausibility
   and one-per-cell, or where it tensions with them.
6. **Proposed next actions** — concrete options for the user to choose
   from. Always come with proposals, not just questions.

The user reads the report and tells you what to do next. **Do not start
the next task until they confirm.**

## Do NOT

- Do not skip the Rose hunt because you are confident the bug is local.
  Local-looking bugs almost always have cousins.
- Do not bundle a "while I'm here" cleanup with the task at hand
  (Karpathy 3, surgical changes). Flag the cleanup in the report; let
  the user decide whether to do it.
- Do not silently downgrade biological plausibility to make the code
  easier to write.
- Do not declare a task done if any of (a) tree-check, (b) forest-check,
  (c) Rose generalisation has open items.
- Do not write the after-task report before doing the five-step checklist.
  The report follows the work, not the other way around.

## Template

```md
# After Task: <Title>

## Goal

## Implemented

## Files Changed

## Checks Run

## Tests Of The Tests

## Consistency Audit

## What Did Not Go Smoothly

## Team Learning

## Known Limitations

## Next Actions
```
