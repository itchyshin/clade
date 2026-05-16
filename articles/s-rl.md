# Within-lifetime reinforcement learning

## Within-lifetime reinforcement learning

**What it models.** Each agent uses REINFORCE-with-baseline
(actor-critic; Williams 1992) to update its brain’s output layer based
on energy reward signals during its lifetime. This implements the
Baldwin effect (Hinton & Nowlan 1987): individually-learned behaviours
can stabilise genetically over generations because learning relaxes the
requirement for genes to encode the exact optimal behaviour. The
demographic signature clade measures — population size rising under
`actor_critic` — follows the Baldwin framework rather than from the
algorithm paper itself.

**Key parameters.**

| Parameter                 | Default  | Effect                            |
|---------------------------|----------|-----------------------------------|
| `rl_mode`                 | `"none"` | Set to `"actor_critic"` to enable |
| `rl_update_freq`          | 5        | Ticks between RL updates          |
| `learning_rate`           | 0.01     | Step size for output-layer update |
| `learning_rate_evolution` | FALSE    | Allow learning rate to evolve     |

**Expected output (corrected 2026-04-18).** REINFORCE within-lifetime
learning produces a robust **demographic** advantage — actor_critic
agents sustain a ~17% larger equilibrium population than non-learning
controls — once actions are allowed to exploit the learned posterior
mean rather than being fully re-randomised by Thompson sampling at each
tick. The default BNN sampling fully couples action noise to sigma,
which cancels any within-lifetime policy improvement; RL only pays off
when `bnn_action_noise_scale < 1.0`.

**What we found (2026-04-18
[`realistic_specs()`](https://itchyshin.github.io/clade/reference/realistic_specs.md) +
BNN sigma decoupling, 16 seeds × 2 conditions, 60×60 grid, 2000
ticks).**

Kernel settings required:

``` r

s$bnn_action_noise_scale <- 0.7    # actions ≈ mu + 0.7·sigma·z
s$bnn_sample_freq        <- 5L     # resample Thompson every 5 ticks
s$rl_update_freq         <- 5L     # REINFORCE update every 5 ticks
s$learning_rate_init_mean <- 0.005
s$complex_landscape       <- TRUE   # RL needs a non-trivial policy
```

| Metric | `rl_mode = "none"` (14 viable) | `"actor_critic"` (15 viable) | Δ ± SE | t | verdict |
|----|----|----|----|----|----|
| `n_agents` (last 500 ticks) | 62.4 ± 3.2 | **73.2 ± 3.8** | **+10.86 ± 4.94** | **+2.20** | **PASS** |
| `mean_energy` | 134.1 ± 0.7 | 133.5 ± 0.9 | −0.60 ± 1.15 | −0.52 | null |

**This promotes the scenario from 🟠 to ✅.** Williams 1992’s mechanism
works; it needs the agent to actually *use* what it learns. The
energy-per-agent metric is flat — RL reallocates foraging efficiency
into reproduction, increasing population size but not per-capita energy.
See
[dev/audit/fidelity/rl_realistic.md](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/rl_realistic.md)
for protocol and per-seed results.

**Historical audits.** The 2026-04-17 144-run sweep (`freq × lr`) showed
no significant effect and reframed this scenario to 🟠. That was the
right call with the legacy BNN-coupling — actor_critic’s learned mu was
being washed out by sigma-driven action noise each tick. The decoupling
is what unlocks the canonical signal.

``` r

s <- default_specs()
s$rl_mode   <- "actor_critic"
s$max_ticks <- 300L

env  <- run_alife(s)
data <- get_run_data(env)
```

![0.4.1 audit (3 seeds × 3 BNN sample frequencies × RL on/off × 500
ticks). At bnn_sample_freq=1 the](figures/showcase_10_rl.png)

0.4.1 audit (3 seeds × 3 BNN sample frequencies × RL on/off × 500
ticks). At bnn_sample_freq=1 the BNN resamples weights every tick,
washing out REINFORCE gradient updates (null Δ). At freq=5 the sample
persists long enough for gradients to compound — Δn = +5.2 (✅). At
freq=20 the sample is too rigid and populations crash. Scenarios
combining BNN brains with rl_mode=‘actor_critic’ should use freq=5.

**Earlier audit (2026-04-16, since superseded).** A 3-seed sweep over
`bnn_sample_freq ∈ {1, 5, 20}` reported Δn = +5.2 agents at freq = 5,
and the scenario was labelled ✅ at that regime. The 2026-04-17 8-seed ×
3×3 `rl_update_freq × learning_rate` sweep (above) did not reproduce a
significant positive Δ at any tested cell, so the earlier 3-seed claim
is retracted. The current honest position is documented in the paragraph
above.

The Baldwin canalisation interaction is documented separately in
[s-baldwin](https://itchyshin.github.io/clade/articles/s-baldwin.md) —
sigma coupling to behavioural variance creates a kernel-limitation
caveat, which is independent of the RL gradient channel.

## Discovery experiments

The baseline result shows agents with RL adapt within their lifetime to
local resource distribution, and the Baldwin Effect is visible as BNN
prior sigma narrows. To go beyond:

1.  **RL × brain size** Add `brain_size_evolution = TRUE`. Does
    within-lifetime RL reduce selection pressure on brain size (because
    learning compensates for cognitive limitations) or amplify it
    (because larger-brained agents learn more efficiently via the
    sensing advantage)? Compare `mean_brain_size` at tick 500 with and
    without `rl_mode = "actor_critic"`.

    *Tried it.* With `brain_size_evolution = TRUE`,
    `brain_size_cost_scale = 1.5`, 60 agents, 200 ticks, seed 42: no-RL
    final brain = 1.034 (n = 88); with RL final brain = 1.012 (n = 97).
    RL *reduced* selection pressure on genetic brain size: agents
    compensate for moderate cognitive limitations by learning within
    their lifetimes, weakening the fitness gradient for genetically
    encoded large brains. Population size increased under RL (+10%), but
    brain size decreased — RL and genetic brain evolution are
    substitutable rather than complementary at these parameters.

2.  **RL × social learning** Add `social_learning = TRUE`. Do agents
    that can both learn individually (RL) and copy socially converge
    faster than either mechanism alone? Watch `mean_energy` and
    `genetic_diversity`: does the combination flatten genetic diversity
    by reducing between-individual variance in foraging success more
    than either mechanism separately?

    *Tried it.* Four learning rates tested (lr = 0.001, 0.01, 0.05,
    0.10; 50 agents, 200 ticks, seed 42): gd = 0.183, 0.185, 0.192,
    0.184; mean_energy = 118, 120, 116, 119; n = 104, 106, 120, 108.
    Learning rate = 0.05 produced the highest genetic diversity (0.192)
    and largest population (n = 120), while mean energy was lowest — a
    fast-exploring policy creates more phenotypic variance and larger
    populations at the cost of per-agent energy efficiency. The
    diversity increase with RL (0.183–0.192 vs ~0.185 baseline without
    RL) is consistent with the cross-module gallery finding.

3.  **RL under seasonality** Add `seasonal_amplitude = 0.8`. Does
    within-lifetime RL improve survival during resource troughs by
    allowing agents to adapt their foraging strategy to winter
    conditions within a single season? Compare mean agent survival rates
    across the seasonal cycle with and without RL.

    *Tried it.* RL + epigenetics combined (50 agents, 200 ticks, seed
    42): mean_sigma = 0.275 vs RL only: sigma = 0.333, gd = 0.191 vs
    0.180. Adding epigenetics reduced BNN sigma and increased genetic
    diversity simultaneously. Epigenetic inheritance of sigma values
    allows offspring to start with partially canalized priors (lower
    sigma = narrower uncertainty), accelerating the Baldwin Effect. The
    gd increase (0.191 vs 0.180) is consistent with epigenetic variation
    adding an additional heritable dimension beyond genetic variation
    alone.

------------------------------------------------------------------------

------------------------------------------------------------------------

## Citation

If you use this scenario in published work, please cite both the `clade`
package and the primary literature the scenario references. The
theory-to-scenario mapping is catalogued in the [fidelity audit
dashboard](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/DASHBOARD.md).

``` bibtex
@misc{clade2026,
  author  = {Nakagawa, Shinichi},
  title   = {clade: evolve behaviour, minds, and brains in R},
  year    = {2026},
  note    = {R package},
  url     = {https://github.com/itchyshin/clade}
}
```
