# Vignette review: paper-courchamp-1999

**Date**: 2026-05-16 (Phase B Tier B1, second session)
**Branch**: `claude/phase-B-tier-B1-part2`
**Status**: ✅ Allee effect reproduction; module-gap framing.

## RENDER

`vignettes/paper-courchamp-1999.Rmd` (247 lines), `eval = FALSE` globally. No fidelity rds; figure at `figures-papers/allee-courchamp-1999.png` is the saved artifact.

## CLAIM

Courchamp 1999: Allee effect — populations below a critical density go extinct. clade reproduces the qualitative effect using `allee_threshold` and a sweep over `n_agents_init`. Spearman(n_init, equilibrium) shows the predicted positive direction; the lowest densities go extinct.

The vignette frames this as a "custom-module gap" example: clade doesn't have a dedicated Courchamp-style module, but the existing `allee_threshold` parameter + initial-density sweep produces the right qualitative behaviour. Methodology insight (lines 225–227): "compose existing modules to produce custom dynamics", "compute any post-hoc metric on `get_run_data()$ticks`", "between-run interventions via spec manipulation".

## RE-RUN substitute

No rds. Prose is the baseline. Trust until v0.8-core regression check.

## TABLE

Per-density-cell sweep results live in the figure; prose narrates the verdict.

## ROSE

**"Custom-module gap via composition."** This vignette's methodology-takeaway is the canonical answer when a paper's mechanism doesn't map 1:1 onto a clade module: compose existing knobs. Worth referencing from `paper-template.Rmd` as the recipe.

## BIO

Allee dynamics emerge naturally when `allee_threshold > 0` and initial population starts below threshold; the extinction cascade is mechanistic. Defensible.

## API references in code chunks

7 references; 0 stale.

## Deferred fixes

- Optional: re-run; defer.
- Consider adding a fidelity rds for this vignette to match the part-1 pattern. ~5 min compute when convenient.
