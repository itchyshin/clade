using GLMakie
using Clade
using Statistics # Required for calculating means

# =====================================================================
# 1. THE INJECTION
# We inject a single-tick step function directly into the Clade module 
# so it has access to all of Sergio's unexported internal functions.
# =====================================================================
@eval Clade begin
    function step_tick!(env, specs)
        env.t += Int32(1)
        
        _reset_counters!(env)

        # ── Core tick sequence ───────────────────────────────────────────
        grow_grass!(env)
        apply_fixed_patch!(env)           
        grow_resources!(env)              
        apply_niche_construction!(env)
        
        env.t == 1 && seed_predators!(env)
        
        tick_agents!(env)
        apply_responsive_personalities!(env)
        tick_predators!(env)              
        apply_body_size!(env)             
        apply_brain_size_evolution!(env)  
        apply_ann_regularization!(env)    
        apply_dispersal!(env)             
        apply_habitat_preference!(env)    
        apply_seasonal_mortality!(env)    
        apply_toxicity_costs!(env)        
        apply_signal_costs!(env)          
        apply_plasticity_cost!(env)       
        apply_signal_mortality!(env)      
        apply_preference_bias!(env)       
        apply_signal_evolution!(env)      
        apply_signal_toxicity_pleiotropy!(env)  
        apply_coevolving_parasites!(env)  

        # ── Optional modules ─────────────────────────────────────────────
        if env.t == 1 && Bool(get(specs, "disease", false))
            seed_disease!(env)
        end
        
        apply_disease!(env)
        apply_kin_altruism!(env)
        apply_iffolk!(env)                
        apply_scavenging!(env)
        decay_carrion!(env)
        apply_cooperation!(env)
        apply_epigenetics!(env)
        apply_care_costs!(env)            
        feed_offspring!(env)              
        age_juveniles!(env)               
        apply_cooperative_breeding!(env)  
        
        if Bool(get(specs, "social_learning", false))
            sl_freq = Int(get(specs, "social_learning_freq", 10))
            sl_freq > 0 && env.t % sl_freq == 0 && apply_social_learning!(env)
        end
        
        if String(get(specs, "rl_mode", "none")) != "none"
            rl_freq = Int(get(specs, "rl_update_freq", 1))
            rl_freq > 0 && env.t % rl_freq == 0 && apply_rl!(env)
        end
        
        assign_species!(env)
        apply_antipredator_game!(env)
        apply_hawkdove_game!(env)
        apply_reciprocal_altruism!(env)

        # ── Death and reproduction ───────────────────────────────────────
        kill_dead!(env)
        remove_dead!(env)
        update_unions!(env)
        graduate_offspring!(env)          
        apply_lifehistory_tradeoff!(env)
        create_offspring!(env)

        # ── Logging ──────────────────────────────────────────────────────
        log_freq = Int(get(specs, "log_freq", 1))
        if env.t % log_freq == 0
            log_tick!(env)
            log_genomes!(env)
        end
    end
end

# =====================================================================
# 2. THE VISUALIZER UI (6-Panel Dashboard)
# =====================================================================
function launch_visualizer(specs::Dict{String, Any})
    env = Clade.create_environment(specs)
    env.t = Int32(0) 
    
    # ─── DATA HELPERS ────────────────────────────────────────────────
    get_agent_coords(e) = isempty(e.agents) ? Point2f[] : [Point2f(a.x, a.y) for a in e.agents]
    get_ages(e)         = isempty(e.agents) ? Float32[] : [Float32(a.age) for a in e.agents]
    get_energies(e)     = isempty(e.agents) ? Float32[] : [Float32(a.energy) for a in e.agents]
    get_mean_energy(e)  = isempty(e.agents) ? 0.0f0 : Float32(mean(a.energy for a in e.agents))
    
    # ─── OBSERVABLES (Reactive Data) ─────────────────────────────────
    # Grid 1: Spatial Map
    grass_obs = Observable(env.grass)
    agent_obs = Observable(get_agent_coords(env))
    title_obs = Observable("Spatial Map - Tick 0 | Pop: $(length(env.agents))")
    
    # Grids 2, 3, 4: Time Series Arrays
    time_hist   = Observable(Float32[0.0])
    pop_hist    = Observable(Float32[length(env.agents)])
    energy_hist = Observable(Float32[get_mean_energy(env)])
    grass_hist  = Observable(Float32[sum(env.grass)])
    
    # Grids 5 & 6: Scatter Data
    agent_ages     = Observable(get_ages(env))
    agent_energies = Observable(get_energies(env))

    # ─── UI LAYOUT (2x3 Grid) ────────────────────────────────────────
    # Expanded window size to fit 6 panels comfortably
    fig = Figure(size = (1600, 900))
    
    # [1, 1] Spatial Map
    ax1 = Axis(fig[1, 1], title = title_obs, aspect = DataAspect())
    heatmap!(ax1, grass_obs, colormap = :Greens, colorrange = (0, 5))
    scatter!(ax1, agent_obs, color = :dodgerblue, markersize = 12, strokecolor = :black, strokewidth = 1)
    
    # [1, 2] Population Dynamics
    ax2 = Axis(fig[1, 2], title = "Population Dynamics", xlabel = "Tick", ylabel = "Alive Agents")
    lines!(ax2, time_hist, pop_hist, color = :dodgerblue, linewidth = 2.5)
    
    # [1, 3] Mean Energy
    ax3 = Axis(fig[1, 3], title = "Mean Agent Energy", xlabel = "Tick", ylabel = "Energy")
    lines!(ax3, time_hist, energy_hist, color = :crimson, linewidth = 2.5)
    
    # [2, 1] Total Grass Biomass
    ax4 = Axis(fig[2, 1], title = "Total Grass Biomass", xlabel = "Tick", ylabel = "Sum of Grass")
    lines!(ax4, time_hist, grass_hist, color = :forestgreen, linewidth = 2.5)
    
    # [2, 2] Age vs Energy Scatter
    ax5 = Axis(fig[2, 2], title = "Living Demographics: Age vs Energy", xlabel = "Age (ticks)", ylabel = "Energy")
    scatter!(ax5, agent_ages, agent_energies, color = :purple, markersize = 8, alpha = 0.6)
    
    # [2, 3] Spatial Age Map (Replaces the TSNE map)
    ax6 = Axis(fig[2, 3], title = "Spatial Demographics (Yellow = Older)", aspect = DataAspect())
    # No grass here so the agent colors pop
    scatter!(ax6, agent_obs, color = agent_ages, colormap = :plasma, markersize = 12)

    # ─── CONTROL PANEL ───────────────────────────────────────────────
    ui_layout = fig[3, 1:3] = GridLayout()
    play_button = Button(ui_layout[1, 1], label = "Play", width = 150)
    step_button = Button(ui_layout[1, 2], label = "Step Forward", width = 150)
    
    is_running = Observable(false)
    max_t = Int(specs["max_ticks"])
    
    # ─── LOOP LOGIC ──────────────────────────────────────────────────
    function update_dashboard!()
        # 1. Update Map
        grass_obs[] = env.grass
        agent_obs[] = get_agent_coords(env)
        title_obs[] = "Spatial Map - Tick $(env.t) | Pop: $(length(env.agents))"
        
        # 2. Push to Time Series
        push!(time_hist[], Float32(env.t))
        push!(pop_hist[], Float32(length(env.agents)))
        push!(energy_hist[], get_mean_energy(env))
        push!(grass_hist[], Float32(sum(env.grass)))
        
        # Tell Makie the arrays changed
        notify(time_hist)
        notify(pop_hist)
        notify(energy_hist)
        notify(grass_hist)
        
        # 3. Update Scatters
        agent_ages[] = get_ages(env)
        agent_energies[] = get_energies(env)
        
        # 4. Auto-scale line and scatter plots dynamically
        autolimits!(ax2)
        autolimits!(ax3)
        autolimits!(ax4)
        autolimits!(ax5)
    end

    on(play_button.clicks) do _
        is_running[] = !is_running[]
        play_button.label = is_running[] ? "Pause" : "Play"
        
        if is_running[]
            @async while is_running[] && env.t < max_t
                Clade.step_tick!(env, specs)
                update_dashboard!()
                sleep(0.05) 
            end
        end
    end
    
    on(step_button.clicks) do _
        if !is_running[] && env.t < max_t
            Clade.step_tick!(env, specs)
            update_dashboard!()
        end
    end
    
    display(fig)
    return fig
end

# =====================================================================
# 3. LAUNCH SCRIPT
# =====================================================================
println("Initializing Clade 6-Panel Visualizer...")

specs = Dict{String, Any}(
    "grid_rows" => 30, "grid_cols" => 30, "toroidal" => true, "random_tick_order" => true,
    "n_agents_init" => 50, "max_agents" => 500, "max_ticks" => 1000,
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

launch_visualizer(specs)