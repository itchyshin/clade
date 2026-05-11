"""
    habitat_preference.jl — Secondary movement toward preferred habitat density.

Agents with `habitat_preference != 0` take a second movement step each tick
toward the cardinal neighbour that best matches their preference:

- `habitat_preference > 0` → prefer cells with MORE grass (resource-rich
  microhabitats). Approximates ideal free distribution in resource-patch
  landscapes (Fretwell & Lucas 1970).
- `habitat_preference < 0` → prefer cells with LESS grass (low-competition
  refugia). Models avoidance of over-exploited patches.

The probability of attempting the step is `abs(hp) * habitat_preference_strength`.
The agent moves to the best available (unoccupied, in-bounds) cardinal
neighbour. If no better neighbour exists the agent stays put. The move costs
`habitat_move_cost` energy (default 0; set > 0 to impose a trade-off).

Habitat preference is expressed from the heritable genome slot
TRAIT_HABITAT_PREFERENCE and inherits with mutation governed by
`habitat_preference_mutation_sd`.

## References

Fretwell, S.D. & Lucas, H.L. (1970) On territorial behaviour and other
factors influencing habitat distribution in birds. *Acta Biotheoretica*
19(1):16–36.

Morris, D.W. (2003) Toward an ecological synthesis: a case for habitat
selection. *Oecologia* 136(1):1–13.
"""

"""
    apply_habitat_preference!(env::Environment)

Apply one secondary habitat-preference movement step to all live agents.
Increments `env.n_habitat_moves` for each move made.
"""
function apply_habitat_preference!(env::Environment)
    Bool(get(env.specs, "habitat_preference_evolution", false)) || return

    specs     = env.specs
    strength  = Float32(get(specs, "habitat_preference_strength", 0.5))
    gmax      = Float32(get(specs, "grass_max", 5.0))
    move_cost = Float32(get(specs, "habitat_move_cost", 0.0))
    rows      = size(env.grass, 1)
    cols      = size(env.grass, 2)
    toroidal  = Bool(get(specs, "toroidal", true))

    # Cardinal directions: N, E, S, W
    DX = (Int32(-1), Int32(0),  Int32(1), Int32(0))
    DY = (Int32(0),  Int32(1),  Int32(0), Int32(-1))

    # 0.7.0: random asynchronous scheduling (see tick.jl).
    n_ag       = length(env.agents)
    rand_order = Bool(get(specs, "random_tick_order", true))
    order      = rand_order ? randperm(env.rng, n_ag) : (1:n_ag)

    for i in order
        ag = env.agents[i]
        ag.alive || continue
        hp = ag.habitat_preference
        hp == 0.0f0 && continue
        rand(env.rng) > abs(hp) * strength && continue

        x, y = Int(ag.x), Int(ag.y)
        cur_grass = env.grass[x, y]

        # Score of current cell under this agent's preference
        best_score = hp > 0.0f0 ? cur_grass : (gmax - cur_grass)
        best_dx = Int32(0); best_dy = Int32(0); moved = false

        for d in 1:4
            nx = wrap_or_clamp(x + Int(DX[d]), rows, toroidal)
            ny = wrap_or_clamp(y + Int(DY[d]), cols, toroidal)
            # Must be unoccupied (agent_map == 0 means free)
            env.agent_map[nx, ny] != 0 && continue
            g     = env.grass[nx, ny]
            score = hp > 0.0f0 ? g : (gmax - g)
            if score > best_score
                best_score = score
                best_dx    = DX[d]
                best_dy    = DY[d]
                moved      = true
            end
        end

        moved || continue

        # Perform move: update agent_map and agent position
        env.agent_map[x, y] = 0
        nx_new = Int32(wrap_or_clamp(x + Int(best_dx), rows, toroidal))
        ny_new = Int32(wrap_or_clamp(y + Int(best_dy), cols, toroidal))
        ag.x = nx_new
        ag.y = ny_new
        env.agent_map[nx_new, ny_new] = 1   # non-zero = occupied (index updated below)
        ag.energy -= move_cost
        env.n_habitat_moves += Int32(1)
    end

    # Rebuild agent_map indices correctly after all habitat moves
    # (the 1-placeholder above is only correct if we rebuild afterward)
    fill!(env.agent_map, Int64(0))
    for (idx, ag) in enumerate(env.agents)
        ag.alive && (env.agent_map[ag.x, ag.y] = idx)
    end
end
