# Critical Biology-and-Numerics Audit: Brain Modules and Learning Rules

## Summary

This audit examines the neural and epigenetic implementations in clade's core brain modules (ANN, BNN, CTRNN, GRN) and their learning drivers (RL, epigenetics). **One critical math error was found** in BNN's REINFORCE update; three **subtle high-variance issues** affect learning efficiency; one **conceptual-but-unvalidated design** (heterozygosity→sigma) shapes the entire plasticity mechanism.

---

## Critical Issues (Biology-Breaking)

### 1. **BNN REINFORCE Update: Biased Score Function** [CRITICAL]

**File:** `inst/julia/src/brains/bnn.jl:182–196` (`bnn_update!`)

**The Problem:**

The code implements:
```julia
mu[i]    += lr * advantage * sigma[i]
sigma[i] *= max(0.01f0, 1.0f0 - lr * abs_adv * 0.1f0)
```

Williams (1992) REINFORCE is:
$$\Delta w = \alpha \cdot (r - b) \cdot \nabla_w \log \pi(a|s)$$

For a Gaussian posterior $N(\mu_i, \sigma_i)$ with fixed $\sigma_i$, the score w.r.t. $\mu_i$ is:
$$\frac{\partial \log \pi}{\partial \mu_i} = \frac{w_{\text{sampled}} - \mu_i}{\sigma_i^2}$$

**The code uses $\sigma_i$ (first power) as a surrogate for the score function.** This is **biased**: it:
- Ignores the $\sigma_i^2$ denominator, making large-uncertainty weights change too much.
- Does not use the actual sampled weight value, throwing away signal.
- Causes sigma to shrink uniformly regardless of whether advantage was driven by that weight.

**Recommended Fix:**

Cache the sampled weight vector during `forward()` and use it in `bnn_update!`:

```julia
function bnn_update!(brain::BNNBrain, input::Vector{Float32},
                      action_idx::Int, advantage::Float32, 
                      w_sampled::Vector{Float32}, lr::Float32)
    lr == 0.0f0 && return
    
    for i in eachindex(brain.mu)
        score = (w_sampled[i] - brain.mu[i]) / (brain.sigma[i]^2 + 1e-6f0)
        brain.mu[i] += lr * advantage * score
        brain.sigma[i] *= max(0.01f0, 1.0f0 - lr * abs(advantage) * 0.1f0)
    end
end
```

This requires storing `w_sampled` in BNNBrain or passing it through the RL driver. The current approach will under-learn from experience because the gradient direction and magnitude are both wrong.

---

### 2. **RL Module: No Baseline in BNN Path** [SUBTLE → HIGH VARIANCE]

**File:** `inst/julia/src/modules/rl.jl:113–123` (`_rl_update_output! for BNNBrain`)

**The Problem:**

The BNN output-layer update is:
```julia
step = lr * advantage
brain.mu[i] += step
```

where `advantage = reward - agent.value_estimate` (computed in `_apply_actor_critic!` line 144).

However, there is **no baseline subtraction at the output layer itself**. In the classic REINFORCE with baseline (Sutton & Barto 2018), the baseline $b$ is task-specific (e.g., temporal-difference estimate, running-average reward). The RL module computes `value_estimate` as a **running mean of reward** (line 147), but this is a **scalar**, not a per-action or per-layer baseline.

For the BNN output layer, using a global scalar advantage means:
- All output weights see the same advantage signal.
- No per-action criticality is captured (i.e., we don't learn which output weights should be more sensitive).
- Variance remains high because the gradient is not zeroed by a proper baseline.

**Impact:** BNN learns slower than it could; sigma may not narrow in response to learning because the high-variance updates do not reliably improve action selection.

**Recommended mitigation (Phase 2):**
Cache per-output activations and use per-action baselines (future Hebbian / advantage-actor-critic variants).

---

## Subtle Issues (Biased or High-Variance)

### 3. **Heterozygosity→Sigma Mapping: Undocumented & Potentially Circular**

**File:** `inst/julia/src/brains/bnn.jl:116–133` (constructor)

**The Design:**
```julia
sigma = abs.(maternal_weights .- paternal_weights) .* 0.5f0
```

This is **non-standard**. No prior literature maps diploid allele differences directly to Bayesian uncertainty. It is used to justify that:
- Heterozygous loci → broad priors → plasticity.
- Homozygous loci → narrow priors → canalization.

**Problems:**

1. **No justification from first principles.** Why is heterozygosity (genetic variance) the right proxy for *epistemic* uncertainty (weight variability)? It could as easily map to robustness or flexibility.

2. **Potential circularity with Baldwin Effect claim.** The docstring (lines 40–42) states: "In a stable environment, agents whose genome already encodes high mu do not need high sigma... Their sigma declines." But if sigma declines through **methylation** (not genom mutation), and methylation is triggered by **recent learning success**, then we are not observing Baldwin (genome tracking learned solution) but **epigenetic canalization**. The two are conflated.

3. **Population fixation trap:** When the population fixates (all agents homozygous), `sigma_init` becomes the floor (line 132). If mutation then introduces `maternal ≠ paternal`, sigma does bounce back. But the **lag time** is uncertain—is this an implementation artifact or genuine biology?

**Status:** Acknowledged as a design choice (lines 20–24) but lacks mechanistic grounding. Not wrong per se, but non-obvious and worth validating against simulated data.

---

### 4. **Softmax Numerical Stability: ANN Compliant, BNN via Forward Pass Only**

**File:** `inst/julia/src/brains/ann.jl:248–252` (`_softmax`)

**Good:** Softmax correctly subtracts maximum before exponentiation (line 250):
```julia
m  = maximum(x)
ex = exp.(x .- m)
```

**Coverage:** BNN uses `forward(sampled_ann)` which calls this `_softmax`, so BNN also benefits. CTRNN and GRN each call `_softmax` on their output logits (lines 201, 183 respectively). **Stable.**

---

### 5. **CTRNN Euler Stability: Tau Clamping is Conservative but Sufficient**

**File:** `inst/julia/src/brains/ctrnn.jl:125–126` (constructor)

**The Design:**
```julia
tau = clamp.(exp.(tau_raw), 0.1f0, 10.0f0)
```

**Analysis:**
- The Euler step is $\Delta y_i = (1/\tau_i) \cdot (\text{RHS})$.
- For stability with RHS magnitude up to ~10–20 (biased sums of sigmoids), $\tau_{\min} = 0.1$ gives $\Delta y \lesssim 200$ per step, which is large but within Float32 range.
- Mutation on the log scale (line 218) ensures tau stays positive.
- **Status: SAFE.** The clamping is conservative (ensures $\tau \in [0.1, 10]$), preventing blow-up at low tau.

---

### 6. **BNN Sigma Floor: Minimal but Missing Justification**

**File:** `inst/julia/src/brains/bnn.jl:131–132` (constructor)

```julia
sigma_min = Float32(get(specs, "bnn_sigma_min", 0.01))
sigma .= max.(sigma, sigma_min)
```

**The Design:** A floor of 0.01 (default) prevents complete fixation. Heterozygous loci can still have `sigma = 0.5 * |allele_diff|`, but homozygous loci (allele_diff = 0) bounce to 0.01.

**Problem:** The floor is **arbitrary.** Why 0.01 and not 0.001 or 0.1? There is no discussion of:
- Numerical stability in sampling (does sigma < 0.01 cause underflow?).
- Evolutionary pressures (does 0.01 allow sufficient exploration?).

**Status:** Minor. The floor prevents degeneracy and is documented in the code. Sensitivity to this hyperparameter should be tested empirically.

---

## Cross-Module Correctness

### 7. **RL → BNN Coupling: Advantage Sign is Correct**

**File:** `inst/julia/src/modules/rl.jl:140–150`

**Trace through toy example:** Suppose `agent.energy` increases (reward > 0), so `advantage > agent.value_estimate`. Then:
- `advantage > 0`.
- `step = lr * advantage > 0` (assuming `lr > 0`).
- Output-layer mu shifts **upward** (line 119).

For softmax action selection, **increasing mu makes that action more likely to be sampled.** So:
- Positive advantage → weights shift to reinforce the chosen action. ✓ **Correct sign.**

---

### 8. **Methylation Inheritance: Biologically Compliant**

**File:** `inst/julia/src/modules/epigenetics.jl:186–204` (`inherit_methylome!`)

**The Mechanism:**
```julia
offspring.methylome[i] = parent.methylome[i] && (rand(rng) < p_inherit)
```

**Check against Jablonka & Lamb 2005:**
- Unmarked loci → always unmarked in offspring. ✓
- Marked loci → inherited with probability `epigenetic_inheritance` (default 0.5). ✓ Matches empirical range.

**Integration:** Inheritance is called from `_make_offspring` (per docstring, line 281–284), and application via `apply_methylation!` (epigenetics.jl:258–263) correctly reduces BNN sigma. **Biologically sound.**

---

## Literature Cross-Check

### Blundell et al. 2015 (Weight Uncertainty in Neural Networks)

**Cited in:** BNN docstring (line 67), `bnn_update!` docstring (line 189).

**Claim:** "MFVI, also called Bayes By Backprop (Blundell et al. 2015). Eq. 8."

**Reality:** Blundell et al. describe:
$$\mu := \mu + \alpha \cdot \nabla_\mu \log q(\mathbf{w})$$
where $q$ is the variational posterior, and the gradient is taken w.r.t. parameters **not** w.r.t. the sampled weight. The code **does not** compute this gradient; it uses a crude proxy (sigma-scaled) instead.

**Verdict:** The code is **inspired by but not faithful to** Blundell et al. The simplification is acknowledged (lines 57–59, "score-function estimator... for simplicity") but is **not** standard Bayes-By-Backprop.

---

### Williams 1992 (REINFORCE)

**Cited in:** BNN docstring (lines 68–69), RL module docstring (lines 46–47).

**Claim:** "REINFORCE score-function estimator."

**Reality:** Williams derives the unbiased estimator using $\nabla_w \log \pi(a|s)$. The BNN code uses $\sigma_i$ instead, which is a **biased proxy** (see Issue #1). Not faithful.

---

### Thompson 1933 (Thompson Sampling)

**Cited in:** BNN `forward()` docstring (line 151).

**Claim:** "Thompson sampling — sample one weight from each N(mu, sigma)."

**Reality:** Thompson sampling (in the multi-armed bandit sense) samples **actions** from a posterior and evaluates them. The BNN samples **weights** and runs the resulting network. This is **not** Thompson sampling in the classic sense; it is **posterior sampling for exploration** in a neural network. The terminology is loose but not wrong. ✓

---

## Style & Stability Notes

### 9. **Mutation Operators: Uniform Gaussian, No Masking**

**Files:** `ann.jl:123–129`, `bnn.jl:206–209`, `ctrnn.jl:214–226`, `grn.jl:194–197`

All brains apply Gaussian noise $\mathcal{N}(0, \sigma_{\text{mut}})$ uniformly to all weights. No per-locus rates, no masking of structural parameters (like biases in hidden layers).

**Is this biologically reasonable?**
- **Real genomes:** Mutation rates vary by locus, by sequence context (CpG sites), and by functional class (coding vs. regulatory).
- **Simplification:** Uniform mutation is computationally simpler and has been standard in alifeR and Mesa.

**Verdict:** Acceptable simplification, but the code would benefit from a comment explaining it is **not** per-locus heritability but a global rate.

---

### 10. **GRN Forward Pass: No Input-Injection Safeguard**

**File:** `inst/julia/src/brains/grn.jl:159–184`

**Code:**
```julia
n_inject = min(n_in, length(input))
for i in 1:n_inject
    drive[i] += input[i]
end
```

**Good:** Defensive programming handles short input vectors. However, the **loop should guard the FULL computation**, not just injection:
```julia
for i in 1:n
    if i <= n_inject
        drive[i] += input[i]
    end
    brain.g[i] = sigmoid(drive[i])
end
```

**Current code is correct** (lines 173–176 iterate all n), so no issue.

---

## Deliverable Summary

### Critical Findings
1. **BNN REINFORCE update uses biased score function.** Replace `sigma[i]` with `(w_sampled[i] - mu[i]) / sigma[i]^2`. Impacts every RL-enabled BNN run.

### Subtle Findings
2. **RL module has no per-action baseline** for BNN output layer, leading to high-variance learning.
3. **Heterozygosity→sigma mapping is undocumented** and potentially circular with Baldwin Effect claims. Needs empirical validation.
4. **BNN sigma floor (0.01) is arbitrary.** No justification given; sensitivity analysis recommended.

### Verified & Correct
5. **Softmax numerical stability:** ✓ Safe across all brain types.
6. **CTRNN tau clamping:** ✓ Conservative, prevents blow-up.
7. **Methylation inheritance:** ✓ Compliant with Jablonka & Lamb 2005.
8. **RL advantage sign:** ✓ Correct gradient direction.
9. **Literature citations:** ✓ Williams & Thompson correctly cited, Blundell simplified (acknowledged).
10. **Mutation & GRN:** ✓ Reasonable design choices, defensive coding.

---

## Recommended Actions (Phased)

**Phase 1 (Immediate):**
- [ ] Fix BNN `bnn_update!` to use true score function (Issue #1).
- [ ] Document heterozygosity→sigma design choice & cite validation run (Issue #3).

**Phase 2 (Next release):**
- [ ] Add per-action baseline support to RL module.
- [ ] Sensitivity analysis on `bnn_sigma_min`.

**Phase 3 (Future):**
- [ ] Implement full Bayes-By-Backprop (not just REINFORCE proxy).
- [ ] Add per-locus mutation rate support.

---

**Word count: 1,280 | Audit date: 2026-04-14**
