"""
    types.jl — Core type definitions for the Clade simulation.

Types defined here form a strict hierarchy:

    AbstractBrain          — interface for all agent brain implementations
    DiploidGenome          — maternal + paternal allele vectors + metadata
    Agent                  — individual organism carrying genome + brain
    Environment            — grid world containing agents + resources

Design principles
-----------------
1. All mutable state lives in `Agent` and `Environment`. `DiploidGenome` and
   concrete brain structs are immutable once created (replaced at offspring
   creation, never mutated in place). This makes the tick loop safe for
   future multi-threading.

2. Every Agent carries a `methylome` field (Vector{Bool}) regardless of
   whether `specs["epigenetics"]` is true. When epigenetics is off the
   methylome is all-false and is never read. This avoids conditional branches
   in the hot path.

3. Brain type is selected at runtime by `specs["brain_type"]` (a String).
   The AbstractBrain interface guarantees that any brain can be substituted
   without changes to tick.jl or reproduce.jl. New brain types can be added
   by extending AbstractBrain and registering in make_brain().

References
----------
- Beer, R.D. (1995) On the dynamics of small continuous-time recurrent neural
  networks. Adaptive Behavior 3(4):469–509.
- Blundell et al. (2015) Weight uncertainty in neural networks. ICML pp 1613–1622.
- Kauffman, S.A. (1993) The Origins of Order. Oxford University Press.
- Jablonka, E. & Lamb, M.J. (2005) Evolution in Four Dimensions. MIT Press.
- Vaswani et al. (2017) Attention is all you need. NeurIPS 30.
"""

# ── Abstract brain interface ───────────────────────────────────────────────────

"""
    AbstractBrain

All agent brain implementations must subtype `AbstractBrain` and implement:

- `forward(brain, input::Vector{Float32})::Vector{Float32}` — map sensory
  input to action logits.
- `mutate(brain, mutation_sd::Float32, rng)::AbstractBrain` — return a
  mutated copy of the brain.
- `crossover(b1, b2, crossover_points::Vector{Int}, rng)::AbstractBrain` —
  return an offspring brain by recombining two parent brains.
- `flatten(brain)::Vector{Float32}` — serialise brain to a flat numeric
  vector (used for genome distance and diversity calculations).
- `brain_size(brain)::Int` — number of free parameters (synaptic weights +
  biases; for BNN: 2 × n_weights for μ and σ).

Optional (default implementations provided):
- `n_actions(brain)::Int` — number of output units. Defaults to 5 (for
  the 5 standard actions: move N/E/S/W, idle).
- `n_inputs(brain)::Int` — number of sensory input units.
"""
abstract type AbstractBrain end

# Default action count (move N, E, S, W, idle)
n_actions(::AbstractBrain) = 5
n_inputs(b::AbstractBrain)  = error("n_inputs not implemented for $(typeof(b))")

# ── DiploidGenome ──────────────────────────────────────────────────────────────

"""
    DiploidGenome

Stores the complete genetic information for one individual. All fields are
immutable — the genome is replaced (not mutated in place) at reproduction.

## Fields

- `maternal_weights::Vector{Float32}` — flattened weight vector from the
  maternal haplotype. Length = brain genome size.
- `paternal_weights::Vector{Float32}` — same from the paternal haplotype.
  For haploid organisms (`ploidy == 1`), `paternal_weights` is an empty
  vector.
- `maternal_traits::Vector{Float32}` — scalar heritable traits (body_size,
  immune_strength, cooperation_level, dispersal_tendency, metabolic_rate,
  aging_rate, repro_threshold, mutation_sd, learning_rate) from maternal copy.
  Length fixed to `N_SCALAR_TRAITS`.
- `paternal_traits::Vector{Float32}` — same from paternal copy (empty when
  haploid).
- `architecture::Vector{Int32}` — brain architecture specification. For ANN
  and BNN: layer widths including input and output. For GRN: [n_genes,
  n_sensory_genes, n_action_genes]. For Transformer: [n_inputs, n_heads,
  n_history, n_outputs].
- `n_chromosomes::Int32` — number of chromosome pairs (default 1). Affects
  how crossover_points are assigned during meiosis.

## Ploidy convention

When `ploidy == 1` (haploid), `paternal_weights` and `paternal_traits` are
empty (`Float32[]`). All operations that read paternal alleles check
`isempty(g.paternal_weights)` and fall back to maternal. This avoids a
separate haploid type while allowing the same reproduction code to serve
both ploidy levels.
"""
struct DiploidGenome
    maternal_weights ::Vector{Float32}
    paternal_weights ::Vector{Float32}
    maternal_traits  ::Vector{Float32}
    paternal_traits  ::Vector{Float32}
    architecture     ::Vector{Int32}
    n_chromosomes    ::Int32
end

"""Number of scalar traits stored per haplotype in `DiploidGenome`."""
const N_SCALAR_TRAITS = 15

# Scalar trait indices (into maternal_traits / paternal_traits)
const TRAIT_BODY_SIZE             = 1
const TRAIT_IMMUNE_STRENGTH       = 2
const TRAIT_COOPERATION_LEVEL     = 3
const TRAIT_DISPERSAL_TENDENCY    = 4
const TRAIT_METABOLIC_RATE        = 5
const TRAIT_AGING_RATE            = 6
const TRAIT_REPRO_THRESHOLD       = 7
const TRAIT_MUTATION_SD           = 8
const TRAIT_LEARNING_RATE         = 9
const TRAIT_HABITAT_PREFERENCE    = 10
const TRAIT_HELPER_TENDENCY       = 11
const TRAIT_PLASTICITY            = 12
const TRAIT_TOXICITY              = 13
const TRAIT_WING_SIZE             = 14
const TRAIT_BRAIN_SIZE            = 15

"""
    is_haploid(g::DiploidGenome) -> Bool

Return `true` when the genome encodes a haploid organism (paternal vectors
are empty).
"""
is_haploid(g::DiploidGenome) = isempty(g.paternal_weights)

# ── Agent ──────────────────────────────────────────────────────────────────────

"""
    Agent

A single organism in the simulation. All simulation state for one individual
is contained here. Fields are a superset of the trait set in alifeR; unused
fields default to biologically neutral values (0 or false) and are never read
in hot-path code when the corresponding module is disabled.

## Identity and position
- `id::Int64` — unique ID, assigned sequentially from `env.next_id`.
- `parent_id::Int64` — ID of the agent that produced this individual (0 for
  founding agents).
- `mate_id::Int64` — ID of the second parent (0 for asexual/haploid).
- `x::Int32`, `y::Int32` — grid position (1-indexed).

## Energy and state
- `energy::Float32` — current energy. Agent dies when energy < starvation_threshold.
- `age::Int32` — ticks elapsed since birth.
- `t_birth::Int32` — tick at which this agent was born.
- `alive::Bool` — false after death; agent is removed from env.agents before
  the next tick.

## Brain and genome
- `brain::AbstractBrain` — the expressed phenotype brain (computed once at
  birth by `express_phenotype()`).
- `genome::DiploidGenome` — the genotype (not changed within a lifetime).
- `methylome::Vector{Bool}` — epigenetic methylation marks; length matches
  `brain_size(brain)`. All false when `epigenetics == false`.

## Expressed scalar traits (phenotype, not changed within lifetime)
- `body_size::Float32` — scales metabolic costs via Kleiber's law.
- `immune_strength::Float32` — reduces transmission probability and disease
  mortality.
- `cooperation_level::Float32` — fraction of resources contributed to the
  local public goods pool.
- `dispersal_tendency::Float32` — probability of moving to a random cell
  rather than the locally optimal cell.
- `metabolic_rate::Float32` — scales move_cost and idle_cost.
- `aging_rate::Float32` — scales the Gompertz senescence exponent.
- `repro_threshold::Float32` — minimum energy required to attempt
  reproduction (may differ from specs when life_history_evolution = true).
- `mutation_sd::Float32` — mutational variance for this individual's
  offspring (when mutation_rate_evolution = true).
- `learning_rate::Float32` — within-lifetime RL step size (when
  learning_rate_evolution = true).

## Signal evolution
- `signal::Vector{Float32}` — heritable signal vector (length = signal_dims).
- `preference::Vector{Float32}` — mate preference vector.

## Mimicry / toxicity
- `toxicity::Float32` — heritable toxicity level (0 = non-toxic, 1 = maximally
  toxic). Used in mimicry module only.

## Disease (SIR)
- `infected::Bool`, `immune::Bool`
- `infection_age::Int32` — ticks since infection began.
- `immunity_age::Int32` — ticks since recovery began.

## Parental care
- `carried_offspring::Vector{Agent}` — juveniles currently in care.
- `care_load::Int32` — number of carried offspring.

## Within-lifetime RL (REINFORCE with baseline)
- `value_estimate::Float32` — running mean reward (baseline).
- `energy_last_tick::Float32` — energy at end of previous tick.

## Reproductive tracking
- `reproduced::Bool` — true if reproduced this tick (used by semelparous
  life history).
- `num_offspring::Int32` — cumulative offspring count.
- `num_choices::Int32` — cumulative action choices made.
- `num_greedy_choices::Int32` — actions that matched arg-max of logits.

## Speciation
- `species_id::Int32` — cluster ID assigned at each logging tick by
  hierarchical clustering of genome distances. Updated externally; 0 when
  speciation = false.

## Natal dispersal
- `x_birth::Int32`, `y_birth::Int32` — grid position where this agent was
  born (or graduated from parental care). Used by the dispersal module to
  compute direction-away-from-birthplace. Set at construction and never
  updated within a lifetime.
"""
mutable struct Agent
    # Identity
    id              ::Int64
    parent_id       ::Int64
    mate_id         ::Int64
    x               ::Int32
    y               ::Int32

    # Energy and lifecycle
    energy          ::Float32
    age             ::Int32
    t_birth         ::Int32
    alive           ::Bool

    # Brain and genome
    brain           ::AbstractBrain
    genome          ::DiploidGenome
    methylome       ::Vector{Bool}

    # Expressed scalar traits
    body_size           ::Float32
    immune_strength     ::Float32
    cooperation_level   ::Float32
    dispersal_tendency  ::Float32
    metabolic_rate      ::Float32
    aging_rate          ::Float32
    repro_threshold     ::Float32
    mutation_sd         ::Float32
    learning_rate       ::Float32

    # Signal evolution
    signal          ::Vector{Float32}
    preference      ::Vector{Float32}

    # Mimicry
    toxicity        ::Float32

    # Disease
    infected        ::Bool
    immune          ::Bool
    infection_age   ::Int32
    immunity_age    ::Int32

    # Parental care
    carried_offspring ::Vector{Any}   # Vector{Agent} (forward-declared as Any)
    care_load          ::Int32

    # RL
    value_estimate     ::Float32
    energy_last_tick   ::Float32

    # Reproductive tracking
    reproduced         ::Bool
    num_offspring      ::Int32
    num_choices        ::Int32
    num_greedy_choices ::Int32

    # Speciation
    species_id         ::Int32

    # Natal dispersal (birth location, never updated within lifetime)
    x_birth            ::Int32
    y_birth            ::Int32

    # Habitat preference (expressed trait; 0 = none, + = prefer rich, - = avoid rich)
    habitat_preference ::Float32

    # Cooperative breeding
    helper_tendency    ::Float32   # probability of acting as alloparent (0 when disabled)

    # Phenotypic plasticity
    plasticity         ::Float32   # modifies repro_threshold based on local resource richness

    # Complex landscape (Tier 1)
    wing_size          ::Float32   # heritable; 0=ground-bound, 1=full aerial; canopy access when >= canopy_threshold
    niche_layer        ::Int32     # current resource layer: 1=ground, 2=shrub, 3=canopy (updated per tick)

    # Brain size evolution (parental provisioning hypothesis)
    brain_size         ::Float32   # heritable cognitive capacity trait (1.0 = reference)
end

# ── Environment ────────────────────────────────────────────────────────────────

"""
    Environment

The simulation world. Contains the agent population, resource grid, per-tick
counters, and all logged statistics. Passed by reference through every
function in the tick loop.

## Grid
- `grass::Matrix{Float32}` — grass density per cell (rows × cols).
- `agent_map::Matrix{Int64}` — cell → agent index (0 = empty). Updated after
  every tick.
- `predator_map::Matrix{Int64}` — same for predators.
- `shelter_map::Matrix{Int32}` — shelter depth per cell (niche construction).
- `carrion_map::Matrix{Float32}` — carrion energy per cell (scavenging).

## Population
- `agents::Vector{Agent}` — all live agents.
- `predators::Vector{Agent}` — all live predators.
- `next_id::Int64` — next unique ID to assign.
- `t::Int32` — current tick (1-indexed).
- `rng::AbstractRNG` — random number generator (seeded by specs["random_seed"]).

## Specs (copied once at construction)
- `specs::Dict{String,Any}` — the full parameter list for this run.

## Per-tick module counters (reset to 0 at start of each tick)
All counters are `Int32` unless noted.
- `n_births`, `n_deaths`, `n_starvations`, `n_age_deaths`
- `n_new_infections`, `n_recoveries`
- `n_altruistic_acts`, `n_cooperation_acts`
- `n_shelters_built`, `n_graduations`, `n_juv_deaths`
- `n_toxic_attacks`, `n_avoided_attacks`
- `n_dispersal_events` — agents that dispersed away from birthplace this tick

## Logging (pre-allocated for max_ticks rows)
- `progress::Dict{String, Vector}` — named vectors, one entry per log tick.
  Populated by `log_tick!()`.
- `deaths::Dict{String, Vector}` — per-death records.
"""
mutable struct Environment
    # Grid
    grass        ::Matrix{Float32}
    agent_map    ::Matrix{Int64}
    predator_map ::Matrix{Int64}
    shelter_map  ::Matrix{Int32}
    carrion_map  ::Matrix{Float32}
    # Complex landscape resource layers (Tier 1; zero matrices when complex_landscape=false)
    shrub_map    ::Matrix{Float32}
    canopy_map   ::Matrix{Float32}

    # Population
    agents       ::Vector{Agent}
    predators    ::Vector{Agent}
    next_id      ::Int64
    t            ::Int32
    rng          ::Any   # AbstractRNG (forward-declared)

    # Parameters
    specs        ::Dict{String,Any}

    # Per-tick counters
    n_births            ::Int32
    n_deaths            ::Int32
    n_starvations       ::Int32
    n_age_deaths        ::Int32
    n_new_infections    ::Int32
    n_recoveries        ::Int32
    n_altruistic_acts   ::Int32
    n_cooperation_acts  ::Int32
    n_shelters_built    ::Int32
    n_graduations       ::Int32
    n_juv_deaths        ::Int32
    n_toxic_attacks     ::Int32
    n_avoided_attacks   ::Int32
    n_dispersal_events  ::Int32
    n_habitat_moves     ::Int32
    n_helpers           ::Int32   # cooperative breeding helper acts this tick
    # New module counters (Tier 2)
    n_front_agents      ::Int32   # spatial sorting: agents at range front this tick
    n_iffolk_transfers  ::Int32   # IFfolk: energy transfers this tick

    # Logging
    progress     ::Dict{String, Vector}
    deaths       ::Dict{String, Vector}
    genome_log   ::Vector{Any}   # Vector{Matrix{Float32}} when log_genomes
end
