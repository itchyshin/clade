"""
    cooperation.jl — Spatial public goods game (cooperation evolution).

Enabled when `specs["cooperation_evolution"] == true`. Each live agent plays
one public goods game with itself plus all live agents in its Moore
neighbourhood (9-cell group). This is the lattice public goods game of
Nowak & May (1992), with continuous cooperation levels rather than
pure C / D strategies.

## Donor-centred payoff

Let the focal agent's local group contain `n_local` agents. Each agent `i`
in the group contributes `c_i = cooperation_level_i * cooperation_cost` to a
common pool. The pool is multiplied by `M = cooperation_multiplier` and the
result is divided equally among all `n_local` members:

    share_i = M * sum(c_j, j in group) / n_local
    Δenergy_i = share_i - c_i

With `M = 2` and a dyadic group (`n_local = 2`), a pure cooperator playing
another pure cooperator breaks even (`2*2C / 2 - C = C`); with a defector,
the cooperator loses `C / 2`. For `M > n_local`, cooperation is unconditionally
profitable — the classic tragedy-of-the-commons threshold at `M = n_local`
is reproduced.

## Important: donor-centred, not recipient-centred

An earlier alifeR implementation used a recipient-centred formulation in
which every agent received a share from every neighbour who had already
contributed. This double-counted contributions (each cooperator paid once
but was effectively credited to every neighbour's group), producing a
zero-sum transfer that cannot select for cooperation. The donor-centred
formulation used here is the one analysed in Nowak & May (1992) and in
Hauert et al. (2002).

## Accumulator pattern

Energy deltas are accumulated in a scratch vector and applied after all
games have been scored. This removes order dependence: the payoff to agent
`i` depends only on the state at the start of `apply_cooperation!`, not on
whether neighbour `j` has already been updated. Agents receiving positive
net payoffs have their energy capped at `specs["energy_max"]`.

## Counter

`env.n_cooperation_acts` is incremented once per game in which at least one
non-zero contribution was made.

References
----------
Nowak, M.A. & May, R.M. (1992) Evolutionary games and spatial chaos.
    Nature 359:826–829.
Hauert, C., De Monte, S., Hofbauer, J. & Sigmund, K. (2002) Volunteering
    and the tragedy of the commons. Science 296:1129–1132.
Hamilton, W.D. (1964) The genetical evolution of social behaviour I & II.
    Journal of Theoretical Biology 7:1–52.
"""

"""
    apply_cooperation!(env::Environment)

Run one round of the spatial public goods game for all live agents.
"""
function apply_cooperation!(env::Environment)
    Bool(get(env.specs, "cooperation_evolution", false)) || return

    specs = env.specs
    rows  = Int(specs["grid_rows"])
    cols  = Int(specs["grid_cols"])
    cost  = Float32(get(specs, "cooperation_cost",       1.0))
    mult  = Float32(get(specs, "cooperation_multiplier", 2.0))
    e_max = Float32(get(specs, "energy_max",           200.0))

    n_agents = length(env.agents)
    n_agents == 0 && return

    # Scratch vector: Δenergy for each agent (indexed by position in env.agents)
    deltas = zeros(Float32, n_agents)

    @inbounds for (focal_idx, focal) in enumerate(env.agents)
        focal.alive || continue

        # Collect the local group: focal + all agents in the 3×3 Moore block.
        # On a toroidal grid we wrap around with mod1. Because agent_map holds
        # at most one agent per cell (see tick.jl rebuild), one Moore pass
        # yields at most 9 group members.
        fx, fy = Int(focal.x), Int(focal.y)
        group_idx = Int[]               # indices into env.agents
        pool = 0.0f0

        for dx in -1:1, dy in -1:1
            nx = mod1(fx + dx, rows)
            ny = mod1(fy + dy, cols)
            m  = env.agent_map[nx, ny]
            m == 0 && continue
            neighbour = env.agents[m]
            neighbour.alive || continue
            push!(group_idx, m)
            pool += neighbour.cooperation_level * cost
        end

        n_local = length(group_idx)
        n_local == 0 && continue        # should never happen (focal is in it)

        # Public pool is multiplied and divided equally.
        share = mult * pool / Float32(n_local)

        # Net payoff to each group member. Only the focal game is scored here
        # — each agent will be the focal in its own iteration, so each game
        # is counted once per potential focal agent. The payoff is summed into
        # `deltas` across all games a given agent participates in, which is
        # consistent with Nowak & May's iterated lattice formulation where
        # each cell accumulates payoff from every game it plays.
        for idx in group_idx
            own_contrib = env.agents[idx].cooperation_level * cost
            deltas[idx] += share - own_contrib
        end

        # A game counts as a cooperation act whenever any non-zero
        # contribution was made to the pool.
        pool > 0.0f0 && (env.n_cooperation_acts += Int32(1))
    end

    # Apply accumulated energy deltas with the energy_max cap.
    @inbounds for i in 1:n_agents
        ag = env.agents[i]
        ag.alive || continue
        ag.energy = min(ag.energy + deltas[i], e_max)
    end
    nothing
end

"""
    express_cooperation_level(agent::Agent, specs) -> Float32

Return the agent's expressed cooperation level. The trait is set at birth
(in `_make_offspring` / `_make_founder_agent`) by `express_trait`, so this
is just a pass-through provided for legibility at call sites where the
dependency on `cooperation_evolution` is being checked.
"""
function express_cooperation_level(agent::Agent, specs::Dict{String,Any})::Float32
    Bool(get(specs, "cooperation_evolution", false)) || return 0.0f0
    agent.cooperation_level
end

# === CLADE.JL ADDITIONS NEEDED ===
# include: include("modules/cooperation.jl")
# tick loop: apply_cooperation!(env)    [after tick_agents!, any position
#                                        before kill_dead!; safe to run
#                                        alongside other post-tick modules]
# logging.jl: add "n_cooperation_acts" key to _init_progress() Dict, and
#             p["n_cooperation_acts"][t] = Int(env.n_cooperation_acts) in
#             log_tick!() (the Environment struct already has the counter).
# No dependencies on other modules; no Environment struct changes needed.
# === END CLADE.JL ADDITIONS ===
