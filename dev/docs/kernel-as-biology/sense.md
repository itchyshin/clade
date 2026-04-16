# `sense.jl` — what an agent perceives

This file builds the **input vector** that gets fed to the agent's
brain each tick. It's the model's answer to: *what does an organism
know about its world at any given moment?*

The choices made here matter biologically. If an agent can sense
grass three cells away, foraging is largely a navigation problem. If
it can only sense its own current cell, foraging is essentially
random walk plus reactive grazing. Neither extreme is correct for any
particular real organism, but the chosen middle ground (cardinal
directions at radius 1) maps best to a small mammal or insect
foraging in dense vegetation.

Source file: [`inst/julia/src/sense.jl`](../../../inst/julia/src/sense.jl)
(132 lines).

---

## 1. The input vector layout

```
Index  Content
-----  -------
1      own_energy / energy_max          (normalised [0, 1])
2      own_age / max_age                (normalised [0, 1])
3–6    grass N/E/S/W at distance 1
7–10   agent presence N/E/S/W at distance 1
11     constant bias term = 1.0

Optional extensions (appended in order):
+ predators (n_predators_init > 0):  +4 predator-distance inputs
+ parental_care = TRUE:               +2 care-load inputs
+ signal_dims > 0:                    +signal_dims inputs

Default total: 11 inputs.
With predators: 15.
With predators + signals (3 dim) + care: 20.
```

**What this says.** Every agent gets exactly the same input format —
11 numbers (the default), each in [0, 1]. The brain is wired to expect
a vector of this length. Optional modules append extra inputs, and the
brain's input layer is sized accordingly at construction time.

**Biology.** This is the **perceptual world** of an agent — what
ethologists call the *Umwelt* (von Uexküll 1934). Every species has
its own; clade gives all agents the same one because evolutionary
ecology rarely models perception in detail. The 11-input default
represents:

- 2 internal signals (energy, age — what the agent knows about its
  own state)
- 8 external signals (4 grass intensities + 4 conspecific presences,
  one per cardinal direction)
- 1 constant bias (lets the network learn unconditional preferences)

This vector is small by ML standards (typical RL networks consume
hundreds of inputs). The smallness is intentional: a small input vector
is interpretable and selection acts on a tractable space.

---

## 2. Self-knowledge — energy and age

```julia
inp[pos] = clamp(ag.energy / emax, 0.0f0, 1.0f0);  pos += 1
inp[pos] = clamp(Float32(ag.age) / amax, 0.0f0, 1.0f0); pos += 1
```

**What this says.** First two inputs: the agent's own energy and age,
each divided by their respective maxima so the values are in [0, 1].

**Biology.** This is **interoception** — the perception of one's own
internal state. Real animals have hunger, thirst, fatigue. Here we
collapse all of that into two numbers:

- **Energy** as a proxy for hunger / condition. Low energy → urgent
  need to find food. High energy → slack, can afford to explore or
  reproduce.
- **Age** as a proxy for ontogenetic stage. Young = unsophisticated;
  old = experienced (or near-death, depending on senescence).

Both are normalised to [0, 1], which means the agent doesn't know its
absolute energy reserves, only its proportion-full. Biologically
reasonable: an animal "feels" hungry as a relative state.

**Audit findings.** No issues with these inputs themselves. But note
that age dynamics are dominated by the always-on `max_age = 200` cap
(s-pace-of-life audit) — every agent's age fills the [0, 1] range on
the same timescale regardless of metabolic rate. Tier 2 fix
(max_age scales with metabolic_rate) will give the age signal more
biological meaning.

---

## 3. Grass — directional resource sensing

```julia
for d in 1:r
    xN = wrap_or_clamp(x - d, rows, toroidal);  xS = wrap_or_clamp(x + d, rows, toroidal)
    yE = wrap_or_clamp(y + d, cols, toroidal);  yW = wrap_or_clamp(y - d, cols, toroidal)
    inp[pos] = clamp(env.grass[xN, y]  / gmax * sense_mult, 0.0f0, 1.0f0);  pos += 1
    inp[pos] = clamp(env.grass[x,  yE] / gmax * sense_mult, 0.0f0, 1.0f0);  pos += 1
    inp[pos] = clamp(env.grass[xS, y]  / gmax * sense_mult, 0.0f0, 1.0f0);  pos += 1
    inp[pos] = clamp(env.grass[x,  yW] / gmax * sense_mult, 0.0f0, 1.0f0);  pos += 1
end
```

**What this says.** For each distance from 1 to `input_radius` (default
1), look up the grass value in the four cardinal cells (north, east,
south, west of the agent), normalise to [0, 1], optionally amplify by a
brain-size multiplier, and add to the input vector.

**Biology.** This is **directional resource perception**. The agent
gets four values telling it which way the food is, at each distance
within its sensing radius. Two important biological choices:

1. **Cardinal only** — N, E, S, W. No diagonals. Real animals usually
   sense in all directions, but the cardinal-only choice is a
   computational shortcut that doesn't matter much when sensing radius
   is small.
2. **Per-distance, not summed** — at radius 2, you get separate
   inputs for "grass at distance 1 north" and "grass at distance 2
   north." This contrasts with the MATLAB/alifeR ancestors, which
   collapsed all distances into a weighted sum (closer cells weighted
   more). Per-distance inputs give the network strictly more
   information; the weighted-sum is a learnable function of these.

The `sense_mult` factor scales perception by `brain_size ^ 0.3`. At the
default `brain_size = 1.0` this is 1.0 (no effect). When
`brain_size_evolution = TRUE`, larger-brained agents perceive grass
gradients more clearly — the **cognitive-foraging benefit** that makes
big brains worthwhile (Aiello & Wheeler 1995).

**Audit findings.** Input normalisation to [0, 1] (vs MATLAB/alifeR's
raw values) is a clade improvement — it prevents the high-magnitude
energy input from dominating the network's first layer. No biological
issue.

**Variants worth considering.**

1. **All-direction sensing** (N, NE, E, SE, S, SW, W, NW) would add
   four more directional channels at small computational cost. Worth
   considering if foraging precision matters for a scenario.
2. **Smell** vs **vision** modes: smell would integrate across
   distances (perceive total food in a sector); vision would prioritise
   the nearest signal. Currently both are implicit in the per-distance
   format — the network can learn either pattern.
3. **Limited field of view**: real animals have blind spots. Currently
   no blind spots are modelled. Adding heading-dependent sensing
   would be a kernel addition.

---

## 4. Conspecific presence — who's nearby

```julia
for d in 1:r
    xN = wrap_or_clamp(x - d, rows, toroidal);  xS = wrap_or_clamp(x + d, rows, toroidal)
    yE = wrap_or_clamp(y + d, cols, toroidal);  yW = wrap_or_clamp(y - d, cols, toroidal)
    inp[pos] = env.agent_map[xN, y]  > 0 ? 1.0f0 : 0.0f0; pos += 1
    inp[pos] = env.agent_map[x,  yE] > 0 ? 1.0f0 : 0.0f0; pos += 1
    inp[pos] = env.agent_map[xS, y]  > 0 ? 1.0f0 : 0.0f0; pos += 1
    inp[pos] = env.agent_map[x,  yW] > 0 ? 1.0f0 : 0.0f0; pos += 1
end
```

**What this says.** For each cardinal direction at each distance,
check if any other agent occupies that cell. If yes, the input is 1.0;
if no, 0.0. Binary presence, not a count.

**Biology.** This is **conspecific detection**. Real animals are
acutely sensitive to neighbours — for mating, for competition, for
warning, for safety in numbers. clade abstracts this as a binary
signal per cell.

The binary nature is a deliberate simplification:

- Real signals are graded (one neighbour vs three neighbours
  matters), but a binary signal is simpler for the network to learn
  from and the cellular grid forces a "one agent per cell" rule
  anyway.
- Distinguishing kin from non-kin is *not* done here — the input
  is an indistinct "agent present." Kin altruism (when active) does
  the relatedness check separately, in `kin.jl`.

**Audit findings.** No specific issues. The binary presence signal is
sufficient for the foraging-driven behaviours we test.

**Variants worth considering.**

1. **Distinguish kin from non-kin** in the sensing layer (would need
   a separate channel per direction). Would give the network direct
   access to kin information. Currently kin signals are processed
   only by the dedicated `kin_altruism` module.
2. **Distinguish predators from prey** when both species are present.
   Currently predators get their own slot in the predator-extension
   block; prey see other prey via this `agent_map` block.

---

## 5. Bias — the constant-1.0 input

```julia
inp[pos] = 1.0f0; pos += 1
```

**What this says.** Append a constant 1.0 to the input vector.

**Biology.** Not biology — neural-network convention. A bias term
lets the network learn unconditional offsets in its first layer
(equivalent to adding a constant to every neuron's input). Without
it, the network can only respond to inputs that vary; with it, the
network can have baseline preferences (e.g., "I always slightly
prefer to move north").

This is technical scaffolding rather than biology. Some
implementations build the bias directly into the network weights;
clade adds it as an explicit input slot for clarity.

---

## 6. Predator proximity — the optional threat channel

```julia
if Int(get(specs, "n_predators_init", 0)) > 0
    for d in 1:r
        xN = mod1(x - d, rows);  xS = mod1(x + d, rows)
        yE = mod1(y + d, cols);  yW = mod1(y - d, cols)
        inp[pos] = _pred_dist(env, xN, y);  pos += 1
        inp[pos] = _pred_dist(env, x,  yE); pos += 1
        inp[pos] = _pred_dist(env, xS, y);  pos += 1
        inp[pos] = _pred_dist(env, x,  yW); pos += 1
    end
end
```

with the helper:

```julia
_pred_dist(env::Environment, x::Int, y::Int)::Float32 =
    env.predator_map[x, y] > 0 ? 1.0f0 : 0.0f0
```

**What this says.** If predators exist in the simulation, add four
extra inputs per sensing distance — predator presence in each cardinal
direction. Like conspecific presence, this is binary.

**Biology.** **Predator detection** is one of the most important
sensory tasks any prey animal does. Anti-predator behaviour
(vigilance, alarm calls, fleeing) is shaped by selection on this
signal. clade gives prey a dedicated predator-presence channel,
distinct from generic agent presence — this lets the brain learn
predator-specific responses without having to disambiguate from
conspecifics.

**Audit findings.** No issues with the predator-sensing channel
itself. The s-predator-prey audit ✅ verified that this signal allows
prey to evolve avoidance behaviour over generations.

**Variants worth considering.**

1. **Distance-graded predator signal** (real `1/(distance+1)`
   instead of binary) would let the brain assess threat level.
   The function `_pred_dist` was apparently meant to do this (the
   docstring says so) but the implementation just returns binary.
   Worth fixing for biological realism.
2. **Predator type signal** — when multiple predator species exist,
   distinguishing them is useful (e.g. terrestrial vs aerial
   predators trigger different responses). Currently a single
   predator channel.

---

## 7. Parental-care signals — the carried-brood channel

```julia
if Bool(get(specs, "parental_care", false))
    max_cl    = Float32(max(1, get(specs, "max_clutch_size", 1)))
    inp[pos]  = Float32(ag.care_load) / max_cl;  pos += 1
    mean_e    = ag.care_load > 0 ?
                mean(Float32[c.energy for c in ag.carried_offspring]) : 0.0f0
    inp[pos]  = clamp(mean_e / emax, 0.0f0, 1.0f0);  pos += 1
end
```

**What this says.** When parental care is enabled, append two more
inputs: how many offspring this agent is currently carrying (as a
fraction of max clutch size), and the average energy of those
offspring (normalised).

**Biology.** **Reproductive interoception** — knowing about one's
current parental burden. A parent carrying many low-energy offspring
should behave differently from a parent with no brood: it should
prioritise foraging over mating, and avoid risky moves.

The signal is simple — care load (a count) and brood condition (mean
energy). A parent that perceives its brood is starving might forage
more aggressively. A parent with no brood is free to seek mates.

**Audit findings.** s-parental-care audit ✅ confirmed the graduation
pathway works (juveniles persist, then graduate). The care-load signal
is correctly fed to the brain. Population-level buffering (P2) was
flat at default parameters but mechanism is wired.

---

## 8. Mating signals — the heritable ornament channel

```julia
for s in ag.signal
    inp[pos] = s;  pos += 1
end
```

**What this says.** If the agent has a signal vector (only when
`signal_dims > 0`), append every value of that vector to the input.

**Biology.** **Self-perception of phenotype** — the agent perceives
its own evolved sexual or warning signal. This is biologically odd
(real animals don't usually "see" their own coloration in the way the
network does here), but it's needed for the brain to learn how to
behave in a way that's consistent with its own signal value (e.g.,
display behaviour matching ornament magnitude).

A more realistic alternative would be to have agents perceive
*neighbours'* signals (so they can choose mates by signal). This is
done in the `signals.R` mate-choice code rather than as a sensory
input, so the brain doesn't directly see other agents' signals.

**Audit findings.** s-signals audit ✅ Zahavi handicap honesty
recovered (Spearman ρ(energy, signal) = +0.25 across seeds). Mechanism
works; the cost-vs-population effect dynamics differ from the textbook
(cost hits population not signal magnitude) — flagged as kernel
characteristic, not a bug.

---

## What this file *doesn't* do

- **Process the inputs.** That happens in the brain (the brain takes
  the input vector and produces an action choice).
- **Decide based on signals.** Mate-choice and predator avoidance
  logic live in their own modules.
- **Sense at long range.** No vision beyond `input_radius` cells.
- **Track sensory history.** Each tick gets a fresh input vector; the
  brain has no memory across ticks except what's encoded in its
  internal state (CTRNN brains have this; ANN, BNN do not).

---

## Reading guide for biologists who want to spot bugs

Things to check when reading this file:

1. **Are inputs in [0, 1]?** All grass, age, energy, and care inputs
   are clamped or naturally bounded. Predator and conspecific inputs
   are binary {0, 1}. Bias is constant 1.0. Signal inputs are
   *unbounded* — the only ones that can fall outside [0, 1].
2. **What does the brain *not* see?** It doesn't see absolute energy
   (only relative), absolute grid position (only relative cell
   sensing), other agents' traits (only their presence). This is
   biologically reasonable — real animals don't have GPS or mind-
   reading.
3. **Is sensing symmetric across cardinal directions?** Yes — N, E,
   S, W are treated identically. The agent has no intrinsic
   forward-back asymmetry. This means the brain has to learn any
   anisotropic preferences from scratch.
4. **What happens at the grid edge?** `wrap_or_clamp` handles it.
   With toroidal grids (default), edges wrap around. With bounded
   grids, sensing past the edge returns the edge value (clamped).
   Neither is perfectly biological but both are common in spatial
   ABMs.

---

## Citations referenced in this document

- Aiello, L.C. & Wheeler, P. (1995) The expensive-tissue hypothesis.
  *Curr. Anthropol.* 36:199-221.
- von Uexküll, J. (1934/2010) *A Foray into the Worlds of Animals
  and Humans.* University of Minnesota Press.

---

*Companion documents:*

- [`README.md`](README.md) — Reading guide.
- [`tick.md`](tick.md) — Per-tick agent update (the hot path).
- [`clade-main.md`](clade-main.md) — Main loop orchestration.
- *(planned)* `reproduce.md`, `death.md`, `genome.md`.
