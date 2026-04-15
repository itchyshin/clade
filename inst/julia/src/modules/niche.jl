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
    apply_shelter_occupancy_benefit!(env)
    decay_shelters!(env)
end

"""
    apply_shelter_occupancy_benefit!(env::Environment)

Heritable niche-construction effect (Odling-Smee, Laland & Feldman 2003):
agents occupying a sheltered cell receive an energy subsidy
`shelter_occupancy_bonus * depth` per tick, representing the metabolic
benefit of ancestral construction (wind-break, thermal buffer, predator
concealment). Default bonus is 0 — behavior matches the pre-0.2 local-
public-good semantics. Set `specs["shelter_occupancy_bonus"]` > 0 to
enable heritable niche dynamics where offspring reap what ancestors
built.

No-op when `niche_construction == false` or the bonus is zero.
"""
function apply_shelter_occupancy_benefit!(env::Environment)
    Bool(get(env.specs, "niche_construction", false)) || return
    bonus = Float32(get(env.specs, "shelter_occupancy_bonus", 0.0))
    bonus > 0.0f0 || return

    @inbounds for ag in env.agents
        ag.alive || continue
        d = env.shelter_map[Int(ag.x), Int(ag.y)]
        d > 0 && (ag.energy += bonus * Float32(d))
    end
    nothing
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

# === CLADE.JL ADDITIONS NEEDED ===
# include: include("modules/niche.jl")
# tick loop: apply_niche_construction!(env)   [BEFORE tick_agents!, so that
#                                              shelters built or decayed
#                                              this tick are visible to
#                                              predators and sensing code]
# grow_grass! modification: when niche_construction == true, iterate over
#   (x, y) explicitly and multiply the per-cell rate by
#   niche_grass_rate_multiplier(env.shelter_map, x, y). Minimal patch:
#
#     niche_on = Bool(get(env.specs, "niche_construction", false))
#     if niche_on
#         rows = size(env.grass, 1)
#         cols = size(env.grass, 2)
#         @inbounds for y in 1:cols, x in 1:rows
#             env.grass[x, y] < gmax || continue
#             mult = niche_grass_rate_multiplier(env.shelter_map, x, y)
#             if rand(env.rng) < rate * mult
#                 env.grass[x, y] = min(env.grass[x, y] + 1.0f0, gmax)
#             end
#         end
#     else
#         # (existing grow_grass! body)
#     end
#
# _env_to_result (optional, tests only): add
#     total_shelter = Int(sum(env.shelter_map))
# so R tests can assert shelter accumulation without reading the full
# shelter_map matrix. R/run.R's .julia_env_to_r must forward
# env_julia$total_shelter.
#
# env.shelter_map is already initialised in create_environment() as
#   zeros(Int32, rows, cols) — no struct change required.
#
# niche_attack_multiplier() is a stub: when the Phase 2 predators module is
# wired in, its attack roll should be multiplied by this helper.
# === END CLADE.JL ADDITIONS ===
