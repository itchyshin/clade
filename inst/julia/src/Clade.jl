"""
    Clade.jl — Entry point for the Clade simulation engine.

This module is loaded by clade's R package via JuliaConnectoR:
    JuliaConnectoR::juliaEval('include("<path>/Clade.jl")')

The public API (called from R) is:
    Clade.run_clade(specs::Dict) -> NamedTuple (env)
    Clade.create_environment(specs::Dict) -> Environment

All other functions are internal.

Architecture
------------
1. types.jl     — AbstractBrain, DiploidGenome, Agent, Environment
2. genome.jl    — meiosis, phenotype expression, genome distance
3. brains/*.jl  — six brain implementations + make_brain() dispatcher
4. sense.jl     — sensory input vector construction
5. tick.jl      — per-tick agent update (movement, eating, energy)
6. reproduce.jl — offspring creation (meiosis → brain → agent)
7. death.jl     — mortality: starvation, senescence, disease, age
8. modules/*.jl — optional biological modules (disease, kin, cooperation, ...)
9. logging.jl   — init_progress!, log_tick!, get_run_data
10. search.jl   — MAP-Elites, CMA-ES, gradient search

Calling convention
------------------
All stateful objects are passed explicitly (no globals). The Environment is
modified in place by tick!, die!, reproduce! etc. Agents that die within a
tick have `alive` set to false; they are removed from `env.agents` at the end
of each tick in `remove_dead!()`. This is the same pattern used in alifeR
(agents removed after `remove_dead_agents()` in run_alife.R).
"""
module Clade

using Random: Xoshiro, seed!, default_rng, randperm
using Statistics: mean, std
using LinearAlgebra: norm

# ── Load sub-modules in dependency order ──────────────────────────────────────

include("types.jl")

# D1: wrap_or_clamp — toroidal-or-bounded grid helper
# Used by all modules that iterate over Moore/Chebyshev neighbourhoods.
# When toroidal = true  → mod1(x, n)   (classic wraparound)
# When toroidal = false → clamp(x, 1, n) (reflective boundary)
@inline function wrap_or_clamp(x::Int, n::Int, toroidal::Bool)::Int
    toroidal ? mod1(x, n) : clamp(x, 1, n)
end
include("genome.jl")

# Brains (load all; make_brain() selects at runtime)
include("brains/ann.jl")
include("brains/bnn.jl")
include("brains/ctrnn.jl")
include("brains/grn.jl")

# Defer heavier brain types for later phases; stubs emit clear error messages.
# Replace each stub with the real include() as that phase is implemented.
# include("brains/transformer.jl")
# include("brains/synthesis.jl")

include("sense.jl")
include("tick.jl")
include("reproduce.jl")
include("death.jl")
include("logging.jl")

# Optional module includes — each is a no-op when its flag is false
include("modules/disease.jl")
include("modules/kin.jl")
include("modules/cooperation.jl")
include("modules/scavenging.jl")
include("modules/niche.jl")
include("modules/epigenetics.jl")
include("modules/social_learning.jl")
include("modules/rl.jl")
include("modules/mimicry.jl")
include("modules/signals.jl")
include("modules/coevolving_parasite.jl")
include("modules/speciation.jl")
include("modules/tick_predators.jl")
include("modules/group_defense.jl")
include("modules/dispersal.jl")
include("modules/habitat_preference.jl")
include("modules/seasonal.jl")
include("modules/parental_care.jl")
include("modules/cooperative_breeding.jl")
include("modules/body_size.jl")
include("modules/brain_size_evolution.jl")
include("modules/plasticity.jl")
# include("modules/world_evolution.jl")

# Tier 1–2 new modules
include("modules/complex_landscape.jl")
include("modules/spatial_sorting.jl")
include("modules/fixed_patch.jl")
include("modules/lamarckian.jl")
include("modules/ann_regularization.jl")

# ── R-to-Julia specs bridge ───────────────────────────────────────────────────

"""
    r_specs_to_dict(nt) -> Dict{String,Any}

Convert the object received from R (via JuliaConnectoR) into the
`Dict{String,Any}` expected by `run_clade`. JuliaConnectoR wraps a named R
list as an `RConnector.ElementList` whose fields include `names` (a vector
of symbols) and `namedelements` (a `Dict{Symbol,Any}`), so we iterate over
the symbols to preserve R-side ordering.

If a caller already holds a `Dict`, pass it through unchanged. This lets
internal tests call `run_clade(Dict(...))` directly.
"""
r_specs_to_dict(d::Dict{String,Any}) = d

function r_specs_to_dict(nt)
    d = Dict{String,Any}()
    # Prefer iterating over `names` for a deterministic order when the input
    # is an RConnector.ElementList, falling back to `pairs` for NamedTuples
    # or other Associative types.
    if hasproperty(nt, :names) && hasproperty(nt, :namedelements)
        for k in getfield(nt, :names)
            d[string(k)] = getfield(nt, :namedelements)[k]
        end
    else
        for (k, v) in pairs(nt)
            d[string(k)] = v
        end
    end
    d
end

# ── Brain dispatcher ──────────────────────────────────────────────────────────

"""
    make_brain(g::DiploidGenome, specs) -> AbstractBrain

Construct the appropriate brain type from the genome and specs.
"""
function make_brain(g::DiploidGenome, specs::Dict{String,Any})::AbstractBrain
    bt = get(specs, "brain_type", "bnn")
    brain = if bt == "ann"
        make_ann_brain_from_genome(g, specs)
    elseif bt == "bnn"
        make_bnn_brain(g, specs)
    elseif bt == "ctrnn"
        make_ctrnn_brain_from_genome(g, specs)
    elseif bt == "grn"
        make_grn_brain_from_genome(g, specs)
    elseif bt == "random"
        make_random_brain(g.architecture)
    else
        error("Brain type '$bt' is not yet implemented. " *
              "Supported: \"ann\", \"bnn\", \"ctrnn\", \"grn\", \"random\". " *
              "Transformer and Synthesis are planned for later phases.")
    end
    # Discrete/quantized weights: snap to allowed set when ann_weight_values is set.
    pv = get(specs, "ann_weight_values", nothing)
    if !isnothing(pv) && length(pv) > 0
        _quantize_brain_weights!(brain, Float32.(pv))
    end
    brain
end

# ── Random brain (null model) ─────────────────────────────────────────────────

"""
    RandomBrain <: AbstractBrain

Chooses actions uniformly at random. Used as a null model baseline.
"""
struct RandomBrain <: AbstractBrain
    arch ::Vector{Int32}
end

n_inputs(b::RandomBrain)  = Int(b.arch[1])
n_actions(b::RandomBrain) = Int(b.arch[end])

function forward(b::RandomBrain, input::Vector{Float32})::Vector{Float32}
    n = n_actions(b)
    fill(Float32(1.0 / n), n)
end

mutate(b::RandomBrain, ::Float32, ::Any) = b
crossover(b1::RandomBrain, ::RandomBrain, ::Vector{Int}, ::Any) = b1
flatten(b::RandomBrain) = zeros(Float32, arch_to_n_weights(b.arch))
brain_size(b::RandomBrain) = arch_to_n_weights(b.arch)

make_random_brain(arch) = RandomBrain(arch)

# ── Environment construction ──────────────────────────────────────────────────

"""
    create_environment(specs::Dict{String,Any}) -> Environment

Initialise a new simulation environment. Called once before the tick loop.

Steps:
1. Seed the RNG (or use a random seed).
2. Allocate and populate the grass grid.
3. Determine brain architecture from `specs["brain_type"]` and
   `specs["hidden_layers"]`.
4. Create `n_agents_init` founder agents with random positions.
5. Build the agent_map from agent positions.
6. Pre-allocate the progress logging vectors.
"""
function create_environment(specs::Dict{String,Any})::Environment
    # 1. RNG
    seed_val = get(specs, "random_seed", nothing)
    rng = if seed_val === nothing || seed_val isa Nothing
        Xoshiro()   # random seed
    else
        Xoshiro(Int(seed_val))
    end

    rows = Int(specs["grid_rows"])
    cols = Int(specs["grid_cols"])

    # 2. Grass grid
    grass = Matrix{Float32}(undef, rows, cols)
    gmax  = Float32(get(specs, "grass_max", 5.0))
    gprob = Float32(get(specs, "grass_init_prob", 0.5))
    for i in eachindex(grass)
        grass[i] = rand(rng) < gprob ? gmax : 0.0f0
    end

    # 3. Brain architecture
    arch = _build_arch(specs)

    # 4. Founder agents
    n_init  = Int(specs["n_agents_init"])
    agents  = Vector{Agent}(undef, n_init)
    next_id = Int64(1)

    for i in 1:n_init
        g  = make_genome(specs, arch, rng)
        br = make_brain(g, specs)
        ag = _make_founder_agent(next_id, g, br, specs, rng)
        agents[i] = ag
        next_id += 1
    end

    # 5. Agent map
    agent_map = zeros(Int64, rows, cols)
    for (idx, ag) in enumerate(agents)
        agent_map[ag.x, ag.y] = idx
    end

    # 6. Logging
    n_log_ticks = Int(specs["max_ticks"])
    progress    = _init_progress(specs, n_log_ticks)
    deaths      = _init_deaths()

    # Complex landscape resource layers (allocated even when disabled; zero-filled)
    shrub_density  = Bool(get(specs, "complex_landscape", false)) ?
                     Float32(get(specs, "shrub_density",  0.3)) : 0.0f0
    canopy_density = Bool(get(specs, "complex_landscape", false)) ?
                     Float32(get(specs, "canopy_density", 0.15)) : 0.0f0
    shrub_map  = Matrix{Float32}(undef, rows, cols)
    canopy_map = Matrix{Float32}(undef, rows, cols)
    for i in eachindex(shrub_map)
        shrub_map[i]  = rand(rng) < shrub_density  ? Float32(get(specs, "shrub_energy",  20.0)) * 0.5f0 : 0.0f0
        canopy_map[i] = rand(rng) < canopy_density ? Float32(get(specs, "canopy_energy", 50.0)) * 0.5f0 : 0.0f0
    end

    env = Environment(
        grass,
        agent_map,
        zeros(Int64,    rows, cols),   # predator_map
        zeros(Int32,    rows, cols),   # shelter_map
        zeros(Float32,  rows, cols),   # carrion_map
        zeros(Bool,     rows, cols),   # carrion_infected_map
        shrub_map,
        canopy_map,
        agents,
        Agent[],                        # predators (empty)
        next_id,
        Int32(0),                       # t = 0 (incremented at start of tick)
        rng,
        specs,
        # per-tick counters (all zero)
        Int32(0), Int32(0), Int32(0), Int32(0),
        Int32(0), Int32(0), Int32(0), Int32(0),
        Int32(0), Int32(0), Int32(0), Int32(0), Int32(0),
        Int32(0),                       # n_dispersal_events
        Int32(0),                       # n_habitat_moves
        Int32(0),                       # n_helpers
        Int32(0),                       # n_front_agents
        Int32(0),                       # n_iffolk_transfers
        Int32(0),                       # n_scavenge_events
        Int32(0),                       # n_gd_events
        Int32(0),                       # n_repro_events
        Int32(0),                       # n_clutch_total
        progress,
        deaths,
        Any[]                           # genome_log
    )

    # Fixed patch: resolve cells once and cache for zero-alloc tick access
    if Bool(get(specs, "fixed_patch", false))
        patch_cells = _fixed_patch_cells(specs, rows, cols)
        env.specs["_fixed_patch_cells"] = patch_cells
        val = Float32(get(specs, "fixed_patch_value", 5.0))
        @inbounds for ci in patch_cells
            env.grass[ci] = val
        end
    end

    env
end

# ── Main simulation loop ──────────────────────────────────────────────────────

"""
    run_clade(specs::Dict{String,Any}) -> NamedTuple

Run a complete simulation and return the final environment state plus all
logged data. Called from R via:
    JuliaConnectoR::juliaCall("Clade.run_clade", specs_dict)

Returns a NamedTuple with fields:
- `agents`     — Vector of agent NamedTuples (id, x, y, energy, age, ...)
- `t`          — final tick
- `progress`   — Dict of logged per-tick statistics
- `deaths`     — Dict of per-death records
- `genome_log` — Vector of genome matrices (empty unless log_genomes=true)
"""
# Fallback: convert a NamedTuple / RConnector.ElementList / named-like input
# to Dict{String,Any} and dispatch. This lets R callers pass a native list
# without building the Dict explicitly on the Julia side.
run_clade(specs) = run_clade(r_specs_to_dict(specs))

function run_clade(specs::Dict{String,Any})
    env = create_environment(specs)
    max_t = Int(specs["max_ticks"])
    verbose = Bool(get(specs, "verbose", false))

    for t in 1:max_t
        env.t = Int32(t)
        _reset_counters!(env)

        # ── Core tick sequence ───────────────────────────────────────────
        grow_grass!(env)
        apply_fixed_patch!(env)           # fixed patch: replenish stable cell(s) after growth
        grow_resources!(env)              # complex landscape: shrub + canopy regrowth
        # Niche construction runs before tick_agents! so shelters built or
        # decayed this tick affect grass growth (already applied) and are
        # seen by predators / sensing during movement.
        apply_niche_construction!(env)
        # Seed predators on first tick if enabled
        t == 1 && seed_predators!(env)
        tick_agents!(env)
        tick_predators!(env)              # predator sense-decide-act loop
        apply_body_size!(env)             # metabolic + foraging correction
        apply_brain_size_evolution!(env)  # expensive brain + cognitive foraging
        apply_ann_regularization!(env)    # L1/L0 weight complexity penalty
        apply_dispersal!(env)             # natal dispersal away from birthplace
        apply_habitat_preference!(env)    # secondary move toward preferred habitat
        apply_seasonal_mortality!(env)    # winter death probability
        apply_toxicity_costs!(env)        # mimicry: per-tick toxicity energy cost
        apply_signal_costs!(env)          # signal evolution: per-tick signal cost
        apply_signal_evolution!(env)      # signal drift mutation (when enabled)
        apply_signal_toxicity_pleiotropy!(env)  # 0.4.4: aposematic coupling
        apply_coevolving_parasites!(env)  # 0.5.0: Hamilton 1980 Red Queen

        # ── Optional modules ─────────────────────────────────────────────
        # (each is a no-op when its flag is false)
        if t == 1 && Bool(get(specs, "disease", false))
            seed_disease!(env)
        end
        apply_disease!(env)
        apply_kin_altruism!(env)
        apply_iffolk!(env)                # IFfolk inclusive fitness + parliament suppression
        # Scavenging: agents consume carrion deposited on previous ticks,
        # then carrion decays exponentially.
        apply_scavenging!(env)
        decay_carrion!(env)
        apply_cooperation!(env)
        apply_epigenetics!(env)
        apply_care_costs!(env)            # parental care energy cost
        feed_offspring!(env)              # parental care: feed juveniles
        age_juveniles!(env)               # parental care: age + metabolic cost
        apply_cooperative_breeding!(env)  # alloparental helper transfers
        # Social learning: every social_learning_freq ticks
        if Bool(get(specs, "social_learning", false))
            sl_freq = Int(get(specs, "social_learning_freq", 10))
            sl_freq > 0 && t % sl_freq == 0 && apply_social_learning!(env)
        end
        # Within-lifetime RL: every rl_update_freq ticks
        if String(get(specs, "rl_mode", "none")) != "none"
            rl_freq = Int(get(specs, "rl_update_freq", 1))
            rl_freq > 0 && t % rl_freq == 0 && apply_rl!(env)
        end
        # Speciation clustering every N ticks
        assign_species!(env)

        # ── Death and reproduction ───────────────────────────────────────
        kill_dead!(env)
        remove_dead!(env)
        graduate_offspring!(env)          # parental care: promote juveniles
        create_offspring!(env)

        # ── Logging ──────────────────────────────────────────────────────
        log_freq = Int(get(specs, "log_freq", 1))
        if t % log_freq == 0
            log_tick!(env)
        end

        if verbose && t % 100 == 0
            @info "tick $t: $(length(env.agents)) agents alive"
        end
    end

    _env_to_result(env)
end

# ── Tick helpers ──────────────────────────────────────────────────────────────

"""
    grow_grass!(env::Environment)

Grow grass according to logistic regrowth: each empty cell has probability
`grass_rate` of gaining one unit per tick, up to `grass_max`.
"""
function grow_grass!(env::Environment)
    rate = Float32(env.specs["grass_rate"])
    gmax = Float32(get(env.specs, "grass_max", 5.0))
    # Seasonal modulation
    amp  = Float32(get(env.specs, "seasonal_amplitude", 0.0))
    if amp > 0.0f0
        period = Float64(get(env.specs, "season_length", 100))
        rate *= Float32(1.0 + amp * sin(2π * Float64(env.t) / period))
        rate  = clamp(rate, 0.0f0, 1.0f0)
    end

    niche_on = Bool(get(env.specs, "niche_construction", false))

    if niche_on
        rows = size(env.grass, 1)
        cols = size(env.grass, 2)
        @inbounds for y in 1:cols, x in 1:rows
            env.grass[x, y] < gmax || continue
            mult = niche_grass_rate_multiplier(env.shelter_map, x, y)
            if rand(env.rng) < rate * mult
                env.grass[x, y] = min(env.grass[x, y] + 1.0f0, gmax)
            end
        end
    else
        @inbounds for i in eachindex(env.grass)
            if env.grass[i] < gmax && rand(env.rng) < rate
                env.grass[i] = min(env.grass[i] + 1.0f0, gmax)
            end
        end
    end
end

"""
    _reset_counters!(env::Environment)

Reset all per-tick module counters to zero at the start of each tick.
"""
function _reset_counters!(env::Environment)
    env.n_births          = Int32(0)
    env.n_deaths          = Int32(0)
    env.n_starvations     = Int32(0)
    env.n_age_deaths      = Int32(0)
    env.n_new_infections  = Int32(0)
    env.n_recoveries      = Int32(0)
    env.n_altruistic_acts = Int32(0)
    env.n_cooperation_acts= Int32(0)
    env.n_shelters_built  = Int32(0)
    env.n_graduations     = Int32(0)
    env.n_juv_deaths      = Int32(0)
    env.n_toxic_attacks   = Int32(0)
    env.n_avoided_attacks = Int32(0)
    env.n_dispersal_events  = Int32(0)
    env.n_habitat_moves     = Int32(0)
    env.n_helpers           = Int32(0)
    env.n_front_agents      = Int32(0)
    env.n_iffolk_transfers  = Int32(0)
    env.n_scavenge_events   = Int32(0)
    env.n_gd_events         = Int32(0)
    env.n_repro_events      = Int32(0)
    env.n_clutch_total      = Int32(0)
end

# ── Internal constructors ─────────────────────────────────────────────────────

"""
    _build_arch(specs) -> Vector{Int32}

Compute the brain architecture vector from specs.

For ANN and BNN: arch = [n_inputs, hidden..., n_outputs]
where n_inputs depends on active sensory modules and n_outputs = 5 (actions).
"""
function _build_arch(specs::Dict{String,Any})::Vector{Int32}
    bt = get(specs, "brain_type", "bnn")
    if bt in ("ann", "bnn", "random")
        n_in  = _compute_n_inputs(specs)
        n_out = Int32(5)   # N, E, S, W, idle
        hidden = Int32.(specs["hidden_layers"])
        return Int32[n_in; hidden; n_out]
    elseif bt == "ctrnn"
        # arch = [n_inputs, n_neurons, n_outputs]. n_neurons is taken from
        # the first element of hidden_layers (CTRNN uses a single pool).
        n_in      = _compute_n_inputs(specs)
        hidden    = Int32.(specs["hidden_layers"])
        n_neurons = isempty(hidden) ? Int32(8) : hidden[1]
        n_out     = Int32(5)
        # Ensure n_neurons is large enough to accommodate the input and
        # output slots without overlap.
        n_neurons = max(n_neurons, n_in + n_out)
        return Int32[n_in, n_neurons, n_out]
    elseif bt == "grn"
        # arch = [n_inputs, n_genes, n_outputs].
        n_in      = _compute_n_inputs(specs)
        n_genes_v = Int32(get(specs, "n_genes", 20))
        n_out     = min(Int32(5), n_genes_v)
        # Ensure n_genes is at least n_in + n_out so that the sensory and
        # action genes don't overlap.
        n_genes_v = max(n_genes_v, n_in + n_out)
        return Int32[n_in, n_genes_v, n_out]
    elseif bt == "transformer"
        n_in = _compute_n_inputs(specs)
        return Int32[n_in,
                     specs["transformer_heads"],
                     specs["transformer_history"],
                     Int32(5)]
    else
        # Synthesis: return placeholder; replaced in a later phase.
        n_in = _compute_n_inputs(specs)
        hidden = Int32.(specs["hidden_layers"])
        return Int32[n_in; hidden; Int32(5)]
    end
end

"""
    _compute_n_inputs(specs) -> Int32

Sensory input vector length depends on `input_radius` (r) and active modules:
- Base: 3 + 8r inputs (r=1 → 11, r=2 → 19)
  - 2 self slots (energy, age) + 4r grass + 4r occupancy + 1 bias
- + predators:     +4r (predator N/E/S/W at distances 1..r)
- + parental care: +2  (care_load, offspring_energy)
- + signal_dims:   +signal_dims (own signal)

Must stay in sync with sense_agent() in sense.jl.
"""
function _compute_n_inputs(specs::Dict{String,Any})::Int32
    r = Int32(get(specs, "input_radius", 1))
    n = Int32(3) + Int32(8) * r          # base: 2 self + 4r grass + 4r occ + 1 bias
    Int(get(specs, "n_predators_init", 0)) > 0 && (n += Int32(4) * r)
    Bool(get(specs, "parental_care",   false)) && (n += Int32(2))
    sig = Int(get(specs, "signal_dims", 0))
    n += Int32(sig)
    n
end

"""
    _init_parasite_haplotype(specs, rng) -> Vector{Int32}

0.5.1: initialise a random binary haplotype for the discrete-locus
Red Queen module. Returns an empty vector when `n_parasite_loci == 0`
(default), so all legacy scenarios are unaffected.
"""
function _init_parasite_haplotype(specs::Dict{String,Any}, rng)::Vector{Int32}
    n_loci = Int(get(specs, "n_parasite_loci", 0))
    n_loci == 0 && return Int32[]
    Int32[rand(rng, 0:1) for _ in 1:n_loci]
end

"""
    _make_founder_agent(id, g, brain, specs, rng) -> Agent

Construct a founder agent (no parents). Position is assigned uniformly at
random on the grid. All non-core fields take biologically neutral defaults.
"""
function _make_founder_agent(id::Int64, g::DiploidGenome, brain::AbstractBrain,
                              specs::Dict{String,Any}, rng)::Agent
    rows = Int(specs["grid_rows"])
    cols = Int(specs["grid_cols"])

    dm = get(specs, "dominance_model", "additive")

    body_size = express_trait(g, TRAIT_BODY_SIZE, dm,
                              Float32(get(specs, "body_size_min",  0.1)),
                              Float32(get(specs, "body_size_max",  5.0)), rng)
    immune_str = express_trait(g, TRAIT_IMMUNE_STRENGTH, dm,
                               Float32(get(specs, "immune_strength_min", 0.0)),
                               Float32(get(specs, "immune_strength_max", 1.0)), rng)
    coop = express_trait(g, TRAIT_COOPERATION_LEVEL, dm, 0.0f0, 1.0f0, rng)
    disp = express_trait(g, TRAIT_DISPERSAL_TENDENCY, dm,
                         Float32(get(specs, "dispersal_min", 0.0)),
                         Float32(get(specs, "dispersal_max", 1.0)), rng)
    metab = express_trait(g, TRAIT_METABOLIC_RATE, dm,
                          Float32(get(specs, "metabolic_rate_min", 0.1)),
                          Float32(get(specs, "metabolic_rate_max", 5.0)), rng)
    aging = express_trait(g, TRAIT_AGING_RATE, dm,
                          Float32(get(specs, "aging_rate_min", 0.01)),
                          Float32(get(specs, "aging_rate_max", 10.0)), rng)
    repro_th = express_trait(g, TRAIT_REPRO_THRESHOLD, dm, 0.0f0, 1000.0f0, rng)
    mut_sd   = express_trait(g, TRAIT_MUTATION_SD, dm,
                             Float32(get(specs, "mutation_sd_min",  0.001)),
                             Float32(get(specs, "mutation_sd_max",  1.0)), rng)
    lr       = express_trait(g, TRAIT_LEARNING_RATE, dm,
                             Float32(get(specs, "learning_rate_min", 0.0)),
                             Float32(get(specs, "learning_rate_max", 0.5)), rng)
    hp       = express_trait(g, TRAIT_HABITAT_PREFERENCE, dm,
                             Float32(get(specs, "habitat_preference_min", -1.0)),
                             Float32(get(specs, "habitat_preference_max",  1.0)), rng)
    helper_t  = express_trait(g, TRAIT_HELPER_TENDENCY, dm, 0.0f0, 1.0f0, rng)
    plast     = express_trait(g, TRAIT_PLASTICITY, dm,
                              Float32(get(specs, "plasticity_min", 0.0)),
                              Float32(get(specs, "plasticity_max", 1.0)), rng)
    tox       = express_trait(g, TRAIT_TOXICITY, dm, 0.0f0, 1.0f0, rng)
    wing      = express_trait(g, TRAIT_WING_SIZE, dm,
                              Float32(get(specs, "wing_size_min", 0.0)),
                              Float32(get(specs, "wing_size_max", 1.0)), rng)
    bsz       = express_trait(g, TRAIT_BRAIN_SIZE, dm,
                              Float32(get(specs, "brain_size_min", 0.1)),
                              Float32(get(specs, "brain_size_max", 3.0)), rng)

    sig_dims = Int(get(specs, "signal_dims", 0))

    px = Int32(rand(rng, 1:rows))
    py = Int32(rand(rng, 1:cols))

    Agent(
        # Identity
        id, Int64(0), Int64(0),
        px, py,
        # Energy
        Float32(get(specs, "energy_init", 100.0)),
        Int32(0), Int32(0), true,
        # Brain and genome
        brain, g, Bool[],   # methylome initialised empty; filled by epigenetics module
        # Scalar traits
        body_size, immune_str, coop, disp, metab, aging, repro_th, mut_sd, lr,
        # Signal
        zeros(Float32, sig_dims), zeros(Float32, sig_dims),
        # Mimicry / toxicity (heritable) + predator signal memory (0.4.4)
        tox,
        Float32[],   # signal_memory: empty for founders, populated by predators on attacks
        _init_parasite_haplotype(specs, rng),  # 0.5.1: discrete haplotype for Red Queen

        # Disease
        false, false, Int32(0), Int32(0),
        # Parental care
        Any[], Int32(0),
        # RL
        0.0f0, Float32(get(specs, "energy_init", 100.0)),
        # Reproductive tracking
        false, Int32(0), Int32(0), Int32(0),
        # Speciation
        Int32(0),
        # Natal dispersal (birth location = spawn location for founders)
        px, py,
        # Habitat preference, cooperative breeding, plasticity
        hp, helper_t, plast,
        # Complex landscape traits
        wing, Int32(1),   # wing_size, niche_layer (1=ground)
        # Brain size evolution
        bsz
    )
end

"""
    _dict_to_nt(d::Dict{String, Vector}) -> NamedTuple

Convert a `Dict{String, Vector}` to a Julia NamedTuple with sorted keys.
JuliaConnectoR converts NamedTuples to R named lists reliably (preserving
all fields), whereas Dict conversion drops keys inconsistently for larger
dicts. This is the fix for `mean_brain_size` / `mean_habitat_preference`
being silently dropped when `progress` was returned as a Dict.
"""
function _dict_to_nt(d::Dict{String,Vector})::NamedTuple
    ks  = sort(collect(keys(d)))
    syms = Tuple(Symbol(k) for k in ks)
    vals = Tuple(d[k] for k in ks)
    NamedTuple{syms}(vals)
end

"""
    _env_to_result(env::Environment) -> NamedTuple

Convert the environment to a NamedTuple suitable for return to R via
JuliaConnectoR. R will receive this as a named list.

`progress` and `deaths` are converted from Dict to NamedTuple so that
JuliaConnectoR serialises all fields without loss.
"""
function _env_to_result(env::Environment)
    (
        agents        = _agents_to_records(env.agents),
        t             = Int(env.t),
        progress      = _dict_to_nt(env.progress),
        deaths        = _dict_to_nt(env.deaths),
        genome_log    = env.genome_log,
        total_carrion = Float64(sum(env.carrion_map)),
        total_shelter = Int(sum(env.shelter_map)),
    )
end

"""
    _agents_to_records(agents) -> Vector{NamedTuple}

Convert agent structs to a vector of NamedTuples for R consumption.
"""
function _agents_to_records(agents::Vector{Agent})
    map(agents) do ag
        (
            id             = Int(ag.id),
            parent_id      = Int(ag.parent_id),
            x              = Int(ag.x),
            y              = Int(ag.y),
            energy         = Float64(ag.energy),
            age            = Int(ag.age),
            alive          = ag.alive,
            body_size      = Float64(ag.body_size),
            immune_strength= Float64(ag.immune_strength),
            cooperation_level = Float64(ag.cooperation_level),
            metabolic_rate = Float64(ag.metabolic_rate),
            aging_rate     = Float64(ag.aging_rate),
            repro_threshold= Float64(ag.repro_threshold),
            mutation_sd    = Float64(ag.mutation_sd),
            learning_rate  = Float64(ag.learning_rate),
            toxicity       = Float64(ag.toxicity),
            habitat_preference = Float64(ag.habitat_preference),
            plasticity     = Float64(ag.plasticity),
            signal         = Float64.(ag.signal),
            preference     = Float64.(ag.preference),
            num_offspring  = Int(ag.num_offspring),
            species_id     = Int(ag.species_id),
            wing_size      = Float64(ag.wing_size),
            niche_layer    = Int(ag.niche_layer),
            dispersal_tendency = Float64(ag.dispersal_tendency),
            helper_tendency    = Float64(ag.helper_tendency),
            brain_size         = Float64(ag.brain_size),
            infected       = ag.infected,
            immune         = ag.immune,
            care_load      = Int(ag.care_load)
        )
    end
end

end # module Clade
