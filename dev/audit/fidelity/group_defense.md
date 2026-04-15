# Scenario: Group defense / selfish herd (Hamilton 1971)

## 1. Theory
- **Primary source.** Hamilton, W.D. (1971) Geometry for the
  selfish herd. *J. Theor. Biol.* 31:295–311.
- **Core prediction.** Aggregation reduces per-capita predation
  risk via dilution; populations with active group defense should
  sustain larger mean size than baseline under identical predator
  pressure.

## 2. Implementation
- clade Julia: `group_defense.jl`; alifeR: `group_defense.R`;
  MATLAB: N/A.

## 3. Protocol
- 4 seeds × 2 conditions (baseline vs gd), 15 predators, 500 ticks,
  `group_defense_strength = 0.5`.

## 4. Observed dynamics

| Condition | mean n_agents (post-burn) |
|---|---|
| Baseline | 270.9 ± 9.3 |
| Group defense | **278.7 ± 3.2** |

**Direction correct (+3%).** ratio 1.03×. The gd condition has
tighter seed SD (3.2 vs 9.3), suggesting dilution reduces
population volatility alongside the small mean boost.

## 5. Verdict
- [ ] Matches theory
- [x] **Consistent but underpowered.** Direction correct, small
  magnitude. Larger effect would likely appear at higher predator
  pressure where dilution becomes more consequential.

Cross-reference:
| Aspect | Theory (Hamilton 1971) | MATLAB | alifeR | clade |
|---|---|---|---|---|
| gd boosts population | Yes | N/A | Expected | ✓ +3% |
| gd reduces variance | Implicit | N/A | Expected | ✓ SD 3.2 vs 9.3 |

## 6. Actions
- Vignette: update with 4-seed +3% finding.
- Runner: `group_defense.R`.
