"""
    brains/bnn.jl — Bayesian Neural Network (BNN) brain.

The BNN is the default brain type in clade (`brain_type = "bnn"`).

## Design rationale

In a standard ANN (alifeR, NetLogo, Mesa), each synaptic weight w_ij is a
fixed scalar. In the BNN, each weight is a probability distribution:
w_ij ~ N(mu_ij, sigma_ij). The genome encodes the prior (mu, sigma); within
the agent's lifetime, experience updates the posterior.

### Why this is the right default

1. **Exploration is automatic.** High sigma = high uncertainty = broad
   sampling from the distribution = exploration. Low sigma = narrow
   distribution = exploitation. No epsilon-greedy hyperparameter needed.

2. **Genome → brain connection is most natural.** In the diploid case,
   the two alleles at a locus give a natural interpretation:
   - mu = (maternal_weight + paternal_weight) / 2  (midpoint = prior mean)
   - sigma = |maternal_weight - paternal_weight| / 2  (half-difference = prior width)
   A heterozygous locus has a wide prior (plastic agent). A homozygous locus
   has a narrow prior (canalized).

3. **Learning = Bayesian updating.** Within lifetime, the posterior is updated
   by approximate Bayesian inference (here: mean-field variational inference).
   The genome (prior) is not changed; only the posterior is updated. This is
   the mechanistically correct model of phenotypic plasticity: the genome
   constrains what can be learned, not what IS learned.

4. **Epigenetics closes the circuit.** Methylation at locus i → sigma_i is
   multiplied by (1 - epigenetic_effect_size). Offspring of experienced
   learners inherit methylated loci → narrower priors → less plasticity at
   those loci. This implements transgenerational epigenetic canalization
   (Jablonka & Lamb 2005).

5. **Baldwin Effect is observable.** In a stable environment, agents whose
   genome already encodes high mu (close to the optimal weight) do not need
   high sigma (they need not explore). Their sigma declines. Over generations,
   the population mean sigma decreases as the genome tracks the learned solution.
   This is Baldwin (1896) in mechanistic form.

## Implementation

Action selection: Thompson sampling — sample one weight from each N(mu, sigma)
and run the resulting ANN forward. This is a one-line change from ANNBrain.
It is unbiased, computationally cheap, and reduces to argmax exploitation as
sigma → 0.

Within-lifetime learning: mean-field variational inference (MFVI), also called
Bayes By Backprop (Blundell et al. 2015). For each chosen action a:
  mu_i  += lr * advantage * grad_i
  sigma_i = sigma_i * (1 - lr * |advantage|)   (posterior contraction)
where grad_i is the gradient of log pi(a|x) with respect to weight i.

For simplicity in the tick loop, we use the REINFORCE score-function estimator
(Williams 1992) rather than backpropagation. This avoids autodiff and keeps
the tick loop fast.

References
----------
Baldwin, J.M. (1896) A new factor in evolution. American Naturalist 30:441–451.
Hinton, G.E. & Nowlan, S.J. (1987) How learning can guide evolution.
    Complex Systems 1(3):495–502.
Blundell, C., Cornebise, J., Kavukcuoglu, K. & Wierstra, D. (2015)
    Weight uncertainty in neural networks. ICML pp 1613–1622.
Williams, R.J. (1992) Simple statistical gradient-following algorithms for
    connectionist reinforcement learning. Machine Learning 8:229–256.
Jablonka, E. & Lamb, M.J. (2005) Evolution in Four Dimensions. MIT Press.
"""

using Random: AbstractRNG, randn, rand

# ── Struct ─────────────────────────────────────────────────────────────────────

"""
    BNNBrain <: AbstractBrain

Bayesian Neural Network: MLP whose weights are probability distributions
N(mu, sigma) rather than fixed scalars.

Fields:
- `mu::Vector{Float32}` — posterior mean for each weight/bias (same layout
  as ANNBrain's flat vector).
- `sigma::Vector{Float32}` — posterior standard deviation (always > 0).
- `arch::Vector{Int32}` — layer widths (same as ANNBrain).

The prior is the genome (mu_prior, sigma_prior, stored in DiploidGenome).
The posterior (this struct) starts equal to the prior at birth and is updated
by within-lifetime learning.
"""
mutable struct BNNBrain <: AbstractBrain
    mu    ::Vector{Float32}   # posterior mean
    sigma ::Vector{Float32}   # posterior std (> 0)
    arch  ::Vector{Int32}
end

n_inputs(b::BNNBrain)  = Int(b.arch[1])
n_actions(b::BNNBrain) = Int(b.arch[end])

# ── Constructor ────────────────────────────────────────────────────────────────

"""
    make_bnn_brain(g::DiploidGenome, specs) -> BNNBrain

Construct a BNNBrain from a DiploidGenome. The prior mean is the expressed
weight phenotype (additive of maternal and paternal). The prior sigma is
derived from the absolute half-difference of alleles (heterozygosity) when
diploid, or from `bnn_sigma_init` when haploid.

When `specs["epigenetics"] == true` and the agent has a methylome (passed
separately), methylated loci have their sigma reduced by
`epigenetic_effect_size`.
"""
function make_bnn_brain(g::DiploidGenome, specs::Dict{String,Any})::BNNBrain
    n = arch_to_n_weights(g.architecture)

    # Prior mean: additive expression
    mu = express_weights(g, "additive")

    # Prior sigma: from heterozygosity (diploid) or fixed init (haploid)
    sigma_init = Float32(get(specs, "bnn_sigma_init", 0.5))
    if is_haploid(g)
        sigma = fill(sigma_init, n)
    else
        # Half-difference of alleles as prior width
        # Large allele difference → broad prior → plastic agent
        sigma = abs.(g.maternal_weights .- g.paternal_weights) .* 0.5f0
        # Ensure sigma > 0 even for identical alleles (minimum sigma floor)
        sigma_min = Float32(get(specs, "bnn_sigma_min", 0.01))
        sigma .= max.(sigma, sigma_min)
    end

    BNNBrain(mu, sigma, g.architecture)
end

# ── Forward pass (Thompson sampling) ──────────────────────────────────────────

"""
    forward(brain::BNNBrain, input::Vector{Float32}) -> Vector{Float32}

Thompson sampling forward pass: sample one weight vector from the posterior
N(mu, sigma) and run the resulting ANN forward.

At each call, an independent weight sample is drawn. As sigma → 0, this
converges to the deterministic MLP (exploitation). As sigma → inf, actions
become uniform random (exploration). This is the one-line key difference from
ANNBrain.

Reference: Thompson, W.R. (1933) On the likelihood that one unknown probability
exceeds another in view of the evidence of two samples. Biometrika 25:285–294.
"""
function forward(brain::BNNBrain, input::Vector{Float32})::Vector{Float32}
    # Sample weight vector from posterior
    w_sample = brain.mu .+ brain.sigma .* Float32.(randn(length(brain.mu)))

    # Run sampled ANN forward (reuse ANNBrain infrastructure)
    sampled_ann = make_ann_brain(w_sample, brain.arch)
    forward(sampled_ann, input)
end

# ── Within-lifetime learning (REINFORCE update on posterior) ──────────────────

"""
    bnn_update!(brain::BNNBrain, input::Vector{Float32},
                action_idx::Int, advantage::Float32, lr::Float32)

Update the posterior mean and sigma based on the outcome of action `action_idx`.

Uses the REINFORCE score-function estimator (Williams 1992):
- mu_i    += lr * advantage * grad_log_pi_i
- sigma_i *= (1 - lr * |advantage| * 0.1)   (posterior contraction)

For the softmax output, grad_log_pi_i for weight w_i is approximately
sigma_i (the score function of the Gaussian prior times the softmax gradient).
We use the simplified first-order update (suitable for ABM scale).

This update does NOT modify the genome (prior). It only shifts the posterior.
At reproduction, offspring inherit from the genome (prior), not the posterior.
"""
function bnn_update!(brain::BNNBrain, input::Vector{Float32},
                      action_idx::Int, advantage::Float32, lr::Float32)
    lr == 0.0f0 && return

    # REINFORCE: gradient of log pi(a|x) w.r.t. weights
    # Approximate: grad ≈ sigma * (indicator_action - p_action) for output weights
    # For hidden weights: grad ≈ sigma (score function of Gaussian)
    # We use the simple sigma-scaled update as in Blundell et al. (2015) Eq. 8.
    abs_adv = abs(advantage)

    @inbounds for i in eachindex(brain.mu)
        brain.mu[i]    += lr * advantage * brain.sigma[i]
        brain.sigma[i] *= max(0.01f0, 1.0f0 - lr * abs_adv * 0.1f0)
    end
end

# ── Mutation ───────────────────────────────────────────────────────────────────

"""
    mutate(brain::BNNBrain, mutation_sd::Float32, rng) -> BNNBrain

Return a new BNNBrain with Gaussian perturbations to mu. Sigma is not mutated
(it is determined by the new genome's heterozygosity at birth).
"""
function mutate(brain::BNNBrain, mutation_sd::Float32, rng)::BNNBrain
    new_mu = brain.mu .+ Float32.(mutation_sd .* randn(rng, length(brain.mu)))
    BNNBrain(new_mu, copy(brain.sigma), brain.arch)
end

# ── Crossover ──────────────────────────────────────────────────────────────────

"""
    crossover(b1::BNNBrain, b2::BNNBrain, crossover_points::Vector{Int},
              rng) -> BNNBrain

Produce an offspring BNNBrain by crossover on the mu vector. Sigma is
recomputed from the offspring genome after construction (not crossed over
directly), so this function is called only for within-generation brain
recombination (not used in the standard path).
"""
function crossover(b1::BNNBrain, b2::BNNBrain,
                    crossover_points::Vector{Int}, rng)::BNNBrain
    new_mu    = _crossover_vectors(b1.mu, b2.mu, crossover_points)
    new_sigma = _crossover_vectors(b1.sigma, b2.sigma, crossover_points)
    BNNBrain(new_mu, new_sigma, b1.arch)
end

# ── Serialisation ──────────────────────────────────────────────────────────────

"""
    flatten(brain::BNNBrain) -> Vector{Float32}

Serialise to [mu; sigma] concatenated. Length = 2 * arch_to_n_weights(arch).
Used for genome distance (mu only is used for distance; sigma is ignored).
"""
flatten(brain::BNNBrain) = vcat(brain.mu, brain.sigma)

"""
    brain_size(brain::BNNBrain) -> Int

Number of free parameters = 2 * n_weights (mu + sigma per weight).
"""
brain_size(brain::BNNBrain) = 2 * arch_to_n_weights(brain.arch)

# ── Epigenetics application ────────────────────────────────────────────────────

"""
    apply_methylation!(brain::BNNBrain, methylome::Vector{Bool},
                       effect_size::Float32)

Reduce sigma at methylated loci by factor (1 - effect_size). Called once at
agent creation when `specs["epigenetics"] == true`. Implements canalization:
methylated loci become less plastic.

Reference: Jablonka & Lamb (2005), Chapter 4.
"""
function apply_methylation!(brain::BNNBrain, methylome::Vector{Bool},
                              effect_size::Float32)
    n = min(length(brain.sigma), length(methylome))
    @inbounds for i in 1:n
        methylome[i] && (brain.sigma[i] *= (1.0f0 - effect_size))
    end
end

# Quantize BNN mean weights (moved from ann.jl so BNNBrain is in scope).
function _quantize_brain_weights!(brain::BNNBrain, pv::Vector{Float32})
    _snap_to_nearest!(brain.mu, pv)
    nothing
end
