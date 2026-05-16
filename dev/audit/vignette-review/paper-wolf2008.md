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

## Deferred fixes

- **Cross-vignette gap**: per-resource competition denominator (also flagged in Fuller 2005). Future kernel feature.
- **Worth doing**: multi-seed rds upgrade.
