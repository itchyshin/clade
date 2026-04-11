"""
    tick.jl — Per-tick agent update: sense → decide → move → eat → age.

This is the hot path. Called for every agent every tick. Designed to be
allocation-free for ANN and BNN brains after the initial sensory vector
is built.

## Action encoding

Action  Index  Effect
------  -----  ------
N       1      x -= 1 (toroidal wrap)
E       2      y += 1
S       3      x += 1
W       4      y -= 1
idle    5      stay in place

## Energy update

energy -= move_cost * metabolic_rate   (if moved)
       or idle_cost * metabolic_rate   (if idle)
energy -= brain_energy_cost(brain, logits)
energy += eat_gain * grass[x, y]       (grass fully consumed each tick)

Grass at the agent's new cell is consumed regardless of action (even idle),
consistent with alifeR's "eat where you stand" rule.
"""

"""
    tick_agents!(env::Environment)

Apply one tick to all live agents. Modifies agents and env.grass in place.
Updates env.agent_map after all moves.
"""
function tick_agents!(env::Environment)
    specs    = env.specs
    rows     = Int(specs["grid_rows"])
    cols     = Int(specs["grid_cols"])
    toroidal = Bool(get(specs, "toroidal", true))

    move_cost  = Float32(get(specs, "move_cost",  1.0))
    idle_cost  = Float32(get(specs, "idle_cost",  0.5))
    eat_gain   = Float32(get(specs, "eat_gain",   5.0))
    e_mode     = get(specs, "brain_energy_mode", "activity")
    e_base     = Float32(get(specs, "brain_energy_base",     0.001))
    e_act      = Float32(get(specs, "brain_energy_activity", 0.5))

    # Clear agent map before moves (rebuild below)
    fill!(env.agent_map, Int64(0))

    for ag in env.agents
        ag.alive || continue
        ag.age += Int32(1)

        # ── Sense ─────────────────────────────────────────────────────────
        inp = sense_agent(ag, env)

        # ── Decide ────────────────────────────────────────────────────────
        logits = forward(ag.brain, inp)
        action = argmax(logits)           # greedy; BNN exploration via sigma
        ag.num_choices        += Int32(1)
        ag.num_greedy_choices += Int32(1)

        # ── Move ──────────────────────────────────────────────────────────
        ag.energy_last_tick = ag.energy
        x, y = Int(ag.x), Int(ag.y)
        if action == 1      # N
            x = wrap_or_clamp(x - 1, rows, toroidal)
            ag.energy -= move_cost * ag.metabolic_rate
        elseif action == 2  # E
            y = wrap_or_clamp(y + 1, cols, toroidal)
            ag.energy -= move_cost * ag.metabolic_rate
        elseif action == 3  # S
            x = wrap_or_clamp(x + 1, rows, toroidal)
            ag.energy -= move_cost * ag.metabolic_rate
        elseif action == 4  # W
            y = wrap_or_clamp(y - 1, cols, toroidal)
            ag.energy -= move_cost * ag.metabolic_rate
        else                # idle
            ag.energy -= idle_cost * ag.metabolic_rate
        end
        ag.x = Int32(x)
        ag.y = Int32(y)

        # ── Eat ───────────────────────────────────────────────────────────
        if env.grass[x, y] > 0.0f0
            ag.energy    += eat_gain * env.grass[x, y]
            env.grass[x, y] = 0.0f0
        end
        eat_layered!(ag, env)   # complex landscape: shrub/canopy supplements
        ag.energy = min(ag.energy, Float32(get(specs, "energy_max", 200.0)))

        # ── Brain energy cost ─────────────────────────────────────────────
        ag.energy -= _brain_energy_cost(ag.brain, logits, e_mode, e_base, e_act)
    end

    # Rebuild agent map after all moves
    for (idx, ag) in enumerate(env.agents)
        ag.alive && (env.agent_map[ag.x, ag.y] = idx)
    end
end

"""
    _brain_energy_cost(brain, logits, mode, base, act_scale) -> Float32

Compute the metabolic cost of neural computation.

Mode "none": 0.
Mode "size": base * brain_size(brain).
Mode "activity": base * brain_size(brain) + act_scale * mean(abs.(logits)).
Mode "prediction_error": BNN only; placeholder (returns size cost).

Reference: Yaeger (1994) PolyWorld. In: Artificial Life III.
Addison-Wesley, pp 263–298.
"""
function _brain_energy_cost(brain::AbstractBrain,
                              logits::Vector{Float32},
                              mode::String,
                              base::Float32,
                              act_scale::Float32)::Float32
    mode == "none" && return 0.0f0
    size_cost = base * Float32(brain_size(brain))
    mode == "size" && return size_cost
    if mode == "activity"
        act_cost = act_scale * sum(abs, logits) / Float32(length(logits))
        return size_cost + act_cost
    end
    # prediction_error — use size cost as fallback (Phase 3 will implement KL)
    size_cost
end
