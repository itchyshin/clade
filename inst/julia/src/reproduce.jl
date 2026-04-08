"""
    reproduce.jl — Offspring creation via meiosis and brain construction.

Called once per tick after `kill_dead!()`. Eligible agents produce offspring
according to the reproduction rules in specs.

## Reproduction rules

1. Agent must have `energy >= repro_threshold`.
2. Agent must not have already reproduced this tick (`reproduced == false`).
3. If `allee_threshold > 0`: at least this many neighbours required.
4. If `signal_dims > 0` (mate choice): find a compatible mate by signal-
   preference matching.
5. Deduct `repro_cost` from parent (and mate if present).
6. Create offspring genome via meiosis (genome.jl).
7. Express phenotype → construct brain.
8. Place offspring at random unoccupied adjacent cell (or parent's cell if
   grid is full).

## Parental care

When `parental_care = TRUE`: offspring are added to `parent.carried_offspring`
rather than `env.agents`. They join `env.agents` after `care_duration` ticks
via `graduate_offspring!()` (in modules/parental_care.jl; Phase 2 stub here).
"""

"""
    create_offspring!(env::Environment)

Scan all live agents and create offspring for eligible reproducers.
"""
function create_offspring!(env::Environment)
    specs     = env.specs
    repro_th  = Float32(get(specs, "min_repro_energy", 120.0))
    repro_cost= Float32(get(specs, "repro_cost",       30.0))
    off_energy= Float32(get(specs, "offspring_energy", 60.0))
    max_ag    = Int(get(specs, "max_agents",           500))
    care      = Bool(get(specs, "parental_care",       false))
    allee_th  = Int(get(specs, "allee_threshold",      0))
    clutch    = Int(get(specs, "max_clutch_size",      1))

    # Collect reproducers before iterating (avoid modifying during loop)
    new_agents = Agent[]

    for ag in env.agents
        ag.alive             || continue
        ag.reproduced        && continue
        ag.energy < repro_th && continue
        length(env.agents) + length(new_agents) >= max_ag && break

        # Allee effect: count neighbours
        if allee_th > 0
            n_nbrs = _count_neighbours(ag, env)
            n_nbrs < allee_th && continue
        end

        for _ in 1:clutch
            length(env.agents) + length(new_agents) >= max_ag && break

            # Find mate (or reproduce asexually)
            mate = _find_mate(ag, env)

            # Deduct cost
            ag.energy -= repro_cost
            mate !== nothing && (mate.energy -= repro_cost * 0.5f0)

            # Create offspring
            off_genome = make_offspring_genome(
                ag.genome,
                mate !== nothing ? mate.genome : nothing,
                specs, env.rng
            )
            off_brain = make_brain(off_genome, specs)
            off = _make_offspring(env.next_id, off_genome, off_brain,
                                   ag, mate, off_energy, specs, env.rng)
            env.next_id += Int64(1)

            ag.num_offspring += Int32(1)
            ag.reproduced     = true
            env.n_births     += Int32(1)

            if care
                # Phase 2: add to ag.carried_offspring
                push!(new_agents, off)   # placeholder: treat as direct birth
            else
                push!(new_agents, off)
            end
        end
    end

    # Add all new agents to env
    for off in new_agents
        push!(env.agents, off)
        env.agent_map[off.x, off.y] = length(env.agents)
    end
end

# ── Internal helpers ───────────────────────────────────────────────────────────

"""
    _find_mate(ag, env) -> Union{Agent, Nothing}

For haploid organisms or when `signal_dims == 0`: return `nothing` (asexual).
For diploid organisms with signal evolution: find the nearest compatible mate
within the Moore neighbourhood whose `signal` best matches `ag.preference`.
Returns `nothing` if no eligible mate found.
"""
function _find_mate(ag::Agent, env::Environment)::Union{Agent, Nothing}
    specs = env.specs
    if specs["ploidy"] == 1 || Int(get(specs, "signal_dims", 0)) == 0
        # Haploid: asexual reproduction
        return nothing
    end
    # Diploid: find Moore-neighbourhood agent (excluding self) with highest
    # signal-preference compatibility
    rows = Int(specs["grid_rows"])
    cols = Int(specs["grid_cols"])
    x, y = Int(ag.x), Int(ag.y)

    best_score = -Inf32
    best_mate  = nothing

    for dx in -1:1, dy in -1:1
        (dx == 0 && dy == 0) && continue
        nx = mod1(x + dx, rows)
        ny = mod1(y + dy, cols)
        idx = env.agent_map[nx, ny]
        idx == 0 && continue
        candidate = env.agents[idx]
        candidate.alive      || continue
        candidate.id == ag.id && continue
        # Score = negative Euclidean distance between ag.preference and
        # candidate.signal (Zahavi 1975 — preference for signal)
        score = -sum(abs2, ag.preference .- candidate.signal)
        if score > best_score
            best_score = score
            best_mate  = candidate
        end
    end
    best_mate
end

"""
    _count_neighbours(ag, env) -> Int

Count live agents in the Moore neighbourhood of `ag` (excluding self).
"""
function _count_neighbours(ag::Agent, env::Environment)::Int
    specs = env.specs
    rows  = Int(specs["grid_rows"])
    cols  = Int(specs["grid_cols"])
    x, y  = Int(ag.x), Int(ag.y)
    n = 0
    for dx in -1:1, dy in -1:1
        (dx == 0 && dy == 0) && continue
        nx = mod1(x + dx, rows)
        ny = mod1(y + dy, cols)
        env.agent_map[nx, ny] > 0 && (n += 1)
    end
    n
end

"""
    _make_offspring(id, genome, brain, parent, mate, energy, specs, rng) -> Agent

Construct one offspring agent. Position is chosen from the empty cells
adjacent to the parent, or the parent's cell if all neighbours are occupied.
"""
function _make_offspring(id::Int64, g::DiploidGenome, brain::AbstractBrain,
                          parent::Agent, mate::Union{Agent,Nothing},
                          energy::Float32, specs::Dict{String,Any},
                          rng)::Agent
    rows = Int(specs["grid_rows"])
    cols = Int(specs["grid_cols"])
    dm   = get(specs, "dominance_model", "additive")

    # Place at an empty adjacent cell if possible
    x, y = _place_offspring(parent, rows, cols, rng)

    mate_id = mate !== nothing ? mate.id : Int64(0)
    sig_dims = Int(get(specs, "signal_dims", 0))

    # Express scalar traits (pass rng for reproducibility under dominant model)
    body_size  = express_trait(g, TRAIT_BODY_SIZE, dm,
                               Float32(get(specs,"body_size_min",0.1)),
                               Float32(get(specs,"body_size_max",5.0)), rng)
    immune_str = express_trait(g, TRAIT_IMMUNE_STRENGTH, dm, 0.0f0, 1.0f0, rng)
    coop       = express_trait(g, TRAIT_COOPERATION_LEVEL, dm, 0.0f0, 1.0f0, rng)
    disp       = express_trait(g, TRAIT_DISPERSAL_TENDENCY, dm,
                               Float32(get(specs,"dispersal_min",0.0)),
                               Float32(get(specs,"dispersal_max",1.0)), rng)
    metab      = express_trait(g, TRAIT_METABOLIC_RATE, dm,
                               Float32(get(specs,"metabolic_rate_min",0.1)),
                               Float32(get(specs,"metabolic_rate_max",5.0)), rng)
    aging      = express_trait(g, TRAIT_AGING_RATE, dm,
                               Float32(get(specs,"aging_rate_min",0.01)),
                               Float32(get(specs,"aging_rate_max",10.0)), rng)
    repro_th   = express_trait(g, TRAIT_REPRO_THRESHOLD, dm, 0.0f0, 1000.0f0, rng)
    mut_sd     = express_trait(g, TRAIT_MUTATION_SD, dm,
                               Float32(get(specs,"mutation_sd_min",0.001)),
                               Float32(get(specs,"mutation_sd_max",1.0)), rng)
    lr         = express_trait(g, TRAIT_LEARNING_RATE, dm,
                               Float32(get(specs,"learning_rate_min",0.0)),
                               Float32(get(specs,"learning_rate_max",0.5)), rng)

    off = Agent(
        id, parent.id, mate_id,
        Int32(x), Int32(y),
        energy, Int32(0), Int32(0), true,
        brain, g, Bool[],
        body_size, immune_str, coop, disp, metab, aging, repro_th, mut_sd, lr,
        zeros(Float32, sig_dims), zeros(Float32, sig_dims),
        0.0f0,          # toxicity
        false, false, Int32(0), Int32(0),   # disease
        Any[], Int32(0),                    # parental care
        0.0f0, energy,                      # RL
        false, Int32(0), Int32(0), Int32(0), # reproductive tracking
        Int32(0)        # species_id
    )
    apply_epigenetic_inheritance!(off, parent, specs, rng)
    off
end

"""
    _place_offspring(parent, rows, cols, rng) -> Tuple{Int, Int}

Return (x, y) for the offspring. Chooses a random adjacent cell (toroidal
wrap). The caller passes `env.rng` so that seeded runs are reproducible.
"""
function _place_offspring(parent::Agent, rows::Int, cols::Int, rng)::Tuple{Int, Int}
    x, y = Int(parent.x), Int(parent.y)
    dx = rand(rng, -1:1)
    dy = rand(rng, -1:1)
    (mod1(x + dx, rows), mod1(y + dy, cols))
end
