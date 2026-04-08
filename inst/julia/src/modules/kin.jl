"""
    kin.jl — Kin-selected altruism (Hamilton's rule).

Enabled when `specs["kin_selection"] == true`.

Implements a simple form of kin-directed altruism: each tick, every agent
with sufficient energy scans its Moore neighbourhood for the most closely
related neighbour. If that neighbour's pedigree relatedness `r` meets the
minimum threshold `kin_altruism_r_min`, the donor transfers energy: it pays
`kin_altruism_cost` and the recipient gains `kin_altruism_benefit`.

Hamilton's rule states that altruism can be favoured by selection when

    r * B > C

where *r* is the coefficient of relatedness, *B* the benefit to recipient and
*C* the cost to donor. The default specs satisfy the rule with
`r_min = 0.25`, `B = 10`, `C = 2` → `rB = 2.5 > C = 2.0`.

Relatedness here is pedigree-based (not genetic distance): only immediate
parent-offspring (r = 0.5) and full-sibling (r = 0.25) ties count. More distant
kin are treated as r = 0, which slightly under-estimates true relatedness but
keeps the calculation O(1) per pair and matches the alifeR reference
implementation.

References
----------
Hamilton, W.D. (1964) The genetical evolution of social behaviour I & II.
    Journal of Theoretical Biology 7(1):1–52.
Griffin, A.S. & West, S.A. (2003) Kin discrimination and the benefit of
    helping in cooperatively breeding vertebrates. Science 302(5645):634–636.
"""

"""
    compute_relatedness(ag1::Agent, ag2::Agent) -> Float32

Return pedigree-based relatedness between two agents:

- `0.5`  — one is the direct parent of the other
- `0.25` — full siblings (same non-zero `parent_id`)
- `0.0`  — otherwise

Founders (parent_id == 0) are treated as unrelated to each other: two agents
both with `parent_id == 0` return 0, not 0.25. This is the same convention
used in alifeR's `.relatedness()`.
"""
function compute_relatedness(ag1::Agent, ag2::Agent)::Float32
    ag1.id == ag2.id && return 1.0f0   # same individual

    # Parent-offspring
    (ag1.parent_id != 0 && ag1.parent_id == ag2.id) && return 0.5f0
    (ag2.parent_id != 0 && ag2.parent_id == ag1.id) && return 0.5f0

    # Full siblings (shared non-zero parent)
    if ag1.parent_id != 0 && ag1.parent_id == ag2.parent_id
        return 0.25f0
    end

    0.0f0
end

"""
    apply_kin_altruism!(env::Environment)

One round of kin-directed energy transfer. For each live donor:

1. Skip if the donor's energy is below `kin_altruism_min_donor_energy`.
2. Scan the 8-cell Moore neighbourhood (toroidal wrap) for live agents.
3. Compute pedigree relatedness for each neighbour via
   `compute_relatedness()`.
4. Select the neighbour with the highest relatedness; break ties by first
   occurrence in the scan order.
5. If that relatedness meets `kin_altruism_r_min`, transfer energy: donor
   pays `kin_altruism_cost`; recipient gains `kin_altruism_benefit`.

Increments `env.n_altruistic_acts` by the number of successful transfers.

Transfers are applied immediately (not buffered). This means an agent that
has just received energy from a neighbour can itself become a donor later in
the same scan — mimicking continuous-time social behaviour. Donors cannot
give to themselves because the Moore neighbourhood excludes (0, 0).

References
----------
Hamilton, W.D. (1964) The genetical evolution of social behaviour I & II.
    Journal of Theoretical Biology 7(1):1–52.
"""
function apply_kin_altruism!(env::Environment)
    specs = env.specs
    Bool(get(specs, "kin_selection", false)) || return

    rows = Int(specs["grid_rows"])
    cols = Int(specs["grid_cols"])

    cost    = Float32(get(specs, "kin_altruism_cost",              2.0))
    benefit = Float32(get(specs, "kin_altruism_benefit",          10.0))
    r_min   = Float32(get(specs, "kin_altruism_r_min",             0.25))
    min_e   = Float32(get(specs, "kin_altruism_min_donor_energy", 50.0))

    agents = env.agents
    n      = length(agents)
    n == 0 && return

    n_acts = 0

    @inbounds for i in 1:n
        donor = agents[i]
        donor.alive           || continue
        donor.energy <= min_e && continue

        xi, yi = Int(donor.x), Int(donor.y)
        best_r    = 0.0f0
        best_idx  = 0

        for dx in -1:1, dy in -1:1
            (dx == 0 && dy == 0) && continue
            nx = mod1(xi + dx, rows)
            ny = mod1(yi + dy, cols)
            j  = env.agent_map[nx, ny]
            (j == 0 || j > n) && continue
            j == i && continue
            rcv = agents[j]
            rcv.alive || continue

            r = compute_relatedness(donor, rcv)
            if r > best_r
                best_r   = r
                best_idx = j
            end
        end

        if best_idx > 0 && best_r >= r_min
            donor.energy          -= cost
            agents[best_idx].energy += benefit
            n_acts += 1
        end
    end

    env.n_altruistic_acts += Int32(n_acts)
    return
end

# === CLADE.JL ADDITIONS NEEDED ===
# include: include("modules/kin.jl")
# tick loop: apply_kin_altruism!(env)   [after apply_disease!, before kill_dead!]
# Note: apply_kin_altruism! is a no-op when specs["kin_selection"] == false
# STATUS: already wired in commit 3673dc4 (pre-dates the no-edit-Clade.jl protocol)
# === END CLADE.JL ADDITIONS ===
