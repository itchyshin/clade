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
#>  [37] "brain_energy_activity"          "bnn_sigma_init"                
#>  [39] "bnn_sigma_min"                  "bnn_sigma_source"              
#>  [41] "bnn_sample_freq"                "ploidy"                        
#>  [43] "n_chromosomes"                  "crossover_rate"                
#>  [45] "dominance_model"                "mutation_sd"                   
#>  [47] "mutation_rate_evolution"        "mutation_sd_init_mean"         
#>  [49] "mutation_sd_min"                "mutation_sd_max"               
#>  [51] "rl_mode"                        "learning_rate"                 
#>  [53] "learning_rate_evolution"        "learning_rate_init_mean"       
#>  [55] "learning_rate_min"              "learning_rate_max"             
#>  [57] "plasticity_cost"                "rl_update_freq"                
#>  [59] "lamarckian"                     "epigenetics"                   
#>  [61] "epigenetic_learning_coupling"   "epigenetic_inheritance"        
#>  [63] "epigenetic_effect_size"         "methylation_rate"              
#>  [65] "demethylation_rate"             "life_history"                  
#>  [67] "max_age"                        "senescence_rate"               
#>  [69] "repro_senescence"               "life_history_evolution"        
#>  [71] "allee_threshold"                "body_size_evolution"           
#>  [73] "body_size_init_mean"            "body_size_mutation_sd"         
#>  [75] "body_size_min"                  "body_size_max"                 
#>  [77] "brain_size_evolution"           "brain_size_init_mean"          
#>  [79] "brain_size_mutation_sd"         "brain_size_min"                
#>  [81] "brain_size_max"                 "brain_size_cost_scale"         
#>  [83] "brain_size_sensing_exponent"    "metabolic_rate_evolution"      
#>  [85] "metabolic_rate_init_mean"       "metabolic_rate_mutation_sd"    
#>  [87] "metabolic_rate_min"             "metabolic_rate_max"            
#>  [89] "aging_rate_evolution"           "aging_rate_init_mean"          
#>  [91] "aging_rate_mutation_sd"         "aging_rate_min"                
#>  [93] "aging_rate_max"                 "immune_evolution"              
#>  [95] "immune_strength_init_mean"      "immune_strength_mutation_sd"   
#>  [97] "immune_strength_min"            "immune_strength_max"           
#>  [99] "disease"                        "disease_seed_prob"             
#> [101] "transmission_prob"              "disease_duration"              
#> [103] "immune_duration"                "disease_energy_cost"           
#> [105] "disease_death_prob"             "kin_selection"                 
#> [107] "kin_altruism_cost"              "kin_altruism_benefit"          
#> [109] "kin_altruism_r_min"             "kin_altruism_min_donor_energy" 
#> [111] "cooperation_evolution"          "cooperation_multiplier"        
#> [113] "cooperation_init_mean"          "cooperation_mutation_sd"       
#> [115] "cooperation_cost"               "dispersal_evolution"           
#> [117] "dispersal_cost"                 "dispersal_init_mean"           
#> [119] "dispersal_mutation_sd"          "dispersal_min"                 
#> [121] "dispersal_max"                  "habitat_preference_evolution"  
#> [123] "habitat_preference_init_mean"   "habitat_preference_mutation_sd"
#> [125] "habitat_preference_min"         "habitat_preference_max"        
#> [127] "habitat_preference_strength"    "habitat_move_cost"             
#> [129] "group_defense"                  "group_defense_radius"          
#> [131] "group_defense_strength"         "seasonal_amplitude"            
#> [133] "season_length"                  "winter_death_prob"             
#> [135] "parental_care"                  "care_cost_per_tick"            
#> [137] "feeding_rate"                   "juvenile_independence_age"     
#> [139] "juvenile_independence_energy"   "max_clutch_size"               
#> [141] "cooperative_breeding"           "helper_min_energy"             
#> [143] "helper_transfer"                "helper_kin_threshold"          
#> [145] "helper_tendency_init_mean"      "helper_tendency_mutation_sd"   
#> [147] "signal_dims"                    "signal_cost"                   
#> [149] "signal_evolution_drift"         "signal_drift_sd"               
#> [151] "mate_choice_mode"               "mate_choice_strength"          
#> [153] "speciation"                     "isolation_threshold"           
#> [155] "speciation_cluster_interval"    "n_predators_init"              
#> [157] "predator_energy_init"           "predator_live_energy"          
#> [159] "predator_move_energy"           "predator_attack_strength"      
#> [161] "predator_energy_gain"           "predator_min_repro_energy"     
#> [163] "predator_min_repro_age"         "predator_mutation_sd"          
#> [165] "predator_max_agents"            "mimicry"                       
#> [167] "batesian_mimicry"               "toxicity_cost_per_tick"        
#> [169] "toxin_dose"                     "signal_memory_rate"            
#> [171] "avoid_threshold"                "toxicity_init_mean"            
#> [173] "toxicity_mutation_sd"           "phenotypic_plasticity"         
#> [175] "plasticity_sense_radius"        "plasticity_init_mean"          
#> [177] "plasticity_mutation_sd"         "plasticity_min"                
#> [179] "plasticity_max"                 "niche_construction"            
#> [181] "shelter_build_prob"             "shelter_max_depth"             
#> [183] "shelter_min_energy"             "shelter_decay_prob"            
#> [185] "shelter_occupancy_bonus"        "scavenging"                    
#> [187] "carrion_fraction"               "carrion_decay_rate"            
#> [189] "carrion_eat_gain"               "carrion_transmission_prob"     
#> [191] "social_learning"                "social_learning_freq"          
#> [193] "social_learning_rate"           "clutch_size_evolution"         
#> [195] "clutch_size_init_mean"          "clutch_size_min"               
#> [197] "clutch_size_max"                "clutch_size_mutation_sd"       
#> [199] "parental_investment_evolution"  "parental_investment_init_mean" 
#> [201] "female_investment"              "male_repro_cost"               
#> [203] "stress_hypermutation"           "stress_mutation_multiplier"    
#> [205] "stress_threshold"               "senescence_shape"              
#> [207] "min_repro_age"                  "wall_density"                  
#> [209] "wall_clusters"                  "world_evolution"               
#> [211] "world_mutation_sd"              "world_params_to_evolve"        
#> [213] "complex_landscape"              "shrub_density"                 
#> [215] "shrub_growth_rate"              "shrub_energy"                  
#> [217] "canopy_density"                 "canopy_growth_rate"            
#> [219] "canopy_energy"                  "canopy_threshold"              
#> [221] "wing_size_init_mean"            "wing_size_mutation_sd"         
#> [223] "wing_size_min"                  "wing_size_max"                 
#> [225] "spatial_sorting"                "sorting_front_threshold"       
#> [227] "sorting_mating_boost"           "iffolk_selection"              
#> [229] "iffolk_r_min"                   "iffolk_radius"                 
#> [231] "iffolk_transfer"                "iffolk_min_energy"             
#> [233] "parliament_suppression"         "parliament_cost"               
#> [235] "fixed_patch"                    "fixed_patch_value"             
#> [237] "fixed_patch_x"                  "fixed_patch_y"                 
#> [239] "fixed_patch_radius"             "log_freq"                      
#> [241] "log_genomes"                    "random_seed"
# All parameters with their values
str(defs, max.level = 1, give.attr = FALSE)
#> List of 242
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
#>  $ disease                       : logi FALSE
#>   [list output truncated]
```
