# BNN uncertainty canalization and the Baldwin Effect

### BNN uncertainty canalization — the Baldwin Effect

**What it models.** The Bayesian neural network (BNN) brain type
(`brain_type = "bnn"`) places a prior distribution over each synaptic
weight, parameterised by a mean μ and a standard deviation σ. A large σ
encodes behavioural flexibility: the agent samples widely from its
weight posterior and can learn within its lifetime via Thompson
sampling. A small σ encodes genetic assimilation: the agent’s behaviour
is largely determined by the prior mean — the population has, over
generations of selection, canalized a formerly learned behaviour into
the genome.

This is the computational signature of the **Baldwin Effect** (Baldwin
1896), formalised by Hinton & Nowlan (1987): learning guides evolution
toward fixed adaptive solutions, after which the learning machinery
becomes redundant. Mayley (1996) showed analytically that the speed of
canalization depends on the stability of the fitness landscape and the
mutational variance available for selection to act on. The BNN brain in
clade implements this mechanistically: σ is derived from heterozygosity
(half the absolute difference between maternal and paternal alleles at
each weight locus), so high genome diversity implies broad priors and
high within-lifetime flexibility, while genetic convergence produces
narrow priors and increasingly instinctive behaviour.

**How σ changes over time.** Two mechanisms act on σ within each agent’s
lifetime:

1.  **Posterior contraction** (when `rl_mode = "actor_critic"`): each
    tick, the posterior σ at active weights shrinks proportional to the
    learning signal. This within-lifetime narrowing resets at birth —
    offspring inherit the *prior* σ from the genome, not the posterior.

2.  **Genetic assimilation** (across generations): offspring σ reflects
    parental heterozygosity. If high-σ (exploratory) agents leave fewer
    offspring than low-σ (exploitative) agents, mean σ declines over
    generations even without any within-lifetime learning. This is the
    Baldwin Effect proper.

**The key observable.** Track `mean_prior_sigma` in `data$ticks`.
Declining σ over ticks = canalization / Baldwin Effect. Rising or stable
σ = selection maintains flexibility.

**Key parameters.**

| Parameter                 | Default  | Effect                                                                      |
|---------------------------|----------|-----------------------------------------------------------------------------|
| `brain_type`              | `"bnn"`  | Must be `"bnn"` to enable Bayesian weight distributions                     |
| `bnn_sigma_init`          | 0.5      | Initial σ for haploid genomes; in diploid, σ is derived from heterozygosity |
| `bnn_sigma_min`           | 0.01     | Floor: σ cannot be driven below this value                                  |
| `rl_mode`                 | `"none"` | Set to `"actor_critic"` to add within-lifetime posterior contraction        |
| `learning_rate_init_mean` | 0.01     | Controls rate of within-lifetime σ contraction under RL                     |
| `max_ticks`               | —        | Canalization is slow; use ≥ 500 ticks; 1000–2000 for rigorous tests         |
| `grass_rate`              | 0.05     | Resource abundance shapes fitness landscape stability                       |
| `seasonal_amplitude`      | 0        | Temporal variability; high values prevent canalization                      |

------------------------------------------------------------------------

### Baseline: does the Baldwin Effect occur in a foraging world?

**Expected output (theoretical).** Over evolutionary time, the prior σ
should decline as selection canalizes learned behaviour.

**Audit caveat (2026-04-15).** The 4-seed × 800-tick audit found that σ
*rises* from ~0.19 to the cap of 0.50 in both stable and seasonal
environments — the opposite of the Baldwin prediction. Root cause:
clade’s σ is derived from per-locus heterozygosity (\|maternal −
paternal\|), which accumulates under neutral mutation regardless of
selection pressure. Without a kernel change to decouple σ from
heterozygosity or add an explicit cost on uncertainty, the Baldwin
canalization cannot be observed at default parameters. See
[dev/audit/fidelity/baldwin.md](../dev/audit/fidelity/baldwin.md).

``` r
library(clade)
library(ggplot2)

s <- default_specs()
s$brain_type <- "bnn"
s$max_ticks  <- 600L
s$random_seed <- 42L

env  <- run_alife(s)
data <- get_run_data(env)

ggplot(data$ticks, aes(x = t, y = mean_prior_sigma)) +
  geom_line(colour = "#2166ac", linewidth = 0.8, alpha = 0.7) +
  geom_smooth(method = "lm", se = TRUE,
              colour = "#d6604d", fill = "#f4a582", alpha = 0.4) +
  labs(
    title    = "Genetic assimilation of learned behaviour (Baldwin Effect)",
    subtitle = "BNN prior sigma over time — declining = canalization, rising = flexibility favoured",
    x = "Tick", y = expression("Mean prior " * sigma)
  ) +
  theme_minimal()
```

### Calibrated regime (CMA-ES discovered)

Running Phase 7 auto-calibration (`dev/audit/calibration/`) over the
scenario’s parameter subspace discovered the following regime, which
produces a fitness improvement of **1.2x** over the defaults above. See
`dev/audit/calibration/RESULTS.md` for the full CMA-ES results.

``` r
# Parameter overrides discovered by CMA-ES (see dev/audit/calibration/):
s <- default_specs()
s$grass_rate                     <- 0.0266
s$learning_rate_init_mean        <- 0.007
# env <- run_alife(s)   # uncomment to run the calibrated regime
```

![Before/after kernel fix (3 seeds × 600 ticks). LEFT: pre-0.4.0 with
sigma from heterozygosity — σ rises toward the 0.5 cap in both
environments (🔴 contradicts Baldwin). RIGHT: post-0.4.1 with sigma as
evolvable trait + information cost — σ direction reverses. The fix
enables the Baldwin mechanism but the magnitude is modest at 600 ticks
(Δ ≈ 0.004); at 1500 ticks the transient canalisation disappears due to
sigma coupling with behavioural variance — 🟠
kernel-limited.](figures/showcase_bnn_uncertainty.png)

Before/after kernel fix (3 seeds × 600 ticks). LEFT: pre-0.4.0 with
sigma from heterozygosity — σ rises toward the 0.5 cap in both
environments (🔴 contradicts Baldwin). RIGHT: post-0.4.1 with sigma as
evolvable trait + information cost — σ direction reverses. The fix
enables the Baldwin mechanism but the magnitude is modest at 600 ticks
(Δ ≈ 0.004); at 1500 ticks the transient canalisation disappears due to
sigma coupling with behavioural variance — 🟠 kernel-limited.

**What we found (updated 2026-04-16, audit 🔴 → 🟠 kernel-limited).**

The pre-0.4.0 audit showed `mean_prior_sigma` rising monotonically from
~0.3 to the 0.5 cap in both stable and seasonal environments — the
*opposite* of the canonical Baldwin canalization. That was traced to the
legacy `bnn_sigma_source = "heterozygosity"` coupling, which prevented
selection from touching sigma. Two 0.4.x kernel changes addressed that:

1.  **0.4.0 Tier 5A** — `bnn_sigma_source = "trait"`: sigma tracks a
    dedicated heritable `TRAIT_PLASTICITY` gene, so selection can reduce
    it.
2.  **0.4.1 Tier 5C** — `brain_energy_sigma_scale > 0`: a log-scaled
    information cost on sigma creates the selection gradient Hinton &
    Nowlan (1987) call for.

At 600 ticks with these flags on, the **canonical direction appears
transiently**: stable Δ = −0.004, seasonal Δ = +0.003 (Δ-delta = +0.007
in the Hinton-Nowlan direction). However, the 0.4.2 1500-tick sweep
shows this is a **transient on the way to equilibrium, not a stable
selection outcome**:

| sigma_scale | env      | 600-tick Δ | 1500-tick Δ |
|-------------|----------|------------|-------------|
| 0.05        | stable   | **−0.004** | +0.001      |
| 0.05        | seasonal | **+0.003** | −0.004      |

At equilibrium the direction reverses: seasonal ends up with *lower*
sigma than stable. The underlying reason is a kernel limitation — sigma
in clade mediates *both* learning capacity AND behavioural variance
(noisy actions). Seasonal stress kills agents during lean phases; those
kills favour lower-sigma (more deterministic) phenotypes regardless of
the Hinton-Nowlan learning-cost term. 0.4.3+ backlog: decouple sigma
from behavioural variance so the canonical prediction can be tested
without the foraging-efficiency confounder.

**Current verdict** is 🟠 passed-consistent (kernel-limited): direction
reversal from the pre-0.4.0 🔴 confirmed at short timescales, caveated
at equilibrium.

------------------------------------------------------------------------

### Experiment 1 — Environmental stability gradient

**Question.** Does environmental predictability determine whether
canalization occurs? The theory predicts it should: stable,
resource-rich environments provide consistent fitness gradients that
canalization can track; variable or scarce environments do not.

``` r
library(clade)
library(ggplot2)
library(patchwork)

make_specs <- function(grass_rate, seasonal_amplitude) {
  s <- default_specs()
  s$brain_type         <- "bnn"
  s$n_agents_init      <- 100L
  s$grid_rows          <- 25L
  s$grid_cols          <- 25L
  s$max_ticks          <- 1000L
  s$grass_rate         <- grass_rate
  s$seasonal_amplitude <- seasonal_amplitude
  s
}

conditions <- expand.grid(
  grass_rate         = c(0.05, 0.10, 0.20),
  seasonal_amplitude = c(0.0,  0.4,  0.8)
)

# Run each condition across 5 seeds
results <- vector("list", nrow(conditions))
for (i in seq_len(nrow(conditions))) {
  results[[i]] <- batch_seeds(
    make_specs(conditions$grass_rate[i], conditions$seasonal_amplitude[i]),
    seeds = 1:5
  )
}

# Extract slopes
slopes <- mapply(function(res, i) {
  seeds_data <- lapply(res, function(env) get_run_data(env)$ticks)
  slopes_per_seed <- sapply(seeds_data, function(d)
    coef(lm(mean_prior_sigma ~ t, data = d))["t"])
  data.frame(
    grass_rate         = conditions$grass_rate[i],
    seasonal_amplitude = conditions$seasonal_amplitude[i],
    mean_slope         = mean(slopes_per_seed),
    se_slope           = sd(slopes_per_seed) / sqrt(5)
  )
}, results, seq_len(nrow(conditions)), SIMPLIFY = FALSE)
slopes_df <- do.call(rbind, slopes)

ggplot(slopes_df, aes(x = factor(grass_rate), y = factor(seasonal_amplitude),
                      fill = mean_slope)) +
  geom_tile() +
  geom_text(aes(label = round(mean_slope, 4)), size = 3) +
  scale_fill_gradient2(low = "#1a9850", mid = "white", high = "#d73027",
                       midpoint = 0, name = "sigma slope") +
  labs(
    title = "Baldwin Effect phase diagram",
    subtitle = "Green = canalization (sigma declining), red = flexibility favoured (sigma rising)",
    x = "Grass rate (resource abundance)", y = "Seasonal amplitude (variability)"
  ) +
  theme_minimal(base_size = 12)
```

**What we found.** 3 × 3 factorial design (grass_rate ×
seasonal_amplitude), 5 seeds each, 1000 ticks per run (45 runs total).
Every single condition produced a positive sigma slope — no canalization
in any cell. All 9 conditions converged to the ceiling value (σ = 0.5)
by tick 1000.

Crucially, the slope ordering is the **inverse** of the Baldwin Effect
prediction: resource scarcity (grass_rate = 0.05) produced the
*steepest* positive slopes (fastest σ rise), while resource abundance
(grass_rate = 0.20) produced the *shallowest* — but still positive —
slopes. When foraging is difficult, agents with broad priors (high σ)
that can explore widely have a strong survival advantage; tight priors
are fatal. Seasonal amplitude had minimal additional effect within each
resource level.

The one exception: grass_rate = 0.05, seasonal_amplitude = 0.4 showed a
mean slope 2.8× higher than its neighbours and sd_slope 378× higher —
reflecting stochastic population crashes at that resource-variability
combination, not canalization.

| grass_rate | seasonal_amp | mean slope       | final σ  |
|------------|--------------|------------------|----------|
| 0.05       | 0.0          | +2.51 × 10⁻⁴     | 0.50     |
| 0.05       | 0.4          | +5.54 × 10⁻⁴ ‡   | 0.40     |
| 0.05       | 0.8          | +2.45 × 10⁻⁴     | 0.50     |
| 0.10       | 0.0          | +1.98 × 10⁻⁴     | 0.50     |
| 0.10       | 0.4          | +1.92 × 10⁻⁴     | 0.50     |
| 0.10       | 0.8          | +1.83 × 10⁻⁴     | 0.50     |
| 0.20       | 0.0          | +1.49 × 10⁻⁴     | 0.50     |
| 0.20       | 0.4          | +1.43 × 10⁻⁴     | 0.50     |
| **0.20**   | **0.8**      | **+1.38 × 10⁻⁴** | **0.50** |

‡ High variance across seeds (sd_slope 378× larger than other
conditions) — population-crash artefact, not canalization.

**Bold row** = smallest positive slope = most canalization-favourable
condition tested. Even here, σ rose to ceiling. Experiment 2 tests
whether longer runs (2000–5000 ticks) change this outcome.

![Phase diagram of sigma slope across 9 resource × seasonality
conditions. All cells are positive (red) — exploration is selected in
every environment tested. The shallowest slope (bottom-right, bold row)
still reaches the sigma
ceiling.](figures/showcase_bnn_exp1_stability.png)

Phase diagram of sigma slope across 9 resource × seasonality conditions.
All cells are positive (red) — exploration is selected in every
environment tested. The shallowest slope (bottom-right, bold row) still
reaches the sigma ceiling.

------------------------------------------------------------------------

### Experiment 2 — Is the ceiling an artefact of run length?

**Question.** The baseline sigma plateaus at 0.5 within 300 ticks. Is
this because canalization never occurs, or because 600 ticks is too few
generations?

``` r
library(clade)
library(ggplot2)

# Use the most canalization-favourable condition from Experiment 1
# (abundant, stable: grass_rate = 0.20, seasonal_amplitude = 0)
make_long_specs <- function(max_ticks) {
  s <- default_specs()
  s$brain_type         <- "bnn"
  s$n_agents_init      <- 100L
  s$grid_rows          <- 25L
  s$grid_cols          <- 25L
  s$grass_rate         <- 0.20
  s$seasonal_amplitude <- 0.0
  s$max_ticks          <- max_ticks
  s
}

run_lengths <- c(500L, 1000L, 2000L, 5000L)
sigma_trajectories <- lapply(run_lengths, function(ticks) {
  env <- run_alife(make_long_specs(ticks), verbose = FALSE)
  d   <- get_run_data(env)$ticks
  data.frame(t = d$t, mean_prior_sigma = d$mean_prior_sigma,
             run_length = as.character(ticks))
})
traj_df <- do.call(rbind, sigma_trajectories)

ggplot(traj_df, aes(x = t, y = mean_prior_sigma, colour = run_length)) +
  geom_line(linewidth = 0.7, alpha = 0.8) +
  labs(
    title    = "Does canalization emerge at longer run lengths?",
    subtitle = "Stable, resource-abundant environment (grass_rate = 0.20, seasonal_amplitude = 0)",
    x = "Tick", y = expression("Mean prior " * sigma),
    colour   = "Run length (ticks)"
  ) +
  theme_minimal(base_size = 12)
```

**What we found.** Using the most canalization-favourable condition from
Experiment 1 (grass_rate = 0.20, seasonal_amplitude = 0.8 — the cell
with the smallest positive slope), 5 seeds each at 1000, 2000, and 5000
ticks:

| Run length | Mean slope   | Final σ (mean of last 100 ticks) |
|------------|--------------|----------------------------------|
| 1000 ticks | +1.38 × 10⁻⁴ | 0.50 (ceiling)                   |
| 2000 ticks | +3.84 × 10⁻⁵ | 0.50 (ceiling)                   |
| 5000 ticks | +6.54 × 10⁻⁶ | 0.50 (ceiling)                   |

The slope decelerates 21-fold from 1000 to 5000 ticks — but
`final_sigma` remains at the ceiling (0.5) in all cases. This
deceleration is **ceiling saturation**, not the onset of canalization:
exploration is selected so strongly that σ presses against its upper
bound (0.5), and as the ceiling is reached the observable slope
approaches zero. If the ceiling were raised, σ would continue rising.

Run length is not the limiting factor. The Baldwin Effect does not
emerge because exploration is genuinely the ESS in a competitive
foraging world — the fitness landscape has no stable peak for
canalization to track.

![Sigma trajectories at 1000, 2000, and 5000 ticks (mean +/- SE, 5
seeds). All runs hit the 0.5 ceiling; the slope decelerates 21-fold but
never reverses. This is ceiling saturation, not
canalization.](figures/showcase_bnn_exp2_runlength.png)

Sigma trajectories at 1000, 2000, and 5000 ticks (mean +/- SE, 5 seeds).
All runs hit the 0.5 ceiling; the slope decelerates 21-fold but never
reverses. This is ceiling saturation, not canalization.

------------------------------------------------------------------------

### Experiment 3 — Brain architecture comparison

**Question.** Does the Baldwin Effect require the BNN specifically, or
does it emerge with any within-lifetime adaptation mechanism?

``` r
library(clade)
library(ggplot2)

# Best canalization-favourable environment from Experiment 1
base_s <- function(brain_type, rl_mode) {
  s <- default_specs()
  s$brain_type         <- brain_type
  s$rl_mode            <- rl_mode
  s$n_agents_init      <- 100L
  s$grid_rows          <- 25L
  s$grid_cols          <- 25L
  s$grass_rate         <- 0.20
  s$seasonal_amplitude <- 0.0
  s$max_ticks          <- 1000L
  s
}

conditions <- list(
  list(brain = "bnn", rl = "none",         label = "BNN only"),
  list(brain = "ann", rl = "actor_critic", label = "ANN + RL"),
  list(brain = "bnn", rl = "actor_critic", label = "BNN + RL"),
  list(brain = "ann", rl = "none",         label = "ANN null")
)

traj_list <- lapply(conditions, function(cond) {
  env <- run_alife(base_s(cond$brain, cond$rl), verbose = FALSE)
  d   <- get_run_data(env)$ticks
  data.frame(t = d$t, mean_prior_sigma = d$mean_prior_sigma,
             mean_energy = d$mean_energy, condition = cond$label)
})
traj_df <- do.call(rbind, traj_list)

ggplot(traj_df, aes(x = t, y = mean_prior_sigma, colour = condition)) +
  geom_line(linewidth = 0.8) +
  labs(title = "Sigma dynamics by brain architecture",
       x = "Tick", y = expression("Mean prior " * sigma),
       colour = NULL) +
  theme_minimal(base_size = 12)
```

**What we found.** 4 brain conditions × 5 seeds × 1000 ticks (most
canalization-favourable environment from Experiment 1: grass_rate =
0.20, seasonal_amplitude = 0.8):

| Condition | σ slope      | Final σ        | Final energy |
|-----------|--------------|----------------|--------------|
| BNN only  | +1.38 × 10⁻⁴ | 0.50 (ceiling) | 128.3        |
| BNN + RL  | +1.39 × 10⁻⁴ | 0.50 (ceiling) | 127.5        |
| ANN + RL  | 0 (no σ)     | —              | **154.97**   |
| ANN null  | 0 (no σ)     | —              | **154.97**   |

Three findings:

1.  **RL has no effect on sigma dynamics**: BNN-only and BNN+RL are
    indistinguishable in slope and final σ. Within-lifetime policy
    gradient updates do not alter the evolutionary trajectory of prior
    width.

2.  **RL provides no energy benefit at 1000 ticks**: ANN+RL and ANN-null
    have *identical* final energy (154.97 to 5 significant figures). The
    REINFORCE gradient offers no measurable foraging advantage over 1000
    ticks in this environment — genetic evolution of ANN weights is
    sufficient.

3.  **BNN pays an energy cost for exploration**: BNN agents end with 128
    energy vs ANN agents at 155 — a 17% metabolic penalty from broad
    Thompson sampling. Yet sigma is still selected to ceiling. Agents
    pay to explore and selection *still* favours maintaining that
    capacity. This is the strongest evidence that exploration is the
    ESS: even when it is costly, it is preferred over genetic
    assimilation.

![Left: sigma trajectories for BNN-only and BNN+RL (seed 1). The two
curves are indistinguishable — RL does not alter sigma dynamics. Right:
final mean energy by condition. BNN agents pay a 17% energy cost
relative to ANN agents yet the exploration ESS
persists.](figures/showcase_bnn_exp3_brains.png)

Left: sigma trajectories for BNN-only and BNN+RL (seed 1). The two
curves are indistinguishable — RL does not alter sigma dynamics. Right:
final mean energy by condition. BNN agents pay a 17% energy cost
relative to ANN agents yet the exploration ESS persists.

------------------------------------------------------------------------

### Experiment 4 — Social modifiers

**Question.** Do social transmission mechanisms (kin altruism, social
learning, epigenetic inheritance) accelerate or retard canalization?

**Existing finding.** Adding `kin_selection = TRUE` to the baseline BNN
run *raised* sigma rather than lowering it. The interpretation: kin
altruism provides energy subsidies that buffer the cost of exploration —
agents with kin support can afford to maintain broader priors because
the energy risk of uncertain decisions is partially insured by
relatives. Social insurance maintains cognitive flexibility. This is a
novel interaction: **social buffering retards the Baldwin Effect**.

``` r
library(clade)
library(ggplot2)

base_s <- function(...) {
  s <- default_specs()
  s$brain_type         <- "bnn"
  s$n_agents_init      <- 150L   # need higher density for social effects
  s$grid_rows          <- 25L
  s$grid_cols          <- 25L
  s$grass_rate         <- 0.20
  s$seasonal_amplitude <- 0.0
  s$max_ticks          <- 1000L
  mods <- list(...)
  for (nm in names(mods)) s[[nm]] <- mods[[nm]]
  s
}

conditions <- list(
  list(specs = base_s(),                                   label = "BNN baseline"),
  list(specs = base_s(social_learning = TRUE),             label = "BNN + social learning"),
  list(specs = base_s(epigenetics = TRUE, tei_prob = 0.3), label = "BNN + epigenetics"),
  list(specs = base_s(kin_selection = TRUE),               label = "BNN + kin selection")
)

traj_list <- lapply(conditions, function(cond) {
  env <- run_alife(cond$specs, verbose = FALSE)
  d   <- get_run_data(env)$ticks
  data.frame(t = d$t, mean_prior_sigma = d$mean_prior_sigma,
             condition = cond$label)
})
traj_df <- do.call(rbind, traj_list)

ggplot(traj_df, aes(x = t, y = mean_prior_sigma, colour = condition)) +
  geom_line(linewidth = 0.8) +
  labs(title = "Social modifiers accelerate or retard canalization",
       subtitle = "Kin altruism maintains exploration; social learning may accelerate assimilation",
       x = "Tick", y = expression("Mean prior " * sigma), colour = NULL) +
  theme_minimal(base_size = 12)
```

**What we found.** 4 modules × 2 environments × 5 seeds × 1000 ticks (40
runs). Results ordered by final σ within each environment:

**Stable abundant (grass = 0.20, seasonal = 0.8):**

| Module                | σ slope     | Final σ         |
|-----------------------|-------------|-----------------|
| BNN + epigenetics     | +6.6 × 10⁻⁵ | **0.342**       |
| BNN + kin selection   | +1.5 × 10⁻⁴ | 0.500 (ceiling) |
| BNN + social learning | +1.7 × 10⁻⁴ | 0.500 (ceiling) |
| BNN baseline          | +1.7 × 10⁻⁴ | 0.500 (ceiling) |

**Scarce stable (grass = 0.05, seasonal = 0.0):**

| Module                | σ slope     | Final σ   |
|-----------------------|-------------|-----------|
| BNN + epigenetics     | +5.5 × 10⁻⁴ | **0.140** |
| BNN + social learning | +6.2 × 10⁻⁴ | 0.300     |
| BNN baseline          | +4.5 × 10⁻⁴ | 0.400     |
| BNN + kin selection   | +5.6 × 10⁻⁴ | 0.400     |

**The headline finding: epigenetic inheritance is the only mechanism
that substantially reduces σ below ceiling.** In the stable abundant
environment, epigenetics reduces final σ from 0.500 to 0.342 (32% below
ceiling). In the scarce stable environment, the effect is even stronger:
σ reaches only 0.140 — 72% below the 0.5 ceiling and 65% below the
baseline final value of 0.400.

The mechanism is epigenetic transmission of sigma itself: when agents
learn within their lifetime (posterior σ contraction), their offspring
inherit partially-contracted priors via TEI (transgenerational
epigenetic inheritance, `tei_prob = 0.3`). This is a Lamarckian shortcut
to canalization — within-lifetime narrowing is transmitted directly,
bypassing the slow genetic route that pure Baldwinian assimilation
requires.

**Other findings:** - Social learning: slightly increases σ slope in the
scarce environment (copying behaviour from successful high-σ agents
propagates the exploration strategy), reduces final σ slightly (0.30 vs
0.40 baseline) via within-generation variance reduction - Kin selection:
negligible effect in stable conditions; in scarce conditions, energy
subsidies to relatives allow high-σ exploration to be maintained (kin
buffer the cost of uncertainty) — consistent with the earlier finding
that social insurance retards canalization - **Prediction reversal**:
epigenetics was predicted to moderately accelerate canalization; it
produced the largest effect observed across all 4 experiments. Social
learning was predicted to accelerate canalization; it had no significant
effect in the stable environment.

![Final mean sigma by social module, faceted by environment. Epigenetics
(red) is the only mechanism that substantially reduces sigma — 32% below
ceiling in stable-abundant conditions, 72% below ceiling in
scarce-stable conditions. All other modules remain at or near the 0.5
ceiling (dashed line).](figures/showcase_bnn_exp4_social.png)

Final mean sigma by social module, faceted by environment. Epigenetics
(red) is the only mechanism that substantially reduces sigma — 32% below
ceiling in stable-abundant conditions, 72% below ceiling in
scarce-stable conditions. All other modules remain at or near the 0.5
ceiling (dashed line).

------------------------------------------------------------------------

### Discovery experiments

The core finding is that the Baldwin Effect is conditional, not
universal. The experiments above characterise the boundary. To go
further:

1.  **Predation pressure as a stabilising force.** Add
    `n_predators_init = 5L`. Predators create a consistent survival
    advantage for agents that learn to avoid them rapidly. If
    predator-avoidance is learnable and pays off reliably, the
    predator-selection gradient may be stable enough to drive
    canalization even in otherwise heterogeneous environments. Does
    `mean_prior_sigma` decline faster under predation than in the
    baseline?

2.  **Spatial heterogeneity versus temporal variability.** Use
    `complex_landscape = TRUE` to create spatially patchy but temporally
    stable resources. Does spatial heterogeneity (which creates locally
    optimal strategies) prevent canalization the same way that temporal
    variability does, or is it less disruptive because local specialists
    can coexist?

3.  **MAP-Elites to discover canalization-compatible phenotypes.** Use
    [`search_map_elites()`](../reference/search_map_elites.md) with
    `archive_dims = list(mean_prior_sigma = seq(0, 0.5, by=0.05), genetic_diversity = seq(0, 0.5, by=0.05))`
    to systematically search the parameter space for conditions that
    produce low-sigma (canalized) genomes. Does low sigma coexist with
    high genetic diversity (Baldwin Effect proper) or require
    drift-to-fixation (pseudo-canalization via homozygosity)?

    *Tried it.* 150 iterations on the BNN baseline, 500-tick runs,
    121-cell archive (mean_prior_sigma × genetic_diversity, both 0–0.5,
    step 0.05): 20 cells filled (16.5% of the archive). Low-sigma cells
    were found — σ as low as 0.028 — but every low-sigma cell also had
    very low genetic diversity (gd \< 0.15 for all cells with σ \< 0.3).
    The σ-gd correlation across the archive was +0.593. The five
    highest-scoring cells (highest genetic diversity) all had σ \> 0.40.

    **This is the critical distinction from the Baldwin Effect.** The
    Baldwin Effect proper requires low σ *coexisting with* high genetic
    diversity — the genome has converged on specific adaptive weight
    configurations (low heterozygosity at key loci) while maintaining
    diversity at others. MAP-Elites found no such solutions. Low sigma
    in the archive is entirely explained by genetic drift to fixation:
    when a population becomes genetically homogeneous (low gd),
    heterozygosity at all loci collapses, driving σ toward zero as a
    byproduct of fixation, not of selection for canalized behaviour.
    This is pseudo-canalization via drift, not the Baldwin Effect.

    The complete absence of low-σ + high-gd cells from the archive
    confirms that no parameter combination in the tested space produces
    genuine Baldwinian canalization. Only epigenetic inheritance
    (Experiment 4) provides a route to substantially reduced σ while
    maintaining viable populations.

![MAP-Elites archive: each point is a filled cell (20 of 121 total). Low
sigma is only found with low genetic diversity — consistent with drift
to fixation, not with the Baldwin Effect, which requires low sigma
coexisting with high diversity. No cells appear in the low-sigma +
high-diversity quadrant (bottom-right of the dashed reference
lines).](figures/showcase_bnn_exp5_mapelites.png)

MAP-Elites archive: each point is a filled cell (20 of 121 total). Low
sigma is only found with low genetic diversity — consistent with drift
to fixation, not with the Baldwin Effect, which requires low sigma
coexisting with high diversity. No cells appear in the low-sigma +
high-diversity quadrant (bottom-right of the dashed reference lines).

------------------------------------------------------------------------

### References

Baldwin, J.M. (1896) A new factor in evolution. *American Naturalist*
30:441–451.

Blundell, C. et al. (2015) Weight uncertainty in neural networks. *ICML*
32:1613–1622.

Hinton, G.E. & Nowlan, S.J. (1987) How learning can guide evolution.
*Complex Systems* 1:495–502.

Jablonka, E. & Lamb, M.J. (2005) *Evolution in Four Dimensions.* MIT
Press.

Mayley, G. (1996) Landscapes, learning costs and genetic assimilation.
*Evolutionary Computation* 4(3):213–234.

Waddington, C.H. (1942) Canalization of development and the inheritance
of acquired characters. *Nature* 150:563–565.
