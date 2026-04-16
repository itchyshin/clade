# Scenario: Body size evolution (Cope's rule + size-dependent detectability)

## 1. Theory
- **Primary sources.** Cope's rule (paleontological observation;
  Stanley 1973 review). Shine, R. et al. (2011) *Proc. R. Soc. B*
  278:1449–1457 (predator-mediated size selection, cane-toad
  example). Size-dependent detectability (Brooks & Dodson 1965
  "size-efficiency hypothesis"; visual-predator fisheries
  literature, e.g. Allen 1982 *Fish. Bull.*).
- **Core prediction.**
  1. **Cope direction.** Under foraging selection with a body-size ×
     gain coupling, mean body size drifts upward.
  2. **Size-dependent predation.** Predators exert size-biased
     mortality. Direction of bias depends on which mechanism
     dominates: *large-escape* (Shine 2011) predicts predation
     accelerates the Cope drift; *size-detectability* predicts the
     opposite (large prey easier to find → predation cull the top
     tail → slower drift). clade's sensing model implements the
     detectability variant.

## 2. Implementation
- **clade Julia:** `inst/julia/src/modules/body_size.jl`.
- **alifeR:** `body_size.R`.
- **MATLAB:** N/A.

## 3. Protocol

- 0.4.1 audit: 5 seeds × 2 predator levels × 600 ticks.
- **0.5.2 resolution**: 16 seeds × 2 predator levels × 2 sensing
  modes (graded vs binary `predator_sense_graded`) = 64 runs × 600
  ticks. Direction calls use an explicit 2×SE hypothesis test on
  the predator-vs-control difference.

## 4. Observed dynamics

### 0.5.2 16-seed × 2-sensing × 2-pred factorial

| graded | n_pred | Δ mean_body_size | 1×SE |
|---|---|---|---|
| FALSE | 0  | +0.0870 | 0.0070 |
| FALSE | 10 | +0.0963 | 0.0118 |
| TRUE  | 0  | +0.1074 | 0.0060 |
| TRUE  | 10 | +0.1110 | 0.0099 |

**P1 (Cope direction) PASS robustly** — body size drifts upward by
~9–11% over 600 ticks in both sensing modes with ~0.6–0.7% SE (16
seeds).

**P2 (predation direction) NULL within 2×SE in both modes**:

- Binary sensing: Δ(with-pred) − Δ(no-pred) = +0.009 ± 0.014 (flat)
- Graded sensing: Δ(with-pred) − Δ(no-pred) = +0.004 ± 0.012 (flat)

The earlier 5-seed audits (0.4.1 claim of "ratio 0.81,
detectability"; 0.4.3 claim of "ratio 1.08, Shine") were both inside
the 5-seed noise band. The 16-seed sweep resolves cleanly as
neither-direction significant.

### Secondary observation (0.5.2)

Graded predator sensing (0.4.2 default) produces a *larger* Cope
drift (+0.107) than legacy binary sensing (+0.087). This is an
SE-bounded real effect: agents with finer threat information forage
more effectively and thus support larger bodies. A side benefit of
the 0.4.2 sensing polish, not an audit failure.

### Implementation note

The earlier vignette framed P2 as the Shine 2011 escape mechanism
("+57% larger increase under predation"), which was retracted in
0.4.1. The subsequent 0.4.1 reframe as Brooks-Dodson detectability
is also not supported at 16 seeds — neither direction is
statistically supported at default parameters.

## 5. Verdict
- [x] **Cope direction (P1) robustly confirmed.** Upward drift of
  ~9–11% over 600 ticks, 16 seeds, both sensing modes. SE
  ≤ 0.7% of the effect.
- [N/A] **Size-dependent predation (P2) NULL at 16 seeds.** Neither
  Shine-accelerates nor Brooks-Dodson-slows direction is
  statistically supported. clade produces Cope's rule robustly but
  does not reproduce any particular predator-mediated size
  selection at default parameters. The prior Shine/Brooks-Dodson
  framings are retracted and superseded by this null finding.

Cross-reference:
| Aspect | Theory | clade 0.5.2 (16 seeds) |
|---|---|---|
| Body size drifts up | Cope's rule (Stanley 1973) | ✓ Δ = +0.10 (both modes) |
| Predation slows drift | Brooks & Dodson 1965 | ✗ not significant |
| Predation accelerates drift | Shine et al. 2011 | ✗ not significant |

## 6. Actions
- Runner: `body_size.R` (0.5.2 version, 16-seed × 2×2 factorial).
- Figure: `figs/body_size.png` (SE-bar barchart + trajectories).
- Vignette: should be updated to drop both P2 direction claims and
  state the P1-only ✅ verdict (0.5.3 backlog).
