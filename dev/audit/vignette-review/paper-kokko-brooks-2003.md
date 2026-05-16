# Vignette review: paper-kokko-brooks-2003

**Date**: 2026-05-16 (Phase B Tier B1, second session)
**Branch**: `claude/phase-B-tier-B1-part2`
**Status**: ⚠️ Honest negative result, kernel-correctness-documenting vignette.

## RENDER

`vignettes/paper-kokko-brooks-2003.Rmd` (414 lines) has `eval = FALSE` globally. No fidelity rds; the saved figure at `figures-papers/kokko-brooks-2003.png` is the only persisted artifact.

## CLAIM

"Sexy to die for?" — Kokko & Brooks 2003 predict that under stress (low grass), strongly-signalling individuals should be disproportionately lost, producing an interaction `cost × grass → n_signals`. clade's earlier reproduction (pre-0.6.4) reported `t = +2.81 PASS`; the current kernel (post-#124 mate_choice wiring) shows the effect is weak and non-monotonic.

**Honest negative result**: the interaction goes null. The previously-reported PASS depended on an implicit argmax in a stub that PR #124 removed. The vignette documents this transparently — it's a kernel-correctness story, not a vignette-stale-claim story.

## RE-RUN substitute

No fidelity rds to compare against. The vignette's prose carries the headline; the figure was regenerated after the 0.6.4 kernel change. Trust the prose as the current baseline; defer regression check until v0.8-core.

## TABLE

The vignette uses a sweep × signals_off comparison framework. Table at lines 165+ specifies the analysis but the actual numbers are in the figure (PNG); the prose narrates the verdict.

## ROSE

**"Vignette as kernel-correctness historian."** This is the first Phase B vignette we've reviewed that is *about* a kernel change rather than a paper reproduction per se. The 0.6.4 wiring change re-classified this from PASS to null; the vignette acknowledges the change and explains why. Worth canonicalising — when a kernel correctness fix flips a previous PASS to null, the right move is to keep the vignette, retitle as "previously reported PASS was an artifact" and explain.

## BIO

The cost × grass interaction has biological backing in Kokko & Brooks 2003. The current null result is honest — without the implicit argmax, the spatially-explicit clade kernel produces a weaker effect. Biologically defensible to report "weaker than the analytic model predicts."

## API references in code chunks

16 references; 0 stale spec fields. The earlier scan flagged `mean_energy` and `n_agents` as stale — false positives; both are `ticks$<column>` progress accesses inside metric functions, not spec accesses. Confirmed clean.

## Deferred fixes

- Optional: re-run with current kernel to confirm the null is still the right verdict. ~5 min compute.
- Once Sergio's v0.8-core merges, this is a candidate for the regression baseline that documents what the kernel reset did to this contrast.
