# Parameter Reference

This article lists every parameter in
[`default_specs()`](../reference/default_specs.md), grouped by
biological theme. For each parameter: the default value, type, and what
it controls.

Use `print_specs(diff_only = TRUE)` to see which parameters differ from
defaults in a given specs list.

``` r
s <- default_specs()
s$kin_selection      <- TRUE
s$complex_landscape  <- TRUE
print_specs(s, diff_only = TRUE)
```

------------------------------------------------------------------------

## Grid and population

| Parameter       | Default | Type    | Description                                 |
|-----------------|---------|---------|---------------------------------------------|
| `grid_rows`     | 20      | integer | Number of rows in the toroidal grid         |
| `grid_cols`     | 20      | integer | Number of columns                           |
| `n_agents_init` | 50      | integer | Starting population size                    |
| `max_agents`    | 300     | integer | Hard population cap (no births above this)  |
| `max_ticks`     | 300     | integer | Simulation length                           |
| `random_seed`   | 42      | integer | Random seed (set to reproduce runs exactly) |

------------------------------------------------------------------------

## Energy and metabolism

| Parameter              | Default | Type    | Description                          |
|------------------------|---------|---------|--------------------------------------|
| `energy_init`          | 30.0    | numeric | Starting energy for each agent       |
| `energy_max`           | 200.0   | numeric | Energy cap per agent                 |
| `move_cost`            | 1.0     | numeric | Energy cost per move action          |
| `idle_cost`            | 0.5     | numeric | Energy cost per tick of inaction     |
| `eat_gain`             | 20.0    | numeric | Energy gained from eating grass      |
| `min_repro_energy`     | 80.0    | numeric | Energy threshold to reproduce        |
| `repro_cost`           | 20.0    | numeric | Energy cost to parent per offspring  |
| `offspring_energy`     | 20.0    | numeric | Starting energy for offspring        |
| `starvation_threshold` | 0.0     | numeric | Die if energy falls to or below this |

------------------------------------------------------------------------

## Grass dynamics

| Parameter         | Default | Type            | Description                                  |
|-------------------|---------|-----------------|----------------------------------------------|
| `grass_init_prob` | 0.5     | numeric $$0,1$$ | Fraction of cells with grass at tick 1       |
| `grass_rate`      | 0.10    | numeric $$0,1$$ | Per-tick regrowth probability on empty cells |
| `grass_max`       | 1.0     | numeric         | Maximum grass per cell                       |

------------------------------------------------------------------------

## Neural architecture

| Parameter       | Default    | Options                                      | Description                                               |
|-----------------|------------|----------------------------------------------|-----------------------------------------------------------|
| `brain_type`    | `"bnn"`    | bnn, ann, ctrnn, grn, transformer, synthesis | Neural network architecture                               |
| `hidden_layers` | `c(16, 8)` | integer vector                               | Hidden layer sizes                                        |
| `n_inputs`      | auto       | integer                                      | Sensory input vector size (set by `create_environment()`) |
| `n_outputs`     | 4          | integer                                      | Action output size (N/E/S/W)                              |

The six brain types differ in expressive power and computational cost:

- **bnn** (Bayesian neural network): default; learns a distribution over
  weights.
- **ann**: standard multilayer perceptron.
- **ctrnn**: continuous-time recurrent network; suitable for temporally
  extended tasks.
- **grn**: gene regulatory network topology; sparse, biologically
  motivated.
- **transformer**: self-attention architecture; highest capacity,
  slowest.
- **synthesis**: symbolic rule extraction from evolved weights.

------------------------------------------------------------------------

## Reproduction and genetics

| Parameter        | Default    | Type            | Description                               |
|------------------|------------|-----------------|-------------------------------------------|
| `ploidy`         | 2          | 1 or 2          | Diploid (default) or haploid              |
| `sex_ratio`      | 0.5        | numeric $$0,1$$ | Fraction of agents that are female        |
| `mating_system`  | `"random"` | character       | Random, monogamy, polygyny, polyandry     |
| `mutation_sd`    | 0.05       | numeric         | Gaussian noise on genome weights          |
| `crossover_rate` | 0.1        | numeric $$0,1$$ | Per-locus crossover probability (diploid) |
| `min_repro_age`  | 0          | integer         | Minimum age to reproduce                  |
| `max_repro_age`  | Inf        | integer         | Maximum age to reproduce (Inf = no limit) |

------------------------------------------------------------------------

## Life history

| Parameter          | Default         | Options                  | Description                          |
|--------------------|-----------------|--------------------------|--------------------------------------|
| `max_age`          | 500             | integer                  | Die if age exceeds this              |
| `life_history`     | `"iteroparous"` | iteroparous, semelparous | Semelparous: reproduce once then die |
| `senescence_rate`  | 0.0             | numeric                  | Gompertz mortality scaling with age  |
| `repro_senescence` | 0.0             | numeric                  | Age-related fertility decline rate   |

------------------------------------------------------------------------

## Body size evolution

Enable with `body_size_evolution = TRUE`.

| Parameter               | Default | Description                     |
|-------------------------|---------|---------------------------------|
| `body_size_evolution`   | FALSE   | Enable                          |
| `body_size_init_mean`   | 1.0     | Starting value (relative units) |
| `body_size_mutation_sd` | 0.05    | Mutation noise                  |
| `body_size_min`         | 0.1     | Lower clamp                     |
| `body_size_max`         | 5.0     | Upper clamp                     |

------------------------------------------------------------------------

## Dispersal evolution

Enable with `dispersal_evolution = TRUE`. Combine with
`spatial_sorting = TRUE` for invasion-front dynamics.

| Parameter               | Default | Description                    |
|-------------------------|---------|--------------------------------|
| `dispersal_evolution`   | FALSE   | Enable heritable dispersal     |
| `dispersal_init_mean`   | 0.5     | Starting dispersal probability |
| `dispersal_mutation_sd` | 0.05    | Mutation noise                 |
| `dispersal_min`         | 0.0     | Minimum clamp                  |
| `dispersal_max`         | 1.0     | Maximum clamp                  |

------------------------------------------------------------------------

## Kin selection

Enable with `kin_selection = TRUE`.

| Parameter                       | Default | Description                            |
|---------------------------------|---------|----------------------------------------|
| `kin_selection`                 | FALSE   | Enable kin altruism                    |
| `kin_altruism_r_min`            | 0.25    | Minimum pedigree relatedness to donate |
| `kin_altruism_cost`             | 2.0     | Energy transferred per altruistic act  |
| `kin_altruism_min_donor_energy` | 50.0    | Donor energy floor                     |

------------------------------------------------------------------------

## SIR disease

Enable with `disease = TRUE`.

| Parameter             | Default | Description                                  |
|-----------------------|---------|----------------------------------------------|
| `disease`             | FALSE   | Enable SIR dynamics                          |
| `transmission_prob`   | 0.15    | Per-tick transmission probability            |
| `disease_energy_cost` | 5.0     | Energy cost per tick while infected          |
| `disease_duration`    | 10      | Ticks until recovery                         |
| `immune_duration`     | 20      | Ticks of post-recovery immunity              |
| `disease_death_prob`  | 0.01    | Additional per-tick mortality while infected |
| `disease_seed_prob`   | 0.02    | Fraction of agents infected at tick 1        |

------------------------------------------------------------------------

## Predators

Enable with `n_predators_init > 0`.

| Parameter                   | Default | Description                     |
|-----------------------------|---------|---------------------------------|
| `n_predators_init`          | 0       | Starting predator count         |
| `predator_energy_init`      | 60.0    | Starting energy for predators   |
| `predator_attack_strength`  | 10.0    | Damage dealt to prey per attack |
| `predator_min_repro_energy` | 100.0   | Predator reproduction threshold |
| `predator_max_agents`       | 50      | Predator population cap         |

------------------------------------------------------------------------

## Niche construction

Enable with `niche_construction = TRUE`.

| Parameter                 | Default | Description                                                                                                                                           |
|---------------------------|---------|-------------------------------------------------------------------------------------------------------------------------------------------------------|
| `niche_construction`      | FALSE   | Enable shelter building                                                                                                                               |
| `shelter_build_prob`      | 0.1     | Per-tick build probability (when energy sufficient)                                                                                                   |
| `shelter_min_energy`      | 40.0    | Minimum donor energy to build                                                                                                                         |
| `shelter_max_depth`       | 5       | Maximum shelter units per cell                                                                                                                        |
| `shelter_decay_rate`      | 0.02    | Fraction of shelters lost per tick                                                                                                                    |
| `shelter_occupancy_bonus` | 0.0     | (0.3.0) When \> 0, agents on a shelter cell receive `bonus × depth` energy per tick — the Odling-Smee, Laland & Feldman (2003) heritable-niche effect |

------------------------------------------------------------------------

## Within-lifetime RL

Enable with `rl_mode = "actor_critic"`.

| Parameter                 | Default  | Description                               |
|---------------------------|----------|-------------------------------------------|
| `rl_mode`                 | `"none"` | `"actor_critic"` or `"hebbian"`           |
| `learning_rate`           | 0.01     | Output-layer update step size             |
| `learning_rate_evolution` | FALSE    | Allow learning rate to evolve genetically |
| `rl_update_freq`          | 5        | Ticks between RL updates                  |

------------------------------------------------------------------------

## Social learning

Enable with `social_learning = TRUE`.

| Parameter                | Default | Description                              |
|--------------------------|---------|------------------------------------------|
| `social_learning`        | FALSE   | Enable copying successful neighbours     |
| `social_learning_freq`   | 10      | Ticks between learning events            |
| `social_learning_radius` | 3       | Neighbourhood radius for model selection |

------------------------------------------------------------------------

## Signals and mate choice

| Parameter                | Default | Description                               |
|--------------------------|---------|-------------------------------------------|
| `signal_dims`            | 2       | Dimensionality of heritable signal vector |
| `signal_mutation_sd`     | 0.05    | Signal mutation noise                     |
| `preference_mutation_sd` | 0.05    | Mate-preference mutation noise            |

------------------------------------------------------------------------

## Mimicry and toxicity

Enable with `mimicry = TRUE`.

| Parameter                | Default | Description                                                                                                                                             |
|--------------------------|---------|---------------------------------------------------------------------------------------------------------------------------------------------------------|
| `mimicry`                | FALSE   | Enable toxicity and predator learning (Müllerian by default)                                                                                            |
| `batesian_mimicry`       | FALSE   | (0.3.0) Enable Batesian mimicry: palatable prey (toxicity = 0) exploit learned aversion; predator-betrayal decay prevents runaway cheating (Bates 1862) |
| `toxicity_init_mean`     | 0.0     | Starting toxicity                                                                                                                                       |
| `toxicity_cost_per_tick` | 2.0     | Per-tick energy cost for toxicity \> 0 (raised from 0.5 in 0.3.0 for Zahavi-handicap honesty)                                                           |
| `toxin_dose`             | 2.0     | Damage per toxicity unit per attack                                                                                                                     |
| `signal_memory`          | 20      | Predator memory window (Rescorla-Wagner)                                                                                                                |

------------------------------------------------------------------------

## Parental care

Enable with `parental_care = TRUE`.

| Parameter              | Default | Description                              |
|------------------------|---------|------------------------------------------|
| `parental_care`        | FALSE   | Enable carried offspring                 |
| `care_duration`        | 5       | Ticks offspring are carried              |
| `care_energy_cost`     | 2.0     | Parent energy cost per juvenile per tick |
| `juvenile_energy_gain` | 3.0     | Energy transferred to juvenile per tick  |

------------------------------------------------------------------------

## Cooperative breeding

Enable with `cooperative_breeding = TRUE`. Usually combined with
`iffolk_selection = TRUE`.

| Parameter                     | Default | Description                    |
|-------------------------------|---------|--------------------------------|
| `cooperative_breeding`        | FALSE   | Enable `helper_tendency` trait |
| `helper_tendency_init_mean`   | 0.2     | Starting helper tendency       |
| `helper_tendency_mutation_sd` | 0.05    | Mutation noise                 |

------------------------------------------------------------------------

## Phenotypic plasticity

Enable with `phenotypic_plasticity = TRUE`.

| Parameter                | Default | Description             |
|--------------------------|---------|-------------------------|
| `phenotypic_plasticity`  | FALSE   | Enable plasticity trait |
| `plasticity_init_mean`   | 0.5     | Starting plasticity     |
| `plasticity_mutation_sd` | 0.05    | Mutation noise          |

------------------------------------------------------------------------

## Spatial sorting

Enable with `spatial_sorting = TRUE`. Requires
`dispersal_evolution = TRUE`.

| Parameter                 | Default | Description                                |
|---------------------------|---------|--------------------------------------------|
| `spatial_sorting`         | FALSE   | Enable invasion-front mating assortment    |
| `sorting_front_threshold` | 0.75    | Fraction from front to define “front zone” |
| `sorting_mating_boost`    | 3.0     | Mating encounter fold-increase at front    |

------------------------------------------------------------------------

## IFfolk inclusive fitness

Enable with `iffolk_selection = TRUE`.

| Parameter                | Default | Description                                        |
|--------------------------|---------|----------------------------------------------------|
| `iffolk_selection`       | FALSE   | Enable energy transfers to relatives               |
| `iffolk_r_min`           | 0.125   | Minimum relatedness (cousins and closer)           |
| `iffolk_radius`          | 5       | Neighbourhood radius for kin search                |
| `iffolk_transfer`        | 3.0     | Energy transferred per act                         |
| `iffolk_min_energy`      | 60.0    | Donor energy floor                                 |
| `parliament_suppression` | FALSE   | Penalise defectors among cooperators               |
| `parliament_cost`        | 0.5     | Energy cost for defectors per cooperator neighbour |

------------------------------------------------------------------------

## Complex landscape (forest world)

Enable with `complex_landscape = TRUE`.

| Parameter               | Default | Description                         |
|-------------------------|---------|-------------------------------------|
| `complex_landscape`     | FALSE   | Enable 3-layer habitat              |
| `shrub_density`         | 0.35    | Fraction of cells with shrubs       |
| `shrub_energy`          | 25.0    | Energy gained from shrubs           |
| `shrub_growth_rate`     | 0.04    | Shrub regrowth rate per tick        |
| `canopy_density`        | 0.15    | Fraction of cells with canopy       |
| `canopy_energy`         | 55.0    | Energy gained from canopy           |
| `canopy_growth_rate`    | 0.005   | Canopy regrowth rate                |
| `canopy_threshold`      | 0.6     | Minimum wing_size for canopy access |
| `wing_size_init_mean`   | 0.1     | Starting wing size                  |
| `wing_size_mutation_sd` | 0.05    | Wing size mutation noise            |
| `wing_size_min`         | 0.0     | Lower clamp                         |
| `wing_size_max`         | 1.0     | Upper clamp                         |

------------------------------------------------------------------------

## Logging and output

| Parameter       | Default | Description                             |
|-----------------|---------|-----------------------------------------|
| `log_genomes`   | FALSE   | Log full genome matrices (large output) |
| `log_deaths`    | TRUE    | Record every agent death                |
| `log_freq`      | 1       | Ticks between progress log entries      |
| `verbose_julia` | FALSE   | Print Julia-side debug messages         |

------------------------------------------------------------------------

## Inspecting defaults programmatically

``` r
defs <- default_specs()
# All parameter names
names(defs)
#>   [1] "grid_rows"                      "grid_cols"                     
#>   [3] "toroidal"                       "n_agents_init"                 
#>   [5] "max_agents"                     "max_ticks"                     
#>   [7] "energy_init"                    "energy_max"                    
#>   [9] "move_cost"                      "idle_cost"                     
#>  [11] "eat_gain"                       "max_bite"                      
#>  [13] "min_repro_energy"               "repro_cost_mode"               
#>  [15] "repro_cost"                     "repro_cost_fraction"           
#>  [17] "offspring_energy_mode"          "offspring_energy"              
#>  [19] "offspring_energy_fraction"      "starvation_threshold"          
#>  [21] "max_age_scales_with_metabolism" "grass_init_prob"               
#>  [23] "grass_rate"                     "grass_max"                     
#>  [25] "brain_type"                     "hidden_layers"                 
#>  [27] "input_radius"                   "n_genes"                       
#>  [29] "transformer_history"            "transformer_heads"             
#>  [31] "synthesis_max_rules"            "ann_weight_values"             
#>  [33] "ann_regularization"             "ann_regularization_lambda"     
#>  [35] "brain_energy_mode"              "brain_energy_base"             
#>  [37] "brain_energy_activity"          "brain_energy_sigma_scale"      
#>  [39] "bnn_sigma_init"                 "bnn_sigma_min"                 
#>  [41] "bnn_sigma_source"               "bnn_sample_freq"               
#>  [43] "ploidy"                         "n_chromosomes"                 
#>  [45] "crossover_rate"                 "dominance_model"               
#>  [47] "mutation_sd"                    "mutation_rate_evolution"       
#>  [49] "mutation_sd_init_mean"          "mutation_sd_min"               
#>  [51] "mutation_sd_max"                "rl_mode"                       
#>  [53] "learning_rate"                  "learning_rate_evolution"       
#>  [55] "learning_rate_init_mean"        "learning_rate_min"             
#>  [57] "learning_rate_max"              "plasticity_cost"               
#>  [59] "rl_update_freq"                 "lamarckian"                    
#>  [61] "epigenetics"                    "epigenetic_learning_coupling"  
#>  [63] "epigenetic_inheritance"         "epigenetic_effect_size"        
#>  [65] "methylation_rate"               "demethylation_rate"            
#>  [67] "life_history"                   "max_age"                       
#>  [69] "senescence_rate"                "repro_senescence"              
#>  [71] "life_history_evolution"         "allee_threshold"               
#>  [73] "body_size_evolution"            "body_size_init_mean"           
#>  [75] "body_size_mutation_sd"          "body_size_min"                 
#>  [77] "body_size_max"                  "brain_size_evolution"          
#>  [79] "brain_size_init_mean"           "brain_size_mutation_sd"        
#>  [81] "brain_size_min"                 "brain_size_max"                
#>  [83] "brain_size_cost_scale"          "brain_size_sensing_exponent"   
#>  [85] "metabolic_rate_evolution"       "metabolic_rate_init_mean"      
#>  [87] "metabolic_rate_mutation_sd"     "metabolic_rate_min"            
#>  [89] "metabolic_rate_max"             "aging_rate_evolution"          
#>  [91] "aging_rate_init_mean"           "aging_rate_mutation_sd"        
#>  [93] "aging_rate_min"                 "aging_rate_max"                
#>  [95] "immune_evolution"               "immune_strength_init_mean"     
#>  [97] "immune_strength_mutation_sd"    "immune_strength_min"           
#>  [99] "immune_strength_max"            "disease"                       
#> [101] "disease_seed_prob"              "transmission_prob"             
#> [103] "disease_duration"               "immune_duration"               
#> [105] "disease_energy_cost"            "disease_death_prob"            
#> [107] "kin_selection"                  "kin_altruism_cost"             
#> [109] "kin_altruism_benefit"           "kin_altruism_r_min"            
#> [111] "kin_altruism_min_donor_energy"  "cooperation_evolution"         
#> [113] "cooperation_multiplier"         "cooperation_init_mean"         
#> [115] "cooperation_mutation_sd"        "cooperation_cost"              
#> [117] "dispersal_evolution"            "dispersal_cost"                
#> [119] "dispersal_init_mean"            "dispersal_mutation_sd"         
#> [121] "dispersal_min"                  "dispersal_max"                 
#> [123] "habitat_preference_evolution"   "habitat_preference_init_mean"  
#> [125] "habitat_preference_mutation_sd" "habitat_preference_min"        
#> [127] "habitat_preference_max"         "habitat_preference_strength"   
#> [129] "habitat_move_cost"              "group_defense"                 
#> [131] "group_defense_radius"           "group_defense_strength"        
#> [133] "seasonal_amplitude"             "season_length"                 
#> [135] "winter_death_prob"              "parental_care"                 
#> [137] "care_cost_per_tick"             "feeding_rate"                  
#> [139] "juvenile_independence_age"      "juvenile_independence_energy"  
#> [141] "max_clutch_size"                "cooperative_breeding"          
#> [143] "helper_min_energy"              "helper_transfer"               
#> [145] "helper_kin_threshold"           "helper_tendency_init_mean"     
#> [147] "helper_tendency_mutation_sd"    "signal_dims"                   
#> [149] "signal_cost"                    "signal_evolution_drift"        
#> [151] "signal_drift_sd"                "mate_choice_mode"              
#> [153] "mate_choice_strength"           "speciation"                    
#> [155] "isolation_threshold"            "speciation_cluster_interval"   
#> [157] "n_predators_init"               "predator_energy_init"          
#> [159] "predator_live_energy"           "predator_move_energy"          
#> [161] "predator_attack_strength"       "predator_energy_gain"          
#> [163] "predator_min_repro_energy"      "predator_min_repro_age"        
#> [165] "predator_mutation_sd"           "predator_max_agents"           
#> [167] "mimicry"                        "batesian_mimicry"              
#> [169] "toxicity_cost_per_tick"         "toxin_dose"                    
#> [171] "signal_memory_rate"             "avoid_threshold"               
#> [173] "toxicity_init_mean"             "toxicity_mutation_sd"          
#> [175] "phenotypic_plasticity"          "plasticity_sense_radius"       
#> [177] "plasticity_init_mean"           "plasticity_mutation_sd"        
#> [179] "plasticity_min"                 "plasticity_max"                
#> [181] "niche_construction"             "shelter_build_prob"            
#> [183] "shelter_max_depth"              "shelter_min_energy"            
#> [185] "shelter_decay_prob"             "shelter_occupancy_bonus"       
#> [187] "scavenging"                     "carrion_fraction"              
#> [189] "carrion_decay_rate"             "carrion_eat_gain"              
#> [191] "carrion_transmission_prob"      "social_learning"               
#> [193] "social_learning_freq"           "social_learning_rate"          
#> [195] "clutch_size_evolution"          "clutch_size_init_mean"         
#> [197] "clutch_size_min"                "clutch_size_max"               
#> [199] "clutch_size_mutation_sd"        "parental_investment_evolution" 
#> [201] "parental_investment_init_mean"  "female_investment"             
#> [203] "male_repro_cost"                "stress_hypermutation"          
#> [205] "stress_mutation_multiplier"     "stress_threshold"              
#> [207] "senescence_shape"               "min_repro_age"                 
#> [209] "wall_density"                   "wall_clusters"                 
#> [211] "world_evolution"                "world_mutation_sd"             
#> [213] "world_params_to_evolve"         "complex_landscape"             
#> [215] "shrub_density"                  "shrub_growth_rate"             
#> [217] "shrub_energy"                   "canopy_density"                
#> [219] "canopy_growth_rate"             "canopy_energy"                 
#> [221] "canopy_threshold"               "wing_size_init_mean"           
#> [223] "wing_size_mutation_sd"          "wing_size_min"                 
#> [225] "wing_size_max"                  "spatial_sorting"               
#> [227] "sorting_front_threshold"        "sorting_mating_boost"          
#> [229] "iffolk_selection"               "iffolk_r_min"                  
#> [231] "iffolk_radius"                  "iffolk_transfer"               
#> [233] "iffolk_min_energy"              "parliament_suppression"        
#> [235] "parliament_cost"                "fixed_patch"                   
#> [237] "fixed_patch_value"              "fixed_patch_x"                 
#> [239] "fixed_patch_y"                  "fixed_patch_radius"            
#> [241] "log_freq"                       "log_genomes"                   
#> [243] "random_seed"
# All parameters with their values
str(defs, max.level = 1, give.attr = FALSE)
#> List of 243
#>  $ grid_rows                     : int 30
#>  $ grid_cols                     : int 30
#>  $ toroidal                      : logi TRUE
#>  $ n_agents_init                 : int 50
#>  $ max_agents                    : int 500
#>  $ max_ticks                     : int 500
#>  $ energy_init                   : num 100
#>  $ energy_max                    : num 200
#>  $ move_cost                     : num 1
#>  $ idle_cost                     : num 0.5
#>  $ eat_gain                      : num 5
#>  $ max_bite                      : num 2
#>  $ min_repro_energy              : num 120
#>  $ repro_cost_mode               : chr "proportional"
#>  $ repro_cost                    : num 30
#>  $ repro_cost_fraction           : num 0.5
#>  $ offspring_energy_mode         : chr "proportional"
#>  $ offspring_energy              : num 60
#>  $ offspring_energy_fraction     : num 0.25
#>  $ starvation_threshold          : num 0
#>  $ max_age_scales_with_metabolism: logi FALSE
#>  $ grass_init_prob               : num 0.5
#>  $ grass_rate                    : num 0.05
#>  $ grass_max                     : num 5
#>  $ brain_type                    : chr "bnn"
#>  $ hidden_layers                 : int 8
#>  $ input_radius                  : int 1
#>  $ n_genes                       : int 20
#>  $ transformer_history           : int 8
#>  $ transformer_heads             : int 2
#>  $ synthesis_max_rules           : int 10
#>  $ ann_weight_values             : NULL
#>  $ ann_regularization            : chr "none"
#>  $ ann_regularization_lambda     : num 0.001
#>  $ brain_energy_mode             : chr "activity"
#>  $ brain_energy_base             : num 0.001
#>  $ brain_energy_activity         : num 0.5
#>  $ brain_energy_sigma_scale      : num 0
#>  $ bnn_sigma_init                : num 0.5
#>  $ bnn_sigma_min                 : num 0.01
#>  $ bnn_sigma_source              : chr "heterozygosity"
#>  $ bnn_sample_freq               : int 1
#>  $ ploidy                        : int 2
#>  $ n_chromosomes                 : int 1
#>  $ crossover_rate                : num 1
#>  $ dominance_model               : chr "additive"
#>  $ mutation_sd                   : num 0.1
#>  $ mutation_rate_evolution       : logi FALSE
#>  $ mutation_sd_init_mean         : num 0.1
#>  $ mutation_sd_min               : num 0.001
#>  $ mutation_sd_max               : num 1
#>  $ rl_mode                       : chr "none"
#>  $ learning_rate                 : num 0.01
#>  $ learning_rate_evolution       : logi FALSE
#>  $ learning_rate_init_mean       : num 0.01
#>  $ learning_rate_min             : num 0
#>  $ learning_rate_max             : num 0.5
#>  $ plasticity_cost               : num 0.05
#>  $ rl_update_freq                : int 1
#>  $ lamarckian                    : logi FALSE
#>  $ epigenetics                   : logi FALSE
#>  $ epigenetic_learning_coupling  : num 0.1
#>  $ epigenetic_inheritance        : num 0.5
#>  $ epigenetic_effect_size        : num 0.2
#>  $ methylation_rate              : num 0.001
#>  $ demethylation_rate            : num 0.002
#>  $ life_history                  : chr "iteroparous"
#>  $ max_age                       : int 200
#>  $ senescence_rate               : num 0
#>  $ repro_senescence              : num 0
#>  $ life_history_evolution        : logi FALSE
#>  $ allee_threshold               : int 0
#>  $ body_size_evolution           : logi FALSE
#>  $ body_size_init_mean           : num 1
#>  $ body_size_mutation_sd         : num 0.08
#>  $ body_size_min                 : num 0.3
#>  $ body_size_max                 : num 3
#>  $ brain_size_evolution          : logi FALSE
#>  $ brain_size_init_mean          : num 1
#>  $ brain_size_mutation_sd        : num 0.05
#>  $ brain_size_min                : num 0.1
#>  $ brain_size_max                : num 3
#>  $ brain_size_cost_scale         : num 1
#>  $ brain_size_sensing_exponent   : num 0.3
#>  $ metabolic_rate_evolution      : logi FALSE
#>  $ metabolic_rate_init_mean      : num 1
#>  $ metabolic_rate_mutation_sd    : num 0.05
#>  $ metabolic_rate_min            : num 0.1
#>  $ metabolic_rate_max            : num 5
#>  $ aging_rate_evolution          : logi FALSE
#>  $ aging_rate_init_mean          : num 1
#>  $ aging_rate_mutation_sd        : num 0.05
#>  $ aging_rate_min                : num 0.01
#>  $ aging_rate_max                : num 10
#>  $ immune_evolution              : logi FALSE
#>  $ immune_strength_init_mean     : num 0.3
#>  $ immune_strength_mutation_sd   : num 0.05
#>  $ immune_strength_min           : num 0
#>  $ immune_strength_max           : num 1
#>   [list output truncated]
```
