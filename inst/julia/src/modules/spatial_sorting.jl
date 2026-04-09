"""
    spatial_sorting.jl -- Assortative mating at the invasion range front.

Enabled when `specs["spatial_sorting"] == true`.

Modifies mate selection in reproduce.jl: agents at the range front
(far from the population centroid) preferentially mate with high-dispersal
partners, causing dispersal-enhancing alleles to accumulate at the frontier
without requiring any fitness advantage over sedentary conspecifics.

Mechanism (Shine et al. 2011)
------------------------------
At the expanding range front, the first arrivals are the fastest dispersers.
When they reproduce, their mates are drawn disproportionately from nearby
high-dispersal individuals (because sedentary individuals lag behind). This
assortment progressively co-locates dispersal alleles on the same chromosome,
producing rapid spatial evolution of dispersal tendency.

Implementation note
-------------------
This module exports two helpers used by `_find_mate()` in reproduce.jl:
- `compute_range_centroid(env)` -- population centroid in grid space
- `spatial_sort_score(ag, candidate, cx, cy, max_dist, specs)` -- scoring bias

The centroid is cached in a module-level Ref and refreshed once per
`create_offspring!` call (not per agent), keeping cost O(n_agents) per tick
rather than O(n_agents^2).
"""

# Module-level cache for centroid computation (refreshed at start of each
# create_offspring! call via `refresh_sorting_centroid!`).
const _sort_cx    = Ref{Float32}(0.0f0)
const _sort_cy    = Ref{Float32}(0.0f0)
const _sort_dmax  = Ref{Float32}(1.0f0)

"""
    refresh_sorting_centroid!(env::Environment)

Recompute the population centroid and maximum dispersal distance.
Called once at the start of `create_offspring!` when `spatial_sorting == true`.
No-op when disabled.
"""
function refresh_sorting_centroid!(env::Environment)
    Bool(get(env.specs, "spatial_sorting", false)) || return
    ags = env.agents
    n   = count(ag -> ag.alive, ags)
    n == 0 && return

    cx = Float32(sum(ag.x for ag in ags if ag.alive)) / Float32(n)
    cy = Float32(sum(ag.y for ag in ags if ag.alive)) / Float32(n)
    dmax = maximum(sqrt((Float32(ag.x) - cx)^2 + (Float32(ag.y) - cy)^2)
                   for ag in ags if ag.alive)
    _sort_cx[]   = cx
    _sort_cy[]   = cy
    _sort_dmax[] = max(dmax, 1.0f0)   # avoid division by zero

    # Log front-agent count
    front_thr = Float32(get(env.specs, "sorting_front_threshold", 0.75))
    env.n_front_agents = Int32(count(
        ag -> ag.alive &&
              sqrt((Float32(ag.x) - cx)^2 + (Float32(ag.y) - cy)^2) / _sort_dmax[] >= front_thr,
        ags))
end

"""
    spatial_sort_score(ag, candidate, specs) -> Float32

Return a mate-selection score for `candidate` from `ag`'s perspective.

When `spatial_sorting == true` and `ag` is at the range front (distance from
centroid >= `sorting_front_threshold * max_dist`), the score is the candidate's
`dispersal_tendency` boosted by `sorting_mating_boost`. Otherwise the score is
the raw `dispersal_tendency` (no modification).

When `spatial_sorting == false` this function returns 0.0f0 and is never
consulted by `_find_mate`.
"""
function spatial_sort_score(ag::Agent, candidate::Agent, specs::Dict{String,Any})::Float32
    cx   = _sort_cx[]
    cy   = _sort_cy[]
    dmax = _sort_dmax[]

    front_thr = Float32(get(specs, "sorting_front_threshold", 0.75))
    boost     = Float32(get(specs, "sorting_mating_boost",    3.0))

    d_ag = sqrt((Float32(ag.x) - cx)^2 + (Float32(ag.y) - cy)^2)
    at_front = (d_ag / dmax) >= front_thr

    return at_front ? candidate.dispersal_tendency * boost : candidate.dispersal_tendency
end
