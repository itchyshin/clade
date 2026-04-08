"""
    sense.jl — Sensory input vector construction.

Builds the sensory input vector for one agent at its current position. The
vector is consumed by brain.forward() each tick.

## Input vector layout (base: 11 elements)

Index  Content
-----  -------
1      own_energy / energy_max                    (normalised [0, 1])
2      own_age / max_age                          (normalised [0, 1])
4–5    grass N / E / S / W (clipped to [0,1])    (4 values)
6–9    wall N / E / S / W                        (1 = wall/edge, 0 = open)
10     local_density / max_agents                 (normalised)
11     constant bias term = 1.0

## Optional extensions (appended in order):
+ n_predators_init > 0: predator distance N/E/S/W (+4; value = 1/dist, 0 if none)
+ parental_care = true: care_load / max_clutch_size, mean offspring energy (+2)
+ signal_dims > 0: own signal vector (+signal_dims)

Total length = 11 + 4*(pred) + 2*(care) + signal_dims.
This matches `_compute_n_inputs()` in Clade.jl.
"""

"""
    sense_agent(ag::Agent, env::Environment) -> Vector{Float32}

Build the sensory input vector for `ag`. Reads the environment grid directly;
no memory allocation beyond the output vector.
"""
function sense_agent(ag::Agent, env::Environment)::Vector{Float32}
    specs = env.specs
    rows  = Int(specs["grid_rows"])
    cols  = Int(specs["grid_cols"])
    emax  = Float32(get(specs, "energy_max",  200.0))
    amax  = Float32(get(specs, "max_age",     200.0))
    mmax  = Float32(get(specs, "max_agents",  500.0))
    gmax  = Float32(get(specs, "grass_max",   5.0))

    x, y = Int(ag.x), Int(ag.y)

    # Moore neighbourhood — toroidal wrapping
    xN = mod1(x - 1, rows);  xS = mod1(x + 1, rows)
    yE = mod1(y + 1, cols);  yW = mod1(y - 1, cols)

    inp = Vector{Float32}(undef, n_inputs(ag.brain))
    pos = 1

    # 1. Energy (normalised)
    inp[pos] = clamp(ag.energy / emax, 0.0f0, 1.0f0);  pos += 1
    # 2. Age (normalised)
    inp[pos] = clamp(Float32(ag.age) / amax, 0.0f0, 1.0f0); pos += 1
    # 3–6. Grass in N/E/S/W cells (normalised)
    inp[pos]   = env.grass[xN, y]  / gmax;  pos += 1
    inp[pos]   = env.grass[x,  yE] / gmax;  pos += 1
    inp[pos]   = env.grass[xS, y]  / gmax;  pos += 1
    inp[pos]   = env.grass[x,  yW] / gmax;  pos += 1
    # 7–10. Occupied cells (1 = another agent present)
    inp[pos]   = env.agent_map[xN, y]  > 0 ? 1.0f0 : 0.0f0; pos += 1
    inp[pos]   = env.agent_map[x,  yE] > 0 ? 1.0f0 : 0.0f0; pos += 1
    inp[pos]   = env.agent_map[xS, y]  > 0 ? 1.0f0 : 0.0f0; pos += 1
    inp[pos]   = env.agent_map[x,  yW] > 0 ? 1.0f0 : 0.0f0; pos += 1
    # 11. Bias
    inp[pos] = 1.0f0; pos += 1

    # Optional: predator proximity (N/E/S/W)
    if Int(get(specs, "n_predators_init", 0)) > 0
        inp[pos]   = _pred_dist(env, xN, y);   pos += 1
        inp[pos]   = _pred_dist(env, x,  yE);  pos += 1
        inp[pos]   = _pred_dist(env, xS, y);   pos += 1
        inp[pos]   = _pred_dist(env, x,  yW);  pos += 1
    end

    # Optional: parental care signals
    if Bool(get(specs, "parental_care", false))
        max_cl    = Float32(max(1, get(specs, "max_clutch_size", 1)))
        inp[pos]  = Float32(ag.care_load) / max_cl;  pos += 1
        mean_e    = ag.care_load > 0 ?
                    mean(Float32[c.energy for c in ag.carried_offspring]) : 0.0f0
        inp[pos]  = clamp(mean_e / emax, 0.0f0, 1.0f0);  pos += 1
    end

    # Optional: own signal
    for s in ag.signal
        inp[pos] = s;  pos += 1
    end

    inp
end

"""
    _pred_dist(env, x, y) -> Float32

Return 1/(distance+1) to the nearest predator in cell (x,y), or 0 if none.
"""
_pred_dist(env::Environment, x::Int, y::Int)::Float32 =
    env.predator_map[x, y] > 0 ? 1.0f0 : 0.0f0
