# Default simulation parameters for clade

Returns a named list of all simulation parameters with type-annotated
defaults. Every parameter is documented below. Pass a modified copy to
[`run_alife()`](run_alife.md) or
[`search_map_elites()`](search_map_elites.md).

## Usage

``` r
default_specs()
```

## Value

A named list of simulation parameters.

## Details

### Grid and population

- `grid_rows`:

  Integer. Number of rows in the grid (default 30).

- `grid_cols`:

  Integer. Number of columns in the grid (default 30).

- `toroidal`:

  Logical. `TRUE` (default) wraps grid edges so that moving off one side
  re-enters on the opposite side (classic torus). `FALSE` clamps at
  boundaries, producing true edges — required for Huffaker-1958-style
  spatial-refugia dynamics and any scenario where corner/edge effects
  matter. Used by movement, sensing, dispersal, kin-scan, group-defense,
  and cooperative-breeding code paths via `wrap_or_clamp()`.

- `n_agents_init`:

  Integer. Number of agents at tick 0 (default 50).

- `max_agents`:

  Integer. Hard cap on live agents; new offspring are rejected if this
  is exceeded (default 500).

- `max_ticks`:

  Integer. Simulation length in ticks (default 500).

### Energy and metabolism

- `energy_init`:

  Numeric. Energy each agent starts with (default 100).

- `energy_max`:

  Numeric. Maximum energy an agent can hold (default 200).

- `move_cost`:

  Numeric. Energy deducted per move action (default 1).

- `idle_cost`:

  Numeric. Energy deducted when agent does not move (default 0.5).

- `eat_gain`:

  Numeric. Energy gained per unit of grass consumed (default 5).

- `max_bite`:

  Numeric. **0.4.0.** Maximum grass units extracted from a cell per tick
  (default 2.0). Implements *handling time*: a rich cell cannot be
  stripped in one step, and multiple agents can graze the same cell
  across ticks. Restores the alifeR / MATLAB ancestor's `maxbite`
  semantics. Per-tick energy income is bounded at `max_bite * eat_gain`.

- `min_repro_energy`:

  Numeric. Minimum energy required to attempt reproduction (default
  120).

- `repro_cost_mode`:

  Character. **0.4.0.** `"proportional"` (default) deducts
  `repro_cost_fraction * parent_energy` per offspring; `"fixed"` deducts
  a constant `repro_cost`. Proportional cost implements Smith &
  Fretwell (1974) parental investment: parents in better condition have
  more to invest. Fixed mode preserved for reproducibility of pre-0.4.0
  runs.

- `repro_cost`:

  Numeric. Energy deducted from parent per offspring when
  `repro_cost_mode = "fixed"` (default 30, ignored when mode is
  `"proportional"`).

- `repro_cost_fraction`:

  Numeric in (0, 1). **0.4.0.** Fraction of parent energy paid per
  offspring when `repro_cost_mode = "proportional"` (default 0.5).

- `offspring_energy_mode`:

  Character. **0.4.0.** `"proportional"` (default) sets newborn energy
  to `offspring_energy_fraction * cost_paid` (Smith & Fretwell quality-
  quantity); `"fixed"` sets newborn energy to constant
  `offspring_energy` (legacy).

- `offspring_energy`:

  Numeric. Energy given to each new offspring when
  `offspring_energy_mode = "fixed"` (default 60).

- `offspring_energy_fraction`:

  Numeric in (0, 1). **0.4.0.** Fraction of `cost_paid` allocated to
  each offspring when `offspring_energy_mode = "proportional"` (default
  0.25).

- `starvation_threshold`:

  Numeric. Agent dies when energy falls below this value (default 0).

### Grass dynamics

- `grass_init_prob`:

  Numeric in \[0, 1\]. Probability each cell starts with grass (default
  0.5).

- `grass_rate`:

  Numeric in \[0, 1\]. Per-tick probability that an empty cell grows
  grass (default 0.05).

- `grass_max`:

  Numeric. Maximum grass units per cell (default 5).

### Brain architecture

The brain type controls how agents map sensory inputs to action
decisions. All types are heritable and evolvable. See the references in
each entry for the primary literature.

- `brain_type`:

  Character. One of `"bnn"` (default), `"ann"`, `"ctrnn"`, `"grn"`,
  `"transformer"`, `"synthesis"`, or `"random"`. BNN = Bayesian neural
  network (Neal 1996; Blundell et al. 2015); ANN = multilayer perceptron
  (Rumelhart et al. 1986); CTRNN = continuous-time recurrent network
  (Beer 1995); GRN = gene regulatory network (Kauffman 1993);
  transformer = attention over sensory history (Vaswani et al. 2017);
  synthesis = evolved symbolic IF-THEN rules (Koza 1992); random = null
  baseline. See
  [`vignette("custom-modules")`](../articles/custom-modules.md) for
  architecture details.

- `hidden_layers`:

  Integer vector. Hidden layer widths for `"ann"` and `"bnn"` (default
  `c(8L)`; gives one hidden layer of 8 units). Set to `c(16L, 8L)` for
  two hidden layers.

- `input_radius`:

  Integer. Radius of the Moore neighbourhood used when building each
  agent's sensory input vector (default `1L`). Radius 1 gives the
  standard 8-cell neighbourhood; radius 2 extends to the 24-cell
  neighbourhood. Increasing this value expands the input vector and the
  brain's first-layer width accordingly.

- `n_genes`:

  Integer. Number of genes for `"grn"` brain type (default 20L).
  Includes sensory input genes and action output genes.

- `transformer_history`:

  Integer. Number of past sensory inputs the transformer attends over
  (default 8L).

- `transformer_heads`:

  Integer. Number of attention heads (default 2L).

- `synthesis_max_rules`:

  Integer. Maximum number of IF-THEN rules per agent (default 10L).

- `ann_weight_values`:

  Numeric vector or `NULL`. When not `NULL`, every synaptic weight and
  bias is snapped to the nearest value in this set immediately after
  genome expression (before the first forward pass each generation). Use
  `c(-1, 0, 1)` for ternary weights or `c(-1, 1)` for binary weights.
  Applies to `"ann"` and `"bnn"` brain types. Biologically motivated by
  evidence that biological synapses operate in a small number of
  discrete strength states (Bhumbra & Bhatt 2020). Also enables symbolic
  formula distillation from evolved ANNs (as in the original MATLAB
  alife2025usra codebase). Default `NULL` = continuous weights.

- `ann_regularization`:

  Character. Energy penalty on brain weight complexity: `"none"`
  (default), `"weight_magnitude"` (L1: deduct `lambda * sum(|w|)` per
  tick), or `"weight_count"` (L0-like: deduct
  `lambda * n_active_weights` per tick). References: Laughlin et
  al. (1998) *Nature Neuroscience* 1:36–41; Attwell & Laughlin (2001)
  *J. Cerebral Blood Flow and Metabolism* 21:1133–1145.

- `ann_regularization_lambda`:

  Numeric. Scale factor for the regularisation penalty (default 0.001).
  Too large a value will cause all weights to collapse to zero within a
  few ticks.

### Brain energy cost

Brain energy cost models the metabolic cost of neural computation, as in
the Polyworld simulation (Yaeger 1994).

- `brain_energy_mode`:

  Character. One of `"none"` (no cost), `"size"` (proportional to
  synapse count), `"activity"` (default; base + activity-scaled cost),
  or `"prediction_error"` (BNN-only; KL divergence between prior and
  posterior). Reference: Yaeger (1994) PolyWorld, in *Artificial Life
  III*, pp 263–298.

- `brain_energy_base`:

  Numeric. Fixed cost per synaptic weight per tick (default 0.001).

- `brain_energy_activity`:

  Numeric. Scaling factor on mean absolute activation when
  `brain_energy_mode = "activity"` (default 0.5).

- `brain_energy_size_exponent`:

  Numeric. Exponent applied to the brain-size term of the metabolic
  cost: `size_cost = base * n_weights^exp` (default 1.0 = linear,
  legacy). Set to 1.5 for Kleiber-style super-linear scaling (Isler &
  van Schaik 2009 expensive-brain hypothesis) so large brains carry
  disproportionate metabolic weight — sharpens the parental-provisioning
  selection gradient at the default `brain_energy_base` without needing
  a scenario-specific override (0.4.3).

- `brain_energy_sigma_scale`:

  Numeric. Log-scaled information cost on BNN posterior width (sigma).
  When \> 0, each tick costs
  `scale * mean(max(log(sigma / sigma_min), 0))` energy. Default 0 (no
  cost). Set 0.005–0.1 for Baldwin canalisation scenarios. Reference:
  Aiello & Wheeler (1995) expensive-tissue hypothesis. Added 0.4.1 Tier
  5C.

- `bnn_action_noise_scale`:

  Numeric in \[0, 1\]. Controls how much BNN sigma contributes to action
  noise during the forward pass: `w = mu + scale * sigma * z`. At 1.0
  (default) = full coupling (legacy). At 0 = deterministic actions from
  mu; sigma only affects the learning/cost channel. Added 0.5.5 for
  sigma-action decoupling in Baldwin/plasticity scenarios.

### Genome and ploidy

clade supports diploid (default) and haploid life cycles. The diploid
path implements full Mendelian genetics with independent assortment and
recombination.

- `ploidy`:

  Integer. `1L` = haploid; `2L` = diploid (default). In the diploid case
  every heritable trait (brain weights, body size, immune strength,
  cooperation level, etc.) has two alleles – one maternal, one paternal.
  The expressed phenotype is computed by `dominance_model` at birth and
  does not change within a lifetime.

- `n_chromosomes`:

  Integer. Number of chromosome pairs (default 1L). When `> 1`,
  chromosomes assort independently at meiosis (each pair segregates with
  probability 0.5). The brain genome is split evenly across chromosome
  pairs.

- `crossover_rate`:

  Numeric. Expected number of crossover events per chromosome pair per
  meiosis (Poisson distributed; default 1.0). Set to 0 to disable
  recombination.

- `dominance_model`:

  Character. How maternal and paternal alleles combine: `"additive"`
  (default; mean of two alleles), `"dominant"` (random allele at each
  locus), or `"codominant"` (both expressed; reported separately in
  [`get_genome_data()`](get_genome_data.md)). Reference: Charlesworth &
  Charlesworth (2010) *Elements of Evolutionary Genetics*, Chapter 5.

### Mutation

- `mutation_sd`:

  Numeric. Standard deviation of Gaussian noise added to each brain
  weight at reproduction (default 0.1).

- `mutation_rate_evolution`:

  Logical. If `TRUE`, `mutation_sd` is itself a heritable diploid trait
  that evolves (default `FALSE`). Reference: Sniegowski, Gerrish &
  Lenski (1997) Evolution of high mutation rates in experimental
  populations of *E. coli*, *Nature* 387:703–705.

- `mutation_sd_init_mean`:

  Numeric. Initial mean of the `mutation_sd` distribution when
  `mutation_rate_evolution = TRUE` (default 0.1).

- `mutation_sd_min`:

  Numeric. Minimum allowed `mutation_sd` (default 0.001).

- `mutation_sd_max`:

  Numeric. Maximum allowed `mutation_sd` (default 1.0).

### Learning and plasticity

Within-lifetime learning modifies the brain without altering the genome.
When `learning_rate_evolution = TRUE`, the learning rate is itself a
heritable diploid trait; variation in `learning_rate` across the
population then allows the Baldwin Effect (Baldwin 1896) to be observed:
genomes that encode pre-adapted solutions outcompete those relying on
learning.

- `rl_mode`:

  Character. Reinforcement learning update rule: `"none"` (default),
  `"actor_critic"` (REINFORCE with baseline, Williams 1992; reward =
  energy delta, applied to output weights), or `"hebbian"` (Hebbian
  potentiation, Hebb 1949; co-active neurons are strengthened). Use
  `bnn_sample_freq = 5` with BNN brains so REINFORCE gradients
  accumulate across ticks.

- `learning_rate`:

  Numeric. Step size for within-lifetime weight updates (default 0.01).

- `learning_rate_evolution`:

  Logical. If `TRUE`, `learning_rate` is a heritable diploid trait
  (default `FALSE`). Enables study of the Baldwin Effect (Baldwin 1896,
  Hinton & Nowlan 1987). References: Baldwin (1896) *American
  Naturalist* 30:441–451; Hinton & Nowlan (1987) *Complex Systems*
  1(3):495–502.

- `learning_rate_init_mean`:

  Numeric. Initial mean of the `learning_rate` distribution when
  `learning_rate_evolution = TRUE` (default 0.01).

- `learning_rate_min`:

  Numeric. Minimum allowed `learning_rate` (default 0.0).

- `learning_rate_max`:

  Numeric. Maximum allowed `learning_rate` (default 0.5).

- `plasticity_cost`:

  Numeric. Energy cost per unit of absolute weight change per tick
  (default 0.05). Implements the metabolic cost of synaptic plasticity.
  Reference: Laughlin, de Ruyter van Steveninck & Anderson (1998) The
  metabolic cost of neural information, *Nature Neuroscience*
  1(1):36–41.

- `rl_update_freq`:

  Integer. Apply RL update every this many ticks (default 1L).

- `lamarckian`:

  Logical. If `TRUE` and `rl_mode` is not `"none"`, the within-lifetime
  RL-updated brain weights are written back to the parent's genome
  before meiosis. Offspring therefore directly inherit the learned
  solution rather than rediscovering it from the unmodified starting
  genome (Darwinian path). This is **distinct** from `epigenetics`:
  epigenetics inherits methylation marks that record *which* loci should
  be canalized; Lamarckian inheritance copies the actual learned *weight
  values* into the heritable material. Both can be active simultaneously
  (default `FALSE`). Reference: Baldwin (1896) *American Naturalist*
  30:441–451; Weismann (1892) *Das Keimplasma*; Jablonka & Lamb (2005)
  *Evolution in Four Dimensions*, MIT Press.

### Epigenetics and transgenerational inheritance

When `epigenetics = TRUE`, each agent carries a methylome: a Boolean
vector of the same length as the genome. Each element records whether
the corresponding locus is methylated. Within lifetime, learning events
can methylate loci (epigenetic_learning_coupling). At reproduction, a
fraction of the parent's methylation pattern is inherited by offspring
(epigenetic_inheritance). For BNN brains, methylation at locus i shrinks
the prior sigma_i (canalization – the agent becomes less plastic at that
weight). This implements transgenerational epigenetic inheritance (TEI)
as described by Jablonka & Lamb (2005).

- `epigenetics`:

  Logical. Enable epigenetic methylation and TEI (default `FALSE`).
  Reference: Jablonka & Lamb (2005) *Evolution in Four Dimensions*, MIT
  Press.

- `epigenetic_learning_coupling`:

  Numeric in \[0, 1\]. Probability that a within-lifetime learning event
  methylates the corresponding locus (default 0.10).

- `epigenetic_inheritance`:

  Numeric in \[0, 1\]. Fraction of the parent's methylation marks
  inherited by each offspring (default 0.50). The remaining marks are
  reset (demethylated) in the offspring.

- `epigenetic_effect_size`:

  Numeric. Factor by which methylation reduces prior sigma (for BNN) or
  mutational variance at the locus (for other brain types) (default
  0.20).

- `methylation_rate`:

  Numeric. Spontaneous methylation probability per locus per tick
  (default 0.001).

- `demethylation_rate`:

  Numeric. Spontaneous demethylation probability per methylated locus
  per tick (default 0.002).

### Predators

- `n_predators_init`:

  Integer. Number of predators at tick 0 (default 0L). Predators have
  evolving brains (`"ann"` by default) and co-evolve with prey.

- `predator_energy_init`:

  Numeric. Starting energy for predators (default 150).

- `predator_attack_cost`:

  Numeric. Energy deducted from predator per attack attempt (default 2).

- `predator_kill_gain`:

  Numeric. Energy predator gains per successful kill (default 50).

- `predator_mutation_sd`:

  Numeric. Mutation SD for predator brain weights (default 0.1).

- `max_predators`:

  Integer. Hard cap on predator population (default 20L).

- `predator_sense_graded`:

  Logical. If `TRUE` (default, 0.4.2), prey's predator sensory input at
  distance `d` is `1/(d+1)` (closer predators produce a stronger
  signal). If `FALSE`, falls back to the pre-0.4.2 binary presence
  signal. No effect when `n_predators_init = 0`.

### Life history

- `life_history`:

  Character. `"iteroparous"` (default) or `"semelparous"`. Semelparous
  agents die immediately after reproducing. Reference: Stearns (1992)
  *The Evolution of Life Histories*, Oxford UP.

- `max_age`:

  Integer. Maximum lifespan in ticks; agents die at this age regardless
  of energy (default 200L). The hard cap applies only when
  `senescence_rate == 0`; when Gompertz senescence is active, late-life
  mortality is governed by the stochastic curve instead (0.4.2
  behaviour). Set to `Inf` to disable.

- `senescence_rate`:

  Numeric in \[0, 1\]. Gompertz mortality rate; per-tick death
  probability scales as exp(senescence_rate \* age) (default 0 = no
  senescence). When \> 0, supersedes the `max_age` hard cap (0.4.2).
  Reference: Gompertz (1825) On the nature of the function expressive of
  the law of human mortality, *Philosophical Transactions of the Royal
  Society* 115:513–583.

- `repro_senescence`:

  Numeric in \[0, 1\]. Per-tick decline in reproduction probability with
  age (default 0 = no reproductive senescence).

- `life_history_evolution`:

  Logical. If `TRUE`, `max_age` and `senescence_rate` are heritable
  diploid traits (default `FALSE`).

- `allee_threshold`:

  Integer. Minimum local density for reproduction (default 0L = Allee
  effects off). When \> 0, agents require at least this many
  conspecifics in their Moore neighbourhood to reproduce. Reference:
  Allee (1931) *Animal Aggregations*, University of Chicago Press.

### Body size evolution

- `body_size_evolution`:

  Logical. Enable heritable body size trait (default `FALSE`). Body size
  scales metabolic costs (larger = more expensive), foraging capacity
  (larger = more grass per tick), and energy storage (larger = higher
  cap). Reference size is 1.0 (no effect). Reference: Kleiber, M. (1947)
  Body size and metabolic rate, *Physiological Reviews* 27(4):511–541.

- `body_size_init_mean`:

  Numeric. Initial mean body size (default 1.0).

- `body_size_mutation_sd`:

  Numeric. Mutation SD for body size (default 0.08).

- `body_size_min`:

  Numeric. Minimum body size (default 0.3).

- `body_size_max`:

  Numeric. Maximum body size (default 3.0).

### Brain size evolution

- `brain_size_evolution`:

  Logical. Enable heritable brain size trait (default `FALSE`).
  Implements the parental provisioning hypothesis: brain size is
  metabolically costly (expensive brain hypothesis) yet confers a
  cognitive foraging advantage. The bootstrapping problem —
  large-brained offspring pay the metabolic cost from birth before their
  cognitive advantage can offset it — means brain size can only evolve
  when parental provisioning (`parental_care = TRUE`) buffers the
  infancy energy deficit. References: van Schaik et al. (2023) *PLoS
  Biology* 21(5):e3002064; Griesser et al. (2023) *PNAS*
  120(31):e2301005120; Song et al. (2025) *PNAS* 122(8):e2412783122.

- `brain_size_init_mean`:

  Numeric. Initial mean brain size (default 1.0, reference = no effect).

- `brain_size_mutation_sd`:

  Numeric. Mutation SD for brain size (default 0.05).

- `brain_size_min`:

  Numeric. Minimum brain size (default 0.1).

- `brain_size_max`:

  Numeric. Maximum brain size (default 3.0).

- `brain_size_cost_scale`:

  Numeric. Multiplier on the metabolic surcharge per unit of
  `brain_size - 1.0`. Higher values steepen the cost curve and make the
  bootstrapping problem harder (default 1.0).

- `brain_size_sensing_exponent`:

  Numeric. Power applied to `brain_size` when scaling grass sensing
  inputs. `brain_size^exponent` determines the sensing multiplier.
  Exponent 0 = no sensing effect; exponent 1.0 = linear scaling; default
  0.3 gives a gentle sublinear boost (e.g. `brain_size = 2.0` → 1.23×
  multiplier). No effect when `brain_size_evolution = FALSE`.

### Metabolic rate evolution

- `metabolic_rate_evolution`:

  Logical. Enable heritable metabolic rate (default `FALSE`). Scales
  `move_cost` and `idle_cost`.

- `metabolic_rate_init_mean`:

  Numeric. Initial mean metabolic rate (default 1.0).

- `metabolic_rate_mutation_sd`:

  Numeric. Mutation SD (default 0.05).

- `metabolic_rate_min`:

  Numeric. Minimum (default 0.1).

- `metabolic_rate_max`:

  Numeric. Maximum (default 5.0).

### Aging rate evolution

- `aging_rate_evolution`:

  Logical. Enable heritable aging rate (default `FALSE`). Scales the
  Gompertz senescence exponent.

- `aging_rate_init_mean`:

  Numeric. Initial mean aging rate (default 1.0).

- `aging_rate_mutation_sd`:

  Numeric. Mutation SD (default 0.05).

- `aging_rate_min`:

  Numeric. Minimum (default 0.01).

- `aging_rate_max`:

  Numeric. Maximum (default 10.0).

### Immune system evolution

- `immune_evolution`:

  Logical. Enable heritable immune strength trait (default `FALSE`).

- `immune_strength_init_mean`:

  Numeric. Initial mean (default 0.3).

- `immune_strength_mutation_sd`:

  Numeric. Mutation SD (default 0.05).

- `immune_strength_min`:

  Numeric. Minimum (default 0.0).

- `immune_strength_max`:

  Numeric. Maximum (default 1.0).

### Disease (SIR model)

- `disease`:

  Logical. Enable SIR disease dynamics (default `FALSE`). Reference:
  Kermack & McKendrick (1927) Contributions to the mathematical theory
  of epidemics, *Proceedings of the Royal Society A* 115(772):700–721.

- `disease_seed_prob`:

  Numeric in \[0, 1\]. Probability each agent is initially infected at
  tick 1 (default 0.01).

- `transmission_prob`:

  Numeric in \[0, 1\]. Probability of transmission to a susceptible
  neighbour per infected-susceptible adjacent pair per tick (default
  0.1). Effective transmission = transmission_prob \* (1 - receiver's
  immune_strength).

- `disease_duration`:

  Integer. Ticks an agent remains infectious (default 10L).

- `immune_duration`:

  Integer. Ticks of immunity after recovery (default 20L). After this,
  agent returns to Susceptible.

- `disease_energy_cost`:

  Numeric. Energy deducted per tick while infected (default 5).

- `disease_death_prob`:

  Numeric in \[0, 1\]. Per-tick probability of death while infected
  (default 0.02). Scaled by (1 - immune_strength) if
  `immune_evolution = TRUE`.

### Kin selection

- `kin_selection`:

  Logical. Enable kin altruism (default `FALSE`). Reference:
  Hamilton (1964) The genetical evolution of social behaviour I & II,
  *Journal of Theoretical Biology* 7:1–52.

- `kin_altruism_cost`:

  Numeric. Energy transferred from donor (default 2.0). Hamilton's rule
  requires benefit \* r \> cost.

- `kin_altruism_benefit`:

  Numeric. Energy received by recipient (default 10.0).

- `kin_altruism_r_min`:

  Numeric. Minimum pedigree relatedness r required to trigger altruism
  (default 0.25 = half-siblings).

- `kin_altruism_min_donor_energy`:

  Numeric. Donor must have at least this energy to donate (default 50).

### Cooperation (public goods game)

- `cooperation_evolution`:

  Logical. Enable heritable cooperation level (default `FALSE`). Uses a
  spatial public goods game (Nowak & May 1992). Reference: Nowak &
  May (1992) Evolutionary games and spatial chaos, *Nature* 359:826–829.

- `cooperation_multiplier`:

  Numeric. Payoff multiplier M in the public goods game (default 2.0).
  Each cooperator pays cost C; the group receives M \*
  sum(contributions) / n_local. For cooperation to be selectively
  favoured, M must exceed group size.

- `cooperation_init_mean`:

  Numeric. Initial mean cooperation level (default 0.5).

- `cooperation_mutation_sd`:

  Numeric. Mutation SD (default 0.05).

- `cooperation_cost`:

  Numeric. Per-tick energy cost paid by cooperator (default 1.0).

### Dispersal evolution

- `dispersal_evolution`:

  Logical. Enable heritable natal dispersal (default `FALSE`). Each
  agent carries a `dispersal_tendency` trait (per-tick probability of
  moving away from birthplace). Reduces inbreeding and kin competition.
  Reference: Ronce, O. (2007) How does it feel to be like a rolling
  stone? *Annual Review of Ecology, Evolution, and Systematics*
  38:231–253.

- `dispersal_cost`:

  Numeric. Energy cost per dispersal step (default 2.0). Agents with
  energy \<= 2 x dispersal_cost do not disperse.

- `dispersal_init_mean`:

  Numeric. Initial mean dispersal tendency (default 0.1).

- `dispersal_mutation_sd`:

  Numeric. Mutation SD for dispersal tendency (default 0.02).

- `dispersal_min`:

  Numeric. Minimum dispersal tendency (default 0.0).

- `dispersal_max`:

  Numeric. Maximum dispersal tendency (default 0.5).

### Parental care

- `parental_care`:

  Logical. Enable altricial parental care (default `FALSE`). Offspring
  remain with parent until graduation.

- `care_duration`:

  Integer. Ticks offspring remain in parental care (default 5L).

- `care_cost_per_offspring`:

  Numeric. Energy cost per carried offspring per tick (default 2.0).

- `max_clutch_size`:

  Integer. Maximum offspring per reproductive event (default 1L).

- `neonatal_foraging_deficit`:

  Numeric in \[0, 1\]. Reduction in foraging efficiency (effective
  `max_bite`) for newborns during their first
  `neonatal_deficit_duration` ticks of life (default 0.0). Creates the
  selection gradient for parental provisioning — unprovisioned newborns
  can't forage effectively, provisioned ones are fed by the parent via
  `feeding_rate`. Reference: Aiello & Wheeler (1995); Isler & van
  Schaik (2009) expensive brain hypothesis.

- `neonatal_deficit_duration`:

  Integer. How many ticks the neonatal foraging deficit applies for
  (default 10L).

### Signal evolution and mate choice

- `signal_dims`:

  Integer. Number of signal dimensions (default 0L = off). When \> 0,
  each agent evolves a heritable signal vector and a preference vector;
  mates are chosen by proximity of signal to preference.

- `signal_cost`:

  Numeric. Energy cost per unit of signal magnitude per tick (default
  0.1). Models honest signalling costs (Zahavi 1975). Reference:
  Zahavi (1975) Mate selection – a selection for a handicap, *Journal of
  Theoretical Biology* 53(1):205–214.

- `signal_toxicity_coupling`:

  Numeric in \[0, 1\]. Strength of aposematic pleiotropy between the
  first signal dimension and the heritable `toxicity` trait. At 0
  (default) signal and toxicity evolve independently; at 1, `signal[1]`
  is locked to each agent's toxicity value so predators can learn a
  reliable honest aposematic signal. Required to close the Bates (1862)
  / Müller (1879) feedback loop in clade. Active only when
  `mimicry = TRUE` and `signal_dims > 0`. Added 0.4.4.

### Coevolving parasites (Hamilton 1980 Red Queen, 0.5.0 / 0.5.1)

- `coevolving_parasites`:

  Logical. Enable genotype-matched virulence module (default `FALSE`).
  Reference: Hamilton, W.D. (1980) Sex versus non-sex versus parasite.
  *Oikos* 35:282–290.

- `parasite_match_mode`:

  Character. One of `"auto"` (default), `"continuous"`, or `"discrete"`.
  Continuous mode (0.5.0) uses Euclidean distance on the `signal` vector
  and tracks the host population centroid with lag — a mean-tracking
  variant that does NOT reproduce the canonical Red Queen. Discrete mode
  (0.5.1) uses Hamming distance on a binary-allele `parasite_haplotype`
  trait with Mendelian inheritance — this is the canonical Hamilton
  mechanism. `"auto"` picks discrete when `n_parasite_loci > 0`, else
  continuous.

- `parasite_virulence_rate`:

  Numeric in \[0, 1\]. Rate at which the collective parasite genotype
  tracks the host majority each tick (default 0.1 ≈ 10-tick lag).

- `parasite_pressure`:

  Numeric. Maximum per-tick energy drain from parasite infection,
  applied to hosts exactly matching the parasite haplotype (default
  0.5).

- `parasite_distance_scale`:

  Numeric. Continuous-mode Gaussian falloff scale (default 1.0; ignored
  in discrete mode).

- `n_parasite_loci`:

  Integer. Number of binary loci in the heritable `parasite_haplotype`
  trait (default 0 = continuous mode only). When \> 0, each agent
  carries a `Vector{Int32}` of this length, inherited Mendelian-style
  for diploid, clonal + per-locus mutation for haploid. 0.5.1.

- `parasite_mutation_rate`:

  Numeric in \[0, 1\]. Per-locus mutation rate (allele flip) during
  inheritance (default 0.01).

- `parasite_discrete_exponent`:

  Numeric. Exponent controlling Hamming-distance falloff:
  `penalty = pressure * ((n_loci - hamming) / n_loci)^exp` (default
  4.0). Higher exponents concentrate pressure on near-matching hosts and
  let mismatched hosts escape cleanly.

### Mimicry and toxicity

- `mimicry`:

  Logical. Enable heritable toxicity trait and predator signal learning
  (default `FALSE`). Implements Mullerian and Batesian mimicry via
  Rescorla-Wagner learning in predators. Reference: Rescorla &
  Wagner (1972) A theory of Pavlovian conditioning, in *Classical
  Conditioning II*, Appleton-Century-Crofts, pp 64–99.

### Niche construction

- `niche_construction`:

  Logical. Enable shelter building (default `FALSE`). Shelters reduce
  predation and slow grass regrowth. Reference: Odling-Smee, Laland &
  Feldman (2003) *Niche Construction: The Neglected Process in
  Evolution*, Princeton UP.

- `shelter_build_prob`:

  Numeric in \[0, 1\]. Probability of building a shelter unit per tick
  when eligible (default 0.1).

- `shelter_max_depth`:

  Integer. Maximum shelter depth per cell (default 5L).

- `shelter_min_energy`:

  Numeric. Minimum energy required to build (default 80).

- `shelter_decay_prob`:

  Numeric in \[0, 1\]. Per-tick probability that each shelter unit
  decays (default 0.05).

### Scavenging

- `scavenging`:

  Logical. Enable carrion dynamics (default `FALSE`). Dead agents
  deposit body mass as carrion; scavengers consume it.

- `carrion_fraction`:

  Numeric in \[0, 1\]. Fraction of energy_init deposited as carrion upon
  agent death (default 0.5). Uses energy_init not agent\$energy at
  death, because body mass does not change with starvation.

- `carrion_decay_rate`:

  Numeric in \[0, 1\]. Per-tick fraction of carrion that decomposes
  (default 0.1).

- `carrion_eat_gain`:

  Numeric. Energy gained per unit of carrion consumed (default 3).

### Group defense (dilution effect)

- `group_defense`:

  Logical. Enable dilution-effect predator avoidance (default `FALSE`).
  Per-agent predation probability decreases with local group size.
  Reference: Foster & Treherne (1981) Evidence for the dilution effect
  in the selfish herd from fish predation on a marine insect, *Nature*
  293:466–467.

### Habitat preference (ideal free distribution)

- `habitat_preference_evolution`:

  Logical. Enable heritable habitat preference (default `FALSE`).
  Preference encodes optimal local grass density; agents are attracted
  to cells matching their preference. Reference: Fretwell & Lucas (1970)
  On territorial behavior and other factors influencing habitat
  distribution in birds, *Acta Biotheoretica* 19(1):16–36.

### Seasonal dynamics

- `seasonal_amplitude`:

  Numeric. Amplitude of sinusoidal grass_rate modulation (default 0 =
  off). grass_rate_t = grass_rate \* (1 + seasonal_amplitude \* sin(2 \*
  pi \* t / seasonal_period)).

- `seasonal_period`:

  Integer. Period of seasonal cycle in ticks (default 100L).

### Speciation (genome clustering)

- `speciation`:

  Logical. Enable reproductive isolation based on genome distance
  (default `FALSE`). Agents only mate with conspecifics (genome distance
  \< isolation_threshold). Reference: Gavrilets (2004) *Fitness
  Landscapes and the Origin of Species*, Princeton UP.

- `isolation_threshold`:

  Numeric. Maximum genome distance for successful mating (default 0.45).
  Species are inferred by hierarchical clustering of genome distances at
  each logging tick.

### Social learning

- `social_learning`:

  Logical. Enable copying of output-layer weights from successful
  neighbours (default `FALSE`). Implements prestige bias. Reference:
  Laland (2004) Social learning strategies, *Learning and Behavior*
  32(1):4–14.

- `social_learning_freq`:

  Integer. Apply social learning every this many ticks (default 10L).

- `social_learning_rate`:

  Numeric. Fraction of neighbour weights copied (default 0.1).

### World evolution (parameter co-evolution)

When `world_evolution = TRUE`, the environment parameters listed in
`world_params_to_evolve` are treated as evolvable quantities that change
via random drift each tick, allowing the environment to co-evolve with
agents. This extends the MAP-Elites search into a joint
agent-environment space.

- `world_evolution`:

  Logical. Enable world parameter evolution (default `FALSE`).

- `world_mutation_sd`:

  Numeric. Standard deviation of Gaussian perturbations to world
  parameters per tick (default 0.02).

- `world_params_to_evolve`:

  Character vector. Names of parameters in `default_specs()` to treat as
  evolvable. Example: `c("grass_rate", "disease_death_prob")`. Defaults
  to `character(0)` (none).

### Complex multi-resource landscape (Tier 1)

Adds shrub and canopy resource layers on top of ground grass. Canopy
access requires `wing_size >= canopy_threshold` (heritable). Designed to
break the standard brain-size x longevity correlation. Reference:
Liedtke & Fromhage (2019); Isbell (2006).

- `complex_landscape`:

  Logical. Enable multi-layer resources (default `FALSE`).

- `shrub_density`:

  Numeric in \[0, 1\]. Initial fraction of cells with shrub resource
  (default 0.3).

- `shrub_growth_rate`:

  Numeric. Per-tick fractional regrowth of shrubs (default 0.03).

- `shrub_energy`:

  Numeric. Maximum energy a shrub cell provides (default 20.0).

- `canopy_density`:

  Numeric in \[0, 1\]. Initial canopy coverage (default 0.15; trees are
  sparse).

- `canopy_growth_rate`:

  Numeric. Per-tick fractional regrowth of canopy (default 0.005; trees
  grow slowly).

- `canopy_energy`:

  Numeric. Maximum energy a canopy cell provides (default 50.0; high
  energy density for aerial specialists).

- `canopy_threshold`:

  Numeric. Minimum `wing_size` needed for canopy access (default 0.6).

- `wing_size_init_mean`:

  Numeric. Initial mean `wing_size` (default 0.0; ground-bound
  founders).

- `wing_size_mutation_sd`:

  Numeric. Mutation SD for `wing_size` (default 0.05).

- `wing_size_min`:

  Numeric. Minimum wing size (default 0.0).

- `wing_size_max`:

  Numeric. Maximum wing size (default 1.0).

### Spatial sorting (Tier 2a)

Implements assortative mating at the invasion range front, causing
dispersal-enhancing alleles to accumulate at the frontier without
requiring any fitness advantage over sedentary conspecifics. Reference:
Shine et al. (2011) An evolutionary process that assembles phenotypes
through space rather than through time. *PNAS* 108:5708–5711. Requires
`dispersal_evolution = TRUE` to have effect.

- `spatial_sorting`:

  Logical. Enable range-front mate preference for high-dispersal
  partners (default `FALSE`).

- `sorting_front_threshold`:

  Numeric in \[0, 1\]. Fraction of maximum range radius that defines
  "the front" (default 0.75; outermost 25%).

- `sorting_mating_boost`:

  Numeric. Multiplier applied to `dispersal_tendency` when scoring mates
  at the front (default 3.0).

### IFfolk inclusive fitness (Tier 2b)

IFfolk = own offspring + sum(r x relative's offspring). Agents transfer
energy to energy-depleted kin. Optional parliament suppression penalises
defectors in cooperative populations. Reference: Fromhage & Jennions
(2019) The strategic reference gene. *Proc R Soc B* 286:20190459.
doi:10.1098/rspb.2019.0459

- `iffolk_selection`:

  Logical. Enable IFfolk energy transfers (default `FALSE`).

- `iffolk_r_min`:

  Numeric. Minimum relatedness coefficient for a relative to count
  (default 0.125 = cousin).

- `iffolk_radius`:

  Integer. Spatial search radius for relatives in grid cells (default
  5L).

- `iffolk_transfer`:

  Numeric. Maximum energy transferred per altruistic act (default 3.0).

- `iffolk_min_energy`:

  Numeric. Minimum donor energy required to transfer (default 60.0).

- `parliament_suppression`:

  Logical. Enable parliament-of-genes penalty for defectors (negative
  `helper_tendency`) when surrounded by cooperators (default `FALSE`).

- `parliament_cost`:

  Numeric. Energy cost per tick for defectors in cooperative
  neighbourhoods (default 0.5).

### Fixed patch (stable fitness peak — Baldwin Effect demonstration)

Places one or more grid cells whose grass value is reset to
`fixed_patch_value` after every `grow_grass!` call, creating a permanent
high-value resource that never depletes. This gives natural selection a
*stable fitness peak*: agents whose genome encodes a fixed policy of
navigating to the patch always outperform agents that must re-discover
it by exploration each lifetime. The result is genetic assimilation of
the patch-navigation strategy — the computational Baldwin Effect as
described by Hinton \\ Nowlan (1987).

Without this module, the foraging fitness landscape shifts continuously
(stochastic grass, population density feedbacks) and exploration remains
the evolutionarily stable strategy (`mean_prior_sigma` rises to
ceiling).

Reference: Hinton, G.E. \\ Nowlan, S.J. (1987) How learning can guide
evolution. *Complex Systems* 1(3):495–502.

- `fixed_patch`:

  Logical. Enable the stable resource patch (default `FALSE`).

- `fixed_patch_value`:

  Numeric. Grass value maintained at patch cells each tick (default
  `5.0`, equal to `grass_max`). Values above `grass_max` are permitted —
  the cap in `grow_grass!` does not apply because the patch uses direct
  assignment.

- `fixed_patch_x`:

  Integer or `NA_integer_`. Column index of the patch centre
  (1-indexed). `NA_integer_` resolves to the grid centre column
  (default).

- `fixed_patch_y`:

  Integer or `NA_integer_`. Row index of the patch centre (1-indexed).
  `NA_integer_` resolves to the grid centre row (default).

- `fixed_patch_radius`:

  Integer. Chebyshev radius of the patch: `0L` = single cell; `1L` = 3×3
  block; `2L` = 5×5 block (default `0L`).

### Logging

- `log_freq`:

  Integer. Log population-level statistics every this many ticks
  (default 1L; set higher to reduce memory use in long runs).

- `log_genomes`:

  Logical. Log flattened genome vectors to `get_genome_data()$genomes`
  at each log tick (default `FALSE`; memory intensive for large
  populations).

- `random_seed`:

  Integer or `NA_integer_`. Seed for Julia's RNG. `NA_integer_` uses a
  random seed (default).

## See also

[`run_alife()`](run_alife.md), [`get_run_data()`](get_run_data.md),
[`search_map_elites()`](search_map_elites.md)

## Examples

``` r
specs <- default_specs()
specs$brain_type   <- "bnn"
specs$ploidy       <- 2L
specs$n_agents_init <- 100L
# run_alife(specs)   # requires Julia
```
