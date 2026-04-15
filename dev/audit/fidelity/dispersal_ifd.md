# Scenario: Dispersal & IFD (Fretwell & Lucas 1970; Shine 2011)

## 1. Theory
- **IFD.** Under perfect information, agents distribute across
  patches proportionally to resources (Fretwell & Lucas 1970).
- **Spatial sorting.** At an expanding invasion front, high-dispersal
  alleles surf the wave (Shine et al. 2011).

## 2. Implementation
- clade Julia: `dispersal.jl`, `habitat_preference.jl`;
  alifeR: `dispersal.R`; MATLAB: N/A.

## 3. Protocol
- IFD: 4 seeds × 500 ticks, `habitat_preference_evolution=TRUE`.
- Spatial sorting: 4 seeds × 500 ticks, non-toroidal 40×40,
  `spatial_sorting=TRUE`.

## 4. Observed dynamics

**IFD (P1):** mean_habitat_preference init = 0.000 → final = 0.002
(**Δ = +0.002**). FAIL. Preference evolution is essentially invisible
at 500 ticks.

**Spatial sorting (P2):** final front_dispersal 0.293 ± 0.070 vs
rear_dispersal 0.288 ± 0.037 (**Δ = +0.005**). PASS in sign but
within seed-level noise.

Both effects are too small to be practically detectable with the
current runner. Possible causes: (a) mutation rate small relative
to signal; (b) 500 ticks insufficient for these subtle selective
effects; (c) default habitat_preference_strength = 0.5 too weak
to create a strong fitness differential.

## 5. Verdict
- [ ] Matches theory
- [x] **Consistent but underpowered.** Signs are directionally
  correct (preference ↑, front > rear) but both magnitudes are
  essentially at noise level. Longer runs (2000+ ticks) and
  higher mutation or stronger preference weighting would likely
  be needed to produce a clean signal.

Cross-reference:
| Aspect | Theory | MATLAB | alifeR | clade |
|---|---|---|---|---|
| IFD habitat preference rises | Yes | N/A | Expected | Δ = +0.002 (noise) |
| Front > rear dispersal | Yes | N/A | Expected | Δ = +0.005 (noise) |

## 6. Actions
- Vignette: flag that baseline parameters produce signals within
  noise; suggest longer runs for strong signatures.
- Runner: `dispersal_ifd.R`.
- Figure: `figs/dispersal_ifd.png`.
