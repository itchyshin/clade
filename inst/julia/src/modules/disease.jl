"""
    disease.jl — SIR (Susceptible-Infected-Recovered) disease dynamics.

Enabled when `specs["disease"] == true`. Agents occupy one of three epidemic
states:

- **S** — susceptible: `ag.infected == false && ag.immune == false`
- **I** — infected:    `ag.infected == true`
- **R** — recovered:   `ag.immune   == true`

The state variable `ag.immune_strength` (evolvable when `immune_evolution ==
true`, otherwise fixed at 0 for all agents) down-scales both transmission
probability and disease-induced mortality. This couples the SIR module to the
heritable immune-strength trait: populations that evolve higher immune strength
experience lower effective transmission and lower case fatality.

When `immune_evolution == false`, every agent has `immune_strength == 0`, so
the effective probabilities collapse to the raw `transmission_prob` and
`disease_death_prob` values from specs.

References
----------
Kermack, W.O. & McKendrick, A.G. (1927) A contribution to the mathematical
    theory of epidemics. Proceedings of the Royal Society of London A
    115(772):700–721.
Anderson, R.M. & May, R.M. (1991) Infectious Diseases of Humans: Dynamics
    and Control. Oxford University Press.
"""

"""
    seed_disease!(env::Environment)

Seed the initial wave of infection. Called **once**, at tick 1 only.
Each susceptible agent becomes infected independently with probability
`specs["disease_seed_prob"]`.

Infected seed agents have `infection_age` reset to 0 so that the `disease_duration`
clock starts from the moment they are seeded.

Increments `env.n_new_infections` by the number of seeded agents.
"""
function seed_disease!(env::Environment)
    specs = env.specs
    Bool(get(specs, "disease", false)) || return
    seed_prob = Float32(get(specs, "disease_seed_prob", 0.0))
    seed_prob <= 0.0f0 && return

    n_seeded = 0
    for ag in env.agents
        ag.alive || continue
        ag.infected && continue
        ag.immune   && continue
        if rand(env.rng) < seed_prob
            ag.infected      = true
            ag.infection_age = Int32(0)
            n_seeded += 1
        end
    end
    env.n_new_infections += Int32(n_seeded)
    return
end

"""
    apply_disease!(env::Environment)

Apply one tick of SIR dynamics. Called every tick when `specs["disease"] == true`.

Steps (in order):

1. **Transmission** — each infected agent probes its 8-cell Moore
   neighbourhood (toroidal wrap) and infects each susceptible neighbour with
   probability `transmission_prob * (1 - receiver.immune_strength)`. A
   newly-infected agent is not immediately contagious in the same tick — new
   infections are collected into a buffer and applied after the full scan so
   that transmission is order-independent within a single tick.

2. **Disease cost** — each infected agent pays `disease_energy_cost` energy.

3. **Disease mortality** — each infected agent dies with probability
   `disease_death_prob * (1 - ag.immune_strength)`. Dead agents have
   `alive = false`; they are removed later by `remove_dead!()`. Increments
   `env.n_deaths`.

4. **Recovery** — an infected agent whose `infection_age >= disease_duration`
   recovers: `infected = false`, `immune = true`, `immunity_age = 0`.

5. **Immunity waning** — an immune agent whose `immunity_age >= immune_duration`
   loses immunity: `immune = false`, `immunity_age = 0`.

6. **Age increment** — `infection_age += 1` for all infected agents;
   `immunity_age += 1` for all immune agents.

Order matters: transmission is applied before costs and mortality so that a
newly-infected agent pays its first disease cost on the tick it is infected
(mirroring the alifeR implementation). Recovery and waning are applied last
so that the age counters reflect the start-of-tick state.

References
----------
Kermack, W.O. & McKendrick, A.G. (1927) A contribution to the mathematical
    theory of epidemics. Proceedings of the Royal Society of London A
    115(772):700–721.
"""
function apply_disease!(env::Environment)
    specs = env.specs
    Bool(get(specs, "disease", false)) || return

    rows = Int(specs["grid_rows"])
    cols = Int(specs["grid_cols"])

    tprob        = Float32(get(specs, "transmission_prob",   0.1))
    cost         = Float32(get(specs, "disease_energy_cost", 5.0))
    death_prob   = Float32(get(specs, "disease_death_prob",  0.02))
    duration     = Int32(get(specs, "disease_duration",      10))
    immune_dur   = Int32(get(specs, "immune_duration",       20))

    agents = env.agents
    n      = length(agents)
    n == 0 && return

    # ── 1. Transmission (collected then applied) ────────────────────────────
    newly_infected = falses(n)

    @inbounds for i in 1:n
        src = agents[i]
        src.alive    || continue
        src.infected || continue

        xi, yi = Int(src.x), Int(src.y)
        for dx in -1:1, dy in -1:1
            (dx == 0 && dy == 0) && continue
            nx = mod1(xi + dx, rows)
            ny = mod1(yi + dy, cols)
            j  = env.agent_map[nx, ny]
            (j == 0 || j > n) && continue
            newly_infected[j] && continue
            rcv = agents[j]
            rcv.alive    || continue
            rcv.infected && continue
            rcv.immune   && continue

            eff_prob = tprob * (1.0f0 - rcv.immune_strength)
            if rand(env.rng) < eff_prob
                newly_infected[j] = true
            end
        end
    end

    n_new = 0
    @inbounds for j in 1:n
        if newly_infected[j]
            agents[j].infected      = true
            agents[j].infection_age = Int32(0)
            n_new += 1
        end
    end
    env.n_new_infections += Int32(n_new)

    # ── 2. Disease cost and 3. mortality ────────────────────────────────────
    @inbounds for ag in agents
        ag.alive    || continue
        ag.infected || continue

        ag.energy -= cost

        if death_prob > 0.0f0
            eff_death = death_prob * (1.0f0 - ag.immune_strength)
            if eff_death > 0.0f0 && rand(env.rng) < eff_death
                ag.alive = false
                env.n_deaths += Int32(1)
                continue
            end
        end
    end

    # ── 4. Recovery and 6. age increment for infected ───────────────────────
    @inbounds for ag in agents
        ag.alive    || continue
        ag.infected || continue
        ag.infection_age += Int32(1)
        if ag.infection_age >= duration
            ag.infected      = false
            ag.immune        = true
            ag.immunity_age  = Int32(0)
            ag.infection_age = Int32(0)
            env.n_recoveries += Int32(1)
        end
    end

    # ── 5. Immunity waning and 6. age increment for immune ──────────────────
    @inbounds for ag in agents
        ag.alive  || continue
        ag.immune || continue
        ag.immunity_age += Int32(1)
        if ag.immunity_age >= immune_dur
            ag.immune       = false
            ag.immunity_age = Int32(0)
        end
    end

    return
end

"""
    apply_disease_transmission(env::Environment) -> Environment

Pure functional variant that mirrors alifeR's `.apply_disease_transmission()`.
Returns a **shallow copy** of `env` with new infections applied. The copy
shares all agent references with the original (mutable `Agent` structs), so
this is intended only for unit tests that verify transmission semantics in
isolation; production code should call `apply_disease!(env)` which is in
place.

The function does not apply disease cost, mortality, recovery, or waning —
only the transmission step.
"""
function apply_disease_transmission(env::Environment)
    specs = env.specs
    rows  = Int(specs["grid_rows"])
    cols  = Int(specs["grid_cols"])
    tprob = Float32(get(specs, "transmission_prob", 0.1))

    agents = env.agents
    n      = length(agents)
    n == 0 && return env

    newly_infected = falses(n)

    for i in 1:n
        src = agents[i]
        src.alive    || continue
        src.infected || continue
        xi, yi = Int(src.x), Int(src.y)
        for dx in -1:1, dy in -1:1
            (dx == 0 && dy == 0) && continue
            nx = mod1(xi + dx, rows)
            ny = mod1(yi + dy, cols)
            j  = env.agent_map[nx, ny]
            (j == 0 || j > n) && continue
            newly_infected[j] && continue
            rcv = agents[j]
            rcv.alive    || continue
            rcv.infected && continue
            rcv.immune   && continue
            eff_prob = tprob * (1.0f0 - rcv.immune_strength)
            if rand(env.rng) < eff_prob
                newly_infected[j] = true
            end
        end
    end

    n_new = 0
    for j in 1:n
        if newly_infected[j]
            agents[j].infected      = true
            agents[j].infection_age = Int32(0)
            n_new += 1
        end
    end
    env.n_new_infections += Int32(n_new)
    return env
end
