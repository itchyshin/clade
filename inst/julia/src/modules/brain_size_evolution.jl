"""
    brain_size_evolution.jl — Heritable brain size with metabolic cost and
    cognitive foraging benefit.

Enabled when `specs["brain_size_evolution"] == true`.

## Biological model

Based on the parental provisioning hypothesis (van Schaik et al. 2023 *PLoS
Biology*; Griesser et al. 2023 *PNAS*; Song et al. 2025 *PNAS*):

> Large-brained offspring face a "bootstrapping problem": neural tissue is
> energetically expensive from birth (expensive brain hypothesis), but the
> cognitive benefits of a larger brain only materialise once the animal can
> forage effectively. This creates a developmental energy gap that parental
> provisioning bridges.

Each agent carries a heritable continuous `brain_size` trait (positive scalar,
default 1.0). Three effects scale with `brain_size`:

1. **Expensive brain (metabolic cost)**: idle cost increases proportionally.
   `energy -= idle_cost * brain_size_cost_scale * (brain_size - 1.0)`.
   Larger-brained agents burn more energy per tick even when stationary. This
   applies from the first tick of life — including infancy — creating the
   bootstrapping energy deficit described in the parental provisioning
   hypothesis.

2. **Cognitive foraging advantage**: agents with larger brains are better
   foragers. They extract more energy from the grass on their current cell,
   proportional to `brain_size - 1.0`. This benefit requires effective
   foraging — which in turn requires either having survived infancy (via
   parental provisioning) or having been lucky as a small-brained infant.

3. **Sensing quality**: grass inputs to the agent's neural network are scaled
   by `brain_size ^ brain_size_sensing_exponent`. Larger-brained agents
   perceive resource gradients more clearly, enabling better navigation toward
   food. With exponent 0.3 and brain_size 1.5 the multiplier is ≈ 1.13 —
   a gentle amplification that compounds with the foraging bonus. This
   complements effect 2 (which acts on the agent's current cell) by providing
   a directional navigation advantage across the grid.

## Bootstrapping problem

With `parental_care = FALSE`: large-brained newborns immediately pay the
metabolic surcharge but forage randomly (ANN weights are random at birth).
They starve before the cognitive advantage can offset the cost → selection
against large brains.

With `parental_care = TRUE`: parents supply `feeding_rate` energy per tick
during `care_duration` ticks. This energy buffer allows large-brained infants
to survive long enough for the population to evolve effective foraging
strategies → selection can favour larger brains.

## Key parameters

- `brain_size_evolution::Bool` — enable/disable (default FALSE)
- `brain_size_init_mean::Float64` — initial population mean (default 1.0)
- `brain_size_mutation_sd::Float64` — per-generation mutation SD (default 0.05)
- `brain_size_min::Float64` — minimum allowed brain_size (default 0.1)
- `brain_size_max::Float64` — maximum allowed brain_size (default 3.0)
- `brain_size_cost_scale::Float64` — multiplier on idle_cost surcharge
  (default 1.0; increase to steepen the cost curve)
- `brain_size_sensing_exponent::Float64` — power applied to brain_size when
  scaling grass sensing inputs in `sense.jl` (default 0.3; 0 = no sensing
  effect; 1.0 = linear scaling)

## References

van Schaik, C.P. et al. (2023) The "expensive brain" framework and the
  evolution of large brains. *PLoS Biology* 21(5): e3002064.
Griesser, M. et al. (2023) Parental provisioning drives brain size evolution.
  *PNAS* 120(31): e2301005120.
Song, Z. et al. (2025) Brain size evolution and parental investment.
  *PNAS* 122(8): e2412783122.
"""

"""
    apply_brain_size_evolution!(env::Environment)

Apply brain-size metabolic surcharge and cognitive foraging correction for all
live agents. Called once per tick immediately after `apply_body_size!`. Is a
no-op when `specs["brain_size_evolution"] == false`.
"""
function apply_brain_size_evolution!(env::Environment)
    Bool(get(env.specs, "brain_size_evolution", false)) || return

    specs      = env.specs
    idle_cost  = Float32(get(specs, "idle_cost",             0.5))
    eat_gain   = Float32(get(specs, "eat_gain",              5.0))
    cost_scale = Float32(get(specs, "brain_size_cost_scale", 1.0))

    @inbounds for ag in env.agents
        ag.alive || continue
        bs = ag.brain_size
        bs == 1.0f0 && continue   # reference size: no correction

        # 1. Expensive brain: extra idle cost proportional to (brain_size - 1)
        ag.energy -= idle_cost * cost_scale * (bs - 1.0f0)

        # 2. Cognitive foraging bonus: larger-brained agents extract more energy
        x, y  = Int(ag.x), Int(ag.y)
        delta = eat_gain * (bs - 1.0f0)

        if delta > 0.0f0
            # Large brain: take extra grass from current cell
            avail = env.grass[x, y]
            extra = min(delta, avail)
            ag.energy        += extra
            env.grass[x, y]  -= extra
        else
            # Small brain: return over-credited energy (capped at 40% to avoid
            # over-correction when cell was partially empty)
            correction = min(-delta, max(0.0f0, ag.energy * 0.4f0))
            ag.energy -= correction
        end
    end
    nothing
end
