# Vignette review: paper-template

**Date**: 2026-05-16 (Phase B Tier B1, second session)
**Branch**: `claude/phase-B-tier-B1-part2`
**Status**: ✅ Template — meta-vignette demonstrating the paper-reproduction methodology.

## RENDER

`vignettes/paper-template.Rmd` (342 lines), `eval = FALSE` globally. This is a template for users to copy when reproducing their own paper.

## CLAIM

No quantitative claim — this is meta-content. The template walks a user through the standard 5-step paper-reproduction workflow:

1. Identify the paper's headline quantitative prediction.
2. Calibrate parameters with `default_specs()` / `*_specs()` presets.
3. Sweep across the relevant gradient using `hypothesis_sweep()`.
4. Compute contrasts using `hypothesis_report()`.
5. Render verdict honestly: PASS / marginal / null / contradicts.

The 4 "stale" references the API scan flagged (`YOUR_OUTCOME_COLUMN`, `n_agents`, `param_a`, `param_b`) are **deliberate placeholders** — users replace them with their actual paper's column/parameter names. NOT bugs.

## RE-RUN substitute

N/A — the template has no real run.

## TABLE

The template includes a model contrast-table layout (lines 200+) showing the expected mean ± SE / t / verdict format. Users fill in actual numbers.

## ROSE

**Template-as-canonical-methodology.** This vignette is the most important paper-* vignette in clade — it's the recipe that turns "I have a paper to reproduce" into a clade audit. The recipe correctly references:
- `default_specs()` + the preset family for parameter setup (item 8 walked)
- `hypothesis_sweep()` + `hypothesis_report()` for multi-seed contrast (items 9+10 walked)
- `viability_report()` for the interpretability gate (item 6 walked)
- The 2σ verdict ladder (item 9+10 audit)
- The `dev/audit/fidelity/paper_<name>.R` + rds save pattern (this Phase B's biggest ROSE finding)

Every methodological component the template references has now been walked, audited, and tested. The template is self-consistent with the package state.

## BIO

N/A — methodology only.

## API references in code chunks

23 total references; 4 placeholders (deliberate); 0 actual stale.

## Deferred fixes

- **Worth doing**: add a "see also `dev/audit/fidelity/paper_reale_2010.R` for a worked example" pointer to the template's preamble. The user gets a working template plus a complete real example to copy.
- Optional: add a paragraph on the part-1-vs-part-2 distinction (vignettes WITH saved rds vs WITHOUT) — recommend always saving the rds when reproducing.
