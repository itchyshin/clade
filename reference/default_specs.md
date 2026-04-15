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

  Integer. Number of rows in the toroidal grid (default 30).

- `grid_cols`:

  Integer. Number of columns in the toroidal grid (default 30).

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

- `min_repro_energy`:

  Numeric. Minimum energy required to attempt reproduction (default
  120).

- `repro_cost`:

  Numeric. Energy deducted from parent at reproduction (default 30).

- `offspring_energy`:

  Numeric. Energy given to each new offspring (default 60).

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
  `"transformer"`, `"synthesis"`, or `"random"`.

      * `"bnn"` -- **Bayesian Neural Network** (default). Each synaptic weight
        is a probability distribution (mean mu, standard deviation sigma)
        rather than a fixed value. The genome encodes the prior (mu, sigma);
        within lifetime, experience updates the posterior via approximate
        Bayesian inference (sigma shrinks as the agent becomes more certain).
        Exploration is automatic: high sigma = uncertain = explore. Diploid
        genomes connect naturally: heterozygosity at a locus sets the prior
        width for that weight. Implemented via Turing.jl.
        References: Neal (1996) *Bayesian Learning for Neural Networks*,
        Springer; Blundell et al. (2015) Weight Uncertainty in Neural
        Networks, *ICML* pp 1613--1622.

      * `"ann"` -- **Multilayer Perceptron**. Standard feedforward network with
        fixed weights. Architecture set by `hidden_layers`. Compatible with
        the `alifeR` ANN format.
        Reference: Rumelhart, Hinton & Williams (1986) Learning
        representations by back-propagating errors, *Nature* 323:533--536.

      * `"ctrnn"` -- **Continuous-Time Recurrent Neural Network**. Each neuron
        i has an internal state y_i governed by the ODE:
        tau_i * dy_i/dt = -y_i + sum_j(w_ij * sigma(y_j + theta_j)) + I_i.
        Produces temporal dynamics, rhythmic behaviour, and autonomous
        initiation. Genome encodes tau (time constants), W (weights), and
        theta (biases).
        Reference: Beer (1995) On the dynamics of small continuous-time
        recurrent neural networks, *Adaptive Behavior* 3(4):469--509.

      * `"grn"` -- **Gene Regulatory Network**. The genome IS the brain;
        no separate neural network. Each locus represents a gene whose
        expression level is regulated by other genes. Some genes receive
        sensory input; others produce action output. Behaviour emerges from
        ~15-30 gene interaction dynamics simulated each tick. Maximally
        biologically minimal. When `ploidy = 2`, each regulatory link has
        two alleles and methylation directly suppresses gene expression.
        References: Kauffman (1993) *The Origins of Order*, Oxford UP;
        Watson & Szathmary (2016) How can evolution learn?, *Trends in
        Ecology and Evolution* 31(2):147--157.

      * `"transformer"` -- **Attention-Based Transformer**. Attends over a
        rolling window of the last `transformer_history` sensory inputs.
        Genome encodes query/key/value projection weights and feed-forward
        layers. Enables agents to integrate temporal context without explicit
        memory parameters.
        Reference: Vaswani et al. (2017) Attention is all you need,
        *NeurIPS* 30.

      * `"synthesis"` -- **Formal / Symbolic Rule Synthesis**. The agent's
        brain is an evolved symbolic program: a set of IF-THEN rules of the
        form (IF condition_1 AND condition_2 THEN action). Rules are encoded
        as a structured list. Evolution proceeds by rule mutation
        (add/remove/modify a rule) and rule-set crossover (swap rule subsets
        between parents). Behaviour is interpretable and human-readable.
        Reference: Angeline, Saunders & Pollack (1994) An evolutionary
        algorithm that constructs recurrent neural networks, *IEEE
        Transactions on Neural Networks* 5(1):54--65; see also Koza (1992)
        *Genetic Programming*, MIT Press.

      * `"random"` -- Null brain. Chooses actions uniformly at random.
        Used as a baseline to confirm that evolved behaviour outperforms
        chance.

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

### Brain energy cost

Brain energy cost models the metabolic cost of neural computation, as in
the Polyworld simulation (Yaeger 1994).

- `brain_energy_mode`:

  Character. One of `"none"`, `"size"`, `"activity"` (default), or
  `"prediction_error"`.

      * `"none"` -- no brain energy cost.
      * `"size"` -- cost proportional to number of synaptic weights.
      * `"activity"` -- cost = `brain_energy_base * n_weights +
        brain_energy_activity * mean(|activations|)`. Larger and more active
        brains are more costly.
      * `"prediction_error"` -- BNN-only; cost proportional to KL divergence
        between prior and posterior (measures how much the agent had to
        update its beliefs).

      Reference: Yaeger (1994) Computational genetics, physiology, metabolism,
      neural systems, learning, vision, and behavior or PolyWorld: Life in a
      new context, in *Artificial Life III*, Addison-Wesley, pp 263--298.

- `brain_energy_base`:

  Numeric. Fixed cost per synaptic weight per tick (default 0.001).

- `brain_energy_activity`:

  Numeric. Scaling factor on mean absolute activation when
  `brain_energy_mode = "activity"` (default 0.5).

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

  Character. How maternal and paternal alleles combine to produce the
  expressed phenotype: \* `"additive"` (default) – phenotype =
  (maternal + paternal) / 2. \* `"dominant"` – randomly choose one
  allele at each locus. \* `"codominant"` – both alleles expressed;
  implemented as additive but reported separately in
  [`get_genome_data()`](get_genome_data.md).

      Reference: Charlesworth & Charlesworth (2010) *Elements of Evolutionary
      Genetics*, Roberts & Company, Chapter 5.

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
  `"actor_critic"`, or `"hebbian"`.

      * `"actor_critic"` -- REINFORCE with baseline (Williams 1992).
        Reward = energy delta per tick. Advantage = reward - running mean
        (`value_estimate`). Applied to output weights for the chosen action.
      * `"hebbian"` -- Hebbian potentiation: weights between co-active
        neurons are strengthened proportionally to joint activation
        (Hebb 1949).

      References:
      Williams (1992) Simple statistical gradient-following algorithms for
      connectionist reinforcement learning, *Machine Learning* 8:229--256.
      Hebb (1949) *The Organisation of Behavior*, Wiley.

- `learning_rate`:

  Numeric. Step size for within-lifetime weight updates (default 0.01).

- `learning_rate_evolution`:

  Logical. If `TRUE`, `learning_rate` is a heritable diploid trait
  (default `FALSE`). Enables study of the Baldwin Effect (Baldwin 1896,
  Hinton & Nowlan 1987).

      References:
      Baldwin (1896) A new factor in evolution, *American Naturalist*
      30:441--451.
      Hinton & Nowlan (1987) How learning can guide evolution, *Complex
      Systems* 1(3):495--502.

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

### Life history

- `life_history`:

  Character. `"iteroparous"` (default) or `"semelparous"`. Semelparous
  agents die immediately after reproducing. Reference: Stearns (1992)
  *The Evolution of Life Histories*, Oxford UP.

- `max_age`:

  Integer. Maximum lifespan in ticks; agents die at this age regardless
  of energy (default 200L). Set to `Inf` to disable.

- `senescence_rate`:

  Numeric in \[0, 1\]. Gompertz mortality rate; per-tick death
  probability scales as exp(senescence_rate \* age) (default 0 = no
  senescence). Reference: Gompertz (1825) On the nature of the function
  expressive of the law of human mortality, *Philosophical Transactions
  of the Royal Society* 115:513–583.

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
