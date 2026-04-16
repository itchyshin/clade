"""
    death.jl — Mortality: starvation, age, Gompertz senescence.

All mortality causes are applied in `kill_dead!()`, called after the tick
loop. Agents with `alive = false` are removed from `env.agents` in
`remove_dead!()`.

## Mortality causes (applied in order)

1. **Starvation**: energy < starvation_threshold → die.
2. **Age cap**: age >= max_age → die (if max_age is finite).
3. **Gompertz senescence**: per-tick death probability
   p = 1 - exp(-senescence_rate * aging_rate * exp(senescence_rate * age)).
   When senescence_rate = 0, this term is zero. Implements the Gompertz-
   Makeham mortality law (Gompertz 1825).
4. **Semelparous**: agent dies if reproduced == true.

References
----------
Gompertz, B. (1825) On the nature of the function expressive of the law of
    human mortality. Philosophical Transactions of the Royal Society 115:513–583.
Stearns, S.C. (1992) The Evolution of Life Histories. Oxford University Press.
Hamilton, W.D. (1966) The moulding of senescence by natural selection.
    Journal of Theoretical Biology 12(1):12–45.
"""

"""
    kill_dead!(env::Environment)

Mark agents that have died this tick as `alive = false`. Updates death
counters and the deaths log.
"""
function kill_dead!(env::Environment)
    specs     = env.specs
    starv_th  = Float32(get(specs, "starvation_threshold", 0.0))
    max_age   = Int(get(specs, "max_age", 200))
    senes_r   = Float32(get(specs, "senescence_rate", 0.0))
    semel     = get(specs, "life_history", "iteroparous") == "semelparous"
    scav_on   = Bool(get(specs, "scavenging", false))
    # 0.4.0 Tier 2: max_age scales inversely with metabolic_rate when
    # `max_age_scales_with_metabolism = TRUE`. Fast-pace agents (high
    # metabolic_rate) get shorter lifespans; slow-pace agents longer.
    # Implements Réale et al. 2010 pace-of-life syndrome at the
    # demographic level: effective max_age = base_max_age / metabolic_rate.
    # Off by default to preserve pre-0.4.0 behaviour.
    age_scales = Bool(get(specs, "max_age_scales_with_metabolism", false))

    for ag in env.agents
        ag.alive || continue
        eff_max_age = age_scales ?
            max(1, round(Int, max_age / max(ag.metabolic_rate, 0.01f0))) :
            max_age
        cause = _death_cause(ag, starv_th, eff_max_age, senes_r, semel, env.rng)
        if cause != :alive
            ag.alive = false
            env.n_deaths += Int32(1)
            cause == :starvation && (env.n_starvations += Int32(1))
            cause == :age        && (env.n_age_deaths  += Int32(1))
            _log_death!(env, ag, cause)
            # Deposit carrion at the dying agent's cell. The helper is
            # a no-op when scavenging is off, but we gate on the spec flag
            # here to avoid function-call overhead in the common case.
            scav_on && deposit_carrion!(env, ag)
        end
    end
end

"""
    _death_cause(ag, starv_th, max_age, senes_r, semel, rng) -> Symbol

Return the cause of death, or `:alive` if the agent survives this tick.
Causes: `:starvation`, `:age`, `:senescence`, `:semelparous`.
"""
function _death_cause(ag::Agent, starv_th::Float32, max_age::Int,
                       senes_r::Float32, semel::Bool, rng)::Symbol
    # 1. Starvation
    ag.energy < starv_th && return :starvation

    # 2. Age cap — only when Gompertz senescence is off (0.4.2). Otherwise
    # the hard cap masks the stochastic senescence curve and no scenario
    # can demonstrate age-dependent mortality cleanly. When senescence is
    # on, Gompertz governs late-life mortality; agents die from the tail
    # well before runaway ages.
    if senes_r <= 0.0f0
        ag.age >= max_age && return :age
    end

    # 3. Gompertz senescence
    if senes_r > 0.0f0
        # Scaled by heritable aging_rate: faster-aging genotypes die sooner
        eff_r = senes_r * ag.aging_rate
        p_die = Float32(1.0 - exp(-Float64(eff_r) * exp(Float64(eff_r) * Float64(ag.age))))
        rand(rng) < p_die && return :senescence
    end

    # 4. Semelparous
    semel && ag.reproduced && return :semelparous

    :alive
end

"""
    remove_dead!(env::Environment)

Remove dead agents from `env.agents` and rebuild `env.agent_map`.
"""
function remove_dead!(env::Environment)
    filter!(ag -> ag.alive, env.agents)
    fill!(env.agent_map, Int64(0))
    for (idx, ag) in enumerate(env.agents)
        env.agent_map[ag.x, ag.y] = idx
    end
end

"""
    _log_death!(env, ag, cause)

Append one record to `env.deaths`.
"""
function _log_death!(env::Environment, ag::Agent, cause::Symbol)
    push!(env.deaths["id"],        Int(ag.id))
    push!(env.deaths["t"],         Int(env.t))
    push!(env.deaths["age"],       Int(ag.age))
    push!(env.deaths["energy"],    Float64(ag.energy))
    push!(env.deaths["cause"],     string(cause))
    push!(env.deaths["body_size"], Float64(ag.body_size))
    push!(env.deaths["num_offspring"], Int(ag.num_offspring))
end
