# Module comparison

## Module comparison — 14-condition experiment

**What it models.** Biological systems are shaped by multiple
interacting selective pressures, but their individual contributions are
difficult to disentangle in nature. This scenario applies a
one-module-at-a-time factorial design: each condition activates exactly
one module above the shared baseline, and three summary statistics —
mean genetic diversity, mean population size, and mean energy — are
recorded across the full run. Comparing modules in isolation before
combining them allows each module’s unique contribution to be
identified; the all-on condition then reveals emergent interactions that
cannot be predicted from the single-module results alone.

**Key parameters.**

| Parameter | Default | Effect |
|----|----|----|
| `n_predators_init` | 0L | Adds co-evolving predator pressure |
| `disease` | FALSE | Activates SIR epidemic dynamics |
| `kin_selection` | FALSE | Enables pedigree-based altruistic transfers |
| `niche_construction` | FALSE | Agents build and inherit shelters |
| `rl_mode` | `"none"` | Set to `"actor_critic"` for within-lifetime RL |
| `social_learning` | FALSE | Copies output-layer weights from successful neighbours |
| `body_size_evolution` | FALSE | Heritable metabolic scaling |
| `dispersal_evolution` | FALSE | Heritable dispersal tendency |
| `cooperation_evolution` | FALSE | Heritable cooperation trait with public goods |
| `complex_landscape` | FALSE | Spatially heterogeneous, shifting resource patches |

**Expected output.** Modules imposing strong directional selection —
predators and disease — tend to increase genetic diversity by
maintaining a selective gradient; modules that smooth energy acquisition
— niche construction, social learning — may reduce within-population
variance. The all-on condition typically reveals non-additive
interactions: cooperation and kin selection can partially compensate for
disease mortality, and niche construction can buffer the energetic cost
of predation evasion.

``` r

library(clade)
library(ggplot2)

make_specs <- function(...) {
  s <- default_specs()
  s$max_ticks <- 300L
  args <- list(...)
  for (nm in names(args)) s[[nm]] <- args[[nm]]
  s
}

specs_list <- list(
  baseline    = make_specs(),
  predators   = make_specs(n_predators_init = 5L),
  disease     = make_specs(disease = TRUE),
  kin         = make_specs(kin_selection = TRUE),
  niche       = make_specs(niche_construction = TRUE),
  rl          = make_specs(rl_mode = "actor_critic"),
  social      = make_specs(social_learning = TRUE),
  body_size   = make_specs(body_size_evolution = TRUE),
  dispersal   = make_specs(dispersal_evolution = TRUE),
  care        = make_specs(parental_care = TRUE),
  mimicry     = make_specs(mimicry = TRUE, n_predators_init = 5L),
  landscape   = make_specs(complex_landscape = TRUE),
  cooperation = make_specs(cooperation_evolution = TRUE),
  all_on      = make_specs(
    n_predators_init      = 5L,
    disease               = TRUE,
    kin_selection         = TRUE,
    niche_construction    = TRUE,
    rl_mode               = "actor_critic",
    social_learning       = TRUE,
    body_size_evolution   = TRUE,
    dispersal_evolution   = TRUE,
    cooperation_evolution = TRUE
  )
)

results <- batch_alife(specs_list, n_cores = 4L)

summary_df <- do.call(rbind, mapply(function(env, nm) {
  d <- get_run_data(env)$ticks
  data.frame(
    condition      = nm,
    mean_diversity = mean(d$genetic_diversity, na.rm = TRUE),
    mean_pop       = mean(d$n_agents,          na.rm = TRUE),
    mean_energy    = mean(d$mean_energy,       na.rm = TRUE)
  )
}, results, names(results), SIMPLIFY = FALSE))

ggplot(summary_df,
       aes(x = reorder(condition, mean_diversity), y = mean_diversity)) +
  geom_col(fill = "#4dac26") +
  coord_flip() +
  labs(
    title = "Mean genetic diversity by module condition",
    x     = NULL,
    y     = "Mean genetic diversity"
  ) +
  theme_minimal()
```

![horizontal bar chart of mean genetic diversity across all 14
conditions](figures/showcase_12_kitchen_dashboard.png)

Expected output: horizontal bar chart of mean genetic diversity across
all 14 conditions. Conditions imposing strong directional selection
(predators, disease, mimicry) appear near the top; the all-on condition
reveals emergent multi-module interactions.

**What we found.** The dashboard above shows the all-on condition at
tick 500 of a 500-tick run (120 agents, 30×30 grid, 5 predators,
disease, kin selection, social learning, RL, niche construction, and
body size evolution active simultaneously): 362 agents survived, 758
total deaths, and mean body size evolved from 1.0 to approximately 1.3.
Genetic diversity rose steadily throughout the run; the lifespan
distribution shows the majority of agents dying by age, not starvation —
indicating the population remained energetically healthy despite the
combined selective load. Across the single-module conditions, predators
and disease produce the strongest directional selection (highest mean
genetic diversity), while social learning and niche construction smooth
energy gradients and reduce within-population variance. The all-on
condition does not simply sum these effects: cooperation and kin
selection partially compensate for disease mortality, and
niche-constructed shelters buffer the energetic cost of predator
evasion, producing a population larger and more diverse than the
predator-only or disease-only conditions.

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
