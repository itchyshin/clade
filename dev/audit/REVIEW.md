# Scenario audit — final 0.3.0 state

35 of 35 scenario vignettes (`vignettes/s-*.Rmd`) audited end-to-end against
the Julia kernel. Stable final state maintained across 20+ rounds of fixes
and new feature additions.

## Headline

| Bucket | Count | Meaning |
|---|---|---|
| OK | 31 | displayed chunk reproduces the vignette's stated finding |
| NO_RUN | 2 | search-only scenarios (s-bad-science, s-map-elites); no trajectory to check — by design |
| NO_ORACLE | 2 | aggregate galleries (s-cross-module, s-module-comparison); no single metric — by design |

## How to re-run

```bash
# Full audit (one warm Julia session, ~6 min):
Rscript dev/audit/run_audit.R

# One scenario only:
Rscript dev/audit/run_audit.R --only s-baldwin.Rmd

# Text-only drift scan (no Julia, <30 s):
Rscript dev/audit/dry_run_parse.R

# CMA-ES auto-calibration across all 31 runnable scenarios (~5 min parallel):
bash dev/audit/calibration/run_all.sh

# Just one scenario's calibration:
Rscript dev/audit/calibration/run_one.R s-plasticity
```

Artifacts land in `dev/audit/_artifacts/` (gitignored).

## What this audit produced

### Kernel-level biology fixes (18-commit series on `scenario-audit-0.2.0`)

1. **Parental-care graduation pathway** — `reproduce.jl:126` was a Phase-2
   stub; offspring now correctly enter `ag.carried_offspring` and graduate
   through `graduate_offspring!()`. Two vignettes (s-parental-care,
   s-parental-investment) that previously showed `n_juveniles = 0`
   throughout now produce real juvenile trajectories.
2. **BNN REINFORCE score function** — `mu[i] += lr * advantage * sigma[i]`
   was replaced with the true Gaussian-policy score
   `mu[i] += lr * advantage * (w_sample[i] - mu[i]) / sigma[i]^2`, matching
   Williams (1992) and Blundell et al. (2015) §3.2. Required caching the
   Thompson-sampled weight vector (new `BNNBrain.last_sample` field).
3. **Parliament-of-genes** — `n_cooperators` was counted across all
   neighbours; now split into `n_coop_relatives` so the intragenomic
   suppression fires on kin cooperation specifically (Haig 2000).
4. **Predator sensory architecture** — `seed_predators!` now builds
   predator brains with a fixed 15-input architecture matching
   `_sense_predator()`, independent of prey `input_radius` and optional
   sensory modules.
5. **Per-agent mutation_sd** — when `mutation_rate_evolution = TRUE`,
   `reproduce.jl` now reads `parent.mutation_sd` as the meiosis base rate.
   Previously `specs["mutation_sd"]` was read unconditionally so the
   evolved trait never propagated.
6. **ann.jl → bnn.jl include order** — `_quantize_brain_weights!(::BNNBrain)`
   was defined in ann.jl before BNNBrain was loaded (fatal under Julia 1.11+).
   Method moved to bnn.jl.
7. **Julia Manifest regenerated** for Julia 1.11+ (previous manifest pinned
   Statistics 1.10).
8. **Randperm imported** in Clade.jl after the parental-care fix enabled
   the `graduate_offspring!` code path.
9. **Ecology corrections**: spatial_sorting + toroidal=TRUE now warns; SIR
   documented as density-dependent; toxicity_cost_per_tick raised 0.5 → 2.0
   to honour the Zahavi handicap.

### New mechanistic features

- **Batesian mimicry** (`batesian_mimicry = TRUE`). Palatable mimics share
  in learned aversion; predator betrayal decay prevents runaway cheating.
  Tests in `test-mimicry-batesian.R`.
- **Heritable niche construction** (`shelter_occupancy_bonus > 0`).
  Occupants of sheltered cells receive `bonus × depth` energy per tick —
  ancestors' constructions benefit descendants. New `n_shelter_occupied`
  logging column. Tests in `test-niche-heritable.R`.

### CMA-ES auto-calibration harness

31 scenarios searched in parallel with per-scenario fitness functions
encoding each vignette's biological claim. Full writeup at
[`dev/audit/calibration/RESULTS.md`](../calibration/RESULTS.md). Headline
biology finding: the Baldwin effect emerges in clade at
`grass_rate ≈ 0.027`, `learning_rate_init_mean ≈ 0.007` — canalization was
not mechanistically impossible, just absent at the originally-displayed
defaults.

### Continuous integration

`.github/workflows/R-CMD-check.yaml` and `pkgdown.yaml` run on every push
and PR. Tests skipped in CI (need Julia) but check catches package-level
regressions.

### Documentation

- NEWS.md has a full 0.3.0 section with every change grouped by theme.
- CITATION, DESCRIPTION, README, `?clade` all at 0.3.0.
- Every vignette's What-we-found section reflects the current kernel.
- 35 scenarios audited; 15 with meaningful CMA-ES improvements got a
  "Calibrated regime (CMA-ES discovered)" subsection.
- Figures regenerated end-to-end by the three generator scripts under
  `vignettes/generate_figures.R`, `gen_hn_fig.R`, `gen_fixed_patch_fig.R`.

## Links

- [dev/audit/review/SUMMARY.md](../review/SUMMARY.md) — critical-review
  triage of brains / social / ecology / traits domains.
- [dev/audit/calibration/RESULTS.md](../calibration/RESULTS.md) —
  Phase 7 auto-calibration discoveries.
- [dev/audit/calibration/DEEP_AND_TASK3_RESULTS.md](../calibration/DEEP_AND_TASK3_RESULTS.md)
  — deeper CMA-ES + Task 3 follow-ups.
- [dev/audit/consolidation_report.md](../consolidation_report.md) —
  ~550 lines of refactor opportunities, scheduled for 0.4.0.
- [dev/audit/design/batesian_mimicry.md](../design/batesian_mimicry.md)
- [dev/audit/design/niche_inheritance.md](../design/niche_inheritance.md)
