"""
    niche.jl — Shelter building (niche construction).

Enabled when `specs["niche_construction"] == true`. Agents with sufficient
energy can pay nothing to stamp a shelter unit onto their current cell.
Shelters accumulate across ticks up to `shelter_max_depth` and decay
stochastically. They reduce the growth rate of grass on the sheltered cell
(representing physical disturbance of the substrate) and reduce predator
attack success (stub: integration point for Phase 2 predators).

## Three effects

1. **Grass growth suppression.** Sheltered cells grow grass more slowly:
   `effective_rate = grass_rate * max(1 - 0.1*depth, 0.1)`. Deep shelters
   still permit some regrowth so the grid is not permanently sterilised.
   Implemented via `niche_grass_rate_multiplier(shelter_map, x, y)`,
   called from `grow_grass!` in Clade.jl.

2. **Predator protection.** Agents on sheltered cells take less damage
   from predators: `attack_success_multiplier = max(1 - 0.2*depth, 0.2)`.
   Implemented via `niche_attack_multiplier(shelter_map, x, y)`. A stub
   is provided here for Phase 2 predators to call.

3. **Niche persistence.** Shelters decay binomially each tick — each
   unit is lost with probability `shelter_decay_prob`.

## Per-tick counter

`env.n_shelters_built` is incremented by one for each shelter unit added
(not per agent).

References
----------
Odling-Smee, F.J., Laland, K.N. & Feldman, M.W. (2003) Niche Construction:
    The Neglected Process in Evolution. Monographs in Population Biology 37.
    Princeton University Press.
Laland, K.N., Matthews, B. & Feldman, M.W. (2016) An introduction to niche
    construction theory. Evolutionary Ecology 30:191–202.
Jones, C.G., Lawton, J.H. & Shachak, M. (1994) Organisms as ecosystem
    engineers. Oikos 69(3):373–386.
"""

"""
    apply_shelter_building!(env::Environment)

Each live agent with energy greater than `specs["shelter_min_energy"]`
attempts to build one shelter unit at its current cell with probability
`specs["shelter_build_prob"]`. The per-cell depth is capped at
`specs["shelter_max_depth"]`. Building is free (no energy cost) — the
fitness trade-off comes from the grass-growth penalty on sheltered cells.
"""
function apply_shelter_building!(env::Environment)
    Bool(get(env.specs, "niche_construction", false)) || return

    min_e   = Float32(get(env.specs, "shelter_min_energy", 80.0))
    p_build = Float32(get(env.specs, "shelter_build_prob",  0.1))
    max_d   = Int32(  get(env.specs, "shelter_max_depth",   5))

    (p_build > 0.0f0 && max_d > 0) || return

    @inbounds for ag in env.agents
        ag.alive || continue
        ag.energy > min_e || continue
        rand(env.rng) < p_build || continue

        x, y = Int(ag.x), Int(ag.y)
        if env.shelter_map[x, y] < max_d
            env.shelter_map[x, y] += Int32(1)
            env.n_shelters_built  += Int32(1)
        end
    end
    nothing
end

"""
    decay_shelters!(env::Environment)

Binomial thinning of the shelter map: each shelter unit is independently
removed with probability `specs["shelter_decay_prob"]` each tick.

For efficiency we use a loop over units rather than a proper Binomial draw
because `shelter_max_depth` is typically small (5). For `shelter_max_depth`
~5 this is roughly as fast as sampling a Binomial and avoids a Distributions
dependency.
"""
function decay_shelters!(env::Environment)
    Bool(get(env.specs, "niche_construction", false)) || return

    p_decay = Float32(get(env.specs, "shelter_decay_prob", 0.05))
    p_decay > 0.0f0 || return

    rng = env.rng
    @inbounds for i in eachindex(env.shelter_map)
        depth = env.shelter_map[i]
        depth == 0 && continue
        lost = Int32(0)
        for _ in 1:Int(depth)
            rand(rng) < p_decay && (lost += Int32(1))
        end
        env.shelter_map[i] = depth - lost
    end
    nothing
end

"""
    apply_niche_construction!(env::Environment)

Umbrella helper: build new shelters, then decay existing ones. Called once
per tick before `tick_agents!`. Both sub-steps are no-ops when
`niche_construction == false`.
"""
function apply_niche_construction!(env::Environment)
    apply_shelter_building!(env)
    decay_shelters!(env)
end

"""
    niche_grass_rate_multiplier(shelter_map, x, y) -> Float32

Return the multiplier applied to `grass_rate` at cell `(x, y)` given the
current shelter depth. Depth 0 returns 1 (no effect). Each depth unit
reduces rate by 0.1, down to a floor of 0.1 at depth ≥ 9. Used by
`grow_grass!` in Clade.jl.
"""
@inline function niche_grass_rate_multiplier(shelter_map::Matrix{Int32},
                                              x::Int, y::Int)::Float32
    @inbounds d = shelter_map[x, y]
    d == 0 && return 1.0f0
    max(1.0f0 - 0.1f0 * Float32(d), 0.1f0)
end

"""
    niche_attack_multiplier(shelter_map, x, y) -> Float32

Return the multiplier applied to predator attack success probability
given shelter depth. Depth 0 returns 1 (no protection). Each depth unit
reduces success by 0.2, down to a floor of 0.2 at depth ≥ 4.

This is a *stub* for Phase 2 predators. No code currently calls it; it is
exported so that the predator tick will wrap its attack roll in this
multiplier once the predator module is activated.
"""
@inline function niche_attack_multiplier(shelter_map::Matrix{Int32},
                                          x::Int, y::Int)::Float32
    @inbounds d = shelter_map[x, y]
    d == 0 && return 1.0f0
    max(1.0f0 - 0.2f0 * Float32(d), 0.2f0)
end
