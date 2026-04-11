"""
    group_defense.jl — Dilution-of-risk protection in grouped agents.

Agents in groups suffer reduced damage from predator attacks. The damage
reduction factor for a focal agent is:

    factor = 1 / (1 + N_nearby × group_defense_strength)

where `N_nearby` is the number of live prey within a Chebyshev radius of
`group_defense_radius` cells (default 2). This implements the dilution-of-risk
(Hamilton 1971) and confusion-effect (Krause & Ruxton 2002) predictions: an
individual's per-capita risk drops as group size grows.

Group defense is called from the predator tick loop (Phase 7d) AFTER predator
attacks are computed. It modifies a `damage_vector::Vector{Float32}` in place
before the energy deductions are applied to agents. When predators are absent
(Phase < 7d) the module is compiled but never called.

## Parameters

| Spec field              | Default | Meaning                                              |
|-------------------------|---------|------------------------------------------------------|
| `group_defense`         | false   | Enable group defense.                                |
| `group_defense_radius`  | 2L      | Chebyshev neighbourhood radius (cells).              |
| `group_defense_strength`| 0.3     | Damage reduction per additional neighbour.           |

## References

Hamilton, W.D. (1971) Geometry for the selfish herd.
*Journal of Theoretical Biology* 31(2):295–311.

Krause, J. & Ruxton, G.D. (2002) *Living in Groups.* Oxford University Press.
"""

"""
    apply_group_defense!(env::Environment, damage::Vector{Float32}) -> Vector{Float32}

Reduce predator attack damage for grouped agents. Called from the predator
tick (Phase 7d) with a pre-computed per-agent damage vector. Returns the
modified damage vector.

When `group_defense == false` the vector is returned unchanged.
"""
function apply_group_defense!(env::Environment,
                               damage::Vector{Float32})::Vector{Float32}
    Bool(get(env.specs, "group_defense", false)) || return damage
    any(d -> d > 0.0f0, damage) || return damage

    specs    = env.specs
    radius   = Int(get(specs, "group_defense_radius",  2))
    strength = Float32(get(specs, "group_defense_strength", 0.3))
    toroidal = Bool(get(specs, "toroidal", true))
    rows     = size(env.grass, 1)
    cols     = size(env.grass, 2)

    for (i, ag) in enumerate(env.agents)
        damage[i] > 0.0f0 || continue
        x, y = Int(ag.x), Int(ag.y)

        # Count live prey within Chebyshev radius (toroidal)
        n_nearby = 0
        for dx in -radius:radius, dy in -radius:radius
            (dx == 0 && dy == 0) && continue
            nx = wrap_or_clamp(x + dx, rows, toroidal)
            ny = wrap_or_clamp(y + dy, cols, toroidal)
            env.agent_map[nx, ny] > 0 && (n_nearby += 1)
        end

        if n_nearby > 0
            factor     = 1.0f0 / (1.0f0 + Float32(n_nearby) * strength)
            damage[i] *= factor
            env.n_gd_events += Int32(1)
        end
    end
    damage
end
