# Vignette review: paper-wolf2007

**Date**: 2026-05-16 (Phase B Tier B1, second session)
**Branch**: `claude/phase-B-tier-B1-part2`
**Status**: ✅ Personality-syndrome reproduction; single-seed test framing.

## RENDER

`vignettes/paper-wolf2007.Rmd` (298 lines), `eval = FALSE` globally. No fidelity rds; the vignette's claims come from `tests/testthat/test-personality-syndrome.R` running at seed 42 with 5000 ticks.

## CLAIM

Wolf, van Doorn, Leimar & Weissing 2007 Nature: under the asset-protection mechanism, high-exploration agents (more to lose at year 2) become less bold + less aggressive. The clade reproduction tests for the **defining feature** of the Wolf 2007 syndrome: a positive cross-context correlation between boldness and aggressiveness.

`.WOLF_R_MIN_MAGNITUDE = 0.05` in the test — the assertion is that `|cor(bold, aggro)| ≥ 0.05` at seed 42. The actual observed correlation is ~+0.30 with the per-strategy (1+α·N_i) denominator. The exploration-bold and exploration-aggro signs are weaker and noisier — the vignette and test both note this honestly and only assert the strongest of the three predictions.

## RE-RUN substitute

`test-personality-syndrome.R` automates the seed-42 verification. Multi-seed extension is the Phase B upgrade.

## TABLE

Vignette text discusses correlation pattern; no inline numerical table beyond the .WOLF_R_MIN_MAGNITUDE floor.

## ROSE

Same single-seed-test pattern as Trivers. Both Wolf 2007 and Trivers 1971 use the minimum-floor framing (assert direction, not magnitude). This is honest — the spatially-explicit clade interpretation predicts a weaker effect than Wolf's mean-field model, so claiming the published magnitude would be misleading. Worth noting: paper-wolf2007.Rmd's "spatially-explicit interpretation" discussion is the right template for any vignette where clade's spatial extension changes the expected effect size.

## BIO

`personality_alpha = 0.005` matches Wolf's published value. `wolf_year1_repro_age = 50L`, `wolf_year2_repro_age = 100L` are clade-specific (Wolf's model is non-spatial and fecundity-based; clade needs concrete tick counts). All biologically defensible per the preset audit (item 11).

## API references in code chunks

9 references; 0 stale. All inherit from `wolf_personality_specs()`.

## Deferred fixes

- **Worth doing**: multi-seed rds upgrade (same as Trivers). ~15-20 min compute.
- Optional: extend test-personality-syndrome.R to run at 3-5 seeds and assert the floor across all seeds (currently single seed). Cheaper than the rds upgrade.
