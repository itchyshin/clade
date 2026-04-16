# Scenario: Niche construction (Odling-Smee et al. 2003)

## 1. Theory
- **Primary source.** Odling-Smee, F.J., Laland, K.N., & Feldman,
  M.W. (2003) *Niche Construction: The Neglected Process in
  Evolution.* Princeton.
- **Core prediction.** Organisms that modify their selective
  environment can gain heritable fitness benefits if the
  modifications persist beyond their lifetime.

## 2. Implementation
- clade Julia: `niche.jl`; alifeR: `niche.R`; MATLAB: N/A.

## 3. Protocol
- 3 seeds × 3 conditions (baseline / NC no-bonus / NC with bonus=0.3)
  × 400 ticks with 10 predators.

## 4. Observed dynamics

| Condition | mean n_agents | shelters built |
|---|---|---|
| Baseline | 233 | 0 |
| NC (bonus=0) | 221 | 15,668 |
| NC (bonus=0.3) | **243** | 17,511 |

- **P1 PASS.** 15,668 shelters built per run — clearly active
  ecosystem engineering.
- **P2 PASS.** Occupancy bonus raises population by +22 (243 vs
  221) — heritable-benefit channel works.

Without bonus, NC slightly *reduces* population (221 vs 233) because
shelter-building suppresses grass regrowth on the cell (a cost)
without a compensating protection benefit (predator-damage
reduction not wired). With bonus = 0.3, the energetic subsidy for
sheltered cells compensates and exceeds the cost.

## 5. Verdict
- [x] **Matches theory.** The heritable-niche-construction benefit
  is present and measurable (+22 agents at bonus = 0.3).

Cross-reference:
| Aspect | Theory (Odling-Smee) | MATLAB | alifeR | clade |
|---|---|---|---|---|
| Shelters built | Yes | N/A | Yes | ✓ 15,668 |
| Net benefit with bonus | Predicted | N/A | Expected | ✓ +22 agents |
| Cost without benefit | Odling-Smee notes cost precedes benefit | N/A | Same | ✓ −12 without bonus |

## 6. Actions
- Vignette: update with three-condition comparison.
- Runner: `niche.R`.
