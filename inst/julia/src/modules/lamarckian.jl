"""
    lamarckian.jl — Lamarckian inheritance: write learned brain weights back
    to the genome before meiosis so offspring directly inherit the parent's
    within-lifetime solution.

Enabled when `specs["lamarckian"] == true` AND `specs["rl_mode"] != "none"`.
Called from `create_offspring!` in reproduce.jl once per eligible parent,
immediately before `_make_offspring`.

## Biological motivation

Darwin's model: within-lifetime learning helps the individual survive but the
genome is unchanged — offspring must re-discover the solution from scratch.

The Baldwin Effect (Baldwin 1896; Hinton & Nowlan 1987) is the Darwinian
resolution: populations under selection converge on genomes that already
*look like* the learned solution, because individuals who are close to the
optimum without learning survive better. Learning guides selection indirectly.

Lamarck's model: the acquired characteristic (the learned weight values) is
written directly into the heritable material. Offspring start the search from
where the parent ended.

In most multicellular biology Lamarckian inheritance of neural connectivity is
prevented by the Weismann barrier (Weismann 1892) — the germline is isolated
from somatic changes. However:
  - It is debated whether this barrier is absolute (Jablonka & Lamb 2005).
  - In organisms with distributed nervous systems or clonal reproduction it
    may be weaker.
  - As a *theoretical condition* it provides the sharpest possible comparison
    for the Baldwin Effect experiment: Lamarckian inheritance should allow
    faster evolutionary convergence but reduce genetic diversity.

This implementation writes the **phenotypic** (post-RL) brain weights into
both maternal and paternal alleles of the parent genome before meiosis.
The `sigma` (uncertainty) of BNN brains is NOT written back: uncertainty is
an individual epistemic state, not a heritable characteristic.

## Interaction with epigenetics

The epigenetics module (epigenetics.jl) also implements a form of soft
transgenerational inheritance: methylation marks that record *which* loci were
plastically modified are partially inherited, causing canalization at those
loci in offspring. This is distinct from Lamarckian inheritance:

  - Epigenetics: inherits *which weights are canalized* (methylation pattern).
  - Lamarckian: inherits *the actual weight values* learned during lifetime.

Both can be active simultaneously. With both enabled, offspring inherit the
parent's learned weight values AND the canalization pattern that stabilises
them — a doubly-reinforced soft inheritance model.

## References

Baldwin, J.M. (1896) A new factor in evolution. *American Naturalist*
    30(354):441–451.
Hinton, G.E. & Nowlan, S.J. (1987) How learning can guide evolution.
    *Complex Systems* 1(3):495–502.
Jablonka, E. & Lamb, M.J. (2005) *Evolution in Four Dimensions.* MIT Press.
Weismann, A. (1892) *Das Keimplasma.* Gustav Fischer, Jena.
"""

# ─────────────────────────────────────────────────────────────────────────────
# Internal helpers
# ─────────────────────────────────────────────────────────────────────────────

"""
    _phenotype_weights(brain::ANNBrain) -> Vector{Float32}

Flatten all layer weights and biases into a single vector. Delegates to the
existing `flatten(::ANNBrain)` function defined in brains/ann.jl.
"""
_phenotype_weights(brain::ANNBrain)::Vector{Float32} = flatten(brain)

"""
    _phenotype_weights(brain::BNNBrain) -> Vector{Float32}

Return the posterior mean vector `brain.mu`. The sigma (uncertainty) is NOT
included: it is an individual epistemic state, not a learned characteristic.
"""
_phenotype_weights(brain::BNNBrain)::Vector{Float32} = copy(brain.mu)

# No-op for all other brain types (CTRNN, GRN, RandomBrain, etc.) — they
# either have no RL update or no flat weight representation.
_phenotype_weights(::AbstractBrain)::Vector{Float32} = Float32[]

# ─────────────────────────────────────────────────────────────────────────────
# Public entry point
# ─────────────────────────────────────────────────────────────────────────────

"""
    lamarck_genome_update!(ag::Agent)

Write the agent's current (RL-updated) brain phenotype back into its genome
so that meiosis operates on the learned solution rather than the original
genetic starting point.

For ANNBrain: flattens all layer (W, b) pairs → overwrites `maternal_weights`
  (and `paternal_weights` if diploid).
For BNNBrain: copies `brain.mu` → overwrites the weight portion of
  `maternal_weights` (and paternal). Length is min of phenotype and genome to
  guard against architecture mismatches.
Other brain types: no-op.

Only `*_weights` are modified; `*_traits` (body size, immune strength, etc.)
are unchanged.
"""
function lamarck_genome_update!(ag::Agent)
    pheno = _phenotype_weights(ag.brain)
    isempty(pheno) && return   # brain type has no RL-updatable weights

    g = ag.genome
    n = min(length(pheno), length(g.maternal_weights))
    n == 0 && return

    @inbounds for i in 1:n
        g.maternal_weights[i] = pheno[i]
    end

    # Diploid: also update paternal allele so offspring sample the learned
    # value from both copies during meiosis.
    if !is_haploid(g)
        np = min(length(pheno), length(g.paternal_weights))
        @inbounds for i in 1:np
            g.paternal_weights[i] = pheno[i]
        end
    end
    nothing
end
