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

0.4.1 condition sweep: 2 ploidies (haploid asex, diploid sex) × 3
environments (stable, disease, seasonal amp=0.8) × 2 seeds × 500
ticks.

Pre-0.4.1 audit tested only the stable environment and found Δ =
−0.005 (sex slightly *below* asex) — not the Red-Queen direction.
This version adds disease and seasonal environments to test whether
the predicted recombination advantage emerges under fluctuating
selection.

## 4. Observed dynamics

| Environment | haploid_asex div | diploid_sex div | Δ (sex − asex) |
|---|---|---|---|
| Stable | 0.290 | 0.287 | −0.003 |
| Disease | 0.291 | 0.289 | −0.003 |
| Seasonal | 0.294 | 0.292 | −0.002 |

Population size is also ~2 agents lower under sex in every env.
None of the three environments reverses the sign: sex does *not*
produce higher diversity than asex in any of stable, disease, or
seasonal conditions.

### Diagnosis

Two structural reasons the Red-Queen advantage does not emerge
here:

1. **No two-fold cost of sex in the kernel.** Sex is implemented as
   `ploidy = 2` + crossover; there's no explicit male subpopulation
   or sexual-selection cost, so sex is not penalised. But the
   kernel also doesn't give sex its standing advantage — it just
   shuffles existing alleles. In a stable environment
   recombination has nothing new to expose.
2. **Disease model does not produce Red-Queen fluctuation.**
   `disease = TRUE` in clade produces a mild constant mortality
   skew, not a co-evolving parasite host-genotype cycle. Without
   genotype-specific parasite pressure, recombination can't find
   the "novel-combinations-escape-parasites" niche Hamilton 1980
   predicted.
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
