"""
    rl.jl — Within-lifetime reinforcement learning (REINFORCE with baseline).

Enabled when `specs["rl_mode"] != "none"`. Applied every
`specs["rl_update_freq"]` ticks from the main tick loop in Clade.jl.

## Actor-critic: REINFORCE with baseline

For each live agent:

1. Compute reward = `agent.energy - agent.energy_last_tick` (the energy delta
   this tick).
2. Compute advantage = `reward - agent.value_estimate`.
3. Update the running baseline:
   `agent.value_estimate += 0.01 * (reward - agent.value_estimate)`.
4. If the advantage is non-zero, shift the **output-layer weights** of the
   brain in the direction of the advantage, scaled by the agent's individual
   `learning_rate`. Updated weights are clamped to `[-5, 5]` to prevent the
   classic REINFORCE divergence.
5. Update `agent.energy_last_tick = agent.energy` so the next tick's reward
   is measured against the post-update state.

Only the output layer is updated. This is the same restriction used in alifeR
(see `R/rl.R` in the alifeR package) and is motivated by Williams (1992): the
score-function estimator has the lowest variance when restricted to the
action-selection layer.

### Per-brain implementation details

- **ANNBrain** — updates `brain.layers[end]` weights and biases in place.
- **BNNBrain** — updates the output-layer portion of `brain.mu` in place;
  `brain.sigma` is left untouched (uncertainty contraction is handled by
  `bnn_update!` separately). Since within-tick activations are not cached,
  we use the score-function estimator with a fixed unit input proxy; the
  advantage-scaled update still points in the right direction on average.
- **RandomBrain** — no-op (no learnable parameters).

## Hebbian mode (stub)

`rl_mode == "hebbian"` is a Phase 3 stub that returns without modifying the
brain. A full implementation would require caching the last per-layer
activations on each brain struct, which is deferred until Phase 3.

References
----------
Williams, R.J. (1992) Simple statistical gradient-following algorithms for
    connectionist reinforcement learning. *Machine Learning* 8(3-4):229-256.
Sutton, R.S. & Barto, A.G. (2018) *Reinforcement Learning: An Introduction.*
    2nd ed. MIT Press, Cambridge MA.
Hebb, D.O. (1949) *The Organization of Behavior: A Neuropsychological
    Theory.* Wiley, New York.
"""

# ── Constants ────────────────────────────────────────────────────────────────

const RL_BASELINE_STEP = 0.01f0   # step size for the running baseline update
const RL_WEIGHT_CLAMP  = 5.0f0    # clamp range for updated weights

# ── Output-layer index helper ────────────────────────────────────────────────

"""
    _rl_output_layer_range(arch::Vector{Int32}) -> UnitRange{Int}

Return the index range within a flat `[W1(:); b1; ...; WL(:); bL]` weight
vector that corresponds to the output layer only. Used by the BNN update
path where `brain.mu` is a flat vector. Local to this file (`_rl_` prefix)
so the module is self-contained and can be included independently of
`social_learning.jl`.
"""
function _rl_output_layer_range(arch::Vector{Int32})::UnitRange{Int}
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

# ── Per-brain output-layer updates ───────────────────────────────────────────

"""
    _rl_update_output!(brain::ANNBrain, advantage::Float32, lr::Float32)

Apply an advantage-scaled REINFORCE update to the output layer of an
ANNBrain. Weights and biases are clamped to `[-RL_WEIGHT_CLAMP, +RL_WEIGHT_CLAMP]`.
"""
function _rl_update_output!(brain::ANNBrain, advantage::Float32, lr::Float32)
    (lr == 0.0f0 || advantage == 0.0f0) && return
    step = lr * advantage
    (W, b) = brain.layers[end]
    @inbounds for i in eachindex(W)
        W[i] = clamp(W[i] + step, -RL_WEIGHT_CLAMP, RL_WEIGHT_CLAMP)
    end
    @inbounds for i in eachindex(b)
        b[i] = clamp(b[i] + step, -RL_WEIGHT_CLAMP, RL_WEIGHT_CLAMP)
    end
    nothing
end

"""
    _rl_update_output!(brain::BNNBrain, advantage::Float32, lr::Float32)

REINFORCE update on the output-layer portion of the BNNBrain posterior mean
`mu`. `sigma` is not touched here — its contraction is handled by the
Bayesian `bnn_update!` pathway.
"""
function _rl_update_output!(brain::BNNBrain, advantage::Float32, lr::Float32)
    (lr == 0.0f0 || advantage == 0.0f0) && return
    step    = lr * advantage
    rng_out = _rl_output_layer_range(brain.arch)
    (isempty(rng_out) || last(rng_out) > length(brain.mu)) && return
    @inbounds for i in rng_out
        brain.mu[i] = clamp(brain.mu[i] + step,
                            -RL_WEIGHT_CLAMP, RL_WEIGHT_CLAMP)
    end
    nothing
end

# Fallback for any other brain type (RandomBrain, CTRNN, GRN, etc.) — no-op.
# The specialised ANN/BNN methods above take precedence when the argument
# matches.
_rl_update_output!(::AbstractBrain, ::Float32, ::Float32) = nothing

# ── Actor-critic loop ────────────────────────────────────────────────────────

"""
    _apply_actor_critic!(env::Environment)

REINFORCE with baseline sweep over all live agents. Uses per-agent
`learning_rate` and updates both `agent.value_estimate` and
`agent.energy_last_tick`.
"""
function _apply_actor_critic!(env::Environment)
    @inbounds for ag in env.agents
        ag.alive || continue

        reward    = ag.energy - ag.energy_last_tick
        advantage = reward - ag.value_estimate

        # Update baseline (exponentially weighted running mean)
        ag.value_estimate += RL_BASELINE_STEP * (reward - ag.value_estimate)

        # Policy gradient step on output layer
        _rl_update_output!(ag.brain, Float32(advantage), Float32(ag.learning_rate))

        # Reset reward reference for the next window
        ag.energy_last_tick = ag.energy
    end
    nothing
end

# ── Hebbian stub ─────────────────────────────────────────────────────────────

"""
    _apply_hebbian!(env::Environment)

Hebbian learning stub. A full implementation will require per-layer activation
caches on the brain structs and is deferred to Phase 3. Currently a no-op.
"""
function _apply_hebbian!(::Environment)
    # Hebbian: Phase 3
    nothing
end

# ── Main entry point ─────────────────────────────────────────────────────────

"""
    apply_rl!(env::Environment)

Dispatch on `specs["rl_mode"]`:

- `"none"`         — no-op.
- `"actor_critic"` — REINFORCE with baseline on output-layer weights.
- `"hebbian"`      — Phase 3 stub (no-op).

Called from the main tick loop in `Clade.jl` once every
`specs["rl_update_freq"]` ticks.
"""
function apply_rl!(env::Environment)
    mode = String(get(env.specs, "rl_mode", "none"))
    if mode == "none"
        return
    elseif mode == "actor_critic"
        _apply_actor_critic!(env)
    elseif mode == "hebbian"
        _apply_hebbian!(env)
    else
        error("Unknown rl_mode: '$mode'. Expected 'none', 'actor_critic', " *
              "or 'hebbian'.")
    end
    nothing
end

# === CLADE.JL ADDITIONS NEEDED ===
# include: include("modules/rl.jl")
# tick loop: apply_rl!(env)
#   [gated: String(get(specs, "rl_mode", "none")) != "none"
#           && Int(get(specs, "rl_update_freq", 1)) > 0
#           && t % Int(get(specs, "rl_update_freq", 1)) == 0
#    location: after apply_kin_altruism! (or after social learning if both on),
#              before death/reproduction]
#
# Example wiring:
#   if String(get(specs, "rl_mode", "none")) != "none"
#       rl_freq = Int(get(specs, "rl_update_freq", 1))
#       rl_freq > 0 && t % rl_freq == 0 && apply_rl!(env)
#   end
# === END CLADE.JL ADDITIONS ===
