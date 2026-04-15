# Scenario: Body size evolution (Cope's rule, Shine et al. 2011)

## 1. Theory
- **Primary sources.** Cope's rule (paleontological observation;
  Stanley 1973 review). Shine, R. et al. (2011) *Proc. R. Soc. B*
  278:1449–1457 (predator-mediated size selection).
- **Core prediction.** Under foraging selection with a body-size ×
  gain coupling, mean body size drifts upward (Cope's rule).
  Predation is classically said to favour larger (harder-to-catch)
  prey, accelerating the drift.

## 2. Implementation
- **clade Julia:** `inst/julia/src/modules/body_size.jl`.
- **alifeR:** `body_size.R`.
- **MATLAB:** N/A.

## 3. Protocol
- 5 seeds × 2 conditions (no predators, 10 predators) × 600 ticks.

## 4. Observed dynamics

| Condition | final body size | Δ from init |
|---|---|---|
| No predators | 1.126 ± 0.029 | **+0.128 ± 0.033** |
| 10 predators | 1.103 ± 0.023 | **+0.105 ± 0.017** |

- **P1 PASS** — body size drifts upward by ~13% over 600 ticks,
  consistent with Cope's rule direction (upward) at small
  magnitude (evolutionary times are short).
- **P2 FAIL as written.** Predation *slows* the drift slightly
  (ratio 0.81), opposite to the vignette's old claim that
  predation accelerates size increase.

### Why P2 fails

Two possible explanations, both biologically meaningful:

1. **Size as detectability.** Larger prey are more detectable in
   clade's sensing model, so predators preferentially cull the
   top of the size distribution — exactly the opposite of the
   "large bodies escape" story. This is size-selective predation
   in the *small-is-better* direction (consistent with some
   ornithological and ichthyological studies of fisheries; Shine's
   original cane-toad result is a special case, not general).
2. **Population thinning.** Predation reduces density, which
   lowers local grass competition. Under Cope-style
   foraging-efficiency selection, larger bodies are most favoured
   when competition is strong. Thinning weakens the Cope gradient.

Either explanation is consistent with the observed data. The
vignette's prior "+57% larger increase under predation" claim is
**not reproduced** and is retracted.

## 5. Verdict
- [x] **Matches theory (Cope direction).** Upward size drift
  confirmed at ~13% over 600 ticks.
- Predation effect is *not* the direction the vignette claimed;
  flagged for prose correction.

Cross-reference:
| Aspect | Theory | MATLAB | alifeR | clade |
|---|---|---|---|---|
| Body size drifts up | Cope's rule | N/A | Expected | ✓ Δ = +0.128 |
| Predation accelerates | Shine 2011 | N/A | Expected | ✗ Δ = +0.105 (slower) |

## 6. Actions
- Vignette: retract the "predation accelerates 57% larger increase"
  claim.
- Runner: `body_size.R`.
- Figure: `figs/body_size.png`.
