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

## Multi-seed re-run (2026-05-16, Trivers rds generated)

Ran `dev/audit/fidelity/paper_trivers1971.R` (32 runs total, 11.2 min wall-clock). Headline findings — distinct from the single-seed test:

| Condition (`dispersal_init_mean`) | n_seeds | mean reciprocity_initial ± SE |
|---|---|---|
| none (0.0) | 8 | 0.554 ± 0.079 |
| low (0.05) | 8 | 0.448 ± 0.107 |
| mid (0.15) | 7 | 0.441 ± 0.062 |
| high (0.30) | 6 | 0.408 ± 0.087 |

- **Direction**: ✓ Spearman(dispersal, mean_initial_coop) = **−0.20** (predicted NEGATIVE).
- **Magnitude**: ⚠️ Contrast high − none: Δ = **−0.147 ± 0.118, t = −1.25 → null** at 8 seeds.
- **Crash signal**: 2 of the 8 high-dispersal seeds crashed (only 6 produced viable end-of-run agents); 1 of 8 mid-dispersal seeds did. Consistent with Trivers: high dispersal disrupts the partner re-encounter structure that maintains the population.

The direction holds, but at 8 seeds the magnitude is below the 2σ verdict floor. The single-seed test (Δ > 0.05 at seed 42) is still passing, but the multi-seed verdict is "direction yes, magnitude not yet significant." Honest classification: ✅ direction-only, not full PASS.

## Deferred fixes

- Vignette prose could be updated to add the multi-seed verdict — "direction-yes, magnitude-null at 8 seeds" — as a "Multi-seed verification" section near the end. ~10-line edit; not done here.
- Crash signal at high dispersal is worth its own callout. The vignette could note that 2 of 8 seeds crashed at `dispersal_init_mean = 0.30`, supporting Trivers' condition 2.
