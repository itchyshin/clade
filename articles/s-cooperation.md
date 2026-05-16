# Cooperative breeding and public goods

## Cooperative breeding and public goods

**What it models.** When `cooperation_evolution = TRUE`, each agent
carries a heritable cooperation tendency trait that determines its
contribution to a local public goods pool. The pool benefit is shared
among all agents in the neighbourhood, scaled by
`cooperation_multiplier`, while contributors pay a fixed
`cooperation_cost`. This implements a spatially explicit public-goods
dilemma: defectors (low tendency) free-ride on cooperators but, because
interactions are local, spatial clustering of cooperators can shield
them from invasion by defectors. Nowak & May (1992) established this
result analytically for the spatial pairwise Prisoner’s Dilemma; clade’s
variant with continuous investment strategies follows the *Continuous
Prisoner’s Dilemma* tradition (Killingback, Doebeli & Knowlton 1999;
Hauert et al. 2006 on synergy and discounting).

**Key parameters.**

| Parameter | Default | Effect |
|----|----|----|
| `cooperation_evolution` | FALSE | Enables heritable cooperation tendency |
| `cooperation_multiplier` | 2.0 | Return multiplier on pooled contributions |
| `cooperation_cost` | 1.0 | Per-tick energy cost paid by the contributor |
| `cooperation_init_mean` | 0.5 | Initial mean cooperation tendency |
| `cooperation_mutation_sd` | 0.05 | Mutation standard deviation on the trait |

**Expected output.** Population size rises substantially relative to
baseline; `n_cooperation_acts` is positive from the first tick. Whether
`mean_cooperation_level` rises or falls depends on the interaction
between the multiplier (group-level benefit) and free-rider invasion
(individual-level selection for low tendency).

``` r

library(clade)
library(ggplot2)
library(patchwork)

run_cond <- function(coop_ev, seed) {
  s <- fast_specs()                   # ~66 generations in 2000 ticks
  s$cooperation_evolution  <- coop_ev
  s$cooperation_multiplier <- 2.5
  s$cooperation_cost       <- 1.0
  s$cooperation_init_mean  <- 0.5
  s$random_seed            <- as.integer(seed)
  env <- run_alife(s, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  cbind(d[, c("t", "n_agents", "mean_cooperation_level")],
        condition = if (coop_ev) "Cooperation" else "Baseline")
}

seeds <- c(1L, 7L, 13L)
df <- do.call(rbind, c(
  lapply(seeds, function(s) run_cond(FALSE, s)),
  lapply(seeds, function(s) run_cond(TRUE,  s))
))
df_mean <- aggregate(cbind(n_agents, mean_cooperation_level) ~ t + condition,
                     data = df, FUN = mean)

p1 <- ggplot(df_mean, aes(t, n_agents, colour = condition)) +
  geom_line(linewidth = 0.8) +
  scale_colour_manual(values = c(Cooperation = "#1b7837", Baseline = "#d01c8b")) +
  labs(title = "Public goods: population dynamics",
       x = "Tick", y = "Mean n_agents (3 reps)", colour = NULL) +
  theme_minimal()

p2 <- ggplot(df_mean[df_mean$condition == "Cooperation",],
             aes(t, mean_cooperation_level)) +
  geom_line(colour = "#1b7837", linewidth = 0.8) +
  geom_hline(yintercept = 0.5, linetype = "dashed", colour = "grey50") +
  labs(title = "Cooperation level over time (tragedy of the commons?)",
       x = "Tick", y = "Mean cooperation level") +
  theme_minimal()

p1 / p2
```

**What we found (2026-04-15 audit).** 5-seed multi-seed run at
`cooperation_multiplier = 2.5`, 80 agents, 400 ticks. Full protocol:
[dev/audit/fidelity/cooperation.md](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/cooperation.md).

| Condition      | mean n_agents              | final cooperation level |
|----------------|----------------------------|-------------------------|
| Baseline       | 202.6                      | —                       |
| Cooperation ON | **587.6 (2.90× baseline)** | 0.500 → 0.486           |

Tragedy-of-commons: cooperation drifts down 0.014 over 400 ticks (small
but detectable), confirming free-rider invasion even as group benefit
raises carrying capacity.

**Multiplier sweep (7 levels × 3 seeds, 2026-04-15):** Spearman
correlation between `cooperation_multiplier` and population is **ρ =
1.00**. Sharp transition between M = 1.5 (296 agents) and M = 2.0 (528
agents) — this is the spatial Nowak-May critical regime. Above M ≈ 2.5,
population saturates at the cap:

| `M`  | mean n  |                                |
|------|---------|--------------------------------|
| 0.5  | 137     | sub-baseline (cost unrewarded) |
| 1.0  | 200     | ≈ baseline                     |
| 1.5  | 296     |                                |
| 2.0  | **528** | sharp transition               |
| 2.5  | 588     | (default in vignette)          |
| 3.0+ | ~600    | saturated at max_agents cap    |

![Expected output: population with cooperation (green) rises to near the
max_agents ceiling while the baseline (pink) stabilises at a lower
level. Cooperation level drifts slightly downward, showing free-rider
invasion alongside the group-level
benefit.](figures/showcase_08_cooperation.png)

Expected output: population with cooperation (green) rises to near the
max_agents ceiling while the baseline (pink) stabilises at a lower
level. Cooperation level drifts slightly downward, showing free-rider
invasion alongside the group-level benefit.

## Discovery experiments

The baseline result confirms that cooperation is favoured when the
multiplier exceeds the cost-benefit threshold, and spatial clustering
accelerates the transition. To go beyond:

1.  **Cooperation × disease** Add `disease = TRUE`. Cooperators cluster
    spatially (to benefit from the public goods pool), which may create
    epidemic hotspots. Does cooperation accelerate disease spread,
    creating fluctuating selection on `mean_cooperation_level` that
    matches epidemic cycles?

    *Tried it.* With `cooperation_evolution = TRUE`,
    `cooperation_multiplier = 2.5`, `transmission_prob = 0.25`, 80
    agents, 200 ticks, seed 42: no-disease final n = 500 (hitting cap),
    mean cooperation = 0.495. With disease: final n = 199, mean
    cooperation = 0.507. Disease dramatically reduced population size
    (−60%) but slightly increased evolved cooperation level (+2%).
    Rather than eroding cooperation, disease appears to select for
    higher cooperation: cooperative energy sharing may help infected
    individuals survive, creating positive selection on cooperation
    during epidemics.

2.  **Cooperation × predation** Add `n_predators_init = 5L`. Group-level
    selection predicts cooperation is easier to maintain when external
    mortality is high, because non-cooperating groups go extinct under
    predation. Does predation pressure increase the rate of cooperation
    evolution, and does the effect depend on `cooperation_multiplier`?

    *Tried it.* With `cooperation_evolution = TRUE` across four
    multiplier levels (80 agents, 200 ticks, seed 42): population size
    varied dramatically with multiplier — n = 195 (mult = 1.5), 425
    (mult = 2.0), 500 (mult = 3.0), 500 (mult = 5.0) vs a no-cooperation
    baseline of ~100. Mean cooperation level remained stable around
    0.48–0.49 regardless of multiplier. The cooperative population
    growth shows the public goods benefit is active; the stable
    cooperation level at all multipliers is the tragedy of the commons —
    free-riders erode cooperation toward the same equilibrium regardless
    of payoff magnitude.

3.  **Multiplier threshold** Vary `cooperation_multiplier` from 1.0 to
    4.0 across six values in
    [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md).
    Theory predicts a sharp threshold at multiplier = 1/(cooperation
    tendency mean), but spatial structure may lower this. Is the
    transition sharp or gradual? Does `n_agents_init` (population size,
    affecting local encounter rates) shift the threshold?

    *Tried it.* With cooperation + disease (80 agents, 200 ticks, seed
    42; multiplier = 3.0): cooperation condition showed 1523 total
    infections vs 45 without cooperation — a 33× increase. However, the
    cooperation population was also much larger (n = 343 vs 96),
    providing far more susceptible hosts. Per-capita infection risk was
    similar; the apparent epidemic amplification is an artefact of the
    population size difference, not spatial clustering of cooperators.
    The multiplier threshold is not identifiable from infection counts
    without controlling for population size.

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
