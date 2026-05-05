"""
    personality.jl — Wolf et al. 2007 Nature personality syndrome.

Implements the asset-protection life-history mechanism that produces a
boldness–aggressiveness syndrome:

> Wolf, M., van Doorn, G.S., Leimar, O. & Weissing, F.J. (2007)
> Life-history trade-offs favour the evolution of animal personalities.
> *Nature* 447:581–584. doi:10.1038/nature05835.

## Spatially-explicit clade interpretation

Wolf 2007 is a mean-field model: hawk-dove pairs are random across the
whole population, and the anti-predator game is a pure individual draw
with no actual predator on the grid. clade is a spatially-explicit ABM,
so we re-implement Wolf's mechanism using clade's spatial machinery:

- **Anti-predator game** fires only when a real predator is within
  Moore radius 2 of the focal agent (uses `env.predator_map`).
- **Hawk-dove game** pairs the focal agent with a random *between-phase*
  agent in its Moore neighborhood (`personality_hawkdove_radius`,
  default 1). Falls back to no game if no qualifying neighbour.

This is biologically more realistic (encounters require proximity) and
matches clade's existing spatial conventions for kin altruism, mate
choice, and disease transmission. See dev/docs/consolidation-audit.md
for the broader spatial-explicit design philosophy.

## Life cycle (age-windowed reproduction)

Wolf's discrete year-1 / year-2 reproduction events map to fixed agent
ages in clade ticks:

- `age == wolf_year1_repro_age` (default 50): emit ⌊g(x) · f_low⌋
  offspring, where g(x) = (1−x)^β and x = `agent.exploration`. Year-1
  payoff is reduced for thorough explorers.
- `age == wolf_year2_repro_age` (default 100): emit `f_high` offspring
  with probability x, else `f_low`. Agent dies after year-2 reproduction.
- `age > wolf_year2_repro_age`: defensive death (should not happen).

Game payoffs (anti-predator boldness gain `b`; hawk-dove value `V`)
accumulate in `agent.wolf_payoff_accum` during the between-phase
(year1 < age < year2). At each reproduction event the accumulated
payoff is converted to extra offspring units (divided by `f_low` to
keep it on the same scale as Wolf's fecundity numbers). The accumulator
is reset to zero after each reproduction event.

## Disabling clade's standard reproduction

clade's standard `create_offspring!` triggers on energy threshold and
fires every tick. The Wolf scenario disables it by setting
`min_repro_energy` to a very large value in the `wolf_personality_specs()`
preset, so only the age-windowed Wolf reproduction below fires. This
keeps the standard tick loop unchanged and lets researchers compose
Wolf with other modules cleanly.

## Tick order discipline

All three sub-functions iterate `env.agents` in randperm order when
`random_tick_order == true` (default), matching the Phase 1 scheduling
discipline restored in 0.7.0.

## References

- Wolf, M., van Doorn, G.S., Leimar, O. & Weissing, F.J. (2007) Nature 447:581–584.
- Clark, C.W. (1994) Antipredator behavior and the asset-protection
  principle. *Behavioral Ecology* 5:159–170.
"""

# ── Helper: stochastic rounding (preserves expectation) ──────────────────────

@inline function _stochastic_round(x::Float32, rng)::Int
    f = floor(Int, x)
    rand(rng) < (Float32(x) - Float32(f)) ? f + 1 : f
end

# ── Helper: emit n offspring at parent's neighborhood ─────────────────────────

@inline function _wolf_emit_offspring!(parent::Agent, env::Environment, n::Int,
                                        rows::Int, cols::Int, toroidal::Bool,
                                        max_ag::Int)
    n <= 0 && return
    specs      = env.specs
    off_energy = Float32(get(specs, "offspring_energy", 60.0))

    for _ in 1:n
        length(env.agents) >= max_ag && break

        # Pre-check: a free Moore neighbour must exist.
        px, py   = Int(parent.x), Int(parent.y)
        any_free = false
        @inbounds for dx in -1:1, dy in -1:1
            (dx == 0 && dy == 0) && continue
            nx = wrap_or_clamp(px + dx, rows, toroidal)
            ny = wrap_or_clamp(py + dy, cols, toroidal)
            if env.agent_map[nx, ny] == 0
                any_free = true
                break
            end
        end
        any_free || break

        mate       = _find_mate(parent, env)
        off_genome = make_offspring_genome(parent.genome,
                                            mate !== nothing ? mate.genome : nothing,
                                            specs, env.rng)
        off_brain  = make_brain(off_genome, specs)
        env.next_id += Int64(1)
        off = _make_offspring(env.next_id, off_genome, off_brain,
                               parent, mate, off_energy, env, env.rng)
        parent.num_offspring += Int32(1)
        env.n_births         += Int32(1)
        push!(env.agents, off)
        env.agent_map[off.x, off.y] = length(env.agents)
    end
end

# ── 1. Life-history trade-off + age-windowed reproduction ────────────────────

"""
    apply_lifehistory_tradeoff!(env::Environment)

At each agent's `wolf_year1_repro_age` and `wolf_year2_repro_age` boundary,
emit Wolf 2007 fecundity-formula offspring and (for year-2) kill the
parent. No-op when `personality_syndrome == false`.
"""
function apply_lifehistory_tradeoff!(env::Environment)
    Bool(get(env.specs, "personality_syndrome", false)) || return

    specs    = env.specs
    rows     = Int(specs["grid_rows"])
    cols     = Int(specs["grid_cols"])
    toroidal = Bool(get(specs, "toroidal", true))
    year1    = Int32(get(specs, "wolf_year1_repro_age", 50))
    year2    = Int32(get(specs, "wolf_year2_repro_age", 100))
    f_high   = Float32(get(specs, "personality_f_high", 3.0))
    f_low    = Float32(get(specs, "personality_f_low",  2.0))
    beta     = Float32(get(specs, "personality_beta",   1.25))
    max_ag   = Int(get(specs, "max_agents",            500))

    n_ag       = length(env.agents)
    rand_order = Bool(get(specs, "random_tick_order", true))
    order      = rand_order ? randperm(env.rng, n_ag) : (1:n_ag)

    for i in order
        ag = env.agents[i]
        ag.alive || continue

        if ag.age == year1
            # Year-1 reproduction. Wolf's games fire BETWEEN year 1 and
            # year 2, so payoff_accum is zero at this point and contributes
            # nothing here (kept for completeness; will reset anyway).
            x     = ag.exploration
            n_off = _stochastic_round((1.0f0 - x)^beta * f_low, env.rng)
            n_off = max(0, n_off)
            _wolf_emit_offspring!(ag, env, n_off, rows, cols, toroidal, max_ag)
            ag.wolf_payoff_accum = 0.0f0

        elseif ag.age == year2
            # Year-2 reproduction. Game payoffs accumulated during the
            # between-phase fold into year-2 fecundity. Wolf's V/f_high ≈
            # 3%, so individual game wins are small relative to the base
            # fecundity but accumulate over the between-phase. The
            # accumulator is divided by `f_low` to keep `payoff_bonus`
            # on the same scale as the discrete fecundity numbers.
            x            = ag.exploration
            f_i          = rand(env.rng) < Float64(x) ? f_high : f_low
            payoff_bonus = ag.wolf_payoff_accum / max(f_low, 1.0f-3)
            n_off        = _stochastic_round(f_i + payoff_bonus, env.rng)
            n_off        = max(0, n_off)
            _wolf_emit_offspring!(ag, env, n_off, rows, cols, toroidal, max_ag)
            ag.alive = false
            env.n_deaths += Int32(1)
            ag.wolf_payoff_accum = 0.0f0

        elseif ag.age > year2
            # Defensive: any agent that survives past year 2 dies.
            ag.alive = false
            env.n_deaths += Int32(1)
        end
    end
    nothing
end

# ── 2. Anti-predator game (clade-native: real predator presence) ──────────────

"""
    apply_antipredator_game!(env::Environment)

For each between-phase agent (year1 < age < year2) with probability
`personality_antipred_per_tick`, if a predator is within Moore radius
2 of the agent, draw bold/shy by `agent.boldness`:

- Bold: gain `personality_b` payoff (added to `wolf_payoff_accum`),
  die with probability `personality_gamma`.
- Shy: no payoff, survives.

No-op when `personality_syndrome == false`, when no predators are
present, or when `personality_antipred_per_tick == 0`.
"""
function apply_antipredator_game!(env::Environment)
    Bool(get(env.specs, "personality_syndrome", false)) || return
    isempty(env.predators) && return

    specs        = env.specs
    year1        = Int32(get(specs, "wolf_year1_repro_age", 50))
    year2        = Int32(get(specs, "wolf_year2_repro_age", 100))
    b_pay        = Float32(get(specs, "personality_b",                 10.0))
    gamma        = Float32(get(specs, "personality_gamma",              0.1))
    p_per_tick   = Float64(get(specs, "personality_antipred_per_tick",  0.5))
    p_per_tick > 0.0 || return

    rows         = size(env.grass, 1)
    cols         = size(env.grass, 2)
    toroidal     = Bool(get(specs, "toroidal", true))
    sense_radius = 2   # Moore radius for predator detection

    n_ag       = length(env.agents)
    rand_order = Bool(get(specs, "random_tick_order", true))
    order      = rand_order ? randperm(env.rng, n_ag) : (1:n_ag)

    for i in order
        ag = env.agents[i]
        ag.alive || continue
        (ag.age > year1 && ag.age < year2) || continue
        rand(env.rng) < p_per_tick || continue

        ax, ay = Int(ag.x), Int(ag.y)
        predator_nearby = false
        @inbounds for dx in -sense_radius:sense_radius, dy in -sense_radius:sense_radius
            (dx == 0 && dy == 0) && continue
            nx = wrap_or_clamp(ax + dx, rows, toroidal)
            ny = wrap_or_clamp(ay + dy, cols, toroidal)
            if env.predator_map[nx, ny] != 0
                predator_nearby = true
                break
            end
        end
        predator_nearby || continue

        if rand(env.rng) < Float64(ag.boldness)
            ag.wolf_payoff_accum += b_pay
            if rand(env.rng) < Float64(gamma)
                ag.alive = false
                env.n_deaths += Int32(1)
            end
        end
        # Shy: nothing happens.
    end
    nothing
end

# ── 3. Hawk-dove game (spatially-explicit: Moore neighborhood pairing) ───────

"""
    apply_hawkdove_game!(env::Environment)

For each between-phase agent (year1 < age < year2) with probability
`personality_hawkdove_per_tick`, find a random between-phase neighbour
within Moore radius `personality_hawkdove_radius` (default 1) and play
hawk-dove:

- Both hawk: random winner gets `personality_V` payoff; loser dies
  with probability `personality_delta`.
- Hawk vs dove: hawk gets V, dove gets 0.
- Both dove: V/2 each.

Each agent draws hawk vs dove by its `aggressiveness` trait.

No-op when `personality_syndrome == false`, when
`personality_hawkdove_per_tick == 0`, or when
`personality_hawkdove_radius == 0`.
"""
function apply_hawkdove_game!(env::Environment)
    Bool(get(env.specs, "personality_syndrome", false)) || return

    specs      = env.specs
    year1      = Int32(get(specs, "wolf_year1_repro_age", 50))
    year2      = Int32(get(specs, "wolf_year2_repro_age", 100))
    V          = Float32(get(specs, "personality_V",                 10.0))
    delta      = Float32(get(specs, "personality_delta",              0.5))
    p_per_tick = Float64(get(specs, "personality_hawkdove_per_tick",  0.1))
    radius     = Int(   get(specs, "personality_hawkdove_radius",     1))
    (p_per_tick > 0.0 && radius > 0) || return

    rows     = size(env.grass, 1)
    cols     = size(env.grass, 2)
    toroidal = Bool(get(specs, "toroidal", true))

    n_ag       = length(env.agents)
    rand_order = Bool(get(specs, "random_tick_order", true))
    order      = rand_order ? randperm(env.rng, n_ag) : (1:n_ag)

    for i in order
        ag = env.agents[i]
        ag.alive || continue
        (ag.age > year1 && ag.age < year2) || continue
        rand(env.rng) < p_per_tick || continue

        ax, ay = Int(ag.x), Int(ag.y)
        candidates = Int[]
        @inbounds for dx in -radius:radius, dy in -radius:radius
            (dx == 0 && dy == 0) && continue
            nx = wrap_or_clamp(ax + dx, rows, toroidal)
            ny = wrap_or_clamp(ay + dy, cols, toroidal)
            j  = env.agent_map[nx, ny]
            j == 0 && continue
            j > length(env.agents) && continue
            other = env.agents[j]
            other.alive || continue
            (other.age > year1 && other.age < year2) || continue
            push!(candidates, j)
        end
        isempty(candidates) && continue

        partner = env.agents[candidates[rand(env.rng, 1:length(candidates))]]

        ag_hawk      = rand(env.rng) < Float64(ag.aggressiveness)
        partner_hawk = rand(env.rng) < Float64(partner.aggressiveness)

        if ag_hawk && partner_hawk
            # Hawk-hawk: random winner gets V; loser dies with prob δ.
            if rand(env.rng) < 0.5
                ag.wolf_payoff_accum += V
                if rand(env.rng) < Float64(delta)
                    partner.alive = false
                    env.n_deaths += Int32(1)
                end
            else
                partner.wolf_payoff_accum += V
                if rand(env.rng) < Float64(delta)
                    ag.alive = false
                    env.n_deaths += Int32(1)
                end
            end
        elseif ag_hawk && !partner_hawk
            ag.wolf_payoff_accum += V
        elseif !ag_hawk && partner_hawk
            partner.wolf_payoff_accum += V
        else
            ag.wolf_payoff_accum      += V * 0.5f0
            partner.wolf_payoff_accum += V * 0.5f0
        end
    end
    nothing
end
