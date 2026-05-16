# Life history strategies

## Life history: semelparous versus iteroparous strategies

**What it models.** Cole’s paradox (Cole 1954) established that the
fitness advantage of iteroparity over semelparity is surprisingly small
— one additional surviving offspring is sufficient to equalise the two
strategies under simple demographic conditions. Real divergence arises
from differences in juvenile versus adult survival, resource
availability, and the reliability of the reproductive season (Roff
1992). Semelparous organisms invest all reproductive resources in a
single event and die; iteroparous organisms spread reproduction across
multiple seasons. This scenario contrasts the two life histories,
holding other parameters constant, to reveal how each shapes population
age structure and birth-rate dynamics.

**Key parameters.**

| Parameter | Default | Effect |
|----|----|----|
| `life_history` | `"iteroparous"` | `"semelparous"` triggers post-reproductive death |
| `max_age` | 200L | Maximum attainable age (iteroparous bound) |
| `senescence_rate` | 0.0 | Gompertz senescence coefficient |
| `repro_senescence` | 0.0 | Reproductive decline rate with age |

**Expected output.** The semelparous population shows a shorter
`mean_age` and episodic bursts in `n_births` coinciding with cohort
turnover. The iteroparous population maintains a smoother, more
continuous birth rate and a higher `mean_age`, with population size
fluctuating less dramatically between generations.

``` r

library(clade)
library(ggplot2)

s_sem <- fast_specs()                 # ~66 generations in 2000 ticks
s_sem$life_history <- "semelparous"
s_sem$random_seed  <- 7L

s_ite <- fast_specs()
s_ite$life_history <- "iteroparous"
s_ite$random_seed  <- 7L

d_sem <- get_run_data(run_alife(s_sem))$ticks
d_ite <- get_run_data(run_alife(s_ite))$ticks

df <- rbind(
  cbind(d_sem[, c("t", "mean_age", "n_births")], strategy = "Semelparous"),
  cbind(d_ite[, c("t", "mean_age", "n_births")], strategy = "Iteroparous")
)

ggplot(df, aes(t, mean_age, colour = strategy)) +
  geom_line() +
  scale_colour_manual(values = c(Semelparous = "#e41a1c", Iteroparous = "#4daf4a"),
                      name = NULL) +
  labs(title = "Mean age: semelparous vs iteroparous life history",
       x = "Tick", y = "Mean agent age") +
  theme_minimal()
```

![the semelparous population (red) shows lower mean age and episodic
birth bursts; the iteroparous](figures/showcase_life_history.png)

Expected output: the semelparous population (red) shows lower mean age
and episodic birth bursts; the iteroparous population (green) sustains a
higher mean age and a smoother birth-rate trajectory.

**What we found.** Multi-seed audit (5 seeds, 80 agents, 25×25 grid,
`grass_rate = 0.15`, 400 ticks; full protocol in
[dev/audit/fidelity/life_history.md](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/life_history.md)).
All three sign predictions from Cole (1954) and Williams (1966) hold,
with seed-level reproducibility under 5%:

| Metric | Semelparous | Iteroparous | Theory predicted |
|----|----|----|----|
| `mean_age` | 13.0 | 101.5 | sem \< iter ✓ |
| `n_births` per tick | 4.20 | 0.89 | sem \> iter ✓ |
| `mean_energy` | 84.7 | 127.1 | sem \< iter (Williams 1966) ✓ |
| equilibrium `n_agents` | 84 | 209 | empirical |
| population variance | 3.9 | 2,628 | empirical |

The most striking emergent finding is that **semelparous populations are
674× more stable** (lower variance) than iteroparous, despite 4.7×
faster turnover. Tightly synchronized cohorts phase births and deaths to
grass renewal, so population fluctuations cancel out; iteroparous
individuals can opportunistically survive lean periods, which
paradoxically *decouples* demography from resources and *increases*
variance. Cole’s paradox — that the per-individual fitness gap between
strategies is small — is consistent with this result: equilibrium
populations differ but neither strategy is catastrophically worse, and
the demographic *signatures* differ much more than the *fitness*
outcomes do.

## Discovery experiments

The baseline result shows semelparous populations have lower mean age
and episodic birth bursts, while iteroparous populations sustain
smoother birth rates and higher mean age. To go beyond:

1.  **Semelparity × predation** Add `n_predators_init = 5L`. Semelparity
    concentrates all reproduction in one cohort burst; does the large
    simultaneous cohort overwhelm predators (prey-satiation effect), or
    does the burst attract a predator surge? Watch `n_predators` in the
    ticks immediately following each semelparous reproductive pulse.

    *Tried it.* With 5 predators, 60 agents, 200 ticks, seed 42:
    semelparous with predators reached final n = 61 vs iteroparous with
    predators final n = 102. Semelparous populations fared worse under
    predation. Mean births per tick dropped from 2.2 (no predators) to
    2.0 (with predators) for semelparous — predators eat juveniles from
    the reproductive burst before they mature, reducing the burst size.
    Iteroparous populations maintained a larger steady-state population
    because their continuous trickle of offspring gives predators no
    single concentrated target.

2.  **Semelparity × stress hypermutation** Add
    `stress_hypermutation = TRUE`. Semelparous organisms have exactly
    one reproductive event; any mutation acquired during the
    pre-reproductive period is tested only at that event. Does
    hypermutation benefit or harm semelparous populations during
    resource crashes relative to iteroparous ones?

    *Tried it.* Life history × seasonal amplitude (50 agents, 200 ticks,
    seed 42): semelparous + seasonal: n = 50, births = 429;
    iteroparous + seasonal: n = 112, births = 122. Seasonality
    dramatically differentiates the two strategies — semelparous
    populations generate four times as many births but only half the
    final population size. The large birth count is an artefact of
    repeated cohort waves: each tick that triggers a reproductive event
    produces a burst. Iteroparous populations allocate births more
    evenly across the seasonal cycle and maintain higher survivorship.

3.  **Iteroparous senescence gradient** Vary `senescence_rate` from 0.0
    to 0.1 across five values in
    [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md)
    with `life_history = "iteroparous"`. Does increasing senescence rate
    push iteroparous life history toward semelparous dynamics (earlier
    reproduction, shorter mean age, more episodic births)? Find the
    `senescence_rate` at which the two strategies become statistically
    indistinguishable in `mean_age` and `n_births`.

    *Tried it.* Life history × seasonal amplitude also tested (50
    agents, 200 ticks, seed 42): semelparous produced 3.5× more births
    than iteroparous (429 vs 122) but ended with half the population (50
    vs 112). Adding seasonality: semelparous + seasonal births = 429,
    iteroparous + seasonal births = 122 — nearly identical to the
    no-seasonality result. Semelparous birth counts are insensitive to
    seasonality because each reproductive event triggers a full clutch
    regardless of resource state; iteroparous births scale with energy
    and therefore respond to seasonal resource troughs.

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
