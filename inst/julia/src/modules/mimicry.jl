"""
    mimicry.jl — Müllerian/Batesian mimicry and toxicity coevolution.

Enabled when `specs["mimicry"] == true`. Requires predators to be active
(`n_predators_init > 0`).

Each agent carries a heritable `toxicity` trait in [0, 1]. Toxic prey impose
energetic damage on predators that attack them and drive predator aversion
learning via a Rescorla-Wagner associative model (Rescorla & Wagner 1972).
Predators store their toxin-signal association as a running scalar in
`value_estimate` (repurposed when mimicry is active), which accumulates across
successful attacks and decays toward zero between encounters.

The two coevolutionary forces this creates are:

1. **Toxicity is costly** (`apply_toxicity_costs!`): producing toxins imposes
   a per-tick metabolic drain proportional to the agent's toxicity level. This
   creates a cost–benefit trade-off between protection and energy expenditure.

2. **Predator learning** (`apply_predator_toxin!`): attacking a toxic agent
   poisons the predator and strengthens its aversion memory, eventually
   suppressing attacks on similar prey — or, if signal mimics are present, on
   non-toxic agents whose signals resemble toxic ones (Batesian mimicry).

The `should_avoid_prey` query encapsulates the predator's avoidance decision
for external callers (e.g., tick_predators.jl). Counter bookkeeping is left
to the caller so that both `env.n_toxic_attacks` and `env.n_avoided_attacks`
are incremented in the same code path that drives the attack loop.

References
----------
Müller, F. (1879) Ituna and Thyridia: a remarkable case of mimicry in
    butterflies. Proceedings of the Entomological Society of London 1879:
    xxvii–xxix.
Endler, J.A. (1988) Frequency-dependent predation, crypsis and aposematic
    coloration. Philosophical Transactions of the Royal Society of London B
    319(1196):505–523.
Rescorla, R.A. & Wagner, A.R. (1972) A theory of Pavlovian conditioning:
    variations in the effectiveness of reinforcement and non-reinforcement.
    In A.H. Black & W.F. Prokasy (eds.), Classical Conditioning II.
    Appleton-Century-Crofts. pp. 64–99.
"""

"""
    apply_toxicity_costs!(env::Environment)

Deduct per-tick metabolic costs for toxin production from all live agents.

Each live agent pays:

    energy -= toxicity_cost_per_tick × ag.toxicity

Agents with `toxicity == 0` incur no cost. The cost implements the evolutionary
trade-off that drives honest aposematic signalling: only agents whose genetic
fitness benefits from toxin-mediated predator deterrence can afford to
maintain high toxicity (Endler 1988).

Called every tick from the main loop. Is a no-op when `mimicry == false`.
"""
function apply_toxicity_costs!(env::Environment)
    Bool(get(env.specs, "mimicry", false)) || return

    cost = Float32(get(env.specs, "toxicity_cost_per_tick", 0.5))
    cost == 0.0f0 && return

    @inbounds for ag in env.agents
        ag.alive || continue
        ag.energy -= cost * ag.toxicity
    end
    nothing
end

"""
    apply_predator_toxin!(pred::Agent, prey::Agent, env::Environment)

Apply toxin damage to a predator that has attacked a toxic prey agent, and
update the predator's aversion memory via Rescorla-Wagner learning.

Called from the predator attack path in tick_predators.jl immediately after
a successful attack is resolved (i.e., after the predator has already landed
the attack but before energy transfers are finalised). The function:

1. Inflicts toxin damage:

       pred.energy -= toxin_dose × prey.toxicity

2. Updates the predator's scalar signal memory (`pred.value_estimate`, which is
   repurposed as a toxin-association accumulator when `mimicry == true`):

       memory ← (1 − lr) × memory + lr × prey.toxicity

   where `lr = signal_memory_rate`. High prey toxicity drives memory toward 1;
   low toxicity allows it to decay back toward 0 over repeated encounters with
   palatable prey.

Note: multi-dimensional signal memory would require a dedicated field. The
scalar `value_estimate` is used for computational efficiency and to avoid
struct changes, consistent with alifeR's approach.

Is a no-op when `mimicry == false`.
"""
function apply_predator_toxin!(pred::Agent, prey::Agent, env::Environment)
    Bool(get(env.specs, "mimicry", false)) || return

    toxin_damage = Float32(get(env.specs, "toxin_dose", 30.0)) * prey.toxicity
    pred.energy -= toxin_damage

    lr = Float64(get(env.specs, "signal_memory_rate", 0.3))
    pred.value_estimate = Float32(
        (1.0 - lr) * Float64(pred.value_estimate) + lr * Float64(prey.toxicity)
    )
    nothing
end

"""
    should_avoid_prey(pred::Agent, prey::Agent, env::Environment) -> Bool

Return `true` if the predator's learned aversion memory is strong enough to
suppress an attack on this prey agent.

Avoidance occurs when both conditions hold:

- `pred.value_estimate >= avoid_threshold`  (predator has strong aversion memory)
- `prey.toxicity > 0`                        (prey is actually toxic, or mimics
                                              a toxic signal; the predator cannot
                                              distinguish true toxics from mimics)

Returns `false` unconditionally when `mimicry == false` (avoidance is not
modelled in that regime).

**Counter bookkeeping is the caller's responsibility.** The caller should:

- Increment `env.n_avoided_attacks` when this function returns `true`.
- Increment `env.n_toxic_attacks` when this function returns `false` and
  `prey.toxicity > 0` (i.e., the predator attacked a toxic agent anyway).

This separation keeps the query pure and the counter semantics explicit in
the predator tick loop.
"""
function should_avoid_prey(pred::Agent, prey::Agent, env::Environment)::Bool
    Bool(get(env.specs, "mimicry", false)) || return false

    avoid_threshold = Float64(get(env.specs, "avoid_threshold", 0.5))
    learned = pred.value_estimate >= Float32(avoid_threshold)

    # Mullerian (default): avoidance fires only for actually-toxic prey.
    # Batesian: avoidance fires for ANY prey whose signal has been learned,
    # regardless of the prey's own toxicity. This lets palatable mimics
    # exploit the predator's aversion memory built up against toxic
    # model species sharing the same signal (Bates 1862). See
    # apply_predator_toxin! for the "predator betrayal" decay that
    # prevents runaway cheating.
    if Bool(get(env.specs, "batesian_mimicry", false))
        learned
    else
        learned && prey.toxicity > 0.0f0
    end
end

# === CLADE.JL ADDITIONS NEEDED ===
# include: include("modules/mimicry.jl")
# tick loop: apply_toxicity_costs!(env)
#   [location: after apply_signal_costs!, before apply_kin_altruism!;
#    gated internally by mimicry == true]
# predator attack path (tick_predators.jl):
#   if should_avoid_prey(pred, prey, env)
#       env.n_avoided_attacks += Int32(1)
#       continue  # skip attack
#   end
#   # ... resolve attack ...
#   if Bool(get(env.specs, "mimicry", false)) && prey.toxicity > 0.0f0
#       env.n_toxic_attacks += Int32(1)
#       apply_predator_toxin!(pred, prey, env)
#   end
# Note: apply_toxicity_costs! is a no-op when mimicry == false
# === END CLADE.JL ADDITIONS ===
