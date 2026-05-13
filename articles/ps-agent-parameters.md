# Parameter search — agent-level parameters

Agent-level parameters are the ones that vary per organism or per
species. They set individual morphology, behaviour, life history, and
cognition — and they are typically what gets tuned when you ask “which
type of organism thrives here?”. For environment-level parameters
(resources, grid, seasonality, external forces), see
[ps-environment-parameters.html](https://itchyshin.github.io/clade/articles/ps-environment-parameters.md).

This vignette lists the agent-level parameters by module, flags the ones
that are only active when a matching `_evolution` flag is set, and shows
worked searches for a few common cases. For the algorithms themselves,
see
[ps-algorithms.html](https://itchyshin.github.io/clade/articles/ps-algorithms.md).

------------------------------------------------------------------------

## Traits (heritable scalars)

The 15 `TRAIT_*` scalar traits live on the genome and express per
individual. Each is silent (fixed at a biologically neutral default)
unless its `_evolution` flag is `TRUE`. You can search either the *init
mean* (to ask where the population *starts*) or the `_mutation_sd` (to
ask how fast it drifts), or both.

| Trait | Enable flag | Init-mean field | Mutation-SD field | Biological role |
|----|----|----|----|----|
| `body_size` | `body_size_evolution` | `body_size_init_mean` | `body_size_mutation_sd` | Metabolic scaling + foraging allometry (Kleiber) |
| `immune_strength` | `immune_evolution` | `immune_strength_init_mean` | `immune_strength_mutation_sd` | Disease resistance |
| `cooperation_level` | `cooperation_evolution` | `cooperation_init_mean` | `cooperation_mutation_sd` | Public-goods contribution |
| `dispersal_tendency` | `dispersal_evolution` | `dispersal_init_mean` | `dispersal_mutation_sd` | Natal dispersal probability |
| `metabolic_rate` | `metabolic_rate_evolution` | `metabolic_rate_init_mean` | `metabolic_rate_mutation_sd` | Pace-of-life cost multiplier |
| `aging_rate` | `aging_rate_evolution` | `aging_rate_init_mean` | `aging_rate_mutation_sd` | Gompertz senescence multiplier |
| `mutation_sd` | `mutation_rate_evolution` | `mutation_sd_init_mean` | — | Evolving evolvability |
| `learning_rate` | `learning_rate_evolution` | `learning_rate_init_mean` | — | RL step size, Baldwin |
| `habitat_preference` | `habitat_preference_evolution` | `habitat_preference_init_mean` | `habitat_preference_mutation_sd` | IFD tracking |
| `helper_tendency` | `cooperative_breeding` | `helper_tendency_init_mean` | `helper_tendency_mutation_sd` | Alloparental propensity |
| `plasticity` | `phenotypic_plasticity` | `plasticity_init_mean` | `plasticity_mutation_sd` | 0.4.0: also sets BNN prior-sigma when `bnn_sigma_source = "trait"` |
| `toxicity` | `mimicry` | `toxicity_init_mean` | `toxicity_mutation_sd` | Aposematism (Bates/Müller) |
| `wing_size` | `complex_landscape` | `wing_size_init_mean` | `wing_size_mutation_sd` | Canopy access in 3-layer habitat |
| `brain_size` | `brain_size_evolution` | `brain_size_init_mean` | `brain_size_mutation_sd` | Expensive-brain + sensing bonus |

**If the `_evolution` flag is `FALSE`, the init-mean and mutation-SD are
ignored.** The trait is clamped at its biologically neutral value
(usually `1.0` for multipliers, `0.0` for zero-centred propensities).
This catches beginners: setting `body_size_init_mean = 2.0` with
`body_size_evolution = FALSE` has no effect. The [fidelity audit
pace-of-life
trace](https://github.com/itchyshin/clade/blob/main/dev/audit/fidelity/pace_of_life.md)
is a cautionary example of this exact pitfall.

------------------------------------------------------------------------

## Brain architecture

Four architecture knobs, all searchable:

| Parameter | Default | Range / values | Role |
|----|----|----|----|
| `brain_type` | `"bnn"` | `"bnn" / "ann" / "ctrnn" / "grn" / "transformer" / "synthesis" / "random"` | Choose once — not evolved within a run |
| `hidden_layers` | `c(8L)` | `c(8L)`, `c(16L, 8L)`, etc. | Capacity |
| `input_radius` | `1L` | `1L`, `2L` | Sensing range |
| `bnn_sigma_source` | `"heterozygosity"` | `"heterozygosity"` (legacy), `"fixed"`, `"trait"` | 0.4.0: how BNN prior width is set |
| `bnn_sigma_init` | `0.5` | positive float | Used in `"fixed"` mode |
| `bnn_sample_freq` | `1L` | `1L`, `5L`, `20L` | 0.4.0: cache sample for N forward calls |
| `rl_mode` | `"none"` | `"none"`, `"actor_critic"` | Within-lifetime REINFORCE (Williams 1992) |
| `lamarckian` | `FALSE` | logical | Write RL-learned weights back to genome at reproduction |

`brain_type` is categorical — search it by looping over conditions
rather than passing to CMA-ES. `bnn_sigma_source` is also categorical;
the two non-default modes were introduced in 0.4.0 specifically to make
the Baldwin Effect testable (see
[kernel-0.4.0.md](https://github.com/itchyshin/clade/blob/main/dev/docs/kernel-0.4.0.md)).

------------------------------------------------------------------------

## Life history

| Parameter | Default | Role |
|----|----|----|
| `life_history` | `"iteroparous"` | `"semelparous"` triggers post-reproductive death |
| `max_age` | `200L` | Hard age cap |
| `max_age_scales_with_metabolism` | `FALSE` | 0.4.0: when `TRUE`, eff. max_age = base / metabolic_rate (Réale 2010 pace-of-life) |
| `senescence_rate` | `0.0` | Gompertz coefficient (0 = off) |
| `min_repro_age` | `0L` | Minimum age to reproduce |
| `min_repro_energy` | `120.0` | Minimum energy to reproduce |

`max_age_scales_with_metabolism = TRUE` is what lets pace-of-life
scenarios show the predicted fast-pace-short-life pattern; otherwise
every agent dies at the base cap regardless of metabolic rate.

------------------------------------------------------------------------

## Reproduction

0.4.0 rewrote the reproduction-cost accounting. The legacy `fixed` mode
is still available for reproducing pre-0.4.0 results, but the biological
default is now `proportional` (Smith & Fretwell 1974).

| Parameter | Default | Role |
|----|----|----|
| `repro_cost_mode` | `"proportional"` | `"fixed"` or `"proportional"` |
| `repro_cost` | `30.0` | Fixed-mode constant cost |
| `repro_cost_fraction` | `0.5` | Proportional-mode fraction of parent energy |
| `offspring_energy_mode` | `"proportional"` | Same dichotomy for newborn starting energy |
| `offspring_energy` | `60.0` | Fixed-mode newborn energy |
| `offspring_energy_fraction` | `0.25` | Proportional-mode: fraction of cost paid |
| `max_clutch_size` | `1L` | Offspring per reproductive event |
| `clutch_size_evolution` | `FALSE` | Make clutch size heritable |
| `parental_care` | `FALSE` | Carry offspring until graduation |
| `care_duration` | `5L` | Ticks of carrying |
| `parental_investment_evolution` | `FALSE` | Enable Trivers biparental split |
| `female_investment` | `0.7` | In 0.4.0, splits cost fi vs (1-fi) + scales offspring energy by 2×fi |

The `female_investment` coupling is new in 0.4.0 — it was a no-op
before. See `s-parental-investment` for the ρ = −1.00 dose-response it
now produces.

------------------------------------------------------------------------

## Signals, mate choice, social behaviour

| Parameter | Default | Role |
|----|----|----|
| `signal_dims` | `0L` | Length of heritable signal vector; 0 disables signals |
| `signal_init_mean` | `0.0` | Starting signal magnitude |
| `signal_cost` | `0.1` | Per-tick energy cost per unit magnitude (Zahavi handicap) |
| `signal_evolution_drift` | `FALSE` | Add mutation to signals each tick |
| `mate_choice_mode` | `"preference"` | `"preference"`, `"random"`, or `"highest_signal"` (wired 0.6.4) |
| `avoid_threshold` | `0.5` | Aposematic avoidance trigger (mimicry) |
| `kin_altruism_cost` | `2.0` | Donor cost |
| `kin_altruism_benefit` | `10.0` | Recipient benefit |
| `kin_altruism_r_min` | `0.25` | Relatedness threshold |
| `iffolk_transfer` | `3.0` | Inclusive-fitness transfer amount |
| `parliament_suppression` | `FALSE` | Penalise defectors among cooperators |
| `parliament_cost` | `0.5` | Defector penalty |
| `cooperation_multiplier` | `2.0` | Public-goods payoff (Nowak & May 1992) |

Kin altruism is the textbook case for a clean parameter search: a 9-cell
`B × C` grid at fixed `r_min = 0.25` recovers Hamilton’s rule with
Spearman ρ = 0.97, and a similar grid on the cooperation multiplier
recovers Nowak–May with ρ = 1.00. See `s-kin` and `s-cooperation`.

------------------------------------------------------------------------

## Worked example: random search over agent parameters

The cheapest way to explore — 30 simulations at random points inside a
hyper-box you specify. Use this first to locate productive regions
before committing to a more expensive algorithm.

``` r

library(clade)

result <- search_random(
  specs_base    = default_specs(),
  search_params = list(
    mutation_sd             = c(0.01, 0.5),
    crossover_rate          = c(0.0, 2.0),
    body_size_mutation_sd   = c(0.01, 0.2)
  ),
  n_samples = 30L,
  objective = "genetic_diversity"
)

head(result)
```

The `result` data frame is sorted by descending score. Each row is one
simulation; `score` is mean `genetic_diversity` across ticks.

Retrieve the full specs of the best configuration:

``` r

best_specs <- attr(result, "specs_list")[[1]]
cat("Best mutation_sd:", best_specs$mutation_sd, "\n")
cat("Best crossover_rate:", best_specs$crossover_rate, "\n")
```

------------------------------------------------------------------------

## Worked example: CMA-ES on brain hyperparameters

When you want the single best brain configuration and the search space
is continuous (BNN prior width, learning rate, body-size trait), CMA-ES
gives you a good answer in ~20 iterations × popsize 10 = 200 runs.

``` r

result <- search_cmaes(
  specs_base = default_specs(),
  params     = c("bnn_sigma_init",
                 "learning_rate_init_mean",
                 "body_size_mutation_sd"),
  objective  = "genetic_diversity",
  n_iterations = 20L,
  popsize      = 10L
)

cat("Best diversity:", result$score, "\n")
print(result$specs[c("bnn_sigma_init",
                     "learning_rate_init_mean",
                     "body_size_mutation_sd")])
```

Use the `learning_rate_evolution = TRUE` + `rl_mode = "actor_critic"`
combination to test the Baldwin Effect directly — this is exactly the
setup the auto-calibration harness in
[`dev/audit/calibration/`](https://github.com/itchyshin/clade/tree/main/dev/audit/calibration)
uses.

------------------------------------------------------------------------

## Worked example: calibrating IFfolk

A domain-specific
[`tune_iffolk()`](https://itchyshin.github.io/clade/reference/tune_iffolk.md)
wrapper pre-configures the relevant agent-level parameters (transfer
rate, parliament cost, helper tendency evolution) and uses
[`objective_iffolk()`](https://itchyshin.github.io/clade/reference/objective_iffolk.md),
which fits a linear regression to `mean_helper_tendency` over time and
rewards upward trends plus a per-agent transfer bonus. This is far more
sensitive than simply maximising the final helper tendency:

``` r

tuned_iff <- tune_iffolk(default_specs(), n_iterations = 80L)
tuned_iff$specs$iffolk_transfer   # optimal transfer amount
```

Pair this with
[`search_viability()`](https://itchyshin.github.io/clade/reference/search_viability.md)
first — see
[ps-environment-parameters.html#viability-mapping](https://itchyshin.github.io/clade/articles/ps-environment-parameters.html#viability-mapping)
— because at extreme parameter values the IFfolk population goes extinct
and CMA-ES has no signal to follow.

------------------------------------------------------------------------

## Cross-links to fuzzy parameters

A handful of parameters blur the agent/environment line. Their primary
listing is here, but see the environment page for how they interact with
the world:

- **Predator agent parameters** (`predator_attack_strength`,
  `predator_energy_gain`, `predator_min_repro_energy`,
  `predator_mutation_sd`) live on the predators themselves but their
  *abundance* (`n_predators_init`, `predator_max_agents`) is an
  environmental selection force — see
  [ps-environment-parameters.html#predators](https://itchyshin.github.io/clade/articles/ps-environment-parameters.html#predators).
- **Niche-construction parameters** (`shelter_build_prob`,
  `shelter_occupancy_bonus`) are agent-behavioural, but their effect on
  grass regrowth is environmental.
- **Scavenging** (`carrion_eat_gain`) is agent foraging on a world state
  that was created by another agent’s death.

------------------------------------------------------------------------

## See also

- **[ps-introduction.html](https://itchyshin.github.io/clade/articles/ps-introduction.md)**
  — when to search, which algorithm, how to design an objective
  function.
- **[ps-environment-parameters.html](https://itchyshin.github.io/clade/articles/ps-environment-parameters.md)**
  — grid, resources, seasonality, external forces.
- **[ps-algorithms.html](https://itchyshin.github.io/clade/articles/ps-algorithms.md)**
  — full algorithm reference.
- **[`vignette("parameter-reference")`](https://itchyshin.github.io/clade/articles/parameter-reference.md)**
  — exhaustive list of every parameter in
  [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md).
