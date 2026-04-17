# `tick.jl` — one tick in the life of an agent

This file is the **heart of the simulation**. Every other module hangs
off it. For each agent, every tick, this is what happens: the agent
senses its surroundings, decides what to do, moves (or stays), eats
whatever grass it can, ages, and pays its metabolic costs. If it runs
out of energy, it dies the next time `kill_dead!` is called (handled
elsewhere in `death.jl`).

This file is short (~130 lines of executable code) and contains many of
the model's most consequential biological assumptions. Read it slowly.

Source file: [`inst/julia/src/tick.jl`](../../../inst/julia/src/tick.jl).

---

## 1. Function header — what gets passed in

```julia
function tick_agents!(env::Environment)
    specs    = env.specs
    rows     = Int(specs["grid_rows"])
    cols     = Int(specs["grid_cols"])
    toroidal = Bool(get(specs, "toroidal", true))
```

**What this says.** The function `tick_agents!` takes the whole
environment as its argument. Inside, it pulls out the user-set
parameters (`specs`), the grid dimensions, and whether the grid is
toroidal (i.e. does the world wrap around at the edges, like an old
Asteroids game, or are there walls).

**Biology.** The grid is the world. Toroidal means no edges — useful for
modelling habitats that are continuous from the agent's perspective (a
patch of forest large enough that any individual rarely encounters the
boundary). Bounded (non-toroidal) grids matter for invasion-front
dynamics like Shine's spatial sorting (s-dispersal-ifd) where the front
is a real ecological feature.

**Variants worth considering.** Real habitats are rarely either
perfectly toroidal or perfectly bounded — most have edges with
permeability gradients (a forest fading into pasture). clade currently
supports only the two extremes. A "soft edge" mode (probability of
re-entry decreasing with distance from grid centre) would more
realistically model habitat fragmentation.

---

## 2. Per-tick costs and gains — the energy economy parameters

```julia
move_cost  = Float32(get(specs, "move_cost",  1.0))
idle_cost  = Float32(get(specs, "idle_cost",  0.5))
eat_gain   = Float32(get(specs, "eat_gain",   5.0))
max_bite   = Float32(get(specs, "max_bite",   2.0))   # 0.4.0: handling time
e_mode     = get(specs, "brain_energy_mode", "activity")
e_base     = Float32(get(specs, "brain_energy_base",     0.001))
e_act      = Float32(get(specs, "brain_energy_activity", 0.5))
```

**What this says.** Read the user-set energetic constants once at the
top of the function rather than looking them up every iteration of the
agent loop:

- `move_cost = 1.0` — energy spent moving one cell.
- `idle_cost = 0.5` — energy spent staying in place. (Half the
  movement cost, but not zero — even a resting animal burns energy.)
- `eat_gain = 5.0` — energy gained per unit of grass consumed.
- `max_bite = 2.0` — maximum grass an agent can eat in one tick from
  one cell. **Added in 0.4.0**, see audit findings below.
- The three brain-energy parameters control how expensive thinking is.

**Biology.** All four parameters carve out a model of basal metabolic
rate and resource intake. The numbers themselves matter less than the
ratios — what matters is that:

1. Moving costs more than resting (it does, in real animals).
2. Eating yields more energy than moving costs (otherwise foraging
   is a losing strategy).
3. The maximum per-tick intake is bounded (real animals have
   handling time and gut capacity — they can't eat infinite food
   from one bush in one moment).

The `max_bite` parameter is the **handling time** constraint, well-known
from Holling's disc equation (Holling 1959, *Can. Entomol.* 91:385-398).
Without it, a forager that finds a rich patch can extract its entire
content instantly — a manifest unrealism.

**Audit findings.** The `max_bite` parameter was *missing* in clade
0.3.x — agents stripped a cell entirely each tick. The fidelity audit
flagged this as one of ten kernel rules that diverged from both
ancestor implementations (MATLAB Bulitko 2023; alifeR R port). Restored
in 0.4.0. See `dev/docs/kernel-0.4.0.md` for the full reasoning.

**Variants worth considering.** Real animals' bite size scales with body
mass (larger animals take bigger bites). A future kernel change could
make `max_bite` proportional to the agent's `body_size` trait, coupling
two existing modules. This is on the 0.4.0 backlog as a Tier 2
improvement.

---

## 3. The agent loop — apply tick logic to every living agent

```julia
fill!(env.agent_map, Int64(0))

for ag in env.agents
    ag.alive || continue
    ag.age += Int32(1)
```

**What this says.** Clear the bookkeeping map of where agents are (it
will be rebuilt as agents move during this tick). Then iterate over
every agent in the population. Skip dead ones. Increment the age of
every living agent by 1.

**Biology.** Time is discrete in this model — one tick is one unit of
biological time. The interpretation of the tick varies by scenario
(roughly a day for foraging, a generation for evolutionary dynamics).
Aging is universal and irreversible. Every agent that's alive ages
exactly one tick.

**Audit findings.** The audit on s-pace-of-life (Réale 2010) found that
metabolic rate has no effect on observed mean age — every agent dies at
`max_age = 200` regardless. This is because the always-active age cap
(in `death.jl`) overrides any pace-of-life dynamics. Tier 2 backlog item:
make `max_age` scale with `metabolic_rate` so fast-pace species have
shorter lifespans, as Réale predicts.

---

## 4. Sense — what the agent perceives

```julia
inp = sense_agent(ag, env)
```

**What this says.** Build a sensory-input vector for this agent based on
its surroundings. The function `sense_agent` (defined in `sense.jl`,
documented separately) returns a list of numbers describing what the
agent can "see": grass at its own cell, grass to the north, south,
east, west, presence of other agents nearby, its own energy and age,
plus extras when extensions like predators or signals are active.

**Biology.** This is the **perceptual world** of the agent. Real organisms
have specific sensory modalities — a frog sees motion, a bat hears
echoes, a cat smells pheromones. clade collapses all sensing into a
single vector of summary statistics. This is a deliberate
simplification — the goal is not to model sensory ecology but to give
each agent enough information that natural selection can shape its
foraging policy.

The default 11-input vector is the same across all three ancestor
implementations (MATLAB, alifeR R, clade Julia). See `sense.md` for
the per-input breakdown when that document is written.

**Audit findings.** Input normalisation differs from the ancestors:
clade normalises every input to [0, 1], while MATLAB and alifeR fed raw
values. clade's normalisation is more ML-realistic and avoids the
high-magnitude energy input dominating the network's first layer. Not a
biology issue.

---

## 5. Decide — the brain runs

```julia
logits = forward(ag.brain, inp)
action = argmax(logits)           # greedy; BNN exploration via sigma
ag.num_choices        += Int32(1)
ag.num_greedy_choices += Int32(1)
```

**What this says.** Pass the input vector through the agent's brain
(its evolved neural network), getting back a vector of five "logits" —
one for each possible action (north, east, south, west, idle). Pick the
action with the highest logit. Increment two counters tracking how many
total decisions and how many greedy decisions this agent has made.

**Biology.** This is **behavioural decision-making**, simplified to its
core: gather information, run it through your brain, choose an action.
The brain is a heritable structure (the genome encodes the network's
weights) so foraging strategy evolves across generations.

The "greedy" choice (always pick the highest-scoring action) is one of
two exploration schemes:

- For ANN, CTRNN, GRN brains: greedy = deterministic policy, behaviour
  is fully determined by current input.
- For BNN brain (the default): greedy is *randomised* because the BNN
  samples its weights from a posterior distribution before each
  forward pass. Two presentations of the same input can yield two
  different actions if `sigma > 0`. This is **Thompson sampling**,
  which is mathematically equivalent to soft exploration in
  reinforcement-learning theory.

**Audit findings.** The BNN's per-tick weight resampling (s-baldwin,
s-rl, s-social-learning audits) dilutes any within-lifetime learning —
copied or RL-trained weights get drowned out by the next tick's random
sample. Tier 5 backlog item: make BNN sample once per significant
decision interval instead of every tick.

**Variants worth considering.** Some animals (especially insects)
behave in ways closer to fixed action patterns than to flexible
decision-making. A "no-brain random walk" mode (`brain_type =
"random"`, already implemented) provides this control. For ecological
realism, *most* animals have intermediate flexibility — some habitual
behaviour interspersed with situational responses. clade's BNN
captures this when sigma is tuned.

---

## 6. Move — the energy cost of action

```julia
ag.energy_last_tick = ag.energy
x, y = Int(ag.x), Int(ag.y)
if action == 1      # N
    x = wrap_or_clamp(x - 1, rows, toroidal)
    ag.energy -= move_cost * ag.metabolic_rate
elseif action == 2  # E
    y = wrap_or_clamp(y + 1, cols, toroidal)
    ag.energy -= move_cost * ag.metabolic_rate
elseif action == 3  # S
    x = wrap_or_clamp(x + 1, rows, toroidal)
    ag.energy -= move_cost * ag.metabolic_rate
elseif action == 4  # W
    y = wrap_or_clamp(y - 1, cols, toroidal)
    ag.energy -= move_cost * ag.metabolic_rate
else                # idle
    ag.energy -= idle_cost * ag.metabolic_rate
end
ag.x = Int32(x)
ag.y = Int32(y)
```

**What this says.** Record what the agent's energy was before this
tick's actions (`energy_last_tick`, used by the RL module if active).
Update position based on the chosen action. North decreases the row
index; south increases it; east/west change the column. Idle leaves
position alone. Each action deducts an energy cost, scaled by the
agent's metabolic rate (a heritable trait — agents with higher
`metabolic_rate` pay more for the same action). Movement costs more
than resting.

**Biology.** This is the **mechanical-cost-of-living** rule. Energy is
the universal currency:

- Movement is metabolically expensive (locomotion, oxygen demand,
  muscular work).
- Resting still costs something (basal metabolic rate — heart, brain,
  organs all consume energy even at rest).
- The cost scales with the agent's intrinsic metabolic rate (Kleiber
  1932, *Hilgardia* 6:315-353; Brown et al. 2004, *Ecology* 85:1771-
  1789).

Action 5 (idle) costs *less than* movement but *not zero* — this is
biologically correct (basal vs active metabolism differ but both are
nonzero). The MATLAB ancestor charged zero for idle; the alifeR port
charged the full movement cost (a documented bug). clade's split into
`move_cost` and `idle_cost` is more realistic than either ancestor.

**Audit findings.** No specific issues — this rule is sound and
matches biology. The `metabolic_rate` heritable trait is wired up
correctly; what's broken is downstream (the always-on age cap
overrides pace-of-life signals — see audit on s-pace-of-life).

**Variants worth considering.**

1. Real movement costs scale with body mass (larger animals pay more
   per metre but per metre per gram less — Kleiber's law). A future
   change could make `move_cost` scale with `body_size`.
2. Different terrain types could carry different movement costs (mud
   slower than open ground). Currently the cost is uniform across the
   grid. This is fine for clade's grass-grid abstraction but would
   matter if the grid grew more complex.
3. The current N/E/S/W movement is **rook-style** (no diagonal). Real
   animals typically use **king-style** (8 directions) movement.
   Adding diagonals would be a small kernel change with biological
   payoff.
4. **Non-toroidal boundary semantics (surfaced by 2026-04-17
   s-predator-prey spatial-refugia audit).** Under `toroidal =
   FALSE`, `wrap_or_clamp()` clamps off-grid moves to the edge,
   which pins agents against boundaries rather than rejecting the
   move. The 2×2 Huffaker audit showed this produces edge-pile-up
   that halves prey carrying capacity (276 vs 643) and zeros the LV
   oscillation score in both homogeneous and patchy landscapes. A
   cleaner bounded-world mode would **reject** moves that step
   off-grid (agent stays put, still pays the move cost), matching
   classical reflective-boundary PDE conventions. Small kernel
   change, but requires parallel updates in `tick.jl` (movement),
   `reproduce.jl` (offspring placement), and possibly `sense.jl`
   (return "empty" for off-grid queries). Deferred until a scenario
   actually needs it.

---

## 7. Eat — the resource intake rule (0.4.0 change)

```julia
# 0.4.0: handling-time-limited intake. An agent extracts at most
# `max_bite` units of grass from the cell per tick. Multiple ticks
# (or multiple agents on consecutive ticks) are needed to deplete
# a rich cell. Restores alifeR / MATLAB-Bulitko `maxbite` semantics.
if env.grass[x, y] > 0.0f0
    bite             = min(env.grass[x, y], max_bite)
    ag.energy       += eat_gain * bite
    env.grass[x, y] -= bite
end
eat_layered!(ag, env)   # complex landscape: shrub/canopy supplements
ag.energy = min(ag.energy, Float32(get(specs, "energy_max", 200.0)))
```

**What this says.** If there's grass at the agent's current cell, take
either *all of it* or `max_bite` worth, whichever is smaller. Convert
that bite into energy via `eat_gain`. Remove the eaten amount from the
cell. Then call `eat_layered!` (a no-op unless the complex-landscape
module is enabled — when it is, agents can also eat from shrub and
canopy layers). Finally, cap the agent's energy at `energy_max` (default
200) — agents can't accumulate infinite reserves.

**Biology.** This is **foraging** — the central process of trophic
ecology. Three biological constraints are encoded:

1. **Eat where you stand.** An agent gets the resources at its
   current cell. There's no reaching, no caching, no sharing (other
   modules add those). This matches grazing herbivores well; less
   well predator-prey systems where chase-and-handle is the norm.
2. **Handling time** (`max_bite`). The agent can only process so
   much per tick. This is Holling's Type II functional response in
   its simplest form (Holling 1959).
3. **Storage capacity** (`energy_max`). Real organisms have finite
   storage — fat reserves, glycogen pools, gut volume. Once full,
   excess intake is wasted.

The 0.3.x kernel had a single line for eating:

```julia
ag.energy += eat_gain * env.grass[x, y]
env.grass[x, y] = 0.0f0
```

That was "strip the cell entirely in one tick." Both ancestors enforced
`max_bite`; clade was the outlier. Audit (Tier 1, 0.4.0) flagged this
and we restored handling time.

**Audit findings.** The 0.3.x strip-the-cell rule produced two
artefacts:

- **Per-tick energy windfalls.** Finding a rich cell could yield
  `eat_gain * grass_max` = 25 energy in one tick — distorting
  reproductive timing because the post-windfall agent immediately
  crossed `min_repro_energy`.
- **Suppressed density-dependence.** A cell could only feed one agent
  per visit; second visitors found it empty. This made shared-resource
  scenarios (cooperation, kin altruism) harder to test.

With `max_bite = 2`, the maximum windfall is 10 energy and rich cells
sustain multiple grazings.

**Variants worth considering.**

1. Bite size scaling with body size (mentioned earlier).
2. Different resource types (fruit, leaves, insects) with different
   `eat_gain` and `max_bite`. The complex-landscape module is a
   start; adding nutritional dimensions would extend it.
3. Group foraging: multiple agents on the same cell could cooperate
   to extract more (or compete to extract less). Currently each agent
   eats independently in turn (the order is a side effect of the
   `for ag in env.agents` loop).

---

## 8. Brain energy cost — thinking is expensive

```julia
ag.energy -= _brain_energy_cost(ag.brain, logits, e_mode, e_base, e_act)
```

with the helper function:

```julia
function _brain_energy_cost(brain::AbstractBrain,
                              logits::Vector{Float32},
                              mode::String,
                              base::Float32,
                              act_scale::Float32)::Float32
    mode == "none" && return 0.0f0
    size_cost = base * Float32(brain_size(brain))
    mode == "size" && return size_cost
    if mode == "activity"
        act_cost = act_scale * sum(abs, logits) / Float32(length(logits))
        return size_cost + act_cost
    end
    # prediction_error — use size cost as fallback (Phase 3 will implement KL)
    size_cost
end
```

**What this says.** After eating, deduct an additional energy cost for
running the brain. The cost depends on which mode is active:

- `"none"` — free thinking. No cost. (Useful for control runs.)
- `"size"` — cost is proportional to brain size. A bigger brain
  costs more to maintain, regardless of how active it is.
- `"activity"` (the default) — cost = size cost + activity cost.
  The activity component scales with how strongly the brain is firing
  (the average absolute logit value).
- `"prediction_error"` — currently a placeholder, falls back to size
  cost.

**Biology.** Brains are **expensive organs**. Human brains use roughly
20% of total energy budget despite being 2% of body mass (Aiello &
Wheeler 1995, *Curr. Anthropol.* 36:199-221). The "expensive brain
hypothesis" is the standard framework: large brains require sustained
high-quality energy input to maintain, which constrains brain
evolution.

clade's three modes encode three different theories of brain cost:

- `"size"` corresponds to the **expensive-tissue hypothesis** —
  larger brains cost more to maintain (basal metabolic load).
- `"activity"` corresponds to **attention cost** (Yaeger 1994,
  PolyWorld) — thinking *harder* costs more. This is the default
  because it adds a within-lifetime selection pressure on
  energy-efficient policies.
- `"prediction_error"` is reserved for an information-theoretic cost
  (KL divergence between prior and posterior) but isn't implemented.

The MATLAB ancestor charged `sum(|weights|) * annPowerCoefficient` —
size-based with weight magnitude as the proxy. alifeR didn't charge a
brain cost at all. clade's "activity" mode is the most biologically
motivated of the three — and the most novel.

**Audit findings.** The s-brain-size scenario tests the parental-
provisioning hypothesis: care is needed to bootstrap large brains
because newborns can't yet forage well. Audit found the effect is
**directionally correct but tiny** at default parameters — Δ = 0.009
units between care and no-care. Tier 2 backlog: rebalance
`brain_energy_base` and `brain_energy_activity` so the cost is more
consequential.

**Variants worth considering.**

1. Brain cost should arguably scale super-linearly with brain size
   (larger brains have disproportionate maintenance costs because of
   blood supply, cooling, and so on). Current scaling is linear.
2. Brain cost might also depend on what the agent is *doing* — high
   cognitive load tasks (hunting, navigating) cost more than habitual
   ones (grazing). Currently no task-dependence; activity mode is the
   closest approximation.
3. Newborns and juveniles might have *building* costs in addition to
   *running* costs. Currently only running cost is modelled; the
   parental-care module covers some development costs separately.

---

## 9. Rebuild the agent map

```julia
for (idx, ag) in enumerate(env.agents)
    ag.alive && (env.agent_map[ag.x, ag.y] = idx)
end
```

**What this says.** After every agent has finished its tick, walk
through the agent list and update the spatial lookup table — for each
living agent, record its current grid position.

**Biology.** Not biology — bookkeeping. The `agent_map` is a 2D array
that says, for any given cell, which agent (if any) is there. This is
needed by other parts of the kernel — especially predator hunting and
mate-finding — to quickly look up neighbours without scanning every
agent's coordinates.

**Audit findings.** No issues; this is a hot-path optimisation that
doesn't change behaviour, only speed.

---

## What this file *doesn't* do

It's worth being explicit about what `tick.jl` deliberately *omits*
from one tick of an agent's life. These responsibilities live elsewhere:

- **Birth** (`reproduce.jl`) — runs once per tick after all agents
  have ticked, scanning for eligible reproducers.
- **Death** (`death.jl`) — runs once per tick, removing agents that
  hit the death conditions (starvation, age cap, optional senescence
  or semelparous death).
- **Predation** (`modules/tick_predators.jl`) — only runs if
  `n_predators_init > 0`. Predators have their own update path; prey
  agents flagged for death by predators get removed in `kill_dead!`.
- **Optional modules** — disease transmission, kin altruism, public
  goods, mating signals, social learning, niche construction, and so
  on. Each lives in `inst/julia/src/modules/`. They are no-ops when
  their flag is off.

This separation matters: the hot-path `tick.jl` is intentionally lean,
and biological extensions live in module files that can be audited and
reasoned about in isolation.

---

## Reading guide for biologists who want to spot bugs

When skimming `tick.jl` looking for biological problems, ask:

1. **Are the energy units consistent?** Movement and idle costs are in
   the same units as eating gain. Yes (all are abstract energy units;
   ratios matter, not absolute values).
2. **Does anything happen for free?** No — every action has a cost,
   and gains require physical contact with grass. ✓
3. **Are there hidden caps or floors?** Yes — `energy_max` (line
   ~118), and `max_bite` (line ~113). Both are biologically
   defensible.
4. **Does the order of operations matter?** Yes — sense before move
   means the agent decides based on its *previous* surroundings, not
   its destination. This is biologically correct (you decide where to
   go based on what you currently see). The eating happens *after*
   moving, so the agent eats wherever it ended up, not where it
   started. Also correct.
5. **What about social effects within a tick?** Within `tick_agents!`
   each agent acts independently (no awareness of other agents'
   *current-tick* moves). Effects requiring interaction (predation,
   altruism) happen in modules called *between* ticks or after the
   tick loop. This is the standard "synchronous" ABM update; the
   alternative ("asynchronous" — process agents one at a time, fully
   completing each agent's tick before the next) is rarely used in
   the literature for performance reasons.

---

## Citations referenced in this document

- Aiello, L.C. & Wheeler, P. (1995) The expensive-tissue hypothesis.
  *Curr. Anthropol.* 36:199-221.
- Brown, J.H. et al. (2004) Toward a metabolic theory of ecology.
  *Ecology* 85:1771-1789.
- Bulitko, V. (2023) MATLAB alife codebase, `~/Documents/alifeR/alife_matlab/codebase/`.
- Holling, C.S. (1959) The components of predation as revealed by a
  study of small-mammal predation of the European pine sawfly.
  *Can. Entomol.* 91:293-320.
- Kleiber, M. (1932) Body size and metabolism. *Hilgardia* 6:315-353.
- Yaeger, L. (1994) Computational genetics, physiology, metabolism,
  neural systems, learning, vision, and behavior or PolyWorld:
  Life in a new context. *Artificial Life III*, Addison-Wesley,
  pp. 263-298.

---

*Companion documents in this directory:*

- [`README.md`](README.md) — Reading guide and Julia-for-biologists primer.
- *(planned)* `clade-main.md` — The main loop in `Clade.jl` that calls
  `tick_agents!` and orchestrates the tick order across all modules.
- *(planned)* `sense.md` — How agents perceive their environment.
- *(planned)* `reproduce.md` — Birth, inheritance, and parental cost.
- *(planned)* `death.md` — When agents die and why.
- *(planned)* `genome.md` — How heritable traits work.
