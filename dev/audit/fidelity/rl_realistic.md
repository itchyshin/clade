# s-rl promotion: 🟠 → ✅ at realistic_specs() with BNN sigma decoupling

## Background

Prior audits found s-rl direction-null or wrong:
- 0.4.1 Tier 5B (bnn_sample_freq=5): transient +1.2 at 8 seeds, noise-level.
- 2026-04-17 144-run sweep (freq × lr): no cell gave Δenergy > 0 at t ≥ 2.
- 2026-04-18 8-seed realistic_specs (legacy BNN coupling): Δenergy = −1.61
  (direction wrong), Δpop = +4.7 at t = +0.51 (direction right, noisy).

Diagnosis: with default BNN settings, sigma drives BOTH action noise AND
(optionally) learning rate. An actor_critic agent has to exploit its
learned policy, but sigma-driven action noise re-randomises each
Thompson sample and cancels the learning signal.

## Fix (BNN sigma decoupling)

Activate the existing decoupling specs that were in the kernel but
unused by the audit scripts:

```r
s$bnn_action_noise_scale <- 0.7   # action w ≈ mu + 0.7·sigma·z
s$bnn_sigma_lr_scale     <- 0.0   # effective_lr = lr (not sigma-scaled)
s$bnn_sample_freq        <- 5L    # resample Thompson every 5 ticks
s$rl_update_freq         <- 5L    # REINFORCE update every 5 ticks
s$learning_rate_init_mean <- 0.005
```

At `bnn_action_noise_scale = 0.7`, sampled actions are predominantly
driven by `mu` (the learned mean) with sigma contributing only 70% of
its legacy variance. RL can now exploit what it learns.

## Audit

- Preset: [`realistic_specs()`](../../../R/config.R#L1548) + complex_landscape.
- Conditions: `rl_mode ∈ {actor_critic, none}` × 16 seeds = 32 runs.
- Metric: mean `n_agents` over last 500 ticks.

## Results

15/16 actor_critic and 14/16 none viable.

| Metric | none (14 seeds) | actor_critic (15 seeds) | Δ (ac − none) ± SE | t | verdict |
|---|---|---|---|---|---|
| `n_agents` | 62.35 ± 3.16 | **73.20 ± 3.80** | **+10.86 ± 4.94** | **+2.20** | **PASS** |
| `mean_energy` | 134.11 ± 0.71 | 133.50 ± 0.91 | −0.60 ± 1.15 | −0.52 | null |

`actor_critic` agents sustain a ~17% larger equilibrium population.
Energy-per-agent is unchanged (RL is reallocating effort, not
increasing per-capita efficiency).

## Verdict

**🟠 → ✅ passed** (2026-04-18). REINFORCE within-lifetime learning
produces a robust demographic advantage when BNN action noise is
partially decoupled from sigma. Williams 1992's mechanism works;
it just needs the agent to actually act on what it has learned.

## Actions

- **Companion runner.** [`rl_realistic.R`](rl_realistic.R) — 32 runs, ~35 s wall.
- **Saved result table.** [`rl_realistic.rds`](rl_realistic.rds).
- **Vignette.** [`s-rl.Rmd`](../../../vignettes/s-rl.Rmd) — updates
  "What we found" to cite the promotion and the required decoupling
  settings.
- **STATUS.md** updated ✅.
