# Parameter Reference

This article lists every parameter in
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md),
grouped by biological theme. For each parameter you’ll see the default
value and its type.

**The tables on this page are generated at vignette-build time** from
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md)
itself, so they cannot drift from what the code actually ships. The full
description of each parameter — including units, valid ranges,
references, and module-interaction notes — lives in the
[`default_specs()` reference
page](https://itchyshin.github.io/clade/reference/default_specs.md).
This page is a quick lookup; that page is the authoritative
documentation.

For an interactive view of a customised spec list, use
[`print_specs()`](https://itchyshin.github.io/clade/reference/print_specs.md):

``` r

s <- default_specs()
s$kin_selection      <- TRUE
s$complex_landscape  <- TRUE
print_specs(s, diff_only = TRUE)
```

------------------------------------------------------------------------

## Grid and population

The toroidal grid, founder population, simulation horizon, and the two
0.7.0 kernel-discipline switches.

| Parameter           | Default      | Type    |
|:--------------------|:-------------|:--------|
| `grid_rows`         | 30           | integer |
| `grid_cols`         | 30           | integer |
| `toroidal`          | TRUE         | logical |
| `random_tick_order` | TRUE         | logical |
| `n_agents_init`     | 50           | integer |
| `max_agents`        | 500          | integer |
| `max_ticks`         | 500          | integer |
| `random_seed`       | NA_integer\_ | integer |

`random_tick_order = TRUE` (default) enables random asynchronous agent
scheduling per Grimm & Railsback (2005); setting `FALSE` recovers the
legacy fixed-order behaviour. `max_agents_per_cell = 1L` (default)
enforces one-per-cell movement; `0L` allows unbounded co-occupancy
(legacy). See `NEWS.md` for the 0.7.0 audit that surfaced these.

------------------------------------------------------------------------

## Energy and metabolism

Per-agent energy budget: starting energy, costs of moving / waiting /
reproducing, and the threshold below which agents starve.

| Parameter                   | Default        | Type      |
|:----------------------------|:---------------|:----------|
| `energy_init`               | 100            | numeric   |
| `energy_max`                | 200            | numeric   |
| `move_cost`                 | 1              | numeric   |
| `idle_cost`                 | 0.5            | numeric   |
| `eat_gain`                  | 5              | numeric   |
| `max_bite`                  | 2              | numeric   |
| `min_repro_energy`          | 120            | numeric   |
| `repro_cost_mode`           | “proportional” | character |
| `repro_cost`                | 30             | numeric   |
| `repro_cost_fraction`       | 0.5            | numeric   |
| `offspring_energy_mode`     | “proportional” | character |
| `offspring_energy`          | 60             | numeric   |
| `offspring_energy_fraction` | 0.25           | numeric   |
| `starvation_threshold`      | 0              | numeric   |

`repro_cost_mode` and `offspring_energy_mode` control whether the cost
and birth-energy are fixed amounts or fractions of parental state — see
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md)
for the full Smith-Fretwell quality-quantity options.

------------------------------------------------------------------------

## Grass dynamics

The base food supply: how cells initialise, how often they regrow, and
the per-cell saturation.

| Parameter         | Default | Type    |
|:------------------|:--------|:--------|
| `grass_init_prob` | 0.5     | numeric |
| `grass_rate`      | 0.05    | numeric |
| `grass_max`       | 5       | numeric |

------------------------------------------------------------------------

## Brain architecture

The four implemented brain types plus a random null-model baseline.
`"transformer"` and `"synthesis"` are reserved names — the kernel errors
if either is requested at present.

| Parameter                    | Default          | Type      |
|:-----------------------------|:-----------------|:----------|
| `brain_type`                 | “bnn”            | character |
| `hidden_layers`              | 8                | integer   |
| `input_radius`               | 1                | integer   |
| `n_genes`                    | 20               | integer   |
| `transformer_history`        | 8                | integer   |
| `transformer_heads`          | 2                | integer   |
| `synthesis_max_rules`        | 10               | integer   |
| `ann_weight_values`          | NULL             | NULL      |
| `ann_regularization_lambda`  | 0.001            | numeric   |
| `bnn_sigma_source`           | “heterozygosity” | character |
| `bnn_sigma_init`             | 0.5              | numeric   |
| `bnn_sigma_min`              | 0.01             | numeric   |
| `bnn_sample_freq`            | 1                | integer   |
| `bnn_sigma_lr_scale`         | 0                | numeric   |
| `bnn_sigma_lr_ref`           | 0.5              | numeric   |
| `bnn_action_noise_scale`     | 1                | numeric   |
| `action_exploration_epsilon` | 0                | numeric   |

`bnn_sigma_source` is required for s-baldwin / s-plasticity scenarios
(0.4.0 Tier 5A). `bnn_sample_freq = 5` lets REINFORCE gradients
accumulate (required for the 0.4.1 s-rl ✅ verdict).

------------------------------------------------------------------------

## Brain metabolic cost

How brains cost energy: a fixed-per-weight floor, an activity-scaled
component, BNN-uncertainty information cost, and the Kleiber-style size
exponent.

| Parameter                    | Default    | Type      |
|:-----------------------------|:-----------|:----------|
| `brain_energy_mode`          | “activity” | character |
| `brain_energy_base`          | 0.001      | numeric   |
| `brain_energy_activity`      | 0.5        | numeric   |
| `brain_energy_sigma_scale`   | 0          | numeric   |
| `brain_energy_size_exponent` | 1          | numeric   |
| `brain_size_cost_scale`      | 1          | numeric   |

------------------------------------------------------------------------

## Reproduction and genetics

Ploidy, mate-choice, recombination, and reproduction-age controls.

| Parameter                     | Default      | Type      |
|:------------------------------|:-------------|:----------|
| `ploidy`                      | 2            | integer   |
| `mate_choice_mode`            | “preference” | character |
| `mate_choice_strength`        | 1            | numeric   |
| `mutation_sd`                 | 0.1          | numeric   |
| `crossover_rate`              | 1            | numeric   |
| `min_repro_age`               | 0            | integer   |
| `n_chromosomes`               | 1            | integer   |
| `dominance_model`             | “additive”   | character |
| `mate_search_radius`          | 1            | integer   |
| `self_fertilization_fallback` | FALSE        | logical   |

`mate_choice_mode = "preference"` enables signal-preference assortative
mating; `"random"` reverts to baseline. `mate_search_radius` is the
Moore-neighbourhood radius for partner search.

------------------------------------------------------------------------

## Life history

Maximum lifespan, the Gompertz senescence parameters (rate × shape), and
the optional pace-of-life lifespan-scaling coupling.

| Parameter                        | Default       | Type      |
|:---------------------------------|:--------------|:----------|
| `max_age`                        | 200           | integer   |
| `life_history`                   | “iteroparous” | character |
| `senescence_rate`                | 0             | numeric   |
| `senescence_shape`               | 1             | numeric   |
| `allee_threshold`                | 0             | integer   |
| `max_age_scales_with_metabolism` | FALSE         | logical   |

The Gompertz hazard is
$`p = 1 - \exp(-r \cdot \exp(r \cdot \mathrm{age}^{\mathrm{shape}}))`$
with $`r = \mathrm{senescence\_rate} \times \mathrm{aging\_rate}`$.
`senescence_shape = 1` (default) is the classic Gompertz; \> 1
accelerates late-life mortality; \< 1 gives a late-life plateau (Vaupel
et al. 1998).

------------------------------------------------------------------------

## Body size evolution

Enable with `body_size_evolution = TRUE`.

| Parameter               | Default | Type    |
|:------------------------|:--------|:--------|
| `body_size_evolution`   | FALSE   | logical |
| `body_size_init_mean`   | 1       | numeric |
| `body_size_mutation_sd` | 0.08    | numeric |
| `body_size_min`         | 0.3     | numeric |
| `body_size_max`         | 3       | numeric |

------------------------------------------------------------------------

## Brain size evolution

Enable with `brain_size_evolution = TRUE`. Cognitive bonus is balanced
against the metabolic cost set in “Brain metabolic cost” above.

| Parameter                     | Default | Type    |
|:------------------------------|:--------|:--------|
| `brain_size_evolution`        | FALSE   | logical |
| `brain_size_init_mean`        | 1       | numeric |
| `brain_size_mutation_sd`      | 0.05    | numeric |
| `brain_size_min`              | 0.1     | numeric |
| `brain_size_max`              | 3       | numeric |
| `brain_size_sensing_exponent` | 0.3     | numeric |

------------------------------------------------------------------------

## Dispersal evolution

Enable with `dispersal_evolution = TRUE`. Combine with
`spatial_sorting = TRUE` for invasion-front dynamics.

| Parameter               | Default | Type    |
|:------------------------|:--------|:--------|
| `dispersal_evolution`   | FALSE   | logical |
| `dispersal_init_mean`   | 0.1     | numeric |
| `dispersal_mutation_sd` | 0.02    | numeric |
| `dispersal_min`         | 0       | numeric |
| `dispersal_max`         | 0.5     | numeric |
| `dispersal_cost`        | 2       | numeric |

------------------------------------------------------------------------

## Habitat preference

Enable with `habitat_preference_evolution = TRUE`.

| Parameter                        | Default | Type    |
|:---------------------------------|:--------|:--------|
| `habitat_preference_evolution`   | FALSE   | logical |
| `habitat_preference_init_mean`   | 0       | numeric |
| `habitat_preference_mutation_sd` | 0.03    | numeric |
| `habitat_preference_min`         | -1      | numeric |
| `habitat_preference_max`         | 1       | numeric |
| `habitat_preference_strength`    | 0.5     | numeric |
| `habitat_move_cost`              | 0       | numeric |

------------------------------------------------------------------------

## Kin selection

Enable with `kin_selection = TRUE`. Pedigree-based relatedness; see the
`s-kin` vignette for Hamilton’s-rule examples.

| Parameter                       | Default | Type    |
|:--------------------------------|:--------|:--------|
| `kin_selection`                 | FALSE   | logical |
| `kin_altruism_r_min`            | 0.25    | numeric |
| `kin_altruism_cost`             | 2       | numeric |
| `kin_altruism_benefit`          | 10      | numeric |
| `kin_altruism_min_donor_energy` | 50      | numeric |

------------------------------------------------------------------------

## Cooperation (PGG)

Enable with `cooperation_evolution = TRUE`. Public-goods games on the
neighbourhood; see `s-cooperation`.

| Parameter                 | Default | Type    |
|:--------------------------|:--------|:--------|
| `cooperation_evolution`   | FALSE   | logical |
| `cooperation_multiplier`  | 2       | numeric |
| `cooperation_init_mean`   | 0.5     | numeric |
| `cooperation_mutation_sd` | 0.05    | numeric |
| `cooperation_cost`        | 1       | numeric |

------------------------------------------------------------------------

## Disease (SIR dynamics)

Enable with `disease = TRUE`.

| Parameter                     | Default | Type    |
|:------------------------------|:--------|:--------|
| `disease`                     | FALSE   | logical |
| `transmission_prob`           | 0.1     | numeric |
| `disease_duration`            | 10      | integer |
| `disease_energy_cost`         | 5       | numeric |
| `disease_death_prob`          | 0.02    | numeric |
| `immune_duration`             | 20      | integer |
| `disease_seed_prob`           | 0.01    | numeric |
| `immune_evolution`            | FALSE   | logical |
| `immune_strength_init_mean`   | 0.3     | numeric |
| `immune_strength_mutation_sd` | 0.05    | numeric |
| `immune_strength_min`         | 0       | numeric |
| `immune_strength_max`         | 1       | numeric |

------------------------------------------------------------------------

## Predators

Enable with `n_predators_init > 0`. Predators are co-evolving agents
with their own 15-input sensory brain.

| Parameter                   | Default | Type    |
|:----------------------------|:--------|:--------|
| `n_predators_init`          | 0       | integer |
| `predator_energy_init`      | 150     | numeric |
| `predator_live_energy`      | 2       | numeric |
| `predator_attack_strength`  | 40      | numeric |
| `predator_energy_gain`      | 30      | numeric |
| `predator_min_repro_energy` | 200     | numeric |
| `predator_min_repro_age`    | 5       | integer |
| `predator_mutation_sd`      | 0.1     | numeric |
| `predator_max_agents`       | 50      | integer |
| `predator_max_age`          | NA      | logical |
| `predator_sense_graded`     | TRUE    | logical |
| `predator_move_energy`      | 1       | numeric |

`predator_sense_graded = TRUE` (0.4.2 default): prey’s predator sensory
input at distance `d` is `1/(d+1)` (graded threat-level). `FALSE` falls
back to pre-0.4.2 binary presence.

------------------------------------------------------------------------

## Group defense

Enable with `group_defense = TRUE`. Coordinated anti-predator behaviour
at high local density.

| Parameter                | Default | Type    |
|:-------------------------|:--------|:--------|
| `group_defense`          | FALSE   | logical |
| `group_defense_radius`   | 2       | integer |
| `group_defense_strength` | 0.3     | numeric |

------------------------------------------------------------------------

## Niche construction

Enable with `niche_construction = TRUE`. Shelters modify the local
selection environment.

| Parameter                 | Default | Type    |
|:--------------------------|:--------|:--------|
| `niche_construction`      | FALSE   | logical |
| `shelter_build_prob`      | 0.1     | numeric |
| `shelter_min_energy`      | 80      | numeric |
| `shelter_max_depth`       | 5       | integer |
| `shelter_decay_prob`      | 0.05    | numeric |
| `shelter_occupancy_bonus` | 0       | numeric |

`shelter_occupancy_bonus > 0` activates the heritable-niche effect
(Odling-Smee, Laland & Feldman 2003): agents on a shelter cell receive
`bonus × depth` energy per tick.

------------------------------------------------------------------------

## Within-lifetime reinforcement learning

Enable with `rl_mode = "actor_critic"`. `plasticity_cost` charges a
per-tick metabolic cost proportional to `learning_rate` (Laughlin et
al. 1998 *Nature Neuroscience*).

| Parameter                 | Default | Type      |
|:--------------------------|:--------|:----------|
| `rl_mode`                 | “none”  | character |
| `learning_rate`           | 0.01    | numeric   |
| `learning_rate_init_mean` | 0.01    | numeric   |
| `learning_rate_min`       | 0       | numeric   |
| `learning_rate_max`       | 0.5     | numeric   |
| `learning_rate_evolution` | FALSE   | logical   |
| `plasticity_cost`         | 0.05    | numeric   |
| `rl_update_freq`          | 1       | integer   |
| `lamarckian`              | FALSE   | logical   |

`lamarckian = TRUE` writes within-lifetime learned weights back to the
genome before meiosis. Off by default.

------------------------------------------------------------------------

## Social learning

Enable with `social_learning = TRUE`.

| Parameter              | Default | Type    |
|:-----------------------|:--------|:--------|
| `social_learning`      | FALSE   | logical |
| `social_learning_freq` | 10      | integer |
| `social_learning_rate` | 0.1     | numeric |

------------------------------------------------------------------------

## Signals and mate choice

Sexual-selection machinery. Enable signals by setting `signal_dims > 0`.

| Parameter                  | Default | Type    |
|:---------------------------|:--------|:--------|
| `signal_dims`              | 0       | integer |
| `signal_cost`              | 0.1     | numeric |
| `signal_cost_mortality`    | 0       | numeric |
| `signal_evolution_drift`   | TRUE    | logical |
| `signal_drift_sd`          | 0.01    | numeric |
| `preference_bias_target`   | NULL    | NULL    |
| `preference_bias_strength` | 0       | numeric |
| `signal_toxicity_coupling` | 0       | numeric |

`preference_bias_target` + `preference_bias_strength` implement the β_N
leg of Fuller, Houle & Travis (2005); see `paper-ryan-1990`.

------------------------------------------------------------------------

## Mimicry and toxicity

Enable with `mimicry = TRUE`. Müllerian by default; set
`batesian_mimicry = TRUE` for Batesian dynamics. As of 0.4.4 the
predator memory is a `signal_dims`-length vector updated via the
Widrow-Hoff delta rule.

| Parameter                | Default | Type    |
|:-------------------------|:--------|:--------|
| `mimicry`                | FALSE   | logical |
| `batesian_mimicry`       | FALSE   | logical |
| `toxicity_init_mean`     | 0       | numeric |
| `toxicity_mutation_sd`   | 0.05    | numeric |
| `toxicity_cost_per_tick` | 2       | numeric |
| `toxin_dose`             | 30      | numeric |
| `signal_memory_rate`     | 0.3     | numeric |
| `avoid_threshold`        | 0.5     | numeric |

------------------------------------------------------------------------

## Coevolving parasites (Hamilton 1980 Red Queen)

Enable with `coevolving_parasites = TRUE` AND either `signal_dims > 0`
(continuous mode) or `n_parasite_loci > 0` (discrete mode).

| Parameter                    | Default | Type      |
|:-----------------------------|:--------|:----------|
| `coevolving_parasites`       | FALSE   | logical   |
| `parasite_match_mode`        | “auto”  | character |
| `parasite_virulence_rate`    | 0.1     | numeric   |
| `parasite_pressure`          | 0.5     | numeric   |
| `parasite_distance_scale`    | 1       | numeric   |
| `n_parasite_loci`            | 0       | integer   |
| `parasite_mutation_rate`     | 0.01    | numeric   |
| `parasite_discrete_exponent` | 4       | numeric   |

Discrete mode (`n_parasite_loci >= 8`) is the canonical Hamilton
mechanism and is the regime where clade can show sex \> asex.

------------------------------------------------------------------------

## Parental care

Enable with `parental_care = TRUE`.

| Parameter                      | Default | Type    |
|:-------------------------------|:--------|:--------|
| `parental_care`                | FALSE   | logical |
| `juvenile_independence_age`    | 10      | integer |
| `juvenile_independence_energy` | 50      | numeric |
| `care_cost_per_tick`           | 1       | numeric |
| `feeding_rate`                 | 5       | numeric |
| `max_clutch_size`              | 1       | integer |
| `neonatal_foraging_deficit`    | 0       | numeric |
| `neonatal_deficit_duration`    | 10      | integer |

`neonatal_foraging_deficit > 0` creates the expensive-brain selection
pressure for parental provisioning (Aiello & Wheeler 1995; Isler & van
Schaik 2009).

------------------------------------------------------------------------

## Cooperative breeding

Enable with `cooperative_breeding = TRUE`. Usually combined with
`iffolk_selection = TRUE`. See `paper-emlen-1982`.

| Parameter                     | Default | Type    |
|:------------------------------|:--------|:--------|
| `cooperative_breeding`        | FALSE   | logical |
| `helper_min_energy`           | 80      | numeric |
| `helper_transfer`             | 5       | numeric |
| `helper_kin_threshold`        | 0.25    | numeric |
| `helper_tendency_init_mean`   | 0.1     | numeric |
| `helper_tendency_mutation_sd` | 0.02    | numeric |

------------------------------------------------------------------------

## Parental investment (Trivers 1972)

Enable with `parental_investment_evolution = TRUE`. The female bears
`female_investment` of per-offspring cost; offspring birth energy scales
by `2 × female_investment`.

| Parameter                       | Default | Type    |
|:--------------------------------|:--------|:--------|
| `parental_investment_evolution` | FALSE   | logical |
| `female_investment`             | 0.7     | numeric |
| `male_repro_cost`               | 0.3     | numeric |

------------------------------------------------------------------------

## Pace of life (Réale et al. 2010)

Heritable metabolic rate and aging rate; see `paper-reale-2010` and
`s-pace-of-life`.

| Parameter                    | Default | Type    |
|:-----------------------------|:--------|:--------|
| `metabolic_rate_evolution`   | FALSE   | logical |
| `metabolic_rate_init_mean`   | 1       | numeric |
| `metabolic_rate_mutation_sd` | 0.05    | numeric |
| `metabolic_rate_min`         | 0.1     | numeric |
| `metabolic_rate_max`         | 5       | numeric |
| `aging_rate_evolution`       | FALSE   | logical |
| `aging_rate_init_mean`       | 1       | numeric |
| `aging_rate_mutation_sd`     | 0.05    | numeric |
| `aging_rate_min`             | 0.01    | numeric |
| `aging_rate_max`             | 10      | numeric |

------------------------------------------------------------------------

## Mutation-rate evolution

Enable with `mutation_rate_evolution = TRUE`. Per-agent heritable
`mutation_sd`.

| Parameter                 | Default | Type    |
|:--------------------------|:--------|:--------|
| `mutation_rate_evolution` | FALSE   | logical |
| `mutation_sd_init_mean`   | 0.1     | numeric |
| `mutation_sd_min`         | 0.001   | numeric |
| `mutation_sd_max`         | 1       | numeric |

------------------------------------------------------------------------

## Phenotypic plasticity

Enable with `phenotypic_plasticity = TRUE`. The `plasticity` trait
scales how much an agent’s effective reproductive threshold depends on
local resource density.

| Parameter                 | Default | Type    |
|:--------------------------|:--------|:--------|
| `phenotypic_plasticity`   | FALSE   | logical |
| `plasticity_sense_radius` | 3       | integer |
| `plasticity_init_mean`    | 0.3     | numeric |
| `plasticity_mutation_sd`  | 0.03    | numeric |
| `plasticity_min`          | 0       | numeric |
| `plasticity_max`          | 1       | numeric |

------------------------------------------------------------------------

## Stress hypermutation

Enable with `stress_hypermutation = TRUE`. SOS-style mutation-rate spike
below `stress_threshold` energy.

| Parameter                    | Default | Type    |
|:-----------------------------|:--------|:--------|
| `stress_hypermutation`       | FALSE   | logical |
| `stress_mutation_multiplier` | 3       | numeric |
| `stress_threshold`           | 20      | numeric |

------------------------------------------------------------------------

## Clutch size (r/K)

Enable with `clutch_size_evolution = TRUE`. r/K trade-off between clutch
count and per-offspring investment.

| Parameter                 | Default | Type    |
|:--------------------------|:--------|:--------|
| `clutch_size_evolution`   | FALSE   | logical |
| `clutch_size_init_mean`   | 1       | numeric |
| `clutch_size_min`         | 1       | integer |
| `clutch_size_max`         | 5       | integer |
| `clutch_size_mutation_sd` | 0.3     | numeric |

------------------------------------------------------------------------

## Spatial sorting

Enable with `spatial_sorting = TRUE`. Requires
`dispersal_evolution = TRUE` and a bounded grid (`toroidal = FALSE`).

| Parameter                 | Default | Type    |
|:--------------------------|:--------|:--------|
| `spatial_sorting`         | FALSE   | logical |
| `sorting_front_threshold` | 0.75    | numeric |
| `sorting_mating_boost`    | 3       | numeric |

------------------------------------------------------------------------

## IFfolk inclusive fitness

Enable with `iffolk_selection = TRUE`. Haig 2000 / Fromhage & Jennions
2019 intragenomic-conflict + parliament suppression.

| Parameter                | Default | Type    |
|:-------------------------|:--------|:--------|
| `iffolk_selection`       | FALSE   | logical |
| `iffolk_r_min`           | 0.125   | numeric |
| `iffolk_radius`          | 5       | integer |
| `iffolk_transfer`        | 3       | numeric |
| `iffolk_min_energy`      | 60      | numeric |
| `parliament_suppression` | FALSE   | logical |
| `parliament_cost`        | 0.5     | numeric |

------------------------------------------------------------------------

## Complex landscape (forest world)

Enable with `complex_landscape = TRUE`. Three-layer foraging: ground
grass + shrubs + canopy. Wing-size evolves for canopy access.

| Parameter               | Default | Type    |
|:------------------------|:--------|:--------|
| `complex_landscape`     | FALSE   | logical |
| `shrub_density`         | 0.3     | numeric |
| `shrub_growth_rate`     | 0.03    | numeric |
| `shrub_energy`          | 20      | numeric |
| `canopy_density`        | 0.15    | numeric |
| `canopy_growth_rate`    | 0.005   | numeric |
| `canopy_energy`         | 50      | numeric |
| `canopy_threshold`      | 0.15    | numeric |
| `wing_size_init_mean`   | 0.08    | numeric |
| `wing_size_mutation_sd` | 0.05    | numeric |
| `wing_size_min`         | 0       | numeric |
| `wing_size_max`         | 1       | numeric |

------------------------------------------------------------------------

## Fixed patch

A single fixed-rich-cell helper for testing local-resource scenarios.

| Parameter            | Default      | Type    |
|:---------------------|:-------------|:--------|
| `fixed_patch`        | FALSE        | logical |
| `fixed_patch_value`  | 5            | numeric |
| `fixed_patch_x`      | NA_integer\_ | integer |
| `fixed_patch_y`      | NA_integer\_ | integer |
| `fixed_patch_radius` | 0            | integer |

------------------------------------------------------------------------

## Epigenetics

Enable with `epigenetics = TRUE`. Methylation inheritance on BNN sigma
(Jablonka & Lamb 2005).

| Parameter                      | Default | Type    |
|:-------------------------------|:--------|:--------|
| `epigenetics`                  | FALSE   | logical |
| `epigenetic_learning_coupling` | 0.1     | numeric |
| `epigenetic_inheritance`       | 0.5     | numeric |
| `epigenetic_effect_size`       | 0.2     | numeric |
| `methylation_rate`             | 0.001   | numeric |
| `demethylation_rate`           | 0.002   | numeric |

------------------------------------------------------------------------

## Speciation

Enable with `speciation = TRUE`. Genome-distance clustering +
reproductive isolation. See `paper-dieckmann-doebeli-1999`.

| Parameter                     | Default | Type    |
|:------------------------------|:--------|:--------|
| `speciation`                  | FALSE   | logical |
| `isolation_threshold`         | 0.5     | numeric |
| `speciation_cluster_interval` | 10      | integer |

------------------------------------------------------------------------

## Seasonal dynamics

| Parameter               | Default | Type    |
|:------------------------|:--------|:--------|
| `seasonal_amplitude`    | 0       | numeric |
| `season_length`         | 100     | integer |
| `seasonal_spatial_bias` | 0       | numeric |
| `winter_death_prob`     | 0       | numeric |

`seasonal_spatial_bias = TRUE` (0.5.18) flips the spatial grass
distribution between seasons — required for the Baldwin / plasticity
scenarios to demonstrate fluctuating selection.

------------------------------------------------------------------------

## Scavenging

Enable with `scavenging = TRUE`. Carcasses decay over time and can
transmit disease.

| Parameter                   | Default | Type    |
|:----------------------------|:--------|:--------|
| `scavenging`                | FALSE   | logical |
| `carrion_fraction`          | 0.5     | numeric |
| `carrion_decay_rate`        | 0.1     | numeric |
| `carrion_eat_gain`          | 3       | numeric |
| `carrion_transmission_prob` | 0       | numeric |

------------------------------------------------------------------------

## ANN regularisation

Optional weight regularisation on ANN brains.

| Parameter            | Default | Type      |
|:---------------------|:--------|:----------|
| `ann_regularization` | “none”  | character |

------------------------------------------------------------------------

## Wolf 2007 personality syndrome (0.7.0)

Enable with `personality_syndrome = TRUE`. See `paper-wolf2007` for the
boldness-aggressiveness syndrome reproduction and the Massol-Crochet /
McElreath critiques.

| Parameter                       | Default | Type    |
|:--------------------------------|:--------|:--------|
| `personality_syndrome`          | FALSE   | logical |
| `personality_beta`              | 1.25    | numeric |
| `personality_alpha`             | 0.005   | numeric |
| `personality_f_high`            | 3       | numeric |
| `personality_f_low`             | 2       | numeric |
| `personality_b`                 | 0.5     | numeric |
| `personality_gamma`             | 0.1     | numeric |
| `personality_V`                 | 0.5     | numeric |
| `personality_delta`             | 0.5     | numeric |
| `personality_antipred_per_tick` | 0.5     | numeric |
| `personality_hawkdove_per_tick` | 0.1     | numeric |
| `personality_hawkdove_radius`   | 1       | integer |
| `wolf_year1_repro_age`          | 50      | integer |
| `wolf_year2_repro_age`          | 100     | integer |
| `exploration_init_mean`         | 0.5     | numeric |
| `exploration_mutation_sd`       | 0.05    | numeric |
| `boldness_init_mean`            | 0.5     | numeric |
| `boldness_mutation_sd`          | 0.05    | numeric |
| `aggressiveness_init_mean`      | 0.5     | numeric |
| `aggressiveness_mutation_sd`    | 0.05    | numeric |

------------------------------------------------------------------------

## Trivers 1971 reciprocal altruism (0.7.0)

Enable with `reciprocal_altruism = TRUE`. Generous-TFT via three
heritable traits (initial / retaliation / forgiveness). See
`paper-trivers1971`.

| Parameter                             | Default | Type    |
|:--------------------------------------|:--------|:--------|
| `reciprocal_altruism`                 | FALSE   | logical |
| `reciprocity_cost`                    | 0.5     | numeric |
| `reciprocity_benefit_ratio`           | 2       | numeric |
| `reciprocity_interaction_rate`        | 0.1     | numeric |
| `reciprocity_radius`                  | 1       | integer |
| `partner_memory_size`                 | 8       | integer |
| `reciprocity_initial_init_mean`       | 0.5     | numeric |
| `reciprocity_initial_mutation_sd`     | 0.05    | numeric |
| `reciprocity_retaliation_init_mean`   | 0.5     | numeric |
| `reciprocity_retaliation_mutation_sd` | 0.05    | numeric |
| `reciprocity_forgiveness_init_mean`   | 0.1     | numeric |
| `reciprocity_forgiveness_mutation_sd` | 0.05    | numeric |

------------------------------------------------------------------------

## Wolf 2008 responsive personalities (0.7.0)

Enable with `responsive_personalities = TRUE`. Frequency-dependent
sampling: high-responsiveness agents override toward richer cells at a
per-tick metabolic cost. See `paper-wolf2008`.

| Parameter                    | Default | Type    |
|:-----------------------------|:--------|:--------|
| `responsive_personalities`   | FALSE   | logical |
| `responsiveness_cost`        | 0.4     | numeric |
| `responsiveness_init_mean`   | 0.5     | numeric |
| `responsiveness_mutation_sd` | 0.05    | numeric |

------------------------------------------------------------------------

## Logging and output

| Parameter     | Default | Type    |
|:--------------|:--------|:--------|
| `log_genomes` | FALSE   | logical |
| `log_freq`    | 1       | integer |

`log_genomes = TRUE` (wired in 0.7.x) captures every agent’s trait
vector each `log_freq` ticks — consumed by
[`plot_tsne_genomes()`](https://itchyshin.github.io/clade/reference/plot_tsne_genomes.md)
for population-genetic structure visualisations.

------------------------------------------------------------------------

## Inspecting defaults programmatically

``` r

defs <- default_specs()

# All parameter names
length(defs)
#> [1] 296

# First 10 parameters with their values
str(defs[1:10], max.level = 1, give.attr = FALSE)
#> List of 10
#>  $ grid_rows        : int 30
#>  $ grid_cols        : int 30
#>  $ toroidal         : logi TRUE
#>  $ random_tick_order: logi TRUE
#>  $ n_agents_init    : int 50
#>  $ max_agents       : int 500
#>  $ max_ticks        : int 500
#>  $ energy_init      : num 100
#>  $ energy_max       : num 200
#>  $ move_cost        : num 1
```

For an interactive view of all parameters at once, use
[`print_specs()`](https://itchyshin.github.io/clade/reference/print_specs.md).
