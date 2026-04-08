"""
    epigenetics.jl — Within-lifetime methylation and transgenerational
    epigenetic inheritance (TEI).

Enabled when `specs["epigenetics"] == true`. Each agent carries a
`methylome::Vector{Bool}` of length equal to the number of weights in its
brain (one Boolean mark per learnable parameter). Methylation marks are
laid down within an individual's lifetime as a function of recent learning
(reward), partially erased again by stochastic demethylation, and
transmitted across generations with probability `epigenetic_inheritance`.

For BNNBrain agents, the marks act on the posterior `sigma` vector via
`apply_methylation!()` from `brains/bnn.jl`: at each tick the per-locus
sigma is multiplied by `(1 - epigenetic_effect_size)` for every methylated
locus, narrowing the agent's exploration distribution at those weights.
The genome (the prior `mu`, `sigma`) is never touched: only the realised
phenotype is shifted, and only the methylome itself is heritable.

## Conceptual model

This module is the mechanistic core of the "fourth dimension" of evolution
(Jablonka & Lamb 2005): a non-genetic, partially heritable channel that
allows experience to bias the development of descendants without changing
DNA. Three biological observations motivate the implementation:

1. **Hebbian methylation.** Loci that participate in successful behaviour
   become methylated more often (cf. Meaney 2001 on rat maternal care
   shaping methylation of the GR promoter). The coupling here is
   reward-driven: when an agent's energy delta is positive, methylation is
   biased towards more marks; when negative, demethylation dominates.

2. **Lossy inheritance.** Empirical TEI rates are partial, not Mendelian.
   Each parental mark is passed to offspring with probability
   `epigenetic_inheritance` (default 0.5; Jablonka & Raz 2009 review
   estimates ranging from a few percent to ~50% across taxa).

3. **Canalization through plastic suppression.** A methylated locus is one
   where the variational posterior has been actively narrowed —
   exploration there is muted. Over generations, populations exposed to a
   stable environment accumulate methylation at loci that already encode
   adaptive priors, so per-population mean sigma drops. This is the
   mechanistic shadow of the Baldwin Effect (Baldwin 1896; Hinton & Nowlan
   1987): learning canalises into the inherited phenotype without ever
   touching the genome itself.

## Numerical details

- The methylation probability is scaled by `|reward| / mean_energy_scale`
  so that the per-locus probability remains bounded as reward magnitudes
  vary. `mean_energy_scale = max(specs["energy_init"], 1)` provides a
  reasonable units denominator.
- Demethylation is independent across loci with rate `demethylation_rate`,
  applied each tick to every methylated locus.
- The methylome is **lazy-initialised**: when `apply_epigenetics!` first
  encounters an agent with an empty methylome, it allocates a zero-filled
  vector matching `length(brain.sigma)`. This avoids touching every agent
  constructor when the module is off.
- Non-BNN brains are skipped: only BNNBrain has a meaningful sigma vector
  for `apply_methylation!` to act on. The methylome is still tracked
  (and inherited) on other brain types but never affects behaviour.

## References

Baldwin, J.M. (1896) A new factor in evolution. *American Naturalist*
    30(354):441–451.
Hinton, G.E. & Nowlan, S.J. (1987) How learning can guide evolution.
    *Complex Systems* 1(3):495–502.
Jablonka, E. & Lamb, M.J. (2005) *Evolution in Four Dimensions: Genetic,
    Epigenetic, Behavioral, and Symbolic Variation in the History of Life.*
    MIT Press, Cambridge MA.
Jablonka, E. & Raz, G. (2009) Transgenerational epigenetic inheritance:
    prevalence, mechanisms, and implications for the study of heredity and
    evolution. *Quarterly Review of Biology* 84(2):131–176.
Meaney, M.J. (2001) Maternal care, gene expression, and the transmission of
    individual differences in stress reactivity across generations.
    *Annual Review of Neuroscience* 24:1161–1192.
"""

# ── Per-agent methylome lifecycle ─────────────────────────────────────────────

"""
    init_methylome!(agent::Agent, specs::Dict{String,Any})

Allocate an all-`false` methylome on `agent` whose length matches the number
of free parameters in the agent's brain (`length(brain.sigma)` for a
BNNBrain, `brain_size(brain)` otherwise). No-op when the agent already has a
non-empty methylome of the correct length.

Called lazily by `apply_epigenetics!` so that the module is the only piece of
code that needs to know about methylome allocation. Founder and offspring
constructors leave the methylome empty (`Bool[]`).
"""
function init_methylome!(agent::Agent, specs::Dict{String,Any})
    n = if agent.brain isa BNNBrain
        length(agent.brain.sigma)
    else
        brain_size(agent.brain)
    end
    if length(agent.methylome) != n
        agent.methylome = falses(n)
    end
    return
end

"""
    update_methylome!(agent::Agent, reward::Float32,
                       specs::Dict{String,Any}, rng = default_rng())

Hebbian-style update of the methylome from a single tick of experience.

For every locus `i`:

- If currently unmethylated: methylate with probability
  `min(1, epigenetic_learning_coupling * max(reward, 0) / mean_energy_scale)
   + methylation_rate`.
- If currently methylated: demethylate with probability `demethylation_rate`.

The reward dependency is one-sided: only positive reward (energy gain)
drives methylation. Negative reward leaves the existing marks alone and
relies on the background demethylation rate to relax them. This implements
the Meaney (2001) intuition that "good" experiences lay down marks while
"bad" experiences let them decay.

The `methylation_rate` constant is added unconditionally so that even
reward-neutral agents accrue some background methylation, matching empirical
spontaneous methylation rates (Jablonka & Raz 2009).

`rng` defaults to the Julia global RNG only so that direct unit tests can
call the function without an environment in hand. Production callers always
pass `env.rng` so that seeded runs are reproducible.
"""
function update_methylome!(agent::Agent, reward::Float32,
                            specs::Dict{String,Any},
                            rng = default_rng())
    isempty(agent.methylome) && return
    n = length(agent.methylome)

    coupling = Float32(get(specs, "epigenetic_learning_coupling", 0.10))
    meth_bg  = Float32(get(specs, "methylation_rate",            0.001))
    demeth   = Float32(get(specs, "demethylation_rate",          0.002))

    energy_scale = max(Float32(get(specs, "energy_init", 100.0)), 1.0f0)

    pos_reward = reward > 0.0f0 ? reward : 0.0f0
    p_meth     = clamp(coupling * pos_reward / energy_scale + meth_bg,
                       0.0f0, 1.0f0)
    p_demeth   = clamp(demeth, 0.0f0, 1.0f0)

    @inbounds for i in 1:n
        if agent.methylome[i]
            if p_demeth > 0.0f0 && rand(rng) < p_demeth
                agent.methylome[i] = false
            end
        else
            if p_meth > 0.0f0 && rand(rng) < p_meth
                agent.methylome[i] = true
            end
        end
    end
    return
end

"""
    inherit_methylome!(offspring::Agent, parent::Agent,
                        specs::Dict{String,Any}, rng = default_rng())

Transgenerational epigenetic inheritance. For every locus `i` in
`parent.methylome`:

- `offspring.methylome[i] = parent.methylome[i] && (rand(rng) < epigenetic_inheritance)`

That is, an unmethylated parental locus is always unmethylated in the
offspring, and a methylated parental locus is inherited with probability
`epigenetic_inheritance`. The default 0.5 corresponds to the upper end of
empirically observed TEI rates in mammals (Jablonka & Raz 2009).

The offspring's methylome is allocated to match the parent's length. If the
parent has an empty methylome (e.g. on the first tick before
`apply_epigenetics!` has run), the offspring also receives an empty methylome
and will be lazy-initialised on its first tick.

`rng` defaults to the Julia global RNG so that direct unit tests can call
the function without an environment in hand. The standard wiring path
(`apply_epigenetic_inheritance!`) always passes `env.rng`.
"""
function inherit_methylome!(offspring::Agent, parent::Agent,
                             specs::Dict{String,Any},
                             rng = default_rng())
    n = length(parent.methylome)
    if n == 0
        offspring.methylome = Bool[]
        return
    end
    p_inherit = clamp(Float32(get(specs, "epigenetic_inheritance", 0.5)),
                      0.0f0, 1.0f0)
    new_meth = falses(n)
    @inbounds for i in 1:n
        if parent.methylome[i] && rand(rng) < p_inherit
            new_meth[i] = true
        end
    end
    offspring.methylome = new_meth
    return
end

# ── Public entry points ───────────────────────────────────────────────────────

"""
    apply_epigenetics!(env::Environment)

Main per-tick driver. No-op when `specs["epigenetics"] == false`.

For each live agent:

1. Lazy-initialise the methylome if missing (or sized incorrectly).
2. Compute reward = `agent.energy - agent.energy_last_tick` and call
   `update_methylome!`.
3. If the agent has a `BNNBrain`, apply the current methylome to the
   posterior `sigma` via `apply_methylation!`. The brain is mutated in
   place, so the canalization persists across subsequent forward passes.

Non-BNN agents have their methylome updated but no behavioural effect, so
that runs which switch brain types mid-experiment behave consistently.

This function does NOT touch `agent.energy_last_tick` — that field is
managed by the RL module (or set at agent creation). Reading it here gives
us the same per-tick energy delta the actor-critic uses, without coupling
the two modules.
"""
function apply_epigenetics!(env::Environment)
    specs = env.specs
    Bool(get(specs, "epigenetics", false)) || return

    effect_size = Float32(get(specs, "epigenetic_effect_size", 0.20))

    @inbounds for ag in env.agents
        ag.alive || continue

        init_methylome!(ag, specs)

        reward = ag.energy - ag.energy_last_tick
        update_methylome!(ag, Float32(reward), specs, env.rng)

        if ag.brain isa BNNBrain && !isempty(ag.methylome)
            apply_methylation!(ag.brain, ag.methylome, effect_size)
        end
    end
    return
end

"""
    apply_epigenetic_inheritance!(offspring::Agent, parent::Agent,
                                    specs::Dict{String,Any},
                                    rng = default_rng())

Wrapper around `inherit_methylome!` that gates on `specs["epigenetics"]`.
Called from `_make_offspring` immediately after the offspring `Agent` has
been constructed (which leaves the methylome empty by default). When
epigenetics is off, this is a no-op and the offspring keeps its empty
methylome. Pass `env.rng` from the wiring site so seeded runs reproduce.
"""
function apply_epigenetic_inheritance!(offspring::Agent, parent::Agent,
                                        specs::Dict{String,Any},
                                        rng = default_rng())
    Bool(get(specs, "epigenetics", false)) || return
    inherit_methylome!(offspring, parent, specs, rng)
    return
end

# === CLADE.JL ADDITIONS NEEDED ===
# include: include("modules/epigenetics.jl")
#   [add immediately after include("modules/niche.jl") in the modules block]
#
# tick loop: apply_epigenetics!(env)
#   [insert after apply_rl!(env) (when wired) and before kill_dead!(env);
#    in the current Clade.jl this means after apply_cooperation!(env)
#    and before kill_dead!(env)]
#
# reproduce.jl::_make_offspring:
#     apply_epigenetic_inheritance!(off, parent, specs, rng)
#   [insert immediately after the Agent(...) constructor that builds `off`
#    and before the function returns it. The local `parent::Agent` and
#    `rng` arguments of `_make_offspring` are exactly what is needed.
#    Pass `rng` so seeded runs are reproducible.]
#
# Note: apply_epigenetics! and apply_epigenetic_inheritance! are both
#       no-ops when specs["epigenetics"] == false, so wiring them
#       unconditionally is safe.
# === END CLADE.JL ADDITIONS ===
