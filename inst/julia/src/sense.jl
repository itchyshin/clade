"""
    sense.jl — Sensory input vector construction.

Builds the sensory input vector for one agent at its current position. The
vector is consumed by brain.forward() each tick.

## Input vector layout

The vector length depends on `input_radius` (r, default 1) and active modules.

Index  Content
-----  -------
1      own_energy / energy_max                       (normalised [0, 1])
2      own_age / max_age                             (normalised [0, 1])
3–(2+4r)   grass N/E/S/W at distances 1..r          (4r values)
(3+4r)–(2+8r) agent occupancy N/E/S/W at 1..r       (4r values)
(3+8r) constant bias term = 1.0

Base length = 1 + 8r + 2 = 3 + 8r  (r=1 → 11, r=2 → 19)

## Optional extensions (appended in order):
+ n_predators_init > 0: predator distance N/E/S/W at 1..r (+4r)
+ parental_care = true: care_load / max_clutch_size, mean offspring energy (+2)
+ signal_dims > 0: own signal vector (+signal_dims)

Total length = (3 + 8r) + 4r*(pred) + 2*(care) + signal_dims.
This matches `_compute_n_inputs()` in Clade.jl.
"""

"""
    sense_agent(ag::Agent, env::Environment) -> Vector{Float32}

Build the sensory input vector for `ag`. Reads the environment grid directly;
no memory allocation beyond the output vector.

The sensing radius is controlled by `specs["input_radius"]` (default 1). Radius 1
gives the standard 4-cell cardinal sensing (N/E/S/W). Radius 2 extends to 8
cells along each cardinal axis (steps 1 and 2 in each direction), doubling the
grass and occupancy slots to 8 each and the predator slots to 8.
"""
function sense_agent(ag::Agent, env::Environment)::Vector{Float32}
    specs = env.specs
    rows  = Int(specs["grid_rows"])
    cols  = Int(specs["grid_cols"])
    emax  = Float32(get(specs, "energy_max",  200.0))
    amax  = Float32(get(specs, "max_age",     200.0))
    mmax  = Float32(get(specs, "max_agents",  500.0))
    gmax  = Float32(get(specs, "grass_max",   5.0))
    r     = Int(get(specs, "input_radius", 1))

    x, y = Int(ag.x), Int(ag.y)

    inp = Vector{Float32}(undef, n_inputs(ag.brain))
    pos = 1

    # 1. Energy (normalised)
    inp[pos] = clamp(ag.energy / emax, 0.0f0, 1.0f0);  pos += 1
    # 2. Age (normalised)
    inp[pos] = clamp(Float32(ag.age) / amax, 0.0f0, 1.0f0); pos += 1

    # 3–(2+4r). Grass in cardinal cells at distances 1..r (N/E/S/W × r steps)
    for d in 1:r
        xN = mod1(x - d, rows);  xS = mod1(x + d, rows)
        yE = mod1(y + d, cols);  yW = mod1(y - d, cols)
        inp[pos] = env.grass[xN, y]  / gmax;  pos += 1
        inp[pos] = env.grass[x,  yE] / gmax;  pos += 1
        inp[pos] = env.grass[xS, y]  / gmax;  pos += 1
        inp[pos] = env.grass[x,  yW] / gmax;  pos += 1
    end

    # Next 4r. Occupied cells (1 = another agent present) at distances 1..r
    for d in 1:r
        xN = mod1(x - d, rows);  xS = mod1(x + d, rows)
        yE = mod1(y + d, cols);  yW = mod1(y - d, cols)
        inp[pos] = env.agent_map[xN, y]  > 0 ? 1.0f0 : 0.0f0; pos += 1
        inp[pos] = env.agent_map[x,  yE] > 0 ? 1.0f0 : 0.0f0; pos += 1
        inp[pos] = env.agent_map[xS, y]  > 0 ? 1.0f0 : 0.0f0; pos += 1
        inp[pos] = env.agent_map[x,  yW] > 0 ? 1.0f0 : 0.0f0; pos += 1
    end

    # Bias
    inp[pos] = 1.0f0; pos += 1

    # Optional: predator proximity at distances 1..r (N/E/S/W × r steps)
    if Int(get(specs, "n_predators_init", 0)) > 0
        for d in 1:r
            xN = mod1(x - d, rows);  xS = mod1(x + d, rows)
            yE = mod1(y + d, cols);  yW = mod1(y - d, cols)
            inp[pos] = _pred_dist(env, xN, y);  pos += 1
            inp[pos] = _pred_dist(env, x,  yE); pos += 1
            inp[pos] = _pred_dist(env, xS, y);  pos += 1
            inp[pos] = _pred_dist(env, x,  yW); pos += 1
        end
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
