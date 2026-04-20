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
via `graduate_offspring!()` (in modules/parental_care.jl).
"""

"""
    create_offspring!(env::Environment)

Scan all live agents and create offspring for eligible reproducers.
"""
function create_offspring!(env::Environment)
    specs     = env.specs
    # Spatial sorting: refresh centroid cache once before mate-finding loop
    refresh_sorting_centroid!(env)
    # 0.4.0: parental cost can be either fixed (legacy) or proportional to
    # parent energy. Proportional cost is the biological default per
    # Smith & Fretwell (1974) and all life-history theory: parents in
    # better condition have more to invest. Fixed-cost mode preserved for
    # reproducibility of pre-0.4.0 runs.
    repro_cost_mode = String(get(specs, "repro_cost_mode", "proportional"))
    repro_cost      = Float32(get(specs, "repro_cost",          30.0))
    repro_cost_frac = Float32(get(specs, "repro_cost_fraction", 0.5))
    off_energy_base = Float32(get(specs, "offspring_energy",    60.0))
    off_energy_mode = String(get(specs, "offspring_energy_mode", "proportional"))
    off_energy_frac = Float32(get(specs, "offspring_energy_fraction", 0.25))
    max_ag    = Int(get(specs, "max_agents",           500))
    care      = Bool(get(specs, "parental_care",       false))
    allee_th      = Int(get(specs, "allee_threshold",  0))
    min_repro_age = Int32(get(specs, "min_repro_age",  0))

    # Lamarckian flag: precompute once (avoids dict lookup per agent)
    do_lamarck = Bool(get(specs, "lamarckian", false)) &&
                 get(specs, "rl_mode", "none") != "none"

    # Collect reproducers before iterating (avoid modifying during loop)
    new_agents = Agent[]

    for ag in env.agents
        ag.alive              || continue
        ag.reproduced         && continue
        ag.age < min_repro_age && continue
        # Per-agent threshold: evolved repro_threshold, plasticity-adjusted
        ag.energy < effective_repro_threshold(ag, env) && continue
        length(env.agents) + length(new_agents) >= max_ag && break

        # Allee effect: count neighbours
        if allee_th > 0
            n_nbrs = _count_neighbours(ag, env)
            n_nbrs < allee_th && continue
        end

        # Clutch size: per-agent sample when clutch_size_evolution is on
        clutch = if Bool(get(specs, "clutch_size_evolution", false))
            lo = Int(get(specs, "clutch_size_min", 1))
            hi = Int(get(specs, "clutch_size_max", 5))
            mu = Float64(get(specs, "clutch_size_init_mean", 1.0))
            sd = Float64(get(specs, "clutch_size_mutation_sd", 0.3))
            clamp(round(Int, mu + randn(env.rng) * sd), lo, hi)
        else
            Int(get(specs, "max_clutch_size", 1))
        end
        # B6: accumulate for mean_clutch_size logging
        env.n_repro_events += Int32(1)
        env.n_clutch_total += Int32(clutch)

        for _ in 1:clutch
            length(env.agents) + length(new_agents) >= max_ag && break

            # Find mate (or reproduce asexually)
            mate = _find_mate(ag, env)

            # 0.4.0: parental cost
            #   "fixed"        — deduct constant `repro_cost` (legacy)
            #   "proportional" — deduct `repro_cost_fraction * parent.energy`
            #                    (Smith & Fretwell 1974; default in 0.4.0)
            cost_paid = if repro_cost_mode == "proportional"
                repro_cost_frac * ag.energy
            else
                repro_cost
            end
            # 0.4.0 Tier 3: female_investment couples to outcomes.
            # When parental_investment_evolution = TRUE, the female (focal
            # agent) bears `female_investment` of the total cost and the
            # male bears `1 - female_investment`. Default 0.5 (symmetric)
            # preserves prior behaviour. The whole `cost_paid` flows into
            # offspring energy below — so higher female_investment
            # automatically gives offspring more of *its* mother's
            # contribution, exactly as Trivers (1972) predicts.
            pi_on  = Bool(get(specs, "parental_investment_evolution", false))
            fi     = Float32(get(specs, "female_investment", 0.5))
            if pi_on && mate !== nothing
                ag.energy   -= cost_paid * fi
                mate.energy -= cost_paid * (1.0f0 - fi)
            else
                ag.energy   -= cost_paid
                mate !== nothing && (mate.energy -= cost_paid * 0.5f0)
            end

            # 0.4.0: offspring birth energy
            #   "fixed"        — every newborn starts with `offspring_energy`
            #                    (legacy; ignores parent condition)
            #   "proportional" — newborn starts with `offspring_energy_fraction
            #                    * cost_paid` per Smith-Fretwell quality-quantity
            #                    (default in 0.4.0)
            off_energy_actual = if off_energy_mode == "proportional"
                off_energy_frac * cost_paid
            else
                off_energy_base
            end
            # 0.4.0 Tier 3: scale offspring birth energy by `2 * fi` when
            # parental_investment_evolution is on. fi = 0.5 → factor 1
            # (no change vs default); fi = 0.9 → factor 1.8 (larger
            # offspring); fi = 0.3 → factor 0.6 (smaller offspring).
            # Direct implementation of Trivers' (1972) prediction that
            # higher maternal investment yields better-provisioned young.
            if pi_on
                off_energy_actual = off_energy_actual * 2.0f0 * fi
            end

            # Legacy "male_repro_cost" extra male contribution: only fires
            # when pi_on AND explicit male_repro_cost > 0. Stacks on top
            # of the basic split.
            if pi_on && mate !== nothing
                male_extra = Float32(get(specs, "male_repro_cost", 0.0))
                male_extra > 0.0f0 && (mate.energy -= male_extra * off_energy_actual)
            end

            # Base mutation rate: when mutation_rate_evolution is on, use
            # the parent's per-agent evolved trait (ag.mutation_sd); else
            # use the global default from specs. Stress hypermutation
            # multiplies the base when parent energy is below threshold.
            global_mut_sd = Float32(get(specs, "mutation_sd", 0.1))
            evo_rate_on  = Bool(get(specs, "mutation_rate_evolution", false))
            base_mut_sd  = evo_rate_on ? ag.mutation_sd : global_mut_sd
            eff_mut_sd = if Bool(get(specs, "stress_hypermutation", false)) &&
                            ag.energy < Float32(get(specs, "stress_threshold", 20.0))
                base_mut_sd * Float32(get(specs, "stress_mutation_multiplier", 3.0))
            else
                base_mut_sd
            end
            specs["mutation_sd"] = eff_mut_sd

            # Lamarckian: write RL-learned phenotype back to genome before meiosis
            do_lamarck && lamarck_genome_update!(ag)

            # Create offspring
            off_genome = make_offspring_genome(
                ag.genome,
                mate !== nothing ? mate.genome : nothing,
                specs, env.rng
            )
            specs["mutation_sd"] = global_mut_sd   # restore after meiosis

            off_brain = make_brain(off_genome, specs)
            off = _make_offspring(env.next_id, off_genome, off_brain,
                                   ag, mate, off_energy_actual, specs, env.rng)
            env.next_id += Int64(1)

            ag.num_offspring += Int32(1)
            ag.reproduced     = true
            env.n_births     += Int32(1)

            if care
                # Parental care: offspring enter the brood instead of the
                # main agent pool. They do not occupy a grid cell, do not
                # forage, and pay no movement cost until they graduate via
                # `graduate_offspring!()` (see modules/parental_care.jl).
                # Carried juveniles keep their `alive = true` flag so
                # age/feeding logic treats them as live.
                push!(ag.carried_offspring, off)
                ag.care_load += Int32(1)
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

For haploid organisms (`ploidy == 1`): return `nothing` (asexual by genome).

For diploid organisms (`ploidy == 2`): search for a mate within a configurable
radius (default 1 = 3×3 Moore neighbourhood; `mate_search_radius = 2` gives
5×5, etc.). Returns `nothing` only if no eligible mate exists in the search
window — this is a real Allee-failure event, not the default outcome.

Mate selection (0.6.4 — `mate_choice_mode` and `mate_choice_strength` wired):
- `signal_dims == 0`: random choice among eligible candidates (sexual
  reproduction without mate choice).
- `signal_dims > 0` branches on `mate_choice_mode`:
    - `"random"`        — uniform random (ignores signals).
    - `"preference"`    — score by -||preference - candidate.signal||^2
                          (Zahavi / Fuller β_S).
    - `"highest_signal"` — score by Σ|candidate.signal_i| (magnitude).
  The per-candidate score is then sampled via softmax with temperature
  `1 / mate_choice_strength`:
    - `strength = 1.0`  — argmax (legacy behaviour, preserved).
    - `0 < strength < 1` — softmax sampling (noisier choice).
    - `strength = 0.0`  — uniform random (equivalent to `mode = "random"`).

Pre-0.6.4: `mate_choice_mode` and `mate_choice_strength` were documented
spec fields but silently ignored; `signal_dims > 0` always produced hard
argmax on preference-distance regardless of mode or strength. Fixed in
0.6.4 so the documented semantics actually run. Default
`mate_choice_mode = "preference"` and `mate_choice_strength = 1.0`
exactly reproduce pre-0.6.4 behaviour for all existing callers that set
`signal_dims > 0`; callers that explicitly set `"random"` or a strength
< 1 now get the behaviour they asked for (this may shift paper
reproductions that toggled these fields — flagged in NEWS 0.6.4).

Pre-0.5.10 behaviour (bug): when `signal_dims == 0`, this function returned
`nothing` immediately, which made every "diploid" run structurally produce
haploid offspring (`pat_w = Float32[]` in `make_offspring_genome`). The
entire ploidy=2 pathway was effectively a no-op unless signal evolution was
explicitly enabled.
"""
function _find_mate(ag::Agent, env::Environment)::Union{Agent, Nothing}
    specs = env.specs
    if specs["ploidy"] == 1
        return nothing     # haploid: asexual by genome structure
    end

    rows     = Int(specs["grid_rows"])
    cols     = Int(specs["grid_cols"])
    toroidal = Bool(get(specs, "toroidal", true))
    radius   = Int(get(specs, "mate_search_radius", 1))
    radius   = max(radius, 1)
    x, y = Int(ag.x), Int(ag.y)

    candidates = Agent[]
    for dx in -radius:radius, dy in -radius:radius
        (dx == 0 && dy == 0) && continue
        nx = wrap_or_clamp(x + dx, rows, toroidal)
        ny = wrap_or_clamp(y + dy, cols, toroidal)
        idx = env.agent_map[nx, ny]
        idx == 0 && continue
        candidate = env.agents[idx]
        candidate.alive       || continue
        candidate.id == ag.id && continue
        push!(candidates, candidate)
    end

    # Speciation filter: restrict to same species when speciation is active
    candidates = speciation_filter_mates(ag, candidates, specs)
    isempty(candidates) && return nothing

    # No signal dimensions → sexual reproduction without mate choice:
    # pick any eligible neighbour at random.
    if Int(get(specs, "signal_dims", 0)) == 0
        return candidates[rand(env.rng, 1:length(candidates))]
    end

    mode     = String(get(specs, "mate_choice_mode", "preference"))
    strength = Float32(get(specs, "mate_choice_strength", 1.0))

    # "random" mode or zero strength → uniform random.
    if mode == "random" || strength <= 0.0f0
        return candidates[rand(env.rng, 1:length(candidates))]
    end

    spatial_sort = Bool(get(specs, "spatial_sorting", false)) &&
                   Bool(get(specs, "dispersal_evolution", false))

    # Per-candidate score.
    scores = Vector{Float32}(undef, length(candidates))
    @inbounds for i in eachindex(candidates)
        c = candidates[i]
        s = if mode == "highest_signal"
            Float32(sum(abs, c.signal))
        else  # "preference" (default) or unrecognised → preference semantics
            -sum(abs2, ag.preference .- c.signal)
        end
        if spatial_sort
            s += Float32(spatial_sort_score(ag, c, specs))
        end
        scores[i] = s
    end

    # Greedy short-circuit at strength >= 1 — exact argmax preserves the
    # pre-0.6.4 observed behaviour for callers that kept default strength.
    if strength >= 1.0f0
        best_score = -Inf32
        best_mate  = candidates[1]
        @inbounds for i in eachindex(candidates)
            if scores[i] > best_score
                best_score = scores[i]
                best_mate  = candidates[i]
            end
        end
        return best_mate
    end

    # Softmax sampling with temperature 1/strength. Subtract max for
    # numerical stability (classic log-sum-exp trick).
    smax = maximum(scores)
    total = 0.0f0
    @inbounds for i in eachindex(scores)
        scores[i] = exp(strength * (scores[i] - smax))
        total    += scores[i]
    end
    r = rand(env.rng) * total
    cum = 0.0f0
    @inbounds for i in eachindex(candidates)
        cum += scores[i]
        if r <= cum
            return candidates[i]
        end
    end
    candidates[end]  # floating-point fallthrough
end

"""
    _count_neighbours(ag, env) -> Int

Count live agents in the Moore neighbourhood of `ag` (excluding self).
"""
function _count_neighbours(ag::Agent, env::Environment)::Int
    specs    = env.specs
    rows     = Int(specs["grid_rows"])
    cols     = Int(specs["grid_cols"])
    toroidal = Bool(get(specs, "toroidal", true))
    x, y  = Int(ag.x), Int(ag.y)
    n = 0
    for dx in -1:1, dy in -1:1
        (dx == 0 && dy == 0) && continue
        nx = wrap_or_clamp(x + dx, rows, toroidal)
        ny = wrap_or_clamp(y + dy, cols, toroidal)
        env.agent_map[nx, ny] > 0 && (n += 1)
    end
    n
end

"""
    _inherit_parasite_haplotype(parent, specs, rng; mate=nothing) -> Vector{Int32}

0.5.1: inherit a discrete-locus haplotype for the Red Queen module.

- When `n_parasite_loci == 0`: return empty vector (module off).
- Haploid (no mate): clone parent's haplotype, then flip each locus with
  probability `parasite_mutation_rate` (default 0.01).
- Diploid (mate provided): Mendelian segregation with free recombination —
  each locus inherits independently from parent or mate with 50/50
  probability, then mutation at rate `parasite_mutation_rate`.

The free-recombination / two-parent combination is what produces the
novel haplotypes Hamilton's Red Queen invokes.
"""
function _inherit_parasite_haplotype(parent::Agent, specs::Dict{String,Any},
                                       rng;
                                       mate::Union{Agent,Nothing} = nothing)::Vector{Int32}
    n_loci = Int(get(specs, "n_parasite_loci", 0))
    n_loci == 0 && return Int32[]

    # Defensive resizing if parent haplotype length doesn't match (scenario
    # change mid-run). Fall back to random initialisation.
    parent_hap = length(parent.parasite_haplotype) == n_loci ?
                 parent.parasite_haplotype :
                 Int32[rand(rng, 0:1) for _ in 1:n_loci]
    mate_hap = if mate !== nothing && length(mate.parasite_haplotype) == n_loci
        mate.parasite_haplotype
    else
        parent_hap
    end

    μ = Float32(get(specs, "parasite_mutation_rate", 0.01))
    offspring = Vector{Int32}(undef, n_loci)
    @inbounds for i in 1:n_loci
        # Mendelian recombination: each locus independently from parent or mate
        allele = rand(rng, Bool) ? parent_hap[i] : mate_hap[i]
        # Per-locus mutation (flip)
        if μ > 0.0f0 && rand(rng) < μ
            allele = Int32(1 - allele)
        end
        offspring[i] = allele
    end
    offspring
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
    rows     = Int(specs["grid_rows"])
    cols     = Int(specs["grid_cols"])
    dm       = get(specs, "dominance_model", "additive")
    toroidal = Bool(get(specs, "toroidal", true))

    # Place at an empty adjacent cell if possible
    x, y = _place_offspring(parent, rows, cols, rng; toroidal = toroidal)

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
    hp         = express_trait(g, TRAIT_HABITAT_PREFERENCE, dm,
                               Float32(get(specs,"habitat_preference_min",-1.0)),
                               Float32(get(specs,"habitat_preference_max", 1.0)), rng)
    helper_t   = express_trait(g, TRAIT_HELPER_TENDENCY, dm, 0.0f0, 1.0f0, rng)
    plasticity = express_trait(g, TRAIT_PLASTICITY, dm,
                               Float32(get(specs,"plasticity_min",0.0)),
                               Float32(get(specs,"plasticity_max",1.0)), rng)
    toxicity   = express_trait(g, TRAIT_TOXICITY, dm, 0.0f0, 1.0f0, rng)
    wing       = express_trait(g, TRAIT_WING_SIZE, dm,
                               Float32(get(specs,"wing_size_min",0.0)),
                               Float32(get(specs,"wing_size_max",1.0)), rng)
    bsz        = express_trait(g, TRAIT_BRAIN_SIZE, dm,
                               Float32(get(specs,"brain_size_min",0.1)),
                               Float32(get(specs,"brain_size_max",3.0)), rng)

    off = Agent(
        id, parent.id, mate_id,
        Int32(x), Int32(y),
        energy, Int32(0), Int32(0), true,
        brain, g, Bool[],
        body_size, immune_str, coop, disp, metab, aging, repro_th, mut_sd, lr,
        zeros(Float32, sig_dims), zeros(Float32, sig_dims),
        toxicity,       # toxicity (heritable via TRAIT_TOXICITY)
        Float32[],      # signal_memory (0.4.4): empty for prey offspring
        _inherit_parasite_haplotype(parent, specs, rng; mate = mate),  # 0.5.1
        false, false, Int32(0), Int32(0),   # disease
        Any[], Int32(0),                    # parental care
        0.0f0, energy,                      # RL
        false, Int32(0), Int32(0), Int32(0), # reproductive tracking
        Int32(0),       # species_id
        Int32(x), Int32(y),  # x_birth, y_birth = spawn location
        hp,              # habitat_preference
        helper_t,        # helper_tendency
        plasticity,      # plasticity
        wing, Int32(1),  # wing_size, niche_layer (1=ground)
        bsz              # brain_size
    )
    apply_epigenetic_inheritance!(off, parent, specs, rng)
    off
end

"""
    _place_offspring(parent, rows, cols, rng) -> Tuple{Int, Int}

Return (x, y) for the offspring. Chooses a random adjacent cell (toroidal
wrap). The caller passes `env.rng` so that seeded runs are reproducible.
"""
function _place_offspring(parent::Agent, rows::Int, cols::Int, rng;
                           toroidal::Bool = true)::Tuple{Int, Int}
    x, y = Int(parent.x), Int(parent.y)
    dx = rand(rng, -1:1)
    dy = rand(rng, -1:1)
    (wrap_or_clamp(x + dx, rows, toroidal), wrap_or_clamp(y + dy, cols, toroidal))
end
