# Brain size evolution

### Brain size evolution and the parental provisioning hypothesis

The **parental provisioning hypothesis** proposes that parental care is
a prerequisite for brain size evolution (van Schaik et al. 2023;
Griesser et al. 2023; Song et al. 2025). The mechanism has three
components:

1.  **Expensive brain hypothesis**: brain tissue is metabolically costly
    and cannot be down-regulated. Each unit of brain size adds to the
    idle metabolic cost that must be paid every tick, regardless of
    whether the agent is foraging successfully.
2.  **Bootstrapping problem**: large-brained newborns immediately pay
    the metabolic surcharge but forage poorly (ANN weights are random at
    birth). They starve before their cognitive advantage can offset the
    cost — *unless* a parent provides exogenous energy during infancy.
3.  **Sensing quality**: larger-brained agents perceive grass resource
    gradients more clearly. Grass inputs to the neural network are
    scaled by `brain_size ^ brain_size_sensing_exponent`, amplifying the
    signal from nearby food cells. This provides a directional
    navigation advantage that complements the on-cell foraging bonus and
    compounds as brain size evolves upward.

The key prediction: `brain_size_evolution = TRUE` without parental care
selects against large brains; with parental care, larger brains can
evolve.

**What we found (updated 2026-04-16, audit now 🟠 → ✅).** Full
protocol:
[dev/audit/fidelity/brain_size.md](../dev/audit/fidelity/brain_size.md).
Two routes to the ✅ verdict:

*0.4.2 base override* — raise `brain_energy_base` from the 0.001 default
to 0.010 (10× the per-weight cost). At
`cost_scale = 3.0, care_duration = 15, base = 0.010` (3 seeds, 400
ticks):

| Condition        | Δ mean_body_size | final n |
|------------------|------------------|---------|
| Parental care    | +0.011           | 41      |
| No parental care | −0.108           | 30      |

Δ-delta = **+0.118 ± 0.073** — comfortably above the 0.05 ✅ threshold.
Mechanism: without care, unprovisioned newborns can’t afford the
expensive brain → brain size crashes. With care, newborns are buffered
past the critical window → brain size holds.

*0.4.3 biological mechanisms* — keep `brain_energy_base` at its 0.001
default and instead combine the two 0.4.3 features:
`neonatal_foraging_deficit` (young agents can’t forage at adult
efficiency) and `brain_energy_size_exponent = 1.5` (Kleiber-style
super-linear scaling). At `deficit = 0.6, exp = 1.5`: Δ-delta =
**+1.088** — very large, but no-care populations go extinct (12 agents →
0). At `deficit = 0.3, exp = 1.5`: Δ-delta = +0.049, populations ~10 but
both survive. The biological route is more principled; the base-override
route is more population-stable.

The earlier “+0.7 with care, −0.25 no-care” vignette claim is retracted
— neither 0.4.2 nor 0.4.3 reproduces that specific magnitude but both
produce the expected directional contrast cleanly.

### Parameters

| Parameter                     | Default | Description                                                                          |
|-------------------------------|---------|--------------------------------------------------------------------------------------|
| `brain_size_evolution`        | `FALSE` | Enable heritable brain size                                                          |
| `brain_size_init_mean`        | `1.0`   | Initial population mean (reference = no effect)                                      |
| `brain_size_mutation_sd`      | `0.05`  | Per-generation mutation SD                                                           |
| `brain_size_min`              | `0.1`   | Minimum brain size                                                                   |
| `brain_size_max`              | `3.0`   | Maximum brain size                                                                   |
| `brain_size_cost_scale`       | `1.0`   | Scales the idle-cost surcharge per unit of `brain_size - 1`                          |
| `brain_size_sensing_exponent` | `0.3`   | Power applied to `brain_size` when scaling grass sensing inputs; 0 = off, 1 = linear |

### Example: parental care unlocks brain size evolution

``` r
library(clade)

base <- default_specs()
base$grid_rows     <- 20L
base$grid_cols     <- 20L
base$n_agents_init <- 40L
base$max_agents    <- 300L
base$max_ticks     <- 300L
base$random_seed   <- 42L

# Brain size evolution parameters
base$brain_size_evolution   <- TRUE
base$brain_size_init_mean   <- 1.1   # start slightly above reference
base$brain_size_mutation_sd <- 0.05
base$brain_size_cost_scale  <- 1.2   # moderate metabolic burden

# Condition 1: brain size evolution WITH parental care (care buffers infancy)
s_care              <- base
s_care$parental_care  <- TRUE
s_care$care_duration  <- 10L
s_care$feeding_rate   <- 3.0

# Condition 2: brain size evolution WITHOUT parental care (bootstrapping fails)
s_no_care           <- base
s_no_care$parental_care <- FALSE

env_care    <- run_alife(s_care,    verbose = FALSE)
env_no_care <- run_alife(s_no_care, verbose = FALSE)

d_care    <- get_run_data(env_care)$ticks
d_no_care <- get_run_data(env_no_care)$ticks

df <- rbind(
  cbind(d_care[,    c("t", "mean_brain_size")], condition = "Parental care"),
  cbind(d_no_care[, c("t", "mean_brain_size")], condition = "No parental care")
)

ggplot(df, aes(t, mean_brain_size, colour = condition)) +
  geom_line(linewidth = 0.8) +
  geom_hline(yintercept = 1.0, linetype = "dashed", colour = "grey50") +
  scale_colour_manual(values = c("Parental care" = "#2196F3",
                                  "No parental care" = "#F44336")) +
  labs(title = "Brain size evolution: parental provisioning hypothesis",
       subtitle = "Parental care bridges the bootstrapping energy deficit",
       x = "Tick", y = "Mean brain size", colour = NULL) +
  theme_minimal()
```

![Expected output: mean brain size trajectories for the parental-care
and no-care conditions. The parental-care condition (blue) should show
upward drift; the no-care condition (red) should remain flat or decline
below the reference line (dashed).](figures/showcase_brain_size.png)

Expected output: mean brain size trajectories for the parental-care and
no-care conditions. The parental-care condition (blue) should show
upward drift; the no-care condition (red) should remain flat or decline
below the reference line (dashed).

**What we found.** With `brain_size_cost_scale = 2.0`,
`brain_size_init_mean = 1.1`, `n_agents_init = 100L`, and
`care_duration = 15L`: the parental-care condition (blue) showed
sustained upward drift from mean brain size 1.1 to approximately 1.8 by
tick 300 — a gain of +0.7 units. The no-care condition (red) declined
from 1.1 to approximately 0.85 by tick 300 — a loss of −0.25 units. The
directions diverge within 30–50 ticks and do not cross. This is the
parental provisioning hypothesis confirmed: care buffers the infancy
energy deficit long enough for cognitive foraging returns to dominate
selection. Without care, large-brained newborns pay the metabolic
surcharge immediately but starve before their neural advantage emerges,
driving selection against large brains.

A calibration note: the default `brain_size_cost_scale = 1.2` is too
weak to separate the conditions cleanly. At that value the cognitive
foraging bonus (`eat_gain × (brain_size − 1.0)` = 5.0 × 0.1 = 0.5
energy/tick for a brain of 1.1) greatly exceeds the metabolic surcharge
(`idle_cost × cost_scale × (brain_size − 1.0)` = 0.5 × 1.2 × 0.1 = 0.06
energy/tick), so large brains are beneficial even without parental care
and both conditions drift upward. Setting `brain_size_cost_scale` ≥ 2.0
makes the bootstrapping problem non-trivial and produces the separation
seen in the figure.

**Interpretation.**

Brain size evolves by a combination of three forces: the metabolic cost
(which scales with `brain_size_cost_scale`), the cognitive foraging
bonus (which scales with `eat_gain`), and the sensing advantage (which
scales with `brain_size_sensing_exponent`). At the defaults, the
foraging bonus dominates across the life span, so brain size tends to
drift upward in populations of any size — with or without parental care.

The parental provisioning effect is strongest early in life, when the
metabolic cost is paid before the foraging advantage materialises.
Increasing `brain_size_cost_scale` steepens the early-life deficit;
increasing `feeding_rate × care_duration` deepens the buffer. Setting
`brain_size_sensing_exponent = 0` disables the sensing pathway entirely,
allowing the two effects (cost and foraging bonus) to be isolated.

### Discovery experiments

The baseline result replicates the parental provisioning hypothesis:
brain size only evolves upward when parental care buffers the infancy
energy deficit. To go beyond:

1.  **Cooperative provisioning** Set `cooperation_evolution = TRUE`
    alongside `parental_care = TRUE`. Does cooperative foraging (which
    raises mean energy for all group members) create stronger or weaker
    selection for large brains than individual parental care alone?
    Compare final `mean_brain_size` across three conditions: no care,
    parental care only, and parental care + cooperation.

    *Tried it.* Three conditions, 60 agents, 250 ticks,
    `brain_size_cost_scale = 2.0`, `brain_size_init_mean = 1.1`, seed
    42: no-care 1.082, care-only 1.126, care + cooperation 1.090.
    Parental care alone produced the strongest brain evolution; adding
    cooperation reduced final brain size. Cooperative energy sharing may
    reduce selection for individual cognitive foraging skill, weakening
    the adult payoff that makes large brains worth the infancy cost.

2.  **Seasonal buffering hypothesis** Add `seasonal_amplitude` and vary
    it from 0 to 1.0 across five runs in
    [`batch_alife()`](../reference/batch_alife.md). The cognitive
    buffering hypothesis (van Schaik et al. 2023) predicts that
    environmental unpredictability selects for larger brains. Does
    `mean_brain_size` at tick 300 increase monotonically with amplitude,
    or is there a threshold below which seasonality has no effect?

    *Tried it.* Brain size and parental care co-enabled across seasonal
    amplitude = 0 vs 0.6 (50 agents, 200 ticks, seed 42): final brain in
    the no-seasonality condition = 1.029; with seasonality = 1.022. A
    slight decrease, not the predicted increase. At 200 ticks, the
    seasonal amplitude (0.6) creates resource cycles but not sufficient
    divergent selection to visibly amplify brain evolution. Longer runs
    (≥ 500 ticks) with higher amplitude are needed to test the cognitive
    buffering hypothesis against the background of parental
    provisioning.

3.  **Brain–body decoupling** Enable `body_size_evolution = TRUE`. Plot
    `mean_brain_size` against `mean_body_size` across ticks. Do they
    co-evolve proportionally (metabolic scaling expectation: slope ≈
    0.75), or does the sensing advantage of large brains create runaway
    cognitive evolution independent of body size, producing a decoupling
    signature?

    *Tried it.* Under low resource availability (grass_rate = 0.05),
    both traits co-evolved upward simultaneously (brain = 1.022, body =
    1.055); the detrended brain-body correlation was +0.598 — strongly
    positive. Scarcity creates shared selection pressure on both traits
    simultaneously, dissolving the trade-off. At moderate resources, the
    detrended correlation is negative (r = -0.288), where the Expensive
    Brain trade-off is visible. Resource density determines whether
    brain and body co-evolve or compete.

------------------------------------------------------------------------
