# fixed_patch.jl — Stable high-value resource patch
#
# Replicates the core landscape condition of Hinton & Nowlan (1987): a single
# globally-optimal target that never moves. One or more grid cells are reset to
# a fixed high grass value after every call to grow_grass!, giving selection a
# stable fitness peak that canalization can track.
#
# Without a stable peak the fitness landscape shifts continuously (stochastic
# grass, population density feedbacks) and exploration remains the ESS —
# sigma rises to ceiling. With a stable patch, a fixed "navigate to patch"
# policy is always optimal; sigma should decline over generations as that
# policy is genetically assimilated.
#
# Reference: Hinton, G.E. & Nowlan, S.J. (1987) How learning can guide
# evolution. Complex Systems 1(3):495-502.

"""
    _fixed_patch_cells(specs, rows, cols) -> Vector{CartesianIndex{2}}

Resolve the grid cells covered by the fixed patch from specs. Called once
during `create_environment()`; result is cached in
`env.specs["_fixed_patch_cells"]` so the tick loop has zero-allocation access.

Centre defaults to grid centre when `fixed_patch_x` / `fixed_patch_y` are
absent or `nothing`. Radius follows the Chebyshev (Moore) convention:
radius 0 = 1 cell, radius 1 = 3×3, radius 2 = 5×5, etc.
"""
function _fixed_patch_cells(specs::Dict{String,Any}, rows::Int, cols::Int)
    cx = let v = get(specs, "fixed_patch_x", nothing)
        (v === nothing || ismissing(v)) ? div(cols, 2) + 1 : Int(v)
    end
    cy = let v = get(specs, "fixed_patch_y", nothing)
        (v === nothing || ismissing(v)) ? div(rows, 2) + 1 : Int(v)
    end
    r = Int(get(specs, "fixed_patch_radius", 0))

    idxs = CartesianIndex{2}[]
    for dx in -r:r, dy in -r:r
        nx = mod1(cy + dy, rows)
        ny = mod1(cx + dx, cols)
        push!(idxs, CartesianIndex(nx, ny))
    end
    unique!(idxs)
end

"""
    apply_fixed_patch!(env)

Reset fixed patch cells to `specs["fixed_patch_value"]` immediately after
`grow_grass!`. No-op when `fixed_patch == false`.

Because the replenishment happens before `tick_agents!`, agents always see
the full patch value when they decide where to move and eat — the patch
provides a consistent signal across all ticks.
"""
function apply_fixed_patch!(env::Environment)
    Bool(get(env.specs, "fixed_patch", false)) || return
    val  = Float32(get(env.specs, "fixed_patch_value", 5.0))
    idxs = env.specs["_fixed_patch_cells"]::Vector{CartesianIndex{2}}
    @inbounds for ci in idxs
        env.grass[ci] = val
    end
    nothing
end
