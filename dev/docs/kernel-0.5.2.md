# Kernel 0.5.2 — body-size P2 direction resolution

Released 2026-04-16.

## Motivation

The s-body-size audit has been ✅ since 0.4.1, but the P2
(predation direction) sign was seed-noise-sensitive across the
0.4.1 → 0.4.3 release chain:

- 0.4.1 (binary predator sensing, 5 seeds): Δ ratio 0.81 — predation
  *slows* drift. Framed as Brooks & Dodson (1965) size-detectability
  direction.
- 0.4.3 (graded predator sensing default, 5 seeds): Δ ratio 1.08 —
  predation *accelerates* drift. The Shine et al. (2011) direction.

Both were within 5-seed noise. The audit md documented the
sensitivity and flagged a 16-seed resolution for the 0.5.2 backlog.

This release closes that loop. No kernel changes — audit-only
resolution via a 16-seed × 2-sensing-mode × 2-predator-level factorial.

## Changes

### Rewritten body_size audit

**File:** `dev/audit/fidelity/body_size.R`.

Previous protocol: 5 seeds × 2 predator levels = 10 runs.
New protocol: 16 seeds × 2 sensing modes × 2 predator levels = 64
runs. Explicit 2×SE criterion for P2 direction calls.

Cells:

| graded | n_pred | description |
|---|---|---|
| FALSE | 0 | binary sensing, no predators (control) |
| FALSE | 10 | binary sensing, 10 predators (0.4.1 regime) |
| TRUE | 0 | graded sensing, no predators (control) |
| TRUE | 10 | graded sensing, 10 predators (0.4.2+ default regime) |

P2 direction is called "accelerates" / "slows" / "flat" using a
2×SE window on the predator-vs-control difference. This is the
standard hypothesis-testing criterion and produces robust direction
calls under realistic seed noise.

## Audit impact — resolution

16-seed factorial results:

| graded | n_pred | Δ mean_body_size | 1×SE |
|---|---|---|---|
| FALSE | 0  | +0.0870 | 0.0070 |
| FALSE | 10 | +0.0963 | 0.0118 |
| TRUE  | 0  | +0.1074 | 0.0060 |
| TRUE  | 10 | +0.1110 | 0.0099 |

**P1 (Cope direction) robust**: all four cells show +8.7% to +11.1%
upward drift with SE ~0.6–1.2%. Cope's rule is statistically clean
in clade.

**P2 (predation direction) NULL under both sensing modes**:

- Binary sensing: Δ(with-pred) − Δ(no-pred) = +0.009 ± 0.014 → flat
- Graded sensing: Δ(with-pred) − Δ(no-pred) = +0.004 ± 0.012 → flat

The earlier 5-seed ratio-0.81 "detectability" (0.4.1) and ratio-1.08
"Shine-accelerates" (0.4.3) claims were both seed-noise artefacts.
At 16 seeds, neither direction is statistically supported — so
clade produces Cope's rule robustly but does not reproduce any
particular predator-mediated size selection at default parameters.

**Secondary observation**: graded predator sensing (0.4.2 default)
produces +0.107 Cope drift vs binary sensing's +0.087 — an
SE-bounded real effect. Finer threat information → more efficient
foraging → support for larger bodies. A side benefit of the 0.4.2
sensing polish.

s-body-size stays ✅ (Cope direction robust) with the P2 direction
claims retracted. Both prior framings (Shine 2011 and Brooks-Dodson
1965) are superseded by the 16-seed null finding on P2.

## Files touched

- `dev/audit/fidelity/body_size.R` — rewritten as 16-seed × 2×2
  factorial with explicit 2×SE hypothesis test.
- `dev/audit/fidelity/body_size.md` — updated with 16-seed
  verdict (post-run).

## Out of scope

- Kernel changes: none. P2 direction is an emergent ecological
  property of the existing kernel, not a kernel bug.
- Other 🟠 scenarios (s-plasticity, s-baldwin, s-mimicry,
  s-dispersal-ifd): deferred to future work. s-mating-systems is
  tracked in 0.5.0 / 0.5.1.
