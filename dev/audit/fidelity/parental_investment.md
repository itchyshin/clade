# Scenario: Parental investment (Trivers 1972)

## 1. Theory
- **Primary source.** Trivers, R.L. (1972) Parental investment and
  sexual selection. In Campbell (ed.) *Sexual Selection and the
  Descent of Man.*
- **Core prediction.** The sex that invests more per offspring
  is more selective in mate choice; shifts in the allocation of
  investment between parents should shift births, offspring
  quality, and mate-choice dynamics.

## 2. Implementation
- clade Julia module; alifeR `parental_care.R` with investment
  extensions; MATLAB: N/A.

## 3. Protocol
- 3 seeds × 4 female_investment levels {0.3, 0.5, 0.7, 0.9} ×
  500 ticks.

## 4. Observed dynamics

| `female_investment` | mean n_births | mean n_juveniles | mean n_agents | mean_energy |
|---|---|---|---|---|
| 0.3 | 1.47 | 1.5 | 260 | 125.5 |
| 0.5 | 1.48 | 1.5 | 262 | 126.2 |
| 0.7 | 1.51 | 1.5 | 264 | 125.5 |
| 0.9 | 1.47 | 1.5 | 262 | 125.4 |

**Dynamics are flat across the entire investment range.** Spearman
ρ(fi, births) = −0.20 (weak, not significant). The parameter
barely moves any downstream metric.

### Diagnosis

Three possibilities:
1. Both parents still need enough energy to survive regardless of
   ratio — the total cost is similar.
2. The parental-care module may bottleneck all reproduction
   through carrying/graduation regardless of who pays.
3. The Trivers asymmetry (sex-differential mate choice) requires
   a heritable preference trait that isn't part of this module.

Without a kernel extension that couples `female_investment` to a
differential outcome (e.g., per-offspring energy at graduation
scaling explicitly with maternal contribution), the Trivers
prediction cannot be tested with the current module.

## 5. Verdict
- [ ] Matches theory
- [x] **Consistent but underpowered.** Mechanism is wired but
  parameter has negligible effect on population-level metrics at
  these conditions. The Trivers quality-quantity trade-off
  requires a stronger coupling between `female_investment` and
  offspring energy/survival than the current module provides.

Cross-reference:
| Aspect | Theory (Trivers) | MATLAB | alifeR | clade |
|---|---|---|---|---|
| fi affects births | Yes | N/A | Expected | Flat (ρ = −0.20) |
| fi affects quality | Yes | N/A | Expected | Flat |

## 6. Actions
- Vignette: flag that the module doesn't produce a measurable
  Trivers effect at current couplings; add to 0.4.0 backlog.
- Runner: `parental_investment.R`.
- Figure: `figs/parental_investment.png`.
