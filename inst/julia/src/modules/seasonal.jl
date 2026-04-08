"""
    seasonal.jl — Seasonal dynamics: grass modulation and winter mortality.

Seasonal dynamics add a sinusoidal cycle to the environment. Two mechanisms
are implemented here:

1. **Grass growth modulation** (already wired into `grow_grass!()` in
   Clade.jl): the per-tick grass regrowth probability is multiplied by
   `1 + seasonal_amplitude * sin(2π t / season_length)`. Values > 1 during
   summer, < 1 during winter. Controlled by `seasonal_amplitude` (default 0).

2. **Winter mortality** (`apply_seasonal_mortality!`): during winter
   (sin < 0), each agent independently dies with probability
   `winter_death_prob`. This models cold-temperature, food-stress, or
   other season-specific mortality beyond the energy cost channel. Default
   is 0 (disabled).

Winter is the phase where `sin(2π t / season_length) < 0`, i.e., the second
half of each cycle. Summer is the first half.

## Parameters

| Spec field              | Default | Meaning                                           |
|-------------------------|---------|---------------------------------------------------|
| `seasonal_amplitude`    | 0.0     | Amplitude of sinusoidal grass modulation (0–1).   |
| `season_length`         | 100L    | Period of the seasonal cycle in ticks.            |
| `winter_death_prob`     | 0.0     | Per-tick mortality probability during winter.     |

## References

Feder, M.E. & Burggren, W.W. (1992) *Environmental Physiology of the
Amphibians.* University of Chicago Press. (seasonal mortality in ectotherms)

McNab, B.K. (2002) *The Physiological Ecology of Vertebrates.* Cornell
University Press. (energy balance and seasonal mortality).
"""

"""
    apply_seasonal_mortality!(env::Environment)

Kill agents stochastically during the winter phase of the seasonal cycle.
Winter is defined as any tick where `sin(2π t / season_length) < 0`.

When `winter_death_prob == 0` or `seasonal_amplitude == 0`, returns
immediately (no overhead).
"""
function apply_seasonal_mortality!(env::Environment)
    wdp = Float64(get(env.specs, "winter_death_prob", 0.0))
    wdp > 0.0 || return

    season_len = Float64(get(env.specs, "season_length", 100))
    t          = Float64(env.t)

    # Only active in winter (second half of sinusoidal cycle)
    sin(2π * t / season_len) >= 0.0 && return

    for ag in env.agents
        ag.alive || continue
        if rand(env.rng) < wdp
            ag.alive = false
            env.n_deaths += Int32(1)
        end
    end
end
