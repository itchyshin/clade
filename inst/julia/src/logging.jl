"""
    logging.jl — Pre-allocated progress logging and get_run_data helpers.

## Design

All logging vectors are pre-allocated to `max_ticks` elements in
`_init_progress()`. Each call to `log_tick!()` writes to the next position
without allocating. This avoids per-tick allocation in the hot path.

The structure of `env.progress` matches the output of `get_run_data(env)\$ticks`
in R: a named dict of equal-length vectors, one entry per logged tick.
"""

"""
    _init_progress(specs, n_ticks) -> Dict{String, Vector}

Pre-allocate all logged time-series vectors. Called once in
`create_environment()`. All vectors are initialised to 0 (or 0.0).

The set of logged variables expands automatically when optional modules are
enabled.
"""
function _init_progress(specs::Dict{String,Any}, n_ticks::Int)::Dict{String,Vector}
    iz = zeros(Int32, n_ticks)
    fz = zeros(Float64, n_ticks)

    d = Dict{String, Vector}(
        "t"                 => copy(iz),
        "n_agents"          => copy(iz),
        "n_births"          => copy(iz),
        "n_deaths"          => copy(iz),
        "n_starvations"     => copy(iz),
        "n_age_deaths"      => copy(iz),
        "mean_energy"       => copy(fz),
        "sd_energy"         => copy(fz),
        "mean_age"          => copy(fz),
        "sd_age"            => copy(fz),
        "mean_body_size"    => copy(fz),
        "sd_body_size"      => copy(fz),
        "genetic_diversity" => copy(fz),
        "n_species"         => copy(iz),
        "mean_cooperation_level" => copy(fz),
        "mean_immune_strength"   => copy(fz),
        "sd_immune_strength"     => copy(fz),
        "mean_metabolic_rate"    => copy(fz),
        "mean_learning_rate"     => copy(fz),
        "mean_prior_sigma"       => copy(fz),   # BNN-only; 0 for other brains
        "grass_coverage"         => copy(fz),
        "n_infected"             => copy(iz),
        "n_new_infections"       => copy(iz),
        "n_altruistic_acts"      => copy(iz),
        "n_shelters_built"       => copy(iz),
        "n_shelter_occupied"     => copy(iz),
        "n_cooperation_acts"     => copy(iz),
        "n_dispersal_events"     => copy(iz),
        "n_habitat_moves"        => copy(iz),
        # Phase 7c–7f modules (always allocated; 0 when module disabled)
        "n_predators"            => copy(iz),
        "n_prey_killed"          => copy(iz),
        "n_juveniles"            => copy(iz),
        "n_helpers"              => copy(iz),
        "n_toxic_attacks"        => copy(iz),
        "n_avoided_attacks"      => copy(iz),
        "mean_signal_magnitude"  => copy(fz),
        # 0.6.2 — preference and signal-preference dynamics.
        # These three metrics operationalise quantities from the
        # Fuller, Houle & Travis (2005) *Am Nat* unified quantitative-
        # genetic framework for sexual-selection models:
        #   mean_preference_magnitude   ≈ mean preference phenotype p̄
        #   mean_signal_preference_dist ≈ proxy for −C_tp (preference-
        #       display covariance); shrinks under Fisher/good-genes
        #       coevolution, stays large under sensory bias alone
        #   sd_signal_magnitude         ≈ proxy for V_t (additive
        #       genetic variance in the display trait)
        # Together they distinguish Fisher runaway, sensory bias,
        # and drift-only outcomes in the Fuller 2005 framework.
        "mean_preference_magnitude"  => copy(fz),
        "mean_signal_preference_dist" => copy(fz),
        "sd_signal_magnitude"         => copy(fz),
        "mean_toxicity"          => copy(fz),
        "mean_plasticity"        => copy(fz),
        "mean_helper_tendency"   => copy(fz),
        "mean_habitat_preference" => copy(fz),
        "mean_brain_size"         => copy(fz),
        # Tier 1: complex landscape
        "n_ground_agents"        => copy(iz),
        "n_shrub_agents"         => copy(iz),
        "n_canopy_agents"        => copy(iz),
        "mean_wing_size"         => copy(fz),
        "mean_shrub_coverage"    => copy(fz),
        "mean_canopy_coverage"   => copy(fz),
        # Tier 2a: spatial sorting
        "n_front_agents"         => copy(iz),
        "mean_front_dispersal"   => copy(fz),
        "mean_rear_dispersal"    => copy(fz),
        # Tier 2b: IFfolk inclusive fitness
        "n_iffolk_transfers"     => copy(iz),
        # Session 2: previously-NA fields (B1–B6)
        "mean_relatedness"   => copy(fz),   # B1: kin selection; 0 when disabled
        "n_scavenge_events"  => copy(iz),   # B2: carrion consumption events per tick
        "n_gd_events"        => copy(iz),   # B3: group defense applications per tick
        "mean_shelter_depth" => copy(fz),   # B4: mean depth of occupied shelter cells
        "mean_mutation_rate" => copy(fz),   # B5: mean agent mutation_sd; 0 when not evolved
        "mean_clutch_size"   => copy(fz),   # B6: mean realized clutch size per tick
        "mean_ann_weight_magnitude" => copy(fz),  # B7: mean |w| per agent; 0 when regularization off
    )

    d
end

"""
    _init_deaths() -> Dict{String, Vector}

Pre-allocate the deaths log. Grows dynamically (push!).
"""
function _init_deaths()::Dict{String, Vector}
    Dict{String, Vector}(
        "id"           => Int[],
        "t"            => Int[],
        "age"          => Int[],
        "energy"       => Float64[],
        "cause"        => String[],
        "body_size"    => Float64[],
        "num_offspring"=> Int[],
    )
end

"""
    log_tick!(env::Environment)

Write population statistics for the current tick into `env.progress`.
Reads `env.t` to determine the write position.
"""
function log_tick!(env::Environment)
    t   = Int(env.t)
    p   = env.progress
    ags = env.agents

    n = length(ags)
    n == 0 && return   # no agents: skip (vectors remain 0)

    # Precompute
    energies  = Float64[ag.energy       for ag in ags]
    ages      = Float64[ag.age          for ag in ags]
    bsizes    = Float64[ag.body_size    for ag in ags]
    coops     = Float64[ag.cooperation_level for ag in ags]
    imms      = Float64[ag.immune_strength   for ag in ags]
    metabs    = Float64[ag.metabolic_rate    for ag in ags]
    lrs       = Float64[ag.learning_rate     for ag in ags]

    # Prior sigma for BNN brains
    sigmas = Float64[]
    for ag in ags
        if ag.brain isa BNNBrain
            push!(sigmas, Float64(mean(ag.brain.sigma)))
        end
    end

    # Genetic diversity: mean pairwise genome distance (sample up to 50 pairs)
    gdiv = _sample_genetic_diversity(ags, env.rng)

    # Grass coverage
    gmax   = Float32(get(env.specs, "grass_max", 5.0))
    gcov   = Float64(sum(env.grass .> 0.0f0)) / Float64(length(env.grass))

    p["t"][t]                  = t
    p["n_agents"][t]           = n
    p["n_births"][t]           = Int(env.n_births)
    p["n_deaths"][t]           = Int(env.n_deaths)
    p["n_starvations"][t]      = Int(env.n_starvations)
    p["n_age_deaths"][t]       = Int(env.n_age_deaths)
    p["mean_energy"][t]        = mean(energies)
    p["sd_energy"][t]          = n > 1 ? std(energies) : 0.0
    p["mean_age"][t]           = mean(ages)
    p["sd_age"][t]             = n > 1 ? std(ages) : 0.0
    p["mean_body_size"][t]     = mean(bsizes)
    p["sd_body_size"][t]       = n > 1 ? std(bsizes) : 0.0
    p["genetic_diversity"][t]  = gdiv
    p["n_species"][t]          = Int(maximum(ag.species_id for ag in ags))
    p["mean_cooperation_level"][t] = mean(coops)
    p["mean_immune_strength"][t]   = mean(imms)
    p["sd_immune_strength"][t]     = n > 1 ? std(imms) : 0.0
    p["mean_metabolic_rate"][t]    = mean(metabs)
    p["mean_learning_rate"][t]     = mean(lrs)
    p["mean_prior_sigma"][t]       = isempty(sigmas) ? 0.0 : mean(sigmas)
    p["grass_coverage"][t]         = gcov
    p["n_infected"][t]             = count(ag -> ag.infected, ags)
    p["n_new_infections"][t]       = Int(env.n_new_infections)
    p["n_altruistic_acts"][t]      = Int(env.n_altruistic_acts)
    p["n_shelters_built"][t]       = Int(env.n_shelters_built)
    # Count agents currently sitting on a sheltered cell (depth > 0).
    # This is the natural observable for heritable niche construction
    # (Odling-Smee et al. 2003): shelters persist beyond their builders,
    # and descendant lineages that locate to sheltered cells reap the
    # cumulative benefit. When shelter_occupancy_bonus > 0 (see
    # modules/niche.jl apply_shelter_occupancy_benefit!) this metric
    # directly tracks the number of beneficiaries per tick.
    n_occ = 0
    if Bool(get(env.specs, "niche_construction", false))
        for ag in ags
            env.shelter_map[Int(ag.x), Int(ag.y)] > 0 && (n_occ += 1)
        end
    end
    p["n_shelter_occupied"][t] = n_occ
    p["n_cooperation_acts"][t]     = Int(env.n_cooperation_acts)
    p["n_dispersal_events"][t]     = Int(env.n_dispersal_events)
    p["n_habitat_moves"][t]        = Int(env.n_habitat_moves)

    # Phase 7c–7f columns
    p["n_predators"][t]         = length(env.predators)
    p["n_prey_killed"][t]       = Int(env.n_deaths)   # includes prey deaths from predators
    n_juv = sum(ag.care_load for ag in ags; init = 0)
    p["n_juveniles"][t]         = n_juv
    p["n_helpers"][t]           = Int(env.n_helpers)
    p["n_toxic_attacks"][t]     = Int(env.n_toxic_attacks)
    p["n_avoided_attacks"][t]   = Int(env.n_avoided_attacks)
    sig_dims = Int(get(env.specs, "signal_dims", 0))
    if sig_dims > 0 && n > 0
        sig_mags = Float64[sum(abs.(ag.signal)) for ag in ags]
        pref_mags = Float64[sum(abs.(ag.preference)) for ag in ags]
        # Per-agent L2 distance between signal and preference vectors.
        # Direct measure of signal-preference coevolution:
        #   - small distance ⇒ signals track preferences (Fisher runaway)
        #   - large distance ⇒ signals and preferences drift independently
        sp_dists = Float64[sqrt(sum(abs2, ag.signal .- ag.preference)) for ag in ags]
        p["mean_signal_magnitude"][t]       = mean(sig_mags)
        p["sd_signal_magnitude"][t]         = length(sig_mags) > 1 ? std(sig_mags) : 0.0
        p["mean_preference_magnitude"][t]   = mean(pref_mags)
        p["mean_signal_preference_dist"][t] = mean(sp_dists)
    else
        # signal_dims == 0 ⇒ signals/preferences vectors are empty;
        # all four metrics are identically zero.
        p["mean_signal_magnitude"][t]       = 0.0
        p["sd_signal_magnitude"][t]         = 0.0
        p["mean_preference_magnitude"][t]   = 0.0
        p["mean_signal_preference_dist"][t] = 0.0
    end
    p["mean_toxicity"][t]       = mean(ag.toxicity for ag in ags)
    p["mean_plasticity"][t]     = mean(ag.plasticity for ag in ags)
    p["mean_helper_tendency"][t]    = mean(ag.helper_tendency for ag in ags)
    p["mean_habitat_preference"][t] = mean(ag.habitat_preference for ag in ags)
    p["mean_brain_size"][t]         = mean(ag.brain_size for ag in ags)

    # Tier 1: complex landscape
    complex_on = Bool(get(env.specs, "complex_landscape", false))
    if complex_on
        p["n_ground_agents"][t]   = count(ag -> ag.niche_layer == 1, ags)
        p["n_shrub_agents"][t]    = count(ag -> ag.niche_layer == 2, ags)
        p["n_canopy_agents"][t]   = count(ag -> ag.niche_layer == 3, ags)
        p["mean_wing_size"][t]    = mean(ag.wing_size for ag in ags)
        shrub_vals = env.shrub_map[env.shrub_map .> 0.0f0]
        canopy_vals = env.canopy_map[env.canopy_map .> 0.0f0]
        p["mean_shrub_coverage"][t]  = isempty(shrub_vals)  ? 0.0 :
            Float64(length(shrub_vals)) / Float64(length(env.shrub_map))
        p["mean_canopy_coverage"][t] = isempty(canopy_vals) ? 0.0 :
            Float64(length(canopy_vals)) / Float64(length(env.canopy_map))
    end

    # Tier 2a: spatial sorting
    sort_on = Bool(get(env.specs, "spatial_sorting", false))
    if sort_on && n > 0
        p["n_front_agents"][t] = Int(env.n_front_agents)
        cx = _sort_cx[]
        cy = _sort_cy[]
        dm = _sort_dmax[]
        front_thr = Float32(get(env.specs, "sorting_front_threshold", 0.75))
        front_disps = Float64[]
        rear_disps  = Float64[]
        for ag in ags
            d = sqrt((Float32(ag.x) - cx)^2 + (Float32(ag.y) - cy)^2)
            if d / dm >= front_thr
                push!(front_disps, Float64(ag.dispersal_tendency))
            else
                push!(rear_disps, Float64(ag.dispersal_tendency))
            end
        end
        p["mean_front_dispersal"][t] = isempty(front_disps) ? 0.0 : mean(front_disps)
        p["mean_rear_dispersal"][t]  = isempty(rear_disps)  ? 0.0 : mean(rear_disps)
    end

    # Tier 2b: IFfolk inclusive fitness
    p["n_iffolk_transfers"][t] = Int(env.n_iffolk_transfers)

    # Session 2: previously-NA fields (B1–B6)

    # B1: mean pairwise relatedness (sampled; 0 when kin_selection disabled)
    if Bool(get(env.specs, "kin_selection", false)) && n >= 2
        n_pairs = min(20, n * (n - 1) ÷ 2)
        r_total = 0.0
        sampled = 0
        for _ in 1:n_pairs
            i = rand(env.rng, 1:n)
            j = rand(env.rng, 1:n)
            i == j && continue
            r_total += Float64(compute_relatedness(ags[i], ags[j]))
            sampled += 1
        end
        p["mean_relatedness"][t] = sampled > 0 ? r_total / sampled : 0.0
    end

    # B2: scavenging consumption events
    p["n_scavenge_events"][t] = Int(env.n_scavenge_events)

    # B3: group defense applications
    p["n_gd_events"][t] = Int(env.n_gd_events)

    # B4: mean shelter depth (non-zero cells only; 0 when no shelters exist)
    if Bool(get(env.specs, "niche_construction", false))
        shelter_vals = view(env.shelter_map, env.shelter_map .> Int32(0))
        p["mean_shelter_depth"][t] = isempty(shelter_vals) ? 0.0 :
            mean(Float64.(shelter_vals))
    end

    # B5: mean evolved mutation rate (only when mutation_rate_evolution = TRUE)
    if Bool(get(env.specs, "mutation_rate_evolution", false))
        p["mean_mutation_rate"][t] = mean(Float64(ag.mutation_sd) for ag in ags)
    end

    # B6: mean realized clutch size this tick
    p["mean_clutch_size"][t] = if env.n_repro_events > 0
        Float64(env.n_clutch_total) / Float64(env.n_repro_events)
    else
        Float64(get(env.specs, "max_clutch_size", 1))
    end

    # B7: mean ANN weight magnitude (always logged; useful even without regularisation)
    p["mean_ann_weight_magnitude"][t] = if n > 0
        mean(_ann_weight_magnitude(ag.brain) for ag in ags)
    else
        0.0
    end
end

"""
    _sample_genetic_diversity(agents, rng) -> Float64

Estimate mean pairwise genome distance by sampling up to 50 random pairs.
Returns 0 when fewer than 2 agents are alive.

Full O(n^2) pairwise distance is too expensive for large populations; this
Monte Carlo estimator with 50 pairs is accurate to ~5% for n > 50.
"""
function _sample_genetic_diversity(agents::Vector{Agent}, rng)::Float64
    n = length(agents)
    n < 2 && return 0.0
    n_pairs = min(50, n * (n - 1) ÷ 2)
    total   = 0.0
    for _ in 1:n_pairs
        i = rand(rng, 1:n)
        j = rand(rng, 1:n)
        i == j && continue
        total += Float64(genome_distance(agents[i].genome, agents[j].genome))
    end
    total / n_pairs
end

"""
    log_genomes!(env::Environment)

Snapshot every alive agent's trait genome (haplotype 1 only — the maternal
trait vector, which equals the expressed phenotype for haploid agents and
is one of two haplotypes for diploid agents) and push to `env.genome_log`.

Only fires when `specs["log_genomes"] == true`. Called once per tick
right after `log_tick!`; the same `log_freq` gate applies upstream in
the tick loop, so log_genomes inherits the same sampling cadence.

Each pushed entry is a `Dict{String,Any}` with:
  - `"t"`         => the tick number
  - `"agent_ids"` => `Vector{Int64}` of agent IDs at this tick
  - `"traits"`    => `Matrix{Float32}` of size (n_alive × N_SCALAR_TRAITS),
                     row i = `agent_ids[i]`'s maternal_traits vector

The R-side `get_genome_data()` composes a single tall data.frame from
these per-tick snapshots; `plot_tsne_genomes()` runs PCA on the
resulting matrix.

This is a deliberately minimal genome snapshot: only the heritable
22-trait scalar vector, not the full brain weight matrix (which is
brain-architecture-specific and would inflate the log by orders of
magnitude). Sufficient for population-genetic structure analyses;
adding weights is straightforward future work.
"""
function log_genomes!(env::Environment)
    Bool(get(env.specs, "log_genomes", false)) || return
    ags_alive = [a for a in env.agents if a.alive]
    n = length(ags_alive)
    n == 0 && return

    # Matrix: rows = agents, cols = N_SCALAR_TRAITS
    mat = Matrix{Float32}(undef, n, N_SCALAR_TRAITS)
    ids = Vector{Int64}(undef, n)
    for (i, ag) in enumerate(ags_alive)
        ids[i] = Int64(ag.id)
        @inbounds for j in 1:N_SCALAR_TRAITS
            mat[i, j] = ag.genome.maternal_traits[j]
        end
    end

    push!(env.genome_log, Dict{String,Any}(
        "t"         => Int(env.t),
        "agent_ids" => ids,
        "traits"    => mat,
    ))
    return
end
