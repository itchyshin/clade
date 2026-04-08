"""
    brains/ann.jl — Multilayer Perceptron (ANN) brain.

Standard feedforward neural network with tanh hidden activations and softmax
output. This is the alifeR-compatible brain type (`brain_type = "ann"`).

Architecture
------------
A network with specification arch = [n0, n1, ..., nL] has:
  - Input layer:  n0 units (sensory inputs)
  - Hidden layers: n1, ..., n(L-1) units (tanh activation)
  - Output layer: nL units (softmax → action probabilities)

Genome encoding
---------------
Weights and biases are stored row-major in a single flat vector:
  [W1(:), b1, W2(:), b2, ..., WL(:), bL]
where W_i is the weight matrix (n_{i} × n_{i-1}) and b_i is the bias vector
(n_i). This matches the alifeR ANN format (flattened column-major in R, but
row-major here for cache-friendliness in Julia).

References
----------
Rumelhart, D.E., Hinton, G.E. & Williams, R.J. (1986) Learning representations
    by back-propagating errors. Nature 323:533–536.
LeCun, Y., Bengio, Y. & Hinton, G.E. (2015) Deep learning.
    Nature 521:436–444.
"""

# ── Struct ─────────────────────────────────────────────────────────────────────

"""
    ANNBrain <: AbstractBrain

Multilayer perceptron with tanh hidden activations and softmax output.

Fields:
- `layers::Vector{Tuple{Matrix{Float32}, Vector{Float32}}}` — one (W, b) pair
  per layer. W has shape (n_out × n_in); b has length n_out.
- `arch::Vector{Int32}` — layer widths including input and output.
"""
struct ANNBrain <: AbstractBrain
    layers ::Vector{Tuple{Matrix{Float32}, Vector{Float32}}}
    arch   ::Vector{Int32}
end

n_inputs(b::ANNBrain)  = Int(b.arch[1])
n_actions(b::ANNBrain) = Int(b.arch[end])

# ── Constructor ────────────────────────────────────────────────────────────────

"""
    make_ann_brain(weights::Vector{Float32}, arch::Vector{Int32}) -> ANNBrain

Reconstruct an ANNBrain from a flat weight vector and architecture spec.
Raises an error if `length(weights) != arch_to_n_weights(arch)`.
"""
function make_ann_brain(weights::Vector{Float32}, arch::Vector{Int32})::ANNBrain
    expected = arch_to_n_weights(arch)
    length(weights) == expected || error(
        "ANNBrain: weight vector length $(length(weights)) ≠ expected $expected " *
        "for arch $(arch)"
    )

    layers = Vector{Tuple{Matrix{Float32}, Vector{Float32}}}(undef, length(arch) - 1)
    pos = 1
    for i in 1:length(arch)-1
        n_in  = Int(arch[i])
        n_out = Int(arch[i+1])
        W = reshape(weights[pos : pos + n_in*n_out - 1], n_out, n_in)
        pos += n_in * n_out
        b = weights[pos : pos + n_out - 1]
        pos += n_out
        layers[i] = (W, b)
    end
    ANNBrain(layers, arch)
end

"""
    make_ann_brain_from_genome(g::DiploidGenome, specs) -> ANNBrain

Express the genome phenotype and construct an ANNBrain.
"""
function make_ann_brain_from_genome(g::DiploidGenome,
                                     specs::Dict{String,Any})::ANNBrain
    dm = get(specs, "dominance_model", "additive")
    w  = express_weights(g, dm)
    make_ann_brain(w, g.architecture)
end

# ── Forward pass ───────────────────────────────────────────────────────────────

"""
    forward(brain::ANNBrain, input::Vector{Float32}) -> Vector{Float32}

Compute the forward pass of the ANN. Hidden layers use tanh; the output
layer returns softmax probabilities over actions.

Returns a vector of length `n_actions(brain)`.
"""
function forward(brain::ANNBrain, input::Vector{Float32})::Vector{Float32}
    x = input
    n_layers = length(brain.layers)
    for (i, (W, b)) in enumerate(brain.layers)
        x = W * x .+ b
        if i < n_layers
            x = tanh.(x)   # hidden layers: tanh
        else
            x = _softmax(x) # output: softmax
        end
    end
    x
end

# ── Mutation ───────────────────────────────────────────────────────────────────

"""
    mutate(brain::ANNBrain, mutation_sd::Float32, rng) -> ANNBrain

Return a new ANNBrain with Gaussian noise N(0, mutation_sd) added to each
weight and bias independently.
"""
function mutate(brain::ANNBrain, mutation_sd::Float32, rng)::ANNBrain
    new_layers = map(brain.layers) do (W, b)
        (W .+ Float32.(mutation_sd .* randn(rng, size(W))),
         b .+ Float32.(mutation_sd .* randn(rng, length(b))))
    end
    ANNBrain(new_layers, brain.arch)
end

# ── Crossover ──────────────────────────────────────────────────────────────────

"""
    crossover(b1::ANNBrain, b2::ANNBrain, crossover_points::Vector{Int},
              rng) -> ANNBrain

Produce an offspring brain by single- or multi-point crossover on the flat
weight vector. `crossover_points` is a sorted vector of indices in
`1:brain_size(b1)`; the template alternates between `b1` and `b2` at each
point. When `crossover_points` is empty, the offspring is a copy of `b1`.
"""
function crossover(b1::ANNBrain, b2::ANNBrain,
                    crossover_points::Vector{Int}, rng)::ANNBrain
    w1 = flatten(b1)
    w2 = flatten(b2)
    offspring_w = _crossover_vectors(w1, w2, crossover_points)
    make_ann_brain(offspring_w, b1.arch)
end

# ── Serialisation ──────────────────────────────────────────────────────────────

"""
    flatten(brain::ANNBrain) -> Vector{Float32}

Serialise the brain to a flat weight vector (same layout as the genome).
Used for genome distance and diversity calculations.
"""
function flatten(brain::ANNBrain)::Vector{Float32}
    n = arch_to_n_weights(brain.arch)
    w = Vector{Float32}(undef, n)
    pos = 1
    for (W, b) in brain.layers
        n_el = length(W)
        w[pos : pos + n_el - 1] = vec(W)
        pos += n_el
        n_b = length(b)
        w[pos : pos + n_b - 1] = b
        pos += n_b
    end
    w
end

"""
    brain_size(brain::ANNBrain) -> Int

Total number of free parameters (weights + biases).
"""
brain_size(brain::ANNBrain) = arch_to_n_weights(brain.arch)

# ── Softmax ────────────────────────────────────────────────────────────────────

"""
    _softmax(x::Vector{Float32}) -> Vector{Float32}

Numerically stable softmax. Subtracts the maximum before exponentiation to
prevent overflow.
"""
function _softmax(x::Vector{Float32})::Vector{Float32}
    m  = maximum(x)
    ex = exp.(x .- m)
    ex ./ sum(ex)
end

# ── Crossover helper (shared with other brain types) ──────────────────────────

"""
    _crossover_vectors(w1, w2, xpts) -> Vector{Float32}

Produce a recombinant vector from `w1` and `w2` by alternating at each
crossover point in the sorted vector `xpts`.
"""
function _crossover_vectors(w1::Vector{Float32}, w2::Vector{Float32},
                              xpts::Vector{Int})::Vector{Float32}
    n  = length(w1)
    out = copy(w1)
    using_w1 = true
    pos = 1
    for xp in xpts
        xp = clamp(xp, 1, n)
        out[pos:xp] = using_w1 ? w1[pos:xp] : w2[pos:xp]
        pos = xp + 1
        using_w1 = !using_w1
    end
    if pos <= n
        out[pos:n] = using_w1 ? w1[pos:n] : w2[pos:n]
    end
    out
end
