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
    specs    = env.specs
    rows     = Int(specs["grid_rows"])
    cols     = Int(specs["grid_cols"])
    toroidal = Bool(get(specs, "toroidal", true))
    emax  = Float32(get(specs, "energy_max",  200.0))
    amax  = Float32(get(specs, "max_age",     200.0))
    mmax  = Float32(get(specs, "max_agents",  500.0))
    gmax  = Float32(get(specs, "grass_max",   5.0))
    r     = Int(get(specs, "input_radius", 1))

    x, y = Int(ag.x), Int(ag.y)

    inp = Vector{Float32}(undef, n_inputs(ag.brain))
    pos = 1

    # Brain-size sensing multiplier (third brain_size_evolution effect).
    # Scales grass perception by brain_size ^ brain_size_sensing_exponent.
    # brain_size = 1.0 → multiplier = 1.0 (no change).
    # brain_size > 1.0 → multiplier > 1.0 → amplified grass gradients → better
    # navigation toward food. brain_size < 1.0 → attenuated perception.
    # No-op when brain_size_evolution = false (brain_size is always 1.0f0).
    bs_exp     = Float32(get(specs, "brain_size_sensing_exponent", 0.3))
    sense_mult = ag.brain_size ^ bs_exp   # == 1.0 when brain_size == 1.0

    # 1. Energy (normalised)
    inp[pos] = clamp(ag.energy / emax, 0.0f0, 1.0f0);  pos += 1
    # 2. Age (normalised)
    inp[pos] = clamp(Float32(ag.age) / amax, 0.0f0, 1.0f0); pos += 1

    # 3–(2+4r). Grass in cardinal cells at distances 1..r (N/E/S/W × r steps)
    # Grass inputs scaled by sense_mult (clamped to [0, 1]): larger-brained
    # agents perceive resource gradients more clearly.
    for d in 1:r
        xN = wrap_or_clamp(x - d, rows, toroidal);  xS = wrap_or_clamp(x + d, rows, toroidal)
        yE = wrap_or_clamp(y + d, cols, toroidal);  yW = wrap_or_clamp(y - d, cols, toroidal)
        inp[pos] = clamp(env.grass[xN, y]  / gmax * sense_mult, 0.0f0, 1.0f0);  pos += 1
        inp[pos] = clamp(env.grass[x,  yE] / gmax * sense_mult, 0.0f0, 1.0f0);  pos += 1
        inp[pos] = clamp(env.grass[xS, y]  / gmax * sense_mult, 0.0f0, 1.0f0);  pos += 1
        inp[pos] = clamp(env.grass[x,  yW] / gmax * sense_mult, 0.0f0, 1.0f0);  pos += 1
    end

    # Next 4r. Occupied cells (1 = another agent present) at distances 1..r
    for d in 1:r
        xN = wrap_or_clamp(x - d, rows, toroidal);  xS = wrap_or_clamp(x + d, rows, toroidal)
        yE = wrap_or_clamp(y + d, cols, toroidal);  yW = wrap_or_clamp(y - d, cols, toroidal)
        inp[pos] = env.agent_map[xN, y]  > 0 ? 1.0f0 : 0.0f0; pos += 1
        inp[pos] = env.agent_map[x,  yE] > 0 ? 1.0f0 : 0.0f0; pos += 1
        inp[pos] = env.agent_map[xS, y]  > 0 ? 1.0f0 : 0.0f0; pos += 1
        inp[pos] = env.agent_map[x,  yW] > 0 ? 1.0f0 : 0.0f0; pos += 1
    end

    # Bias
    inp[pos] = 1.0f0; pos += 1

    # Optional: predator proximity at distances 1..r (N/E/S/W × r steps)
    if Int(get(specs, "n_predators_init", 0)) > 0
        graded = Bool(get(specs, "predator_sense_graded", true))
        for d in 1:r
            xN = mod1(x - d, rows);  xS = mod1(x + d, rows)
            yE = mod1(y + d, cols);  yW = mod1(y - d, cols)
            inp[pos] = _pred_dist(env, xN, y, d, graded); pos += 1
            inp[pos] = _pred_dist(env, x,  yE, d, graded); pos += 1
            inp[pos] = _pred_dist(env, xS, y, d, graded); pos += 1
            inp[pos] = _pred_dist(env, x,  yW, d, graded); pos += 1
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

    # Optional: own signal (clamped to [0, 1] for consistency with other
    # sensory channels — signal traits evolve freely but the brain sees a
    # bounded value, matching grass/energy/age/care normalisation).
    for s in ag.signal
        inp[pos] = clamp(s, 0.0f0, 1.0f0);  pos += 1
    end

    inp
end

"""
    _pred_dist(env, x, y, d, graded) -> Float32

Predator-proximity signal for cell (x, y) at distance `d`. Returns 0 if no
predator occupies the cell. When `graded` is `true` (the 0.4.2 default),
returns `1/(d+1)` — closer predators produce a stronger signal, giving the
brain a distance-graded threat input. When `false`, returns `1.0f0` (legacy
binary behaviour pre-0.4.2).
"""
_pred_dist(env::Environment, x::Int, y::Int, d::Int, graded::Bool)::Float32 =
    env.predator_map[x, y] > 0 ?
        (graded ? 1.0f0 / Float32(d + 1) : 1.0f0) :
        0.0f0
