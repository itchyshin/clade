"""
    cooperative_breeding.jl — Alloparental helping in cooperatively breeding groups.

Enabled when `specs["cooperative_breeding"] == true`. Requires
`specs["parental_care"] == true`.

Cooperative breeding is implemented as kin-biased alloparenting: a helper
agent (the alloparent) transfers energy to a nearby parent that is currently
carrying offspring. Whether a candidate helps is determined stochastically
by its heritable `helper_tendency` trait (probability of acting as alloparent
on any given tick) and its pedigree relatedness to the focal parent. Only
candidates with relatedness `r >= helper_kin_threshold` and energy above
`helper_min_energy` are eligible. Each parent receives at most one helper per
tick (the first eligible candidate found in a shuffled scan within Moore
radius 2, toroidal).

The helper pays `helper_transfer` energy; the parent gains the same amount,
reducing the net care cost modelled in `apply_care_costs!()`. This energy
transfer can propagate indirectly to juveniles through `feed_offspring!()`,
creating the classic indirect fitness benefit that Hamilton's rule predicts
should favour alloparental helping when r × B > C.

`env.n_helpers` is incremented once per successful helping event per tick.

References
----------
Hamilton, W.D. (1964) The genetical evolution of social behaviour I & II.
    Journal of Theoretical Biology 7(1):1–52.
Brown, J.L. & Brown, E.R. (1981) Kin selection and individual selection in
    babblers. In: Alexander, R.D. & Tinkle, D.W. (eds.) Natural Selection
    and Social Behavior. Chiron Press, pp. 244–256.
"""

"""
    _helper_relatedness(helper::Agent, parent::Agent, agents::Vector{Agent}) -> Float64

Compute pedigree-based relatedness between a candidate helper and the focal
parent using a three-case lookup:

- `0.5`  — `helper.parent_id == parent.id`: helper is an offspring of the parent
- `0.5`  — `helper.id == parent.parent_id`: helper is the parent's own parent
- `0.25` — `helper.parent_id == parent.parent_id && helper.parent_id != 0`: full siblings
- `0.0`  — otherwise (including both having `parent_id == 0`)

This is O(1) per pair and matches the two-generation pedigree convention used
throughout the clade and alifeR codebases (see `compute_relatedness` in
`kin.jl`). The return type is Float64 so it can be directly compared against
`helper_kin_threshold` without promotion.
"""
function _helper_relatedness(helper::Agent, parent::Agent, agents::Vector{Agent})::Float64
    # Helper is offspring of parent
    helper.parent_id != 0 && helper.parent_id == parent.id && return 0.5

    # Helper is the parent of parent (grandparent helping)
    helper.id == parent.parent_id && parent.parent_id != 0 && return 0.5

    # Full siblings: shared non-zero parent
    if helper.parent_id != 0 && helper.parent_id == parent.parent_id
        return 0.25
    end

    0.0
end

"""
    apply_cooperative_breeding!(env::Environment)

One round of alloparental energy transfer. For each live parent currently
carrying offspring:

1. Scan every live agent within Moore radius 2 (5×5 neighbourhood, toroidal)
   for eligible helpers.
2. A candidate is eligible if:
   - `candidate.alive == true`
   - `candidate.energy > helper_min_energy`
   - `rand(env.rng) <= candidate.helper_tendency` (stochastic willingness)
   - `_helper_relatedness(candidate, parent) >= helper_kin_threshold`
3. The first eligible candidate found transfers `helper_transfer` energy to
   the parent and increments `env.n_helpers`. The inner search then stops
   (one helper per parent per tick).

The neighbourhood is scanned via `env.agent_map` using a doubly-nested loop
over dx ∈ -2:2, dy ∈ -2:2 (excluding the parent's own cell). This is O(25)
per parent per tick, cheap relative to the ANN decision step.

Guard: no-op when `specs["cooperative_breeding"] == false`.
"""
function apply_cooperative_breeding!(env::Environment)
    specs = env.specs
    Bool(get(specs, "cooperative_breeding", false)) || return

    rows     = Int(specs["grid_rows"])
    cols     = Int(specs["grid_cols"])
    toroidal = Bool(get(specs, "toroidal", true))

    helper_min_energy    = Float32(get(specs, "helper_min_energy",    80.0))
    helper_transfer      = Float32(get(specs, "helper_transfer",       5.0))
    helper_kin_threshold = Float64(get(specs, "helper_kin_threshold",  0.25))

    agents = env.agents
    n      = length(agents)
    n == 0 && return

    n_help = 0

    @inbounds for i in 1:n
        ag = agents[i]
        ag.alive          || continue
        ag.care_load <= 0 && continue

        xi, yi  = Int(ag.x), Int(ag.y)
        helped  = false

        for dx in -2:2
            helped && break
            for dy in -2:2
                helped && break
                (dx == 0 && dy == 0) && continue
                nx = wrap_or_clamp(xi + dx, rows, toroidal)
                ny = wrap_or_clamp(yi + dy, cols, toroidal)
                j  = env.agent_map[nx, ny]
                (j == 0 || j > n) && continue
                j == i && continue

                cand = agents[j]
                cand.alive                    || continue
                cand.energy <= helper_min_energy && continue
                rand(env.rng) > cand.helper_tendency && continue

                r = _helper_relatedness(cand, ag, agents)
                r < helper_kin_threshold && continue

                # Eligible helper found — transfer energy
                cand.energy -= helper_transfer
                ag.energy   += helper_transfer
                n_help      += 1
                helped       = true
            end
        end
    end

    env.n_helpers += Int32(n_help)
    return
end

# === CLADE.JL ADDITIONS NEEDED ===
# include: include("modules/cooperative_breeding.jl")
# tick loop: apply_cooperative_breeding!(env)  [after apply_care_costs!, before feed_offspring!]
# Requires parental_care = true in specs.
# Note: apply_cooperative_breeding! is a no-op when specs["cooperative_breeding"] == false
# === END CLADE.JL ADDITIONS ===
