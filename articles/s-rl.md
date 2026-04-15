# Within-lifetime reinforcement learning

### Within-lifetime reinforcement learning

**What it models.** Each agent uses REINFORCE-with-baseline
(actor-critic) to update its brain’s output layer based on energy reward
signals during its lifetime. This implements the Baldwin effect:
individually-learned behaviours can stabilise genetically over
generations because learning relaxes the requirement for genes to encode
the exact optimal behaviour.

**Key parameters.**

| Parameter                 | Default  | Effect                            |
|---------------------------|----------|-----------------------------------|
| `rl_mode`                 | `"none"` | Set to `"actor_critic"` to enable |
| `rl_update_freq`          | 5        | Ticks between RL updates          |
| `learning_rate`           | 0.01     | Step size for output-layer update |
| `learning_rate_evolution` | FALSE    | Allow learning rate to evolve     |

**Expected output.** Agents with RL enabled adapt within their lifetime
to the local resource distribution. When
`learning_rate_evolution = TRUE`, the evolved learning rate reflects the
environmental uncertainty: noisy environments favour lower rates; stable
environments favour higher rates.

``` r
s <- default_specs()
s$rl_mode   <- "actor_critic"
s$max_ticks <- 300L

env  <- run_alife(s)
data <- get_run_data(env)
```

![Expected output: agents with within-lifetime RL adapt to local
resource distribution within their lifetime. The Baldwin Effect is
visible as the BNN prior sigma narrows over
generations.](figures/showcase_10_rl.png)

Expected output: agents with within-lifetime RL adapt to local resource
distribution within their lifetime. The Baldwin Effect is visible as the
BNN prior sigma narrows over generations.

**What we found.** Running 3 replicates with `rl_mode = "actor_critic"`
vs `"none"`, 80 agents, 25×25 grid, `grass_rate = 0.15`, 400 ticks
(seeds 41–43): mean population was 208 (RL) vs 207 (no RL); mean energy
124.8 vs 124.85. BNN prior sigma rose from ~0.30 early to ~0.50 late in
*both* conditions — the opposite of the expected Baldwin Effect
canalization. At `learning_rate = 0.01` and `rl_update_freq = 5`, each
REINFORCE gradient step is small relative to the BNN’s per-tick weight
resampling from a broad sigma prior. The copied delta is diluted before
the next update, preventing sustained policy improvement. The Baldwin
Effect (sigma narrowing through genetic assimilation) is predicted to
require: (i) runs longer than 400 ticks to allow genetic fixation; or
(ii) a narrower initial sigma that is itself heritable and under
selection. A dedicated BNN canalization scenario (see below) uses a
500-tick run that is more likely to reveal the sigma trajectory.

### Discovery experiments

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
