# Clade.jl — the main loop, in biological order

## `Clade.jl` — the main loop, in biological order

`Clade.jl` is the orchestrator. It contains the main `for t in 1:max_t`
loop and decides *what runs in what order* during each tick. Every
biology module (predators, disease, kin altruism, mating, etc.) gets
called from this file, in a specific sequence.

The order matters. Eating before death means starving agents get one
last meal. Reproduction after death means dead parents don’t reproduce.
These choices encode biological assumptions about how a tick maps to
real time.

This document walks the main tick loop in execution order.

Source file:
[`inst/julia/src/Clade.jl`](https://github.com/itchyshin/clade/blob/main/inst/julia/src/Clade.jl#L336)
(lines 336–414).

------------------------------------------------------------------------

### 1. The tick loop

``` julia
max_t = Int(specs["max_ticks"])
verbose = Bool(get(specs, "verbose", false))

for t in 1:max_t
    env.t = Int32(t)
    _reset_counters!(env)
```

**What this says.** Read how many ticks the user wants to run. Then loop
from tick 1 to that many. At the top of every tick, set the
environment’s clock and zero out the per-tick event counters
(`n_births`, `n_deaths`, `n_toxic_attacks`, etc., which are summed
across all events within this single tick).

**Biology.** A tick is the unit of biological time. Different scenarios
interpret it differently — for foraging it’s roughly a day; for
generational dynamics it’s about a year. The model doesn’t fix this; the
user does, by choosing parameter scales (`grass_rate`, `min_repro_age`).

The per-tick counter reset is bookkeeping: each tick is treated as an
independent reporting interval. Cumulative totals are reconstructed by
summing across ticks if needed.

------------------------------------------------------------------------

### 2. Resource regrowth — environment first

``` julia
grow_grass!(env)
apply_fixed_patch!(env)           # fixed patch: replenish stable cell(s) after growth
grow_resources!(env)              # complex landscape: shrub + canopy regrowth
```

**What this says.** First, grow grass everywhere (each empty cell has
some probability of growing one unit, up to a cap). Then, if a
`fixed_patch` is configured, replenish those special cells. Then, if
`complex_landscape` is enabled, grow the shrub and canopy layers too.

**Biology.** This is **primary production**. The grid is the world; the
grass is the energy that flows into the food web from the sun. Real
ecosystems regenerate primary producers on a daily-to-seasonal
timescale; `grow_grass!` does it once per tick.

Three notable biological decisions are baked in here:

1.  **Probabilistic regrowth.** Each cell either grows or doesn’t — it’s
    not “grass-rate units of growth per cell, deterministically.” This
    produces patchy renewal and prevents the grid from synchronising
    into a uniform “grass wave.”
2.  **Cap.** Cells can’t accumulate grass beyond `grass_max`. Real
    meadows have biomass caps too — at some density, grass shades itself
    out, runs out of light, gets eaten. The cap abstracts all that.
3.  **Resources before agents.** Grass grows *before* agents act each
    tick. So agents act on a freshly-replenished world, not on
    yesterday’s leftovers. This makes foraging slightly more generous
    than the alternative (act first, then regrow).

**Audit findings.** The seasonal modulation built into `grow_grass!`
(rate scales sinusoidally when `seasonal_amplitude > 0`) was tested by
the s-seasonal audit and produces classic half-period anti-correlation
in grass coverage (lag-25 ac = -0.58 at amp=0.8). Mechanism works.

------------------------------------------------------------------------

### 3. Niche construction — agents shape their environment

``` julia
# Niche construction runs before tick_agents! so shelters built or
# decayed this tick affect grass growth (already applied) and are
# seen by predators / sensing during movement.
apply_niche_construction!(env)
```

**What this says.** If `niche_construction = TRUE`, agents that have
enough energy build (or decay) shelters on their current cell. This runs
*before* the agent tick so shelters built this tick affect what agents
perceive when they move next.

**Biology.** **Ecosystem engineering** — organisms that modify their own
selective environment (Odling-Smee et al. 2003). Beavers building dams,
earthworms aerating soil, agents in clade building shelters that
suppress local grass and provide a metabolic bonus.

The placement before the agent tick is a deliberate biological choice:
it means shelters are *durable infrastructure* visible to all agents in
the same tick, not transient effects. This matches the slow-decay
dynamics of real ecosystem engineering.

**Audit findings.** s-niche audit ✅ passed: 15,668 shelters built per
run, occupancy bonus channel raises population +22 agents over no-bonus
control. Mechanism works as documented (Odling-Smee).

------------------------------------------------------------------------

### 4. Predator seeding — only on tick 1

``` julia
# Seed predators on first tick if enabled
t == 1 && seed_predators!(env)
```

**What this says.** On the first tick only (and only if predators are
enabled), populate the environment with the initial predator
individuals.

**Biology.** Predators are deferred to tick 1 (rather than created
during environment initialisation) because their initial population size
and brain genomes need to be drawn from the prey-population
infrastructure. This is a kernel implementation detail rather than a
biological decision.

------------------------------------------------------------------------

### 5. Agent ticks — the heart

``` julia
tick_agents!(env)
tick_predators!(env)              # predator sense-decide-act loop
```

**What this says.** Run the per-agent tick logic for every prey agent
(documented in detail in [tick.jl chapter](k-tick.md)). Then run the
predator update loop.

**Biology.** This is where most of the per-tick action lives. Each prey
agent senses, decides, moves, eats, and pays its metabolic costs. Each
predator does the same plus attack logic. See the [tick.jl
chapter](k-tick.md) for the full breakdown.

The ordering — prey first, then predators — matters: it means predators
react to *post-move* prey positions, not *pre-move*. Real predator-prey
interactions are messier (both are moving simultaneously), but in a
discrete-tick model the order has to be picked. Putting predators second
models predators as faster decision-makers, biologically reasonable for
ambush predators.

------------------------------------------------------------------------

### 6. Trait-evolution corrections — apply phenotypic effects

``` julia
apply_body_size!(env)             # metabolic + foraging correction
apply_brain_size_evolution!(env)  # expensive brain + cognitive foraging
apply_ann_regularization!(env)    # L1/L0 weight complexity penalty
apply_dispersal!(env)             # natal dispersal away from birthplace
apply_habitat_preference!(env)    # secondary move toward preferred habitat
apply_seasonal_mortality!(env)    # winter death probability
apply_toxicity_costs!(env)        # mimicry: per-tick toxicity energy cost
apply_signal_costs!(env)          # signal evolution: per-tick signal cost
apply_signal_evolution!(env)      # signal drift mutation (when enabled)
```

**What this says.** A series of optional modifications applied after the
basic agent tick. Each is a no-op unless its flag is on. Examples:

- `apply_body_size!` corrects metabolic cost based on each agent’s
  evolved body size.
- `apply_brain_size_evolution!` adds the expensive-brain surcharge.
- `apply_dispersal!` performs additional movement based on the evolved
  dispersal trait.
- `apply_toxicity_costs!` deducts the metabolic cost of producing toxins
  (mimicry scenario).

**Biology.** Each call corresponds to a specific biological hypothesis
that can be turned on independently. The structure is **layered**: core
biology runs in `tick_agents!`; trait-evolution modules add post-hoc
corrections. This is a kernel architecture choice with biological
consequences:

- **Pro:** modules can be tested in isolation; turning a flag on doesn’t
  require kernel changes.
- **Con:** modules can interact in unintended ways. If `body_size` and
  `metabolic_rate` both correct movement cost, the order of correction
  matters.

**Audit findings.** Body-size audit found that predation produces
*smaller* bodies, not larger, opposite to the Shine 2011 cane-toad
prediction. Diagnosis: clade’s predator detection is signal-strength
based (larger prey are more detectable), so predators preferentially
remove the largest agents. This is a different biological prediction
than Shine’s, both are valid, audit-flagged for vignette prose update.

------------------------------------------------------------------------

### 7. Optional modules — biology extensions

``` julia
# (each is a no-op when its flag is false)
if t == 1 && Bool(get(specs, "disease", false))
    seed_disease!(env)
end
apply_disease!(env)
apply_kin_altruism!(env)
apply_iffolk!(env)                # IFfolk inclusive fitness + parliament suppression
apply_scavenging!(env)
decay_carrion!(env)
apply_cooperation!(env)
apply_epigenetics!(env)
apply_care_costs!(env)            # parental care energy cost
feed_offspring!(env)              # parental care: feed juveniles
age_juveniles!(env)               # parental care: age + metabolic cost
apply_cooperative_breeding!(env)  # alloparental helper transfers
```

**What this says.** Run each optional biology module in turn. If the
module’s flag is off, it returns immediately without doing anything.

**Biology.** This is the **extensions library**. Disease (SIR), kin
altruism (Hamilton 1964), inclusive fitness, scavenging, public-goods
cooperation, epigenetic inheritance, parental care, cooperative breeding
— each is a separate biological theory implemented as an opt-in module.

The order encodes biological assumptions about timing within a tick:

- Disease seeds on tick 1, then transmits/recovers each tick after.
- Kin altruism happens after the agent tick (so donors have made their
  move and consumed their food, then check if a relative needs help).
- Scavenging and carrion decay are paired — agents consume carrion
  first, then remaining carrion decays. (Reverse order would mean
  carrion always decays before being eaten — biologically odd.)
- Parental care has three sub-steps: cost (parent pays), feeding
  (juvenile gains), aging (juvenile gets older). Order: cost → feed →
  age means parent pays before juvenile benefits, which is the realistic
  flow.

**Audit findings.** Most of these passed cleanly (kin ρ=0.97,
cooperation ρ=1.00, disease ρ=1.00, niche +22 agents, scavenging +5
agents). Those that didn’t (mimicry scalar memory, parental- investment
coupling) have separate kernel issues already in the 0.4.0 backlog.

------------------------------------------------------------------------

### 8. Conditional modules — frequency-gated

``` julia
# Social learning: every social_learning_freq ticks
if Bool(get(specs, "social_learning", false))
    sl_freq = Int(get(specs, "social_learning_freq", 10))
    sl_freq > 0 && t % sl_freq == 0 && apply_social_learning!(env)
end
# Within-lifetime RL: every rl_update_freq ticks
if String(get(specs, "rl_mode", "none")) != "none"
    rl_freq = Int(get(specs, "rl_update_freq", 1))
    rl_freq > 0 && t % rl_freq == 0 && apply_rl!(env)
end
# Speciation clustering every N ticks
assign_species!(env)
```

**What this says.** Some modules don’t run every tick. Social learning
and within-lifetime RL run only every Nth tick (configurable).
Speciation clustering runs at its own frequency (set inside the module).

**Biology.** **Timescale separation** — a key concept in ecology. Some
processes are faster than others. Within-lifetime learning happens
multiple times per generation but not every minute. Cultural
transmission (social learning) is even slower. Speciation is slower
still — the clustering algorithm doesn’t need to run every tick to
detect lineage divergence.

The frequency-gating saves compute (each module call is expensive) and
also models the biology: a population doesn’t undergo speciation
clustering every day. The default `social_learning_freq = 10` means
copying happens every 10 ticks, roughly weekly if a tick is a day.

------------------------------------------------------------------------

### 9. Death and reproduction — close the demographic cycle

``` julia
kill_dead!(env)
remove_dead!(env)
graduate_offspring!(env)          # parental care: promote juveniles
create_offspring!(env)
```

**What this says.** First, mark agents that should die this tick
(`kill_dead!` — sets `alive = false`). Then physically remove them from
the agent list (`remove_dead!`). Then check if any parental-care
juveniles have aged out and should join the adult population
(`graduate_offspring!`). Finally, scan for eligible parents and create
new offspring (`create_offspring!`).

**Biology.** This is the **demographic accounting** at the end of each
tick. Three biological choices:

1.  **Death before reproduction.** Agents that are about to die get one
    last chance to act and eat (in `tick_agents!`) but cannot reproduce
    in their dying tick. This is a deliberate choice: it means starving
    parents don’t get one last “death-bed” reproduction. Some species do
    undergo this kind of “terminal investment” — the choice here is to
    model the more common case where reproduction requires being alive
    *at the end of* the tick.
2.  **Graduation before new births.** Juveniles still being carried by
    parents are checked for graduation *before* new offspring are
    created. This means if a parent’s brood graduates this tick, it can
    then have new offspring on the same tick — a real biological pattern
    (mothers can have a new clutch as soon as the previous one is
    independent).
3.  **`kill_dead!` and `remove_dead!` are split.** Marking and removing
    are separate steps because some downstream code (logging, last-tick
    statistics) needs to see the just-died agents one more time.

**Audit findings.** s-life-history audit ✅ passed all three sign
predictions. The death/reproduction ordering is sound; what was missing
was honest documentation of the asymmetric (rather than
parental-investment-coupled) cost. 0.4.0 fixes the latter.

------------------------------------------------------------------------

### 10. Logging

``` julia
log_freq = Int(get(specs, "log_freq", 1))
if t % log_freq == 0
    log_tick!(env)
end

if verbose && t % 100 == 0
    @info "tick $t: $(length(env.agents)) agents alive"
end
```

**What this says.** Every `log_freq` ticks (default: every tick), record
the per-tick statistics that downstream R analysis will read. If verbose
mode is on, also print a status line every 100 ticks.

**Biology.** Pure observation — the simulation doesn’t change behaviour
based on logging frequency. But logging cadence affects *statistical
resolution*: logging every tick means we can detect fast oscillations
(e.g. epidemic peaks); logging every 10 ticks saves disk space at the
cost of resolution.

Default `log_freq = 1` is the safe choice for biology — record
everything, downsample later if needed.

------------------------------------------------------------------------

### What this file *doesn’t* do

- **Per-agent decisions.** Those are in `tick_agents!` ([tick.jl
  chapter](k-tick.md)).
- **Reproduction logic.** That’s in `create_offspring!` ([reproduce.jl
  chapter](k-reproduce.md)).
- **Death decisions.** Those are in `kill_dead!` ([death.jl
  chapter](k-death.md)).
- **Sensing.** That’s in `sense_agent` ([sense.jl chapter](k-sense.md)).
- **Module logic.** Each module file in `inst/julia/src/modules/`.

`Clade.jl` is *just the orchestrator* — it answers “in what order do
biological processes run within a tick?” and nothing more. The processes
themselves are defined elsewhere.

------------------------------------------------------------------------

### Reading guide for biologists who want to spot bugs

Things to check when reading this file:

1.  **Is the order biologically defensible?** Resource growth before
    agent action, prey before predators, agent action before death,
    death before reproduction — these are all biologically reasonable.
    Other orderings are possible (e.g., predators before prey), and each
    choice has consequences for steady-state dynamics.
2.  **Are conditional modules gated correctly?** Yes — every module call
    returns immediately if its flag is off, so the cost of an inactive
    module is negligible.
3.  **Does anything happen “twice” by accident?** The trait-evolution
    corrections (`apply_body_size!`, `apply_brain_size_evolution!`,
    etc.) all run after `tick_agents!`, but they each correct different
    aspects of the agent state. As long as no two modules correct the
    *same* field, this is safe.
4.  **Are there subtle race conditions across modules?** Not in the
    single-threaded execution here. If we ever go multithreaded within a
    tick, the per-agent loops (in `tick_agents!`) would need to be
    carefully ordered.

------------------------------------------------------------------------

### Citations referenced in this document

- Hamilton, W.D. (1964) The genetical evolution of social behaviour. *J.
  Theor. Biol.* 7:1-52.
- Odling-Smee, F.J., Laland, K.N., Feldman, M.W. (2003) *Niche
  Construction.* Princeton.
- Shine, R. et al. (2011) An evolutionary process that assembles
  phenotypes through space rather than through time. *Proc. R. Soc. B*
  278:1449-1457.

------------------------------------------------------------------------

------------------------------------------------------------------------

### Companion chapters

- [Kernel as biology — overview](k-README.md)
- [tick.jl — one tick in the life of an agent](k-tick.md)
- [Clade.jl — the main loop, in biological order](k-clade-main.md)
- [sense.jl — what an agent perceives](k-sense.md)
- [reproduce.jl — birth, inheritance, parental cost](k-reproduce.md)
- [death.jl — when agents die and why](k-death.md)
- [genome.jl — meiosis, traits, inheritance](k-genome.md)
