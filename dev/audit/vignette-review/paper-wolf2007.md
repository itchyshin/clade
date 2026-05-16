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

## Multi-seed re-run (2026-05-16, Wolf 2007 rds generated)

Ran `dev/audit/fidelity/paper_wolf2007.R` (8 sims × 5000 ticks, 4.6 min). **Headline finding rewrites the verdict.**

### Per-seed correlations (8 seeds)

| seed | cor(bold, aggro) | cor(exp, bold) | cor(exp, aggro) | n_alive |
|---|---|---|---|---|
| 1 | −0.370 | −0.017 | −0.023 | 402 |
| 2 | +0.248 | +0.013 | −0.115 | 401 |
| 3 | −0.201 | +0.017 | −0.226 | 424 |
| 4 | +0.201 | +0.068 | +0.058 | 402 |
| 5 | −0.331 | −0.142 | +0.262 | 422 |
| 6 | +0.052 | +0.032 | −0.084 | 430 |
| 7 | +0.193 | −0.034 | +0.014 | 419 |
| 8 | −0.251 | +0.064 | −0.163 | 418 |

### Aggregate across 8 seeds

| correlation | predicted | mean | SE | t | verdict |
|---|---|---|---|---|---|
| `cor(bold, aggro)` | > 0 (syndrome) | **−0.057** | 0.091 | −0.63 | **null** |
| `cor(exp, bold)` | < 0 (asset-protection) | +0.0003 | 0.024 | +0.01 | **null** |
| `cor(exp, aggro)` | < 0 (asset-protection) | −0.034 | 0.054 | −0.64 | **null** |

**All three correlations are null at 8 seeds.** Individual seeds bounce between strongly positive (+0.25 at seed 2) and strongly negative (−0.37 at seed 1) for the boldness-aggressiveness syndrome — no systematic direction emerges. The single-seed test (which observes ~+0.30 at seed 42 with the per-strategy denominator) was a lucky landing on the positive end of the multi-seed distribution.

**Vignette status reclassification**: from "half-PASS (strongest prediction only)" to **"null at 8 seeds; single-seed observation was within the noise envelope, not a robust signal."** This is the kind of finding the multi-seed-rds upgrade is *designed* to surface — the Wolf 2007 personality-syndrome reproduction does not survive a rigorous statistical test in clade's current kernel.

This is also a candidate finding for Sergio's v0.8-core review — the result suggests either (a) the kernel implementation has residual issues at 5000-tick scale, (b) Wolf's mean-field result doesn't reproduce under clade's spatially-explicit interpretation even with the per-strategy denominator, or (c) more ticks / different parameter calibration are needed. Worth flagging.

## Deferred fixes

- Update vignette prose to surface the null verdict — currently the vignette overstates with "the test asserts the strongest of the three predictions". The strongest prediction is also null at 8 seeds; the single-seed pass was a noise-envelope landing.
- This rds is a regression baseline for v0.8-core: if Sergio's kernel reset changes the syndrome strength, the diff will be visible here.
