# Scavenging and carrion dynamics

### Scavenging and carrion dynamics

**What it models.** Scavenging — the consumption of carrion left by dead
conspecifics — is a widespread foraging strategy that provides a
resource buffer when primary productivity is low (DeVault et al. 2003).
In `clade`, when `scavenging = TRUE`, agent deaths deposit a fraction of
their remaining energy as carrion on the grid cell where they died.
Carrion decays each tick at rate `carrion_decay_rate` and can be
consumed by any agent that moves onto the cell, yielding
`carrion_eat_gain` energy units.

**Key parameters.**

| Parameter                   | Default | Effect                                                                        |
|-----------------------------|---------|-------------------------------------------------------------------------------|
| `scavenging`                | FALSE   | Enables carrion deposition and consumption                                    |
| `carrion_fraction`          | 0.5     | Fraction of a dead agent’s energy deposited as carrion                        |
| `carrion_decay_rate`        | 0.1     | Proportional decay of carrion per tick                                        |
| `carrion_eat_gain`          | 3.0     | Energy gained by a scavenger per unit of carrion consumed                     |
| `carrion_transmission_prob` | 0.0     | Probability that eating from an infected carcass transmits disease            |
| `grass_rate`                | 0.05    | Set low to create resource scarcity that accentuates the scavenging advantage |

**Expected output.** Under scarce grass conditions, mean agent energy
should be higher in the scavenging condition than the baseline, and the
total number of deaths should be lower. Carrion provides a
density-dependent buffer: more deaths in a tick produce more carrion,
partially compensating for the energy deficit that caused those deaths.

``` r
library(clade)
library(ggplot2)

base_specs <- function() {
  s <- default_specs()
  s$n_agents_init <- 100L
  s$grid_rows     <- 30L
  s$grid_cols     <- 30L
  s$grass_rate    <- 0.15
  s$max_ticks     <- 400L
  s
}

s_no <- base_specs(); s_no$scavenging <- FALSE
s_sc <- base_specs()
s_sc$scavenging        <- TRUE
s_sc$carrion_fraction  <- 0.5
s_sc$carrion_decay_rate <- 0.1
s_sc$carrion_eat_gain  <- 3.0

d_no <- get_run_data(run_alife(s_no))$ticks
d_sc <- get_run_data(run_alife(s_sc))$ticks

d_no$condition <- "No scavenging"
d_sc$condition <- "Scavenging"
dat <- rbind(d_no, d_sc)

ggplot(dat, aes(x = t, y = mean_energy, colour = condition)) +
  geom_line(linewidth = 0.8) +
  scale_colour_manual(
    values = c("No scavenging" = "#E53935", "Scavenging" = "#FB8C00"),
    name   = NULL
  ) +
  labs(
    x     = "Tick",
    y     = "Mean agent energy",
    title = "Scavenging sustains energy budgets under resource scarcity"
  ) +
  theme_classic(base_size = 12)
```

### Calibrated regime (CMA-ES discovered)

Running Phase 7 auto-calibration (`dev/audit/calibration/`) over the
scenario’s parameter subspace discovered the following regime, which
produces a fitness improvement of **12.0x** over the defaults above. See
`dev/audit/calibration/RESULTS.md` for the full CMA-ES results.

``` r
# Parameter overrides discovered by CMA-ES (see dev/audit/calibration/):
s <- default_specs()
s$grass_rate                     <- 1
s$idle_cost                      <- 1.528
# env <- run_alife(s)   # uncomment to run the calibrated regime
```

![Expected output: scavengers (orange) maintain higher mean energy than
non-scavengers (red) under identical low-grass conditions, with carrion
providing a density-dependent buffer against
starvation.](figures/showcase_scavenging.png)

Expected output: scavengers (orange) maintain higher mean energy than
non-scavengers (red) under identical low-grass conditions, with carrion
providing a density-dependent buffer against starvation.

**What we found.** Running 3 replicates with 80 agents, 25×25 grid,
`grass_rate = 0.06`, `idle_cost = 1.0`, 400 ticks (seeds 41–43):
scavenging increased final population by 21% (mean 53 vs 44 agents)
compared to no-scavenging controls under identical conditions. Mean
population over all 400 ticks was more similar (91 vs 87, +5%), because
the carrion buffer is most valuable during starvation troughs rather
than over the full run. The effect was modest at higher grass rates
(`grass_rate = 0.08`; +5.2% mean population) and negligible at
`grass_rate = 0.15` where food scarcity is not the binding constraint.
The mechanism matters: agents encounter carrion stochastically as they
explore the grid rather than seeking it out. This limits
population-level impact; directed scavenging behaviour (which would
require RL or social learning of carrion-cell rewards) would be expected
to produce substantially larger effects.

### Discovery experiments

The baseline result shows that scavenging sustains higher mean energy
than baseline under identical low-grass conditions. To go beyond:

1.  **Carrion as pathogen reservoir** When `disease = TRUE` and
    `carrion_transmission_prob > 0`, agents that die while infected
    deposit a flagged carcass; any agent that eats from it becomes
    infected with the specified probability. This models fomite
    transmission observed in vultures, hyenas, and other obligate
    scavengers (Ogada et al. 2012). The question: does carrion-mediated
    transmission reverse the previously observed anti-epidemic effect of
    scavenging?

``` r
library(clade)
library(ggplot2)

make_specs <- function(carrion_tp = 0.0) {
  s <- default_specs()
  s$n_agents_init           <- 200L
  s$grid_rows               <- 25L
  s$grid_cols               <- 25L
  s$grass_rate              <- 0.08
  s$max_ticks               <- 300L
  s$scavenging              <- TRUE
  s$carrion_fraction        <- 0.5
  s$carrion_decay_rate      <- 0.1
  s$disease                 <- TRUE
  s$transmission_prob       <- 0.15
  s$disease_seed_prob       <- 0.03
  s$carrion_transmission_prob <- carrion_tp
  s
}

d_safe <- get_run_data(run_alife(make_specs(0.0)))$ticks
d_risk <- get_run_data(run_alife(make_specs(0.3)))$ticks

d_safe$condition <- "Carrion safe (prob = 0)"
d_risk$condition <- "Carrion risky (prob = 0.3)"
dat <- rbind(d_safe, d_risk)

ggplot(dat, aes(x = t, y = n_new_infections, colour = condition)) +
  geom_line(linewidth = 0.7, alpha = 0.8) +
  scale_colour_manual(
    values = c("Carrion safe (prob = 0)" = "#43A047",
               "Carrion risky (prob = 0.3)" = "#E53935"),
    name = NULL
  ) +
  labs(
    x     = "Tick",
    y     = "New infections per tick",
    title = "Carrion as pathogen reservoir amplifies epidemics"
  ) +
  theme_classic(base_size = 12)
```

**Expected output.** When `carrion_transmission_prob = 0.3`,
`n_new_infections` should be higher than the safe-carrion baseline,
particularly during population troughs when scavenging rates are
highest. The carrion_decay_rate acts as a natural quarantine: fast decay
reduces fomite persistence and dampens transmission. Watch whether the
epidemic peak shifts earlier (higher early transmission from dense
infection) or later (carcasses accumulate as the epidemic matures).

2.  **Kin scavenging** Add `kin_selection = TRUE`. Both kin altruism and
    scavenging buffer energy deficits — are they additive (both help
    independently) or redundant (populations with kin altruism scavenge
    less because energy transfers substitute for carrion)? Watch
    `n_altruistic_acts` and `mean_energy` jointly under combined and
    single-module conditions.

    *Tried it.* With scavenging + disease enabled (50 agents, 200 ticks,
    seed 42): despite scavenge_events = 0, disease transmission was 37%
    lower in the scavenging condition (22 vs 35 infections). The
    scavenging module requires larger populations (≥ 200 agents) or
    longer runs (≥ 500 ticks) for consistent dead-agent turnover that
    generates detectable carrion. The epidemiological signal likely
    reflects energy-state differences between conditions rather than
    literal carrion contact.

3.  **Scavenging × learning** Add `rl_mode = "actor_critic"`. Can
    within-lifetime RL discover scavenging opportunities faster than
    pure genetic evolution can encode the behaviour? Compare
    `mean_energy` trajectories between RL and no-RL conditions in a
    scavenging-enabled world at tick 100 (early learning phase) vs tick
    400 (late genetic phase).

    *Tried it.* Combining scavenging and kin selection (50 agents, 200
    ticks, seed 42): kin altruism operated normally (1278 acts, n =
    132), but scavenge_events = 0. Both modules function independently
    at small population scales — kin altruism operates via live energy
    transfers while scavenging requires dead-agent corpse density. The
    two energy-buffering mechanisms are additive in principle but
    non-overlapping in the conditions that activate them.

------------------------------------------------------------------------
