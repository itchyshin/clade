# Scenario: Predation and neural evolution

## 1. Theory

Two candidate claims have been floated for this scenario historically:

- **(a) Predation increases prey genetic diversity** by imposing
  strong directional selection on cognition and maintaining trait
  variance.
- **(b) Predation reduces prey equilibrium population size**
  directly through mortality (Williams 1966; standard predator–prey
  theory).

Claim (a) is a diversity-preservation argument analogous to
frequency-dependent selection; claim (b) is a straightforward
top-down control prediction.

## 2. Audit design (2026-04-18)

- **Preset.** [`realistic_specs()`](../../../R/config.R#L1548) —
  60×60 grid, 150 init prey, 2000 ticks, `max_age = 30`,
  `predator_max_age = 60`.
- **Conditions.**
  - `no_predators` (`n_predators_init = 0`)
  - `predators` (`n_predators_init = 30`, `predator_max_agents = 120`,
    `predator_energy_gain = 20`, `predator_attack_strength = 40`)
- **Seeds.** 8 per condition = 16 runs total, PSOCK-parallel.
- **Metrics.** Mean over last 500 ticks of: `genetic_diversity`,
  `mean_energy`, `n_agents`.

## 3. Results

All 16 runs viable — no crashes in either condition.

| Metric | no_predators (8 seeds) | predators (8 seeds) | Δ (pred − no) | SE | t | verdict |
|---|---|---|---|---|---|---|
| `genetic_diversity` | 1.876 ± 0.008 | 1.867 ± 0.006 | −0.009 | 0.010 | −0.90 | null |
| `mean_energy`       | 85.05 ± 0.42  | 85.11 ± 0.63  | +0.06  | 0.75  | +0.08 | null |
| `n_agents`          | 145.5 ± 4.4   | 124.4 ± 3.8   | **−21.1** | 5.8 | **−3.64** | **PASS** |

## 4. Verdict

**⚪ N/A → 🟠 passed-consistent** (2026-04-18). The honest reframe:

- Claim (b), **predation reduces prey population**, is robustly
  reproduced at t = −3.64 across 8 seeds (−21 agents, a 15% drop in
  equilibrium population size). This is the Williams-1966 / standard
  predator–prey prediction. ✅ at the standard 2 σ bar.
- Claim (a), **predation increases prey genetic diversity**, is
  NOT supported at realistic scale — diversity is essentially flat
  (Δ = −0.009, t = −0.90). The older framing ("predation imposes
  strong directional selection on cognition, maintaining variance")
  does not emerge here. The most defensible interpretation is that
  under clade's kernel, cognition-brain diversity is already
  mutation-bounded and predation's selection pressure is not strong
  enough to push the equilibrium noticeably.

The scenario is marked **🟠 passed-consistent** because the
demographic prediction (b) passes at 2 σ, while the diversity
prediction (a) does not and is retracted. Both claims are honestly
stated in the vignette.

## 5. Actions taken

- **Companion runner.**
  [`predation_neural_realistic.R`](predation_neural_realistic.R)
  — 16 runs, ~1 min wall on 16 PSOCK workers.
- **Saved result table.**
  [`predation_neural_realistic.rds`](predation_neural_realistic.rds).
- **Vignette.**
  [`s-predation-neural.Rmd`](../../../vignettes/s-predation-neural.Rmd)
  — "What we found" updated to lead with the robust
  prey-reduction claim and explicitly retract the diversity-increase
  claim.
