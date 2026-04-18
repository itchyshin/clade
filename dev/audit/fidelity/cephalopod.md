# Scenario: Cephalopod paradox (Liedtke & Fromhage 2019)

## 1. Theory

- **Primary source.** Liedtke, J. & Fromhage, L. (2019). When should
  cephalopods be intelligent? *Royal Society Open Science* 6:190242.
- **Core prediction.** Evolved within-lifetime learning rate should
  be HIGHEST at short lifespans. Short-lived organisms cannot wait
  for genetic evolution to encode food-finding solutions, so
  within-lifetime learning is the only viable adaptive mechanism.
  As lifespan lengthens, genetic evolution substitutes for learning
  and the selection pressure on learning rate weakens.

## 2. Implementation under audit

- **Kernel.** `rl_mode = "actor_critic"` + `learning_rate_evolution
  = TRUE` gives agents a heritable `mean_learning_rate` trait under
  REINFORCE-style policy gradient (Williams 1992).
- **Audit preset.** [`realistic_specs()`](../../../R/config.R#L1548)
  (60×60 grid, 150 init agents, 2000 ticks, `max_age = 30`, daily
  generations) with `complex_landscape = TRUE` so the environment
  actually rewards learning.
- **Protocol.** `max_age ∈ {30, 50, 100, 200}` × 10 seeds × 2000
  ticks = 40 runs. Measure `tail(mean_learning_rate, 1L)` at end
  of each run, regress against `max_age`.

## 3. Observed dynamics (10 seeds × 4 lifespans, 2026-04-18)

| `max_age` | N viable | Evolved `mean_lr` (mean ± SE) |
|---|---|---|
| 30 (cephalopod-like)  | 10/10 | **0.0909 ± 0.0029** |
| 50                    | 10/10 | 0.0793 ± 0.0025 |
| 100                   | 10/10 | 0.0809 ± 0.0027 |
| 200 (long-lived)      | 10/10 | **0.0712 ± 0.0042** |

Linear regression `mean_lr_final ~ max_age`:

- slope = **−9.23 × 10⁻⁵** ± 2.48 × 10⁻⁵
- t = **−3.72** (well past the 2 σ bar)
- ≈ 22% drop in evolved learning rate from `max_age = 30` to 200.

## 4. Verdict

- [x] **Matches theory.** Slope is negative and significant; short
      lifespans evolve higher learning rates, long lifespans evolve
      lower ones. All 40 runs viable — no seed extinctions.
- [ ] Consistent but underpowered
- [ ] Contradicts theory

**Status change: ⚪ N/A → ✅ passed** (2026-04-18).

### Cross-reference table

| Aspect | Liedtke & Fromhage 2019 | clade Julia (realistic_specs) |
|---|---|---|
| Direction (short life → higher LR) | Predicted | ✓ t = −3.72 |
| Magnitude at cephalopod-like lifespan (`max_age = 30`) | Highest | ✓ 0.091 |
| Learning rate for `max_age = 200` | Low | ✓ 0.071 |
| Mechanism | Evolution substitutes for learning as payback lengthens | ✓ reproduced |

## 5. Actions taken

- **Companion runner.** [`cephalopod_realistic.R`](cephalopod_realistic.R)
  — 40 runs, ~1 min wall on 40 PSOCK workers.
- **Saved result table.** [`cephalopod_realistic.rds`](cephalopod_realistic.rds).
- **Vignette.** [`s-cephalopod.Rmd`](../../../vignettes/s-cephalopod.Rmd)
  — updated "What we found" to cite the 10-seed result with the
  quantitative slope, and the claim that short lifespans should
  evolve higher learning rates is no longer a "tried it" note but
  the primary finding.
- **Key kernel spec surfaced.** `realistic_specs()` uses
  `max_age = 30` by default (ported from `fast_specs()`), so the
  short-lived-organism preset is now documented as
  cephalopod-relevant.
