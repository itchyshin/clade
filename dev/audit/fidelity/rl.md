# Scenario: Within-lifetime RL (Williams 1992 REINFORCE)

## 1. Theory
- **Primary source.** Williams, R.J. (1992) Simple statistical
  gradient-following algorithms for connectionist reinforcement
  learning. *Machine Learning* 8:229–256.
- **Core prediction.** Agents with REINFORCE-style within-lifetime
  learning achieve higher reward (mean energy / survival) than
  non-learning agents through within-lifetime policy adaptation.

## 2. Implementation
- clade Julia: BNN posterior update (brains/bnn.jl:189-214) or
  output-layer update (modules/rl.jl); alifeR: `rl.R`; MATLAB:
  `RLupdate.m` (Bulitko 2023 — ancestral form).

## 3. Protocol
- 4 seeds × 2 conditions (rl_mode=none vs actor_critic) × 500
  ticks with BNN brain.

## 4. Observed dynamics

| Condition | mean n | mean_energy |
|---|---|---|
| No RL | 239 ± 4 | 127.1 ± 1.5 |
| RL on (actor_critic) | 239 ± 2 | 126.5 ± 0.8 |

Essentially identical — Δn = +0.7, Δe = −0.6. Both are well within
seed noise.

### Diagnosis

Known BNN interaction: the BNN brain samples all weights from its
prior distribution each tick. REINFORCE gradient updates modify
the posterior mean, but the next tick's sample is drawn around
that mean with wide sigma (~0.5 after heterozygosity accumulation,
per Baldwin audit). The copied delta is diluted before behaviour
can improve. Same architecture caveat as s-social-learning: RL
works with ANN brains (Bulitko's MATLAB ancestor used ReLU-ANN),
not BNN.

## 5. Verdict
- [ ] Matches theory
- [x] **Consistent but underpowered (BNN interaction).** RL is
  wired and produces posterior updates, but with default BNN
  brain + broad sigma, the within-lifetime benefit is too small
  to detect. ANN brain or narrower initial sigma would expose
  the benefit.

Cross-reference:
| Aspect | Theory (Williams 1992) | MATLAB (RLupdate.m) | alifeR | clade (BNN) |
|---|---|---|---|---|
| RL raises reward | Yes | Yes (ReLU ANN) | Yes (ANN) | ✗ null with BNN |

## 6. Actions
- Vignette: update with 4-seed null result + BNN caveat.
- 0.4.0 backlog: narrower initial sigma or heritable sigma to
  allow BNN+RL interaction to express.
- Runner: `rl.R`.
