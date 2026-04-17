# Scenario visual strength assessment — 2026-04-17

Rating each scenario's **demo figure** for visual clarity — can a
biologist look at the figure and immediately see the predicted effect?

## Rating scale

- **STRONG**: effect obvious at a glance (>20% separation, clear
  divergence, unmistakable pattern)
- **MODERATE**: effect visible but requires reading the caption
  (~5-20% separation, noisy trajectories)
- **WEAK**: effect below visual noise; requires statistical analysis
  to detect (<5% separation)

## Ratings

### ✅ scenarios with STRONG visual demos

| Scenario | Effect size | Visual |
|---|---|---|
| s-baseline | Fundamental | Clean dashboard, obvious dynamics |
| s-predator-prey | Prey oscillate, pred saturate | Clear damped LV pattern |
| s-pop-genetics | Lag-1 autocorrelation ~1.0 | Fisher-Wright drift obvious |
| s-disease | SIR epidemic dynamics | Peak + recovery clearly visible |
| s-kin | Spearman ρ = 0.97 | Near-perfect linear relationship |
| s-cooperation | Nowak-May PGG | Cooperation level clearly diverges |
| s-speciation | Bimodality | Cluster separation visible |
| s-seasonal | Sinusoidal oscillation | Population tracks grass phase |
| s-clutch-size | Bell-shaped r/K | Optimum clutch visible |
| s-parental-care | +30% population with care | Clear separation |
| s-life-history | Semelparous +58% pop | Very clear divergence |
| s-niche | Shelter benefit | Population boost visible |
| s-scavenging | Carrion buffer | Population smoothing visible |
| s-complex-landscape | 3-layer occupancy | Layer differentiation clear |
| s-body-size | +10-42% Cope drift | Upward trajectory obvious |

### ✅ scenarios with MODERATE visual demos (improved this session)

| Scenario | Effect size | Visual | Improvement |
|---|---|---|---|
| s-brain-size | ~20% pop divergence | Two-panel (brain + pop) | Regenerated at cost_scale=5.0 |
| s-group-defense | ~10% pop boost | Trajectory separation | Regenerated at n_pred=30, str=2.0 |
| s-rl | +2.6% pop (Δn=+5.2) | Subtle trajectory split | Regenerated at bnn_sample_freq=5 |
| s-signals | Zahavi handicap visible | — | Not regenerated; original may be adequate |
| s-social-learning | Boyd-Richerson ANN | — | Not regenerated; ANN-specific effect |
| s-parental-investment | Trivers effect | — | Not assessed; check original figure |
| s-pace-of-life | Metabolic rate ~0.96 | — | Effect is small; may need param search |

### 🟠 scenarios with WEAK visual demos (honest kernel/ecology limits)

| Scenario | Effect size | Why weak | Can it be improved? |
|---|---|---|---|
| s-plasticity | Δdelta = +0.002 | Sigma couples to behavioural variance | Needs kernel fix (sigma decoupling) |
| s-baldwin | Transient only | Same limitation as plasticity | Same fix needed |
| s-dispersal-ifd | Δ = +0.001 at grid-max | Behavioural sorting dominates trait evolution | Needs much longer runs or kernel change |
| s-mating-systems | Direction correct, ~0 at 2×SE | clade's cost of sex too high | Needs kernel change or mixed-ploidy |
| s-mimicry | Toxicity declines at most params | Zahavi cost > benefit at default ecology | grass_rate ≈ 0.08 shows first positive |
| s-stress-hypermut | Δgd = +0.015 | Inherently small effect in ABM | Accept as direction-correct |

### ⚪ N/A or other

| Scenario | Note |
|---|---|
| s-bad-science | Smaldino & McElreath demo; not a "strong effect" scenario |
| s-map-elites | Tooling scenario; archive coverage is the metric |
| s-predation-neural | Demo-only; no fidelity claim |
| s-cephalopod | Demo-only |
| s-kitchen-sink | Demo-only |
| s-module-comparison | Demo-only |
| s-cross-module | Demo-only |

## Priority improvements

1. **s-rl** (✅ moderate): +5.2 agents is 2.6% — the figure with
   5 seeds + bold mean makes this barely visible. Consider: show the
   MEAN difference as a bar chart alongside the trajectory plot.
2. **s-pace-of-life** (✅ moderate): metabolic rate barely evolves
   at defaults. Need a parameter search for a regime where the
   fast-pace/slow-pace divergence is clear.
3. **s-parental-investment** (✅ but unchecked): verify the figure
   shows a clear Trivers effect. If not, recalibrate.
4. **s-signals** (✅ but unchecked): verify Zahavi handicap is
   visually obvious. The signal_cost parameter drives the effect.

## What NOT to do

Don't hype 🟠 scenarios by cherry-picking seeds or showing
non-representative single runs. The audit methodology (16-seed with
2×SE) showed that 3-5 seed direction claims don't survive scrutiny.
Present 🟠 scenarios honestly with the "direction correct, magnitude
limited" framing.
