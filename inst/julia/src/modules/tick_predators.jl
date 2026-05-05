"""
    tick_predators.jl — Predator tick loop: sense → decide → move/attack → age → reproduce.

Enabled when `specs["n_predators_init"] > 0`. Predators are full `Agent`
structs (same type as prey) using the same brain interface. They hunt prey via
the `agent_map` and can evolve improved hunting strategies across generations.

## Predator tick sequence (per predator, per tick)

1. Build a 15-element sensory input vector (energy, age, prey counts and
   distances in four cardinal directions, adjacent grass density, bias).
2. Choose action via `forward(brain, input)` → `argmax`.
3. Move (actions 1–4: N/E/S/W) or attack at current cell (action 5: idle).
4. Deduct metabolic costs; increment age; mark dead if energy ≤ 0.

After all predators have acted, eligible predators reproduce asexually with a
mutated brain copy placed at a random adjacent cell.

## Seeding

`seed_predators!(env)` is called once at tick 1 when `n_predators_init > 0`
and `env.predators` is empty. Predators share the prey brain architecture and
are constructed using the same `make_brain` / `make_genome` pipeline, ensuring
they can evolve in the same trait space.

## Group defense integration

When `specs["group_defense"] == true`, attack damage is reduced by the factor
computed in `apply_group_defense!` (group_defense.jl). A per-agent damage
vector is built, reduced, then applied in a single pass.

## References

Hamilton, W.D. (1971) Geometry for the selfish herd.
    *Journal of Theoretical Biology* 31(2):295–311.

Lotka, A.J. (1925) *Elements of Physical Biology.* Williams & Wilkins, Baltimore.

Volterra, V. (1926) Fluctuations in the abundance of a species considered
    mathematically. *Nature* 118(2972):558–560.
"""

# ── Public API ────────────────────────────────────────────────────────────────

"""
    seed_predators!(env::Environment)

Populate `env.predators` with `n_predators_init` founder agents. Called once
at tick 1 when predators are enabled. No-op if predators are already present
or if `n_predators_init == 0`.

Predator founders share the prey brain architecture (taken from
`env.agents[1].genome` when prey are present, otherwise built fresh from
specs). All signal, care, disease, and RL fields are set to neutral defaults.
"""
function seed_predators!(env::Environment)
    n = Int(get(env.specs, "n_predators_init", 0))
    n == 0         && return
    isempty(env.predators) || return   # already seeded

    specs       = env.specs
    rows        = size(env.grass, 1)
    cols        = size(env.grass, 2)
    init_energy = Float32(get(specs, "predator_energy_init", 150.0))

    # Predators use a dedicated 15-input sensory vector (see
    # `_sense_predator`). Build a predator-specific architecture so the
    # brain's `n_inputs == 15`, not the prey's `_compute_n_inputs(specs)`
    # which varies with input_radius and active sensory modules. Without
    # this override, the predator brain reads prey-sense slots for its
    # own inputs (silent size mismatch).
    prey_arch   = _build_arch(specs)
    hidden_arch = length(prey_arch) > 2 ? prey_arch[2:end-1] : Int32[]
    pred_arch   = Int32[Int32(15); hidden_arch; Int32(5)]

    for _ in 1:n
        env.next_id += Int64(1)

        g    = make_genome(specs, pred_arch, env.rng)
        br   = make_brain(g, specs)

        px = Int32(rand(env.rng, 1:rows))
        py = Int32(rand(env.rng, 1:cols))

        pred = Agent(
            # Identity
            env.next_id, Int64(0), Int64(0),
            px, py,
            # Energy / lifecycle
            init_energy, Int32(0), env.t, true,
            # Brain and genome
            br, g, Bool[],
            # Scalar traits (neutral defaults; predators do not use all traits)
            1.0f0,   # body_size
            0.0f0,   # immune_strength
            0.0f0,   # cooperation_level
            0.0f0,   # dispersal_tendency
            1.0f0,   # metabolic_rate
            1.0f0,   # aging_rate
            Float32(get(specs, "predator_min_repro_energy", 200.0)),  # repro_threshold
            Float32(get(specs, "predator_mutation_sd",      0.1)),    # mutation_sd
            0.01f0,  # learning_rate
            # Signal (predators carry no signal)
            Float32[], Float32[],
            # Mimicry (toxicity) + signal_memory (0.4.4) + parasite_haplotype (0.5.1):
            # all lazily sized; predators don't participate in the Red Queen module
            0.0f0,
            Float32[],
            Int32[],
            # Disease
            false, false, Int32(0), Int32(0),
            # Parental care
            Any[], Int32(0),
            # RL
            0.0f0, init_energy,
            # Reproductive tracking
            false, Int32(0), Int32(0), Int32(0),
            # Speciation
            Int32(0),
            # Natal coordinates
            px, py,
            # Habitat preference, helper tendency, plasticity
            0.0f0, 0.0f0, 0.0f0,
            # Wing size, niche layer (predators always ground-layer)
            0.0f0, Int32(1),
            # Brain size (predators use reference value; do not evolve brain_size)
            1.0f0
        )

        push!(env.predators, pred)
        env.predator_map[px, py] = 1   # mark occupied (non-zero = predator present)
    end
end

"""
    tick_predators!(env::Environment)

Apply one tick to all live predators.

Steps (per predator):
1. Build a 15-element sensory input vector via `_sense_predator`.
2. Choose action = `argmax(forward(brain, input))`.
3. Move (action ≤ 4) or attack at current cell (action == 5).
4. Deduct metabolic costs; age by one tick; die if energy ≤ 0.

After the per-predator loop, `_predator_reproduction!` is called.
No-op when `n_predators_init == 0`.
"""
function tick_predators!(env::Environment)
    Int(get(env.specs, "n_predators_init", 0)) == 0 && return

    specs       = env.specs
    live_energy = Float32(get(specs, "predator_live_energy",    2.0))
    move_energy = Float32(get(specs, "predator_move_energy",    1.0))
    attack_str  = Float32(get(specs, "predator_attack_strength", 40.0))
    energy_gain = Float32(get(specs, "predator_energy_gain",    30.0))
    # 0.5.6: separate predator max_age. Defaults to prey max_age if not
    # set, preserving legacy behaviour. Predators are typically longer-
    # lived than prey (owl > mouse, lion > zebra).
    pred_max_age = Int32(get(specs, "predator_max_age",
                             get(specs, "max_age", 200)))
    rows        = size(env.grass, 1)
    cols        = size(env.grass, 2)
    toroidal    = Bool(get(specs, "toroidal", true))

    # ── Build per-prey damage vector for group-defense integration ─────────
    n_prey   = length(env.agents)
    damage   = zeros(Float32, n_prey)   # accumulated damage per prey this tick

    # 0.7.0: random asynchronous scheduling (see tick.jl). Direct analogue of
    # the agent loop: first-array predators otherwise sense, move, and attack
    # first; later predators face a depleted prey field.
    n_pred     = length(env.predators)
    rand_order = Bool(get(specs, "random_tick_order", true))
    pred_order = rand_order ? randperm(env.rng, n_pred) : (1:n_pred)

    for i in pred_order
        pred = env.predators[i]
        pred.alive || continue

        # 1. Sense
        input  = _sense_predator(pred, env)
        # 2. Decide
        logits = forward(pred.brain, input)
        action = argmax(logits)

        # 3. Move or attack
        if action <= 4
            _move_predator!(pred, action, rows, cols, env)
            pred.energy -= move_energy
        else
            # Action 5: idle / attack at current cell
            _accumulate_attack!(pred, attack_str, damage, env)
        end

        # 4. Metabolic cost and aging
        pred.energy -= live_energy
        pred.age    += Int32(1)
        if pred.energy <= 0.0f0
            pred.alive   = false
            env.n_deaths += Int32(1)
        elseif pred.age >= pred_max_age
            pred.alive   = false
            env.n_deaths += Int32(1)
        end
    end

    # Rebuild predator_map after all moves (same pattern as tick.jl / habitat_preference.jl)
    fill!(env.predator_map, Int64(0))
    for pred in env.predators
        pred.alive && (env.predator_map[pred.x, pred.y] = 1)
    end

    # ── Apply group defense, then resolve damage ───────────────────────────
    if any(d -> d > 0.0f0, damage)
        damage = apply_group_defense!(env, damage)
        _apply_prey_damage!(damage, energy_gain, env)
    end

    # ── Predator reproduction ──────────────────────────────────────────────
    _predator_reproduction!(env)
end

# ── Private helpers ───────────────────────────────────────────────────────────

"""
    _sense_predator(pred, env) -> Vector{Float32}

Build the 15-element sensory input vector for a predator agent:

```
[energy/150,  age/100,
 prey_N, prey_E, prey_S, prey_W,          # count of prey in ray (0–1, clipped)
 dist_N, dist_E, dist_S, dist_W,          # normalised distance to nearest prey
 grass_N, grass_E, grass_S, grass_W,      # adjacent grass density (0–1)
 1.0]                                      # bias
```

Prey are detected by scanning up to 5 cells in each cardinal direction using
`env.agent_map`. Distance is normalised by the scan depth (5 cells).
"""
function _sense_predator(pred::Agent, env::Environment)::Vector{Float32}
    specs    = env.specs
    rows     = size(env.grass, 1)
    cols     = size(env.grass, 2)
    gmax     = Float32(get(specs, "grass_max", 5.0))
    toroidal = Bool(get(specs, "toroidal", true))
    max_scan = 5   # cells scanned in each cardinal direction

    x, y = Int(pred.x), Int(pred.y)

    # Cardinal step vectors: N, E, S, W
    DX = (-1,  0,  1,  0)
    DY = ( 0,  1,  0, -1)

    prey_count = zeros(Float32, 4)
    prey_dist  = ones(Float32,  4)   # default: no prey detected (distance = 1.0 = max)
    grass_adj  = zeros(Float32, 4)

    for d in 1:4
        # Count prey and record distance in this direction
        found_dist = false
        n_prey_d   = 0
        for step in 1:max_scan
            nx = wrap_or_clamp(x + step * DX[d], rows, toroidal)
            ny = wrap_or_clamp(y + step * DY[d], cols, toroidal)
            if env.agent_map[nx, ny] > 0
                n_prey_d += 1
                if !found_dist
                    prey_dist[d]  = Float32(step) / Float32(max_scan)
                    found_dist = true
                end
            end
        end
        prey_count[d] = clamp(Float32(n_prey_d) / Float32(max_scan), 0.0f0, 1.0f0)

        # Adjacent cell grass (one step only)
        nx_adj = wrap_or_clamp(x + DX[d], rows, toroidal)
        ny_adj = wrap_or_clamp(y + DY[d], cols, toroidal)
        grass_adj[d] = env.grass[nx_adj, ny_adj] / gmax
    end

    inp = Vector{Float32}(undef, 15)
    inp[1]  = clamp(pred.energy / 150.0f0, 0.0f0, 1.0f0)
    inp[2]  = clamp(Float32(pred.age) / 100.0f0, 0.0f0, 1.0f0)
    inp[3]  = prey_count[1]   # N
    inp[4]  = prey_count[2]   # E
    inp[5]  = prey_count[3]   # S
    inp[6]  = prey_count[4]   # W
    inp[7]  = prey_dist[1]    # N
    inp[8]  = prey_dist[2]    # E
    inp[9]  = prey_dist[3]    # S
    inp[10] = prey_dist[4]    # W
    inp[11] = grass_adj[1]    # N
    inp[12] = grass_adj[2]    # E
    inp[13] = grass_adj[3]    # S
    inp[14] = grass_adj[4]    # W
    inp[15] = 1.0f0           # bias
    inp
end

"""
    _move_predator!(pred, action, rows, cols, env)

Move `pred` by one cell in the direction encoded by `action`:

    1 = N (x − 1)   2 = E (y + 1)   3 = S (x + 1)   4 = W (y − 1)

Uses toroidal wrap via `mod1`. The `predator_map` is cleared for the old cell
and set at the new cell.

**0.7.0 Phase 2**: one-predator-per-cell at movement, mirroring the prey
one-per-cell rule in `tick.jl`. If the target cell is already occupied by
another predator, this predator stays put. Predators can still move onto
prey cells (that's how attacks happen). Restored alongside the agent
one-per-cell fix; pre-0.7.0 silently allowed multiple predators per cell
(the docstring used to admit this as design — it was actually a regression
from the implicit MATLAB/alifeR one-per-cell discipline).
"""
function _move_predator!(pred::Agent, action::Int, rows::Int, cols::Int,
                          env::Environment)
    DX      = (Int32(-1), Int32(0),  Int32(1), Int32(0))
    DY      = (Int32(0),  Int32(1),  Int32(0), Int32(-1))
    toroidal = Bool(get(env.specs, "toroidal", true))

    sx, sy = pred.x, pred.y
    nx = Int32(wrap_or_clamp(Int(sx) + Int(DX[action]), rows, toroidal))
    ny = Int32(wrap_or_clamp(Int(sy) + Int(DY[action]), cols, toroidal))

    # 0.7.0 Phase 2: one-per-cell — block move if target predator-occupied.
    if (nx != sx || ny != sy) && env.predator_map[nx, ny] != 0
        nx = sx
        ny = sy
    end

    if nx != sx || ny != sy
        env.predator_map[sx, sy] = 0
        env.predator_map[nx, ny] = 1
        pred.x = nx
        pred.y = ny
    end
end

"""
    _accumulate_attack!(pred, attack_str, damage, env)

Record attack damage for the prey at `pred`'s current cell. The damage is
stored in `damage[prey_idx]` and applied later (after group defense) by
`_apply_prey_damage!`. If no prey is present the function is a no-op.
"""
function _accumulate_attack!(pred::Agent, attack_str::Float32,
                              damage::Vector{Float32}, env::Environment)
    prey_idx = env.agent_map[pred.x, pred.y]
    prey_idx == 0 && return
    prey_idx > length(env.agents) && return   # stale map entry guard
    prey = env.agents[prey_idx]

    # Mimicry: check learned avoidance before attacking
    if should_avoid_prey(pred, prey, env)
        env.n_avoided_attacks += Int32(1)
        return
    end

    damage[prey_idx] += attack_str

    # Mimicry: toxic prey damages predator and updates memory
    if prey.toxicity > 0.0f0
        env.n_toxic_attacks += Int32(1)
        apply_predator_toxin!(pred, prey, env)
    elseif Bool(get(env.specs, "batesian_mimicry", false)) &&
           Bool(get(env.specs, "mimicry", false))
        # Batesian: predator attacks a palatable mimic and receives no
        # toxin. Learning still runs (prey.toxicity = 0), which decays
        # the aversion memory toward zero — the "predator betrayal"
        # mechanism that stops mimics exploiting the learned signal
        # indefinitely.
        apply_predator_toxin!(pred, prey, env)
    end
end

"""
    _apply_prey_damage!(damage, energy_gain, env)

Apply the resolved damage vector to prey, transfer energy to attacking
predators, and mark dead prey. Predator energy gain is distributed equally
among all predators currently on the same cell as the dying prey.

Each predator gains `energy_gain` only if at least one prey on its cell dies
this step — this prevents energy inflation when multiple predators stack attacks
on a single prey.
"""
function _apply_prey_damage!(damage::Vector{Float32}, energy_gain::Float32,
                              env::Environment)
    n_prey = length(env.agents)
    for i in 1:n_prey
        damage[i] > 0.0f0 || continue
        prey = env.agents[i]
        prey.alive || continue

        prey.energy -= damage[i]

        if prey.energy <= 0.0f0
            prey.alive    = false
            env.n_deaths += Int32(1)

            # Reward predators on this cell
            px, py = Int(prey.x), Int(prey.y)
            for pred in env.predators
                pred.alive              || continue
                Int(pred.x) == px && Int(pred.y) == py || continue
                pred.energy += energy_gain
            end
        end
    end
end

"""
    _predator_reproduction!(env)

Asexual reproduction for predators. Eligible predators (alive, energy ≥
`predator_min_repro_energy`, age ≥ `predator_min_repro_age`) produce one
offspring with a mutated brain copy placed at a random adjacent cell. Energy
is split evenly; the counter `env.n_births` is incremented per offspring.

Reproduction halts once `length(env.predators) >= predator_max_agents`.
"""
function _predator_reproduction!(env::Environment)
    specs       = env.specs
    min_energy  = Float32(get(specs, "predator_min_repro_energy", 200.0))
    min_age     = Int32(get(specs, "predator_min_repro_age",      5))
    max_preds   = Int(get(specs, "predator_max_agents",           50))
    mut_sd      = Float32(get(specs, "predator_mutation_sd",      0.1))
    rows        = size(env.grass, 1)
    cols        = size(env.grass, 2)
    toroidal    = Bool(get(specs, "toroidal", true))
    init_energy = Float32(get(specs, "predator_energy_init",      150.0))
    off_energy  = init_energy * 0.5f0

    new_preds = Agent[]

    # 0.7.0: random asynchronous scheduling (see tick.jl). Order-sensitive cap:
    # `length(env.predators) + length(new_preds) >= max_preds && break` would
    # otherwise systematically favour first-array predators when reproducing.
    n_pred     = length(env.predators)
    rand_order = Bool(get(specs, "random_tick_order", true))
    pred_order = rand_order ? randperm(env.rng, n_pred) : (1:n_pred)

    for i in pred_order
        pred = env.predators[i]
        length(env.predators) + length(new_preds) >= max_preds && break
        pred.alive              || continue
        pred.energy < min_energy && continue
        pred.age    < min_age    && continue

        # Mutate brain
        off_brain = mutate(pred.brain, mut_sd, env.rng)

        # Place offspring at a random adjacent cell (toroidal or bounded)
        ox = Int32(wrap_or_clamp(Int(pred.x) + rand(env.rng, -1:1), rows, toroidal))
        oy = Int32(wrap_or_clamp(Int(pred.y) + rand(env.rng, -1:1), cols, toroidal))

        env.next_id += Int64(1)

        offspring = Agent(
            # Identity
            env.next_id, pred.id, Int64(0),
            ox, oy,
            # Energy / lifecycle
            off_energy, Int32(0), env.t, true,
            # Brain and genome (genome inherited unchanged; only brain mutates)
            off_brain, pred.genome, Bool[],
            # Scalar traits (inherited from parent)
            pred.body_size, pred.immune_strength, pred.cooperation_level,
            pred.dispersal_tendency, pred.metabolic_rate, pred.aging_rate,
            pred.repro_threshold, pred.mutation_sd, pred.learning_rate,
            # Signal
            Float32[], Float32[],
            # Mimicry + signal_memory (0.4.4) + parasite_haplotype (0.5.1):
            # offspring predators carry nothing; they learn fresh each
            # generation and are exempt from the Red Queen module.
            0.0f0,
            Float32[],
            Int32[],
            # Disease
            false, false, Int32(0), Int32(0),
            # Parental care
            Any[], Int32(0),
            # RL
            0.0f0, pred.energy * 0.3f0,
            # Reproductive tracking
            false, Int32(0), Int32(0), Int32(0),
            # Speciation
            Int32(0),
            # Natal coordinates
            ox, oy,
            # Habitat preference, helper tendency, plasticity
            0.0f0, 0.0f0, 0.0f0,
            # Wing size, niche layer (predators always ground-layer)
            0.0f0, Int32(1),
            # Brain size (reference value; predators do not evolve brain_size)
            1.0f0
        )

        pred.energy  -= off_energy
        env.n_births += Int32(1)
        push!(new_preds, offspring)
    end

    for off in new_preds
        push!(env.predators, off)
        env.predator_map[off.x, off.y] = 1
    end
end
