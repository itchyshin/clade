# Scenario: Cooperation & public goods (Nowak & May 1992)

## 1. Theory

- **Primary sources.**
  - Nowak, M.A. & May, R.M. (1992) Evolutionary games and spatial
    chaos. *Nature* 359:826–829.
  - Hauert, C. et al. (2002) Volunteering and reward in the
    snowdrift game. *Science* 296:1129–1132.
  - Hardin, G. (1968) The tragedy of the commons. *Science* 162:
    1243–1248.
- **Core prediction (one sentence).** Continuous-strategy public
  goods games on a spatial grid produce: (a) group-level
  population benefit when the payoff multiplier exceeds the
  cost–benefit break-even, and (b) a tragedy-of-the-commons
  signature in which mean cooperation level drifts slightly
  downward (free-rider invasion) without collapsing to zero
  (spatial clustering protects cooperators).
- **Quantitative expectations.**
  1. Cooperation ON with `M = 2.5` raises population substantially
     above baseline.
  2. Mean cooperation level shows small downward drift from init
     value but does not collapse.
  3. Population size scales monotonically with multiplier `M`;
     below `M = 1` (break-even) cooperation is maladaptive; above
     `M ≈ 2` (spatial-game critical value) cooperation strongly
     favoured.
- **Why the evolutionary ABM may differ from the math.** Nowak &
  May used discrete strategies (C/D) on a Moore lattice; clade uses
  a continuous `cooperation_level ∈ [0,1]` trait. Quantitative
  threshold values will differ, but the qualitative pattern should
  be preserved.

## 2. Implementation under audit

- **Vignette:** [vignettes/s-cooperation.Rmd](../../../vignettes/s-cooperation.Rmd).
- **clade Julia:** [inst/julia/src/modules/cooperation.jl](../../../inst/julia/src/modules/cooperation.jl)
  (156 lines). Public goods pool in Moore neighbourhood; contribution
  = `cooperation_level × cooperation_cost`; benefit =
  `multiplier × total_contribution / n_neighbours`.
- **alifeR R prototype:** [alifeR/R/cooperation.R](../../../../alifeR/R/cooperation.R)
  (71 lines). Same mechanics, less elaborate.
- **MATLAB base:** N/A — cooperation first appears in alifeR.
- **Formula fidelity.** clade's implementation is more elaborate
  (handles mating proximity interactions) but the core
  contribution-and-payoff loop matches alifeR.

## 3. Run protocol

- Step 1: 5 seeds × 2 conditions (off vs on at M=2.5) × 400 ticks.
- Step 2: 3 seeds × 7 multiplier levels {0.5, 1.0, 1.5, 2.0, 2.5,
  3.0, 4.0}.
- Wall time: ~4 min.

## 4. Observed dynamics

### Step 1 — off vs on at M = 2.5

| Condition | mean n_agents | mean cooperation level |
|---|---|---|
| Baseline | 202.6 | — |
| Cooperation ON | **587.6 (2.90× baseline)** | 0.500 → 0.486 |

**P1 PASS.** 2.9× population boost — cooperation dramatically
raises carrying capacity.
**P2 PASS.** Cooperation drifts down 0.014 units over 400 ticks
(tragedy-of-commons signature, not collapse).

### Step 2 — multiplier sweep

| `M` | mean n_agents | final cooperation |
|---|---|---|
| 0.5 | 137 | 0.458 |
| 1.0 | 200 (~= baseline) | 0.467 |
| 1.5 | 296 | 0.486 |
| 2.0 | **528** | 0.452 |
| 2.5 | 588 | 0.497 |
| 3.0 | 593 (saturating) | 0.502 |
| 4.0 | 598 (cap-limited) | 0.509 |

**P3 PASS, Spearman ρ = 1.00.** Perfect monotone relationship.
Sharp transition between M=1.5 (296 agents) and M=2.0 (528
agents) — the spatial Nowak-May critical regime. Above M=2.5,
saturates at ~600 agents (near `max_agents = 600` cap).

Figure: [figs/cooperation.png](figs/cooperation.png).

## 5. Verdict

- [x] **Matches theory.** Nowak-May pattern reproduced with
  Spearman ρ = 1.00 on the multiplier sweep, clear tragedy-of-
  commons drift, and 2.9× group-level population benefit at
  default M = 2.5.

### Cross-reference table

| Aspect | Theory (Nowak-May) | MATLAB | alifeR | clade |
|---|---|---|---|---|
| Public goods mechanism | Prisoner's Dilemma on lattice | N/A | Continuous PGG | Continuous PGG |
| Group benefit | Predicted | N/A | Yes | ✓ 2.9× at M=2.5 |
| Tragedy of commons | Predicted | N/A | Predicted | ✓ −0.014 drift |
| Multiplier threshold | M ≈ 1/(C-mean) | N/A | Expected | ✓ Sharp M∈[1.5, 2.0] |
| Spearman M vs pop | Positive monotone | N/A | Expected | **ρ = 1.00** |

## 6. Actions taken

- Vignette: update "What we found" with 5-seed 2.9× result and
  multiplier-sweep ρ = 1.00.
- Kernel changes: none.
- Runner: `dev/audit/fidelity/cooperation.R`.
- Figure: `dev/audit/fidelity/figs/cooperation.png`.
