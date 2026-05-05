"""
    reciprocity.jl — Trivers 1971 reciprocal altruism.

Implements iterated-PD-style conditional cooperation with per-agent
partner memory, following:

> Trivers, R.L. (1971) The evolution of reciprocal altruism.
> *Quarterly Review of Biology* 46:35–57.

## Spatially-explicit clade interpretation

Trivers' theory is non-mathematical (it's a verbal-conceptual paper);
Axelrod (1981/1984) operationalised it as iterated PD with global
random pairing. clade re-implements it spatially:

- **Encounters**: when two agents are within Moore radius
  `reciprocity_radius` (default 1), they may interact this tick with
  probability `reciprocity_interaction_rate`. Each agent's partner
  memory grows / updates per encounter.
- **Strategy**: each agent uses a generous-tit-for-tat parameterised by
  three heritable traits in [0,1]:
  - `reciprocity_initial`     — Pr(cooperate on first encounter)
  - `reciprocity_retaliation` — Pr(defect after partner defected)
  - `reciprocity_forgiveness` — Pr(return to cooperate after defecting back)
- **Payoffs**: cooperation transfers `reciprocity_cost` energy from
  actor to partner, multiplied by `reciprocity_benefit_ratio` on
  receipt (benefit > cost so cooperation is socially beneficial).
  Defection: actor takes `reciprocity_cost` energy from partner without
  giving back.

## Trivers' conditions for stability

Trivers (and the later Axelrod tournaments) identifies the conditions
where conditional cooperation outcompetes pure defection:

1. **Long lifespan** — many opportunities to repeat games.
2. **Low dispersal** — same partners encountered repeatedly.
3. **Mutual dependence** — incentive to keep partners alive.
4. **Partner recognition** — know who helped you before.
5. **Cheater discrimination** — withhold help from defectors.

clade implements (3) through energy-mediated death (defectors who get
their energy reserves drained eventually die from starvation), (4)
through `partner_ids`/`partner_actions` ring buffer, and (5) through
the `retaliation` trait. Conditions (1) and (2) are scenario-level
choices: long `max_age` and low `dispersal_evolution` for the
trivers preset.

## Headline test

Cooperation is expected to evolve under low dispersal (high re-encounter
rate) and decay to defection under high dispersal — the signature
empirical prediction of Trivers' theory. See
tests/testthat/test-reciprocal-altruism.R for the dispersal sweep.

## Random-asynchronous scheduling

Iterates `env.agents` in `randperm` order when `random_tick_order` is
TRUE (the default since 0.7.0; see tick.jl).

## References

- Trivers, R.L. (1971) Q. Rev. Biol. 46:35–57.
- Axelrod, R. & Hamilton, W.D. (1981) The evolution of cooperation.
  *Science* 211:1390–1396.
- Nowak, M.A. (2006) Five rules for the evolution of cooperation.
  *Science* 314:1560–1563.
"""

# ── Helper: lazy partner-memory init ──────────────────────────────────────────

@inline function _ensure_partner_memory!(ag::Agent, mem_size::Int)
    if length(ag.partner_ids) != mem_size
        resize!(ag.partner_ids,     mem_size); fill!(ag.partner_ids,     Int64(0))
        resize!(ag.partner_actions, mem_size); fill!(ag.partner_actions, Int8(0))
    end
    nothing
end

# ── Helper: look up partner's last action in agent's memory ──────────────────
# Returns 0 if partner not in memory, +1 if they cooperated last, -1 if defected.

@inline function _partner_last_action(ag::Agent, partner_id::Int64)::Int8
    @inbounds for k in eachindex(ag.partner_ids)
        ag.partner_ids[k] == partner_id && return ag.partner_actions[k]
    end
    Int8(0)
end

# ── Helper: record an interaction in agent's ring buffer ─────────────────────
# Overwrites the slot for `partner_id` if present, else evicts the oldest entry.

@inline function _record_partner_action!(ag::Agent, partner_id::Int64, action::Int8)
    # Update existing slot if present
    @inbounds for k in eachindex(ag.partner_ids)
        if ag.partner_ids[k] == partner_id
            ag.partner_actions[k] = action
            return
        end
    end
    # Evict oldest (slot 1) and shift, append at end
    n = length(ag.partner_ids)
    n == 0 && return
    @inbounds for k in 1:(n-1)
        ag.partner_ids[k]     = ag.partner_ids[k+1]
        ag.partner_actions[k] = ag.partner_actions[k+1]
    end
    ag.partner_ids[n]     = partner_id
    ag.partner_actions[n] = action
    nothing
end

# ── Helper: decide cooperate / defect against a partner ──────────────────────
# Returns true to cooperate, false to defect.

@inline function _reciprocity_decide(ag::Agent, partner::Agent, rng)::Bool
    last = _partner_last_action(ag, partner.id)
    if last == Int8(0)
        # First encounter — Pr(cooperate) = initial trait
        return rand(rng) < Float64(ag.reciprocity_initial)
    elseif last == Int8(1)
        # Partner cooperated last — generous TFT: cooperate unless
        # retaliation × (1 − forgiveness) overrules.
        return rand(rng) >= Float64(ag.reciprocity_retaliation) *
                            (1.0 - Float64(ag.reciprocity_forgiveness))
    else  # last == -1 — partner defected last
        # Defect with prob retaliation, else cooperate (forgive).
        return !(rand(rng) < Float64(ag.reciprocity_retaliation)) ||
                rand(rng) < Float64(ag.reciprocity_forgiveness)
    end
end

# ── Public API: run one tick of reciprocal altruism ──────────────────────────

"""
    apply_reciprocal_altruism!(env::Environment)

For each adjacent live-agent pair, with probability
`reciprocity_interaction_rate`, play one round of conditional cooperation
based on partner memory + the three reciprocity traits. Cooperation
transfers `c` energy from actor (multiplied by `b/c` on receipt);
defection takes `c` energy from partner.

No-op when `reciprocal_altruism == false`. Iterates in `randperm` order.
"""
function apply_reciprocal_altruism!(env::Environment)
    Bool(get(env.specs, "reciprocal_altruism", false)) || return

    specs        = env.specs
    cost         = Float32(get(specs, "reciprocity_cost",            0.5))
    b_ratio      = Float32(get(specs, "reciprocity_benefit_ratio",   2.0))
    p_per_tick   = Float64(get(specs, "reciprocity_interaction_rate", 0.1))
    mem_size     = Int(   get(specs, "partner_memory_size",          8))
    radius       = Int(   get(specs, "reciprocity_radius",           1))
    (p_per_tick > 0.0 && radius > 0 && cost > 0.0f0 && mem_size > 0) || return

    rows         = size(env.grass, 1)
    cols         = size(env.grass, 2)
    toroidal     = Bool(get(specs, "toroidal", true))

    n_ag       = length(env.agents)
    rand_order = Bool(get(specs, "random_tick_order", true))
    order      = rand_order ? randperm(env.rng, n_ag) : (1:n_ag)

    for i in order
        ag = env.agents[i]
        ag.alive || continue
        _ensure_partner_memory!(ag, mem_size)

        ax, ay = Int(ag.x), Int(ag.y)
        # Find candidate neighbours (live agents within Moore radius)
        @inbounds for dx in -radius:radius, dy in -radius:radius
            (dx == 0 && dy == 0) && continue
            nx = wrap_or_clamp(ax + dx, rows, toroidal)
            ny = wrap_or_clamp(ay + dy, cols, toroidal)
            j  = env.agent_map[nx, ny]
            j == 0 && continue
            j > length(env.agents) && continue
            partner = env.agents[j]
            partner.alive || continue
            partner.id == ag.id && continue
            # Interaction-rate gate: skip with prob 1 - p
            rand(env.rng) < p_per_tick || continue

            _ensure_partner_memory!(partner, mem_size)

            # Both agents decide independently
            ag_coop      = _reciprocity_decide(ag, partner, env.rng)
            partner_coop = _reciprocity_decide(partner, ag, env.rng)

            # Apply payoffs (Prisoner's Dilemma matrix scaled by `cost`):
            #   ag      partner    ag_payoff    partner_payoff
            #   coop    coop       +c*(b-1)     +c*(b-1)       (mutual benefit)
            #   coop    defect     -c           +c*b           (sucker's payoff)
            #   defect  coop       +c*b         -c             (temptation)
            #   defect  defect     0            0              (mutual punishment)
            if ag_coop && partner_coop
                ag.energy      += cost * (b_ratio - 1.0f0)
                partner.energy += cost * (b_ratio - 1.0f0)
            elseif ag_coop && !partner_coop
                ag.energy      -= cost
                partner.energy += cost * b_ratio
            elseif !ag_coop && partner_coop
                ag.energy      += cost * b_ratio
                partner.energy -= cost
            end
            # defect-defect: no transfer

            # Record actions in both partner memories
            _record_partner_action!(ag,      partner.id, ag_coop      ? Int8(1) : Int8(-1))
            _record_partner_action!(partner, ag.id,      partner_coop ? Int8(1) : Int8(-1))
        end
    end
    nothing
end
