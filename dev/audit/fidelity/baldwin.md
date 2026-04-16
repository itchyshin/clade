# Scenario: Baldwin Effect / BNN sigma canalization

## 1. Theory
- **Primary sources.** Baldwin (1896); Hinton & Nowlan (1987)
  *Complex Systems* 1:495–502; Mayley (1996).
- **Core prediction.** Over many generations in a stable
  environment, learning is genetically assimilated — weights that
  were within-lifetime-learnable become canalized as fixed prior
  means, and the learning machinery (BNN sigma, learning rate)
  contracts.

## 2. Implementation
- clade Julia: BNN brain with sigma = heterozygosity-derived prior
  width (diploid) or `bnn_sigma_init` (haploid, capped at 0.5 by
  default). `rl_mode = "actor_critic"` enables within-lifetime
  posterior contraction. alifeR: partial BNN. MATLAB: base ANN only.

## 3. Protocol
- 4 seeds × 2 conditions (stable vs seasonal amp=0.8) × 800 ticks.

## 4. Observed dynamics

| Condition | init sigma → final sigma | Δ |
|---|---|---|
| Stable | 0.192 → **0.500** (cap) | +0.308 |
| Seasonal (amp=0.8) | 0.185 → **0.500** (cap) | +0.315 |

**Sigma rises, not falls.** Both conditions saturate at the init
cap of 0.5.

### Diagnosis — the kernel mechanism works against the prediction

clade derives sigma from heterozygosity: maternal-paternal allele
difference sets the prior width. Neutral mutation continuously
*adds* heterozygosity; selection at these parameters is not strong
enough to reduce it. So mean sigma rises over generations,
opposite to the Baldwin canalization prediction.

For clade's Baldwin prediction to be testable, one of:
1. Stronger directional selection (tightly scarce resources, or
   a clear fitness optimum) that reduces genetic diversity.
2. A kernel change: decouple sigma from heterozygosity and let it
   evolve as an independent heritable trait subject to
   selection pressure (e.g. cost of uncertainty).
3. Haploid default (`ploidy = 1`) where sigma is set directly by
   `bnn_sigma_init` and can be selected.

## 5. Verdict
- [ ] Matches theory
- [ ] Consistent but underpowered
- [x] **Contradicts theory — implementation mismatch.** The
  sigma-from-heterozygosity mechanism implicitly couples sigma to
  genetic diversity, not to the Baldwin-Hinton-Nowlan learning-
  assimilation gradient. The prediction is *anti-reproduced*
  under default parameters. Flag for 0.4.0 kernel work if
  Baldwin is a scenario we want to claim.

Cross-reference:
| Aspect | Theory (Hinton & Nowlan) | MATLAB | alifeR | clade |
|---|---|---|---|---|
| Stable → sigma declines | Yes | N/A | Expected | **✗ sigma rises to cap** |
| Seasonal → sigma stays high | Yes | N/A | Expected | Same as stable (both rise) |

## 6. Actions
- Vignette: retract the "sigma declines under canalization" claim
  at default parameters. Explain the heterozygosity-coupling
  mechanism and why it produces the opposite result.
- 0.4.0 backlog: decouple sigma from heterozygosity (or allow it
  as a directly heritable trait) to permit Baldwin tests.
- Runner: `baldwin.R`.
- Figure: `figs/baldwin.png`.
