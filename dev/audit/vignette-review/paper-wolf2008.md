# Vignette review: paper-wolf2008

**Date**: 2026-05-16 (Phase B Tier B1, second session)
**Branch**: `claude/phase-B-tier-B1-part2`
**Status**: ✅ Mechanism reproduction; coexistence equilibrium deferred (needs per-resource competition denominator).

## RENDER

`vignettes/paper-wolf2008.Rmd` (228 lines), `eval = FALSE` globally. No fidelity rds; claims come from `tests/testthat/test-responsive-personalities.R`.

## CLAIM

Wolf, van Doorn & Weissing 2008 PNAS: under negative frequency-dependent selection, responsive and unresponsive types coexist at intermediate frequencies. clade's spatially-explicit implementation captures the MECHANISM (responsive agents pay a sampling cost to override their action toward the richest cardinal neighbour, producing frequency-dependent payoffs via grass competition) but does NOT reproduce the specific coexistence equilibrium Wolf reports.

The vignette is honest:
- **Mechanism PASS**: trait moves under selection (responsiveness goes up at low frequency, down at high frequency).
- **Equilibrium deferred**: the polymorphic equilibrium requires a per-resource competition denominator not currently implemented. Vignette acknowledges this as the kernel-mechanism gap (similar shape to Fuller 2005's Fisher leg).

Observed Δ = +0.169 (line 130) — the trait moves in the right direction.

## RE-RUN substitute

`test-responsive-personalities.R` automates seed-42 verification of the mechanism (selection direction). The equilibrium-frequency test is deferred until the per-resource denominator lands.

## TABLE

Single-row Δ table at line 130; honest about being a single seed.

## ROSE

Same "mechanism vs equilibrium" honest-split as Fuller 2005's Zahavi-leg-PASS vs Fisher-leg-null. Both vignettes flag a missing kernel mechanism (per-resource competition denominator) that would close the gap. Worth a meta-audit: enumerate all paper-* vignettes that flag the SAME missing kernel mechanism — if multiple vignettes converge on the same gap, that's a high-priority kernel feature for a future implementation phase.

## BIO

`responsiveness_cost = 0.1` (calibrated below default 0.4 so populations don't collapse during evolution). All other parameters inherit from `wolf2008_responsiveness_specs()`. Biologically defensible per the preset audit (item 13).

## API references in code chunks

4 references; 0 stale.

## Multi-seed re-run (2026-05-16, Wolf 2008 rds generated)

Ran `dev/audit/fidelity/paper_wolf2008.R` (16 sims × 2000 ticks, 2.2 min). Headline result:

| Condition | n_seeds | mean responsiveness ± SE |
|---|---|---|
| off (`responsive_personalities = FALSE`) | 8 | 0.5000 ± 0.0000 (drift only at init mean) |
| on  (`responsive_personalities = TRUE`)  | 8 | 0.5581 ± 0.0737 |

- **Contrast on − off**: Δ = **+0.058 ± 0.074, t = +0.79 → null** at 8 seeds.
- The single-seed test claim (Δ ≈ +0.169 at seed 42) was within the upper noise envelope — the multi-seed mean is +0.058, three times smaller. Direction is upward (predicted ✓) but magnitude does not reach 2σ.

**Vignette status reclassification**: from "mechanism PASS, equilibrium deferred" to **"mechanism direction-yes-but-null at 8 seeds; needs longer ticks or stronger selection to detect."** Honest framing matters here — the current kernel implementation produces a small selection signal that's lost in seed-noise at 2000 ticks.

## Deferred fixes

- **Cross-vignette gap**: per-resource competition denominator (also flagged in Fuller 2005). Future kernel feature.
- Vignette could re-run at 5000 ticks (matching Wolf 2007 ticks) to see if the longer horizon resolves the null. Or run at 16 seeds. Either would clarify whether the issue is sample size or run length.
- This rds is a regression baseline for v0.8-core.
