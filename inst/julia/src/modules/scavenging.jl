"""
    scavenging.jl — Carrion dynamics (DeVault et al. 2003).

Enabled when `specs["scavenging"] == true`. When an agent dies, a fraction
of its *body mass* is deposited as carrion at its cell. Live agents that
visit cells with carrion consume it, gaining energy at a capped rate.
Carrion decays exponentially per tick, representing microbial decomposition
and insect removal.

## Body-mass deposit, not current energy

Carrion is deposited in proportion to `specs["energy_init"]`, not in
proportion to the dead agent's *current* energy. In vertebrates the edible
soft-tissue mass available to scavengers scales with structural body mass,
not with how much the animal had recently eaten — a starving animal's
carcass still yields substantial carrion (Houston 1979). An earlier alifeR
implementation used current energy and thereby incorrectly made starvation
reduce carcass value to zero; this implementation does not repeat that bug.

## Tick order

Called from `run_clade!` *after* `kill_dead!` (which flags dead agents but
does not yet remove them from `env.agents`), with `deposit_carrion!` invoked
from inside `kill_dead!` at the moment the agent is marked dead. Scavenging
consumption and decay are applied each tick after `tick_agents!`.

References
----------
DeVault, T.L., Rhodes, O.E. & Shivik, J.A. (2003) Scavenging by vertebrates:
    behavioral, ecological, and evolutionary perspectives on an important
    energy transfer pathway in terrestrial ecosystems. Oikos 102(2):225–234.
Houston, D.C. (1979) The adaptations of scavengers. In: Sinclair, A.R.E. &
    Norton-Griffiths, M. (eds) Serengeti: Dynamics of an Ecosystem, pp
    263–286. University of Chicago Press.
Wilson, E.E. & Wolkovich, E.M. (2011) Scavenging: how carnivores and
    carrion structure communities. Trends in Ecology & Evolution 26(3):129–135.
"""

"""
    deposit_carrion!(env::Environment, agent::Agent)

Deposit carrion at the dying agent's current cell. Called from
`kill_dead!` when `specs["scavenging"] == true`, at the instant the agent
is flagged dead.

The deposited amount is `specs["energy_init"] * specs["carrion_fraction"]`,
i.e. a fixed fraction of body mass. The dead agent's current energy is
irrelevant — a starved carcass still yields the same structural biomass
to scavengers (see module docstring).
"""
function deposit_carrion!(env::Environment, agent::Agent)
    Bool(get(env.specs, "scavenging", false)) || return
    energy_init = Float32(get(env.specs, "energy_init",       100.0))
    frac        = Float32(get(env.specs, "carrion_fraction",    0.5))
    amount      = energy_init * frac
    amount > 0.0f0 || return
    x, y = Int(agent.x), Int(agent.y)
    @inbounds env.carrion_map[x, y] += amount
    # D2: mark cell as infectious if source agent was infected
    if agent.infected
        @inbounds env.carrion_infected_map[x, y] = true
    end
    nothing
end

"""
    apply_scavenging!(env::Environment)

For each live agent, consume up to `specs["carrion_eat_gain"]` units of
carrion at the current cell (capped by the amount actually present). Energy
is added to the agent, capped at `specs["energy_max"]`, and the consumed
amount is removed from `env.carrion_map`.

Agents are processed in their current order in `env.agents`; this is
deterministic given the Julia RNG state but the order in which two agents
on the same cell consume carrion affects what each gets. At most one agent
occupies any one cell after `tick_agents!` (the agent_map rebuild enforces
this), so contention is rare in practice.
"""
function apply_scavenging!(env::Environment)
    Bool(get(env.specs, "scavenging", false)) || return

    eat_gain      = Float32(get(env.specs, "carrion_eat_gain", 3.0))
    e_max         = Float32(get(env.specs, "energy_max",     200.0))
    carrion_tprob = Float32(get(env.specs, "carrion_transmission_prob", 0.0))
    eat_gain > 0.0f0 || return

    # 0.7.0: random asynchronous scheduling (see tick.jl). The docstring claim
    # above (lines 75–78) that agent_map enforces uniqueness was a regression
    # in clade ≤ 0.6.x (it stored only the LAST agent per cell and didn't gate
    # movement); Phase 2 of the consolidation work restored the MATLAB/alifeR
    # one-per-cell rule at movement time, so the docstring is now correct
    # again. See dev/docs/consolidation-audit.md.
    n_ag       = length(env.agents)
    rand_order = Bool(get(env.specs, "random_tick_order", true))
    order      = rand_order ? randperm(env.rng, n_ag) : (1:n_ag)

    @inbounds for i in order
        ag = env.agents[i]
        ag.alive || continue
        x, y = Int(ag.x), Int(ag.y)
        available = env.carrion_map[x, y]
        available > 0.0f0 || continue
        taken = min(available, eat_gain)
        ag.energy = min(ag.energy + taken, e_max)
        env.carrion_map[x, y] = available - taken
        env.n_scavenge_events += Int32(1)
        # D2: carrion-mediated disease transmission
        if carrion_tprob > 0.0f0 && env.carrion_infected_map[x, y] &&
                !ag.infected && !ag.immune && rand(env.rng) < carrion_tprob
            ag.infected      = true
            ag.infection_age = Int32(0)
            env.n_new_infections += Int32(1)
        end
        # Clear infection flag once carrion is fully consumed
        if env.carrion_map[x, y] <= 0.0f0
            env.carrion_infected_map[x, y] = false
        end
    end
    nothing
end

"""
    decay_carrion!(env::Environment)

Apply exponential decay to every cell's carrion store: each cell's carrion
is multiplied by `(1 - specs["carrion_decay_rate"])` each tick. This
represents microbial breakdown and removal by non-modelled invertebrate
scavengers; with the default rate of 0.1, half-life is ~6.6 ticks.
"""
function decay_carrion!(env::Environment)
    Bool(get(env.specs, "scavenging", false)) || return

    decay_rate = Float32(get(env.specs, "carrion_decay_rate", 0.1))
    keep       = 1.0f0 - decay_rate
    if keep <= 0.0f0
        fill!(env.carrion_map, 0.0f0)
        return
    end

    @inbounds for i in eachindex(env.carrion_map)
        env.carrion_map[i] *= keep
        if env.carrion_map[i] <= 0.0f0
            env.carrion_infected_map[i] = false
        end
    end
    nothing
end

# === CLADE.JL ADDITIONS NEEDED ===
# include: include("modules/scavenging.jl")
# tick loop: apply_scavenging!(env)     [after tick_agents!, before kill_dead!]
# tick loop: decay_carrion!(env)        [immediately after apply_scavenging!]
# death.jl: inside kill_dead!(), after `ag.alive = false; _log_death!(...)`,
#           add `scav_on && deposit_carrion!(env, ag)` where
#           `scav_on = Bool(get(specs, "scavenging", false))` is cached at
#           the top of kill_dead!. This is the ONLY cross-file hook required.
# _env_to_result (optional, tests only): add
#           `total_carrion = Float64(sum(env.carrion_map))`
#           to the returned NamedTuple so R tests can verify accumulation
#           without reading the full carrion_map matrix. R/run.R's
#           .julia_env_to_r must forward env_julia$total_carrion.
# env.carrion_map is already initialised in create_environment() as
#   zeros(Float32, rows, cols) — no struct change required.
# === END CLADE.JL ADDITIONS ===
