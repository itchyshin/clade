#' Default simulation parameters for clade
#'
#' Returns a named list of all simulation parameters with type-annotated
#' defaults. Every parameter is documented below. Pass a modified copy to
#' [run_alife()] or [search_map_elites()].
#'
#' @details
#' ## Grid and population
#' \describe{
#'   \item{`grid_rows`}{Integer. Number of rows in the toroidal grid (default 30).}
#'   \item{`grid_cols`}{Integer. Number of columns in the toroidal grid (default 30).}
#'   \item{`n_agents_init`}{Integer. Number of agents at tick 0 (default 50).}
#'   \item{`max_agents`}{Integer. Hard cap on live agents; new offspring are
#'     rejected if this is exceeded (default 500).}
#'   \item{`max_ticks`}{Integer. Simulation length in ticks (default 500).}
#' }
#'
#' ## Energy and metabolism
#' \describe{
#'   \item{`energy_init`}{Numeric. Energy each agent starts with (default 100).}
#'   \item{`energy_max`}{Numeric. Maximum energy an agent can hold (default 200).}
#'   \item{`move_cost`}{Numeric. Energy deducted per move action (default 1).}
#'   \item{`idle_cost`}{Numeric. Energy deducted when agent does not move
#'     (default 0.5).}
#'   \item{`eat_gain`}{Numeric. Energy gained per unit of grass consumed
#'     (default 5).}
#'   \item{`max_bite`}{Numeric. **0.4.0.** Maximum grass units extracted from
#'     a cell per tick (default 2.0). Implements *handling time*: a rich cell
#'     cannot be stripped in one step, and multiple agents can graze the same
#'     cell across ticks. Restores the alifeR / MATLAB ancestor's `maxbite`
#'     semantics. Per-tick energy income is bounded at `max_bite * eat_gain`.}
#'   \item{`min_repro_energy`}{Numeric. Minimum energy required to attempt
#'     reproduction (default 120).}
#'   \item{`repro_cost_mode`}{Character. **0.4.0.** `"proportional"` (default)
#'     deducts `repro_cost_fraction * parent_energy` per offspring;
#'     `"fixed"` deducts a constant `repro_cost`. Proportional cost
#'     implements Smith & Fretwell (1974) parental investment: parents in
#'     better condition have more to invest. Fixed mode preserved for
#'     reproducibility of pre-0.4.0 runs.}
#'   \item{`repro_cost`}{Numeric. Energy deducted from parent per offspring
#'     when `repro_cost_mode = "fixed"` (default 30, ignored when mode is
#'     `"proportional"`).}
#'   \item{`repro_cost_fraction`}{Numeric in (0, 1). **0.4.0.** Fraction of
#'     parent energy paid per offspring when
#'     `repro_cost_mode = "proportional"` (default 0.5).}
#'   \item{`offspring_energy_mode`}{Character. **0.4.0.** `"proportional"`
#'     (default) sets newborn energy to
#'     `offspring_energy_fraction * cost_paid` (Smith & Fretwell quality-
#'     quantity); `"fixed"` sets newborn energy to constant
#'     `offspring_energy` (legacy).}
#'   \item{`offspring_energy`}{Numeric. Energy given to each new offspring
#'     when `offspring_energy_mode = "fixed"` (default 60).}
#'   \item{`offspring_energy_fraction`}{Numeric in (0, 1). **0.4.0.**
#'     Fraction of `cost_paid` allocated to each offspring when
#'     `offspring_energy_mode = "proportional"` (default 0.25).}
#'   \item{`starvation_threshold`}{Numeric. Agent dies when energy falls below
#'     this value (default 0).}
#' }
#'
#' ## Grass dynamics
#' \describe{
#'   \item{`grass_init_prob`}{Numeric in \[0, 1\]. Probability each cell starts
#'     with grass (default 0.5).}
#'   \item{`grass_rate`}{Numeric in \[0, 1\]. Per-tick probability that an empty
#'     cell grows grass (default 0.05).}
#'   \item{`grass_max`}{Numeric. Maximum grass units per cell (default 5).}
#' }
#'
#' ## Brain architecture
#'
#' The brain type controls how agents map sensory inputs to action decisions.
#' All types are heritable and evolvable. See the references in each entry for
#' the primary literature.
#'
#' \describe{
#'   \item{`brain_type`}{Character. One of `"bnn"` (default), `"ann"`,
#'     `"ctrnn"`, `"grn"`, `"transformer"`, `"synthesis"`, or `"random"`.
#'     BNN = Bayesian neural network (Neal 1996; Blundell et al. 2015);
#'     ANN = multilayer perceptron (Rumelhart et al. 1986);
#'     CTRNN = continuous-time recurrent network (Beer 1995);
#'     GRN = gene regulatory network (Kauffman 1993);
#'     transformer = attention over sensory history (Vaswani et al. 2017);
#'     synthesis = evolved symbolic IF-THEN rules (Koza 1992);
#'     random = null baseline. See `vignette("custom-modules")` for
#'     architecture details.}
#'   \item{`hidden_layers`}{Integer vector. Hidden layer widths for `"ann"` and
#'     `"bnn"` (default `c(8L)`; gives one hidden layer of 8 units). Set to
#'     `c(16L, 8L)` for two hidden layers.}
#'   \item{`input_radius`}{Integer. Radius of the Moore neighbourhood used when
#'     building each agent's sensory input vector (default `1L`). Radius 1 gives
#'     the standard 8-cell neighbourhood; radius 2 extends to the 24-cell
#'     neighbourhood. Increasing this value expands the input vector and the
#'     brain's first-layer width accordingly.}
#'   \item{`n_genes`}{Integer. Number of genes for `"grn"` brain type
#'     (default 20L). Includes sensory input genes and action output genes.}
#'   \item{`transformer_history`}{Integer. Number of past sensory inputs the
#'     transformer attends over (default 8L).}
#'   \item{`transformer_heads`}{Integer. Number of attention heads (default 2L).}
#'   \item{`synthesis_max_rules`}{Integer. Maximum number of IF-THEN rules
#'     per agent (default 10L).}
#'   \item{`ann_weight_values`}{Numeric vector or `NULL`. When not `NULL`,
#'     every synaptic weight and bias is snapped to the nearest value in this
#'     set immediately after genome expression (before the first forward pass
#'     each generation). Use `c(-1, 0, 1)` for ternary weights or `c(-1, 1)`
#'     for binary weights. Applies to `"ann"` and `"bnn"` brain types.
#'     Biologically motivated by evidence that biological synapses operate in
#'     a small number of discrete strength states (Bhumbra & Bhatt 2020).
#'     Also enables symbolic formula distillation from evolved ANNs (as in
#'     the original MATLAB alife2025usra codebase). Default `NULL` = continuous
#'     weights.}
#'   \item{`ann_regularization`}{Character. Energy penalty on brain weight
#'     complexity: `"none"` (default), `"weight_magnitude"` (L1: deduct
#'     `lambda * sum(|w|)` per tick), or `"weight_count"` (L0-like: deduct
#'     `lambda * n_active_weights` per tick). References: Laughlin et al.
#'     (1998) *Nature Neuroscience* 1:36--41; Attwell & Laughlin (2001)
#'     *J. Cerebral Blood Flow and Metabolism* 21:1133--1145.}
#'   \item{`ann_regularization_lambda`}{Numeric. Scale factor for the
#'     regularisation penalty (default 0.001). Too large a value will cause
#'     all weights to collapse to zero within a few ticks.}
#' }
#'
#' ## Brain energy cost
#'
#' Brain energy cost models the metabolic cost of neural computation, as in
#' the Polyworld simulation (Yaeger 1994).
#'
#' \describe{
#'   \item{`brain_energy_mode`}{Character. One of `"none"` (no cost),
#'     `"size"` (proportional to synapse count), `"activity"` (default;
#'     base + activity-scaled cost), or `"prediction_error"` (BNN-only;
#'     KL divergence between prior and posterior). Reference: Yaeger
#'     (1994) PolyWorld, in *Artificial Life III*, pp 263--298.}
#'   \item{`brain_energy_base`}{Numeric. Fixed cost per synaptic weight per
#'     tick (default 0.001).}
#'   \item{`brain_energy_activity`}{Numeric. Scaling factor on mean absolute
#'     activation when `brain_energy_mode = "activity"` (default 0.5).}
#'   \item{`brain_energy_size_exponent`}{Numeric. Exponent applied to the
#'     brain-size term of the metabolic cost: `size_cost = base * n_weights^exp`
#'     (default 1.0 = linear, legacy). Set to 1.5 for
#'     Kleiber-style super-linear scaling (Isler & van Schaik 2009
#'     expensive-brain hypothesis) so large brains carry disproportionate
#'     metabolic weight — sharpens the parental-provisioning selection
#'     gradient at the default `brain_energy_base` without needing a
#'     scenario-specific override (0.4.3).}
#' }
#'
#' ## Genome and ploidy
#'
#' clade supports diploid (default) and haploid life cycles. The diploid path
#' implements full Mendelian genetics with independent assortment and
#' recombination.
#'
#' \describe{
#'   \item{`ploidy`}{Integer. `1L` = haploid; `2L` = diploid (default).
#'     In the diploid case every heritable trait (brain weights, body size,
#'     immune strength, cooperation level, etc.) has two alleles -- one
#'     maternal, one paternal. The expressed phenotype is computed by
#'     `dominance_model` at birth and does not change within a lifetime.}
#'   \item{`n_chromosomes`}{Integer. Number of chromosome pairs (default 1L).
#'     When `> 1`, chromosomes assort independently at meiosis (each pair
#'     segregates with probability 0.5). The brain genome is split evenly
#'     across chromosome pairs.}
#'   \item{`crossover_rate`}{Numeric. Expected number of crossover events per
#'     chromosome pair per meiosis (Poisson distributed; default 1.0). Set to
#'     0 to disable recombination.}
#'   \item{`dominance_model`}{Character. How maternal and paternal alleles
#'     combine: `"additive"` (default; mean of two alleles), `"dominant"`
#'     (random allele at each locus), or `"codominant"` (both expressed;
#'     reported separately in `get_genome_data()`). Reference:
#'     Charlesworth & Charlesworth (2010) *Elements of Evolutionary
#'     Genetics*, Chapter 5.}
#' }
#'
#' ## Mutation
#' \describe{
#'   \item{`mutation_sd`}{Numeric. Standard deviation of Gaussian noise added
#'     to each brain weight at reproduction (default 0.1).}
#'   \item{`mutation_rate_evolution`}{Logical. If `TRUE`, `mutation_sd` is
#'     itself a heritable diploid trait that evolves (default `FALSE`).
#'     Reference: Sniegowski, Gerrish & Lenski (1997) Evolution of high
#'     mutation rates in experimental populations of *E. coli*, *Nature*
#'     387:703--705.}
#'   \item{`mutation_sd_init_mean`}{Numeric. Initial mean of the `mutation_sd`
#'     distribution when `mutation_rate_evolution = TRUE` (default 0.1).}
#'   \item{`mutation_sd_min`}{Numeric. Minimum allowed `mutation_sd`
#'     (default 0.001).}
#'   \item{`mutation_sd_max`}{Numeric. Maximum allowed `mutation_sd`
#'     (default 1.0).}
#' }
#'
#' ## Learning and plasticity
#'
#' Within-lifetime learning modifies the brain without altering the genome.
#' When `learning_rate_evolution = TRUE`, the learning rate is itself a
#' heritable diploid trait; variation in `learning_rate` across the population
#' then allows the Baldwin Effect (Baldwin 1896) to be observed: genomes that
#' encode pre-adapted solutions outcompete those relying on learning.
#'
#' \describe{
#'   \item{`rl_mode`}{Character. Reinforcement learning update rule:
#'     `"none"` (default), `"actor_critic"` (REINFORCE with baseline,
#'     Williams 1992; reward = energy delta, applied to output weights),
#'     or `"hebbian"` (Hebbian potentiation, Hebb 1949; co-active neurons
#'     are strengthened). Use `bnn_sample_freq = 5` with BNN brains so
#'     REINFORCE gradients accumulate across ticks.}
#'   \item{`learning_rate`}{Numeric. Step size for within-lifetime weight
#'     updates (default 0.01).}
#'   \item{`learning_rate_evolution`}{Logical. If `TRUE`, `learning_rate` is a
#'     heritable diploid trait (default `FALSE`). Enables study of the Baldwin
#'     Effect (Baldwin 1896, Hinton & Nowlan 1987).
#'     References: Baldwin (1896) *American Naturalist* 30:441--451;
#'     Hinton & Nowlan (1987) *Complex
#'     Systems* 1(3):495--502.
#'   }
#'   \item{`learning_rate_init_mean`}{Numeric. Initial mean of the
#'     `learning_rate` distribution when `learning_rate_evolution = TRUE`
#'     (default 0.01).}
#'   \item{`learning_rate_min`}{Numeric. Minimum allowed `learning_rate`
#'     (default 0.0).}
#'   \item{`learning_rate_max`}{Numeric. Maximum allowed `learning_rate`
#'     (default 0.5).}
#'   \item{`plasticity_cost`}{Numeric. Energy cost per unit of absolute weight
#'     change per tick (default 0.05). Implements the metabolic cost of
#'     synaptic plasticity.
#'     Reference: Laughlin, de Ruyter van Steveninck & Anderson (1998)
#'     The metabolic cost of neural information, *Nature Neuroscience*
#'     1(1):36--41.}
#'   \item{`rl_update_freq`}{Integer. Apply RL update every this many ticks
#'     (default 1L).}
#'   \item{`lamarckian`}{Logical. If `TRUE` and `rl_mode` is not `"none"`,
#'     the within-lifetime RL-updated brain weights are written back to the
#'     parent's genome before meiosis. Offspring therefore directly inherit the
#'     learned solution rather than rediscovering it from the unmodified
#'     starting genome (Darwinian path). This is **distinct** from
#'     `epigenetics`: epigenetics inherits methylation marks that record
#'     *which* loci should be canalized; Lamarckian inheritance copies the
#'     actual learned *weight values* into the heritable material.
#'     Both can be active simultaneously (default `FALSE`).
#'     Reference: Baldwin (1896) *American Naturalist* 30:441--451;
#'     Weismann (1892) *Das Keimplasma*; Jablonka & Lamb (2005) *Evolution
#'     in Four Dimensions*, MIT Press.}
#' }
#'
#' ## Epigenetics and transgenerational inheritance
#'
#' When `epigenetics = TRUE`, each agent carries a methylome: a Boolean vector
#' of the same length as the genome. Each element records whether the
#' corresponding locus is methylated. Within lifetime, learning events can
#' methylate loci (epigenetic_learning_coupling). At reproduction, a fraction
#' of the parent's methylation pattern is inherited by offspring
#' (epigenetic_inheritance). For BNN brains, methylation at locus i shrinks
#' the prior sigma_i (canalization -- the agent becomes less plastic at that
#' weight). This implements transgenerational epigenetic inheritance (TEI) as
#' described by Jablonka & Lamb (2005).
#'
#' \describe{
#'   \item{`epigenetics`}{Logical. Enable epigenetic methylation and TEI
#'     (default `FALSE`).
#'     Reference: Jablonka & Lamb (2005) *Evolution in Four Dimensions*,
#'     MIT Press.}
#'   \item{`epigenetic_learning_coupling`}{Numeric in \[0, 1\]. Probability that
#'     a within-lifetime learning event methylates the corresponding locus
#'     (default 0.10).}
#'   \item{`epigenetic_inheritance`}{Numeric in \[0, 1\]. Fraction of the
#'     parent's methylation marks inherited by each offspring (default 0.50).
#'     The remaining marks are reset (demethylated) in the offspring.}
#'   \item{`epigenetic_effect_size`}{Numeric. Factor by which methylation
#'     reduces prior sigma (for BNN) or mutational variance at the locus
#'     (for other brain types) (default 0.20).}
#'   \item{`methylation_rate`}{Numeric. Spontaneous methylation probability
#'     per locus per tick (default 0.001).}
#'   \item{`demethylation_rate`}{Numeric. Spontaneous demethylation probability
#'     per methylated locus per tick (default 0.002).}
#' }
#'
#' ## Predators
#' \describe{
#'   \item{`n_predators_init`}{Integer. Number of predators at tick 0
#'     (default 0L). Predators have evolving brains (`"ann"` by default) and
#'     co-evolve with prey.}
#'   \item{`predator_energy_init`}{Numeric. Starting energy for predators
#'     (default 150).}
#'   \item{`predator_attack_cost`}{Numeric. Energy deducted from predator per
#'     attack attempt (default 2).}
#'   \item{`predator_kill_gain`}{Numeric. Energy predator gains per successful
#'     kill (default 50).}
#'   \item{`predator_mutation_sd`}{Numeric. Mutation SD for predator brain
#'     weights (default 0.1).}
#'   \item{`max_predators`}{Integer. Hard cap on predator population
#'     (default 20L).}
#'   \item{`predator_sense_graded`}{Logical. If `TRUE` (default, 0.4.2),
#'     prey's predator sensory input at distance `d` is `1/(d+1)` (closer
#'     predators produce a stronger signal). If `FALSE`, falls back to
#'     the pre-0.4.2 binary presence signal. No effect when
#'     `n_predators_init = 0`.}
#' }
#'
#' ## Life history
#' \describe{
#'   \item{`life_history`}{Character. `"iteroparous"` (default) or
#'     `"semelparous"`. Semelparous agents die immediately after reproducing.
#'     Reference: Stearns (1992) *The Evolution of Life Histories*, Oxford UP.}
#'   \item{`max_age`}{Integer. Maximum lifespan in ticks; agents die at this
#'     age regardless of energy (default 200L). The hard cap applies only
#'     when `senescence_rate == 0`; when Gompertz senescence is active,
#'     late-life mortality is governed by the stochastic curve instead
#'     (0.4.2 behaviour). Set to `Inf` to disable.}
#'   \item{`senescence_rate`}{Numeric in \[0, 1\]. Gompertz mortality rate;
#'     per-tick death probability scales as exp(senescence_rate * age)
#'     (default 0 = no senescence). When > 0, supersedes the `max_age`
#'     hard cap (0.4.2).
#'     Reference: Gompertz (1825) On the nature of the function expressive of
#'     the law of human mortality, *Philosophical Transactions of the Royal
#'     Society* 115:513--583.}
#'   \item{`repro_senescence`}{Numeric in \[0, 1\]. Per-tick decline in
#'     reproduction probability with age (default 0 = no reproductive
#'     senescence).}
#'   \item{`life_history_evolution`}{Logical. If `TRUE`, `max_age` and
#'     `senescence_rate` are heritable diploid traits (default `FALSE`).}
#'   \item{`allee_threshold`}{Integer. Minimum local density for reproduction
#'     (default 0L = Allee effects off). When > 0, agents require at least
#'     this many conspecifics in their Moore neighbourhood to reproduce.
#'     Reference: Allee (1931) *Animal Aggregations*, University of Chicago
#'     Press.}
#' }
#'
#' ## Body size evolution
#' \describe{
#'   \item{`body_size_evolution`}{Logical. Enable heritable body size trait
#'     (default `FALSE`). Body size scales metabolic costs (larger = more
#'     expensive), foraging capacity (larger = more grass per tick), and energy
#'     storage (larger = higher cap). Reference size is 1.0 (no effect).
#'     Reference: Kleiber, M. (1947) Body size and metabolic rate,
#'     *Physiological Reviews* 27(4):511--541.}
#'   \item{`body_size_init_mean`}{Numeric. Initial mean body size (default 1.0).}
#'   \item{`body_size_mutation_sd`}{Numeric. Mutation SD for body size
#'     (default 0.08).}
#'   \item{`body_size_min`}{Numeric. Minimum body size (default 0.3).}
#'   \item{`body_size_max`}{Numeric. Maximum body size (default 3.0).}
#' }
#'
#' ## Brain size evolution
#' \describe{
#'   \item{`brain_size_evolution`}{Logical. Enable heritable brain size trait
#'     (default `FALSE`). Implements the parental provisioning hypothesis: brain
#'     size is metabolically costly (expensive brain hypothesis) yet confers a
#'     cognitive foraging advantage. The bootstrapping problem — large-brained
#'     offspring pay the metabolic cost from birth before their cognitive
#'     advantage can offset it — means brain size can only evolve when parental
#'     provisioning (`parental_care = TRUE`) buffers the infancy energy deficit.
#'     References: van Schaik et al. (2023) *PLoS Biology* 21(5):e3002064;
#'     Griesser et al. (2023) *PNAS* 120(31):e2301005120;
#'     Song et al. (2025) *PNAS* 122(8):e2412783122.}
#'   \item{`brain_size_init_mean`}{Numeric. Initial mean brain size (default 1.0,
#'     reference = no effect).}
#'   \item{`brain_size_mutation_sd`}{Numeric. Mutation SD for brain size
#'     (default 0.05).}
#'   \item{`brain_size_min`}{Numeric. Minimum brain size (default 0.1).}
#'   \item{`brain_size_max`}{Numeric. Maximum brain size (default 3.0).}
#'   \item{`brain_size_cost_scale`}{Numeric. Multiplier on the metabolic
#'     surcharge per unit of `brain_size - 1.0`. Higher values steepen the
#'     cost curve and make the bootstrapping problem harder (default 1.0).}
#'   \item{`brain_size_sensing_exponent`}{Numeric. Power applied to
#'     `brain_size` when scaling grass sensing inputs. `brain_size^exponent`
#'     determines the sensing multiplier. Exponent 0 = no sensing effect;
#'     exponent 1.0 = linear scaling; default 0.3 gives a gentle sublinear
#'     boost (e.g. `brain_size = 2.0` → 1.23× multiplier). No effect when
#'     `brain_size_evolution = FALSE`.}
#' }
#'
#' ## Metabolic rate evolution
#' \describe{
#'   \item{`metabolic_rate_evolution`}{Logical. Enable heritable metabolic rate
#'     (default `FALSE`). Scales `move_cost` and `idle_cost`.}
#'   \item{`metabolic_rate_init_mean`}{Numeric. Initial mean metabolic rate
#'     (default 1.0).}
#'   \item{`metabolic_rate_mutation_sd`}{Numeric. Mutation SD (default 0.05).}
#'   \item{`metabolic_rate_min`}{Numeric. Minimum (default 0.1).}
#'   \item{`metabolic_rate_max`}{Numeric. Maximum (default 5.0).}
#' }
#'
#' ## Aging rate evolution
#' \describe{
#'   \item{`aging_rate_evolution`}{Logical. Enable heritable aging rate
#'     (default `FALSE`). Scales the Gompertz senescence exponent.}
#'   \item{`aging_rate_init_mean`}{Numeric. Initial mean aging rate
#'     (default 1.0).}
#'   \item{`aging_rate_mutation_sd`}{Numeric. Mutation SD (default 0.05).}
#'   \item{`aging_rate_min`}{Numeric. Minimum (default 0.01).}
#'   \item{`aging_rate_max`}{Numeric. Maximum (default 10.0).}
#' }
#'
#' ## Immune system evolution
#' \describe{
#'   \item{`immune_evolution`}{Logical. Enable heritable immune strength trait
#'     (default `FALSE`).}
#'   \item{`immune_strength_init_mean`}{Numeric. Initial mean (default 0.3).}
#'   \item{`immune_strength_mutation_sd`}{Numeric. Mutation SD (default 0.05).}
#'   \item{`immune_strength_min`}{Numeric. Minimum (default 0.0).}
#'   \item{`immune_strength_max`}{Numeric. Maximum (default 1.0).}
#' }
#'
#' ## Disease (SIR model)
#' \describe{
#'   \item{`disease`}{Logical. Enable SIR disease dynamics (default `FALSE`).
#'     Reference: Kermack & McKendrick (1927) Contributions to the mathematical
#'     theory of epidemics, *Proceedings of the Royal Society A*
#'     115(772):700--721.}
#'   \item{`disease_seed_prob`}{Numeric in \[0, 1\]. Probability each agent is
#'     initially infected at tick 1 (default 0.01).}
#'   \item{`transmission_prob`}{Numeric in \[0, 1\]. Probability of transmission
#'     to a susceptible neighbour per infected-susceptible adjacent pair per
#'     tick (default 0.1). Effective transmission = transmission_prob *
#'     (1 - receiver's immune_strength).}
#'   \item{`disease_duration`}{Integer. Ticks an agent remains infectious
#'     (default 10L).}
#'   \item{`immune_duration`}{Integer. Ticks of immunity after recovery
#'     (default 20L). After this, agent returns to Susceptible.}
#'   \item{`disease_energy_cost`}{Numeric. Energy deducted per tick while
#'     infected (default 5).}
#'   \item{`disease_death_prob`}{Numeric in \[0, 1\]. Per-tick probability of
#'     death while infected (default 0.02). Scaled by (1 - immune_strength)
#'     if `immune_evolution = TRUE`.}
#' }
#'
#' ## Kin selection
#' \describe{
#'   \item{`kin_selection`}{Logical. Enable kin altruism (default `FALSE`).
#'     Reference: Hamilton (1964) The genetical evolution of social behaviour
#'     I & II, *Journal of Theoretical Biology* 7:1--52.}
#'   \item{`kin_altruism_cost`}{Numeric. Energy transferred from donor
#'     (default 2.0). Hamilton's rule requires benefit * r > cost.}
#'   \item{`kin_altruism_benefit`}{Numeric. Energy received by recipient
#'     (default 10.0).}
#'   \item{`kin_altruism_r_min`}{Numeric. Minimum pedigree relatedness r
#'     required to trigger altruism (default 0.25 = half-siblings).}
#'   \item{`kin_altruism_min_donor_energy`}{Numeric. Donor must have at least
#'     this energy to donate (default 50).}
#' }
#'
#' ## Cooperation (public goods game)
#' \describe{
#'   \item{`cooperation_evolution`}{Logical. Enable heritable cooperation level
#'     (default `FALSE`). Uses a spatial public goods game (Nowak & May 1992).
#'     Reference: Nowak & May (1992) Evolutionary games and spatial chaos,
#'     *Nature* 359:826--829.}
#'   \item{`cooperation_multiplier`}{Numeric. Payoff multiplier M in the public
#'     goods game (default 2.0). Each cooperator pays cost C; the group
#'     receives M * sum(contributions) / n_local. For cooperation to be
#'     selectively favoured, M must exceed group size.}
#'   \item{`cooperation_init_mean`}{Numeric. Initial mean cooperation level
#'     (default 0.5).}
#'   \item{`cooperation_mutation_sd`}{Numeric. Mutation SD (default 0.05).}
#'   \item{`cooperation_cost`}{Numeric. Per-tick energy cost paid by cooperator
#'     (default 1.0).}
#' }
#'
#' ## Dispersal evolution
#' \describe{
#'   \item{`dispersal_evolution`}{Logical. Enable heritable natal dispersal
#'     (default `FALSE`). Each agent carries a `dispersal_tendency` trait
#'     (per-tick probability of moving away from birthplace). Reduces inbreeding
#'     and kin competition. Reference: Ronce, O. (2007) How does it feel to be
#'     like a rolling stone? *Annual Review of Ecology, Evolution, and
#'     Systematics* 38:231--253.}
#'   \item{`dispersal_cost`}{Numeric. Energy cost per dispersal step
#'     (default 2.0). Agents with energy <= 2 x dispersal_cost do not disperse.}
#'   \item{`dispersal_init_mean`}{Numeric. Initial mean dispersal tendency
#'     (default 0.1).}
#'   \item{`dispersal_mutation_sd`}{Numeric. Mutation SD for dispersal tendency
#'     (default 0.02).}
#'   \item{`dispersal_min`}{Numeric. Minimum dispersal tendency (default 0.0).}
#'   \item{`dispersal_max`}{Numeric. Maximum dispersal tendency (default 0.5).}
#' }
#'
#' ## Parental care
#' \describe{
#'   \item{`parental_care`}{Logical. Enable altricial parental care
#'     (default `FALSE`). Offspring remain with parent until graduation.}
#'   \item{`care_duration`}{Integer. Ticks offspring remain in parental care
#'     (default 5L).}
#'   \item{`care_cost_per_offspring`}{Numeric. Energy cost per carried
#'     offspring per tick (default 2.0).}
#'   \item{`max_clutch_size`}{Integer. Maximum offspring per reproductive
#'     event (default 1L).}
#'   \item{`neonatal_foraging_deficit`}{Numeric in \[0, 1\]. Reduction in
#'     foraging efficiency (effective `max_bite`) for newborns during
#'     their first `neonatal_deficit_duration` ticks of life (default
#'     0.0). Creates the selection gradient for parental provisioning
#'     — unprovisioned newborns can't forage effectively, provisioned
#'     ones are fed by the parent via `feeding_rate`. Reference:
#'     Aiello & Wheeler (1995); Isler & van Schaik (2009) expensive
#'     brain hypothesis.}
#'   \item{`neonatal_deficit_duration`}{Integer. How many ticks the
#'     neonatal foraging deficit applies for (default 10L).}
#' }
#'
#' ## Signal evolution and mate choice
#' \describe{
#'   \item{`signal_dims`}{Integer. Number of signal dimensions (default 0L = off).
#'     When > 0, each agent evolves a heritable signal vector and a preference
#'     vector; mates are chosen by proximity of signal to preference.}
#'   \item{`signal_cost`}{Numeric. Energy cost per unit of signal magnitude
#'     per tick (default 0.1). Models honest signalling costs (Zahavi 1975).
#'     Reference: Zahavi (1975) Mate selection -- a selection for a handicap,
#'     *Journal of Theoretical Biology* 53(1):205--214.}
#'   \item{`signal_toxicity_coupling`}{Numeric in \[0, 1\]. Strength of
#'     aposematic pleiotropy between the first signal dimension and the
#'     heritable `toxicity` trait. At 0 (default) signal and toxicity
#'     evolve independently; at 1, `signal[1]` is locked to each agent's
#'     toxicity value so predators can learn a reliable honest
#'     aposematic signal. Required to close the Bates (1862) /
#'     Müller (1879) feedback loop in clade. Active only when
#'     `mimicry = TRUE` and `signal_dims > 0`. Added 0.4.4.}
#' }
#'
#' ## Coevolving parasites (Hamilton 1980 Red Queen, 0.5.0 / 0.5.1)
#' \describe{
#'   \item{`coevolving_parasites`}{Logical. Enable genotype-matched
#'     virulence module (default `FALSE`). Reference: Hamilton, W.D.
#'     (1980) Sex versus non-sex versus parasite. *Oikos* 35:282--290.}
#'   \item{`parasite_match_mode`}{Character. One of `"auto"` (default),
#'     `"continuous"`, or `"discrete"`. Continuous mode (0.5.0) uses
#'     Euclidean distance on the `signal` vector and tracks the host
#'     population centroid with lag — a mean-tracking variant that
#'     does NOT reproduce the canonical Red Queen. Discrete mode
#'     (0.5.1) uses Hamming distance on a binary-allele
#'     `parasite_haplotype` trait with Mendelian inheritance — this
#'     is the canonical Hamilton mechanism. `"auto"` picks discrete
#'     when `n_parasite_loci > 0`, else continuous.}
#'   \item{`parasite_virulence_rate`}{Numeric in \[0, 1\]. Rate at which
#'     the collective parasite genotype tracks the host majority each
#'     tick (default 0.1 ≈ 10-tick lag).}
#'   \item{`parasite_pressure`}{Numeric. Maximum per-tick energy drain
#'     from parasite infection, applied to hosts exactly matching the
#'     parasite haplotype (default 0.5).}
#'   \item{`parasite_distance_scale`}{Numeric. Continuous-mode Gaussian
#'     falloff scale (default 1.0; ignored in discrete mode).}
#'   \item{`n_parasite_loci`}{Integer. Number of binary loci in the
#'     heritable `parasite_haplotype` trait (default 0 = continuous
#'     mode only). When > 0, each agent carries a
#'     `Vector{Int32}` of this length, inherited Mendelian-style for
#'     diploid, clonal + per-locus mutation for haploid. 0.5.1.}
#'   \item{`parasite_mutation_rate`}{Numeric in \[0, 1\]. Per-locus
#'     mutation rate (allele flip) during inheritance (default 0.01).}
#'   \item{`parasite_discrete_exponent`}{Numeric. Exponent controlling
#'     Hamming-distance falloff: `penalty = pressure * ((n_loci - hamming) / n_loci)^exp`
#'     (default 4.0). Higher exponents
#'     concentrate pressure on near-matching hosts and let mismatched
#'     hosts escape cleanly.}
#' }
#'
#' ## Mimicry and toxicity
#' \describe{
#'   \item{`mimicry`}{Logical. Enable heritable toxicity trait and predator
#'     signal learning (default `FALSE`). Implements Mullerian and Batesian
#'     mimicry via Rescorla-Wagner learning in predators.
#'     Reference: Rescorla & Wagner (1972) A theory of Pavlovian conditioning,
#'     in *Classical Conditioning II*, Appleton-Century-Crofts, pp 64--99.}
#' }
#'
#' ## Niche construction
#' \describe{
#'   \item{`niche_construction`}{Logical. Enable shelter building (default
#'     `FALSE`). Shelters reduce predation and slow grass regrowth.
#'     Reference: Odling-Smee, Laland & Feldman (2003) *Niche Construction:
#'     The Neglected Process in Evolution*, Princeton UP.}
#'   \item{`shelter_build_prob`}{Numeric in \[0, 1\]. Probability of building a
#'     shelter unit per tick when eligible (default 0.1).}
#'   \item{`shelter_max_depth`}{Integer. Maximum shelter depth per cell
#'     (default 5L).}
#'   \item{`shelter_min_energy`}{Numeric. Minimum energy required to build
#'     (default 80).}
#'   \item{`shelter_decay_prob`}{Numeric in \[0, 1\]. Per-tick probability that
#'     each shelter unit decays (default 0.05).}
#' }
#'
#' ## Scavenging
#' \describe{
#'   \item{`scavenging`}{Logical. Enable carrion dynamics (default `FALSE`).
#'     Dead agents deposit body mass as carrion; scavengers consume it.}
#'   \item{`carrion_fraction`}{Numeric in \[0, 1\]. Fraction of energy_init
#'     deposited as carrion upon agent death (default 0.5). Uses energy_init
#'     not agent$energy at death, because body mass does not change with
#'     starvation.}
#'   \item{`carrion_decay_rate`}{Numeric in \[0, 1\]. Per-tick fraction of
#'     carrion that decomposes (default 0.1).}
#'   \item{`carrion_eat_gain`}{Numeric. Energy gained per unit of carrion
#'     consumed (default 3).}
#' }
#'
#' ## Group defense (dilution effect)
#' \describe{
#'   \item{`group_defense`}{Logical. Enable dilution-effect predator avoidance
#'     (default `FALSE`). Per-agent predation probability decreases with local
#'     group size.
#'     Reference: Foster & Treherne (1981) Evidence for the dilution effect in
#'     the selfish herd from fish predation on a marine insect,
#'     *Nature* 293:466--467.}
#' }
#'
#' ## Habitat preference (ideal free distribution)
#' \describe{
#'   \item{`habitat_preference_evolution`}{Logical. Enable heritable habitat
#'     preference (default `FALSE`). Preference encodes optimal local grass
#'     density; agents are attracted to cells matching their preference.
#'     Reference: Fretwell & Lucas (1970) On territorial behavior and other
#'     factors influencing habitat distribution in birds,
#'     *Acta Biotheoretica* 19(1):16--36.}
#' }
#'
#' ## Seasonal dynamics
#' \describe{
#'   \item{`seasonal_amplitude`}{Numeric. Amplitude of sinusoidal grass_rate
#'     modulation (default 0 = off). grass_rate_t = grass_rate *
#'     (1 + seasonal_amplitude * sin(2 * pi * t / seasonal_period)).}
#'   \item{`seasonal_period`}{Integer. Period of seasonal cycle in ticks
#'     (default 100L).}
#' }
#'
#' ## Speciation (genome clustering)
#' \describe{
#'   \item{`speciation`}{Logical. Enable reproductive isolation based on genome
#'     distance (default `FALSE`). Agents only mate with conspecifics
#'     (genome distance < isolation_threshold).
#'     Reference: Gavrilets (2004) *Fitness Landscapes and the Origin of
#'     Species*, Princeton UP.}
#'   \item{`isolation_threshold`}{Numeric. Maximum genome distance for
#'     successful mating (default 0.45). Species are inferred by hierarchical
#'     clustering of genome distances at each logging tick.}
#' }
#'
#' ## Social learning
#' \describe{
#'   \item{`social_learning`}{Logical. Enable copying of output-layer weights
#'     from successful neighbours (default `FALSE`). Implements prestige bias.
#'     Reference: Laland (2004) Social learning strategies,
#'     *Learning and Behavior* 32(1):4--14.}
#'   \item{`social_learning_freq`}{Integer. Apply social learning every this
#'     many ticks (default 10L).}
#'   \item{`social_learning_rate`}{Numeric. Fraction of neighbour weights
#'     copied (default 0.1).}
#' }
#'
#' ## World evolution (parameter co-evolution)
#'
#' When `world_evolution = TRUE`, the environment parameters listed in
#' `world_params_to_evolve` are treated as evolvable quantities that change
#' via random drift each tick, allowing the environment to co-evolve with
#' agents. This extends the MAP-Elites search into a joint agent-environment
#' space.
#'
#' \describe{
#'   \item{`world_evolution`}{Logical. Enable world parameter evolution
#'     (default `FALSE`).}
#'   \item{`world_mutation_sd`}{Numeric. Standard deviation of Gaussian
#'     perturbations to world parameters per tick (default 0.02).}
#'   \item{`world_params_to_evolve`}{Character vector. Names of parameters in
#'     `default_specs()` to treat as evolvable. Example:
#'     `c("grass_rate", "disease_death_prob")`. Defaults to
#'     `character(0)` (none).}
#' }
#'
#' ## Complex multi-resource landscape (Tier 1)
#'
#' Adds shrub and canopy resource layers on top of ground grass.
#' Canopy access requires `wing_size >= canopy_threshold` (heritable).
#' Designed to break the standard brain-size x longevity correlation.
#' Reference: Liedtke & Fromhage (2019); Isbell (2006).
#' \describe{
#'   \item{`complex_landscape`}{Logical. Enable multi-layer resources
#'     (default `FALSE`).}
#'   \item{`shrub_density`}{Numeric in \[0, 1\]. Initial fraction of cells
#'     with shrub resource (default 0.3).}
#'   \item{`shrub_growth_rate`}{Numeric. Per-tick fractional regrowth of
#'     shrubs (default 0.03).}
#'   \item{`shrub_energy`}{Numeric. Maximum energy a shrub cell provides
#'     (default 20.0).}
#'   \item{`canopy_density`}{Numeric in \[0, 1\]. Initial canopy coverage
#'     (default 0.15; trees are sparse).}
#'   \item{`canopy_growth_rate`}{Numeric. Per-tick fractional regrowth of
#'     canopy (default 0.005; trees grow slowly).}
#'   \item{`canopy_energy`}{Numeric. Maximum energy a canopy cell provides
#'     (default 50.0; high energy density for aerial specialists).}
#'   \item{`canopy_threshold`}{Numeric. Minimum `wing_size` needed for
#'     canopy access (default 0.6).}
#'   \item{`wing_size_init_mean`}{Numeric. Initial mean `wing_size` (default
#'     0.0; ground-bound founders).}
#'   \item{`wing_size_mutation_sd`}{Numeric. Mutation SD for `wing_size`
#'     (default 0.05).}
#'   \item{`wing_size_min`}{Numeric. Minimum wing size (default 0.0).}
#'   \item{`wing_size_max`}{Numeric. Maximum wing size (default 1.0).}
#' }
#'
#' ## Spatial sorting (Tier 2a)
#'
#' Implements assortative mating at the invasion range front, causing
#' dispersal-enhancing alleles to accumulate at the frontier without requiring
#' any fitness advantage over sedentary conspecifics.
#' Reference: Shine et al. (2011) An evolutionary process that assembles
#' phenotypes through space rather than through time. *PNAS* 108:5708--5711.
#' Requires `dispersal_evolution = TRUE` to have effect.
#' \describe{
#'   \item{`spatial_sorting`}{Logical. Enable range-front mate preference
#'     for high-dispersal partners (default `FALSE`).}
#'   \item{`sorting_front_threshold`}{Numeric in \[0, 1\]. Fraction of maximum
#'     range radius that defines "the front" (default 0.75; outermost 25%).}
#'   \item{`sorting_mating_boost`}{Numeric. Multiplier applied to
#'     `dispersal_tendency` when scoring mates at the front (default 3.0).}
#' }
#'
#' ## IFfolk inclusive fitness (Tier 2b)
#'
#' IFfolk = own offspring + sum(r x relative's offspring). Agents transfer
#' energy to energy-depleted kin. Optional parliament suppression penalises
#' defectors in cooperative populations.
#' Reference: Fromhage & Jennions (2019) The strategic reference gene.
#' *Proc R Soc B* 286:20190459. doi:10.1098/rspb.2019.0459
#' \describe{
#'   \item{`iffolk_selection`}{Logical. Enable IFfolk energy transfers
#'     (default `FALSE`).}
#'   \item{`iffolk_r_min`}{Numeric. Minimum relatedness coefficient for a
#'     relative to count (default 0.125 = cousin).}
#'   \item{`iffolk_radius`}{Integer. Spatial search radius for relatives in
#'     grid cells (default 5L).}
#'   \item{`iffolk_transfer`}{Numeric. Maximum energy transferred per
#'     altruistic act (default 3.0).}
#'   \item{`iffolk_min_energy`}{Numeric. Minimum donor energy required to
#'     transfer (default 60.0).}
#'   \item{`parliament_suppression`}{Logical. Enable parliament-of-genes
#'     penalty for defectors (negative `helper_tendency`) when surrounded
#'     by cooperators (default `FALSE`).}
#'   \item{`parliament_cost`}{Numeric. Energy cost per tick for defectors
#'     in cooperative neighbourhoods (default 0.5).}
#' }
#'
#' ## Fixed patch (stable fitness peak — Baldwin Effect demonstration)
#'
#' Places one or more grid cells whose grass value is reset to
#' `fixed_patch_value` after every `grow_grass!` call, creating a permanent
#' high-value resource that never depletes. This gives natural selection a
#' *stable fitness peak*: agents whose genome encodes a fixed policy of
#' navigating to the patch always outperform agents that must re-discover it
#' by exploration each lifetime. The result is genetic assimilation of the
#' patch-navigation strategy — the computational Baldwin Effect as described
#' by Hinton \& Nowlan (1987).
#'
#' Without this module, the foraging fitness landscape shifts continuously
#' (stochastic grass, population density feedbacks) and exploration remains
#' the evolutionarily stable strategy (`mean_prior_sigma` rises to ceiling).
#'
#' Reference: Hinton, G.E. \& Nowlan, S.J. (1987) How learning can guide
#' evolution. \emph{Complex Systems} 1(3):495--502.
#' \describe{
#'   \item{`fixed_patch`}{Logical. Enable the stable resource patch
#'     (default `FALSE`).}
#'   \item{`fixed_patch_value`}{Numeric. Grass value maintained at patch
#'     cells each tick (default `5.0`, equal to `grass_max`). Values above
#'     `grass_max` are permitted — the cap in `grow_grass!` does not apply
#'     because the patch uses direct assignment.}
#'   \item{`fixed_patch_x`}{Integer or `NA_integer_`. Column index of the
#'     patch centre (1-indexed). `NA_integer_` resolves to the grid centre
#'     column (default).}
#'   \item{`fixed_patch_y`}{Integer or `NA_integer_`. Row index of the
#'     patch centre (1-indexed). `NA_integer_` resolves to the grid centre
#'     row (default).}
#'   \item{`fixed_patch_radius`}{Integer. Chebyshev radius of the patch:
#'     `0L` = single cell; `1L` = 3×3 block; `2L` = 5×5 block
#'     (default `0L`).}
#' }
#'
#' ## Logging
#' \describe{
#'   \item{`log_freq`}{Integer. Log population-level statistics every this many
#'     ticks (default 1L; set higher to reduce memory use in long runs).}
#'   \item{`log_genomes`}{Logical. Log flattened genome vectors to
#'     `get_genome_data()$genomes` at each log tick (default `FALSE`;
#'     memory intensive for large populations).}
#'   \item{`random_seed`}{Integer or `NA_integer_`. Seed for Julia's RNG.
#'     `NA_integer_` uses a random seed (default).}
#' }
#'
#' @return A named list of simulation parameters.
#'
#' @examples
#' specs <- default_specs()
#' specs$brain_type   <- "bnn"
#' specs$ploidy       <- 2L
#' specs$n_agents_init <- 100L
#' # run_alife(specs)   # requires Julia
#'
#' @seealso [run_alife()], [get_run_data()], [search_map_elites()]
#' @export
default_specs <- function() {
  list(
    # ── Grid and population ────────────────────────────────────────────────
    grid_rows              = 30L,
    grid_cols              = 30L,
    toroidal               = TRUE,      # D1: FALSE = boundary edges, TRUE = wrap-around
    n_agents_init          = 50L,
    max_agents             = 500L,
    max_ticks              = 500L,

    # ── Energy and metabolism ──────────────────────────────────────────────
    energy_init                 = 100.0,
    energy_max                  = 200.0,
    move_cost                   = 1.0,
    idle_cost                   = 0.5,
    eat_gain                    = 5.0,
    max_bite                    = 2.0,           # 0.4.0: handling time
    min_repro_energy            = 120.0,
    repro_cost_mode             = "proportional",# 0.4.0: Smith-Fretwell default
    repro_cost                  = 30.0,          # used if mode = "fixed"
    repro_cost_fraction         = 0.5,           # 0.4.0: fraction of parent energy
    offspring_energy_mode       = "proportional",# 0.4.0
    offspring_energy            = 60.0,          # used if mode = "fixed"
    offspring_energy_fraction   = 0.25,          # 0.4.0: fraction of cost_paid
    starvation_threshold        = 0.0,
    max_age_scales_with_metabolism = FALSE,      # 0.4.0 Tier 2: Réale 2010 pace-of-life

    # ── Grass ──────────────────────────────────────────────────────────────
    grass_init_prob        = 0.5,
    grass_rate             = 0.05,
    grass_max              = 5.0,

    # ── Brain architecture ─────────────────────────────────────────────────
    brain_type             = "bnn",
    hidden_layers          = c(8L),
    input_radius           = 1L,
    n_genes                = 20L,
    transformer_history    = 8L,
    transformer_heads      = 2L,
    synthesis_max_rules    = 10L,
    ann_weight_values      = NULL,         # NULL = continuous weights (default).
                                           # Numeric vector: snap each weight to
                                           # the nearest element after genome
                                           # expression. E.g. c(-1, 0, 1) for
                                           # ternary weights. Applied to "ann"
                                           # and "bnn" brain types.
    ann_regularization        = "none",   # "none", "weight_magnitude", "weight_count"
    ann_regularization_lambda = 0.001,    # penalty scale (energy / unit / tick)

    # ── Brain energy cost ──────────────────────────────────────────────────
    brain_energy_mode         = "activity",
    brain_energy_base         = 0.001,
    brain_energy_activity     = 0.5,
    brain_energy_sigma_scale  = 0.0,   # 0.4.1 Tier 5C: information cost
                                       # of BNN prior width (sigma).
                                       # Default 0 preserves legacy. Set
                                       # to ~0.005–0.05 for Baldwin
                                       # canalisation scenarios.
    brain_energy_size_exponent = 1.0,  # 0.4.3: super-linear brain-size
                                       # cost. 1.0 = linear (legacy);
                                       # 1.5 = Kleiber-style expensive-
                                       # brain amplification (Isler &
                                       # van Schaik 2009). Applied as
                                       # size_cost = base * n_weights^exp.

    # ── BNN brain ──────────────────────────────────────────────────────────
    bnn_sigma_init    = 0.5,                 # haploid default & "fixed" mode
    bnn_sigma_min     = 0.01,                # floor for all modes
    bnn_sigma_source  = "heterozygosity",    # 0.4.0 Tier 5A: "heterozygosity"
                                             # (legacy), "fixed", or "trait"
    bnn_sample_freq   = 1L,                  # 0.4.0 Tier 5B: resample every
                                             # N forward calls; 1 = legacy
                                             # per-tick sampling. Higher values
                                             # let RL/social-learning updates
                                             # accumulate before washout.

    # ── Genome and ploidy ──────────────────────────────────────────────────
    ploidy                 = 2L,
    n_chromosomes          = 1L,
    crossover_rate         = 1.0,
    dominance_model        = "additive",

    # ── Mutation ───────────────────────────────────────────────────────────
    mutation_sd                = 0.1,
    mutation_rate_evolution    = FALSE,
    mutation_sd_init_mean      = 0.1,
    mutation_sd_min            = 0.001,
    mutation_sd_max            = 1.0,

    # ── Learning and plasticity ────────────────────────────────────────────
    rl_mode                    = "none",
    learning_rate              = 0.01,
    learning_rate_evolution    = FALSE,
    learning_rate_init_mean    = 0.01,
    learning_rate_min          = 0.0,
    learning_rate_max          = 0.5,
    plasticity_cost            = 0.05,
    rl_update_freq             = 1L,
    lamarckian                 = FALSE,   # if TRUE and rl_mode != "none": write
                                          # RL-learned brain weights back to genome
                                          # before meiosis so offspring directly
                                          # inherit the learned solution. Distinct
                                          # from epigenetics (which inherits
                                          # methylation marks, not weight values).
                                          # See modules/lamarckian.jl for detail.

    # ── Epigenetics ────────────────────────────────────────────────────────
    epigenetics                    = FALSE,
    epigenetic_learning_coupling   = 0.10,
    epigenetic_inheritance         = 0.50,
    epigenetic_effect_size         = 0.20,
    methylation_rate               = 0.001,
    demethylation_rate             = 0.002,

    # ── Life history ───────────────────────────────────────────────────────
    life_history               = "iteroparous",
    max_age                    = 200L,
    senescence_rate            = 0.0,
    repro_senescence           = 0.0,
    life_history_evolution     = FALSE,
    allee_threshold            = 0L,

    # ── Body size evolution ────────────────────────────────────────────────
    body_size_evolution        = FALSE,
    body_size_init_mean        = 1.0,
    body_size_mutation_sd      = 0.08,
    body_size_min              = 0.3,
    body_size_max              = 3.0,

    # ── Brain size evolution (parental provisioning hypothesis) ───────────
    brain_size_evolution       = FALSE,
    brain_size_init_mean       = 1.0,
    brain_size_mutation_sd     = 0.05,
    brain_size_min             = 0.1,
    brain_size_max             = 3.0,
    brain_size_cost_scale       = 1.0,
    brain_size_sensing_exponent = 0.3,

    # ── Metabolic rate evolution ───────────────────────────────────────────
    metabolic_rate_evolution   = FALSE,
    metabolic_rate_init_mean   = 1.0,
    metabolic_rate_mutation_sd = 0.05,
    metabolic_rate_min         = 0.1,
    metabolic_rate_max         = 5.0,

    # ── Aging rate evolution ───────────────────────────────────────────────
    aging_rate_evolution       = FALSE,
    aging_rate_init_mean       = 1.0,
    aging_rate_mutation_sd     = 0.05,
    aging_rate_min             = 0.01,
    aging_rate_max             = 10.0,

    # ── Immune system ──────────────────────────────────────────────────────
    immune_evolution               = FALSE,
    immune_strength_init_mean      = 0.3,
    immune_strength_mutation_sd    = 0.05,
    immune_strength_min            = 0.0,
    immune_strength_max            = 1.0,

    # ── Disease (SIR) ──────────────────────────────────────────────────────
    disease                    = FALSE,
    disease_seed_prob          = 0.01,
    transmission_prob          = 0.1,
    disease_duration           = 10L,
    immune_duration            = 20L,
    disease_energy_cost        = 5.0,
    disease_death_prob         = 0.02,

    # ── Kin selection ──────────────────────────────────────────────────────
    kin_selection                  = FALSE,
    kin_altruism_cost              = 2.0,
    kin_altruism_benefit           = 10.0,
    kin_altruism_r_min             = 0.25,
    kin_altruism_min_donor_energy  = 50.0,

    # ── Cooperation (public goods game) ────────────────────────────────────
    cooperation_evolution      = FALSE,
    cooperation_multiplier     = 2.0,
    cooperation_init_mean      = 0.5,
    cooperation_mutation_sd    = 0.05,
    cooperation_cost           = 1.0,

    # ── Dispersal evolution ────────────────────────────────────────────────
    dispersal_evolution        = FALSE,
    dispersal_cost             = 2.0,
    dispersal_init_mean        = 0.1,
    dispersal_mutation_sd      = 0.02,
    dispersal_min              = 0.0,
    dispersal_max              = 0.5,

    # ── Habitat preference evolution ───────────────────────────────────────
    habitat_preference_evolution = FALSE,
    habitat_preference_init_mean = 0.0,
    habitat_preference_mutation_sd = 0.03,
    habitat_preference_min      = -1.0,
    habitat_preference_max      =  1.0,
    habitat_preference_strength = 0.5,
    habitat_move_cost           = 0.0,

    # ── Group defense (dilution of risk) ──────────────────────────────────
    group_defense               = FALSE,
    group_defense_radius        = 2L,
    group_defense_strength      = 0.3,

    # ── Seasonal dynamics ─────────────────────────────────────────────────
    seasonal_amplitude          = 0.0,
    season_length               = 100L,
    winter_death_prob           = 0.0,

    # ── Parental care ──────────────────────────────────────────────────────
    parental_care              = FALSE,
    care_cost_per_tick         = 1.0,
    feeding_rate               = 5.0,
    juvenile_independence_age  = 10L,
    juvenile_independence_energy = 50.0,
    max_clutch_size            = 1L,
    # 0.4.3: neonatal foraging deficit — young agents can't forage at
    # adult efficiency. During the first `neonatal_deficit_duration`
    # ticks of life, their effective max_bite is scaled by
    # `1 - neonatal_foraging_deficit`. Default 0.0 preserves legacy
    # behaviour; set 0.3–0.6 to create the selection pressure for
    # parental provisioning that the expensive-brain hypothesis
    # (Aiello & Wheeler 1995; Isler & van Schaik 2009) identifies.
    neonatal_foraging_deficit   = 0.0,
    neonatal_deficit_duration   = 10L,

    # ── Cooperative breeding ───────────────────────────────────────────────
    cooperative_breeding       = FALSE,
    helper_min_energy          = 80.0,
    helper_transfer            = 5.0,
    helper_kin_threshold       = 0.25,
    helper_tendency_init_mean  = 0.1,
    helper_tendency_mutation_sd = 0.02,

    # ── Signal evolution and mate choice ──────────────────────────────────
    signal_dims                = 0L,
    signal_cost                = 0.1,
    signal_evolution_drift     = TRUE,
    signal_drift_sd            = 0.01,
    mate_choice_mode           = "random",
    mate_choice_strength       = 0.5,
    # 0.4.4: aposematic honest signalling. When > 0, each agent's
    # `signal[1]` is pulled per tick toward its own `toxicity` value
    # (`signal[1] ← (1-coupling)*signal[1] + coupling*toxicity`).
    # At coupling=0 (default) signal evolves freely; at coupling=1
    # signal[1] is locked to toxicity. Required for Bates/Müller
    # aposematic dynamics to close the feedback loop. Active only
    # when `mimicry = TRUE` and `signal_dims > 0`.
    signal_toxicity_coupling   = 0.0,

    # 0.5.0 / 0.5.1: Hamilton 1980 Red Queen coevolving-parasite module.
    # Two matching modes (see `parasite_match_mode`):
    #   "continuous" — Euclidean distance on signal vector (0.5.0;
    #     mean-tracking; does NOT produce the canonical Red Queen)
    #   "discrete"   — Hamming distance on binary haplotype (0.5.1;
    #     requires n_parasite_loci > 0; reproduces Hamilton's canonical
    #     mechanism because sex with Mendelian recombination produces
    #     genuinely novel haplotypes)
    #   "auto"       — pick discrete if n_parasite_loci > 0, else continuous
    coevolving_parasites       = FALSE,
    parasite_match_mode        = "auto",
    parasite_virulence_rate    = 0.1,
    parasite_pressure          = 0.5,
    parasite_distance_scale    = 1.0,
    # Discrete-mode (0.5.1) parameters
    n_parasite_loci            = 0L,
    parasite_mutation_rate     = 0.01,
    parasite_discrete_exponent = 4.0,

    # ── Speciation (genome-distance clustering) ────────────────────────────
    speciation                 = FALSE,
    isolation_threshold        = 0.5,
    speciation_cluster_interval = 10L,

    # ── Predators ─────────────────────────────────────────────────────────
    n_predators_init           = 0L,
    predator_energy_init       = 150.0,
    predator_live_energy       = 2.0,
    predator_move_energy       = 1.0,
    predator_attack_strength   = 40.0,
    predator_energy_gain       = 30.0,
    predator_min_repro_energy  = 200.0,
    predator_min_repro_age     = 5L,
    predator_mutation_sd       = 0.1,
    predator_max_agents        = 50L,
    predator_sense_graded      = TRUE, # 0.4.2: prey's predator sense is 1/(d+1), not binary



    # ── Mimicry / toxicity ─────────────────────────────────────────────────
    mimicry                    = FALSE,
    batesian_mimicry           = FALSE,
    toxicity_cost_per_tick     = 2.0,
    toxin_dose                 = 30.0,
    signal_memory_rate         = 0.3,
    avoid_threshold            = 0.5,
    toxicity_init_mean         = 0.0,
    toxicity_mutation_sd       = 0.05,

    # ── Phenotypic plasticity ──────────────────────────────────────────────
    phenotypic_plasticity      = FALSE,
    plasticity_sense_radius    = 3L,
    plasticity_init_mean       = 0.3,
    plasticity_mutation_sd     = 0.03,
    plasticity_min             = 0.0,
    plasticity_max             = 1.0,

    # ── Niche construction ─────────────────────────────────────────────────
    niche_construction         = FALSE,
    shelter_build_prob         = 0.1,
    shelter_max_depth          = 5L,
    shelter_min_energy         = 80.0,
    shelter_decay_prob         = 0.05,
    shelter_occupancy_bonus    = 0.0,   # >0 to enable heritable niche benefit

    # ── Scavenging ─────────────────────────────────────────────────────────
    scavenging                 = FALSE,
    carrion_fraction           = 0.5,
    carrion_decay_rate         = 0.1,
    carrion_eat_gain           = 3.0,
    carrion_transmission_prob  = 0.0,   # D2: prob infected carrion infects scavenger (0 = off)

    # ── Social learning ────────────────────────────────────────────────────
    social_learning            = FALSE,
    social_learning_freq       = 10L,
    social_learning_rate       = 0.1,

    # ── Clutch size evolution ──────────────────────────────────────────────
    clutch_size_evolution      = FALSE,
    clutch_size_init_mean      = 1.0,
    clutch_size_min            = 1L,
    clutch_size_max            = 5L,
    clutch_size_mutation_sd    = 0.3,

    # ── Parental investment evolution ──────────────────────────────────────
    parental_investment_evolution = FALSE,
    parental_investment_init_mean = 0.5,
    female_investment          = 0.7,
    male_repro_cost            = 0.3,

    # ── Stress hypermutation ───────────────────────────────────────────────
    stress_hypermutation       = FALSE,
    stress_mutation_multiplier = 3.0,
    stress_threshold           = 20.0,

    # ── Senescence shape (Gompertz) ────────────────────────────────────────
    senescence_shape           = 2.0,

    # ── Reproduction ──────────────────────────────────────────────────────
    min_repro_age              = 0L,

    # ── Map generation (walls/barriers) ───────────────────────────────────
    wall_density               = 0.0,
    wall_clusters              = TRUE,

    # ── World evolution ────────────────────────────────────────────────────
    world_evolution            = FALSE,
    world_mutation_sd          = 0.02,
    world_params_to_evolve     = character(0L),

    # ── Complex multi-resource landscape (Tier 1) ─────────────────────────
    complex_landscape           = FALSE,
    shrub_density               = 0.3,
    shrub_growth_rate           = 0.03,
    shrub_energy                = 20.0,
    canopy_density              = 0.15,
    canopy_growth_rate          = 0.005,
    canopy_energy               = 50.0,
    canopy_threshold            = 0.15,
    wing_size_init_mean         = 0.08,
    wing_size_mutation_sd       = 0.05,
    wing_size_min               = 0.0,
    wing_size_max               = 1.0,

    # ── Spatial sorting (Tier 2a) ──────────────────────────────────────────
    spatial_sorting             = FALSE,
    sorting_front_threshold     = 0.75,
    sorting_mating_boost        = 3.0,

    # ── IFfolk inclusive fitness (Tier 2b) ────────────────────────────────
    iffolk_selection            = FALSE,
    iffolk_r_min                = 0.125,
    iffolk_radius               = 5L,
    iffolk_transfer             = 3.0,
    iffolk_min_energy           = 60.0,
    parliament_suppression      = FALSE,
    parliament_cost             = 0.5,

    # ── Fixed patch (stable fitness peak — Baldwin Effect demonstration) ───
    fixed_patch                 = FALSE,
    fixed_patch_value           = 5.0,
    fixed_patch_x               = NA_integer_,
    fixed_patch_y               = NA_integer_,
    fixed_patch_radius          = 0L,

    # ── Logging ────────────────────────────────────────────────────────────
    log_freq                   = 1L,
    log_genomes                = FALSE,
    random_seed                = NA_integer_
  )
}

#' Quick preset specs for fast exploratory runs
#'
#' Returns [default_specs()] with a smaller grid, fewer agents, and shorter
#' run length. Use for rapid prototyping and parameter sweeps where exact
#' biological accuracy is less important than turnaround time.
#'
#' Typical wall time: ~30 seconds per run (Julia warm-up excluded).
#'
#' @return A specs list identical to [default_specs()] except:
#' \describe{
#'   \item{`n_agents_init`}{50L}
#'   \item{`max_ticks`}{200L}
#'   \item{`grid_rows`, `grid_cols`}{20L × 20L}
#' }
#' @seealso [default_specs()], [full_specs()]
#' @export
quick_specs <- function() {
  s <- default_specs()
  s$n_agents_init <- 50L
  s$max_ticks     <- 200L
  s$grid_rows     <- 20L
  s$grid_cols     <- 20L
  s
}

#' Full preset specs for publication-quality runs
#'
#' Returns [default_specs()] with a larger grid, more agents, and a longer
#' run to allow evolutionary dynamics to stabilise. Use for final experiments
#' and vignette figures.
#'
#' Typical wall time: ~10–20 minutes per run (Julia warm-up excluded).
#'
#' @return A specs list identical to [default_specs()] except:
#' \describe{
#'   \item{`n_agents_init`}{200L}
#'   \item{`max_ticks`}{1000L}
#'   \item{`grid_rows`, `grid_cols`}{30L × 30L}
#' }
#' @seealso [default_specs()], [quick_specs()]
#' @export
full_specs <- function() {
  s <- default_specs()
  s$n_agents_init <- 200L
  s$max_ticks     <- 1000L
  s$grid_rows     <- 30L
  s$grid_cols     <- 30L
  s
}
