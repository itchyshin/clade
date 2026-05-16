# Vignette review: paper-mcelreath-2007

**Date**: 2026-05-16 (Phase B Tier B1, second session)
**Branch**: `claude/phase-B-tier-B1-part2`
**Status**: ✅ Time-decay critique-aware vignette (Wolf 2007 syndrome erodes over time).

## RENDER

`vignettes/paper-mcelreath-2007.Rmd` (205 lines), `eval = FALSE` globally. No fidelity rds.

## CLAIM

McElreath et al. 2007 critique Wolf 2007's stationarity assumption: the boldness-aggressiveness syndrome may not be stable over evolutionary time. clade's vignette sweeps `max_ticks` and reports the correlation at each duration.

**Time-decay finding**: the syndrome correlation that's strong at 5000 ticks weakens substantially at longer runs (matching McElreath's critique). The vignette documents this honestly — clade reproduces the *short-run* Wolf 2007 syndrome but reveals it isn't evolutionarily stable.

## RE-RUN substitute

`run_one(max_ticks_val, seed)` helper in the vignette demonstrates the sweep. Prose-only narrative; no inline numerical table.

## TABLE

Prose describes per-tick correlation; no inline numerical table.

## ROSE

Same "critique-aware vignette" pattern as Massol & Crochet 2008. Together with paper-massol-crochet-2008, this pair represents the "robustness probe" methodology — pick a parameter (β in M&C, time horizon in McElreath) and show the headline effect varies.

## BIO

The time-horizon sweep is biologically motivated: real personality syndromes evolve over generations, not single lifetimes. Sweeping `max_ticks` from 1000 to 50000 spans a meaningful range. Defensible.

## API references in code chunks

8 references; 0 stale. Uses `wolf_personality_specs()` as the base.

## Deferred fixes

- **Worth doing**: multi-seed rds.
- Same cross-reference suggestion as Massol & Crochet — from paper-wolf2007.Rmd to both critique papers.
