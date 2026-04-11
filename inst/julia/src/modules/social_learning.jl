"""
    social_learning.jl — Prestige-biased copying of output-layer weights.

Enabled when `specs["social_learning"] == true`. Applied every
`specs["social_learning_freq"]` ticks from the main tick loop in Clade.jl.

## Design

Each live focal agent scans its 8-cell Moore neighbourhood (toroidal wrap).
If at least one neighbour has strictly higher energy, the focal agent blends
a fraction of that model's output-layer weights into its own:

    new_w = (1 - rate) * own_w + rate * model_w

where `rate = specs["social_learning_rate"]`. The model is always the
highest-energy neighbour (prestige bias; Henrich & Gil-White 2001). Ties are
broken by first occurrence in the scan order.

Only the **output layer** is copied. This is both biologically reasonable
(action-selection policy, rather than perceptual features, is what is
observably copied in animal experiments) and computationally cheap. For
ANNBrain this is `brain.layers[end]`; for BNNBrain it is the last
`n_out * n_hidden` elements of `brain.mu` (plus the `n_out` output biases).

Social learning updates the **within-lifetime phenotype** only: the genome
(maternal and paternal weight vectors in `DiploidGenome`) is untouched, so
offspring inherit the parent's genotype, not its socially learned weights.
This keeps the Baldwin Effect pathway open without collapsing into direct
Lamarckian inheritance.

Laland (2004) distinguishes copying-when-uninformed, copying-when-dissatisfied,
copying-the-majority, and copying-successful-individuals. We implement the
last (copy successful individuals) because it is the strategy best supported
by empirical work on primates and fish.

References
----------
Laland, K.N. (2004) Social learning strategies. *Learning and Behavior*
    32(1):4-14.
Henrich, J. & Gil-White, F.J. (2001) The evolution of prestige: freely
    conferred deference as a mechanism for enhancing the benefits of cultural
    transmission. *Evolution and Human Behavior* 22(3):165-196.
Rendell, L. et al. (2010) Why copy others? Insights from the social learning
    strategies tournament. *Science* 328(5975):208-213.
"""

# ── Output-layer access ──────────────────────────────────────────────────────

"""
    _sl_output_layer_range(arch::Vector{Int32}) -> UnitRange{Int}

Return the index range within a flat `[W1(:); b1; W2(:); b2; ...; WL(:); bL]`
weight vector that corresponds to the **output layer only** (`WL(:); bL`).
Used by the BNN path where `brain.mu` is a single flat vector. Local to this
file (`_sl_` prefix) so that each module is self-contained and can be
included independently.
"""
function _sl_output_layer_range(arch::Vector{Int32})::UnitRange{Int}
    n_layers = length(arch) - 1
    n_layers < 1 && return 1:0
    pos = 1
    for i in 1:(n_layers - 1)
        n_in  = Int(arch[i])
        n_out = Int(arch[i + 1])
        pos  += n_in * n_out + n_out
    end
    n_in_last  = Int(arch[end - 1])
    n_out_last = Int(arch[end])
    last_len   = n_in_last * n_out_last + n_out_last
    return pos:(pos + last_len - 1)
end

# ── Per-brain copy ───────────────────────────────────────────────────────────

"""
    _copy_output_layer!(learner::ANNBrain, model::ANNBrain, rate::Float32)

Blend the last (output) layer of `model` into `learner` in place:

    W_learner = (1 - rate) * W_learner + rate * W_model
    b_learner = (1 - rate) * b_learner + rate * b_model

Assumes matching architectures. Silently returns when architectures differ.
"""
function _copy_output_layer!(learner::ANNBrain, model::ANNBrain, rate::Float32)
    learner.arch == model.arch || return
    (W_l, b_l) = learner.layers[end]
    (W_m, b_m) = model.layers[end]
    @inbounds for i in eachindex(W_l)
        W_l[i] = (1.0f0 - rate) * W_l[i] + rate * W_m[i]
    end
    @inbounds for i in eachindex(b_l)
        b_l[i] = (1.0f0 - rate) * b_l[i] + rate * b_m[i]
    end
    nothing
end

"""
    _copy_output_layer!(learner::BNNBrain, model::BNNBrain, rate::Float32)

Blend the output-layer portion of the posterior mean `mu` from `model` into
`learner`. Sigma is not copied: uncertainty is an individual state, not a
cultural trait. Assumes matching architectures.
"""
function _copy_output_layer!(learner::BNNBrain, model::BNNBrain, rate::Float32)
    learner.arch == model.arch || return
    rng_out = _sl_output_layer_range(learner.arch)
    (isempty(rng_out) || last(rng_out) > length(learner.mu)) && return
    @inbounds for i in rng_out
        learner.mu[i] = (1.0f0 - rate) * learner.mu[i] + rate * model.mu[i]
    end
    nothing
end

# Fallback for any other brain type (RandomBrain, CTRNN, GRN, heterogeneous
# pairs, etc.) — no-op. The specialised ANN/BNN methods above take precedence
# when both arguments match.
_copy_output_layer!(::AbstractBrain, ::AbstractBrain, ::Float32) = nothing

# ── Main entry point ─────────────────────────────────────────────────────────

"""
    apply_social_learning!(env::Environment)

Run one round of prestige-biased social learning for all live agents.

For each focal agent, scan the 8-neighbour Moore block (toroidal wrap) for
the live neighbour with the highest energy strictly greater than the focal's
own energy. If one exists, blend a fraction `social_learning_rate` of that
neighbour's output-layer weights into the focal brain.

Does nothing when `specs["social_learning"] == false`. Modifies brains in
place; the genome is untouched.
"""
function apply_social_learning!(env::Environment)
    Bool(get(env.specs, "social_learning", false)) || return

    rate = Float32(get(env.specs, "social_learning_rate", 0.1))
    rate <= 0.0f0 && return

    rows     = Int(env.specs["grid_rows"])
    cols     = Int(env.specs["grid_cols"])
    toroidal = Bool(get(env.specs, "toroidal", true))

    n = length(env.agents)
    n == 0 && return

    @inbounds for focal in env.agents
        focal.alive || continue
        fx, fy = Int(focal.x), Int(focal.y)

        best_e   = focal.energy
        best_idx = 0
        for dx in -1:1, dy in -1:1
            (dx == 0 && dy == 0) && continue
            nx = wrap_or_clamp(fx + dx, rows, toroidal)
            ny = wrap_or_clamp(fy + dy, cols, toroidal)
            m  = env.agent_map[nx, ny]
            m == 0 && continue
            nb = env.agents[m]
            nb.alive || continue
            if nb.energy > best_e
                best_e   = nb.energy
                best_idx = m
            end
        end

        if best_idx != 0
            model = env.agents[best_idx]
            _copy_output_layer!(focal.brain, model.brain, rate)
        end
    end
    nothing
end

# === CLADE.JL ADDITIONS NEEDED ===
# include: include("modules/social_learning.jl")
# tick loop: apply_social_learning!(env)
#   [gated: Bool(get(specs, "social_learning", false))
#           && Int(get(specs, "social_learning_freq", 10)) > 0
#           && t % Int(get(specs, "social_learning_freq", 10)) == 0
#    location: after apply_kin_altruism!, before death/reproduction]
#
# Example wiring:
#   if Bool(get(specs, "social_learning", false))
#       sl_freq = Int(get(specs, "social_learning_freq", 10))
#       sl_freq > 0 && t % sl_freq == 0 && apply_social_learning!(env)
#   end
# === END CLADE.JL ADDITIONS ===
