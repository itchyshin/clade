# clade Vision

`clade` exists to **test behavioural and evolutionary theory by simulating
digital organisms with heritable neural-network brains, then auditing each
scenario against a primary-literature prediction.**

## Readers And Users

The primary readers are:

- **Behavioural and evolutionary ecologists** wanting to test a published
  prediction (e.g., "does Wolf 2007's bold-aggro syndrome survive in a
  spatial setting?") without writing kernel code.
- **Theoretical biologists** developing new mechanisms — clade gives them
  a kernel and ~30 modules to combine.
- **Conservation and climate-change researchers** projecting how
  behaviour and trait distributions evolve under shifting environmental
  parameters (warming, habitat loss, seasonality change). clade's
  world-search tooling makes scenario forecasting tractable.
- **Students** learning agent-based modelling — paper-reproduction
  vignettes are worked examples paired with the original papers.
- **Method-development collaborators** reviewing kernel correctness
  (currently: Sergio @pooherna, against the Bulitko-group MATLAB
  ancestor).
- **Reviewers** evaluating a manuscript that cites clade's results.

## Core Lab Values

clade reflects the four core values of the lab. They are not aspirational
slogans — each maps to a concrete design choice or operating rule.

### Transparency

Every method choice is visible.

- Kernel source is public on GitHub.
- The audit history is committed in `dev/audit/` (consolidation against
  MATLAB ancestor; Rose+Pat documentation audits; spec-wiring audit;
  spot-check scenarios; tick-loop refactor assessment).
- Every paper-reproduction vignette has an **"honest discussion"
  section** that names what aligned with the paper and what didn't.
- Disagreements with the source paper are turned into testable
  companion vignettes (Massol-Crochet β sweep, McElreath time-decay
  critique) rather than buried.

### Reproducibility

Every result is replayable.

- Every simulation is seeded (`random_seed` in `default_specs()`).
- Spec lists are JSON-serializable (`stream_specs_to_csv()`,
  `load_specs()`).
- The R↔Julia boundary uses `JuliaConnectoR`, not a fragile
  re-implementation.
- **Quantitative claims in paper-reproduction vignettes require
  ≥ 5 seeds with mean ± SE reporting** (Phase B of the current Track
  B walk delivers this for all 14 papers).
- Structural drift guards (`test-spec-wiring.R`,
  `test-version-strings.R`, `test-pkgdown-consistency.R`,
  `test-readme-flag-names.R`) prevent silent regression of documented
  behaviour.
- CI runs `R CMD check` on every pull request.

### Accessibility

A new user without specialised infrastructure can use clade.

- User-facing interface is R, not Julia. A user with R installed can
  call `default_specs()` and `run_alife()` without touching the
  kernel.
- The package and documentation are free and open
  (<https://itchyshin.github.io/clade/>).
- A "5-minute basics" vignette (`vignettes/basics.Rmd`, in
  development as the Track B Phase A.5 deliverable) covers the
  minimum viable workflow.
- The audit infrastructure makes it easy to reproduce headline claims
  on a laptop — runs are seeded, viable runs are flagged
  (`viability_report()`), crashed runs warn the user.

### Inclusiveness

Examples, contributors, and design choices represent the diversity of
the field.

- Examples and paper-reproductions cover taxonomic and behavioural
  diversity — not just mammals, not just one social system, not just
  one continent's literature.
- The kit's standing-role names (Ada, Boole, Gauss, Noether, Darwin,
  Fisher, Pat, Jason, Curie, Emmy, Grace, Rose) are deliberately
  diverse across history, gender, and field.
- Contributions are welcomed via GitHub issues and PRs.
- A `CODE_OF_CONDUCT.md` is in development.
- Documentation avoids assuming a privileged technical baseline —
  R basics are not pre-required; Julia is not required at all.

## What Makes clade Different

clade is not "another agent-based simulator." Four things distinguish
it from SLiM, NetLogo, Mesa, and most ABM packages in R:

### 1. R-user interface with Julia performance

The simulation kernel runs in Julia for speed. R is the user-facing
language for specs, analysis, and plotting. **The R↔Julia boundary is
crossed exactly once per `run_alife()` call**, not once per tick. The
practical consequence: 100-to-1000-run audits are routine instead of
overnight jobs. Most ABM packages force the user to choose between
"slow but ergonomic" (pure R / Python) and "fast but cumbersome"
(C++ / Julia / Rust). clade keeps the R-user ergonomics and pays the
performance cost only once per run.

### 2. Evolvable worlds — for mechanism AND for prediction

Real evolutionary biology has one Earth and one history. Researchers
look at what happened and try to explain why. **In silico we have
unlimited worlds**, and clade systematises the search across them.

The `search_*()` family treats ENVIRONMENTAL PARAMETERS as the search
space:

- `search_map_elites()` — illuminates the diversity of evolutionary
  outcomes across world configurations (Mouret & Clune 2015).
- `search_cmaes()` — finds the world parameters that maximise a chosen
  trait (genetic diversity, mean cooperation, brain size, …) — pure
  R, no external dependencies.
- `search_gradient()` — finite-difference gradient ascent on world
  parameters.
- `search_viability()` — finds world parameter combinations where the
  population doesn't crash.

This enables two distinct research modes:

**Mechanism discovery (retrospective).** Given a published claim, find
the parameter regime under which it holds — and the regime where it
breaks. clade's paper-reproduction vignettes use this mode: Wolf 2007's
syndrome holds at certain `personality_beta` values and fails at
others (Massol-Crochet test); the syndrome erodes over long horizons
(McElreath test).

**Future projection (prospective).** Given a *projected* environmental
trajectory — a warming scenario, a habitat-fragmentation scenario, a
seasonality-shift scenario — simulate which behavioural and
life-history traits evolve under it. Climate-change biology has rich
empirical work on *observed* responses; clade's world-search tools
make it tractable to ask **"given THIS climate trajectory, what
behaviour evolves?"** rather than only "given the world today, what
behaviour exists?" This is a tool for conservation and applied
evolutionary work, not just for retrospective explanation.

This shifts the inferential frame: clade enables design-space
exploration of evolutionary dynamics, not just single-world
simulation, and supports both mechanism work and forward-projection
work.

### 3. Paper-reproduction-driven structure

14 paper-reproduction vignettes (Wolf 2007, Trivers 1971, Wolf 2008,
Ryan 1990, Kokko-Brooks, Réale, Emlen, Dieckmann-Doebeli, Griesser,
Fuller, Courchamp, Massol-Crochet critique, McElreath critique,
template). Each has an "honest discussion" section about what
aligned with the paper and what didn't. The package is organised
around **reproducible claims**, not just code modules.

### 4. MATLAB-ancestor lineage

Descended from Bulitko's MATLAB agent-based code via the alifeR R
prototype. A faithfulness check against the ancestor is part of
kernel quality discipline (see `dev/docs/consolidation-audit.md`).
The 0.7.0 release fixed two regressions discovered against this
ancestor (random tick scheduling, one-per-cell movement). Sergio's
v0.8-core branch is pursuing a deeper subtractive reset against the
same ancestor.

## Scope

The package currently supports:

- Agent-based simulation on a 2D toroidal grid with random
  asynchronous scheduling and one-per-cell movement.
- Heritable neural-network genomes (diploid or haploid) with five
  brain architectures: BNN, ANN, CTRNN, GRN, and a random baseline.
- ~30 optional biological modules, each toggled by one boolean flag:
  kin selection, signals + mate choice, parental care, predators,
  mimicry, niche construction, complex landscape, personality
  syndrome (Wolf 2007), reciprocal altruism (Trivers 1971),
  responsive personalities (Wolf 2008), and more.
- Parameter-search tools: MAP-Elites, CMA-ES, finite-difference
  gradient, viability-constrained search.
- A multi-seed audit infrastructure (`viability_report()`,
  `hypothesis_sweep()`, four structural drift-guard tests).
- 14 paper-reproduction vignettes, 36 scenario vignettes, 7 kernel
  documentation vignettes, 4 parameter-search vignettes.

The package does NOT currently support:

- Continuous-time simulation (everything is per-tick discrete).
- 3D space.
- Statistical inference from real data — clade is forward-simulation
  only. For inference, pair with `lme4`, `glmmTMB`, `brms`, or others.
- GPU acceleration.
- Real-time interactive visualisation.
- Reserved-name brain architectures: `"transformer"` and `"synthesis"`
  are documented placeholders; the kernel errors if either is
  requested.

Active discussions (in flight, not yet supported):

- Subtractive v0.8-core reset, on Sergio's branch (`claude/v0.8-core`,
  PR #122). Aims for a MATLAB-ancestor-faithful minimal kernel with
  promoted-back modules.
- Diploid quantitative-genetics extensions beyond Wolf 2007 Fig 4.
- McElreath et al. 2007 follow-up: long-run individual-difference
  erosion at variable population sizes.
- Conservation / climate-change application vignettes (a natural
  follow-on from value-section "scope" of evolvable worlds).

## Core Contracts

Names that must stay stable across code, docs, tutorials, and issue
threads. Changing any of these is a deliberate decision that needs a
note in `dev/dev-log/decisions.md`.

| Contract | Meaning | Where Implemented | Validation |
| --- | --- | --- | --- |
| `default_specs()` | Returns the canonical 296-field spec list. Single source of truth for parameter names, defaults, and types. | `R/config.R` | `test-specs.R`, `test-config.R`, `test-spec-wiring.R` |
| `run_alife()` / `run_clade()` | Primary entry point. R↔Julia boundary crossed once per call. | `R/run.R` | `test-integration.R` |
| `batch_alife()` / `batch_seeds()` | Parallel batch runners. PSOCK cluster; one Julia per worker. | `R/run.R` | `test-integration.R` |
| `get_run_data(env)$ticks` | Per-tick population statistics in long form. Stable column set. | `R/analysis.R` | `test-run-data.R` |
| `get_run_data(env)$deaths` | Per-death individual records. | `R/analysis.R` | `test-run-data.R` |
| `get_run_data(env)$genomes` | Per-tick trait genomes (NULL unless `log_genomes = TRUE`). | `R/analysis.R` | `test-log-genomes.R` |
| `viability_report(ticks, n_agents_init)` | Quality gate. Verdict ∈ {viable, weak, crashed}. | `R/analysis.R` | (Phase A item 6 will add a dedicated test) |
| `wolf_personality_specs()`, `trivers_reciprocity_specs()`, `wolf2008_responsiveness_specs()` | Paper-reproduction presets. | `R/scenarios.R` | per-paper test files |
| `search_map_elites()`, `search_cmaes()`, `search_gradient()`, `search_viability()` | World-evolution search tools. | `R/search.R` | `test-search.R`, `test-search-scenarios.R` |
| `hypothesis_sweep()` / `hypothesis_report()` | Researcher-facing sweep helpers. | `R/hypothesis.R` | `test-hypothesis.R` |
| Spec field naming | `<module>` for module flags (`kin_selection`, `personality_syndrome`); `<trait>_init_mean`, `<trait>_mutation_sd`, `<trait>_min`, `<trait>_max` for heritable trait controls. | `R/config.R` | `test-spec-wiring.R` |
| Module gate semantics | One boolean flag per module in `default_specs()`. TRUE enables; FALSE disables; no other side effects. | `inst/julia/src/Clade.jl` tick loop | `test-spec-wiring.R` |
| R↔Julia boundary | Crossed exactly once per `run_alife()` call. | `R/run.R::.specs_to_julia` + `R/run.R::.julia_env_to_r` | `test-integration.R` |
| `random_tick_order = TRUE` | Random asynchronous scheduling per Grimm & Railsback (2005). Default since 0.7.0. | `inst/julia/src/tick.jl` | `test-tick-order.R` |
| `max_agents_per_cell = 1L` | One-per-cell movement. Movement rejected when target occupied. | `inst/julia/src/tick.jl`, `inst/julia/src/reproduce.jl` | `test-cell-occupancy.R` |
| Brain types | `"bnn"`, `"ann"`, `"ctrnn"`, `"grn"`, `"random"` are implemented. `"transformer"`, `"synthesis"` are reserved names; kernel errors. | `inst/julia/src/Clade.jl::make_brain` | `test-brains.R` |

## Evidence Standard

An implemented claim needs:

- a code path (R function or Julia module);
- at least one test exercising the claim (`skip_no_julia()` if
  Julia-dependent);
- documentation (roxygen or vignette);
- a worked example (vignette section or `\dontrun{}` block);
- a check-log entry for the change in `dev/dev-log/check-log.md`;
- an after-task or after-phase note for meaningful changes
  (`dev/dev-log/after-task/`, `dev/dev-log/after-phase/`).

A planned claim must be labelled as planned in user-facing prose
(`DESCRIPTION`, `README.md`, `NEWS.md`, vignettes) and roadmap files.

Specific to clade (extensions enforced by the lab values above):

- **Paper-reproduction vignettes must include an "honest discussion"
  section** — required by the transparency value, regardless of whether
  the headline result matched the source paper.
- **Any quantitative claim in a paper-reproduction vignette needs
  ≥ 5 seeds** with `mean ± SE` reporting — required by the
  reproducibility value. Single-seed numbers are acceptable only as
  diagnostic illustrations, clearly labelled.
- **Any spec field added to `default_specs()` must have a Julia
  consumer** — asserted automatically by `test-spec-wiring.R`. If a
  field is a reserved-future placeholder, it must be in the
  `.SPEC_WIRING_ALLOWLIST` with a justification comment.
- **Any user-facing flag name in `README.md` must exist in
  `default_specs()`** — asserted by `test-readme-flag-names.R`.
- **Version strings must agree across `DESCRIPTION`, citation, and
  README** — asserted by `test-version-strings.R`.
- **pkgdown navbar dropdown and articles index must agree** —
  asserted by `test-pkgdown-consistency.R`.
- **Examples in user-facing docs should reflect taxonomic and
  behavioural diversity** — required by the inclusiveness value. No
  single-clade dominance in vignette examples.
