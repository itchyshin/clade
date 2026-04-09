"""
    complex_landscape.jl -- Multi-layer resource environment (shrubs + canopy).

Enabled when `specs["complex_landscape"] == true`.

Agents access three resource tiers based on morphology:
- Layer 1 (ground): standard grass, always accessible.
- Layer 2 (shrubs): moderate energy, moderate regrowth; accessible to all
  agents but preferentially exploited.
- Layer 3 (canopy): high energy density, slow regrowth; requires
  `wing_size >= canopy_threshold` (heritable via TRAIT_WING_SIZE).

`grow_resources!` is called once per tick alongside `grow_grass!`.
`eat_layered!` is called per-agent inside `tick_agents!` after standard grass
eating. When `complex_landscape == false`, `eat_layered!` returns immediately.

Biological motivation
---------------------
Real ecosystems layer resources vertically. Morphological access to upper tiers
(flight, arboreal locomotion) relaxes the standard brain-size x longevity
correlation: arboreal specialists may afford shorter lifespans because canopy
provides high-energy bursts that shorten the energy-accumulation time needed
for reproduction.

Reference: Liedtke & Fromhage (2019) on cephalopod learning paradox; Isbell
(2006) on frugivory, habitat complexity, and primate brain size.
"""

"""
    grow_resources!(env::Environment)

Stochastic logistic regrowth for shrub and canopy layers. Each cell's resource
level increases by a uniform draw scaled by the layer growth rate, capped at
the layer energy maximum.

No-op when `complex_landscape == false` (shrub_map and canopy_map are all-zero
and never written).
"""
function grow_resources!(env::Environment)
    Bool(get(env.specs, "complex_landscape", false)) || return

    shrub_rate  = Float32(get(env.specs, "shrub_growth_rate",  0.03))
    canopy_rate = Float32(get(env.specs, "canopy_growth_rate", 0.005))
    shrub_max   = Float32(get(env.specs, "shrub_energy",  20.0))
    canopy_max  = Float32(get(env.specs, "canopy_energy", 50.0))

    @inbounds for i in eachindex(env.shrub_map)
        env.shrub_map[i]  = min(shrub_max,
            env.shrub_map[i]  + rand(env.rng) * shrub_rate  * shrub_max)
        env.canopy_map[i] = min(canopy_max,
            env.canopy_map[i] + rand(env.rng) * canopy_rate * canopy_max)
    end
end

"""
    eat_layered!(ag::Agent, env::Environment)

Attempt to eat from the highest available resource tier at the agent's current
cell, in order: canopy (if wing_size >= threshold) > shrub > ground grass
(already eaten in tick_agents!; this function adds supplemental layered eating).

Updates `ag.niche_layer` to reflect which tier the agent used this tick:
- 3 = canopy
- 2 = shrubs
- 1 = ground (default; no gain here since grass already consumed)

Energy gain is proportional to the resource density at the cell.
Resource is depleted proportionally to the amount eaten.

No-op when `complex_landscape == false`.
"""
function eat_layered!(ag::Agent, env::Environment)
    Bool(get(env.specs, "complex_landscape", false)) || return

    x   = Int(ag.x)
    y   = Int(ag.y)
    thr = Float32(get(env.specs, "canopy_threshold", 0.6))

    if ag.wing_size >= thr && env.canopy_map[x, y] > 0.0f0
        # Canopy access: gain proportional to density; deplete
        gain = env.canopy_map[x, y]
        ag.energy += gain
        env.canopy_map[x, y] = 0.0f0
        ag.niche_layer = Int32(3)
    elseif env.shrub_map[x, y] > 0.0f0
        # Shrub access: all agents can eat shrubs
        gain = env.shrub_map[x, y]
        ag.energy += gain
        env.shrub_map[x, y] = 0.0f0
        ag.niche_layer = Int32(2)
    else
        ag.niche_layer = Int32(1)
    end
end
