# Scenario: Pace-of-life syndromes (Réale et al. 2010)

## 1. Theory
- **Primary source.** Réale, D. et al. (2010) *Phil. Trans. R. Soc.
  B* 365:4051–4063. Stearns (1992) *The Evolution of Life
  Histories.*
- **Core prediction.** Fast-pace (high metabolic rate) agents
  reproduce early and often, live shorter lives, and show more
  volatile populations; slow-pace agents invest in maintenance,
  achieve longer lifespans.

## 2. Implementation
- clade Julia: metabolic_rate trait; alifeR: same mechanism.
  MATLAB: N/A.

## 3. Protocol
- 3 seeds × 5 metabolic_rate levels {0.5, 1.0, 1.5, 2.0, 3.0} ×
  500 ticks.

## 4. Observed dynamics

| `metabolic_rate` | mean_age | mean_n | mean_births | var(n) |
|---|---|---|---|---|
| 0.5 | 98.3 | 257 | 1.42 | 1230 |
| 1.0 | 98.7 | 261 | 1.46 | 1479 |
| 1.5 | 98.1 | 257 | 1.44 | 1302 |
| 2.0 | 99.1 | 254 | 1.41 | 1150 |
| 3.0 | 98.5 | 257 | 1.45 | 1392 |

**All metrics are flat across the entire rate range.** Spearman
ρ(rate, age) = +0.30 (wrong sign), ρ(rate, births) = 0.00, ρ(rate,
variance) = 0.00.

### Diagnosis

Mean age ≈ 98 ≈ `max_age / 2`. The baseline audit flagged that
clade's `max_age = 200` is always active, even when senescence
evolution is off. So agents die at the age cap before pace-of-life
metabolic differences can matter. Metabolic rate does affect
per-tick energy cost, but the compensating grass availability
(infinite renewal capacity at this density) means agents don't
starve at any rate in this range.

To observe true pace-of-life differences, two kernel adjustments
would be needed:
1. Remove or relax the always-on `max_age` cap (or let it scale
   with metabolic_rate via senescence).
2. Tighten resource scarcity so the metabolic rate directly
   differentiates survival.

## 5. Verdict
- [ ] Matches theory
- [x] **Consistent but underpowered (age-cap masking).**
  Mechanism wired; no differential effect at these parameters
  because the always-on `max_age` cap dominates the age schedule.

Cross-reference:
| Aspect | Theory | MATLAB | alifeR | clade |
|---|---|---|---|---|
| Faster rate → younger age | Yes | N/A | Expected | FLAT (age-cap dominates) |
| Faster rate → more births | Yes | N/A | Expected | FLAT |
| Faster rate → higher pop variance | Yes | N/A | Expected | FLAT |

## 6. Actions
- Vignette: flag age-cap masking; recommend senescence experiments
  for 0.4.0.
- Runner: `pace_of_life.R`.
- Figure: `figs/pace_of_life.png`.
