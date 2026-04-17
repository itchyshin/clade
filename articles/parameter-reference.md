# Parameter Reference

This article lists every parameter in
[`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md),
grouped by biological theme. For each parameter: the default value,
type, and what it controls.

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

### BNN-specific controls (0.4.0+)

| Parameter          | Default            | Description                                                                                                                                                                                                                                                   |
|--------------------|--------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `bnn_sigma_source` | `"heterozygosity"` | (0.4.0 Tier 5A) Source of BNN posterior width: `"heterozygosity"` (legacy; derived from parental allele difference), `"fixed"` (constant `bnn_sigma_init`), or `"trait"` (evolvable via `TRAIT_PLASTICITY`). Required for s-baldwin / s-plasticity scenarios. |
| `bnn_sigma_init`   | 0.5                | Initial sigma for haploid and fixed modes                                                                                                                                                                                                                     |
| `bnn_sample_freq`  | 1                  | (0.4.0 Tier 5B) Resample BNN weights every N forward passes. `1` = resample every tick (legacy); `5` lets REINFORCE gradients accumulate (required for the 0.4.1 s-rl ✅ verdict).                                                                            |

### Brain metabolic cost

| Parameter                    | Default      | Description                                                                                                                                                                         |
|------------------------------|--------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `brain_energy_mode`          | `"activity"` | `"none"`, `"size"`, `"activity"`, `"prediction_error"`                                                                                                                              |
| `brain_energy_base`          | 0.001        | Fixed cost per synaptic weight per tick. Scale up (e.g. 0.010) to expose the parental-provisioning signal (see s-brain-size).                                                       |
| `brain_energy_activity`      | 0.5          | Scaling on mean absolute activation                                                                                                                                                 |
| `brain_energy_sigma_scale`   | 0.0          | (0.4.1 Tier 5C) Log-scaled information cost on BNN posterior width. Set 0.005–0.1 for Baldwin-canalisation scenarios.                                                               |
| `brain_energy_size_exponent` | 1.0          | (0.4.3) Exponent on the brain-size term: `size_cost = base × n_weights^exp`. `1.0` = linear (legacy); `1.5` = Kleiber-style super-linear (Isler & van Schaik 2009 expensive-brain). |

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

| Parameter                   | Default | Description                                                                                                                                                |
|-----------------------------|---------|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `n_predators_init`          | 0       | Starting predator count                                                                                                                                    |
| `predator_energy_init`      | 60.0    | Starting energy for predators                                                                                                                              |
| `predator_attack_strength`  | 10.0    | Damage dealt to prey per attack                                                                                                                            |
| `predator_min_repro_energy` | 100.0   | Predator reproduction threshold                                                                                                                            |
| `predator_max_agents`       | 50      | Predator population cap                                                                                                                                    |
| `predator_sense_graded`     | TRUE    | (0.4.2) When TRUE, prey’s predator sensory input at distance `d` is `1/(d+1)` (graded threat-level). FALSE falls back to pre-0.4.2 binary presence signal. |

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

| Parameter                  | Default | Description                                                                                                                                                                                                          |
|----------------------------|---------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `mimicry`                  | FALSE   | Enable toxicity and predator learning (Müllerian by default)                                                                                                                                                         |
| `batesian_mimicry`         | FALSE   | (0.3.0) Enable Batesian mimicry: palatable prey (toxicity = 0) exploit learned aversion; predator-betrayal decay prevents runaway cheating (Bates 1862)                                                              |
| `toxicity_init_mean`       | 0.0     | Starting toxicity                                                                                                                                                                                                    |
| `toxicity_cost_per_tick`   | 2.0     | Per-tick energy cost for toxicity \> 0 (raised from 0.5 in 0.3.0 for Zahavi-handicap honesty)                                                                                                                        |
| `toxin_dose`               | 2.0     | Damage per toxicity unit per attack                                                                                                                                                                                  |
| `signal_memory`            | 20      | Predator memory window (Rescorla-Wagner)                                                                                                                                                                             |
| `signal_toxicity_coupling` | 0.0     | (0.4.4) Aposematic pleiotropy: when \> 0, each agent’s `signal[1]` is pulled toward its own `toxicity` each tick. Set to 1.0 for fully honest signal. Required for Bates/Müller dynamics to close the feedback loop. |

As of 0.4.4 the predator memory is a full **vector** stored in
`signal_memory::Vector{Float32}` on the Agent struct (length =
`signal_dims`), updated via the Widrow-Hoff delta rule
`memory += lr × (toxicity − dot(memory, signal)) × signal`. The
avoidance check uses the predicted toxicity `dot(memory, signal)`
directly. This restores alifeR’s signal-specific learning and produces
textbook Batesian/Müllerian dynamics under the right ecological
parameters.

------------------------------------------------------------------------

## Coevolving parasites (0.5.0 / 0.5.1, Hamilton 1980 Red Queen)

Enable with `coevolving_parasites = TRUE` AND either `signal_dims > 0`
(continuous mode) or `n_parasite_loci > 0` (discrete mode).

| Parameter                    | Default  | Description                                                                                                                 |
|------------------------------|----------|-----------------------------------------------------------------------------------------------------------------------------|
| `coevolving_parasites`       | FALSE    | Enable genotype-matched parasite pressure                                                                                   |
| `parasite_match_mode`        | `"auto"` | `"auto"` / `"continuous"` / `"discrete"`. Auto picks discrete when `n_parasite_loci > 0`, else continuous.                  |
| `parasite_virulence_rate`    | 0.1      | Rate at which the parasite genotype tracks the host majority                                                                |
| `parasite_pressure`          | 0.5      | Maximum per-tick energy drain at full genotype match                                                                        |
| `parasite_distance_scale`    | 1.0      | Continuous-mode Gaussian falloff scale                                                                                      |
| `n_parasite_loci`            | 0        | (0.5.1) Number of binary loci in the discrete-mode `parasite_haplotype` trait. Set 8–16 for Hamilton’s canonical mechanism. |
| `parasite_mutation_rate`     | 0.01     | Per-locus allele-flip rate during inheritance                                                                               |
| `parasite_discrete_exponent` | 4.0      | Hamming-distance falloff sharpness; 4–6 produces cleanly frequency-dependent selection                                      |

**Continuous mode (0.5.0)** uses Euclidean distance on the signal vector
and tracks the population centroid. Sex offspring cluster closer to the
centroid than asex clones, so sex is *more* exposed — this does NOT
reproduce Hamilton’s canonical Red Queen.

**Discrete mode (0.5.1)** uses Hamming distance on a binary-allele
haplotype with Mendelian inheritance (each locus inherited independently
from either parent). Recombination produces novel haplotype combinations
that escape the current parasite genotype. This is the canonical
Hamilton mechanism and is the first regime in which clade shows sex \>
asex.

------------------------------------------------------------------------

## Parental care

Enable with `parental_care = TRUE`.

| Parameter                   | Default | Description                                                                                                                                                                                                                                           |
|-----------------------------|---------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `parental_care`             | FALSE   | Enable carried offspring                                                                                                                                                                                                                              |
| `care_duration`             | 5       | Ticks offspring are carried                                                                                                                                                                                                                           |
| `care_energy_cost`          | 2.0     | Parent energy cost per juvenile per tick                                                                                                                                                                                                              |
| `juvenile_energy_gain`      | 3.0     | Energy transferred to juvenile per tick                                                                                                                                                                                                               |
| `neonatal_foraging_deficit` | 0.0     | (0.4.3) Reduction in effective `max_bite` for newborns during their first `neonatal_deficit_duration` ticks. Set 0.3–0.6 to create the expensive-brain selection pressure for parental provisioning (Aiello & Wheeler 1995; Isler & van Schaik 2009). |
| `neonatal_deficit_duration` | 10      | (0.4.3) How many ticks the neonatal deficit applies for                                                                                                                                                                                               |

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
#>  [39] "brain_energy_size_exponent"     "bnn_sigma_init"                
#>  [41] "bnn_sigma_min"                  "bnn_sigma_source"              
#>  [43] "bnn_sample_freq"                "bnn_action_noise_scale"        
#>  [45] "action_exploration_epsilon"     "bnn_sigma_lr_scale"            
#>  [47] "bnn_sigma_lr_ref"               "ploidy"                        
#>  [49] "n_chromosomes"                  "crossover_rate"                
#>  [51] "dominance_model"                "mutation_sd"                   
#>  [53] "mutation_rate_evolution"        "mutation_sd_init_mean"         
#>  [55] "mutation_sd_min"                "mutation_sd_max"               
#>  [57] "rl_mode"                        "learning_rate"                 
#>  [59] "learning_rate_evolution"        "learning_rate_init_mean"       
#>  [61] "learning_rate_min"              "learning_rate_max"             
#>  [63] "plasticity_cost"                "rl_update_freq"                
#>  [65] "lamarckian"                     "epigenetics"                   
#>  [67] "epigenetic_learning_coupling"   "epigenetic_inheritance"        
#>  [69] "epigenetic_effect_size"         "methylation_rate"              
#>  [71] "demethylation_rate"             "life_history"                  
#>  [73] "max_age"                        "senescence_rate"               
#>  [75] "repro_senescence"               "life_history_evolution"        
#>  [77] "allee_threshold"                "body_size_evolution"           
#>  [79] "body_size_init_mean"            "body_size_mutation_sd"         
#>  [81] "body_size_min"                  "body_size_max"                 
#>  [83] "brain_size_evolution"           "brain_size_init_mean"          
#>  [85] "brain_size_mutation_sd"         "brain_size_min"                
#>  [87] "brain_size_max"                 "brain_size_cost_scale"         
#>  [89] "brain_size_sensing_exponent"    "metabolic_rate_evolution"      
#>  [91] "metabolic_rate_init_mean"       "metabolic_rate_mutation_sd"    
#>  [93] "metabolic_rate_min"             "metabolic_rate_max"            
#>  [95] "aging_rate_evolution"           "aging_rate_init_mean"          
#>  [97] "aging_rate_mutation_sd"         "aging_rate_min"                
#>  [99] "aging_rate_max"                 "immune_evolution"              
#> [101] "immune_strength_init_mean"      "immune_strength_mutation_sd"   
#> [103] "immune_strength_min"            "immune_strength_max"           
#> [105] "disease"                        "disease_seed_prob"             
#> [107] "transmission_prob"              "disease_duration"              
#> [109] "immune_duration"                "disease_energy_cost"           
#> [111] "disease_death_prob"             "kin_selection"                 
#> [113] "kin_altruism_cost"              "kin_altruism_benefit"          
#> [115] "kin_altruism_r_min"             "kin_altruism_min_donor_energy" 
#> [117] "cooperation_evolution"          "cooperation_multiplier"        
#> [119] "cooperation_init_mean"          "cooperation_mutation_sd"       
#> [121] "cooperation_cost"               "dispersal_evolution"           
#> [123] "dispersal_cost"                 "dispersal_init_mean"           
#> [125] "dispersal_mutation_sd"          "dispersal_min"                 
#> [127] "dispersal_max"                  "habitat_preference_evolution"  
#> [129] "habitat_preference_init_mean"   "habitat_preference_mutation_sd"
#> [131] "habitat_preference_min"         "habitat_preference_max"        
#> [133] "habitat_preference_strength"    "habitat_move_cost"             
#> [135] "group_defense"                  "group_defense_radius"          
#> [137] "group_defense_strength"         "seasonal_amplitude"            
#> [139] "season_length"                  "winter_death_prob"             
#> [141] "parental_care"                  "care_cost_per_tick"            
#> [143] "feeding_rate"                   "juvenile_independence_age"     
#> [145] "juvenile_independence_energy"   "max_clutch_size"               
#> [147] "neonatal_foraging_deficit"      "neonatal_deficit_duration"     
#> [149] "cooperative_breeding"           "helper_min_energy"             
#> [151] "helper_transfer"                "helper_kin_threshold"          
#> [153] "helper_tendency_init_mean"      "helper_tendency_mutation_sd"   
#> [155] "signal_dims"                    "signal_cost"                   
#> [157] "signal_evolution_drift"         "signal_drift_sd"               
#> [159] "mate_choice_mode"               "mate_choice_strength"          
#> [161] "signal_toxicity_coupling"       "coevolving_parasites"          
#> [163] "parasite_match_mode"            "parasite_virulence_rate"       
#> [165] "parasite_pressure"              "parasite_distance_scale"       
#> [167] "n_parasite_loci"                "parasite_mutation_rate"        
#> [169] "parasite_discrete_exponent"     "speciation"                    
#> [171] "isolation_threshold"            "speciation_cluster_interval"   
#> [173] "n_predators_init"               "predator_energy_init"          
#> [175] "predator_live_energy"           "predator_move_energy"          
#> [177] "predator_attack_strength"       "predator_energy_gain"          
#> [179] "predator_min_repro_energy"      "predator_min_repro_age"        
#> [181] "predator_mutation_sd"           "predator_max_agents"           
#> [183] "predator_max_age"               "predator_sense_graded"         
#> [185] "mimicry"                        "batesian_mimicry"              
#> [187] "toxicity_cost_per_tick"         "toxin_dose"                    
#> [189] "signal_memory_rate"             "avoid_threshold"               
#> [191] "toxicity_init_mean"             "toxicity_mutation_sd"          
#> [193] "phenotypic_plasticity"          "plasticity_sense_radius"       
#> [195] "plasticity_init_mean"           "plasticity_mutation_sd"        
#> [197] "plasticity_min"                 "plasticity_max"                
#> [199] "niche_construction"             "shelter_build_prob"            
#> [201] "shelter_max_depth"              "shelter_min_energy"            
#> [203] "shelter_decay_prob"             "shelter_occupancy_bonus"       
#> [205] "scavenging"                     "carrion_fraction"              
#> [207] "carrion_decay_rate"             "carrion_eat_gain"              
#> [209] "carrion_transmission_prob"      "social_learning"               
#> [211] "social_learning_freq"           "social_learning_rate"          
#> [213] "clutch_size_evolution"          "clutch_size_init_mean"         
#> [215] "clutch_size_min"                "clutch_size_max"               
#> [217] "clutch_size_mutation_sd"        "parental_investment_evolution" 
#> [219] "parental_investment_init_mean"  "female_investment"             
#> [221] "male_repro_cost"                "stress_hypermutation"          
#> [223] "stress_mutation_multiplier"     "stress_threshold"              
#> [225] "senescence_shape"               "min_repro_age"                 
#> [227] "wall_density"                   "wall_clusters"                 
#> [229] "world_evolution"                "world_mutation_sd"             
#> [231] "world_params_to_evolve"         "complex_landscape"             
#> [233] "shrub_density"                  "shrub_growth_rate"             
#> [235] "shrub_energy"                   "canopy_density"                
#> [237] "canopy_growth_rate"             "canopy_energy"                 
#> [239] "canopy_threshold"               "wing_size_init_mean"           
#> [241] "wing_size_mutation_sd"          "wing_size_min"                 
#> [243] "wing_size_max"                  "spatial_sorting"               
#> [245] "sorting_front_threshold"        "sorting_mating_boost"          
#> [247] "iffolk_selection"               "iffolk_r_min"                  
#> [249] "iffolk_radius"                  "iffolk_transfer"               
#> [251] "iffolk_min_energy"              "parliament_suppression"        
#> [253] "parliament_cost"                "fixed_patch"                   
#> [255] "fixed_patch_value"              "fixed_patch_x"                 
#> [257] "fixed_patch_y"                  "fixed_patch_radius"            
#> [259] "log_freq"                       "log_genomes"                   
#> [261] "random_seed"
# All parameters with their values
str(defs, max.level = 1, give.attr = FALSE)
#> List of 261
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
#>  $ brain_energy_size_exponent    : num 1
#>  $ bnn_sigma_init                : num 0.5
#>  $ bnn_sigma_min                 : num 0.01
#>  $ bnn_sigma_source              : chr "heterozygosity"
#>  $ bnn_sample_freq               : int 1
#>  $ bnn_action_noise_scale        : num 1
#>  $ action_exploration_epsilon    : num 0
#>  $ bnn_sigma_lr_scale            : num 0
#>  $ bnn_sigma_lr_ref              : num 0.5
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
#>   [list output truncated]
```
