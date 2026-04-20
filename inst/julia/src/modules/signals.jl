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
    apply_signal_mortality!(env::Environment)

0.6.3 — direct viability penalty on signal magnitude. Implements the
Zahavi (1975) / Grafen (1990) handicap principle as β_Sv < 0 in the
Fuller, Houle & Travis (2005) framework: individuals carrying larger
signals face a proportional per-tick mortality probability.

    p_die ← signal_cost_mortality × Σ |signal_i|

This is a DIRECT viability cost, distinct from the indirect energy
drain of `apply_signal_costs!`. The energy cost can be masked by
drift (if `signal_drift_sd` is large relative to the cost's
energetic magnitude, selection never catches up). A direct mortality
roll cuts through drift and produces the Zahavi signal-honesty
dynamic: only condition-robust agents can survive carrying costly
signals.

Called every tick from the main tick loop when `signal_dims > 0`.
No-op when `signal_cost_mortality = 0.0` (default) — fully
backward-compatible.

See `vignette("paper-fuller-2005")` for the sexual-selection
framework context.
"""
function apply_signal_mortality!(env::Environment)
    Int(get(env.specs, "signal_dims", 0)) > 0 || return

    mort = Float32(get(env.specs, "signal_cost_mortality", 0.0))
    mort == 0.0f0 && return

    rng = env.rng
    @inbounds for ag in env.agents
        ag.alive || continue
        sig_mag = Float64(sum(abs.(ag.signal)))
        p_die = Float64(mort) * sig_mag
        p_die > 0.0 && rand(rng) < p_die && (ag.alive = false)
    end
    nothing
end

"""
    apply_preference_bias!(env::Environment)

0.6.5 — sensory bias sensu Ryan 1990. Each tick, each agent's
`preference` vector is pulled toward a fixed target vector
`preference_bias_target` with per-tick pull strength
`preference_bias_strength`:

    preference[i] ← (1 - κ) × preference[i] + κ × target[i]

Models a pre-existing receiver bias — a preference shaped by
non-mating selection (e.g. foraging cue detection, predator
avoidance) that exists *before* any signal evolves to exploit
it. Under preference-based mate choice (the 0.6.4 wiring),
signals should drift toward the target direction because
agents whose signals happen to point that way get
preferentially chosen as mates. This is the β_N leg of the
Fuller, Houle & Travis (2005) framework — selection on
preferences that spills over into signal evolution.

No-op when `signal_dims == 0`, `preference_bias_strength == 0`
(default), or `preference_bias_target` is empty / missing.

Components are clamped to [-1, 1] after each pull.

References
----------
Ryan, M. J. (1990). Sexual selection, sensory systems and
    sensory exploitation. *Oxford Surveys in Evolutionary
    Biology* 7:157-195.
Endler, J. A. & Basolo, A. L. (1998). Sensory ecology,
    receiver biases and sexual selection. *TREE* 13:415-420.
Fuller, R. C., Houle, D. & Travis, J. (2005). Sensory bias as
    an explanation for the evolution of mate preferences.
    *Am Nat* 166:437-446.
"""
function apply_preference_bias!(env::Environment)
    Int(get(env.specs, "signal_dims", 0)) > 0 || return

    kappa = Float32(get(env.specs, "preference_bias_strength", 0.0))
    kappa > 0.0f0 || return

    raw = get(env.specs, "preference_bias_target", nothing)
    raw === nothing && return
    target = Float32[Float32(x) for x in raw]
    isempty(target) && return

    @inbounds for ag in env.agents
        ag.alive || continue
        n = min(length(ag.preference), length(target))
        for i in 1:n
            ag.preference[i] = (1.0f0 - kappa) * ag.preference[i] +
                                kappa * target[i]
            ag.preference[i] = clamp(ag.preference[i], -1.0f0, 1.0f0)
        end
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

"""
    apply_signal_toxicity_pleiotropy!(env::Environment)

0.4.4: soft pleiotropic coupling between signal[1] and toxicity. When
`signal_toxicity_coupling > 0`, each agent's `signal[1]` is pulled each
tick toward its own `toxicity` value, blending the heritable signal with
a toxicity-derived value:

    signal[1] ← (1 - coupling) × signal[1] + coupling × toxicity

At `coupling = 0` (default): signal evolves fully independently (legacy
0.3.x / 0.4.x behaviour). At `coupling = 1`: signal[1] is locked to
toxicity — aposematic honest signalling. Intermediate values give a
partial honest-signal regime.

This is the clean mechanism aposematic theory invokes (Endler 1988;
Ruxton, Sherratt & Speed 2004): toxic prey *must* advertise their
toxicity for predator learning to select for it. Without coupling,
signal and toxicity are independent traits in clade and aposematic
dynamics cannot close the feedback loop. Opt-in, so no existing
scenario's behaviour changes.

Is a no-op when `signal_dims == 0` or `mimicry == false`.
"""
function apply_signal_toxicity_pleiotropy!(env::Environment)
    Int(get(env.specs, "signal_dims", 0)) > 0 || return
    Bool(get(env.specs, "mimicry", false))    || return
    coupling = Float32(get(env.specs, "signal_toxicity_coupling", 0.0))
    coupling > 0.0f0 || return

    @inbounds for ag in env.agents
        ag.alive || continue
        if !isempty(ag.signal)
            ag.signal[1] = (1.0f0 - coupling) * ag.signal[1] +
                            coupling * ag.toxicity
            ag.signal[1] = clamp(ag.signal[1], -1.0f0, 1.0f0)
        end
    end
    nothing
end
