"""
    tick.jl — Per-tick agent update: sense → decide → move → eat → age.

This is the hot path. Called for every agent every tick. Designed to be
allocation-free for ANN and BNN brains after the initial sensory vector
is built.

## Action encoding

Action  Index  Effect
------  -----  ------
N       1      x -= 1 (toroidal wrap)
E       2      y += 1
S       3      x += 1
W       4      y -= 1
idle    5      stay in place

## Energy update

energy -= move_cost * metabolic_rate   (if moved)
       or idle_cost * metabolic_rate   (if idle)
energy -= brain_energy_cost(brain, logits)
bite    = min(grass[x, y], max_bite)   (handling-time-limited intake)
energy += eat_gain * bite              (grass[x, y] -= bite)

Grass at the agent's new cell is consumed regardless of action (even idle),
consistent with alifeR's "eat where you stand" rule.

## Handling time (0.4.0 kernel change)

Prior to 0.4.0, `eat_gain * grass[x, y]` was added in one tick and the cell
was zeroed — agents stripped a cell entirely in a single step. Real animals
have *handling time*: a cow doesn't eat a square metre of grass in one bite.
Both the MATLAB ancestor (Bulitko 2023) and the alifeR R port enforce a
per-tick `maxbite` cap. The 0.4.0 kernel restores this: each tick an agent
can extract at most `max_bite` units of grass from its current cell.

Biological consequences:
1. A grass-rich cell can sustain multiple grazing visits (or multiple
   simultaneous grazers) instead of being depleted by the first agent.
2. Per-tick energy intake is bounded — agents cannot accumulate huge
   energy windfalls from finding one rich cell, which previously distorted
   reproduction timing and selection differentials.
3. The per-tick gain:cost ratio drops from ~25:1 (max meal vs metabolic
   cost) to ~5:1, much closer to vertebrate energetics.

See `dev/docs/kernel-0.4.0.md` for the full audit trail and citations.
"""

"""
    tick_agents!(env::Environment)

Apply one tick to all live agents. Modifies agents and env.grass in place.
Updates env.agent_map after all moves.
"""
function tick_agents!(env::Environment)
    specs    = env.specs
    rows     = Int(specs["grid_rows"])
    cols     = Int(specs["grid_cols"])
    toroidal = Bool(get(specs, "toroidal", true))

    move_cost  = Float32(get(specs, "move_cost",  1.0))
    idle_cost  = Float32(get(specs, "idle_cost",  0.5))
    eat_gain   = Float32(get(specs, "eat_gain",   5.0))
    max_bite   = Float32(get(specs, "max_bite",   2.0))   # 0.4.0: handling time
    # 0.4.3: neonatal foraging deficit. Newborn agents can't forage at adult
    # efficiency — they're still motor-learning. During the first
    # `neonatal_deficit_duration` ticks of life, their effective max_bite is
    # scaled by `(1 - neonatal_foraging_deficit)`. Parental care (feeding_rate)
    # naturally compensates: provisioned newborns eat from the parent instead.
    # Default 0 preserves legacy behaviour.
    neo_deficit = Float32(get(specs, "neonatal_foraging_deficit", 0.0))
    neo_window  = Int32(get(specs, "neonatal_deficit_duration", 10))
    # 0.4.0 Tier 5B: BNN sample cadence — cache weight sample for N forward
    # calls instead of resampling every tick. Freq = 1 is legacy default.
    _bnn_set_freq(Int(get(specs, "bnn_sample_freq", 1)))
    e_mode     = get(specs, "brain_energy_mode", "activity")
    e_base     = Float32(get(specs, "brain_energy_base",     0.001))
    e_act      = Float32(get(specs, "brain_energy_activity", 0.5))
    e_size_exp = Float32(get(specs, "brain_energy_size_exponent", 1.0))
    # 0.4.1 Tier 5C: energetic cost of behavioural uncertainty (BNN sigma).
    # Default 0 preserves legacy behaviour. A positive value penalises
    # maintaining wide posterior weight distributions, which is the
    # information-theoretic cost Aiello & Wheeler (1995) identify for
    # flexible brains. Log-scaled relative to `bnn_sigma_min` so that
    # exploitation (sigma == sigma_min) is free and every doubling of
    # uncertainty above the floor costs the same increment.
    e_sigma    = Float32(get(specs, "brain_energy_sigma_scale", 0.0))
    sigma_min  = Float32(get(specs, "bnn_sigma_min",            0.01))

    # Clear agent map before moves (rebuild below)
    fill!(env.agent_map, Int64(0))

    for ag in env.agents
        ag.alive || continue
        ag.age += Int32(1)

        # ── Sense ─────────────────────────────────────────────────────────
        inp = sense_agent(ag, env)

        # ── Decide ────────────────────────────────────────────────────────
        logits = forward(ag.brain, inp)
        action = argmax(logits)           # greedy; BNN exploration via sigma
        ag.num_choices        += Int32(1)
        ag.num_greedy_choices += Int32(1)

        # ── Move ──────────────────────────────────────────────────────────
        ag.energy_last_tick = ag.energy
        x, y = Int(ag.x), Int(ag.y)
        if action == 1      # N
            x = wrap_or_clamp(x - 1, rows, toroidal)
            ag.energy -= move_cost * ag.metabolic_rate
        elseif action == 2  # E
            y = wrap_or_clamp(y + 1, cols, toroidal)
            ag.energy -= move_cost * ag.metabolic_rate
        elseif action == 3  # S
            x = wrap_or_clamp(x + 1, rows, toroidal)
            ag.energy -= move_cost * ag.metabolic_rate
        elseif action == 4  # W
            y = wrap_or_clamp(y - 1, cols, toroidal)
            ag.energy -= move_cost * ag.metabolic_rate
        else                # idle
            ag.energy -= idle_cost * ag.metabolic_rate
        end
        ag.x = Int32(x)
        ag.y = Int32(y)

        # ── Eat ───────────────────────────────────────────────────────────
        # 0.4.0: handling-time-limited intake. An agent extracts at most
        # `max_bite` units of grass from the cell per tick. Multiple ticks
        # (or multiple agents on consecutive ticks) are needed to deplete
        # a rich cell. Restores alifeR / MATLAB-Bulitko `maxbite` semantics.
        if env.grass[x, y] > 0.0f0
            # 0.4.3: neonatal foraging deficit — young agents forage less
            # efficiently for the first `neo_window` ticks of life. Parental
            # care separately feeds provisioned offspring via feeding_rate,
            # so only unprovisioned newborns suffer the full deficit.
            eff_max_bite = if neo_deficit > 0.0f0 && ag.age <= neo_window
                max_bite * (1.0f0 - neo_deficit)
            else
                max_bite
            end
            bite             = min(env.grass[x, y], eff_max_bite)
            ag.energy       += eat_gain * bite
            env.grass[x, y] -= bite
        end
        eat_layered!(ag, env)   # complex landscape: shrub/canopy supplements
        ag.energy = min(ag.energy, Float32(get(specs, "energy_max", 200.0)))

        # ── Brain energy cost ─────────────────────────────────────────────
        ag.energy -= _brain_energy_cost(ag.brain, logits,
                                          e_mode, e_base, e_act,
                                          e_sigma, sigma_min, e_size_exp)
    end

    # Rebuild agent map after all moves
    for (idx, ag) in enumerate(env.agents)
        ag.alive && (env.agent_map[ag.x, ag.y] = idx)
    end
end

"""
    _brain_energy_cost(brain, logits, mode, base, act_scale,
                        sigma_scale = 0, sigma_min = 0.01, size_exp = 1.0) -> Float32

Compute the metabolic cost of neural computation.

Modes:
- `"none"`            : 0.
- `"size"`            : `base * brain_size(brain)`.
- `"activity"`        : `base * brain_size(brain) + act_scale *
                          mean(abs.(logits))`.
- `"prediction_error"`: BNN only; placeholder (returns size cost).

**0.4.1 Tier 5C — behavioural-uncertainty cost.** When `sigma_scale > 0`
and `brain` is a `BNNBrain`, an additional cost is added:

    sigma_cost = sigma_scale *
                 mean(max(log(sigma / sigma_min), 0))

This penalises maintaining wide posterior weight distributions (high
plasticity / exploration). Log-scaled relative to `sigma_min` so that
fully exploitative agents (sigma == sigma_min at every weight) pay 0,
and every doubling of uncertainty above the floor costs the same
increment. The biological analogue is the information-theoretic cost of
maintaining flexible neural hardware (Aiello & Wheeler 1995). Default
`sigma_scale = 0` preserves all legacy behaviour.

References:
- Yaeger, L. (1994) PolyWorld. In: *Artificial Life III*.
  Addison-Wesley, pp 263–298.
- Aiello, L.C. & Wheeler, P. (1995) The expensive-tissue hypothesis.
  *Curr. Anthropol.* 36:199–221.
"""
function _brain_energy_cost(brain::AbstractBrain,
                              logits::Vector{Float32},
                              mode::String,
                              base::Float32,
                              act_scale::Float32,
                              sigma_scale::Float32 = 0.0f0,
                              sigma_min::Float32 = 0.01f0,
                              size_exp::Float32 = 1.0f0)::Float32
    mode == "none" && return 0.0f0
    # 0.4.3: super-linear size scaling via `brain_energy_size_exponent`.
    # `size_exp = 1.0` is the legacy default; `1.5` implements Kleiber-style
    # expensive-brain amplification (Isler & van Schaik 2009) so that large
    # brains carry disproportionate metabolic weight — the gradient needed
    # for parental-provisioning scenarios to express at the default base.
    n_weights = Float32(brain_size(brain))
    size_cost = base * (size_exp == 1.0f0 ? n_weights : n_weights ^ size_exp)

    # 0.4.1 Tier 5C: information-theoretic sigma cost for BNN brains.
    sigma_cost = 0.0f0
    if sigma_scale > 0.0f0 && isa(brain, BNNBrain)
        sm = max(sigma_min, 1.0f-6)
        s  = 0.0f0
        @inbounds for v in brain.sigma
            s += max(log(v / sm), 0.0f0)
        end
        sigma_cost = sigma_scale * s / Float32(length(brain.sigma))
    end

    mode == "size" && return size_cost + sigma_cost
    if mode == "activity"
        act_cost = act_scale * sum(abs, logits) / Float32(length(logits))
        return size_cost + act_cost + sigma_cost
    end
    # prediction_error — use size cost + sigma cost (Phase 3 will implement KL)
    size_cost + sigma_cost
end
