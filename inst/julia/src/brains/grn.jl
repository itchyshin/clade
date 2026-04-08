"""
    brains/grn.jl — Gene Regulatory Network brain.

The GRN is the most biologically parsimonious brain type in clade: there is
no separate "neural network" layer — the genome IS the brain. Each locus
represents a gene whose expression level is regulated by every other gene
through a dense interaction matrix W. Behaviour emerges from the collective
dynamics of these regulatory interactions.

## Design

An agent with `n_genes` has a gene-expression state vector
`g ∈ (0, 1)^n_genes`. Each tick:

    g_new[i] = σ( Σ_j(W[i, j] * g[j]) + I_i )

where σ is the logistic sigmoid and I_i is the sensory input received by
gene i (non-zero only for the first `n_inputs` "sensory" genes). This is a
discrete-time analogue of a Kauffman-style random Boolean network with
sigmoidal activation (Kauffman 1993).

The last `n_outputs` genes are designated action genes; a softmax over
their expression levels gives the action distribution.

## Genome encoding

The regulatory matrix W is the only heritable parameter. Its entries are
stored row-major so that `W[i, j]` (the influence of gene j on gene i) lies
at linear index `(i - 1) * n_genes + j`. Total genome size is n_genes^2,
which is unrelated to the MLP formula in `arch_to_n_weights()`.

## Ploidy

When the genome is diploid, maternal and paternal matrices are combined by
`express_weights()` (additive dominance by default) *before* the GRNBrain
struct is built. This means the expressed W is already the midpoint
(W_mat + W_pat)/2, matching classical additive genetics. Epigenetic
(methylation) effects are handled at the BNN level and do not apply to GRN
in this implementation; a methylated gene can be supported in the future by
scaling row i of W by `(1 - epigenetic_effect_size)` in
`apply_methylation!`.

## State initialisation

Gene expression starts at 0.5 (maximum-entropy prior — each gene is equally
likely to be on or off at birth). As in the CTRNN, the state vector is
ephemeral and is not inherited.

## References

Kauffman, S.A. (1993) The Origins of Order: Self-Organization and Selection
    in Evolution. Oxford University Press.
Watson, R.A. & Szathmáry, E. (2016) How can evolution learn? Trends in
    Ecology and Evolution 31(2):147–157.
"""

using Random: AbstractRNG, randn

# ── Struct ─────────────────────────────────────────────────────────────────────

"""
    GRNBrain <: AbstractBrain

Kauffman-style gene regulatory network. Mutable because `g` is updated in
place each tick.

Fields:
- `g::Vector{Float32}`  — current gene expression levels in (0, 1)
                           (length n_genes).
- `W::Matrix{Float32}`  — regulatory weight matrix, n_genes × n_genes.
                           `W[i, j]` is the influence of gene j on gene i.
- `arch::Vector{Int32}` — [n_inputs, n_genes, n_outputs]. The first n_inputs
                           genes receive sensory input; the last n_outputs
                           genes drive behaviour.
"""
mutable struct GRNBrain <: AbstractBrain
    g    ::Vector{Float32}
    W    ::Matrix{Float32}
    arch ::Vector{Int32}
end

n_inputs(b::GRNBrain)  = Int(b.arch[1])
n_actions(b::GRNBrain) = Int(b.arch[3])

"""
    n_genes(b::GRNBrain) -> Int

Number of regulatory genes encoded in this brain (middle entry of `arch`).
"""
n_genes(b::GRNBrain) = Int(b.arch[2])

# ── Parameter count ────────────────────────────────────────────────────────────

"""
    grn_n_params(arch::Vector{Int32}) -> Int

Number of free parameters in the genome for a GRN brain. Equals
`n_genes^2` — the entries of the regulatory matrix W. Distinct from the
MLP formula in `arch_to_n_weights()`.
"""
function grn_n_params(arch::Vector{Int32})::Int
    n = Int(arch[2])
    n * n
end

# ── Constructors ───────────────────────────────────────────────────────────────

"""
    make_grn_brain(weights::Vector{Float32}, arch::Vector{Int32}) -> GRNBrain

Reconstruct a GRNBrain from a flat weight vector and architecture spec. The
weight vector is interpreted row-major so that `weights[(i-1)*n + j]` is
W[i, j]. Gene expression state is initialised to 0.5 for every gene.

Errors if `length(weights) != grn_n_params(arch)`.
"""
function make_grn_brain(weights::Vector{Float32},
                         arch::Vector{Int32})::GRNBrain
    expected = grn_n_params(arch)
    length(weights) == expected || error(
        "GRNBrain: weight vector length $(length(weights)) ≠ expected " *
        "$expected for arch $(arch)"
    )

    n = Int(arch[2])
    W = Matrix{Float32}(undef, n, n)
    @inbounds for i in 1:n, j in 1:n
        W[i, j] = weights[(i - 1) * n + j]
    end

    g = fill(0.5f0, n)   # maximum-entropy initialisation
    GRNBrain(g, W, arch)
end

"""
    make_grn_brain_from_genome(g::DiploidGenome, specs) -> GRNBrain

Express the genome phenotype and construct a GRNBrain. The diploid
combination is handled by `express_weights()` (additive by default) — the
GRN receives an already-averaged weight vector.
"""
function make_grn_brain_from_genome(g::DiploidGenome,
                                     specs::Dict{String,Any})::GRNBrain
    dm = get(specs, "dominance_model", "additive")
    w  = express_weights(g, dm)
    make_grn_brain(w, g.architecture)
end

# ── Forward pass ───────────────────────────────────────────────────────────────

"""
    forward(brain::GRNBrain, input::Vector{Float32}) -> Vector{Float32}

Advance the regulatory network by one discrete step and return a softmax
over the expression levels of the last `n_actions(brain)` genes. The
sensory input is injected additively into the pre-activation of the first
`n_inputs(brain)` genes. `brain.g` is mutated in place.
"""
function forward(brain::GRNBrain, input::Vector{Float32})::Vector{Float32}
    n     = length(brain.g)
    n_in  = n_inputs(brain)
    n_out = n_actions(brain)

    # Regulatory drive for every gene.
    drive = brain.W * brain.g

    # Inject sensory input into the first n_in genes.
    n_inject = min(n_in, length(input))
    @inbounds for i in 1:n_inject
        drive[i] += input[i]
    end

    # Sigmoidal update of expression levels.
    @inbounds for i in 1:n
        brain.g[i] = 1.0f0 / (1.0f0 + exp(-drive[i]))
    end

    # Softmax over the last n_out action genes.
    out_logits = Vector{Float32}(undef, n_out)
    @inbounds for k in 1:n_out
        out_logits[k] = brain.g[n - n_out + k]
    end
    _softmax(out_logits)
end

# ── Mutation ───────────────────────────────────────────────────────────────────

"""
    mutate(brain::GRNBrain, mutation_sd::Float32, rng) -> GRNBrain

Return a new GRNBrain with Gaussian noise added to every entry of W. Gene
expression state is reset to 0.5 in the offspring.
"""
function mutate(brain::GRNBrain, mutation_sd::Float32, rng)::GRNBrain
    new_W = brain.W .+ Float32.(mutation_sd .* randn(rng, size(brain.W)))
    GRNBrain(fill(0.5f0, length(brain.g)), new_W, brain.arch)
end

# ── Crossover ──────────────────────────────────────────────────────────────────

"""
    crossover(b1::GRNBrain, b2::GRNBrain, crossover_points, rng) -> GRNBrain

Offspring GRNBrain produced by multi-point crossover on the flat W vector.
Reuses `_crossover_vectors` (defined in ann.jl).
"""
function crossover(b1::GRNBrain, b2::GRNBrain,
                    crossover_points::Vector{Int}, rng)::GRNBrain
    w1 = flatten(b1)
    w2 = flatten(b2)
    offspring_w = _crossover_vectors(w1, w2, crossover_points)
    make_grn_brain(offspring_w, b1.arch)
end

# ── Serialisation ──────────────────────────────────────────────────────────────

"""
    flatten(brain::GRNBrain) -> Vector{Float32}

Serialise the regulatory matrix to a flat row-major vector. Gene expression
state is NOT included (it is ephemeral, not heritable).
"""
function flatten(brain::GRNBrain)::Vector{Float32}
    n = length(brain.g)
    w = Vector{Float32}(undef, n * n)
    @inbounds for i in 1:n, j in 1:n
        w[(i - 1) * n + j] = brain.W[i, j]
    end
    w
end

"""
    brain_size(brain::GRNBrain) -> Int

Number of free parameters = n_genes^2.
"""
brain_size(brain::GRNBrain) = n_genes(brain)^2
