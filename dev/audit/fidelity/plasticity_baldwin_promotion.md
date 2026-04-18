# s-plasticity + s-baldwin promotion: 🟠 → ✅ via fluctuating-selection kernel

## Background

Pre-0.5.18, clade's seasonal environment was a **uniform
stressor**: `seasonal_amplitude` modulated grass_rate uniformly
across the grid, and `winter_death_prob` applied equal mortality
to every agent. Both phenotype-agnostic. Neither created the
fluctuating-selection regime DeWitt & Scheiner 2004 and Hinton &
Nowlan 1987 require.

Under that kernel we consistently observed `stable > seasonal` in
`mean_prior_sigma` — reversed from DeWitt direction. Not a bug;
correct kinetics for bottleneck-driven drift vs mutation-selection
balance.

## The 0.5.18 kernel fix: `seasonal_spatial_bias`

New spec in `R/config.R`, wired into `inst/julia/src/Clade.jl:grow_grass!`.
When `seasonal_spatial_bias > 0`, grass growth rate varies across
space and time:

- Summer (season > 0): grass grows preferentially in the **top
  half** (north) of the grid.
- Winter (season < 0): grass grows preferentially in the **bottom
  half** (south).

```julia
sign_factor = if x <= half 1.0f0 else -1.0f0 end
rate_xy = base_rate * (1.0f0 + sbias * season * sign_factor)
```

This creates fluctuating selection: the optimal foraging direction
flips between seasons. Plastic agents (high BNN sigma, high
within-lifetime RL) can track the flip; canalized agents cannot.

## Audit (2026-04-18, 0.5.18)

Design: 3 conditions × 16 seeds × 2000 ticks, `default_specs`, RL on
(`rl_mode = "actor_critic", bnn_sample_freq = 5`):

| condition | `seasonal_amplitude` | `seasonal_spatial_bias` | `season_length` |
|---|---|---|---|
| stable | 0 | 0 | — |
| amp_only (uniform stressor) | 0.5 | 0 | 100 |
| flipping (fluctuating selection) | 0.5 | 0.9 | 100 |

## Result

| condition | mean_prior_sigma ± SE | n_agents | gen_diversity |
|---|---|---|---|
| stable | 0.3759 ± 0.0038 | 96.9 | 0.580 |
| amp_only | 0.3800 ± 0.0025 | 94.2 | 0.586 |
| **flipping** | **0.3986 ± 0.0032** | **69.4** | **0.594** |

Pairwise differentials:

| comparison | Δ sigma ± SE | t | verdict |
|---|---|---|---|
| amp_only − stable | +0.0041 ± 0.0045 | +0.91 | uniform stressor has no plasticity signal |
| **flipping − stable** | **+0.0227 ± 0.0049** | **+4.58** | **PASS** |
| **flipping − amp_only** | **+0.0186 ± 0.0040** | **+4.60** | **PASS** |

## Interpretation

Under fluctuating selection, BNN prior sigma rises ~6% relative to
a stable environment, at t = +4.58 — decisively Hamilton 1987 /
DeWitt 2004 direction. Uniform stressor (amp_only) produces no
detectable plasticity signal (t = +0.91). **Only phenotype-
dependent fluctuating selection selects for plasticity**, as the
theory predicts.

Equilibrium population in the flipping regime (69 agents) is
28% lower than stable (97) — also consistent with DeWitt:
plasticity has demographic costs (exploration is expensive, some
agents don't learn in time). But the populations that survive are
on average more plastic than stable-environment populations.

## Verdict

**Both s-plasticity and s-baldwin promote 🟠 → ✅** (2026-04-18,
0.5.18). The fluctuating-selection kernel feature
(`seasonal_spatial_bias`) was the missing ingredient. Direction,
magnitude, and differential (flipping > amp_only > stable) all
align with DeWitt / Hinton-Nowlan predictions at t > 4σ.

The 0.5.10/0.5.11 "direction reversed" diagnoses remain correct
for the OLD (amp_only) kernel — they correctly diagnosed that
uniform seasonal stressors don't select for plasticity. With
0.5.18's phenotype-dependent spatial flipping, the theory's actual
predictions become testable and pass cleanly.

## Files

- Kernel change: `inst/julia/src/Clade.jl:grow_grass!`,
  `R/config.R:seasonal_spatial_bias`
- Audit: [plasticity_fluctuating_selection.R](plasticity_fluctuating_selection.R),
  [plasticity_fluctuating_selection.rds](plasticity_fluctuating_selection.rds)
- STATUS.md: both scenarios promoted with pressure-scan numbers.
