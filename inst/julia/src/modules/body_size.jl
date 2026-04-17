"""
    body_size.jl — Heritable body size evolution with metabolic scaling.

Enabled when `specs["body_size_evolution"] == true`.

## Biological model

Each agent carries a heritable continuous `body_size` trait (positive scalar).
`body_size = 1.0` is the reference — identical to the default fixed-size
behaviour. The trait is expressed once at birth from the diploid genome and
is immutable within a lifetime.

Three effects scale with body_size:

1. **Metabolic surcharge** (post-tick): The core tick loop charges every agent
   the same base metabolic cost. Agents with body_size ≠ 1 receive a
   correction after the tick: energy -= live_energy_cost * (body_size - 1).
   Larger agents pay more; smaller agents get a metabolic refund.

2. **Foraging bonus/penalty**: The core tick credits every agent the same
   eat_gain × grass. Large agents (body_size > 1) take an extra bite
   proportional to (body_size - 1), capped by available grass. Small agents
   return the over-credited energy.

3. **Energy capacity**: Agent energy is capped at `energy_max * body_size`
   after the correction (larger = more storage).

Kleiber's law (Kleiber 1947) predicts metabolic cost ∝ mass^0.75. We use a
linear approximation for computational efficiency, consistent with alifeR's
implementation.

## Inheritance

`body_size` is expressed via `express_trait(genome, TRAIT_BODY_SIZE, ...)`,
which already incorporates dominance, mutation, and ploidy logic from genome.jl.
The `body_size_min` / `body_size_max` bounds are applied during trait expression.
No additional inheritance function is required here.

## References

Kleiber, M. (1947) Body size and metabolic rate. *Physiological Reviews*
  27(4):511–541.
Peters, R.H. (1983) *The Ecological Implications of Body Size.* Cambridge
  University Press.
"""

"""
    apply_body_size!(env::Environment)

Apply body-size metabolic correction and foraging adjustment for all live
agents. Called once per tick immediately after `tick_agents!` (before other
module hooks). Is a no-op when `specs["body_size_evolution"] == false`.
"""
function apply_body_size!(env::Environment)
    Bool(get(env.specs, "body_size_evolution", false)) || return

    specs      = env.specs
    live_cost  = Float32(get(specs, "idle_cost",    0.5))   # proxy for live energy cost
    energy_max = Float32(get(specs, "energy_max", 200.0))

    @inbounds for ag in env.agents
        ag.alive || continue
        bs = ag.body_size
        bs == 1.0f0 && continue   # reference size: no correction needed

        # 1. Metabolic surcharge: larger agents pay more, smaller pay less
        ag.energy -= live_cost * (bs - 1.0f0)

        # 2. Foraging is now scaled at the source in tick.jl
        #    (ag.energy += eat_gain * bite * body_size), so no post-hoc
        #    correction is needed. The old "correction" branch could
        #    subtract more energy than was actually credited when grass
        #    on the cell was low, creating a bs < 1 death spiral —
        #    diagnosed in dev/audit/fidelity/body_size_crash_diagnosis.R
        #    and documented in CRASH_AUDIT_FINDINGS.md (2026-04-17).

        # 3. Per-agent energy cap
        ag.energy = min(ag.energy, energy_max * bs)
    end
    nothing
end
