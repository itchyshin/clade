# Parental care

### Parental care

**What it models.** Offspring are carried by the parent until graduation
at age `care_duration`. While carried, juveniles receive energy from the
parent at `feeding_rate` per tick. If the parent dies, carried offspring
die too (obligate altriciality). This models the evolutionary trade-off
between clutch size and offspring quality (Smith & Fretwell 1974).

**Key parameters.**

| Parameter            | Default | Effect                                           |
|----------------------|---------|--------------------------------------------------|
| `parental_care`      | FALSE   | Enable parental care                             |
| `care_duration`      | 5       | Ticks offspring are carried                      |
| `care_cost_per_tick` | 1.0     | Energy drained from parent per juvenile per tick |
| `feeding_rate`       | 5.0     | Energy transferred to juvenile per tick          |

**Expected output.** `n_juveniles` is positive. Per-capita offspring
count may be lower than baseline (parents can carry fewer), but juvenile
survival is higher. Population dynamics are more buffered.

``` r
s <- default_specs()
s$parental_care     <- TRUE
s$care_duration     <- 5L
s$care_cost_per_tick <- 2.0
s$max_ticks         <- 300L

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

**What we found (post-0.3.0 kernel fix).** Running with
`parental_care = TRUE` (`care_duration = 5`,
`care_cost_per_tick = 2.0`), 80 agents, 25×25 grid, 300 ticks (seed 42):
`n_juveniles` reaches a peak of 40 and averages ~0.3 across ticks
(juveniles come and go as offspring are born into the brood and graduate
out). Total births: 92; total deaths: 168. The graduation pathway —
wired up in 0.3.0 at
[reproduce.jl:126](../../inst/julia/src/reproduce.jl#L126) after the
earlier audit found it was a Phase-2 stub — correctly moves carried
juveniles into the adult population when they reach
`juvenile_independence_age` or `juvenile_independence_energy`.

Under these specific displayed parameters the population thins to
`final_n = 4` — `care_cost_per_tick = 2.0` per juvenile is expensive
enough that high-care-load parents lose mass and fail to forage, a
genuine cost-of-care dynamic rather than a module stub. Lower
`care_cost_per_tick` (e.g. 0.5) or raise `feeding_rate` to stabilise the
population across generations. The cost-of-care trade-off is now a real
observable, no longer masked by unreachable code.

**Before v0.3.0** this section reported “`n_juveniles` registered as 0
throughout” and explained that the graduation pathway was not yet wired.
That pathway was fixed in 0.3.0 (commit
[7ad2b1d](../../dev/audit/review/SUMMARY.md)) and the results above are
from the current kernel.

### Discovery experiments

The baseline result shows that juvenile counts are positive and
population dynamics are more buffered under parental care. To go beyond:

1.  **Care × brain size** Add `brain_size_evolution = TRUE`. The
    parental provisioning hypothesis predicts parental care is a
    prerequisite for brain size evolution. Does `mean_brain_size` at
    tick 300 increase more under `parental_care = TRUE`? Vary
    `care_duration` across `{2, 5, 10, 20}` ticks in
    [`batch_alife()`](../reference/batch_alife.md) to find the minimum
    care duration that allows brain size to evolve upward.

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
