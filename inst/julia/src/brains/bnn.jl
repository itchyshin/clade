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
    mu          ::Vector{Float32}   # posterior mean
    sigma       ::Vector{Float32}   # posterior std (> 0)
    arch        ::Vector{Int32}
    last_sample ::Vector{Float32}   # most recent Thompson-sampled weights,
                                    # used by bnn_update! for a correct
                                    # REINFORCE score w.r.t. the Gaussian
                                    # policy. Initialised empty; populated
                                    # by the first forward pass.
    # 0.4.0 Tier 5B: sampling cadence. Count of forward calls since
    # the last resample. When this reaches `bnn_sample_freq`, the
    # next forward() draws a fresh sample; otherwise reuses
    # last_sample. Per-tick resampling (freq = 1, legacy default)
    # washes out within-lifetime learning updates because each tick's
    # sample comes from a wide posterior; higher freq lets RL/social-
    # copying accumulate before resampling.
    ticks_since_sample ::Int32
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

    # 0.4.0 Tier 5A: sigma source is configurable.
    #   "heterozygosity" (default, legacy) — sigma = |mat - pat| / 2
    #   "fixed"                            — sigma = bnn_sigma_init for all
    #                                        weights, regardless of genome
    #   "trait"                            — sigma = TRAIT_PLASTICITY value
    #                                        from the genome. Requires
    #                                        phenotypic_plasticity = TRUE so
    #                                        the trait is evolved rather than
    #                                        pinned at 0.
    # The `"heterozygosity"` mode couples BNN width to genetic variance,
    # which makes sigma rise (not fall) under neutral mutation — the root
    # cause of the s-baldwin 🔴 verdict pre-0.4.0. The `"fixed"` and
    # `"trait"` modes decouple sigma from heterozygosity so Baldwin
    # canalization can be observed.
    sigma_source = String(get(specs, "bnn_sigma_source", "heterozygosity"))
    sigma_init   = Float32(get(specs, "bnn_sigma_init", 0.5))
    sigma_min    = Float32(get(specs, "bnn_sigma_min",  0.01))

    sigma = if sigma_source == "fixed"
        fill(sigma_init, n)
    elseif sigma_source == "trait"
        # TRAIT_PLASTICITY is index 10 in the scalar-traits vector
        # (see types.jl TRAIT_* constants). When phenotypic_plasticity
        # is off, the trait value is 0 → fall back to sigma_min.
        plast = is_haploid(g) ?
            g.maternal_traits[TRAIT_PLASTICITY] :
            0.5f0 * (g.maternal_traits[TRAIT_PLASTICITY] +
                     g.paternal_traits[TRAIT_PLASTICITY])
        fill(max(plast, sigma_min), n)
    else   # "heterozygosity" (default legacy)
        if is_haploid(g)
            fill(sigma_init, n)
        else
            s = abs.(g.maternal_weights .- g.paternal_weights) .* 0.5f0
            s .= max.(s, sigma_min)
            s
        end
    end

    # ticks_since_sample starts high so the first forward() resamples.
    BNNBrain(mu, sigma, g.architecture, Float32[], Int32(typemax(Int32)))
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
    # 0.4.0 Tier 5B: sample weights only every `sample_freq` forward calls.
    # With freq = 1 (legacy default), resample every tick — fresh Thompson
    # sampling each time. With freq > 1, cache the sample for that many
    # calls, allowing within-lifetime learning updates (RL, social copying)
    # to accumulate in mu/sigma before the next resample. Freq passed via
    # env specs at construction; read once per call via a module-level
    # hook (kept simple: check the sample_freq spec each call, default 1).
    # Reuse cached sample if available and we haven't hit the resample
    # boundary yet. ticks_since_sample starts at typemax(Int32) so the
    # first call always resamples.
    sample_freq = Int32(get(_bnn_freq_cache, :freq, Int32(1)))

    if isempty(brain.last_sample) ||
       length(brain.last_sample) != length(brain.mu) ||
       brain.ticks_since_sample >= sample_freq
        noise_scale = Float32(get(_bnn_action_noise_cache, :scale, 1.0f0))
        # 0.5.6: use the per-run RNG if one has been set via
        # _bnn_set_rng(env.rng). Falls back to Julia's default global
        # RNG otherwise (legacy behaviour). Without this, consecutive
        # run_alife() calls within one Julia session shared global
        # RNG state and produced non-deterministic trajectories even
        # with the random_seed spec set.
        rng = get(_bnn_rng_cache, :rng, nothing)
        z = if rng === nothing
            Float32.(randn(length(brain.mu)))
        else
            Float32.(randn(rng, length(brain.mu)))
        end
        w_sample = brain.mu .+ (noise_scale .* brain.sigma) .* z
        brain.last_sample = w_sample
        brain.ticks_since_sample = Int32(0)
    else
        brain.ticks_since_sample += Int32(1)
    end

    # Run sampled ANN forward (reuse ANNBrain infrastructure)
    sampled_ann = make_ann_brain(brain.last_sample, brain.arch)
    forward(sampled_ann, input)
end

# Tiny module-level cache to avoid plumbing `specs` through every forward
# call. Set once per tick_agents! entry via `_bnn_set_freq`.
const _bnn_freq_cache = Dict{Symbol,Int32}()
_bnn_set_freq(f::Integer) = (_bnn_freq_cache[:freq] = Int32(max(f, 1)); nothing)

# 0.5.5: action-noise scale for sigma decoupling. At scale=1.0 (default),
# weight samples are w = mu + sigma*z (legacy full coupling). At scale=0,
# actions are deterministic from mu; sigma only affects the learning/cost
# channel. Intermediate values give partial decoupling. Set once per
# tick_agents! entry via `_bnn_set_action_noise_scale`.
const _bnn_action_noise_cache = Dict{Symbol,Float32}()
_bnn_set_action_noise_scale(s::Real) = (_bnn_action_noise_cache[:scale] = Float32(clamp(s, 0, 1)); nothing)

# 0.5.6: per-run RNG cache for BNN Thompson sampling. Set at the
# start of tick_agents! to env.rng so that consecutive run_alife()
# calls don't share Julia's global RNG state through the BNN
# sampling path. Memory: project_rng_order_sensitivity.md.
const _bnn_rng_cache = Dict{Symbol,Any}()
_bnn_set_rng(rng) = (_bnn_rng_cache[:rng] = rng; nothing)
_bnn_clear_rng() = (delete!(_bnn_rng_cache, :rng); nothing)

# 0.5.6: Baldwin deeper lift — when scale > 0, the effective BNN
# learning rate in bnn_update! is mixed between the legacy rate and
# (lr × mean_sigma / sigma_ref). So a canalised (low-sigma) agent
# learns slowly, a plastic (high-sigma) agent learns fast. Makes
# the COST of canalisation sit on learning speed, not action noise.
# scale = 0 preserves legacy behaviour; scale = 1 means effective_lr
# is fully proportional to sigma/sigma_ref. Set from specs at the
# start of tick_agents!.
const _bnn_sigma_lr_cache = Dict{Symbol,Float32}()
_bnn_set_sigma_lr(scale::Real, sigma_ref::Real) = begin
    _bnn_sigma_lr_cache[:scale]     = Float32(clamp(scale, 0, 1))
    _bnn_sigma_lr_cache[:sigma_ref] = Float32(max(sigma_ref, 1.0f-6))
    nothing
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
    # Need a cached sample from the most recent forward pass to compute
    # the score function of the Gaussian policy. If forward has never run
    # (shouldn't happen in normal operation) fall back to no-op.
    isempty(brain.last_sample) && return
    length(brain.last_sample) == length(brain.mu) || return

    # 0.5.6: optional "sigma controls learning rate" mode. When
    # `bnn_sigma_lr_scale > 0`, the effective learning rate for THIS
    # agent's update is scaled by `mean(sigma) / sigma_ref`, where
    # sigma_ref is the initial BNN sigma (typically
    # plasticity_init_mean when bnn_sigma_source = "trait"). Low-sigma
    # (canalised) agents have low effective_lr → they don't update
    # much. High-sigma (plastic) agents learn fast. This creates the
    # Baldwin trade-off: stable envs select for low sigma (learning
    # is wasteful), variable envs select for high sigma (learning
    # pays). Default scale = 0 preserves legacy behaviour.
    lr_scale = Float32(get(_bnn_sigma_lr_cache, :scale, 0.0f0))
    sigma_ref = Float32(get(_bnn_sigma_lr_cache, :sigma_ref, 0.5f0))
    effective_lr = if lr_scale > 0.0f0
        mean_sigma = sum(brain.sigma) / Float32(length(brain.sigma))
        scale_factor = clamp(mean_sigma / max(sigma_ref, 1.0f-6),
                              0.0f0, 1.0f0)
        lr * (1.0f0 - lr_scale + lr_scale * scale_factor)
    else
        lr
    end
    effective_lr == 0.0f0 && return

    # REINFORCE (Williams 1992) with a Gaussian policy over weights
    # (Bayes-By-Backprop score function; Blundell et al. 2015 §3.2):
    #   d log N(w; mu, sigma) / d mu   = (w - mu) / sigma^2
    #   d log N(w; mu, sigma) / d sigma = ((w - mu)^2 - sigma^2) / sigma^3
    #
    # Update mu along the mean-score direction; contract sigma when the
    # sampled weight is further from the mean than the prior predicts
    # under the current advantage sign. The 0.1 damping on the sigma
    # step keeps the posterior contraction slow and stable across ticks.
    abs_adv = abs(advantage)
    @inbounds for i in eachindex(brain.mu)
        s2    = max(brain.sigma[i] * brain.sigma[i], 1.0f-6)
        delta = brain.last_sample[i] - brain.mu[i]
        brain.mu[i]    += effective_lr * advantage * delta / s2
        brain.sigma[i] *= max(0.01f0, 1.0f0 - effective_lr * abs_adv * 0.1f0)
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
    BNNBrain(new_mu, copy(brain.sigma), brain.arch, Float32[],
             Int32(typemax(Int32)))
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
    BNNBrain(new_mu, new_sigma, b1.arch, Float32[], Int32(typemax(Int32)))
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
