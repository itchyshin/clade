# Vignette review: paper-massol-crochet-2008

**Date**: 2026-05-16 (Phase B Tier B1, second session)
**Branch**: `claude/phase-B-tier-B1-part2`
**Status**: ✅ Critique-aware vignette (β sweep over Wolf 2007 syndrome).

## RENDER

`vignettes/paper-massol-crochet-2008.Rmd` (175 lines), `eval = FALSE` globally. No fidelity rds.

## CLAIM

Massol & Crochet 2008 critique Wolf 2007's choice of life-history trade-off curve g(x) = (1−x)^β. They argue β = 1 (linear) is more biologically defensible than Wolf's β = 1.25; the syndrome should be sensitive to β. clade's vignette sweeps `personality_beta` across {0.5, 1.0, 1.25, 2.0} and reports the boldness-aggressiveness correlation at each.

**Critique-aware reproduction**: the vignette doesn't claim Wolf is right or wrong; it documents that the result depends on the β choice, validating Massol & Crochet's methodological concern.

## RE-RUN substitute

Vignette includes a `run_one(beta_val, seed)` helper that demonstrates the sweep methodology. No saved rds; prose describes the qualitative shape (correlation strength varies non-monotonically with β).

## TABLE

The vignette uses prose narration of the sweep results — no inline numerical table beyond per-beta correlation magnitudes embedded in the narrative.

## ROSE

**"Critique-aware vignette."** This is a different paper-* shape: not a direct reproduction of a primary-literature finding, but a methodological probe of a parameter choice in another paper's model. Worth canonicalising — `paper-massol-crochet-2008` and `paper-mcelreath-2007` both follow this pattern (probing Wolf 2007's robustness). Useful template for "critique a published parameter choice" workflow.

## BIO

The β sweep is the natural way to test parameter sensitivity. Wolf's 1.25 falls in the middle of the swept range; the sweep is fair. Biologically defensible.

## API references in code chunks

9 references; 0 stale. Uses `wolf_personality_specs()` as the base.

## Deferred fixes

- **Worth doing**: multi-seed rds. Currently single-seed-per-cell.
- Cross-reference from `paper-wolf2007.Rmd` to this vignette (β robustness) and to paper-mcelreath-2007 (time-decay robustness).
