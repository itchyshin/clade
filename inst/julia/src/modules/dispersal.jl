"""
    dispersal.jl — Natal dispersal evolution: agents move away from birthplace.

Enabled when `specs["dispersal_evolution"] == true`.

## Biological model

Natal dispersal is the tendency of offspring to leave their area of birth.
It reduces inbreeding depression (by reducing mating with close relatives)
and kin competition (by moving to less crowded patches). Each agent carries
a heritable continuous `dispersal_tendency` trait ∈ [0, 1]: the per-tick
probability that the agent takes one step away from its birthplace.

## Algorithm

Each tick, for each live agent with `dispersal_tendency > 0`:
1. Sample Bernoulli(dispersal_tendency). Skip if sample is 0.
2. Evaluate four cardinal neighbours. Compute squared Euclidean distance from
   birthplace `(x_birth, y_birth)` for each candidate cell (toroidal wrap).
3. Move to the neighbour that maximises distance from birthplace (if any
   neighbour is further away than the current cell). Ties broken by first
   occurrence.
4. Deduct `dispersal_cost` energy.
5. Increment `env.n_dispersal_events`.

Dispersal uses *toroidal* distance so that agents near an edge still disperse
consistently. An agent that cannot find a free neighbour cell (all occupied or
closer to birthplace) stays put.

## Integration

Called once per tick after `apply_body_size!` (or after `tick_agents!` when
body_size is off). Does NOT use `env.agent_map` for empty-cell checking —
it only checks the map for occupancy (map[nx, ny] == 0). The map is rebuilt
by `tick_agents!` already; dispersal updates it in place.

## References

Clobert, J. et al. (2001) *Dispersal.* Oxford University Press.
Ronce, O. (2007) How does it feel to be like a rolling stone? Ten questions
  about dispersal evolution. *Annual Review of Ecology, Evolution, and
  Systematics* 38:231–253.
Hamilton, W.D. & May, R.M. (1977) Dispersal in stable habitats. *Nature*
  269:578–581.
"""

# Cardinal directions: N, E, S, W
const _DISP_DX = Int32[-1,  0,  1,  0]
const _DISP_DY = Int32[ 0,  1,  0, -1]

"""
    apply_dispersal!(env::Environment)

Run one round of natal dispersal for all live agents. No-op when
`specs["dispersal_evolution"] == false`.
"""
function apply_dispersal!(env::Environment)
    Bool(get(env.specs, "dispersal_evolution", false)) || return

    specs    = env.specs
    cost     = Float32(get(specs, "dispersal_cost", 2.0))
    rows     = Int(specs["grid_rows"])
    cols     = Int(specs["grid_cols"])
    toroidal = Bool(get(specs, "toroidal", true))

    # 0.7.0: random asynchronous scheduling (see tick.jl). First-array
    # agents otherwise claimed the best free cardinal cell first.
    n_ag       = length(env.agents)
    rand_order = Bool(get(specs, "random_tick_order", true))
    order      = rand_order ? randperm(env.rng, n_ag) : (1:n_ag)

    @inbounds for i in order
        ag = env.agents[i]
        ag.alive || continue
        ag.dispersal_tendency <= 0.0f0 && continue
        # Don't disperse if energy is too low
        ag.energy <= cost * 2.0f0 && continue
        rand(env.rng) > Float64(ag.dispersal_tendency) && continue

        # Find cardinal neighbour that maximises toroidal distance from birthplace
        ax, ay  = Int(ag.x), Int(ag.y)
        bx, by  = Int(ag.x_birth), Int(ag.y_birth)

        # Current squared toroidal distance from birthplace
        cur_dist2 = _torus_dist2(ax, ay, bx, by, rows, cols)

        best_dist2 = cur_dist2
        best_nx    = ax
        best_ny    = ay

        for d in 1:4
            nx = wrap_or_clamp(ax + _DISP_DX[d], rows, toroidal)
            ny = wrap_or_clamp(ay + _DISP_DY[d], cols, toroidal)
            env.agent_map[nx, ny] == 0 || continue   # cell occupied
            d2 = _torus_dist2(nx, ny, bx, by, rows, cols)
            if d2 > best_dist2
                best_dist2 = d2
                best_nx    = nx
                best_ny    = ny
            end
        end

        best_nx == ax && best_ny == ay && continue   # no improvement found

        # Move
        env.agent_map[ax, ay]           = 0
        ag.x                            = Int32(best_nx)
        ag.y                            = Int32(best_ny)
        env.agent_map[best_nx, best_ny] = findfirst(a -> a === ag, env.agents)
        ag.energy -= cost
        env.n_dispersal_events += Int32(1)
    end
    nothing
end

"""
    _torus_dist2(x1, y1, x2, y2, rows, cols) -> Int

Squared toroidal Euclidean distance between two grid cells. Wraps correctly
around both axes.
"""
function _torus_dist2(x1::Int, y1::Int, x2::Int, y2::Int,
                       rows::Int, cols::Int)::Int
    dx = abs(x1 - x2)
    dy = abs(y1 - y2)
    dx = min(dx, rows - dx)
    dy = min(dy, cols - dy)
    dx * dx + dy * dy
end
