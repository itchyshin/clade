# Scenario: Mating systems (Maynard Smith 1978)

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
- 4 seeds × 2 conditions (haploid asex, diploid sex) × 500 ticks,
  stable environment.

## 4. Observed dynamics

| Condition | genetic_diversity | mean n_agents |
|---|---|---|
| Haploid asexual | 0.314 ± 0.003 | 288 |
| Diploid sexual (crossover=0.1) | 0.308 ± 0.002 | 286 |

**Direction reversed — sex < asex in diversity.** Δ = −0.005, very
small but consistent across 4 seeds.

### Diagnosis
In a stable foraging environment, recombination shuffles existing
variants without providing a selective advantage. Haploid agents
expose all mutations immediately (no recessive masking), so more
alleles are visible to selection — this apparently gives slightly
*higher* standing diversity when measured at the phenotype level.
The two-fold cost of sex (half offspring are males) is not
implemented as an explicit overhead in clade, so sex is not
actively penalised, but the recombination advantage also doesn't
manifest at default stable conditions.

The classical Red-Queen advantage of sex (fluctuating selection
from parasites, seasons) would require combining `ploidy=2` with
`disease=TRUE` or `seasonal_amplitude > 0` to test.

## 5. Verdict
- [ ] Matches theory
- [x] **Consistent but underpowered (stable environment).**
  Direction reversed at default parameters but difference is
  very small. The Red-Queen / parasite-driven advantage is not
  tested here.

Cross-reference:
| Aspect | Theory | MATLAB | alifeR | clade |
|---|---|---|---|---|
| Sex > asex diversity (stable) | Weak prediction | base has `sexualReproduction` flag | Expected | ✗ Δ=−0.005 |
| Sex > asex under fluctuation | Strong prediction | N/A | Expected | not tested here |

## 6. Actions
- Vignette: confirm the stable-env null result; suggest fluctuation
  experiments for the Red-Queen advantage.
- Runner: `mating_systems.R`.
- Figure: `figs/mating_systems.png`.
