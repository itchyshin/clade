"""
    parental_care.jl — Obligate altricial parental care dynamics.

Enabled when `specs["parental_care"] == true`.

When parental care is active, offspring do not enter `env.agents` at birth.
Instead they live in the parent's `carried_offspring` vector until they reach
independence (by age or energy threshold). The parent pays a per-tick
energetic cost proportional to its care load, and actively feeds each juvenile
from its own energy reserves. Juveniles age and incur a reduced metabolic cost
within the brood. Graduates are placed in a free adjacent cell (toroidal Moore
neighbourhood, shuffled search order); if no cell is available the juvenile
dies. Parent death immediately kills all juveniles still in the brood
(obligate altricial: juveniles cannot survive without the parent).

This implementation mirrors the alifeR reference design documented in
`R/parental_care.R` and described in the CLAUDE.md architecture notes.

References
----------
Clutton-Brock, T.H. (1991) The Evolution of Parental Care. Princeton
    University Press.
Trivers, R.L. (1972) Parental investment and sexual selection. In: Campbell,
    B. (ed.) Sexual Selection and the Descent of Man 1871–1971. Aldine,
    pp. 136–179.
"""

"""
    apply_care_costs!(env::Environment)

Deduct a per-tick energetic care cost from every live parent with a non-zero
care load.

Each parent pays `care_cost_per_tick * care_load` energy units. This
represents the direct metabolic burden of brooding, guarding, or otherwise
maintaining offspring — a cost that scales linearly with brood size in the
simplest altricial model.

Guard: no-op when `specs["parental_care"] == false`.
"""
function apply_care_costs!(env::Environment)
    specs = env.specs
    Bool(get(specs, "parental_care", false)) || return

    cost_per_offspring = Float32(get(specs, "care_cost_per_tick", 1.0))

    @inbounds for ag in env.agents
        ag.alive          || continue
        ag.care_load <= 0 && continue
        ag.energy -= cost_per_offspring * Float32(ag.care_load)
    end
    return
end

"""
    feed_offspring!(env::Environment)

Transfer energy from each live parent to each of its juveniles.

For each juvenile the feeding amount is:

    feeding = min(feeding_rate, parent.energy * 0.3)

so that a parent can never spend more than 30 % of its current energy
reserves on a single juvenile in one tick, regardless of how many offspring
it carries. The parent's energy is debited by the same amount.

This asymmetry (the cap on 30 % of current reserves rather than 30 % of
total care load) allows parents with low energy to slow provisioning
naturally, without additional guard logic.

Guard: no-op when `specs["parental_care"] == false`.
"""
function feed_offspring!(env::Environment)
    specs = env.specs
    Bool(get(specs, "parental_care", false)) || return

    feeding_rate = Float32(get(specs, "feeding_rate", 5.0))

    @inbounds for ag in env.agents
        ag.alive          || continue
        ag.care_load <= 0 && continue
        for juv in ag.carried_offspring
            feeding    = min(feeding_rate, ag.energy * 0.3f0)
            juv.energy += feeding
            ag.energy  -= feeding
        end
    end
    return
end

"""
    graduate_offspring!(env::Environment)

Promote juveniles that have reached independence into the main agent pool.

Called **after** `remove_dead!(env)` so that agent indices in `env.agent_map`
are stable for this tick.

A juvenile graduates when:

    juv.age >= juvenile_independence_age  OR  juv.energy >= juvenile_independence_energy

For each graduating juvenile, a free adjacent cell is sought by scanning the
8-cell Moore neighbourhood in random shuffled order (toroidal wrap). If a
free cell is found, the juvenile is placed there and appended to `env.agents`
with `env.agent_map` updated; `env.n_graduations` is incremented. If no free
cell is found, the juvenile dies and `env.n_juv_deaths` is incremented.

Juveniles whose parent has died (alive == false) are all killed and counted
in `env.n_juv_deaths`. In practice this case is reached only if
`graduate_offspring!` is called before `remove_dead!` removes the parent; the
guard in the main loop prevents this under normal operation.

Iterate over carried_offspring in reverse so that deletions via `deleteat!`
do not skip entries.

Guard: no-op when `specs["parental_care"] == false`.
"""
function graduate_offspring!(env::Environment)
    specs    = env.specs
    Bool(get(specs, "parental_care", false)) || return

    rows     = Int(specs["grid_rows"])
    cols     = Int(specs["grid_cols"])
    toroidal = Bool(get(specs, "toroidal", true))
    indep_age  = Int32(get(specs, "juvenile_independence_age",    10))
    indep_en   = Float32(get(specs, "juvenile_independence_energy", 50.0))

    dx_offsets = Int[-1, -1, -1,  0,  0,  1,  1,  1]
    dy_offsets = Int[-1,  0,  1, -1,  1, -1,  0,  1]

    agents = env.agents

    for ag in agents
        # Dead parent — obligate altricial: kill the whole brood
        if !ag.alive && ag.care_load > 0
            env.n_juv_deaths += Int32(length(ag.carried_offspring))
            empty!(ag.carried_offspring)
            ag.care_load = Int32(0)
            continue
        end

        ag.alive          || continue
        ag.care_load <= 0 && continue

        # Iterate in reverse so deleteat! indices remain valid
        for k in length(ag.carried_offspring):-1:1
            juv = ag.carried_offspring[k]

            if juv.age >= indep_age || juv.energy >= indep_en
                # Search for a free adjacent cell in shuffled order
                perm     = randperm(env.rng, 8)
                placed   = false
                xi, yi   = Int(ag.x), Int(ag.y)

                for p in perm
                    nx = wrap_or_clamp(xi + dx_offsets[p], rows, toroidal)
                    ny = wrap_or_clamp(yi + dy_offsets[p], cols, toroidal)
                    if env.agent_map[nx, ny] == 0
                        juv.x = Int32(nx)
                        juv.y = Int32(ny)
                        push!(agents, juv)
                        env.agent_map[nx, ny] = length(agents)
                        env.n_graduations += Int32(1)
                        placed = true
                        break
                    end
                end

                if !placed
                    # No free cell — juvenile dies
                    env.n_juv_deaths += Int32(1)
                end

                deleteat!(ag.carried_offspring, k)
                ag.care_load -= Int32(1)
            end
        end
    end
    return
end

"""
    age_juveniles!(env::Environment)

Advance age and apply reduced metabolic costs for all juveniles in brood.

For each live parent, every juvenile in `carried_offspring`:

1. `juv.age += 1`
2. `juv.energy -= live_energy_cost * 0.5` (juveniles pay half the adult rate)
3. If `juv.energy <= 0`, the juvenile dies: it is removed from
   `carried_offspring`, `care_load` is decremented, and `env.n_juv_deaths`
   is incremented.

Iterate in reverse so that deletions via `deleteat!` do not skip entries.

Guard: no-op when `specs["parental_care"] == false`.
"""
function age_juveniles!(env::Environment)
    specs = env.specs
    Bool(get(specs, "parental_care", false)) || return

    juv_cost = Float32(get(specs, "live_energy_cost", 1.0)) * 0.5f0

    @inbounds for ag in env.agents
        ag.alive          || continue
        ag.care_load <= 0 && continue

        for k in length(ag.carried_offspring):-1:1
            juv         = ag.carried_offspring[k]
            juv.age    += Int32(1)
            juv.energy -= juv_cost

            if juv.energy <= 0.0f0
                juv.alive = false
                deleteat!(ag.carried_offspring, k)
                ag.care_load -= Int32(1)
                env.n_juv_deaths += Int32(1)
            end
        end
    end
    return
end

# === CLADE.JL ADDITIONS NEEDED ===
# include: include("modules/parental_care.jl")
# tick loop (order matters — after tick_agents!, before remove_dead!):
#   apply_care_costs!(env)
#   feed_offspring!(env)
#   age_juveniles!(env)
# tick loop (after remove_dead!):
#   graduate_offspring!(env)
# Note: all four functions are no-ops when specs["parental_care"] == false
# === END CLADE.JL ADDITIONS ===
