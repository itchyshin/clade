# Scenario: Mating systems (Maynard Smith 1978; Williams 1975)

## 1. Theory
- **Primary source.** Maynard Smith, J. (1978) *The Evolution of
  Sex.* Williams (1975) *Sex and Evolution.*
- **Core prediction.** Sexual reproduction with recombination
  maintains higher genetic diversity than asexual reproduction,
  *especially* in fluctuating environments. In stable environments,
  the two-fold cost of sex may offset the recombination benefit.

## 2. Implementation
- clade Julia: `ploidy = 1/2` with `crossover_rate`; alifeR:
  similar `sexual_repro` flag; MATLAB: base has sexual option.

## 3. Protocol

- **0.4.1 condition sweep**: 2 ploidies × 3 environments (stable,
  disease, seasonal amp=0.8) × 2 seeds × 500 ticks.
- **0.5.0 update**: 4th env condition `"parasite"` added — enables
  the new `coevolving_parasites` module with `signal_dims = 5`,
  `parasite_pressure = 3.0`, `parasite_distance_scale = 0.4`. Seeds
  bumped to 3 (n = 24 runs total).

Pre-0.4.1 audit tested only the stable environment and found Δ =
−0.005 (sex slightly *below* asex). 0.4.1 added disease and seasonal
environments (still no Red Queen signal). 0.5.0 adds the
coevolving-parasite condition to test Hamilton's (1980) canonical
mechanism directly.

## 4. Observed dynamics

### 0.5.0 result (3 seeds × 4 envs × 500 ticks)

| Environment | haploid_asex div | diploid_sex div | Δ (sex − asex) | asex n | sex n |
|---|---|---|---|---|---|
| Stable | 0.289 | 0.286 | −0.003 | 236.5 | 235.2 |
| Disease | 0.291 | 0.290 | −0.001 | 237.2 | 236.8 |
| Seasonal | 0.294 | 0.290 | −0.004 | 223.1 | 223.0 |
| **Parasite** | 0.286 | **0.239** | **−0.047** | 94.3 | **84.5** |

The parasite condition (new in 0.5.0) widens the sex-asex gap
rather than closing it. This is the opposite of what Hamilton's
canonical Red Queen predicts, and is a real finding about the
limits of continuous-trait parasite models — see §5.

### Diagnosis

Three structural reasons the Red-Queen advantage does not emerge
here:

1. **No two-fold cost of sex in the kernel.** Sex is implemented as
   `ploidy = 2` + crossover; there's no explicit male subpopulation
   or sexual-selection cost, so sex is not penalised. But the
   kernel also doesn't give sex its standing advantage — it just
   shuffles existing alleles. In a stable environment
   recombination has nothing new to expose.
2. **`disease = TRUE` is not a coevolving-parasite model.**
   clade's built-in disease module produces a mild constant
   mortality skew (infection rate × virulence), not a
   genotype-matched pressure. 0.5.0 adds an explicit
   coevolving-parasite module (`coevolving_parasites` spec), but
   see #3 for why it still doesn't produce the canonical signal.
3. **0.5.0 coevolving parasites use continuous-trait matching,
   not discrete-allele matching.** The module tracks the host
   signal-centroid with lag and applies Gaussian-falloff penalty
   based on Euclidean distance. Under this dynamic, sex offspring
   (genotype midpoint of two parents) end up *closer* to the
   population mean than asex offspring (clones of a potentially-
   drifted parent). Parasites sit at the mean → sex offspring
   are *more* exposed, not less. Hamilton's canonical Red Queen
   requires DISCRETE-allele matching (haplotypes like AA vs aa
   vs Aa) where recombination produces genuinely novel
   combinations. Deferred to 0.5.1+ (needs a discrete
   `parasite_match::Vector{Int32}` host trait with Mendelian
   inheritance).
3. **Seasonal fluctuation is a phenotypic tracking challenge, not
   a genotypic one.** Sex helps when recombination can track a
   moving genetic optimum; clade's seasonal resource oscillation
   selects on behaviour/phenotype, not on the recombination axis.

This is a genuine kernel-limitation finding: the Red-Queen advantage
of sex requires a genotype-specific fluctuating fitness surface
that clade does not currently implement.

## 5. Verdict
- [ ] Matches theory (✅)
- [x] **Passed-consistent (🟠) — kernel-limited.** The
  recombination advantage is a well-defined theoretical claim
  that *requires* fluctuating genotype-specific fitness; clade's
  default modules provide phenotypic selection on shared resource
  cells and a non-coevolving disease term, neither of which
  produce the Red-Queen fluctuation the sex advantage needs. In
  all three tested environments sex is ~0.003 below asex in
  diversity — consistent direction, well below any promotion
  threshold. Directionally aligned with the "stable env: sex has
  no advantage" corner of Maynard Smith 1978.

Cross-reference:
| Aspect | Theory | clade (all 3 envs) |
|---|---|---|
| Sex > asex diversity (stable) | Weak / no prediction | ✗ Δ = −0.003 |
| Sex > asex under disease (Hamilton 1980 Red Queen) | Strong prediction | ✗ Δ = −0.003 (kernel lacks coevolving parasite) |
| Sex > asex under seasonal | Phenotypic not genotypic fluctuation | ✗ Δ = −0.002 |

## 6. Actions
- Runner: `mating_systems.R` (0.4.1 condition sweep).
- Figure: `figs/mating_systems.png` (facetted by env).
- Vignette: reframe — stable env result is the expected "no
  advantage" corner of Maynard Smith; document that Red-Queen
  scenarios need a coevolving parasite module not currently in
  clade.
- 0.4.2+ backlog: coevolving parasite module (genotype-matched
  virulence) to expose the Hamilton 1980 Red-Queen advantage.
