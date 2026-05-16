# Vignette review: Tier B2 scenario vignettes (36 files)

**Date**: 2026-05-16 (Phase B Tier B2)
**Branch**: `claude/tier-B2-scenario-audit`
**Scope**: all 36 `vignettes/s-*.Rmd` scenario vignettes

Phase B Tier B1 (PRs #135 + #136) audited the 14 `paper-*.Rmd`
reproduction vignettes one at a time, each with a per-file audit
in `dev/audit/vignette-review/`. Tier B2 takes a different shape:
36 scenario vignettes is too many for per-file audits at the same
depth, AND they don't have multi-seed fidelity rds baselines (none
of the s-* vignettes have a matching `dev/audit/fidelity/s_*.rds`).

So Tier B2 is a **single bulk audit** that:

1. Catalogues every s-* vignette (length, eval setting,
   spec-field references).
2. Confirms global `eval = FALSE` is set in all of them (so they
   don't run chunks at knit time — same constraint as Tier B1).
3. Surfaces any **real stale spec-field references** (a $-accessor
   to a field that doesn't exist in `default_specs()` and isn't a
   known progress/env column).
4. Fixes the real findings inline.

## Inventory (36 vignettes)

| File | Lines |
|---|---|
| `s-bad-science.Rmd` | 84 |
| `s-baldwin.Rmd` | 549 |
| `s-baseline.Rmd` | 246 |
| `s-body-size.Rmd` | 167 |
| `s-brain-comparison.Rmd` | 219 |
| `s-brain-size.Rmd` | 209 |
| `s-cephalopod.Rmd` | 313 |
| `s-clutch-size.Rmd` | 153 |
| `s-complex-landscape.Rmd` | 168 |
| `s-cooperation.Rmd` | 158 |
| `s-cross-module.Rmd` | 222 |
| `s-disease.Rmd` | 138 |
| `s-dispersal-ifd.Rmd` | 138 |
| `s-group-defense.Rmd` | 159 |
| `s-kin.Rmd` | 168 |
| `s-kitchen-sink.Rmd` | 261 |
| `s-life-history.Rmd` | 156 |
| `s-map-elites.Rmd` | 159 |
| `s-mating-systems.Rmd` | 153 |
| `s-mimicry.Rmd` | 161 |
| `s-module-comparison.Rmd` | 211 |
| `s-niche.Rmd` | 142 |
| `s-pace-of-life.Rmd` | 167 |
| `s-parental-care.Rmd` | 150 |
| `s-parental-investment.Rmd` | 156 |
| `s-plasticity.Rmd` | 162 |
| `s-pop-genetics.Rmd` | 121 |
| `s-predation-neural.Rmd` | 171 |
| `s-predator-prey.Rmd` | 372 |
| `s-rl.Rmd` | 141 |
| `s-scavenging.Rmd` | 232 |
| `s-seasonal.Rmd` | 139 |
| `s-signals.Rmd` | 169 |
| `s-social-learning.Rmd` | 132 |
| `s-speciation.Rmd` | 151 |
| `s-stress-hypermutation.Rmd` | 156 |
| **TOTAL** | **6 327** |

## Render check (eval = FALSE)

✅ **All 36 vignettes set `eval = FALSE` globally** in their
`knitr::opts_chunk$set(...)` block. Same shape as Tier B1: code
chunks are display-only; rendered HTML pulls from saved figures
+ prose. Vignette renders don't execute Julia.

## Spec-field reference scan

Scanned every `<var>$<field>` accessor in each vignette. Refs
falling outside `names(default_specs())` AND outside the
known-safe list of progress/env columns (`n_agents`, `mean_energy`,
`ticks`, `deaths`, `genomes`, `agents`, `specs`, `viability`,
`verdict`, `cor_*`, etc., plus the 50+ tick-log columns from
`inst/julia/src/logging.jl::_init_progress`) are flagged.

**The scan's dominant "stale" ref across all 36 vignettes was
`set`** — false positive from `knitr::opts_chunk$set(...)`. Other
recurring false positives:

- `cond$brain`, `cond$rl`, `cond$label` (local condition lists in
  `s-baldwin.Rmd`)
- `h2_proxy$h2`, `h2_proxy$method` (return value of
  `estimate_heritability()` in `s-pop-genetics.Rmd`)
- `tks$grass_scaled` (local data.frame column in `s-seasonal.Rmd`)
- `df$rate` (local column in `s-bad-science.Rmd`)
- Various other local data.frame columns / list members.

**One real finding** (fixed in this commit):

- **`s-cross-module.Rmd`**: 5 instances of `base$seed <- 42L` on
  lines 36, 76, 116, 152, 188. The spec field is **`random_seed`**,
  not `seed`. The Julia kernel uses `get(specs, "random_seed",
  ...)`, so `base$seed` was silently ignored — those runs were NOT
  seed-controlled and would not have been reproducible (each
  execution would get a different random sequence). All 5 instances
  fixed: `base$seed <- 42L` → `base$random_seed <- 42L`.

## Claim-consistency spot-check

Unlike Tier B1's 14 paper-* vignettes (which make precise
quantitative claims directly testable against fidelity rds
baselines), the s-* vignettes are typically *demonstrations*
rather than reproductions: they show that a module works, what
its parameters do, and what a typical output looks like. The
"claims" are qualitative ("disease module produces SIR-like
dynamics" rather than "ρ = −0.98").

That makes the Tier B2 walk lighter than Tier B1's. The vignettes
don't need rds baselines because they don't make precise claims
against literature numbers. The quality bar is: does the code
chunk reference a valid current API, and does the prose accurately
describe what the chunk produces?

Per-file deep audits at the Tier B1 level would multiply this
file by 36× — not justified given the lower stakes. The bulk
scan above is appropriate for the scope.

## Cross-vignette pattern observations

1. **All 36 use `eval = FALSE`** — consistent with Tier B1.
   Vignette knitting is text-only; saved figures (`figures/`,
   `figures-papers/`) are the persisted artefacts.

2. **The `s-cross-module.Rmd` seed bug is the kind of class
   item-2's `test-test-field-assertions.R` drift-guard from
   PR #129 catches in TEST files but NOT in VIGNETTES.** A
   parallel drift-guard for vignette field references would close
   the loop — flagged as deferred work.

3. **Spec-field reference density varies widely**: from 4 refs
   (`s-predation-neural`) to 23+ refs (`s-baldwin`). High-density
   vignettes are the ones most likely to harbour stale refs;
   `s-baldwin.Rmd` has 549 lines and 23+ refs but the bulk scan
   found no stale ones (the `brain`, `rl`, `label` flags were
   false positives from inline condition lists).

## Deferred fixes

- **Structural drift-guard for vignette spec-field references**:
  a `tests/testthat/test-vignette-field-references.R` test that
  scans `vignettes/*.Rmd` for `<var>$<field>` patterns and asserts
  every field is in `default_specs()` OR in a known progress/env
  allowlist. Would catch the next `base$seed` accident
  automatically. Estimated 80–100 lines (modelled on
  `test-test-field-assertions.R`).
- **Per-vignette claim verification**: some s-* vignettes do
  make weak quantitative claims (e.g., "disease module reduces
  population by ~30%"). Spot-checking these against fresh runs
  is in scope for a future deeper review but out of scope for
  this bulk Tier B2 walk.

## Verdict

**Tier B2 is structurally clean** apart from the one
`s-cross-module.Rmd` seed bug, which is fixed in this commit.
All 36 vignettes use `eval = FALSE`; all real (non-false-positive)
spec-field references are valid. No further per-vignette audit
files are warranted at this depth.
