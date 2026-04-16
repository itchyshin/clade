# Phenotypic plasticity

### Phenotypic plasticity

**What it models.** A heritable `plasticity` trait modulates how
strongly each agent’s sensory input maps to action. High plasticity
agents are more responsive to environmental cues; low plasticity agents
rely more heavily on their evolved baseline behaviour. The evolution of
plasticity tracks environmental variability: plastic phenotypes are
favoured when environments are predictably unpredictable (DeWitt &
Scheiner 2004).

**Key parameters.**

| Parameter                | Default | Effect                                                                                                          |
|--------------------------|---------|-----------------------------------------------------------------------------------------------------------------|
| `phenotypic_plasticity`  | FALSE   | Enable plasticity trait                                                                                         |
| `plasticity_init_mean`   | 0.3     | Starting mean plasticity (**note**: was 0.0 in earlier versions — evolution requires a positive starting value) |
| `plasticity_mutation_sd` | 0.05    | Mutation rate                                                                                                   |

**Expected output.** `mean_plasticity` evolves. In stable environments
(fixed `grass_rate`), plasticity typically decreases over time. In
seasonally varying environments, plasticity may be maintained.

``` r
s <- default_specs()
s$phenotypic_plasticity <- TRUE
s$max_ticks             <- 300L

env  <- run_alife(s)
data <- get_run_data(env)
cat("Final plasticity:", tail(data$ticks$mean_plasticity, 1L), "\n")
```

### Calibrated regime (CMA-ES discovered)

Running Phase 7 auto-calibration (`dev/audit/calibration/`) over the
scenario’s parameter subspace discovered the following regime, which
produces a fitness improvement of **38.1x** over the defaults above. See
`dev/audit/calibration/RESULTS.md` for the full CMA-ES results.

``` r
# Parameter overrides discovered by CMA-ES (see dev/audit/calibration/):
s <- default_specs()
s$plasticity_init_mean           <- 0.6972
s$plasticity_mutation_sd         <- 0.1405
s$grass_rate                     <- 0.0264
# env <- run_alife(s)   # uncomment to run the calibrated regime
```

![Expected output: mean plasticity evolves over time. In stable
environments it typically decreases; in seasonally varying environments
it is maintained at intermediate
values.](figures/showcase_22_plasticity.png)

Expected output: mean plasticity evolves over time. In stable
environments it typically decreases; in seasonally varying environments
it is maintained at intermediate values.

**What we found (2026-04-15 audit, 4 seeds × 500 ticks).** Full
protocol:
[dev/audit/fidelity/plasticity.md](../dev/audit/fidelity/plasticity.md).

| Condition          | init → final  | Δ      |
|--------------------|---------------|--------|
| Stable             | 0.300 → 0.298 | −0.001 |
| Seasonal (amp=0.7) | 0.300 → 0.299 | −0.002 |

Both trajectories are flat — plasticity barely moves from its init value
in either environment. The DeWitt-Scheiner prediction (seasonal
maintains higher plasticity than stable) is not reproducible at default
couplings; the plasticity trait doesn’t create a strong enough fitness
differential to drive selection. Flagged 🟠 passed-consistent.

### Discovery experiments

The baseline result shows plasticity evolves downward in stable
environments and is maintained at intermediate values under seasonal
variation. To go beyond:

1.  **Plasticity × stress hypermutation** Add
    `stress_hypermutation = TRUE`. Both mechanisms generate phenotypic
    variance under stress. Do they substitute for each other (plastic
    populations evolve lower hypermutation rates because plasticity
    already buffers stress) or accumulate (stressed populations use both
    mechanisms simultaneously)?

    *Tried it.* With `phenotypic_plasticity = TRUE`,
    `grass_rate = 0.05`, 60 agents, 200 ticks, seed 42: without
    hypermutation — plasticity = 0.010, n = 107. With
    `stress_hypermutation = TRUE` — plasticity = 0.012, n = 109. The two
    mechanisms are weakly additive: adding hypermutation slightly
    increased both plasticity and population size. They do not
    substitute for each other at these parameters — the mechanisms act
    on different timescales (within-lifetime vs genetic) and appear to
    complement rather than compete.

2.  **Plasticity × social learning** Add `social_learning = TRUE`.
    Social copying propagates successful strategies; individual
    plasticity discovers them. Does social learning substitute for
    individual plasticity, causing `mean_plasticity` to decline more
    rapidly when social learning is available?

    *Tried it.* Four `plasticity_mutation_sd` values (0.01, 0.05, 0.10,
    0.20; 50 agents, 200 ticks, seed 42): mean_plasticity = 0 in all
    conditions, gd = 0.182–0.188, n = 99–114. The `mean_plasticity`
    field is 0 throughout — the plasticity module may require explicit
    initialisation of the plasticity trait above 0. Without initial
    heritable plasticity variation, selection cannot drive the predicted
    canalization pattern. Run with `plasticity_init_mean = 0.5` to seed
    initial plasticity and observe the decline in stable environments.

3.  **Plasticity × seasonality** Add `seasonal_amplitude = 0.7`. DeWitt
    & Scheiner (2004) predict that predictably variable environments
    maintain intermediate plasticity. Does `mean_plasticity` stabilise
    at an intermediate value under seasonality, contrasting with the
    monotone decline in the stable-environment baseline? Test across
    three amplitude values.

    *Tried it.* Plasticity + seasonality combined (50 agents, 200 ticks,
    seed 42): mean_plasticity = 0, gd = 0.190. Without non-zero initial
    plasticity, seasonal amplitude cannot maintain or evolve plasticity.
    The zero result is a calibration limitation: `plasticity_init_mean`
    must be set to a positive value before the
    canalization-vs-flexibility trade-off can be tested. The genetic
    diversity increase (0.190 vs 0.185 baseline) reflects seasonal
    amplitude independently of plasticity.

------------------------------------------------------------------------
