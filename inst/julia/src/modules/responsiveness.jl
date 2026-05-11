"""
    responsiveness.jl — Wolf et al. 2008 PNAS responsive/unresponsive personalities.

Implements the frequency-dependent-benefit-of-sampling mechanism from:

> Wolf, M., van Doorn, G.S. & Weissing, F.J. (2008) Evolutionary
> emergence of responsive and unresponsive personalities. *Proceedings
> of the National Academy of Sciences USA* 105:15825–15830.
> doi:10.1073/pnas.0805473105.

## Spatially-explicit clade interpretation

Wolf 2008 is a non-spatial 50-island model where agents play either a
"responsive" strategy (pay cost C, observe environmental state, choose
action conditional on state) or an "unresponsive" strategy (use a fixed
general-purpose action). The paper's headline result: negative
frequency-dependent selection on responsiveness produces stable
coexistence; positive feedback on cost-of-responsiveness maintains
cross-context consistency.

clade re-implements the core mechanism — the **frequency-dependent
benefit of sampling** — using clade's spatial machinery instead of
abstract islands:

- Each agent has one heritable trait `responsiveness ∈ [0,1]` =
  Pr(sample local state and override action this tick).
- When responsive: pay `responsiveness_cost` energy; scan the four
  cardinal-neighbour cells; override the agent's normal ANN-decided
  action with the move toward the richest cell. (If the agent's own
  cell is richest, choose idle.)
- When NOT responsive: standard ANN-decided action stands; no cost.

Frequency-dependence emerges naturally from clade's existing grass
economy:

- When few agents are responsive → rich cells stay rich → being
  responsive yields large foraging gain → trait selected for.
- When many agents are responsive → all flock to rich cells →
  handling-time + one-per-cell movement-block deplete the rich cells →
  responsiveness loses its edge → trait selected against.

This is exactly Wolf 2008's `dE/dp_r < 0` condition (Methods Eq. 1)
realised via spatial competition rather than the abstract patch-choice
denominator.

## What's NOT implemented (deliberate scope choice)

The Phase 5 implementation captures the **frequency-dependence**
mechanism. Wolf 2008's two extensions — (a) two-stage games producing
cross-context CONSISTENCY of responsiveness, and (b) positive feedback
where prior responsiveness reduces cost — are not yet implemented.
clade's existing modules (Wolf 2007 hawk-dove, Trivers reciprocity)
could supply the second context for (a); the cost-feedback for (b)
would need a per-agent `times_responsive` counter. Both are future
follow-up work documented in the vignette.

## Tick-loop placement

`apply_responsive_personalities!` runs immediately AFTER `tick_agents!`,
so it can override the action that was just executed. Specifically: it
re-positions the agent (and its energy gain from eating) based on the
richest neighbour cell, paying the sampling cost. This is a deliberate
design choice — the alternative (run BEFORE tick_agents! to set the
action) would require deeper integration with the per-agent decision
loop.

## Random asynchronous scheduling

Iterates `env.agents` in `randperm` order when `random_tick_order` is
TRUE (the default since 0.7.0).

## References

- Wolf, M., van Doorn, G.S. & Weissing, F.J. (2008) PNAS 105:15825–15830.
- DeWitt, T.J., Sih, A. & Wilson, D.S. (1998) Costs and limits of
  phenotypic plasticity. *Trends in Ecology & Evolution* 13:77–81.
"""

# ── Public API ────────────────────────────────────────────────────────────────

"""
    apply_responsive_personalities!(env::Environment)

For each live agent, with probability equal to its `responsiveness`
trait, pay `responsiveness_cost` energy and sample its 4 cardinal
neighbour cells. If a neighbour cell has more grass than the agent's
own cell AND is currently free (one-per-cell rule), move the agent
to the richest free neighbour. (The agent then eats from its new cell
on the next tick's `tick_agents!` pass.)

No-op when `responsive_personalities == false`.
"""
function apply_responsive_personalities!(env::Environment)
    Bool(get(env.specs, "responsive_personalities", false)) || return

    specs    = env.specs
    cost     = Float32(get(specs, "responsiveness_cost", 0.4))
    cost > 0.0f0 || return

    rows      = size(env.grass, 1)
    cols      = size(env.grass, 2)
    toroidal  = Bool(get(specs, "toroidal", true))
    # Reuse the same eating params as tick.jl so the post-override bite
    # behaves consistently with normal foraging.
    eat_gain  = Float32(get(specs, "eat_gain", 5.0))
    max_bite  = Float32(get(specs, "max_bite", 2.0))
    energy_max = Float32(get(specs, "energy_max", 200.0))

    n_ag       = length(env.agents)
    rand_order = Bool(get(specs, "random_tick_order", true))
    order      = rand_order ? randperm(env.rng, n_ag) : (1:n_ag)

    for i in order
        ag = env.agents[i]
        ag.alive || continue
        # Decide whether to sample this tick (Pr = responsiveness)
        rand(env.rng) < Float64(ag.responsiveness) || continue

        # Pay sampling cost
        ag.energy -= cost

        # Find best free cardinal neighbour (or stay if own cell is richest)
        sx, sy   = Int(ag.x), Int(ag.y)
        best_g   = env.grass[sx, sy]
        best_x   = sx
        best_y   = sy
        # N (x-1), E (y+1), S (x+1), W (y-1)
        @inbounds for d in 1:4
            nx = sx; ny = sy
            if d == 1
                nx = wrap_or_clamp(sx - 1, rows, toroidal)
            elseif d == 2
                ny = wrap_or_clamp(sy + 1, cols, toroidal)
            elseif d == 3
                nx = wrap_or_clamp(sx + 1, rows, toroidal)
            else
                ny = wrap_or_clamp(sy - 1, cols, toroidal)
            end
            # one-per-cell rule: only consider free target cells
            env.agent_map[nx, ny] == 0 || continue
            g = env.grass[nx, ny]
            if g > best_g
                best_g = g
                best_x = nx
                best_y = ny
            end
        end

        # If best is a different cell, move there + update agent_map +
        # eat at the new cell. The eat is necessary: the agent paid cost
        # to sample, the benefit must materialise this tick (otherwise
        # responsiveness is pure cost with no payoff and selection
        # destroys the trait + the population).
        if best_x != sx || best_y != sy
            env.agent_map[sx, sy]         = Int64(0)
            env.agent_map[best_x, best_y] = Int64(i)
            ag.x = Int32(best_x)
            ag.y = Int32(best_y)

            # Eat at the new cell (handling-time-limited intake, matching
            # tick.jl semantics). Body-size scaling: large agents extract
            # more per bite (matches tick.jl line 203).
            if env.grass[best_x, best_y] > 0.0f0
                bite = min(env.grass[best_x, best_y], max_bite)
                ag.energy = min(ag.energy + eat_gain * bite * ag.body_size,
                                energy_max * ag.body_size)
                env.grass[best_x, best_y] -= bite
            end
        end
    end
    nothing
end
