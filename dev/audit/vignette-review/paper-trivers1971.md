# Vignette review: paper-trivers1971

**Date**: 2026-05-16 (Phase B Tier B1, second session)
**Branch**: `claude/phase-B-tier-B1-part2`
**Status**: ✅ Reciprocal-altruism reproduction; single-seed test with multi-seed expansion path.

## RENDER

`vignettes/paper-trivers1971.Rmd` (228 lines), `eval = FALSE` globally. No fidelity rds; the vignette's claims come from a single-seed test in `tests/testthat/test-reciprocal-altruism.R`.

## CLAIM

At default Trivers parameters (`reciprocity_cost = 0.5`, `b/c = 2`, `partner_memory_size = 8`, `reciprocity_radius = 1`), cooperation rises above the no-reciprocity baseline at low dispersal. The vignette **asserts only that Δ > 0.05** with seed 42; observed Δ ≈ +0.218 at that seed.

The "Δ > 0.05" framing replaces an earlier over-claim ("Δ = +0.218") flagged during the kit-install session and corrected to the floor-based assertion. This is a model of how to write a per-seed test that documents the expected magnitude without over-claiming.

## RE-RUN substitute

The test in `tests/testthat/test-reciprocal-altruism.R` re-runs at seed 42 each `devtools::test()` invocation, so the single-seed verification is automated. Multi-seed extension is the natural Phase B follow-up: sweep over dispersal rates × seeds to map the regime boundary (Trivers' condition 2).

## TABLE

The vignette explicitly suggests the sweep code (lines 270+) for multi-seed mapping but doesn't run it inline. Prose-only baseline.

## ROSE

**"Single-seed test with multi-seed expansion path."** Different from the part-1 vignettes (which use multi-seed rds baselines). Worth canonicalising: a paper-* vignette's MINIMUM is a single-seed test that asserts the predicted floor (Δ > 0.05); the IDEAL is a multi-seed rds. The Trivers vignette is at the minimum; an upgrade to ideal would mean adding `dev/audit/fidelity/paper_trivers1971.R` + rds.

## BIO

Trivers 1971 conditions encoded by the preset:
- Long lifespan (max_age = 500): condition 1 (repeat encounters).
- Low dispersal (`dispersal_evolution = FALSE`): condition 2.
- Partner memory (8 partners): condition 3.
- Reciprocity radius 1 (Moore neighborhood): spatially-explicit interpretation.

All four are biologically defensible per Trivers' original argument.

## API references in code chunks

7 references; 0 stale.

## Deferred fixes

- **Script written, rds pending compute**: `dev/audit/fidelity/paper_trivers1971.R` is now ready (8 seeds × 4 dispersal cells × 5000 ticks → 32 runs). Run it via `Rscript dev/audit/fidelity/paper_trivers1971.R` to generate the rds. ~15-20 min wall-clock with healthy Julia. Once the rds lands, this vignette graduates from "minimum framing" to "ideal" Phase B pattern.
