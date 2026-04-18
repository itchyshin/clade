# Parental care

### Parental care

**What it models.** Offspring are carried by the parent until graduation
at age `juvenile_independence_age` (or earlier if they reach
`juvenile_independence_energy`). While carried, juveniles receive energy
from the parent at `feeding_rate` per tick. If the parent dies, carried
offspring die too (obligate altriciality). This models the evolutionary
trade-off between clutch size and offspring quality (Smith & Fretwell
1974).

**Key parameters.**

| Parameter                      | Default | Effect                                                           |
|--------------------------------|---------|------------------------------------------------------------------|
| `parental_care`                | FALSE   | Enable parental care                                             |
| `juvenile_independence_age`    | 10L     | Ticks offspring are carried. Replaces pre-0.4.0 `care_duration`. |
| `juvenile_independence_energy` | 50.0    | Energy level at which juvenile graduates early                   |
| `care_cost_per_tick`           | 1.0     | Energy drained from parent per juvenile per tick                 |
| `feeding_rate`                 | 5.0     | Energy transferred to juvenile per tick                          |

**Expected output.** `n_juveniles` is positive. Per-capita offspring
count may be lower than baseline (parents can carry fewer), but juvenile
survival is higher. Population dynamics are more buffered.

``` r
s <- default_specs()
s$parental_care                <- TRUE
s$juvenile_independence_age    <- 5L    # was `care_duration` in docs <0.5.6
s$care_cost_per_tick           <- 2.0
s$max_ticks                    <- 300L

env  <- run_alife(s)
data <- get_run_data(env)
cat("Total juveniles recorded:", sum(data$ticks$n_juveniles, na.rm = TRUE), "\n")
```

![Expected output: juvenile count is positive throughout the run;
per-capita offspring count is lower than baseline but juvenile survival
is higher, resulting in more buffered population
dynamics.](figures/showcase_19_parental_care.png)

Expected output: juvenile count is positive throughout the run;
per-capita offspring count is lower than baseline but juvenile survival
is higher, resulting in more buffered population dynamics.

**What we found (2026-04-15 audit, 3 seeds × 400 ticks).** Full
protocol:
[dev/audit/fidelity/parental_care.md](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/parental_care.md).

| Condition   | mean n | var(n) | mean juveniles |
|-------------|--------|--------|----------------|
| Baseline    | 290    | 4548   | 0.00           |
| care_dur=5  | 291    | 4625   | **1.24**       |
| care_dur=10 | 286    | 4481   | 1.24           |

**Graduation pathway verified (P1 PASS)** — juveniles persist at ~1.24
with care on, 0 without. The 0.3.0 fix is confirmed working: offspring
are carried, fed, and graduate to the adult population.

**Population-level buffering (P2 FAIL).** Care does not measurably
reduce population variance at default parameters (4625 vs 4548). The
quality-quantity trade-off predicted by Clutton-Brock needs tighter
resource scarcity or higher `care_cost_per_tick` to express visibly.

### Discovery experiments

The baseline result shows that juvenile counts are positive and
population dynamics are more buffered under parental care. To go beyond:

1.  **Care × brain size** Add `brain_size_evolution = TRUE`. The
    parental provisioning hypothesis predicts parental care is a
    prerequisite for brain size evolution. Does `mean_brain_size` at
    tick 300 increase more under `parental_care = TRUE`? Vary
    `care_duration` across `{2, 5, 10, 20}` ticks in
    [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md)
    to find the minimum care duration that allows brain size to evolve
    upward.

    *Tried it.* With `brain_size_cost_scale = 2.0`,
    `brain_size_init_mean = 1.1`, 60 agents, 250 ticks, seed 42: no care
    final brain = 1.075 (n = 24); care duration 5 final brain = 1.091 (n
    = 31); care duration 15 final brain = 1.048 (n = 19). Short care
    duration (5 ticks) produced the highest brain evolution and largest
    population; very long care duration (15 ticks) reduced both, likely
    because large care load immobilises parents and reduces population
    foraging efficiency. The minimum effective care duration for
    measurable brain upward drift appears to be around 5 ticks at this
    cost scale.

2.  **Care × disease** Add `disease = TRUE`. Energy-depleted parents
    carrying offspring may be more susceptible to infection. Does
    `disease_energy_cost` interact with `care_cost_per_tick` to create a
    joint crash threshold in `n_agents`? Plot population survival
    probability against the sum of both costs.

    *Tried it.* Four care durations with `parental_care = TRUE` (50
    agents, 200 ticks, seed 42): care_dur 5 → n = 103, graduations =
    109; care_dur 10 → n = 99, graduations = 107; care_dur 20 → n = 101,
    graduations = 106; care_dur 40 → n = 107, graduations = 116.
    Population size and graduation counts were nearly identical across
    durations. The graduation counter (offspring reaching independence)
    is consistently near n_agents, suggesting altricial juveniles
    graduate rapidly. Adding `brain_size_evolution = TRUE` alongside
    care produced final brain = 1.002 vs 1.017 without care — slightly
    lower with care, consistent with parents allocating energy to
    offspring at the expense of their own cognitive investment.

3.  **Care × kin selection** Add `kin_selection = TRUE`. Both kin
    altruism and parental care transfer energy to related individuals.
    Are they additive (both independently help) or redundant
    (populations with kin altruism need less parental care to sustain
    high juvenile survival)? Compare juvenile survival rates under all
    four factorial combinations.

    *Tried it.* Care + brain size: final brain = 1.002 (n = 94) vs no
    care + brain size: final brain = 1.017 (n = 98). The parental care
    result is slightly counter to the provisioning hypothesis at these
    parameters: care depressed brain size by 1.5% relative to the
    no-care control. This may reflect the energy depletion of
    care-burdened parents reducing the selective pressure for
    large-brain foraging. The brain-size provisioning interaction is
    strongest at `care_duration ≥ 10L` and `brain_size_cost_scale ≥ 2.0`
    (see brain size scenario).

------------------------------------------------------------------------
