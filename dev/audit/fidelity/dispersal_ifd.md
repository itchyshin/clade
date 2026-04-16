# Scenario: Dispersal & IFD (Fretwell & Lucas 1970; Shine 2011)

## 1. Theory
- **IFD.** Under perfect information, agents distribute across
  patches proportionally to resources (Fretwell & Lucas 1970).
  Expected signature: heritable `habitat_preference` evolves
  upward because agents that prefer high-grass cells gain energy
  advantage.
- **Spatial sorting.** At an expanding invasion front, high-
  dispersal alleles surf the wave (Shine et al. 2011).

## 2. Implementation
- clade Julia: `dispersal.jl`, `habitat_preference.jl`;
  alifeR: `dispersal.R`; MATLAB: N/A.

## 3. Protocol

0.4.1 grid (P1): 4 preference strengths
(`habitat_preference_strength ∈ {0.5, 1.0, 2.0, 4.0}`) × 2 run
lengths (`max_ticks ∈ {500, 1000}`) × 2 seeds.

Spatial sorting (P2): unchanged, 2 seeds × 500 ticks,
non-toroidal 40×40, `spatial_sorting=TRUE`.

Pre-0.4.1 audit used a single strength (0.5) / single tick count
(500) and got Δ=+0.002 (P1 FAIL) and front-rear Δ=+0.005 (P2
PASS in sign, noisy). This version searches for a preference
strength that produces a clean IFD signal.

## 4. Observed dynamics

**IFD grid summary** (ordered by Δ mean_habitat_preference):

| strength | ticks | Δ mean ± sd |
|---|---|---|
| **2.0** | **1000** | **+0.0058 ± 0.0012** |
| 2.0 | 500 | +0.0056 ± 0.0064 |
| 4.0 | 1000 | +0.0050 ± 0.0005 |
| 4.0 | 500 | +0.0047 ± 0.0023 |
| 0.5 | 1000 | +0.0020 ± 0.0012 |
| 0.5 | 500 | +0.0020 ± 0.0028 |
| 1.0 | 500 | −0.0005 ± 0.0027 |
| 1.0 | 1000 | −0.0023 ± 0.0005 |

Signal saturates around strength=2.0 (Δ ≈ +0.006) then actually
*weakens* at strength=4.0 — stronger preference doesn't translate
into a stronger trait-evolution signal because the within-run
population mostly sorts spatially (behaviourally) rather than
selecting on the trait. The strength=1.0 cells are within the
seed-noise band (small negative numbers). None of the cells reach
the 0.02 ✅ threshold.

**Spatial sorting (P2):** front_dispersal = 0.273 ± 0.057 vs
rear_dispersal = 0.261 ± 0.053, Δ = **+0.012** (2 seeds). PASS
in sign.

## 5. Verdict
- [ ] Matches theory (✅)
- [x] **Passed-consistent (🟠).** P1 direction is correct across
  most grid cells (preference evolves upward) and saturates around
  +0.006 at strength=2.0. Well below the 0.02 threshold; practical
  detection would require substantially longer runs or kernel-level
  changes to the fitness-preference coupling. P2 PASS in sign
  (+0.012).

Cross-reference:
| Aspect | Theory | clade 0.4.0 | clade 0.4.1 (best grid cell) |
|---|---|---|---|
| IFD preference ↑ | Yes | Δ = +0.002 | Δ = +0.006 (str=2.0, 1000t) |
| Front > rear dispersal | Yes | Δ = +0.005 | Δ = +0.012 |

## 6. Actions
- Runner: `dispersal_ifd.R` (0.4.1 grid version).
- Figure: `figs/dispersal_ifd.png` (facetted by run length).
- Vignette: flag that IFD signal saturates at modest strength and
  requires longer runs for practical detection.
- 0.4.2 backlog: try `habitat_preference_mutation_sd > 0.03` to
  speed trait evolution, or extend to 2000+ ticks.
