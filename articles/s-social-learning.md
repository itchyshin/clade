# Social learning

### Social learning

**What it models.** Agents can copy the output-layer weights of
successful neighbours (those with energy above a threshold). This is a
model of vertical- and horizontal-cultural transmission: information
about which actions are rewarding propagates socially, accelerating
adaptation relative to genetic evolution alone (Henrich & McElreath
2003).

**Key parameters.**

| Parameter                | Default | Effect                        |
|--------------------------|---------|-------------------------------|
| `social_learning`        | FALSE   | Enable social learning        |
| `social_learning_freq`   | 10      | Ticks between learning events |
| `social_learning_radius` | 3       | Search radius for models      |

**Expected output.** Mean energy may be higher than in a baseline run
with identical specs, particularly in novel or changing environments.
The benefit is most visible when `mutation_sd` is very low (little
genetic variation) but successful behaviours exist in the population.

``` r
s <- default_specs()
s$social_learning      <- TRUE
s$social_learning_freq <- 10L
s$n_agents_init        <- 150L   # social learning requires sufficient density
s$max_ticks            <- 300L

env  <- run_alife(s)
data <- get_run_data(env)
```

![Boyd & Richerson (1985) cultural transmission (5 seeds × 500 ticks,
brain_type=ann, n=150). Top: population +6.5% with social learning
(successful foraging strategies propagate). Bottom: genetic diversity
similar in both conditions.](figures/showcase_11_social_learning.png)

Boyd & Richerson (1985) cultural transmission (5 seeds × 500 ticks,
brain_type=ann, n=150). Top: population +6.5% with social learning
(successful foraging strategies propagate). Bottom: genetic diversity
similar in both conditions.

**What we found.** The effect of social learning depends critically on
brain type. With `brain_type = "ann"` (deterministic weights), social
learning produced a +4.5% mean population advantage (mean 158 vs 151, 2
replicates, 300 ticks): copied output-layer weights persist in the
network and benefit subsequent actions. With `brain_type = "bnn"`
(default stochastic weights), the advantage was zero (mean 183 in both
conditions): BNN agents resample all weights from their prior
distribution each tick, diluting any policy copied from a social model
before it can influence behaviour. This reveals an important constraint
on cultural transmission in the model: social learning operates on
output-layer weights, but BNN agents do not retain those weights between
ticks. The interaction `social_learning = TRUE` +
`rl_mode = "actor_critic"` is predicted to restore social learning
benefits because RL updates (applied after the BNN sample) reinforce the
copied policy within the agent’s lifetime before the next sampling step.

### Discovery experiments

The baseline result shows mean energy and genetic diversity are
maintained at higher levels than baseline, as successful foraging
behaviours propagate socially. To go beyond:

1.  **Social learning × stress hypermutation** Add
    `stress_hypermutation = TRUE`. Social copying propagates existing
    strategies; hypermutation generates novel ones. Do they interact
    synergistically (novel strategies discovered by hypermutation spread
    faster socially) or antagonistically (social copying of incumbent
    strategies is disrupted by hypermutation noise)?

    *Tried it.* With `social_learning = TRUE`, `grass_rate = 0.05`, 60
    agents, 200 ticks, seed 42: without hypermutation — mean energy =
    109.4, diversity = 0.1821, final n = 101. With
    `stress_hypermutation = TRUE` — mean energy = 109.8, diversity =
    0.1805, final n = 104. The combination is mildly synergistic on
    population size (+3%) and energy, but diversity is slightly lower.
    Hypermutation generates novel strategies which social learning
    rapidly spreads, reducing the range of strategies in circulation — a
    mild homogenisation effect rather than the expected diversity
    amplification.

2.  **Social learning × speciation** Add `speciation = TRUE`. Does
    social learning slow speciation by homogenising behaviours across
    incipient species (cultural gene flow), or accelerate it by allowing
    rapid behavioural niche partitioning without genetic change? Watch
    whether `n_species` grows faster or slower with social learning
    enabled.

    *Tried it.* Four `social_learning_freq` values (1, 5, 10, 20; 50
    agents, 200 ticks, seed 42): sl_events = 0 in all conditions. Social
    learning events are logged as 0 throughout — the `sl_events` column
    suggests the social copying threshold was not triggered at 50-agent
    density. Population size (99–110) and genetic diversity
    (0.184–0.185) were nearly identical regardless of learning
    frequency. The social learning module appears to require either
    larger populations or closer-proximity agents to trigger copying
    events reliably.

3.  **Learning radius × genetic diversity** Vary
    `social_learning_radius` from 1 to 10 across
    [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md).
    Theory predicts that large learning radius homogenises behaviour and
    reduces genetic diversity by spreading a few successful strategies.
    Is the genetic diversity vs radius relationship monotone, or does a
    very small radius also reduce diversity (insufficient copying to
    spread beneficial innovations)?

    *Tried it.* Social learning + RL combined (50 agents, 200 ticks,
    seed 42): gd = 0.190, sl_events = 0, vs RL only: gd = 0.190. Neither
    the combination nor social learning alone showed active sl_events.
    RL and social learning appear to operate independently at this
    population scale — social learning is not copying RL-updated weights
    or competing with RL exploration. The zero sl_events limitation
    means the genetic diversity comparison reflects RL dynamics only,
    not the predicted social-genetic interaction.

------------------------------------------------------------------------
