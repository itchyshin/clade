# Pretty-print all simulation parameters

Prints every parameter in a [`default_specs()`](default_specs.md) list
with its current value, grouped by biological theme. Pass a modified
specs list to see which parameters differ from the defaults.

## Usage

``` r
print_specs(specs = NULL, diff_only = FALSE)
```

## Arguments

- specs:

  A named list of simulation parameters (from
  [`default_specs()`](default_specs.md)). If `NULL` (default), prints
  the unmodified defaults.

- diff_only:

  Logical. If `TRUE`, only print parameters that differ from
  [`default_specs()`](default_specs.md) defaults. Useful for inspecting
  a customised spec list. Default `FALSE`.

## Value

Invisibly, the `specs` list (for piping).

## Examples

``` r
print_specs()
#> -- clade specs (232 parameters) --
#> 
#>   Grid & population
#>     grid_rows                              30
#>     grid_cols                              30
#>     n_agents_init                          50
#>     max_agents                             500
#>     max_ticks                              500
#>     random_seed                            NA
#> 
#>   Energy & metabolism
#>     energy_init                            100
#>     energy_max                             200
#>     move_cost                              1
#>     idle_cost                              0.5
#>     eat_gain                               5
#>     min_repro_energy                       120
#>     repro_cost                             30
#>     offspring_energy                       60
#>     starvation_threshold                   0
#> 
#>   Grass dynamics
#>     grass_init_prob                        0.5
#>     grass_rate                             0.05
#>     grass_max                              5
#> 
#>   Brain architecture
#>     brain_type                             bnn
#>     hidden_layers                          8
#> 
#>   Reproduction & sex
#>     ploidy                                 2
#>     mutation_sd                            0.1
#>     crossover_rate                         1
#>     min_repro_age                          0
#> 
#>   Life history
#>     max_age                                200
#>     life_history                           iteroparous
#>     senescence_rate                        0
#>     repro_senescence                       0
#> 
#>   Body size
#>     body_size_evolution                    FALSE
#>     body_size_init_mean                    1
#>     body_size_mutation_sd                  0.08
#>     body_size_min                          0.3
#>     body_size_max                          3
#> 
#>   Dispersal
#>     dispersal_evolution                    FALSE
#>     dispersal_init_mean                    0.1
#>     dispersal_mutation_sd                  0.02
#>     dispersal_min                          0
#>     dispersal_max                          0.5
#> 
#>   Kin selection
#>     kin_selection                          FALSE
#>     kin_altruism_r_min                     0.25
#>     kin_altruism_cost                      2
#>     kin_altruism_min_donor_energy          50
#> 
#>   Disease (SIR)
#>     disease                                FALSE
#>     transmission_prob                      0.1
#>     disease_duration                       10
#>     disease_energy_cost                    5
#>     disease_death_prob                     0.02
#>     immune_duration                        20
#>     disease_seed_prob                      0.01
#> 
#>   Predators
#>     n_predators_init                       0
#>     predator_energy_init                   150
#>     predator_attack_strength               40
#>     predator_min_repro_energy              200
#>     predator_max_agents                    50
#> 
#>   Niche construction
#>     niche_construction                     FALSE
#>     shelter_build_prob                     0.1
#>     shelter_min_energy                     80
#>     shelter_max_depth                      5
#> 
#>   Within-lifetime RL
#>     rl_mode                                none
#>     learning_rate                          0.01
#>     learning_rate_evolution                FALSE
#>     rl_update_freq                         1
#> 
#>   Social learning
#>     social_learning                        FALSE
#>     social_learning_freq                   10
#> 
#>   Signals & mate choice
#>     signal_dims                            0
#> 
#>   Mimicry & toxicity
#>     mimicry                                FALSE
#>     toxicity_init_mean                     0
#>     toxin_dose                             30
#> 
#>   Parental care
#>     parental_care                          FALSE
#> 
#>   Cooperative breeding
#>     cooperative_breeding                   FALSE
#>     helper_tendency_init_mean              0.1
#>     helper_tendency_mutation_sd            0.02
#> 
#>   Phenotypic plasticity
#>     phenotypic_plasticity                  FALSE
#>     plasticity_init_mean                   0.3
#>     plasticity_mutation_sd                 0.03
#> 
#>   Spatial sorting
#>     spatial_sorting                        FALSE
#>     sorting_front_threshold                0.75
#>     sorting_mating_boost                   3
#> 
#>   IFfolk incl. fitness
#>     iffolk_selection                       FALSE
#>     iffolk_r_min                           0.125
#>     iffolk_radius                          5
#>     iffolk_transfer                        3
#>     iffolk_min_energy                      60
#>     parliament_suppression                 FALSE
#>     parliament_cost                        0.5
#> 
#>   Complex landscape
#>     complex_landscape                      FALSE
#>     shrub_density                          0.3
#>     shrub_growth_rate                      0.03
#>     shrub_energy                           20
#>     canopy_density                         0.15
#>     canopy_growth_rate                     0.005
#>     canopy_energy                          50
#>     canopy_threshold                       0.15
#>     wing_size_init_mean                    0.08
#>     wing_size_mutation_sd                  0.05
#>     wing_size_min                          0
#>     wing_size_max                          1
#> 
#>   Logging & search
#>     log_genomes                            FALSE
#>     log_freq                               1
#> 
#>   Other
#>     toroidal                               TRUE
#>     input_radius                           1
#>     n_genes                                20
#>     transformer_history                    8
#>     transformer_heads                      2
#>     synthesis_max_rules                    10
#>     ann_regularization                     none
#>     ann_regularization_lambda              0.001
#>     brain_energy_mode                      activity
#>     brain_energy_base                      0.001
#>     brain_energy_activity                  0.5
#>     n_chromosomes                          1
#>     dominance_model                        additive
#>     mutation_rate_evolution                FALSE
#>     mutation_sd_init_mean                  0.1
#>     mutation_sd_min                        0.001
#>     mutation_sd_max                        1
#>     learning_rate_init_mean                0.01
#>     learning_rate_min                      0
#>     learning_rate_max                      0.5
#>     plasticity_cost                        0.05
#>     lamarckian                             FALSE
#>     epigenetics                            FALSE
#>     epigenetic_learning_coupling           0.1
#>     epigenetic_inheritance                 0.5
#>     epigenetic_effect_size                 0.2
#>     methylation_rate                       0.001
#>     demethylation_rate                     0.002
#>     life_history_evolution                 FALSE
#>     allee_threshold                        0
#>     brain_size_evolution                   FALSE
#>     brain_size_init_mean                   1
#>     brain_size_mutation_sd                 0.05
#>     brain_size_min                         0.1
#>     brain_size_max                         3
#>     brain_size_cost_scale                  1
#>     brain_size_sensing_exponent            0.3
#>     metabolic_rate_evolution               FALSE
#>     metabolic_rate_init_mean               1
#>     metabolic_rate_mutation_sd             0.05
#>     metabolic_rate_min                     0.1
#>     metabolic_rate_max                     5
#>     aging_rate_evolution                   FALSE
#>     aging_rate_init_mean                   1
#>     aging_rate_mutation_sd                 0.05
#>     aging_rate_min                         0.01
#>     aging_rate_max                         10
#>     immune_evolution                       FALSE
#>     immune_strength_init_mean              0.3
#>     immune_strength_mutation_sd            0.05
#>     immune_strength_min                    0
#>     immune_strength_max                    1
#>     kin_altruism_benefit                   10
#>     cooperation_evolution                  FALSE
#>     cooperation_multiplier                 2
#>     cooperation_init_mean                  0.5
#>     cooperation_mutation_sd                0.05
#>     cooperation_cost                       1
#>     dispersal_cost                         2
#>     habitat_preference_evolution           FALSE
#>     habitat_preference_init_mean           0
#>     habitat_preference_mutation_sd         0.03
#>     habitat_preference_min                 -1
#>     habitat_preference_max                 1
#>     habitat_preference_strength            0.5
#>     habitat_move_cost                      0
#>     group_defense                          FALSE
#>     group_defense_radius                   2
#>     group_defense_strength                 0.3
#>     seasonal_amplitude                     0
#>     season_length                          100
#>     winter_death_prob                      0
#>     care_cost_per_tick                     1
#>     feeding_rate                           5
#>     juvenile_independence_age              10
#>     juvenile_independence_energy           50
#>     max_clutch_size                        1
#>     helper_min_energy                      80
#>     helper_transfer                        5
#>     helper_kin_threshold                   0.25
#>     signal_cost                            0.1
#>     signal_evolution_drift                 TRUE
#>     signal_drift_sd                        0.01
#>     mate_choice_mode                       random
#>     mate_choice_strength                   0.5
#>     speciation                             FALSE
#>     isolation_threshold                    0.5
#>     speciation_cluster_interval            10
#>     predator_live_energy                   2
#>     predator_move_energy                   1
#>     predator_energy_gain                   30
#>     predator_min_repro_age                 5
#>     predator_mutation_sd                   0.1
#>     batesian_mimicry                       FALSE
#>     toxicity_cost_per_tick                 2
#>     signal_memory_rate                     0.3
#>     avoid_threshold                        0.5
#>     toxicity_mutation_sd                   0.05
#>     plasticity_sense_radius                3
#>     plasticity_min                         0
#>     plasticity_max                         1
#>     shelter_decay_prob                     0.05
#>     shelter_occupancy_bonus                0
#>     scavenging                             FALSE
#>     carrion_fraction                       0.5
#>     carrion_decay_rate                     0.1
#>     carrion_eat_gain                       3
#>     carrion_transmission_prob              0
#>     social_learning_rate                   0.1
#>     clutch_size_evolution                  FALSE
#>     clutch_size_init_mean                  1
#>     clutch_size_min                        1
#>     clutch_size_max                        5
#>     clutch_size_mutation_sd                0.3
#>     parental_investment_evolution          FALSE
#>     parental_investment_init_mean          0.5
#>     female_investment                      0.7
#>     male_repro_cost                        0.3
#>     stress_hypermutation                   FALSE
#>     stress_mutation_multiplier             3
#>     stress_threshold                       20
#>     senescence_shape                       2
#>     wall_density                           0
#>     wall_clusters                          TRUE
#>     world_evolution                        FALSE
#>     world_mutation_sd                      0.02
#>     fixed_patch                            FALSE
#>     fixed_patch_value                      5
#>     fixed_patch_x                          NA
#>     fixed_patch_y                          NA
#>     fixed_patch_radius                     0

s <- default_specs()
s$kin_selection <- TRUE
s$complex_landscape <- TRUE
print_specs(s, diff_only = TRUE)
#> -- clade specs (232 parameters) [diff only] --
#> 
#>   Kin selection
#>     kin_selection                          TRUE *
#> 
#>   Complex landscape
#>     complex_landscape                      TRUE *
```
