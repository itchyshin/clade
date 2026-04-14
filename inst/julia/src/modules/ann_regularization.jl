"""
    ann_regularization.jl — Energy penalty for ANN weight complexity.

Enabled when `specs["ann_regularization"] != "none"` (default `"none"`).
Applied once per tick after `apply_brain_size_evolution!` in the main loop.

## Modes

- `"weight_magnitude"` — penalty = lambda × Σ|w| over all weights and biases.
  Implements L1 regularisation: a continuous cost that shrinks every weight
  toward zero, producing sparse but not binary genomes. Analogous to LASSO
  in statistical models.

- `"weight_count"` — penalty = lambda × number of weights with |w| > threshold.
  Implements L0 regularisation: a fixed cost per active synapse regardless of
  magnitude. Stronger selection pressure for binary (on/off) synaptic patterns.

## Biological motivation

Synaptic maintenance is metabolically expensive (Laughlin et al. 1998;
Attwell & Laughlin 2001). Larger and more complex brains consume more energy,
creating a fitness trade-off between cognitive capacity and metabolic cost.
This module lets that trade-off operate on the evolved genome: agents with
unnecessarily large weights or many active synapses pay a per-tick energy
penalty, so selection drives the population toward parsimonious brains.

Combined with `brain_energy_mode = "activity"` (which penalises large
activations), this provides a richer model of neural metabolic cost than
activation cost alone.

Combined with `ann_weight_values` (discrete weights), weight_magnitude
regularisation reproduces the MATLAB `annRegularization = "weightMagnitude"`
condition from the alife2025usra codebase, enabling symbolic formula
distillation of evolved, sparse ANNs.

## References

Laughlin, S.B., de Ruyter van Steveninck, R.R. & Anderson, J.C. (1998)
    The metabolic cost of neural information. *Nature Neuroscience*
    1(1):36–41.
Attwell, D. & Laughlin, S.B. (2001) An energy budget for signaling in the
    grey matter of the brain. *Journal of Cerebral Blood Flow and Metabolism*
    21(10):1133–1145.
"""

const _REG_WEIGHT_THRESHOLD = 0.01f0   # weights below this are "inactive" (weight_count mode)

# ── Per-brain regularisation term ─────────────────────────────────────────────

"""
    _ann_weight_magnitude(brain) -> Float32

Sum of absolute values of all weights and biases. Returns 0 for unsupported
brain types.
"""
function _ann_weight_magnitude(brain::ANNBrain)::Float32
    s = 0.0f0
    @inbounds for (W, b) in brain.layers
        for x in W; s += abs(x); end
        for x in b; s += abs(x); end
    end
    s
end

function _ann_weight_magnitude(brain::BNNBrain)::Float32
    s = 0.0f0
    @inbounds for x in brain.mu; s += abs(x); end
    s
end

_ann_weight_magnitude(::AbstractBrain)::Float32 = 0.0f0

"""
    _ann_weight_count(brain) -> Float32

Count of weights with absolute value above `_REG_WEIGHT_THRESHOLD`.
"""
function _ann_weight_count(brain::ANNBrain)::Float32
    n = 0
    @inbounds for (W, b) in brain.layers
        for x in W; abs(x) > _REG_WEIGHT_THRESHOLD && (n += 1); end
        for x in b; abs(x) > _REG_WEIGHT_THRESHOLD && (n += 1); end
    end
    Float32(n)
end

function _ann_weight_count(brain::BNNBrain)::Float32
    Float32(count(x -> abs(x) > _REG_WEIGHT_THRESHOLD, brain.mu))
end

_ann_weight_count(::AbstractBrain)::Float32 = 0.0f0

# ── Main entry point ──────────────────────────────────────────────────────────

"""
    apply_ann_regularization!(env::Environment)

Deduct energy from each live agent proportional to the regularisation
term on its brain weights.

No-op when `specs["ann_regularization"] == "none"` (the default).
"""
function apply_ann_regularization!(env::Environment)
    mode = get(env.specs, "ann_regularization", "none")
    mode == "none" && return

    lambda   = Float32(get(env.specs, "ann_regularization_lambda", 0.001))
    lambda <= 0.0f0 && return
    e_min    = Float32(get(env.specs, "starvation_threshold", 0.0))

    @inbounds for ag in env.agents
        ag.alive || continue
        penalty = if mode == "weight_magnitude"
            lambda * _ann_weight_magnitude(ag.brain)
        elseif mode == "weight_count"
            lambda * _ann_weight_count(ag.brain)
        else
            0.0f0
        end
        ag.energy = max(ag.energy - penalty, e_min - 1.0f0)
        # Note: kill_dead! handles starvation; we only deduct energy here.
    end
    nothing
end
