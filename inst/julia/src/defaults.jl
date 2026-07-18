"""
    get_default_specs()

Returns the complete master dictionary of all Clade parameters.
This mirrors the R-side `default_specs()` function to ensure the 
Julia kernel can run independently without crashing on missing keys.
"""
function get_default_specs()
    return Dict{String, Any}(
        "grid_rows" => 30, "grid_cols" => 30, "toroidal" => true, "random_tick_order" => true,
        "n_agents_init" => 50, "max_agents" => 500, "max_ticks" => 500,
        "energy_init" => 100.0, "energy_max" => 200.0, "move_cost" => 1.0, "idle_cost" => 0.5,
        "eat_gain" => 5.0, "max_bite" => 2.0, "min_repro_energy" => 120.0,
        "repro_cost_mode" => "proportional", "repro_cost" => 30.0, "repro_cost_fraction" => 0.5,
        "offspring_energy_mode" => "proportional", "offspring_energy" => 60.0, "offspring_energy_fraction" => 0.25,
        "starvation_threshold" => 0.0, "max_age_scales_with_metabolism" => false,
        "grass_init_prob" => 0.5, "grass_rate" => 0.05, "grass_max" => 5.0,
        "brain_type" => "bnn", "hidden_layers" => [8], "input_radius" => 1, "n_genes" => 20,
        "transformer_history" => 8, "transformer_heads" => 2, "synthesis_max_rules" => 10,
        "ann_weight_values" => nothing, "ann_regularization" => "none", "ann_regularization_lambda" => 0.001,
        "brain_energy_mode" => "activity", "brain_energy_base" => 0.001, "brain_energy_activity" => 0.5,
        "brain_energy_sigma_scale" => 0.0, "brain_energy_size_exponent" => 1.0,
        "bnn_sigma_init" => 0.5, "bnn_sigma_min" => 0.01, "bnn_sigma_source" => "heterozygosity",
        "bnn_sample_freq" => 1, "bnn_action_noise_scale" => 1.0, "action_exploration_epsilon" => 0.0,
        "bnn_sigma_lr_scale" => 0.0, "bnn_sigma_lr_ref" => 0.5,
        "ploidy" => 2, "n_chromosomes" => 1, "crossover_rate" => 1.0, "dominance_model" => "additive",
        "self_fertilization_fallback" => false, "mate_search_radius" => 1,
        "mutation_sd" => 0.1, "mutation_rate_evolution" => false, "mutation_sd_init_mean" => 0.1,
        "mutation_sd_min" => 0.001, "mutation_sd_max" => 1.0,
        "rl_mode" => "none", "learning_rate" => 0.01, "learning_rate_evolution" => false,
        "learning_rate_init_mean" => 0.01, "learning_rate_min" => 0.0, "learning_rate_max" => 0.5,
        "plasticity_cost" => 0.05, "rl_update_freq" => 1, "lamarckian" => false,
        "epigenetics" => false, "epigenetic_learning_coupling" => 0.10, "epigenetic_inheritance" => 0.50,
        "epigenetic_effect_size" => 0.20, "methylation_rate" => 0.001, "demethylation_rate" => 0.002,
        "life_history" => "iteroparous", "max_age" => 200, "senescence_rate" => 0.0, "allee_threshold" => 0,
        "body_size_evolution" => false, "body_size_init_mean" => 1.0, "body_size_mutation_sd" => 0.08, "body_size_min" => 0.3, "body_size_max" => 3.0,
        "brain_size_evolution" => false, "brain_size_init_mean" => 1.0, "brain_size_mutation_sd" => 0.05, "brain_size_min" => 0.1, "brain_size_max" => 3.0,
        "brain_size_cost_scale" => 1.0, "brain_size_sensing_exponent" => 0.3,
        "personality_syndrome" => false, "exploration_init_mean" => 0.5, "exploration_mutation_sd" => 0.05,
        "boldness_init_mean" => 0.5, "boldness_mutation_sd" => 0.05, "aggressiveness_init_mean" => 0.5, "aggressiveness_mutation_sd" => 0.05,
        "personality_beta" => 1.25, "personality_alpha" => 0.005, "wolf_year1_repro_age" => 50, "wolf_year2_repro_age" => 100,
        "personality_f_high" => 3.0, "personality_f_low" => 2.0, "personality_b" => 0.5, "personality_gamma" => 0.1,
        "personality_V" => 0.5, "personality_delta" => 0.5, "personality_hawkdove_per_tick" => 0.1,
        "personality_antipred_per_tick" => 0.5, "personality_hawkdove_radius" => 1,
        "reciprocal_altruism" => false, "reciprocity_initial_init_mean" => 0.5, "reciprocity_initial_mutation_sd" => 0.05,
        "reciprocity_retaliation_init_mean" => 0.5, "reciprocity_retaliation_mutation_sd" => 0.05,
        "reciprocity_forgiveness_init_mean" => 0.1, "reciprocity_forgiveness_mutation_sd" => 0.05,
        "reciprocity_cost" => 0.5, "reciprocity_benefit_ratio" => 2.0, "reciprocity_interaction_rate" => 0.1,
        "partner_memory_size" => 8, "reciprocity_radius" => 1,
        "responsive_personalities" => false, "responsiveness_init_mean" => 0.5, "responsiveness_mutation_sd" => 0.05, "responsiveness_cost" => 0.4,
        "metabolic_rate_evolution" => false, "metabolic_rate_init_mean" => 1.0, "metabolic_rate_mutation_sd" => 0.05, "metabolic_rate_min" => 0.1, "metabolic_rate_max" => 5.0,
        "aging_rate_evolution" => false, "aging_rate_init_mean" => 1.0, "aging_rate_mutation_sd" => 0.05, "aging_rate_min" => 0.01, "aging_rate_max" => 10.0,
        "immune_evolution" => false, "immune_strength_init_mean" => 0.3, "immune_strength_mutation_sd" => 0.05, "immune_strength_min" => 0.0, "immune_strength_max" => 1.0,
        "disease" => false, "disease_seed_prob" => 0.01, "transmission_prob" => 0.1, "disease_duration" => 10, "immune_duration" => 20, "disease_energy_cost" => 5.0, "disease_death_prob" => 0.02,
        "kin_selection" => false, "kin_altruism_cost" => 2.0, "kin_altruism_benefit" => 10.0, "kin_altruism_r_min" => 0.25, "kin_altruism_min_donor_energy" => 50.0,
        "cooperation_evolution" => false, "cooperation_multiplier" => 2.0, "cooperation_init_mean" => 0.5, "cooperation_mutation_sd" => 0.05, "cooperation_cost" => 1.0,
        "dispersal_evolution" => false, "dispersal_cost" => 2.0, "dispersal_init_mean" => 0.1, "dispersal_mutation_sd" => 0.02, "dispersal_min" => 0.0, "dispersal_max" => 0.5,
        "habitat_preference_evolution" => false, "habitat_preference_init_mean" => 0.0, "habitat_preference_mutation_sd" => 0.03, "habitat_preference_min" => -1.0, "habitat_preference_max" => 1.0, "habitat_preference_strength" => 0.5, "habitat_move_cost" => 0.0,
        "group_defense" => false, "group_defense_radius" => 2, "group_defense_strength" => 0.3,
        "seasonal_amplitude" => 0.0, "season_length" => 100, "winter_death_prob" => 0.0, "seasonal_spatial_bias" => 0.0,
        "parental_care" => false, "care_cost_per_tick" => 1.0, "feeding_rate" => 5.0, "juvenile_independence_age" => 10, "juvenile_independence_energy" => 50.0, "max_clutch_size" => 1, "neonatal_foraging_deficit" => 0.0, "neonatal_deficit_duration" => 10,
        "cooperative_breeding" => false, "helper_min_energy" => 80.0, "helper_transfer" => 5.0, "helper_kin_threshold" => 0.25, "helper_tendency_init_mean" => 0.1, "helper_tendency_mutation_sd" => 0.02,
        "signal_dims" => 0, "signal_cost" => 0.1, "signal_cost_mortality" => 0.0, "preference_bias_target" => nothing, "preference_bias_strength" => 0.0, "signal_evolution_drift" => true, "signal_drift_sd" => 0.01, "mate_choice_mode" => "preference", "mate_choice_strength" => 1.0, "signal_toxicity_coupling" => 0.0,
        "coevolving_parasites" => false, "parasite_match_mode" => "auto", "parasite_virulence_rate" => 0.1, "parasite_pressure" => 0.5, "parasite_distance_scale" => 1.0, "n_parasite_loci" => 0, "parasite_mutation_rate" => 0.01, "parasite_discrete_exponent" => 4.0,
        "speciation" => false, "isolation_threshold" => 0.5, "speciation_cluster_interval" => 10,
        "n_predators_init" => 0, "predator_energy_init" => 150.0, "predator_live_energy" => 2.0, "predator_move_energy" => 1.0, "predator_attack_strength" => 40.0, "predator_energy_gain" => 30.0, "predator_min_repro_energy" => 200.0, "predator_min_repro_age" => 5, "predator_mutation_sd" => 0.1, "predator_max_agents" => 50, "predator_max_age" => nothing, "predator_sense_graded" => true,
        "mimicry" => false, "batesian_mimicry" => false, "toxicity_cost_per_tick" => 2.0, "toxin_dose" => 30.0, "signal_memory_rate" => 0.3, "avoid_threshold" => 0.5, "toxicity_init_mean" => 0.0, "toxicity_mutation_sd" => 0.05,
        "phenotypic_plasticity" => false, "plasticity_sense_radius" => 3, "plasticity_init_mean" => 0.3, "plasticity_mutation_sd" => 0.03, "plasticity_min" => 0.0, "plasticity_max" => 1.0,
        "niche_construction" => false, "shelter_build_prob" => 0.1, "shelter_max_depth" => 5, "shelter_min_energy" => 80.0, "shelter_decay_prob" => 0.05, "shelter_occupancy_bonus" => 0.0,
        "scavenging" => false, "carrion_fraction" => 0.5, "carrion_decay_rate" => 0.1, "carrion_eat_gain" => 3.0, "carrion_transmission_prob" => 0.0,
        "social_learning" => false, "social_learning_freq" => 10, "social_learning_rate" => 0.1,
        "clutch_size_evolution" => false, "clutch_size_init_mean" => 1.0, "clutch_size_min" => 1, "clutch_size_max" => 5, "clutch_size_mutation_sd" => 0.3,
        "parental_investment_evolution" => false, "female_investment" => 0.7, "male_repro_cost" => 0.3,
        "sex_labels" => false, "sex_determination" => "random", "sex_ratio_primary" => 0.5,
        "sex_specific_traits" => String[], "sex_specific_tradeoffs" => Dict("male_mating_vs_aging" => 0.0, "female_offspring_vs_aging" => 0.0),
        "mating_system" => "any", "divorce_rate" => 0.0, "pair_bond_persistence" => true, "mating_group_n_males" => 1, "mating_group_n_females" => 1, "mating_group_fecundity_scaling" => "balanced",
        "stress_hypermutation" => false, "stress_mutation_multiplier" => 3.0, "stress_threshold" => 20.0,
        "senescence_shape" => 1.0, "min_repro_age" => 0,
        "complex_landscape" => false, "shrub_density" => 0.3, "shrub_growth_rate" => 0.03, "shrub_energy" => 20.0, "canopy_density" => 0.15, "canopy_growth_rate" => 0.005, "canopy_energy" => 50.0, "canopy_threshold" => 0.15, "wing_size_init_mean" => 0.08, "wing_size_mutation_sd" => 0.05, "wing_size_min" => 0.0, "wing_size_max" => 1.0,
        "spatial_sorting" => false, "sorting_front_threshold" => 0.75, "sorting_mating_boost" => 3.0,
        "iffolk_selection" => false, "iffolk_r_min" => 0.125, "iffolk_radius" => 5, "iffolk_transfer" => 3.0, "iffolk_min_energy" => 60.0, "parliament_suppression" => false, "parliament_cost" => 0.5,
        "fixed_patch" => false, "fixed_patch_value" => 5.0, "fixed_patch_x" => nothing, "fixed_patch_y" => nothing, "fixed_patch_radius" => 0,
        "log_freq" => 1, "log_genomes" => false, "random_seed" => nothing, "verbose" => false
    )
end

"""
    normalize_specs(user_specs::AbstractDict)

Shallow merges user-provided overrides into the master default dictionary.
Safely handles type conversions (e.g., from an inferred Dict{String, Int}).
"""
function normalize_specs(user_specs::AbstractDict)
    defaults = get_default_specs()
    # Convert incoming dict to Dict{String, Any} to prevent type errors on merge
    user_any = Dict{String, Any}(string(k) => v for (k, v) in user_specs)
    return merge(defaults, user_any)
end