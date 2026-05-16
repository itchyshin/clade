# clade Agent Instructions

`clade` is an R package providing an agent-based evolutionary simulation
with a Julia backend. This file is the canonical instructions file for
Claude Code, Codex, and any other coding agent working in this
repository. **Repository files are authoritative.** Hidden agent memory
may help route work, but it must not be the only record of a design
decision, validation result, or release boundary.

Read this file first. Then read `dev/design/00-vision.md` for scope and
lab values, and `dev/dev-log/check-log.md` for the latest validation
state.

## Core Scope

clade is a **forward-simulation testbed for behavioural and
evolutionary theory**, with three uses:

1. **Reproduce published predictions** (paper-reproduction vignettes,
   with honest discussion sections).
2. **Search across worlds** (`search_cmaes`, `search_map_elites`,
   `search_gradient`, `search_viability` — find environmental
   configurations with target evolutionary outcomes).
3. **Project future evolution** (given a climate-change or
   habitat-shift trajectory, simulate what behaviour evolves).

clade is NOT for statistical inference from real data. Pair with
`lme4`, `glmmTMB`, `brms`, or others when that's the need.

Full vision, user list, lab values, and contracts: `dev/design/00-vision.md`.

## R + Julia Split

clade has a hard architectural boundary that shapes every task:

- **R side** — `R/*.R`, `tests/testthat/`, `vignettes/`, package
  documentation, `_pkgdown.yml`. Owned by the AI integrator (Claude /
  Codex / etc.) by default.
- **Julia side** — `inst/julia/src/`. Currently under parallel review
  on Sergio's branch (`claude/v0.8-core`, PR #122) for the subtractive
  v0.8-core reset. **Do not touch `inst/julia/src/` without
  coordination with Sergio's track** unless the change is purely
  additive and the user explicitly approves.
- **Boundary** — crossed exactly once per `run_alife()` call via
  `JuliaConnectoR`. Never per tick. This is a contract — don't
  introduce per-tick R↔Julia calls.

When an R-side change implies a Julia-side change (or vice versa),
say so before editing either side.

## Coding Principles

Bias toward caution over speed. For trivial edits, use judgment; for
anything substantive, these four hold. Adapted from the karpathy-skills
guidelines (<https://github.com/forrestchang/andrej-karpathy-skills>).

### 1. Think before coding

Don't assume. Don't hide confusion. Surface tradeoffs.

- State assumptions explicitly; if uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

In this repo this particularly means: when an audit result is
ambiguous, flag the ambiguity instead of forcing a PASS/FAIL verdict;
when an R-spec change implies a Julia-side change (or vice versa), say
so before editing either side.

### 2. Simplicity first

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No configurability that wasn't requested.
- No error handling for impossible scenarios.
- If you wrote 200 lines and it could be 50, rewrite it.

In this repo: don't add new spec fields "for flexibility". A new spec
is a commitment we have to test, document, and maintain forever, and
`test-spec-wiring.R` will fail if it's not consumed in Julia.

### 3. Surgical changes

Touch only what you must. Clean up only your own mess.

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions *your* changes made unused.
  Don't remove pre-existing dead code unless asked.

In this repo: when fixing a single vignette or audit report, don't
sweep nearby files for "related" issues in the same commit —
separate PRs. And don't hand-edit `NAMESPACE` or `man/*.Rd`; run
`devtools::document()` and commit the generated output.

### 4. Goal-driven execution

Define success criteria. Loop until verified.

- "Add X" → "Write a test for X, then make it pass."
- "Fix the bug" → "Write a test that reproduces it, then make it pass."
- "Refactor X" → "Ensure tests pass before and after."

For multi-step tasks, state a brief plan:

```
1. [step] → verify: [check]
2. [step] → verify: [check]
```

In this repo: audit claims need ≥5 seeds + `viability_report()` guard
before being called PASS; kernel changes need the relevant
`tests/testthat/test-*.R` to still be green; figure regenerations
should reproduce their claimed Δ before being pushed.

## Design Rules

1. Do not add user-facing functions without roxygen docs and at least
   one example or vignette section.
2. Do not change public function signatures, spec field names, or
   `default_specs()` defaults without updating the relevant Core
   Contract row in `dev/design/00-vision.md` AND adding a note in
   `dev/dev-log/decisions.md`.
3. Do not add likelihoods, simulation modules, search algorithms, or
   data transformations without targeted tests.
4. Keep pull requests small and focused. One change per PR; one commit
   per logical concern.
5. Every meaningful change must update `dev/dev-log/check-log.md`.
6. Every completed task or phase must create an after-task or
   after-phase report under `dev/dev-log/after-task/` or
   `dev/dev-log/after-phase/` following
   `dev/design/10-after-task-protocol.md`.
7. If code or examples are ported from another package, paper,
   repository, or branch, document provenance before treating the
   change as complete.
8. No agent should revert another agent's or the user's work without
   explicit instruction.

## Standard Commands

R-side (run from repo root):

```r
# Load package for interactive dev (no install required)
devtools::load_all()

# Run all tests
devtools::test()

# Run a single test file
testthat::test_file("tests/testthat/test-config.R")

# Rebuild documentation from roxygen comments
devtools::document()

# Full check (CRAN-style)
devtools::check()

# Build pkgdown site locally (writes to docs/, gitignored)
pkgdown::build_site()
```

Quick smoke run:

```r
library(clade)
julia_is_ready()         # checks status; compilation happens on
                         # first run_alife() — ~60–90 s once
specs <- default_specs()
specs$n_agents_init <- 40L
specs$max_ticks     <- 300L
env  <- run_alife(specs)
plot_run(get_run_data(env))
```

Julia-side (only needed for kernel debugging — Sergio's territory):

```bash
cd inst/julia
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

## Definition Of Done

A feature is done only when implementation, tests, documentation,
examples, check-log entry, after-task note, and review are all
present. If one of those is not appropriate for the specific change,
the after-task report must say why.

## Repository Map

| Path | Purpose |
|---|---|
| `R/run.R` | `run_alife()`, `batch_alife()` — main entry points |
| `R/config.R` | `default_specs()`, preset families |
| `R/scenarios.R` | Pre-baked scenario specs (`wolf_personality_specs`, etc.) |
| `R/hypothesis.R` | `hypothesis_sweep()` + `hypothesis_report()` |
| `R/analysis.R` | `get_run_data()`, `viability_report()`, `compute_ld()`, heritability, relatedness |
| `R/visualization.R` | `plot_run()`, `plot_diversity()`, etc. |
| `R/search.R` | `search_cmaes()`, `search_map_elites()`, `search_gradient()`, `search_viability()` |
| `R/maps.R` | Landscape generation (`generate_map()`, `prepare_map()`) |
| `R/utils.R`, `R/zzz.R` | Helpers and package load hooks; `.SPEC_GROUPS` lives here |
| `inst/julia/src/Clade.jl` | Julia kernel entry point |
| `inst/julia/src/{tick,sense,reproduce,death,genome,logging,types}.jl` | Core simulation loop |
| `inst/julia/src/brains/` | Brain architectures (BNN, ANN, CTRNN, GRN) + a RandomBrain baseline in `Clade.jl`. `transformer` and `synthesis` are reserved names; kernel errors if requested. |
| `inst/julia/src/modules/` | Optional biological modules (disease, dispersal, kin, etc.) |
| `vignettes/paper-*.Rmd` | Paper-reproduction vignettes (14) |
| `vignettes/s-*.Rmd` | Scenario vignettes (36) |
| `vignettes/k-*.Rmd` | Kernel-as-biology vignettes (7) |
| `vignettes/ps-*.Rmd` | Parameter-search vignettes (4) |
| `tests/testthat/test-*.R` | Unit and integration tests |
| `dev/design/` | Vision, after-task protocol — durable architecture docs |
| `dev/dev-log/` | check-log, decisions, after-task reports — append-only history |
| `dev/audit/` | One-off audit docs (Rose+Pat findings, spec-wiring audit, consolidation audit, spot-checks) |
| `.agents/skills/` | Project-local skills (`after-task-audit`, `prose-style-review`, `simulation-test-plan`) |

## Conventions

- Exports are managed by roxygen → do **not** edit `NAMESPACE` by hand;
  edit `@export` tags in `R/*.R` and run `devtools::document()`.
- Public R API surface is everything listed in `NAMESPACE` (`export(...)`).
- Specs are plain named lists — `default_specs()` is the schema;
  `vignettes/parameter-reference.Rmd` is the user-facing reference
  (introspection-generated as of 0.7.1).
- Modules are toggled via a single boolean flag on the specs list
  (`specs$disease <- TRUE`). One flag = one module; no side effects.
- Cached `.rds` files in `Rdata/` are checked into git so vignettes
  render cheaply — regenerate only when the underlying simulation
  changes meaningfully.
- Quantitative claims in paper-reproduction vignettes need ≥5 seeds
  with `mean ± SE`. Single-seed numbers are diagnostic only, labelled
  as such.
- "Honest discussion" section is required in every paper-reproduction
  vignette regardless of whether the result matched the paper.

## Standing Review Roles

These are shorthand for recurring review perspectives, not separate
permanent processes. Use them when they sharpen the work; keep every
claim grounded in files, commands, tests, citations, or explicit
design assumptions. Six roles are standing; the others from the kit
(`team-roles.md` reference) are available when relevant.

| Name | Role | Primary questions for clade |
| --- | --- | --- |
| **Ada** | Orchestrator and integrator | What should happen next, and are R code, Julia code, docs, tests, vignettes, and git consistent? Default integrator for Track B (R-side) work. |
| **Gauss** | Numerical and implementation reviewer | Is the kernel, optimizer, simulation, or numerical routine correct and stable? Sergio's natural role for Julia kernel review against MATLAB ancestor. |
| **Noether** | Mathematical consistency reviewer | Do source-paper equations, clade's parameter names, and the Julia implementation describe the same object? Especially relevant for paper-reproduction vignettes (Wolf 2007 trade-off, Trivers PD payoffs, Massol-Crochet β, etc.). |
| **Fisher** | Inference and evaluation reviewer | Do simulations, metrics, multi-seed dashboards, and viability checks support the headline claim? Owns the ≥5-seed rule. |
| **Pat** | Applied user tester | Can a new behavioural ecologist install clade, follow a vignette, interpret the output, and recover from errors without hidden context? |
| **Rose** | Systems auditor | What stale wording, repeated mistakes, unsupported claims, missing feedback loops, or unfinished handoffs are accumulating? When a single issue surfaces, ask "what class is it and where else does it live?" before moving on. |

Use the canonical names when reporting team perspectives. Don't
rename. Don't use names as decoration — if you name a role, attach a
specific question and a specific output.

## After-Task Protocol

Every meaningful task closes with an after-task report following
`dev/design/10-after-task-protocol.md`. Use the `after-task-audit`
skill (`.agents/skills/after-task-audit/SKILL.md`) before closing.

Reports live in `dev/dev-log/after-task/` (task-scope) or
`dev/dev-log/after-phase/` (phase-scope). Each report includes the
goal, files changed, checks run, consistency audit, tests-of-the-tests
when tests changed, what didn't go smoothly, team learning, known
limitations, and next actions.

## Check Log

Every meaningful change appends an entry to `dev/dev-log/check-log.md`.
Concrete and concise: branch, goal, files changed, exact command
outcomes, stale-claim searches with their `rg` patterns, what was not
run, and the next safest action.

## Decisions Log

Architectural decisions broader than one task — but not yet a full
design doc — go in `dev/dev-log/decisions.md`. Required when changing
any Core Contract row in `dev/design/00-vision.md`.

## Recovery Checkpoints

For long runs, stream failures, or handoffs, write a short note under
`dev/dev-log/recovery-checkpoints/` with:

- current branch and `git status --short`;
- changed files and diff stat;
- commands already run;
- commands that should be rerun;
- next safest action.

After a crash, repository state is authoritative. Always rerun:

```sh
git status --short --branch
git diff --stat
git diff
```

Then read the latest check-log and after-task reports before editing.

## Multi-Agent Collaboration

One agent acts as integrator for each task. Currently:

- **Track A** (Sergio @pooherna): Julia kernel review, v0.8-core
  subtractive reset. Owns `inst/julia/src/`.
- **Track B** (Claude / Codex / AI): R-side function walk and
  vignette deep-dive. Owns `R/`, `tests/`, `vignettes/`, `dev/audit/`,
  `dev/dev-log/`, `_pkgdown.yml`, `NEWS.md`, `README.md`. Plan in
  `~/.claude/plans/purring-honking-dove.md`.

When handing work to another agent (or to the user, or back to
Sergio), leave enough context in `dev/dev-log/check-log.md`, an
after-task report, an issue, or a pull request for the next agent to
continue without rediscovering the whole problem.

Read-only sidecar perspectives (for design review, mathematical
review, documentation review, validation planning) are fine. Write-
capable workers should have narrow file ownership that doesn't
overlap with other active work.

## Resource Limits

When running parallel sweeps, batch jobs, or anything CPU/memory-heavy
on this machine, **cap at ≤200 cores and target ≲300 GB memory**
(machine has ~1 TB but keep headroom). Flag any job that would exceed
either before launching.

## Two-Machine Workflow

This repo is also edited from a second machine. Before making changes:

1. `git pull --rebase` and verify `git status` is clean.
2. Prefer feature branches over committing directly to `main`.
3. Push frequently so the other machine can rebase on your work.
4. Avoid editing the same file as the other machine concurrently — ask
   if unsure which area is in flight.

## Team Improvement Loop

When a task exposes a better way for the team to work, record it in
`dev/dev-log/check-log.md` or `dev/dev-log/decisions.md`. Low-risk
documentation and skill improvements can be implemented immediately.
Product, architecture, or validation-policy changes need a normal
task with evidence and review.

## Things to Avoid

- Don't commit large regenerated artifacts (pkgdown `/docs/`,
  `*.Rcheck/`, `.Rhistory` — already gitignored, but double-check).
- Don't hand-edit `NAMESPACE` or `man/*.Rd` (regenerated by roxygen).
- Don't bypass `JuliaConnectoR` — there should be exactly one R↔Julia
  boundary crossing per `run_alife()` call.
- Don't add a spec field to `default_specs()` without a Julia consumer
  (`test-spec-wiring.R` will fail). If the field is a reserved-future
  placeholder, add it to `.SPEC_WIRING_ALLOWLIST` with a justification
  comment.
- Don't claim a paper-reproduction "works" without ≥5 seeds and an
  honest-discussion section.
- Don't introduce a parallel agent configuration system. Durable
  decisions live in `AGENTS.md`, `dev/design/`, `dev/dev-log/`, issues,
  and pull requests.
