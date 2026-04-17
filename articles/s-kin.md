# Kin selection

### Kin selection and cooperative social structure

**What it models.** Agents can transfer energy to nearby relatives via
two mechanisms: Hamilton’s pedigree-based kin altruism
(`kin_selection = TRUE`) and the IFfolk model
(`iffolk_selection = TRUE`), which adds parliamentary enforcement of
cooperative norms (Fromhage & Jennions 2019).

**Hamilton’s kin selection.** Agents with energy above a threshold
donate a fixed cost to the most closely related Moore-neighbourhood
agent with relatedness r ≥ `kin_altruism_r_min`. Relatedness is computed
from the pedigree (parent chains): r = 0.5 for parent–offspring, 0.25
for siblings, 0 otherwise. This operationalises Hamilton’s rule: the
altruistic act evolves when r × benefit \> cost.

**IFfolk and parliamentary enforcement.** The IFfolk model extends kin
selection with a `helper_tendency` trait and `parliament_suppression`,
which penalises defectors (low `helper_tendency`) surrounded by
cooperators. This models the *parliament of genes* (Fromhage & Jennions
2019): cooperative behaviour is enforced by neighbour-level suppression
of defection.

**Hamilton’s kin altruism parameters.**

| Parameter                       | Default | Effect                                   |
|---------------------------------|---------|------------------------------------------|
| `kin_selection`                 | FALSE   | Enable kin altruism                      |
| `kin_altruism_r_min`            | 0.25    | Minimum relatedness to donate (siblings) |
| `kin_altruism_cost`             | 2.0     | Energy transferred per act               |
| `kin_altruism_min_donor_energy` | 50.0    | Donor energy floor                       |

**IFfolk and parliament parameters.**

| Parameter                   | Default | Effect                                   |
|-----------------------------|---------|------------------------------------------|
| `iffolk_selection`          | FALSE   | Enable IFfolk transfers                  |
| `iffolk_r_min`              | 0.125   | Minimum relatedness (cousins and closer) |
| `iffolk_radius`             | 5       | Neighbourhood radius for kin search      |
| `iffolk_transfer`           | 3.0     | Energy transferred per act               |
| `iffolk_min_energy`         | 60.0    | Donor must exceed this energy            |
| `parliament_suppression`    | FALSE   | Penalise defectors among cooperators     |
| `parliament_cost`           | 0.5     | Energy penalty for defectors             |
| `cooperative_breeding`      | FALSE   | Enable `helper_tendency` trait           |
| `helper_tendency_init_mean` | 0.2     | Starting helper tendency                 |

**Expected outputs.** (1) Kin altruism: `n_altruistic_acts` is positive;
population size is generally higher than baseline; genetic diversity may
be slightly lower due to local inbreeding. (2) IFfolk:
`mean_helper_tendency` increases over time; `n_iffolk_transfers` grows
with population size; parliament suppression accelerates convergence
near 1.0.

**Example: Hamilton kin altruism.**

``` r
library(clade)
library(ggplot2)
library(patchwork)

run_one <- function(kin, seed) {
  s <- fast_specs()                  # ~66 generations in 2000 ticks
  s$kin_selection          <- kin
  s$kin_altruism_r_min     <- 0.25   # help siblings (r ≥ 0.25) and closer
  s$kin_altruism_cost      <- 5.0    # 5 energy units per act
  s$grass_rate             <- 0.08   # scarce resources to create selection pressure
  s$random_seed            <- as.integer(seed)
  env  <- run_alife(s, verbose = FALSE)
  d    <- get_run_data(env)$ticks
  cbind(d[, c("t", "n_agents", "n_altruistic_acts")],
        condition = if (kin) "Kin selection" else "Baseline")
}

seeds <- c(1L, 7L, 13L, 19L, 25L)
df <- do.call(rbind, c(
  lapply(seeds, function(s) run_one(FALSE, s)),
  lapply(seeds, function(s) run_one(TRUE,  s))
))

# Average across replicates
df_mean <- aggregate(cbind(n_agents, n_altruistic_acts) ~ t + condition,
                     data = df, FUN = mean)

p1 <- ggplot(df_mean, aes(t, n_agents, colour = condition)) +
  geom_line(linewidth = 0.8) +
  scale_colour_manual(values = c("Kin selection" = "#2196F3",
                                  "Baseline"      = "#F44336")) +
  labs(title = "Kin selection: population dynamics",
       x = "Tick", y = "Mean n_agents (5 reps)", colour = NULL) +
  theme_minimal()

p2 <- ggplot(df_mean[df_mean$condition == "Kin selection",],
             aes(t, n_altruistic_acts)) +
  geom_line(colour = "#2196F3") +
  labs(title = "Altruistic acts per tick",
       x = "Tick", y = "n_altruistic_acts") +
  theme_minimal()

p1 / p2
```

**What we found (2026-04-15 audit, 60 runs).** Hamilton’s rule is
reproduced with striking clarity at the population level. Full protocol:
[dev/audit/fidelity/kin.md](../dev/audit/fidelity/kin.md).

- **Default regime** (`r_min = 0.25`, `B = 10`, `C = 2` → rB/C = 1.25):
  population rises from 166 (baseline) to **194 (+16.4%)** with 4196
  altruistic acts over 400 ticks.
- **Hamilton-violating regime** (`B = 4`, `C = 10` → rB/C = 0.1): forced
  altruism *reduces* population to 153 (**−7.7%**) — cost exceeds
  indirect benefit, exactly as theory predicts.
- **C × B grid (9 combinations):** Spearman correlation between rB/C
  ratio and equilibrium population is **ρ = 0.97** — one of the cleanest
  population-level confirmations of a textbook prediction observed in
  this audit.

| Regime                | rB/C | Mean n_agents |
|-----------------------|------|---------------|
| Baseline              | —    | 166           |
| `C=10, B=4`           | 0.10 | 154           |
| `C=10, B=20`          | 0.50 | 191           |
| `C=2, B=10` (default) | 1.25 | 194           |
| `C=2, B=20`           | 2.50 | **211**       |

(The higher the rB/C ratio, the greater the population benefit from
altruism. At `rB/C = 2.5`, population rises to 211 agents, +27% above
the baseline.)

**Implementation note.** clade’s kin altruism module is not evolutionary
— the kernel performs altruism deterministically when the gate
(relatedness ≥ `r_min` and `energy > min_donor_energy`) fires. So this
audit tests the *population-level consequences* of Hamilton’s rule, not
the invasion dynamics of an altruistic mutant. For the evolutionary
dynamics (heritable `helper_tendency`), see the cooperative-breeding and
IFfolk modules below.

### Calibrated regime (CMA-ES — superseded by direct Hamilton test)

The 2026-04-15 audit directly varied `C` and `B` across a 9-cell grid
and found population size tracks `rB/C` with Spearman ρ = 0.97. The
strongest regime we observed was `C = 2, B = 20` (rB/C = 2.5) giving 211
agents vs baseline 166 — a +27% lift, and the clearest theoretical
signal in clade’s scenario suite to date. The prior CMA-ES-calibrated
suggestion of `C = 14, B = 143` would give the same rB/C = 2.55 but at
much higher energy scales; direct Hamilton tuning via the C×B grid is
more interpretable.

![Expected output: kin-selection population (blue) is sustained at
higher mean density than the baseline (red). Altruistic acts per tick
(bottom) are highest when resources are tight and related neighbours are
present.](figures/showcase_07_kin_selection.png)

Expected output: kin-selection population (blue) is sustained at higher
mean density than the baseline (red). Altruistic acts per tick (bottom)
are highest when resources are tight and related neighbours are present.

**Example: IFfolk with parliament suppression.**

``` r
s <- default_specs()
s$iffolk_selection        <- TRUE
s$iffolk_r_min            <- 0.125
s$iffolk_transfer         <- 3.0
s$parliament_suppression  <- TRUE
s$parliament_cost         <- 0.5
s$cooperative_breeding    <- TRUE
s$helper_tendency_init_mean <- 0.2
s$max_ticks               <- 400L

env  <- run_alife(s)
data <- get_run_data(env)

plot(data$ticks$t, data$ticks$mean_helper_tendency, type = "l",
     xlab = "Tick", ylab = "Mean helper tendency",
     main = "Helper tendency evolves under IFfolk + parliament suppression")
```

![Expected output: mean helper tendency rises over time as cooperative
genotypes increase in frequency. Parliament suppression accelerates
convergence.](figures/showcase_20_cooperative_breeding.png)

Expected output: mean helper tendency rises over time as cooperative
genotypes increase in frequency. Parliament suppression accelerates
convergence.

**What we found.** Cooperative breeding with helping behaviour (helper
tendency, public goods multiplier) is documented under the Cooperation /
public goods scenario above, which runs an overlapping experiment with
the same module. The cooperation experiment (seed 42, 5 replicates)
found that `cooperation_evolution = TRUE` with
`cooperation_multiplier = 2.5` tripled population carrying capacity
(mean 322 vs 106) while cooperation level declined slightly from 0.504
to 0.492 — the tragedy of the commons signature predicted by
evolutionary theory (Hardin 1968). The cooperative breeding scenario
extends this by adding explicit helper roles (`helper_tendency`); run
the code above and monitor `n_helpers` and `mean_helper_tendency` to
observe whether helpers evolve and whether their presence reduces
per-capita starvation mortality relative to the cooperation-only
baseline.

### Discovery experiments

The baseline results confirm that Hamilton’s rule operates: altruistic
acts accumulate and population size is sustained at higher density than
baseline. To go beyond:

1.  **Epidemic corridors** Add `disease = TRUE`. Kin altruism requires
    proximity; does proximity-clustering among relatives accelerate
    pathogen spread? Compare epidemic peak `n_infected` between kin and
    no-kin conditions. Does `kin_altruism_r_min` modulate epidemic
    severity — do populations with stricter relatedness thresholds
    (fewer but closer relatives) show lower or higher peak infection?

    *Tried it.* With `disease = TRUE`, `transmission_prob = 0.25`,
    `disease_seed_prob = 0.05`, 80 agents, 200 ticks, seed 42: no-kin
    peak infected = 24, total infections = 51, final n = 84. With kin
    selection: peak = 28, total = 69, final n = 108. Kin altruism
    created epidemic corridors (17% higher peak, 35% more total
    infections), confirming that proximity-based altruism concentrates
    susceptible neighbours. Crucially, the much higher final population
    under kin selection (108 vs 84) means the population survived the
    larger epidemic — kin benefits outweigh the epidemiological cost at
    these parameters.

2.  **Relatedness threshold sweep** Vary `kin_altruism_r_min` from 0.0
    to 0.5 across six values in
    [`batch_alife()`](../reference/batch_alife.md). Hamilton’s rule
    predicts a threshold (r × benefit \> cost) below which altruism is
    not favoured. Is there a sharp transition in `n_altruistic_acts`, or
    a smooth decay? Plot final altruism rate against
    `kin_altruism_r_min`.

    *Tried it.* Five thresholds tested (80 agents, 200 ticks, seed 42):
    altruistic acts peaked at r_min = 0.125 (1682 acts), not at r_min =
    0 (1558 acts). This non-monotone result suggests that extremely
    loose thresholds waste energy on unrelated agents, reducing the
    donor’s capacity for later altruism. Population size decreased
    monotonically with threshold (n = 153 at r_min = 0 vs n = 133 at
    r_min = 0.5), confirming that broader altruism sustains larger
    populations even when total act count is similar.

3.  **Kin clusters + niche construction** Add
    `niche_construction = TRUE`. Do relatives cluster in sheltered
    cells, creating kin-structured microhabitats? Measure the spatial
    correlation between `shelter_density` and the local mean pedigree
    relatedness of occupants at the final tick. Does niche construction
    accelerate or slow kin group formation?

    *Tried it.* Adding `niche_construction = TRUE` to kin selection (80
    agents, 200 ticks, seed 42) reduced altruistic acts from 1709 to
    1341 (21% reduction), while generating 2641 shelter events. The two
    modules compete: agents that spend energy building shelters have
    less surplus for kin donations. Sheltering appears to partially
    substitute for kin altruism as an energy-buffer strategy — once
    shelters are built, agents need fewer emergency transfers from
    relatives.

------------------------------------------------------------------------
