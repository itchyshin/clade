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

## Multi-seed re-run (2026-05-16, McElreath rds generated)

Ran `dev/audit/fidelity/paper_mcelreath_2007.R` (3 horizons × 8 seeds = 24 sims, ~24 min wall-clock). **The peak-then-decay pattern McElreath predicts does NOT appear at 8 seeds.**

### cor(bold, aggro) by horizon

| Horizon (ticks) | n_seeds | mean ± SE |
|---|---|---|
| short (2000) | 8 | **−0.0746 ± 0.0447** |
| mid (5000) | 8 | **−0.0774 ± 0.0488** |
| long (15000) | 8 | +0.0341 ± 0.0488 |

- The single-seed observation "peaks at +0.307 around 5 000 ticks then decays to +0.032 by 15 000" doesn't survive multi-seed scrutiny.
- The multi-seed pattern is **null at every horizon** (none reach 2σ PASS).
- The single-seed +0.307 at 5000 ticks was a noise-envelope landing on the positive tail — multi-seed mean at the same horizon is −0.077.
- Trait-mean stability check confirms: `mean(exploration)` is essentially constant across horizons (0.119 → 0.112 → 0.113), so the population *is* in a stable equilibrium structure — the syndrome simply isn't there to decay.

### Asset-protection correlations

| Horizon | cor(exp, bold) mean ± SE | cor(exp, aggro) mean ± SE |
|---|---|---|
| 2000 | +0.035 ± 0.029 | **−0.172 ± 0.042** (t = −4.12 PASS-negative) |
| 5000 | −0.069 ± 0.035 | −0.020 ± 0.044 |
| 15000 | +0.015 ± 0.027 | −0.063 ± 0.042 |

Interesting: cor(exp, aggro) at 2000 ticks is **−0.172 with t = −4.12**, which is a PASS for the predicted negative asset-protection sign. This is the only multi-seed cell in any of the three Wolf 2007 reproductions (Wolf 2007 + Massol-Crochet + McElreath) that produces a 2σ PASS in the predicted direction — and it's at the SHORTEST horizon, opposite to McElreath's "peak then decay" prediction. Worth flagging.

### Reclassification

The vignette claims McElreath's critique is "**strongly borne out**" based on a single-seed trajectory showing peak-then-decay. At 8 seeds, **the trajectory is null-flat across all three horizons** — neither McElreath's transience prediction nor Wolf's syndrome appears robustly. The honest verdict is "the syndrome simply doesn't emerge in clade's spatially-explicit kernel at 8 seeds; therefore both Wolf's claim AND McElreath's transience critique are untestable at this sample size."

A larger sample (16+ seeds) might resolve whether the cor(exp, aggro) PASS at 2000 ticks is robust. ~40 min additional compute.

## Vignette prose update (2026-05-16)

✅ **Done in PR #142**: vignette updated.

- "Observed pattern" table caption changed to "single seed = 42 only"; added forward-pointer to the new Multi-seed section.
- New **"Multi-seed verification (2026-05-16)"** section with per-cell tables for bold-aggro, asset-protection correlations, and trait-mean stability. Surfaces the surprise PASS-negative for `cor(exp, aggro)` at 2 000 ticks.
- "Reading the result" rewritten from "**strongly borne out**" to honest revision: at 8 seeds, neither Wolf's syndrome nor McElreath's transience prediction is testable because there's no robust signal to be transient or persistent. The only robust finding is in `cor(exp, aggro)`, opposite to McElreath's prediction.
- "Two critiques together" section updated to reflect that both critique vignettes' single-seed apparent-confirmations dissolve at multi-seed, converging on a cumulative Wolf 2007 null.

## 16-seed verification (2026-05-16, PR #147)

✅ **Done.** Ran `dev/audit/fidelity/paper_mcelreath_2007_16seed.R`
(16 seeds × 2000 ticks, 4.1 min wall-clock; saved to
`dev/audit/fidelity/paper_mcelreath_2007_16seed.rds`). Hypothesis:
the surprise PASS-negative for cor(exp, aggro) at 2000 ticks
hardens with more seeds.

**Hypothesis confirmed.** The signal survives the doubled sample:

| Sample | mean | SE | t | verdict |
|---:|---:|---:|---:|:---|
| 8 seeds (PR #141)  | −0.172 | 0.042 | −4.12 | PASS-negative |
| 16 seeds (this) | **−0.100** | **0.031** | **−3.26** | **PASS-negative** |

Mean magnitude dropped (−0.17 → −0.10) but SE tightened (0.042 →
0.031), so the t-statistic stays well above 2σ. **The
asset-protection signal in cor(exp, aggro) at the shortest
horizon (2000 ticks) is a robust positive finding** — the only
multi-seed cell across all three Wolf-2007-family reproductions
that produces a 2σ PASS in the predicted direction, now confirmed
at twice the sample size.

This is a real candidate for Sergio's v0.8-core review:
clade's spatial Wolf 2007 *does* produce an asset-protection
signal, but it appears in `cor(exp, aggro)` specifically, at the
early end of the time range, opposite to McElreath's prediction.

## Deferred fixes

- Cross-reference from `paper-wolf2007.Rmd` to this vignette and to paper-massol-crochet-2008 is in place via the "Critique-aware framing" section (updated in PR #142).
