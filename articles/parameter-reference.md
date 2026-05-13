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

| Parameter | Default | Type | Description |
|----|----|----|----|
| `grass_init_prob` | 0.5 | numeric 
``` math
0,1
``` | Fraction of cells with grass at tick 1 |
| `grass_rate` | 0.10 | numeric 
``` math
0,1
``` | Per-tick regrowth probability on empty cells |
| `grass_max` | 1.0 | numeric | Maximum grass per cell |

------------------------------------------------------------------------

## Neural architecture

| Parameter | Default | Options | Description |
|----|----|----|----|
| `brain_type` | `"bnn"` | bnn, ann, ctrnn, grn, transformer, synthesis | Neural network architecture |
| `hidden_layers` | `c(16, 8)` | integer vector | Hidden layer sizes |
| `n_inputs` | auto | integer | Sensory input vector size (set by `create_environment()`) |
| `n_outputs` | 4 | integer | Action output size (N/E/S/W) |

### BNN-specific controls (0.4.0+)

| Parameter | Default | Description |
|----|----|----|
| `bnn_sigma_source` | `"heterozygosity"` | (0.4.0 Tier 5A) Source of BNN posterior width: `"heterozygosity"` (legacy; derived from parental allele difference), `"fixed"` (constant `bnn_sigma_init`), or `"trait"` (evolvable via `TRAIT_PLASTICITY`). Required for s-baldwin / s-plasticity scenarios. |
| `bnn_sigma_init` | 0.5 | Initial sigma for haploid and fixed modes |
| `bnn_sample_freq` | 1 | (0.4.0 Tier 5B) Resample BNN weights every N forward passes. `1` = resample every tick (legacy); `5` lets REINFORCE gradients accumulate (required for the 0.4.1 s-rl ✅ verdict). |

### Brain metabolic cost

| Parameter | Default | Description |
|----|----|----|
| `brain_energy_mode` | `"activity"` | `"none"`, `"size"`, `"activity"`, `"prediction_error"` |
| `brain_energy_base` | 0.001 | Fixed cost per synaptic weight per tick. Scale up (e.g. 0.010) to expose the parental-provisioning signal (see s-brain-size). |
| `brain_energy_activity` | 0.5 | Scaling on mean absolute activation |
| `brain_energy_sigma_scale` | 0.0 | (0.4.1 Tier 5C) Log-scaled information cost on BNN posterior width. Set 0.005–0.1 for Baldwin-canalisation scenarios. |
| `brain_energy_size_exponent` | 1.0 | (0.4.3) Exponent on the brain-size term: `size_cost = base × n_weights^exp`. `1.0` = linear (legacy); `1.5` = Kleiber-style super-linear (Isler & van Schaik 2009 expensive-brain). |

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

| Parameter | Default | Type | Description |
|----|----|----|----|
| `ploidy` | 2 | 1 or 2 | Diploid (default) or haploid |
| `sex_ratio` | 0.5 | numeric 
``` math
0,1
``` | Fraction of agents that are female |
| `mating_system` | `"random"` | character | Random, monogamy, polygyny, polyandry |
| `mutation_sd` | 0.05 | numeric | Gaussian noise on genome weights |
| `crossover_rate` | 0.1 | numeric 
``` math
0,1
``` | Per-locus crossover probability (diploid) |
| `min_repro_age` | 0 | integer | Minimum age to reproduce |
| `max_repro_age` | Inf | integer | Maximum age to reproduce (Inf = no limit) |

------------------------------------------------------------------------

## Life history

| Parameter | Default | Options | Description |
|----|----|----|----|
| `max_age` | 500 | integer | Die if age exceeds this |
| `life_history` | `"iteroparous"` | iteroparous, semelparous | Semelparous: reproduce once then die |
| `senescence_rate` | 0.0 | numeric | Gompertz mortality scaling with age |
| `repro_senescence` | 0.0 | numeric | Age-related fertility decline rate |

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

| Parameter | Default | Description |
|----|----|----|
| `kin_selection` | FALSE | Enable kin altruism |
| `kin_altruism_r_min` | 0.25 | Minimum pedigree relatedness to donate |
| `kin_altruism_cost` | 2.0 | Energy transferred per altruistic act |
| `kin_altruism_min_donor_energy` | 50.0 | Donor energy floor |

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

| Parameter | Default | Description |
|----|----|----|
| `n_predators_init` | 0 | Starting predator count |
| `predator_energy_init` | 60.0 | Starting energy for predators |
| `predator_attack_strength` | 10.0 | Damage dealt to prey per attack |
| `predator_min_repro_energy` | 100.0 | Predator reproduction threshold |
| `predator_max_agents` | 50 | Predator population cap |
| `predator_sense_graded` | TRUE | (0.4.2) When TRUE, prey’s predator sensory input at distance `d` is `1/(d+1)` (graded threat-level). FALSE falls back to pre-0.4.2 binary presence signal. |

------------------------------------------------------------------------

## Niche construction

Enable with `niche_construction = TRUE`.

| Parameter | Default | Description |
|----|----|----|
| `niche_construction` | FALSE | Enable shelter building |
| `shelter_build_prob` | 0.1 | Per-tick build probability (when energy sufficient) |
| `shelter_min_energy` | 40.0 | Minimum donor energy to build |
| `shelter_max_depth` | 5 | Maximum shelter units per cell |
| `shelter_decay_rate` | 0.02 | Fraction of shelters lost per tick |
| `shelter_occupancy_bonus` | 0.0 | (0.3.0) When \> 0, agents on a shelter cell receive `bonus × depth` energy per tick — the Odling-Smee, Laland & Feldman (2003) heritable-niche effect |

------------------------------------------------------------------------

## Within-lifetime RL

Enable with `rl_mode = "actor_critic"`.

| Parameter | Default | Description |
|----|----|----|
| `rl_mode` | `"none"` | `"actor_critic"` or `"hebbian"` |
| `learning_rate` | 0.01 | Output-layer update step size |
| `learning_rate_evolution` | FALSE | Allow learning rate to evolve genetically |
| `rl_update_freq` | 5 | Ticks between RL updates |

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

| Parameter | Default | Description |
|----|----|----|
| `mimicry` | FALSE | Enable toxicity and predator learning (Müllerian by default) |
| `batesian_mimicry` | FALSE | (0.3.0) Enable Batesian mimicry: palatable prey (toxicity = 0) exploit learned aversion; predator-betrayal decay prevents runaway cheating (Bates 1862) |
| `toxicity_init_mean` | 0.0 | Starting toxicity |
| `toxicity_cost_per_tick` | 2.0 | Per-tick energy cost for toxicity \> 0 (raised from 0.5 in 0.3.0 for Zahavi-handicap honesty) |
| `toxin_dose` | 2.0 | Damage per toxicity unit per attack |
| `signal_memory` | 20 | Predator memory window (Rescorla-Wagner) |
| `signal_toxicity_coupling` | 0.0 | (0.4.4) Aposematic pleiotropy: when \> 0, each agent’s `signal[1]` is pulled toward its own `toxicity` each tick. Set to 1.0 for fully honest signal. Required for Bates/Müller dynamics to close the feedback loop. |

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

| Parameter | Default | Description |
|----|----|----|
| `coevolving_parasites` | FALSE | Enable genotype-matched parasite pressure |
| `parasite_match_mode` | `"auto"` | `"auto"` / `"continuous"` / `"discrete"`. Auto picks discrete when `n_parasite_loci > 0`, else continuous. |
| `parasite_virulence_rate` | 0.1 | Rate at which the parasite genotype tracks the host majority |
| `parasite_pressure` | 0.5 | Maximum per-tick energy drain at full genotype match |
| `parasite_distance_scale` | 1.0 | Continuous-mode Gaussian falloff scale |
| `n_parasite_loci` | 0 | (0.5.1) Number of binary loci in the discrete-mode `parasite_haplotype` trait. Set 8–16 for Hamilton’s canonical mechanism. |
| `parasite_mutation_rate` | 0.01 | Per-locus allele-flip rate during inheritance |
| `parasite_discrete_exponent` | 4.0 | Hamming-distance falloff sharpness; 4–6 produces cleanly frequency-dependent selection |

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

| Parameter | Default | Description |
|----|----|----|
| `parental_care` | FALSE | Enable carried offspring |
| `juvenile_independence_age` | 10 | Tick age at which offspring leaves parental care. Replaces pre-0.4.0 `care_duration`. |
| `juvenile_independence_energy` | 50.0 | Energy level at which offspring leaves early |
| `care_cost_per_tick` | 1.0 | Parent energy cost per juvenile per tick. Replaces pre-0.5.6 `care_energy_cost` / `care_cost_per_offspring`. |
| `feeding_rate` | 5.0 | Energy transferred to juvenile per tick. Replaces pre-0.5.6 `juvenile_energy_gain`. |
| `neonatal_foraging_deficit` | 0.0 | (0.4.3) Reduction in effective `max_bite` for newborns during their first `neonatal_deficit_duration` ticks. Set 0.3–0.6 to create the expensive-brain selection pressure for parental provisioning (Aiello & Wheeler 1995; Isler & van Schaik 2009). |
| `neonatal_deficit_duration` | 10 | (0.4.3) How many ticks the neonatal deficit applies for |

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

| Parameter | Default | Description |
|----|----|----|
| `spatial_sorting` | FALSE | Enable invasion-front mating assortment |
| `sorting_front_threshold` | 0.75 | Fraction from front to define “front zone” |
| `sorting_mating_boost` | 3.0 | Mating encounter fold-increase at front |

------------------------------------------------------------------------

## IFfolk inclusive fitness

Enable with `iffolk_selection = TRUE`.

| Parameter | Default | Description |
|----|----|----|
| `iffolk_selection` | FALSE | Enable energy transfers to relatives |
| `iffolk_r_min` | 0.125 | Minimum relatedness (cousins and closer) |
| `iffolk_radius` | 5 | Neighbourhood radius for kin search |
| `iffolk_transfer` | 3.0 | Energy transferred per act |
| `iffolk_min_energy` | 60.0 | Donor energy floor |
| `parliament_suppression` | FALSE | Penalise defectors among cooperators |
| `parliament_cost` | 0.5 | Energy cost for defectors per cooperator neighbour |

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
#>   [1] "grid_rows"                          
#>   [2] "grid_cols"                          
#>   [3] "toroidal"                           
#>   [4] "random_tick_order"                  
#>   [5] "n_agents_init"                      
#>   [6] "max_agents"                         
#>   [7] "max_ticks"                          
#>   [8] "energy_init"                        
#>   [9] "energy_max"                         
#>  [10] "move_cost"                          
#>  [11] "idle_cost"                          
#>  [12] "eat_gain"                           
#>  [13] "max_bite"                           
#>  [14] "min_repro_energy"                   
#>  [15] "repro_cost_mode"                    
#>  [16] "repro_cost"                         
#>  [17] "repro_cost_fraction"                
#>  [18] "offspring_energy_mode"              
#>  [19] "offspring_energy"                   
#>  [20] "offspring_energy_fraction"          
#>  [21] "starvation_threshold"               
#>  [22] "max_age_scales_with_metabolism"     
#>  [23] "grass_init_prob"                    
#>  [24] "grass_rate"                         
#>  [25] "grass_max"                          
#>  [26] "brain_type"                         
#>  [27] "hidden_layers"                      
#>  [28] "input_radius"                       
#>  [29] "n_genes"                            
#>  [30] "transformer_history"                
#>  [31] "transformer_heads"                  
#>  [32] "synthesis_max_rules"                
#>  [33] "ann_weight_values"                  
#>  [34] "ann_regularization"                 
#>  [35] "ann_regularization_lambda"          
#>  [36] "brain_energy_mode"                  
#>  [37] "brain_energy_base"                  
#>  [38] "brain_energy_activity"              
#>  [39] "brain_energy_sigma_scale"           
#>  [40] "brain_energy_size_exponent"         
#>  [41] "bnn_sigma_init"                     
#>  [42] "bnn_sigma_min"                      
#>  [43] "bnn_sigma_source"                   
#>  [44] "bnn_sample_freq"                    
#>  [45] "bnn_action_noise_scale"             
#>  [46] "action_exploration_epsilon"         
#>  [47] "bnn_sigma_lr_scale"                 
#>  [48] "bnn_sigma_lr_ref"                   
#>  [49] "ploidy"                             
#>  [50] "n_chromosomes"                      
#>  [51] "crossover_rate"                     
#>  [52] "dominance_model"                    
#>  [53] "self_fertilization_fallback"        
#>  [54] "mate_search_radius"                 
#>  [55] "mutation_sd"                        
#>  [56] "mutation_rate_evolution"            
#>  [57] "mutation_sd_init_mean"              
#>  [58] "mutation_sd_min"                    
#>  [59] "mutation_sd_max"                    
#>  [60] "rl_mode"                            
#>  [61] "learning_rate"                      
#>  [62] "learning_rate_evolution"            
#>  [63] "learning_rate_init_mean"            
#>  [64] "learning_rate_min"                  
#>  [65] "learning_rate_max"                  
#>  [66] "plasticity_cost"                    
#>  [67] "rl_update_freq"                     
#>  [68] "lamarckian"                         
#>  [69] "epigenetics"                        
#>  [70] "epigenetic_learning_coupling"       
#>  [71] "epigenetic_inheritance"             
#>  [72] "epigenetic_effect_size"             
#>  [73] "methylation_rate"                   
#>  [74] "demethylation_rate"                 
#>  [75] "life_history"                       
#>  [76] "max_age"                            
#>  [77] "senescence_rate"                    
#>  [78] "allee_threshold"                    
#>  [79] "body_size_evolution"                
#>  [80] "body_size_init_mean"                
#>  [81] "body_size_mutation_sd"              
#>  [82] "body_size_min"                      
#>  [83] "body_size_max"                      
#>  [84] "brain_size_evolution"               
#>  [85] "brain_size_init_mean"               
#>  [86] "brain_size_mutation_sd"             
#>  [87] "brain_size_min"                     
#>  [88] "brain_size_max"                     
#>  [89] "brain_size_cost_scale"              
#>  [90] "brain_size_sensing_exponent"        
#>  [91] "personality_syndrome"               
#>  [92] "exploration_init_mean"              
#>  [93] "exploration_mutation_sd"            
#>  [94] "boldness_init_mean"                 
#>  [95] "boldness_mutation_sd"               
#>  [96] "aggressiveness_init_mean"           
#>  [97] "aggressiveness_mutation_sd"         
#>  [98] "personality_beta"                   
#>  [99] "personality_alpha"                  
#> [100] "wolf_year1_repro_age"               
#> [101] "wolf_year2_repro_age"               
#> [102] "personality_f_high"                 
#> [103] "personality_f_low"                  
#> [104] "personality_b"                      
#> [105] "personality_gamma"                  
#> [106] "personality_V"                      
#> [107] "personality_delta"                  
#> [108] "personality_hawkdove_per_tick"      
#> [109] "personality_antipred_per_tick"      
#> [110] "personality_hawkdove_radius"        
#> [111] "reciprocal_altruism"                
#> [112] "reciprocity_initial_init_mean"      
#> [113] "reciprocity_initial_mutation_sd"    
#> [114] "reciprocity_retaliation_init_mean"  
#> [115] "reciprocity_retaliation_mutation_sd"
#> [116] "reciprocity_forgiveness_init_mean"  
#> [117] "reciprocity_forgiveness_mutation_sd"
#> [118] "reciprocity_cost"                   
#> [119] "reciprocity_benefit_ratio"          
#> [120] "reciprocity_interaction_rate"       
#> [121] "partner_memory_size"                
#> [122] "reciprocity_radius"                 
#> [123] "responsive_personalities"           
#> [124] "responsiveness_init_mean"           
#> [125] "responsiveness_mutation_sd"         
#> [126] "responsiveness_cost"                
#> [127] "metabolic_rate_evolution"           
#> [128] "metabolic_rate_init_mean"           
#> [129] "metabolic_rate_mutation_sd"         
#> [130] "metabolic_rate_min"                 
#> [131] "metabolic_rate_max"                 
#> [132] "aging_rate_evolution"               
#> [133] "aging_rate_init_mean"               
#> [134] "aging_rate_mutation_sd"             
#> [135] "aging_rate_min"                     
#> [136] "aging_rate_max"                     
#> [137] "immune_evolution"                   
#> [138] "immune_strength_init_mean"          
#> [139] "immune_strength_mutation_sd"        
#> [140] "immune_strength_min"                
#> [141] "immune_strength_max"                
#> [142] "disease"                            
#> [143] "disease_seed_prob"                  
#> [144] "transmission_prob"                  
#> [145] "disease_duration"                   
#> [146] "immune_duration"                    
#> [147] "disease_energy_cost"                
#> [148] "disease_death_prob"                 
#> [149] "kin_selection"                      
#> [150] "kin_altruism_cost"                  
#> [151] "kin_altruism_benefit"               
#> [152] "kin_altruism_r_min"                 
#> [153] "kin_altruism_min_donor_energy"      
#> [154] "cooperation_evolution"              
#> [155] "cooperation_multiplier"             
#> [156] "cooperation_init_mean"              
#> [157] "cooperation_mutation_sd"            
#> [158] "cooperation_cost"                   
#> [159] "dispersal_evolution"                
#> [160] "dispersal_cost"                     
#> [161] "dispersal_init_mean"                
#> [162] "dispersal_mutation_sd"              
#> [163] "dispersal_min"                      
#> [164] "dispersal_max"                      
#> [165] "habitat_preference_evolution"       
#> [166] "habitat_preference_init_mean"       
#> [167] "habitat_preference_mutation_sd"     
#> [168] "habitat_preference_min"             
#> [169] "habitat_preference_max"             
#> [170] "habitat_preference_strength"        
#> [171] "habitat_move_cost"                  
#> [172] "group_defense"                      
#> [173] "group_defense_radius"               
#> [174] "group_defense_strength"             
#> [175] "seasonal_amplitude"                 
#> [176] "season_length"                      
#> [177] "winter_death_prob"                  
#> [178] "seasonal_spatial_bias"              
#> [179] "parental_care"                      
#> [180] "care_cost_per_tick"                 
#> [181] "feeding_rate"                       
#> [182] "juvenile_independence_age"          
#> [183] "juvenile_independence_energy"       
#> [184] "max_clutch_size"                    
#> [185] "neonatal_foraging_deficit"          
#> [186] "neonatal_deficit_duration"          
#> [187] "cooperative_breeding"               
#> [188] "helper_min_energy"                  
#> [189] "helper_transfer"                    
#> [190] "helper_kin_threshold"               
#> [191] "helper_tendency_init_mean"          
#> [192] "helper_tendency_mutation_sd"        
#> [193] "signal_dims"                        
#> [194] "signal_cost"                        
#> [195] "signal_cost_mortality"              
#> [196] "preference_bias_target"             
#> [197] "preference_bias_strength"           
#> [198] "signal_evolution_drift"             
#> [199] "signal_drift_sd"                    
#> [200] "mate_choice_mode"                   
#> [201] "mate_choice_strength"               
#> [202] "signal_toxicity_coupling"           
#> [203] "coevolving_parasites"               
#> [204] "parasite_match_mode"                
#> [205] "parasite_virulence_rate"            
#> [206] "parasite_pressure"                  
#> [207] "parasite_distance_scale"            
#> [208] "n_parasite_loci"                    
#> [209] "parasite_mutation_rate"             
#> [210] "parasite_discrete_exponent"         
#> [211] "speciation"                         
#> [212] "isolation_threshold"                
#> [213] "speciation_cluster_interval"        
#> [214] "n_predators_init"                   
#> [215] "predator_energy_init"               
#> [216] "predator_live_energy"               
#> [217] "predator_move_energy"               
#> [218] "predator_attack_strength"           
#> [219] "predator_energy_gain"               
#> [220] "predator_min_repro_energy"          
#> [221] "predator_min_repro_age"             
#> [222] "predator_mutation_sd"               
#> [223] "predator_max_agents"                
#> [224] "predator_max_age"                   
#> [225] "predator_sense_graded"              
#> [226] "mimicry"                            
#> [227] "batesian_mimicry"                   
#> [228] "toxicity_cost_per_tick"             
#> [229] "toxin_dose"                         
#> [230] "signal_memory_rate"                 
#> [231] "avoid_threshold"                    
#> [232] "toxicity_init_mean"                 
#> [233] "toxicity_mutation_sd"               
#> [234] "phenotypic_plasticity"              
#> [235] "plasticity_sense_radius"            
#> [236] "plasticity_init_mean"               
#> [237] "plasticity_mutation_sd"             
#> [238] "plasticity_min"                     
#> [239] "plasticity_max"                     
#> [240] "niche_construction"                 
#> [241] "shelter_build_prob"                 
#> [242] "shelter_max_depth"                  
#> [243] "shelter_min_energy"                 
#> [244] "shelter_decay_prob"                 
#> [245] "shelter_occupancy_bonus"            
#> [246] "scavenging"                         
#> [247] "carrion_fraction"                   
#> [248] "carrion_decay_rate"                 
#> [249] "carrion_eat_gain"                   
#> [250] "carrion_transmission_prob"          
#> [251] "social_learning"                    
#> [252] "social_learning_freq"               
#> [253] "social_learning_rate"               
#> [254] "clutch_size_evolution"              
#> [255] "clutch_size_init_mean"              
#> [256] "clutch_size_min"                    
#> [257] "clutch_size_max"                    
#> [258] "clutch_size_mutation_sd"            
#> [259] "parental_investment_evolution"      
#> [260] "female_investment"                  
#> [261] "male_repro_cost"                    
#> [262] "stress_hypermutation"               
#> [263] "stress_mutation_multiplier"         
#> [264] "stress_threshold"                   
#> [265] "senescence_shape"                   
#> [266] "min_repro_age"                      
#> [267] "complex_landscape"                  
#> [268] "shrub_density"                      
#> [269] "shrub_growth_rate"                  
#> [270] "shrub_energy"                       
#> [271] "canopy_density"                     
#> [272] "canopy_growth_rate"                 
#> [273] "canopy_energy"                      
#> [274] "canopy_threshold"                   
#> [275] "wing_size_init_mean"                
#> [276] "wing_size_mutation_sd"              
#> [277] "wing_size_min"                      
#> [278] "wing_size_max"                      
#> [279] "spatial_sorting"                    
#> [280] "sorting_front_threshold"            
#> [281] "sorting_mating_boost"               
#> [282] "iffolk_selection"                   
#> [283] "iffolk_r_min"                       
#> [284] "iffolk_radius"                      
#> [285] "iffolk_transfer"                    
#> [286] "iffolk_min_energy"                  
#> [287] "parliament_suppression"             
#> [288] "parliament_cost"                    
#> [289] "fixed_patch"                        
#> [290] "fixed_patch_value"                  
#> [291] "fixed_patch_x"                      
#> [292] "fixed_patch_y"                      
#> [293] "fixed_patch_radius"                 
#> [294] "log_freq"                           
#> [295] "log_genomes"                        
#> [296] "random_seed"
# All parameters with their values
str(defs, max.level = 1, give.attr = FALSE)
#> List of 296
#>  $ grid_rows                          : int 30
#>  $ grid_cols                          : int 30
#>  $ toroidal                           : logi TRUE
#>  $ random_tick_order                  : logi TRUE
#>  $ n_agents_init                      : int 50
#>  $ max_agents                         : int 500
#>  $ max_ticks                          : int 500
#>  $ energy_init                        : num 100
#>  $ energy_max                         : num 200
#>  $ move_cost                          : num 1
#>  $ idle_cost                          : num 0.5
#>  $ eat_gain                           : num 5
#>  $ max_bite                           : num 2
#>  $ min_repro_energy                   : num 120
#>  $ repro_cost_mode                    : chr "proportional"
#>  $ repro_cost                         : num 30
#>  $ repro_cost_fraction                : num 0.5
#>  $ offspring_energy_mode              : chr "proportional"
#>  $ offspring_energy                   : num 60
#>  $ offspring_energy_fraction          : num 0.25
#>  $ starvation_threshold               : num 0
#>  $ max_age_scales_with_metabolism     : logi FALSE
#>  $ grass_init_prob                    : num 0.5
#>  $ grass_rate                         : num 0.05
#>  $ grass_max                          : num 5
#>  $ brain_type                         : chr "bnn"
#>  $ hidden_layers                      : int 8
#>  $ input_radius                       : int 1
#>  $ n_genes                            : int 20
#>  $ transformer_history                : int 8
#>  $ transformer_heads                  : int 2
#>  $ synthesis_max_rules                : int 10
#>  $ ann_weight_values                  : NULL
#>  $ ann_regularization                 : chr "none"
#>  $ ann_regularization_lambda          : num 0.001
#>  $ brain_energy_mode                  : chr "activity"
#>  $ brain_energy_base                  : num 0.001
#>  $ brain_energy_activity              : num 0.5
#>  $ brain_energy_sigma_scale           : num 0
#>  $ brain_energy_size_exponent         : num 1
#>  $ bnn_sigma_init                     : num 0.5
#>  $ bnn_sigma_min                      : num 0.01
#>  $ bnn_sigma_source                   : chr "heterozygosity"
#>  $ bnn_sample_freq                    : int 1
#>  $ bnn_action_noise_scale             : num 1
#>  $ action_exploration_epsilon         : num 0
#>  $ bnn_sigma_lr_scale                 : num 0
#>  $ bnn_sigma_lr_ref                   : num 0.5
#>  $ ploidy                             : int 2
#>  $ n_chromosomes                      : int 1
#>  $ crossover_rate                     : num 1
#>  $ dominance_model                    : chr "additive"
#>  $ self_fertilization_fallback        : logi FALSE
#>  $ mate_search_radius                 : int 1
#>  $ mutation_sd                        : num 0.1
#>  $ mutation_rate_evolution            : logi FALSE
#>  $ mutation_sd_init_mean              : num 0.1
#>  $ mutation_sd_min                    : num 0.001
#>  $ mutation_sd_max                    : num 1
#>  $ rl_mode                            : chr "none"
#>  $ learning_rate                      : num 0.01
#>  $ learning_rate_evolution            : logi FALSE
#>  $ learning_rate_init_mean            : num 0.01
#>  $ learning_rate_min                  : num 0
#>  $ learning_rate_max                  : num 0.5
#>  $ plasticity_cost                    : num 0.05
#>  $ rl_update_freq                     : int 1
#>  $ lamarckian                         : logi FALSE
#>  $ epigenetics                        : logi FALSE
#>  $ epigenetic_learning_coupling       : num 0.1
#>  $ epigenetic_inheritance             : num 0.5
#>  $ epigenetic_effect_size             : num 0.2
#>  $ methylation_rate                   : num 0.001
#>  $ demethylation_rate                 : num 0.002
#>  $ life_history                       : chr "iteroparous"
#>  $ max_age                            : int 200
#>  $ senescence_rate                    : num 0
#>  $ allee_threshold                    : int 0
#>  $ body_size_evolution                : logi FALSE
#>  $ body_size_init_mean                : num 1
#>  $ body_size_mutation_sd              : num 0.08
#>  $ body_size_min                      : num 0.3
#>  $ body_size_max                      : num 3
#>  $ brain_size_evolution               : logi FALSE
#>  $ brain_size_init_mean               : num 1
#>  $ brain_size_mutation_sd             : num 0.05
#>  $ brain_size_min                     : num 0.1
#>  $ brain_size_max                     : num 3
#>  $ brain_size_cost_scale              : num 1
#>  $ brain_size_sensing_exponent        : num 0.3
#>  $ personality_syndrome               : logi FALSE
#>  $ exploration_init_mean              : num 0.5
#>  $ exploration_mutation_sd            : num 0.05
#>  $ boldness_init_mean                 : num 0.5
#>  $ boldness_mutation_sd               : num 0.05
#>  $ aggressiveness_init_mean           : num 0.5
#>  $ aggressiveness_mutation_sd         : num 0.05
#>  $ personality_beta                   : num 1.25
#>  $ personality_alpha                  : num 0.005
#>   [list output truncated]
```
