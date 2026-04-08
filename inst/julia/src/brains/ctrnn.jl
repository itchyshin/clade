"""
    brains/ctrnn.jl — Continuous-Time Recurrent Neural Network brain.

Unlike a feedforward MLP, a CTRNN has internal state — each neuron carries a
"charge" y_i that decays and is driven by the weighted sigmoidal outputs of
other neurons. This produces temporal dynamics: rhythmic behaviour,
sustained responses after inputs vanish, autonomous action initiation, and
genuine "memory" between ticks. These dynamics make CTRNNs a natural
substrate for evolving agents that must track hidden state or cyclic
environmental cues.

## Equations

Each of the n neurons has a real-valued internal state y_i. The continuous
dynamics (Beer 1995) are:

    τ_i * dy_i/dt = -y_i + Σ_j(w_ij * σ(y_j + θ_j)) + I_i

where τ_i > 0 is the time constant, w_ij is the synaptic weight from neuron
j to neuron i, θ_j is the bias of neuron j, σ(x) = 1/(1+exp(-x)) is the
standard logistic sigmoid, and I_i is the external input (non-zero only for
the input neurons).

For discrete simulation we use one Euler step per tick with Δt = 1:

    y_i(t+1) = y_i(t) + (1/τ_i) * (-y_i(t) + Σ_j(w_ij * σ(y_j(t) + θ_j)) + I_i(t))

The first `n_inputs` neurons receive sensory current; the last `n_outputs`
neurons are read out, squashed through sigmoid, and softmaxed to obtain
action probabilities.

## Genome encoding

The genome encodes only the fixed parameters — τ, W, θ — not the state y.
Layout of the flat weight vector (length = n + n*n + n):

    [tau(1:n); vec(W)_row_major; theta(1:n)]

Time constants are stored on the log scale so that mutation in ℝ maps to
ℝ⁺ after `exp`. They are additionally clamped to [0.1, 10.0] to guarantee
well-defined dynamics.

At birth the state y is initialised to zero. It evolves during the agent's
lifetime and is *not* inherited: offspring start from a blank slate.

## Reference

Beer, R.D. (1995) On the dynamics of small continuous-time recurrent neural
    networks. Adaptive Behavior 3(4):469–509.
"""

using Random: AbstractRNG, randn

# ── Struct ─────────────────────────────────────────────────────────────────────

"""
    CTRNNBrain <: AbstractBrain

Continuous-time recurrent neural network. The struct is mutable because the
internal state vector `y` is updated in place each tick.

Fields:
- `y::Vector{Float32}`       — current neuron states (length n_neurons).
- `tau::Vector{Float32}`     — positive time constants (length n_neurons).
- `W::Matrix{Float32}`       — recurrent weight matrix (n_neurons × n_neurons).
- `theta::Vector{Float32}`   — neuron biases (length n_neurons).
- `arch::Vector{Int32}`      — [n_inputs, n_neurons, n_outputs].
"""
mutable struct CTRNNBrain <: AbstractBrain
    y     ::Vector{Float32}
    tau   ::Vector{Float32}
    W     ::Matrix{Float32}
    theta ::Vector{Float32}
    arch  ::Vector{Int32}
end

n_inputs(b::CTRNNBrain)  = Int(b.arch[1])
n_actions(b::CTRNNBrain) = Int(b.arch[3])

# ── Parameter count ────────────────────────────────────────────────────────────

"""
    ctrnn_n_params(arch::Vector{Int32}) -> Int

Number of free parameters encoded in the genome for a CTRNN with the given
architecture `[n_inputs, n_neurons, n_outputs]`. Equals

    n_neurons + n_neurons^2 + n_neurons

(τ vector + recurrent weight matrix + bias vector). This is distinct from
the MLP formula in `arch_to_n_weights()`.
"""
function ctrnn_n_params(arch::Vector{Int32})::Int
    n = Int(arch[2])
    n + n * n + n
end

# ── Constructors ───────────────────────────────────────────────────────────────

"""
    make_ctrnn_brain(weights::Vector{Float32}, arch::Vector{Int32}) -> CTRNNBrain

Reconstruct a CTRNNBrain from a flat weight vector and architecture spec.
The weight vector is expected in the canonical layout

    [tau_raw(1:n); vec(W); theta(1:n)]

where `tau_raw` is exponentiated to ensure positivity and clamped to
[0.1, 10.0]. The state vector y is initialised to zero.

Errors if `length(weights) != ctrnn_n_params(arch)`.
"""
function make_ctrnn_brain(weights::Vector{Float32},
                           arch::Vector{Int32})::CTRNNBrain
    expected = ctrnn_n_params(arch)
    length(weights) == expected || error(
        "CTRNNBrain: weight vector length $(length(weights)) ≠ expected " *
        "$expected for arch $(arch)"
    )

    n = Int(arch[2])

    # τ: stored on the log scale, ensure strictly positive via exp, clamp to
    # a sensible biological range so the Euler step remains stable.
    tau_raw = weights[1:n]
    tau     = clamp.(exp.(tau_raw), 0.1f0, 10.0f0)

    # W: next n*n entries, interpreted row-major so W[i, j] is the weight
    # from neuron j to neuron i.
    W_flat = weights[n + 1 : n + n*n]
    W      = Matrix{Float32}(undef, n, n)
    @inbounds for i in 1:n, j in 1:n
        W[i, j] = W_flat[(i - 1) * n + j]
    end

    # θ: final n entries.
    theta = weights[n + n*n + 1 : n + n*n + n]

    y = zeros(Float32, n)

    CTRNNBrain(y, tau, W, theta, arch)
end

"""
    make_ctrnn_brain_from_genome(g::DiploidGenome, specs) -> CTRNNBrain

Express the genome phenotype and construct a CTRNNBrain. Uses the same
dominance model as ANN/BNN brains (additive by default).
"""
function make_ctrnn_brain_from_genome(g::DiploidGenome,
                                       specs::Dict{String,Any})::CTRNNBrain
    dm = get(specs, "dominance_model", "additive")
    w  = express_weights(g, dm)
    make_ctrnn_brain(w, g.architecture)
end

# ── Forward pass ───────────────────────────────────────────────────────────────

"""
    forward(brain::CTRNNBrain, input::Vector{Float32}) -> Vector{Float32}

Advance the CTRNN by one Euler step (Δt = 1) and return a softmax over the
last `n_actions(brain)` output neurons' sigmoidal activations. The internal
state `brain.y` is mutated in place — this is the source of temporal memory.

The sensory input is injected as an external current I_i into the first
`n_inputs(brain)` neurons; all other neurons see I_i = 0.
"""
function forward(brain::CTRNNBrain, input::Vector{Float32})::Vector{Float32}
    n     = length(brain.y)
    n_in  = n_inputs(brain)
    n_out = n_actions(brain)

    # Sigmoidal outputs of all neurons (evaluated at current state).
    out = Vector{Float32}(undef, n)
    @inbounds for j in 1:n
        out[j] = 1.0f0 / (1.0f0 + exp(-(brain.y[j] + brain.theta[j])))
    end

    # Recurrent drive: W * out
    drive = brain.W * out

    # External current: sensory input into first n_in neurons.
    # Guard against input vectors that are shorter than n_in (shouldn't
    # happen, but be defensive).
    n_inject = min(n_in, length(input))

    # Euler update y(t+1) = y(t) + (1/τ) * (-y(t) + drive + I).
    @inbounds for i in 1:n
        I_i = i <= n_inject ? input[i] : 0.0f0
        brain.y[i] += (1.0f0 / brain.tau[i]) *
                      (-brain.y[i] + drive[i] + I_i)
    end

    # Read out the last n_out neurons: sigmoid → softmax.
    out_logits = Vector{Float32}(undef, n_out)
    @inbounds for k in 1:n_out
        idx = n - n_out + k
        out_logits[k] = 1.0f0 / (1.0f0 + exp(-brain.y[idx]))
    end
    _softmax(out_logits)
end

# ── Mutation ───────────────────────────────────────────────────────────────────

"""
    mutate(brain::CTRNNBrain, mutation_sd::Float32, rng) -> CTRNNBrain

Return a new CTRNNBrain with Gaussian noise added to τ, W and θ. τ is
mutated on the log scale and then clamped to [0.1, 10.0] so that the Euler
integration remains stable. The state vector `y` is reset to zero (offspring
start fresh — see module docstring).
"""
function mutate(brain::CTRNNBrain, mutation_sd::Float32, rng)::CTRNNBrain
    n = length(brain.y)

    # Mutate τ on the log scale then exponentiate.
    log_tau_new = log.(brain.tau) .+
                  Float32.(mutation_sd .* randn(rng, n))
    new_tau     = clamp.(exp.(log_tau_new), 0.1f0, 10.0f0)

    new_W     = brain.W     .+ Float32.(mutation_sd .* randn(rng, size(brain.W)))
    new_theta = brain.theta .+ Float32.(mutation_sd .* randn(rng, n))

    CTRNNBrain(zeros(Float32, n), new_tau, new_W, new_theta, brain.arch)
end

# ── Crossover ──────────────────────────────────────────────────────────────────

"""
    crossover(b1::CTRNNBrain, b2::CTRNNBrain, crossover_points, rng) -> CTRNNBrain

Offspring CTRNNBrain produced by multi-point crossover on the flat weight
vector. Reuses `_crossover_vectors` (defined in ann.jl) to alternate between
parental haplotypes at each crossover point. The state vector y is reset to
zero in the offspring.
"""
function crossover(b1::CTRNNBrain, b2::CTRNNBrain,
                    crossover_points::Vector{Int}, rng)::CTRNNBrain
    w1 = flatten(b1)
    w2 = flatten(b2)
    offspring_w = _crossover_vectors(w1, w2, crossover_points)
    make_ctrnn_brain(offspring_w, b1.arch)
end

# ── Serialisation ──────────────────────────────────────────────────────────────

"""
    flatten(brain::CTRNNBrain) -> Vector{Float32}

Serialise the brain's genome-level parameters to a flat vector
`[log(tau); vec(W); theta]`. Uses log(tau) to match the genome encoding (the
constructor applies `exp` to recover τ). The ephemeral state y is NOT
included — it is not part of the heritable genome.
"""
function flatten(brain::CTRNNBrain)::Vector{Float32}
    n = length(brain.y)
    w = Vector{Float32}(undef, n + n*n + n)

    # log(tau) to round-trip through make_ctrnn_brain.
    @inbounds for i in 1:n
        w[i] = log(brain.tau[i])
    end
    # W row-major
    @inbounds for i in 1:n, j in 1:n
        w[n + (i - 1) * n + j] = brain.W[i, j]
    end
    # theta
    @inbounds for i in 1:n
        w[n + n*n + i] = brain.theta[i]
    end
    w
end

"""
    brain_size(brain::CTRNNBrain) -> Int

Total number of free parameters (τ + W + θ).
"""
brain_size(brain::CTRNNBrain) = ctrnn_n_params(brain.arch)
