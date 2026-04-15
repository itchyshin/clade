# Critical Review: Ecology, Disease, and Spatial-Dynamics Modules

**Audit Date:** April 2026  
**Scope:** SIR dynamics, dispersal, spatial sorting, complex landscape, seasonality, predators, scavenging, group defense, habitat preference, fixed patches, sensory integration, and tick loop order.

---

## CRITICAL ISSUES

### 1. **Spatial Sorting Incompatible with Toroidal Grid**

**File:** `inst/julia/src/modules/spatial_sorting.jl:43–62`  
**Severity:** Critical (contradicts paper mechanics)

The Shine et al. (2011) range-expansion mechanism requires an **invasion front**—a clear spatial boundary where the population begins and expands outward. On a toroidal grid, there is no front: the population wraps continuously, and the centroid computation (Euclidean distance) is meaningless in a periodic topology.

**Current Implementation:**  
```julia
cx = Float32(sum(ag.x for ag in ags if ag.alive)) / Float32(n)
cy = Float32(sum(ag.y for ag in ags if ag.alive)) / Float32(n)
dmax = maximum(sqrt((Float32(ag.x) - cx)^2 + (Float32(ag.y) - cy)^2)...)
```

The centroid is computed as a simple arithmetic mean on coordinates that wrap. On a torus, this produces a meaningless average. Example: agents at x∈{1, 100} on a 100-cell grid have mean x=50.5, but both are actually on the *same edge* (minimum toroidal distance ≈ 1).

**Impact:** Spatial sorting selects on noise, not genuine invasion-front divergence. Vignettes claiming Shine et al. replication are incorrect.

**Fix:** Either:
- Set `toroidal = false` for spatial-sorting experiments (bounded grid with real edges).
- Replace centroid with toroidal-aware distance metric (requires metric definition; not implemented).

**Recommended:** Add validation at initialization:
```julia
if Bool(get(specs, "spatial_sorting", false)) && Bool(get(specs, "toroidal", true))
    @warn "spatial_sorting + toroidal=true: front detection disabled (no edges)."
end
```

---

### 2. **Habitat Preference Moves Break Agent-Map Integrity**

**File:** `inst/julia/src/modules/habitat_preference.jl:84–99`  
**Severity:** Critical (silent corruption)

The module moves agents then rebuilds `agent_map` from scratch. However, it sets `env.agent_map[nx_new, ny_new] = 1` as a placeholder (line 89), violating the invariant that `agent_map[x, y]` holds the index of the agent at (x, y).

**Current Behavior:**
1. Agent moves; old cell cleared.
2. New cell set to 1 (not the actual agent index).
3. Rebuild happens (line 96–99), correcting all indices.

**Risk:** If any code between lines 89–99 reads `agent_map[nx_new, ny_new]` expecting an index (e.g., in a hooked debug function or future module), it will retrieve 1 instead of the correct index, leading to wrong agent access.

**Fix:** Do NOT set placeholder; only clear old cell and rebuild:
```julia
env.agent_map[x, y] = 0
ag.x, ag.y = nx_new, ny_new
# (no intermediate set to 1)
# Then rebuild at end as now
```

Or pre-allocate and maintain invariant:
```julia
ag.x, ag.y = nx_new, ny_new
agent_idx = findfirst(a -> a === ag, env.agents)
env.agent_map[nx_new, ny_new] = agent_idx
```

---

### 3. **Seasonal Amplitude Can Drive Grass Rate Negative**

**File:** `inst/julia/src/modules/seasonal.jl:10`  
**Severity:** Critical (undefined behavior)

The grass regrowth is modulated as:
```
per-tick grass regrowth = grass_rate * (1 + seasonal_amplitude * sin(2π t / season_length))
```

If `seasonal_amplitude ≥ 1`, then in winter (sin < 0), the modulation becomes ≤ 0, producing negative regrowth rates. These are passed to `grow_grass!` and interact multiplicatively with random draws. While probabilistic grass growth (lines 449–451 in Clade.jl) might clamp negatives, the docstring does not document this behavior, and the seasonal.jl module itself provides no guard.

**Current:** `grow_grass!` applies `(1 + sin(...)) * rate`, which can be negative.

**Impact:** Silent underflow or incorrect regrowth if downstream does not clamp. Amplitude > 1 was likely never tested.

**Fix (seasonal.jl):** Add bounds check:
```julia
amplitude = Float32(get(env.specs, "seasonal_amplitude", 0.0))
amplitude >= 1.0f0 && @warn "seasonal_amplitude ≥ 1 can produce negative growth rates"
```

Or enforce maximum:
```julia
amplitude = min(Float32(get(...)), 0.99f0)
```

---

### 4. **Predator Sensory Vector Incompatible with Prey Brain**

**File:** `inst/julia/src/modules/tick_predators.jl:208–213`  
**Severity:** Subtle (architectural; predators function but bypass learning)

Predators use a **hard-coded 15-element sensory input** (energy/2, age/2, 4 cardinal prey counts, 4 cardinal prey distances, 4 adjacent grass densities, bias). This is invariant—no optional modules, no input_radius, no predator-sensing-predators feedback.

Prey use a **dynamic input size** computed by `_compute_n_inputs()` that includes:
- Base: 3 + 8r (energy, age, grass, occupancy, bias)
- Optional: 4r (predator proximity if predators enabled)
- Optional: 2 (care load if parental_care)
- Optional: signal_dims

**Incompatibility:** If prey are born with a brain sized for dynamic inputs but predators always use 15-element inputs, predators' brains may have mismatched architecture. Predators are initialized with prey's brain architecture (line 71: `arch = _build_arch(specs)`), so they inherit the dynamic size. But `_sense_predator` produces a hard-coded 15-element vector.

**Example Failure:**
```
Prey: input_radius=2 → n_inputs = 3 + 8*2 = 19
Predators: always sense 15 elements
Result: predator.brain expects 19, gets 15 → dimension mismatch
```

**Fix:** Either:
1. Make predator sensing match prey architecture:
   ```julia
   inp = sense_agent(pred, env)  # reuse prey sensing
   ```
2. Build a dedicated predator brain architecture (separate from prey) that is 15-element-compatible.

Current predator brain will silently fail or ignore extra prey input dimensions.

---

## SUBTLE ISSUES

### 5. **SIR Transmission is Frequency-Dependent, Not Density-Dependent**

**File:** `inst/julia/src/modules/disease.jl:143–144`  
**Status:** Design choice, not a bug; document clearly

Each infected agent scans its 8-cell Moore neighbourhood and infects susceptible neighbors with constant probability `transmission_prob * (1 - receiver.immune_strength)`. This is **frequency-dependent transmission** (Anderson & May 1991): the per-contact transmission rate is constant, independent of total population size.

**Biological Implications:**
- In classical epidemiology, β S I / N (frequency-dep) is more appropriate for *sexually-transmitted* diseases and *vector-borne* diseases.
- Density-dependent β S I (no division by N) suits *respiratory* and *contact-based* pathogens, where transmission scales with population density.

**Current Default:** `transmission_prob = 0.15` per Moore-neighbor contact per tick.

**Effective R0 (rough):** R0 ≈ β / γ = transmission_prob / (1 / disease_duration) = 0.15 × 10 = **1.5** (with defaults).  
This is a slow-growing epidemic (just above threshold). Reasonable, but undocumented.

**Issue:** Module docstring (line 26) cites Anderson & May but does not specify which model. Users may assume density-dependent if they know the reference.

**Fix:** Add to disease.jl docstring:
```
This implementation uses FREQUENCY-DEPENDENT transmission (β per contact).
For density-dependent transmission, modify line 143:
    eff_prob = tprob * (1 - receiver.immune_strength)  # frequency-dep (current)
    # vs.
    eff_prob = (tprob / n) * (1 - receiver.immune_strength)  # density-dep
```

---

### 6. **Complex Landscape Canopy Access is Binary Gate, Not Probabilistic**

**File:** `inst/julia/src/modules/complex_landscape.jl:79–84`  
**Status:** Design choice; note asymmetry with shrubs

Canopy access is a **hard threshold**: `if ag.wing_size >= canopy_threshold` (binary gate). Shrub access is unlimited (all agents, all the time). Grass access requires only reaching a cell.

**Consequence:** Agents with wing_size < 0.6 (default threshold) *never* access canopy, creating a strict niche partition. This is appropriate for *morphological specialization* (e.g., flying vs. ground-dwelling).

**However:** If habitat_preference or spatial_sorting is enabled, agents may evolve high wing_size purely to bypass the threshold without deriving fitness from canopy nutrients. The fitness landscape then rewards "reach canopy" regardless of energetic need, rather than balancing access-vs-cost.

**Recommendation:** Document this as a *specialization-forcing* mechanism. If niche-switching is desired, use a probabilistic gate:
```julia
prob_access = (ag.wing_size / canopy_threshold) ^ 2  # sigmoid-like
if rand() < prob_access && env.canopy_map[x, y] > 0
    # eat canopy
end
```

---

### 7. **Disease Duration Recovery Mechanism Lacks Vertical Transmission**

**File:** `inst/julia/src/modules/disease.jl:42–61, 177–189`  
**Status:** Design choice; risk of incomplete epidemiology

**Mechanism:** Infection is seeded once at t=1. Agents recover after `disease_duration` ticks and gain immunity for `immune_duration` ticks. Vertical transmission (infected → offspring) is not implemented.

**Consequence:** In a long-running simulation, the initial infected cohort recovers, immunity wanes, but re-infection may be impossible if the disease has been purged from the population. Without vertical transmission or re-infection from an external reservoir, the disease goes extinct even if R0 > 1 (a paradox in epidemiology).

**Fix:** Add optional vertical transmission at reproduction (Clade.jl / reproduce.jl):
```julia
# In _make_offspring:
if parent.infected && rand(rng) < vertical_transmission_prob
    off.infected = true
    off.infection_age = 0
end
```

---

### 8. **Scavenging Carrion Decay Rate Hard-Coded Default 0.1**

**File:** `inst/julia/src/modules/scavenging.jl:123`  
**Status:** Reasonable default; clarify interpretation

Carrion decays exponentially: `carrion *= (1 - 0.1)` per tick. Half-life ≈ 6.6 ticks.

**Question:** Is this decomposition (microbial) or removal (insect scavenging)? The docstring suggests both. In reality:
- Microbial decomposition: several days for vertebrate carrion (much slower).
- Insect/arthropod removal: hours to days for small carcasses.

A decay rate of 0.1/tick (assuming 1 tick ≈ 1 hour) gives a half-life of ~7 hours, which is reasonable for a small carcass in a warm climate. If 1 tick ≈ 1 day, then 0.1 is far too fast.

**No fix needed,** but document tick duration in Clade.jl and scale decay rate accordingly.

---

### 9. **Group Defense Counts Agent-Map Entries, Not Live Agents**

**File:** `inst/julia/src/modules/group_defense.jl:66`  
**Status:** Subtle; may count dead agents briefly

The function counts live agents within a Chebyshev radius:
```julia
env.agent_map[nx, ny] > 0 && (n_nearby += 1)
```

This reads `agent_map` (which holds agent indices), not the agent's `alive` flag. If a dead agent's index is still in `agent_map` (e.g., between `kill_dead!` and `remove_dead!`), the count is inflated.

**Timing:** In Clade.jl (line 397–398), `kill_dead!` then `remove_dead!` are called sequentially. Dead agents are flagged but remain in `env.agents` with stale `agent_map` entries until `remove_dead!` clears them. `tick_predators!` is called earlier (around line 195, estimated), so group defense would see stale dead indices.

**Fix:** Check agent liveness explicitly:
```julia
j = env.agent_map[nx, ny]
j > 0 && j <= length(env.agents) && env.agents[j].alive && (n_nearby += 1)
```

---

### 10. **Sensory Input Ordering Assumes Fixed Module Set**

**File:** `inst/julia/src/sense.jl:1–28; Clade.jl:549–557`  
**Status:** Architectural; brittle if modules reordered

The sensory vector is built in a fixed order: energy, age, grass, occupancy, bias, predators, care, signal. If optional modules are toggled, the input size changes but the *order is invariant*. This means:

1. All brains in the population must be resized when a module is toggled on/off between generations.
2. A brain trained with predators enabled will have corrupted inputs if predators are disabled mid-run.

**Current:** Brains are built at initialization and offspring inherit the architecture. If specs change mid-run (which they shouldn't), the mismatch is silent.

**No fix needed,** but document: "Do not toggle optional modules mid-run. Input architecture is determined at initialization and is invariant."

---

## STYLE / DOCUMENTATION ISSUES

### 11. **Dispersal + Complex Landscape Create Conflicting Selection**

**File:** `inst/julia/src/modules/dispersal.jl:1–45`  
**Status:** Documentation gap

Dispersal is driven by maximizing toroidal distance from birthplace. But if complex_landscape is enabled, agents evolving higher wing_size are also selected for canopy access. Both traits can accumulate, but they trade against different resources:

- High dispersal_tendency → move far, exploit spatially-homogeneous grass.
- High wing_size → stay local, exploit canopy patches.

**Consequence:** Empirical evolution may find an unexpected equilibrium. Document this trade-off in the module docstring.

---

### 12. **Tick Loop Order: Disease Application Before Kin Altruism**

**File:** `Clade.jl:367–380`  
**Status:** Order matters, undocumented

Disease is applied (line 370), potentially killing agents and decrementing energy. Kin altruism (line 371) then applies costs/benefits. If an infected agent is targeted for altruism, does it receive energy transfers before or after disease mortality? Current order (disease first) means infected individuals pay disease cost, then receive kin transfers if alive.

**Alternative:** Reverse the order to apply kin altruism before disease, so relatedness-based support buffers disease cost.

**No fix needed,** but document the rationale in a comment.

---

### 13. **Fixed Patch Compatibility with Seasonality Undocumented**

**File:** `inst/julia/src/modules/fixed_patch.jl:47–64`  
**Status:** Compatibility claim unverified

Fixed patch resets grass to a fixed value after `grow_grass!` every tick. Seasonality modulates the grass growth rate in `grow_grass!`. The fixed patch then overwrites the result, making seasonality **irrelevant at the patch location**. Elsewhere, grass oscillates seasonally; at the patch, it is constant.

**This is likely intentional** (stable peak for evolution of navigation), but undocumented. Add a note:

```
Fixed patch overrides seasonal modulation at patch cells,
ensuring a stable fitness peak even under seasonal grass dynamics.
```

---

## SUMMARY TABLE

| Issue | File | Line(s) | Severity | Status |
|-------|------|---------|----------|--------|
| Spatial sorting incompatible with toroidal grid | spatial_sorting.jl | 43–62 | **CRITICAL** | Needs fix |
| Habitat preference agent_map corruption | habitat_preference.jl | 84–99 | **CRITICAL** | Needs fix |
| Seasonal amplitude can go negative | seasonal.jl | 10 | **CRITICAL** | Needs bounds |
| Predator sensory vector mismatched to brain | tick_predators.jl | 208–273 | **CRITICAL** | Needs reconciliation |
| SIR model frequency-dependent undocumented | disease.jl | 143–144 | Subtle | Document |
| Canopy access binary gate unspecified | complex_landscape.jl | 79–84 | Subtle | Document |
| Disease lacks vertical transmission | disease.jl | entire | Subtle | Optional feature |
| Scavenging decay assumptions unclear | scavenging.jl | 123 | Subtle | Clarify |
| Group defense counts dead agents | group_defense.jl | 66 | Subtle | Verify timing |
| Sensory input brittle to module reordering | sense.jl, Clade.jl | 54, 549 | Style | Document invariant |
| Dispersal-complexity trade-off unspecified | dispersal.jl | entire | Style | Document |
| Tick loop order (disease/kin) undocumented | Clade.jl | 370–371 | Style | Document rationale |
| Fixed patch + seasonal interaction undocumented | fixed_patch.jl | 47–64 | Style | Document override |

---

## RECOMMENDATIONS

1. **Immediate:** Add validation to spatial_sorting.jl to warn if `toroidal=true`.
2. **Immediate:** Remove placeholder index in habitat_preference.jl; rebuild agent_map correctly.
3. **Short-term:** Add bounds checking in seasonal.jl to prevent negative growth rates.
4. **Short-term:** Reconcile predator sensory input with prey brain architecture (reuse `sense_agent` or separate architecture).
5. **Ongoing:** Document all module interactions (dispersal-landscape, disease-vertical-transmission, seasonality-fixed-patch) in docstrings.
6. **Testing:** Add unit tests for tick loop order invariants (agent_map integrity, dead-agent cleanup timing).

