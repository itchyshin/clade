# Scenario: Scavenging (DeVault et al. 2003)

## 1. Theory
- **Primary source.** DeVault, T.L. et al. (2003) Scavenging by
  vertebrates. *Oikos* 102:225–234.
- **Core prediction.** Scavenging provides an energy buffer under
  scarcity — populations with access to conspecific carrion
  should sustain higher carrying capacity than the baseline.

## 2. Implementation
- clade Julia: `scavenging.jl`; alifeR: `scavenging.R`; MATLAB: N/A.

## 3. Protocol
- 4 seeds × 2 conditions (baseline vs scavenging), grass_rate=0.07,
  500 ticks.

## 4. Observed dynamics

| Condition | n_agents | mean_energy |
|---|---|---|
| No scavenging | 135 ± 4 | 127.0 ± 2.9 |
| Scavenging | **140 ± 2** | 125.6 ± 2.4 |

**P1 passes on population, not on per-capita energy.** Scavenging
raises carrying capacity by +5 agents (+3.7%), but per-capita
energy is slightly lower (carrion buffer spread over more agents).
This is actually the right biological interpretation: at
equilibrium, ecological release via scavenging is expressed as
higher density, not higher individual condition.

## 5. Verdict
- [x] **Matches theory (population-level buffer).** Scavenging
  produces the predicted density advantage under scarcity, as
  density-dependent regulation absorbs the excess energy into
  carrying capacity rather than per-capita condition.

Cross-reference:
| Aspect | Theory (DeVault) | MATLAB | alifeR | clade |
|---|---|---|---|---|
| Energy buffer | Yes | N/A | Expected | ✓ expressed as density |
| Higher carrying capacity | Yes | N/A | Expected | ✓ +5 agents (+3.7%) |

## 6. Actions
- Vignette: update to highlight that the buffer appears in
  population size, not per-capita energy.
- Runner: `scavenging.R`.
