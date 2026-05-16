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

## Multi-seed re-run (2026-05-16, Massol-Crochet rds generated)

Ran `dev/audit/fidelity/paper_massol_crochet_2008.R` (5 β values × 8 seeds = 40 sims, ~22 min wall-clock). **The single-seed "peak at β = 1.25" doesn't survive multi-seed.**

### cor(bold, aggro) by β

| β | mean ± SE | t | verdict |
|---|---|---|---|
| 0.5 | −0.004 ± 0.067 | −0.06 | null |
| 1.0 | +0.003 ± 0.065 | +0.05 | null |
| **1.25** | **−0.077 ± 0.049** | −1.59 | **marginal-NEGATIVE** |
| 2.0 | −0.003 ± 0.054 | −0.05 | null |
| 3.0 | +0.053 ± 0.040 | +1.33 | null |

- The single-seed peak (+0.307 at β = 1.25) is now **marginal-negative** (−0.077) at 8 seeds.
- Range across β collapses from single-seed 0.39 to multi-seed **0.13**.
- **No β value produces a robust positive syndrome.** The closest to PASS is β = 3.0 at t = +1.33, still null.
- Massol & Crochet's "β-sensitive" critique is **partially borne out** (the range exists), but their implicit assumption that Wolf's specific β = 1.25 is the *peak* doesn't hold — at multi-seed scrutiny β = 1.25 is the *trough*.

### Asset-protection correlations

cor(exp, bold) and cor(exp, aggro) means are all between ±0.07 across all β values; none reach 2σ. Wolf's predicted negative signs don't emerge robustly at any β.

### Reclassification

Vignette claims the critique is "**partially borne out**" with peak at Wolf's published β = 1.25 (+0.307 single-seed). At 8 seeds, β = 1.25 is the *most negative* condition (−0.077). The β-sensitivity critique survives (correlation range is real), but the interpretation that "Wolf chose a parameter that maximised the syndrome" is contradicted — at multi-seed scale, β = 1.25 produces the worst syndrome of the swept values.

## Vignette prose update (2026-05-16)

✅ **Done in PR #142**: vignette updated.

- "Observed pattern" table caption changed to "single seed only"; added forward-pointer to the new Multi-seed section.
- New **"Multi-seed verification (2026-05-16)"** section with per-cell tables for bold-aggro and asset-protection correlations.
- "Reading the result" rewritten as "honest revision": the β-sensitivity claim survives (range exists) but the "peak at Wolf's β = 1.25" claim is contradicted — β = 1.25 is the trough at 8 seeds.

## Deferred fixes

- ~40 min compute to run at 16 seeds and check whether the marginal-negative at β = 1.25 hardens to a PASS-negative.
- Cross-reference from `paper-wolf2007.Rmd` to this vignette is in place via the "Critique-aware framing" section (updated in PR #142).
