"""
    signals.jl — Heritable signal vectors and mate-choice preference.

Enabled when `specs["signal_dims"] > 0`.

Agents carry two heritable vectors of equal length (`signal_dims`):

- `signal::Vector{Float32}` — phenotypic signal broadcast to potential mates
  and to the sensory input of nearby agents. Sexual selection acts on this
  vector.
- `preference::Vector{Float32}` — the weight template used when evaluating
  potential mates. The mate-choice dot product `dot(preference, candidate.signal)`
  is computed in reproduce.jl (already implemented); this module handles only
  the within-tick costs and optional per-tick drift.

Signals incur a metabolic cost proportional to their absolute magnitude
(Zahavi's handicap principle): costly, hard-to-fake signals can function as
reliable indicators of genetic quality only when they impose a genuine
energetic burden. The default `signal_cost = 0.1` means each unit of
|signal_i| costs 0.1 energy per tick — cheap enough not to drive extinction,
large enough to create selection pressure for signal reduction in the absence
of mate-choice benefits.

Optional per-tick drift (`signal_evolution_drift = true`) adds independent
Gaussian noise to each signal and preference component each tick. This models
within-lifetime phenotypic fluctuation, genetic drift in small populations,
and the mutation pressure that generates novel signal variants for runaway
selection to act on. Components are clamped to [-1, 1] to prevent unbounded
growth.

**Note:** dilution-of-risk (group protection) is handled by group_defense.jl.
This module is exclusively concerned with sexual selection: costly signalling
and preference evolution.

References
----------
Zahavi, A. (1975) Mate selection — a selection for a handicap. Journal of
    Theoretical Biology 53(1):205–214.
Lande, R. (1981) Models of speciation by sexual selection on polygenic traits.
    Proceedings of the National Academy of Sciences 78(6):3721–3725.
Fisher, R.A. (1930) The Genetical Theory of Natural Selection. Clarendon Press.
"""

"""
    apply_signal_costs!(env::Environment)

Deduct per-tick metabolic costs for all live agents that carry signals.
The cost is proportional to the sum of absolute signal component magnitudes:

    energy -= signal_cost × Σ |signal_i|

This implements the handicap principle: large or conspicuous signals impose
real energetic penalties. The `preference` vector carries no cost (it
encodes internal evaluation weights, not externally expressed traits).

Called every tick from the main tick loop when `signal_dims > 0`. Is a
no-op when `signal_dims == 0`.
"""
function apply_signal_costs!(env::Environment)
    Int(get(env.specs, "signal_dims", 0)) > 0 || return

    cost = Float32(get(env.specs, "signal_cost", 0.1))
    cost == 0.0f0 && return

    @inbounds for ag in env.agents
        ag.alive || continue
        ag.energy -= cost * sum(abs.(ag.signal))
    end
    nothing
end

"""
    apply_signal_evolution!(env::Environment)

Apply within-tick Gaussian drift to signal and preference vectors for all
live agents. Enabled only when `specs["signal_evolution_drift"] == true`.

For each live agent, each component of both `signal` and `preference` receives
independent additive noise drawn from N(0, signal_drift_sd). Components are
clamped to [-1, 1] after perturbation to prevent unbounded growth.

The drift models:
- Ongoing mutation pressure on the signal locus each generation.
- Short-term phenotypic fluctuation in expressed signal intensity.
- The raw variation supply on which runaway selection acts (Lande 1981).

All randomness goes through `env.rng` to ensure seeded runs are reproducible.
"""
function apply_signal_evolution!(env::Environment)
    Bool(get(env.specs, "signal_evolution_drift", false)) || return

    drift_sd = Float32(get(env.specs, "signal_drift_sd", 0.01))
    drift_sd == 0.0f0 && return

    rng = env.rng

    @inbounds for ag in env.agents
        ag.alive || continue

        # Drift each signal component
        for i in eachindex(ag.signal)
            ag.signal[i] = clamp(ag.signal[i] + drift_sd * Float32(randn(rng)),
                                 -1.0f0, 1.0f0)
        end

        # Drift each preference component
        for i in eachindex(ag.preference)
            ag.preference[i] = clamp(ag.preference[i] + drift_sd * Float32(randn(rng)),
                                     -1.0f0, 1.0f0)
        end
    end
    nothing
end
