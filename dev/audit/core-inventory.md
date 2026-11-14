# clade core inventory — scoping for v0.8-core

**Purpose**: scope a subtractive reset of clade. Decide which modules
belong in a minimal `clade-core` (matching the MATLAB ancestor +
necessary spatial/biology extensions) and which are demoted to
`inst/dev/legacy/` until a future promotion PR justifies them.

**Reviewer**: Sergio (@pooherna). Please comment in this PR with:
- Strike-throughs / annotations on the "promote?" column where you
  disagree.
- Any module you'd flag for **kernel-level review** (correctness,
  divergence from your MATLAB code) regardless of promote/demote.
- Modules I miscategorised.

**No code in this PR.** Just the inventory. Implementation PRs follow
after your review.

---

## Method

For each Julia module file in `inst/julia/src/modules/`:

1. **Vignette use** — is the module exercised by at least one
   `paper-*.Rmd` (paper reproduction) or `s-*.Rmd` (scenario)?
2. **Test coverage** — is there a passing `test-*.R` that exercises
   the module's behaviour (not just spec-presence)?
3. **Julia consumer** — is the gate flag (and key spec fields) read
   in Julia? Confirmed by `tests/testthat/test-spec-wiring.R` +
   `dev/audit/spec-wiring-audit.md`.
4. **Ancestor link** — did the MATLAB code (`Bulitko 2023`,
   `~/Dropbox/Github Local/alifeR/alife_matlab/codebase/`) have this
   concept, or is it a clade-only addition?

**Promote rule (default proposal)**: a module goes into v0.8-core only
if (vignette + test + Julia consumer + ancestor link) ≥ 3 of 4 AND it
is referenced by at least one **paper-reproduction** vignette. Sergio
overrides.

---

## Kernel files (always-core — not subject to demote)

These are the absolute foundation. Each gets explicit Sergio review
against MATLAB ancestor regardless of "promote" verdict.

| File | What it does | MATLAB ancestor analog | Sergio review priority |
|---|---|---|---|
| `types.jl` | `DiploidGenome`, `Agent`, `Environment` structs | `alife.m` agent struct | high |
| `genome.jl` | Meiosis, trait expression, genome distance | `cross_over.m`, `mutate.m` | high |
| `tick.jl` | Per-tick agent update (sense → decide → act → eat → energy) | `alife.m:300-450` | **highest** — random tick order + one-per-cell already on Sergio's list |
| `sense.jl` | Sensory input vector | `alife.m:200-300` | **high** — sense semantics divergence flagged in #120 |
| `reproduce.jl` | Meiosis → brain → offspring placement | `alife.m:380-420` | **high** — one-per-cell offspring fix already on Sergio's list |
| `death.jl` | Mortality (starvation, age, Gompertz) | `alife.m:430-450` | medium |
| `logging.jl` | `log_tick!`, `log_genomes!`, `_init_progress`, `_init_deaths` | — | low — pure logging |
| `Clade.jl` | Tick loop dispatch, R↔Julia bridge | `alife.m` main loop | high (ordering decisions in tick loop) |

---

## Brain architectures (all four implemented; rest are reserved-only)

| Brain | File | Vignette | Test | MATLAB | Verdict |
|---|---|---|---|---|---|
| BNN | `brains/bnn.jl` | s-baldwin, s-brain-comparison | test-brains.R | no (clade-only) | **core** — default brain |
| ANN | `brains/ann.jl` | s-brain-comparison | test-ann.R, test-brains.R | `alife.m` (MLP) | **core** |
| CTRNN | `brains/ctrnn.jl` | s-brain-comparison | test-brains.R | no (clade-only) | **core** |
| GRN | `brains/grn.jl` | s-brain-comparison | test-brains.R | no (clade-only) | **core** |
| Random (baseline) | `Clade.jl::RandomBrain` | — | test-brains.R | — | **core** — sanity-check null model |
| Transformer | — (placeholder) | — | — | — | **leave as reserved name** (kernel errors if requested) |
| Synthesis | — (placeholder) | — | — | — | **leave as reserved name** |

Default: BNN. The four working brains share a single `AbstractBrain`
dispatcher (`make_brain` in `Clade.jl`). Sergio: do any of CTRNN / GRN
diverge from common neural-net practice in ways that concern you?

---

## Modules — 30 candidates

Sort key: paper-reproduction vignette use (highest signal of "the
module is actually used by clade's scientific contribution") → test
presence → Julia consumer.

### Tier 1 — promote (8 modules): used by a paper-reproduction vignette

These are the modules that earn their keep by appearing in at least
one published-paper reproduction. The paper-reproductions ARE clade's
scientific contribution; the modules that drive them are the
non-negotiable core.

| Module | Paper-reproduction | Scenario vignette | Test | Julia consumer | MATLAB | Promote? |
|---|---|---|---|---|---|---|
| `personality.jl` | paper-wolf2007 | — | test-personality-syndrome.R | yes | no (0.7.0) | **yes** |
| `reciprocity.jl` | paper-trivers1971 | — | test-reciprocal-altruism.R | yes | no (0.7.0) | **yes** |
| `responsiveness.jl` | paper-wolf2008 | — | test-responsive-personalities.R | yes | no (0.7.0) | **yes** |
| `parental_care.jl` | paper-griesser-2023 | s-parental-care | test-parental-care.R | yes | no (clade) | **yes** |
| `cooperative_breeding.jl` | paper-emlen-1982 | s-cooperation | test-cooperative-breeding.R | yes | no (clade) | **yes** |
| `signals.jl` | paper-ryan-1990, paper-fuller-2005, paper-kokko-brooks-2003 | s-signals, s-mating-systems | test-signals-matechoice.R, test-scenario-signals.R | yes | no (clade) | **yes** |
| `tick_predators.jl` | paper-courchamp-1999 (Allee + predation), paper-griesser-2023 (predation pressure) | s-predator-prey, s-predation-neural | test-predators.R | yes | yes (alife.m predators) | **yes** |
| `speciation.jl` | paper-dieckmann-doebeli-1999 | s-speciation | test-speciation.R | yes | no (clade) | **yes** |

### Tier 2 — promote (5 modules): foundational biology used everywhere

Not in a paper-reproduction vignette explicitly, but provides
foundational machinery that other modules + the kernel rely on.

| Module | Justification | Scenario | Test | Julia consumer | MATLAB | Promote? |
|---|---|---|---|---|---|---|
| `body_size.jl` | Metabolic scaling (Kleiber) — used by life-history work | s-body-size, s-pace-of-life | test-body-size.R | yes | partial | **yes** |
| `brain_size_evolution.jl` | Cognitive-foraging — paper-griesser-2023 mentions this | s-brain-size | test-brain-size-evolution.R | yes | no (clade) | **yes** |
| `dispersal.jl` | Dispersal evolution — paper-griesser would need this | s-dispersal-ifd | test-dispersal.R | yes | yes (alife.m has movement) | **yes** |
| `kin.jl` | Hamilton's rule — referenced by many cooperation discussions | s-kin | test-modules-disease-kin.R | yes | no (clade) | **yes** |
| `seasonal.jl` | Seasonal mortality — paper-reale-2010 implicit | s-seasonal | test-seasons.R | yes | no (clade) | **yes** |

### Tier 3 — promote with caveat (4 modules): used but flagged for review

Used in scenarios but no paper-reproduction. Promote, but Sergio,
flag any of these for kernel-level review.

| Module | Scenario | Test | Julia consumer | MATLAB | Promote? |
|---|---|---|---|---|---|
| `disease.jl` | s-disease | test-modules-disease-kin.R | yes | no (clade) | **yes** (paper-reale-2010 sometimes uses) |
| `mimicry.jl` | s-mimicry | test-mimicry.R, test-mimicry-batesian.R | yes | no (clade) | **yes** (complex; check) |
| `niche.jl` | s-niche | test-niche-heritable.R | yes | no (clade) | **yes** |
| `complex_landscape.jl` | s-complex-landscape | test-complex-landscape.R | yes | no (clade) | **yes** (multi-layer foraging) |

### Tier 4 — demote-candidate (6 modules): orphaned or duplicated

Used by an `s-*` scenario but no paper-reproduction, OR functionality
overlaps with another module. **Default: demote to legacy.** Sergio:
override any you want to keep in core.

| Module | Scenario | Test | Julia consumer | MATLAB | Promote? |
|---|---|---|---|---|---|
| `habitat_preference.jl` | s-dispersal-ifd | test-habitat-preference.R | yes | no (clade) | **demote** — overlaps with dispersal |
| `group_defense.jl` | s-group-defense | test-group-defense.R | yes | no (clade) | **demote** — no paper-reproduction |
| `social_learning.jl` | s-social-learning | test-rl-social.R | yes | no (clade) | **demote** — no paper-reproduction |
| `scavenging.jl` | s-scavenging | test-modules-cooperation-scavenging-niche.R | yes | no (clade) | **demote** — no paper-reproduction |
| `cooperation.jl` | s-cooperation | test-modules-cooperation-scavenging-niche.R | yes | no (clade) | **demote** — public-goods game; overlaps with `kin` + `reciprocity` |
| `plasticity.jl` | s-plasticity, s-baldwin | test-plasticity.R | yes | no (clade) | **demote** — phenotypic plasticity is one bool flag; can be in core, but the file is large and the test coverage is shallow |

### Tier 5 — demote (7 modules): no clear use case

No paper-reproduction, no scenario vignette (or very shallow one), no
test (or shallow test). **Default: demote.** Sergio override if needed.

| Module | Notes | Promote? |
|---|---|---|
| `ann_regularization.jl` | L1/L0 weight regularisation — feature add-on for ANN brain; one bool flag | **demote** |
| `coevolving_parasite.jl` | Hamilton 1980 Red Queen — interesting but no vignette / shallow test | **demote** |
| `epigenetics.jl` | Methylation inheritance — test-epigenetics.R but no scenario / paper | **demote** |
| `fixed_patch.jl` | Single fixed-rich-cell scenario helper | **demote** — utility, not biology |
| `lamarckian.jl` | Within-lifetime learning → genome writeback. Niche flag. | **demote** |
| `rl.jl` | REINFORCE within-lifetime updates. s-rl exists, no paper. | **demote** — orthogonal to the evolutionary kernel |
| `spatial_sorting.jl` | Range-front dispersal. No paper-reproduction, narrow scenario. | **demote** |

---

## Summary

| Tier | Verdict | Count |
|---|---|---|
| Kernel | Always-core (foundational) | 8 files |
| Brains | Promote BNN, ANN, CTRNN, GRN, Random; transformer/synthesis remain reserved names | 5 of 7 |
| Tier 1 | Promote (paper-reproduction users) | 8 modules |
| Tier 2 | Promote (foundational biology) | 5 modules |
| Tier 3 | Promote with caveat | 4 modules |
| Tier 4 | Demote (no paper-reproduction, overlapping or shallow) | 6 modules |
| Tier 5 | Demote (no clear use case) | 7 modules |

**Proposed v0.8-core**: 8 kernel files + 5 brains + 17 modules
(Tiers 1-3) = ~30 files of biology, down from 38 today. Spec fields
proportionally down from ~300 to ~150 (estimate; precise count after
inventory pass).

**Demoted to `inst/dev/legacy/`**: 13 modules. Still build-able if
flags exist; not exposed via top-level user docs; no test guarantees.

---

## Open questions for Sergio

1. **Sense semantics**: your issue #120 — should v0.8-core ship with
   `sense_mode = "per_cell"` (default, current clade) or
   `"weighted_sum"` (alifeR-faithful)? My lean: add the option,
   default to current; document the trade-off in the
   `vignette("kernel-as-biology")`.
2. **Mutate function consolidation**: your issue #111 — should v0.8-core
   consolidate `_mutate_weights` (genome.jl) with per-brain
   `mutate` methods? Doing this in the reset is natural.
3. **MATLAB-faithful vs clade-native handling**: do you want each
   kernel file (tick, reproduce, sense, death) to have a header
   comment "MATLAB ancestor: alife.m:XXX-YYY; deviates in [...]"
   to make divergences explicit?
4. **Tier 4 / Tier 5 strikes**: any of those 13 modules you'd insist
   on keeping in core? Flagging them now is much cheaper than
   demoting then re-promoting.
5. **Brain architectures**: BNN was added as a clade-only architecture
   (your MATLAB code uses MLP/ANN). Do you have a view on whether BNN
   should be the default or whether ANN should reclaim the default
   slot for ancestor compatibility?

---

## After Sergio reviews

Once this inventory is locked, implementation proceeds:

- **PR-1** (~Week 2): strip kernel to the 8 kernel files only.
  All modules including the 17 promoted ones get temporarily
  disabled. Verify core kernel runs at the MATLAB-default spec set.
- **PR-2** (~Week 2-3): re-add kernel-level fixes (random tick order,
  one-per-cell movement, one-per-cell offspring placement) with
  Sergio's commit-by-commit review against MATLAB.
- **PR-3** (~Week 3): promote the 8 paper-reproduction-driving
  Tier 1 modules back into core. Re-run all paper-reproduction
  vignettes; confirm headline correlations match the 0.7.0 numbers
  within seed-to-seed noise.
- **PR-4** (~Week 3-4): promote Tier 2 and Tier 3.
- **Week 4**: lock the core. Either merge to main as v0.8.0 OR
  document as a checkpoint and pause.

In parallel on `main` (no Sergio dependency): Rose+Pat remediation
plan from `~/.claude/plans/purring-honking-dove.md`.
