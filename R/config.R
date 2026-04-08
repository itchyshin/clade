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
#'   \item{`min_repro_energy`}{Numeric. Minimum energy required to attempt
#'     reproduction (default 120).}
#'   \item{`repro_cost`}{Numeric. Energy deducted from parent at reproduction
#'     (default 30).}
#'   \item{`offspring_energy`}{Numeric. Energy given to each new offspring
#'     (default 60).}
#'   \item{`starvation_threshold`}{Numeric. Agent dies when energy falls below
#'     this value (default 0).}
#' }
#'
#' ## Grass dynamics
#' \describe{
#'   \item{`grass_init_prob`}{Numeric in [0, 1]. Probability each cell starts
#'     with grass (default 0.5).}
#'   \item{`grass_rate`}{Numeric in [0, 1]. Per-tick probability that an empty
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
#'
#'     * `"bnn"` — **Bayesian Neural Network** (default). Each synaptic weight
#'       is a probability distribution (mean mu, standard deviation sigma)
#'       rather than a fixed value. The genome encodes the prior (mu, sigma);
#'       within lifetime, experience updates the posterior via approximate
#'       Bayesian inference (sigma shrinks as the agent becomes more certain).
#'       Exploration is automatic: high sigma = uncertain = explore. Diploid
#'       genomes connect naturally: heterozygosity at a locus sets the prior
#'       width for that weight. Implemented via Turing.jl.
#'       References: Neal (1996) *Bayesian Learning for Neural Networks*,
#'       Springer; Blundell et al. (2015) Weight Uncertainty in Neural
#'       Networks, *ICML* pp 1613--1622.
#'
#'     * `"ann"` — **Multilayer Perceptron**. Standard feedforward network with
#'       fixed weights. Architecture set by `hidden_layers`. Compatible with
#'       the `alifeR` ANN format.
#'       Reference: Rumelhart, Hinton & Williams (1986) Learning
#'       representations by back-propagating errors, *Nature* 323:533--536.
#'
#'     * `"ctrnn"` — **Continuous-Time Recurrent Neural Network**. Each neuron
#'       i has an internal state y_i governed by the ODE:
#'       tau_i * dy_i/dt = -y_i + sum_j(w_ij * sigma(y_j + theta_j)) + I_i.
#'       Produces temporal dynamics, rhythmic behaviour, and autonomous
#'       initiation. Genome encodes tau (time constants), W (weights), and
#'       theta (biases).
#'       Reference: Beer (1995) On the dynamics of small continuous-time
#'       recurrent neural networks, *Adaptive Behavior* 3(4):469--509.
#'
#'     * `"grn"` — **Gene Regulatory Network**. The genome IS the brain;
#'       no separate neural network. Each locus represents a gene whose
#'       expression level is regulated by other genes. Some genes receive
#'       sensory input; others produce action output. Behaviour emerges from
#'       ~15-30 gene interaction dynamics simulated each tick. Maximally
#'       biologically minimal. When `ploidy = 2`, each regulatory link has
#'       two alleles and methylation directly suppresses gene expression.
#'       References: Kauffman (1993) *The Origins of Order*, Oxford UP;
#'       Watson & Szathmary (2016) How can evolution learn?, *Trends in
#'       Ecology and Evolution* 31(2):147--157.
#'
#'     * `"transformer"` — **Attention-Based Transformer**. Attends over a
#'       rolling window of the last `transformer_history` sensory inputs.
#'       Genome encodes query/key/value projection weights and feed-forward
#'       layers. Enables agents to integrate temporal context without explicit
#'       memory parameters.
#'       Reference: Vaswani et al. (2017) Attention is all you need,
#'       *NeurIPS* 30.
#'
#'     * `"synthesis"` — **Formal / Symbolic Rule Synthesis**. The agent's
#'       brain is an evolved symbolic program: a set of IF-THEN rules of the
#'       form (IF condition_1 AND condition_2 THEN action). Rules are encoded
#'       as a structured list. Evolution proceeds by rule mutation
#'       (add/remove/modify a rule) and rule-set crossover (swap rule subsets
#'       between parents). Behaviour is interpretable and human-readable.
#'       Reference: Angeline, Saunders & Pollack (1994) An evolutionary
#'       algorithm that constructs recurrent neural networks, *IEEE
#'       Transactions on Neural Networks* 5(1):54--65; see also Koza (1992)
#'       *Genetic Programming*, MIT Press.
#'
#'     * `"random"` — Null brain. Chooses actions uniformly at random.
#'       Used as a baseline to confirm that evolved behaviour outperforms
#'       chance.
#'   }
#'   \item{`hidden_layers`}{Integer vector. Hidden layer widths for `"ann"` and
#'     `"bnn"` (default `c(8L)`; gives one hidden layer of 8 units). Set to
#'     `c(16L, 8L)` for two hidden layers.}
#'   \item{`n_genes`}{Integer. Number of genes for `"grn"` brain type
#'     (default 20L). Includes sensory input genes and action output genes.}
#'   \item{`transformer_history`}{Integer. Number of past sensory inputs the
#'     transformer attends over (default 8L).}
#'   \item{`transformer_heads`}{Integer. Number of attention heads (default 2L).}
#'   \item{`synthesis_max_rules`}{Integer. Maximum number of IF-THEN rules
#'     per agent (default 10L).}
#' }
#'
#' ## Brain energy cost
#'
#' Brain energy cost models the metabolic cost of neural computation, as in
#' the Polyworld simulation (Yaeger 1994).
#'
#' \describe{
#'   \item{`brain_energy_mode`}{Character. One of `"none"`, `"size"`,
#'     `"activity"` (default), or `"prediction_error"`.
#'
#'     * `"none"` — no brain energy cost.
#'     * `"size"` — cost proportional to number of synaptic weights.
#'     * `"activity"` — cost = `brain_energy_base * n_weights +
#'       brain_energy_activity * mean(|activations|)`. Larger and more active
#'       brains are more costly.
#'     * `"prediction_error"` — BNN-only; cost proportional to KL divergence
#'       between prior and posterior (measures how much the agent had to
#'       update its beliefs).
#'
#'     Reference: Yaeger (1994) Computational genetics, physiology, metabolism,
#'     neural systems, learning, vision, and behavior or PolyWorld: Life in a
#'     new context, in *Artificial Life III*, Addison-Wesley, pp 263--298.
#'   }
#'   \item{`brain_energy_base`}{Numeric. Fixed cost per synaptic weight per
#'     tick (default 0.001).}
#'   \item{`brain_energy_activity`}{Numeric. Scaling factor on mean absolute
#'     activation when `brain_energy_mode = "activity"` (default 0.5).}
#' }
#'
#' ## Genome and ploidy
#'
#' clade supports haploid (default) and diploid life cycles. The diploid path
#' implements full Mendelian genetics with independent assortment and
#' recombination.
#'
#' \describe{
#'   \item{`ploidy`}{Integer. `1L` = haploid (default); `2L` = diploid.
#'     In the diploid case every heritable trait (brain weights, body size,
#'     immune strength, cooperation level, etc.) has two alleles — one
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
#'     combine to produce the expressed phenotype:
#'     * `"additive"` (default) — phenotype = (maternal + paternal) / 2.
#'     * `"dominant"` — randomly choose one allele at each locus.
#'     * `"codominant"` — both alleles expressed; implemented as additive but
#'       reported separately in `get_genome_data()`.
#'
#'     Reference: Charlesworth & Charlesworth (2010) *Elements of Evolutionary
#'     Genetics*, Roberts & Company, Chapter 5.
#'   }
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
#'     `"none"` (default), `"actor_critic"`, or `"hebbian"`.
#'
#'     * `"actor_critic"` — REINFORCE with baseline (Williams 1992).
#'       Reward = energy delta per tick. Advantage = reward - running mean
#'       (`value_estimate`). Applied to output weights for the chosen action.
#'     * `"hebbian"` — Hebbian potentiation: weights between co-active
#'       neurons are strengthened proportionally to joint activation
#'       (Hebb 1949).
#'
#'     References:
#'     Williams (1992) Simple statistical gradient-following algorithms for
#'     connectionist reinforcement learning, *Machine Learning* 8:229--256.
#'     Hebb (1949) *The Organisation of Behavior*, Wiley.
#'   }
#'   \item{`learning_rate`}{Numeric. Step size for within-lifetime weight
#'     updates (default 0.01).}
#'   \item{`learning_rate_evolution`}{Logical. If `TRUE`, `learning_rate` is a
#'     heritable diploid trait (default `FALSE`). Enables study of the Baldwin
#'     Effect (Baldwin 1896, Hinton & Nowlan 1987).
#'
#'     References:
#'     Baldwin (1896) A new factor in evolution, *American Naturalist*
#'     30:441--451.
#'     Hinton & Nowlan (1987) How learning can guide evolution, *Complex
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
#' the prior sigma_i (canalization — the agent becomes less plastic at that
#' weight). This implements transgenerational epigenetic inheritance (TEI) as
#' described by Jablonka & Lamb (2005).
#'
#' \describe{
#'   \item{`epigenetics`}{Logical. Enable epigenetic methylation and TEI
#'     (default `FALSE`).
#'     Reference: Jablonka & Lamb (2005) *Evolution in Four Dimensions*,
#'     MIT Press.}
#'   \item{`epigenetic_learning_coupling`}{Numeric in [0, 1]. Probability that
#'     a within-lifetime learning event methylates the corresponding locus
#'     (default 0.10).}
#'   \item{`epigenetic_inheritance`}{Numeric in [0, 1]. Fraction of the
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
#' }
#'
#' ## Life history
#' \describe{
#'   \item{`life_history`}{Character. `"iteroparous"` (default) or
#'     `"semelparous"`. Semelparous agents die immediately after reproducing.
#'     Reference: Stearns (1992) *The Evolution of Life Histories*, Oxford UP.}
#'   \item{`max_age`}{Integer. Maximum lifespan in ticks; agents die at this
#'     age regardless of energy (default 200L). Set to `Inf` to disable.}
#'   \item{`senescence_rate`}{Numeric in [0, 1]. Gompertz mortality rate;
#'     per-tick death probability scales as exp(senescence_rate * age)
#'     (default 0 = no senescence).
#'     Reference: Gompertz (1825) On the nature of the function expressive of
#'     the law of human mortality, *Philosophical Transactions of the Royal
#'     Society* 115:513--583.}
#'   \item{`repro_senescence`}{Numeric in [0, 1]. Per-tick decline in
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
#'     (default `FALSE`). Body size scales metabolic costs via Kleiber's law:
#'     metabolic_cost proportional to body_size^0.75.
#'     Reference: Kleiber (1947) Body size and metabolic rate,
#'     *Physiological Reviews* 27(4):511--541.}
#'   \item{`body_size_init_mean`}{Numeric. Initial mean body size
#'     (default 1.0).}
#'   \item{`body_size_mutation_sd`}{Numeric. Mutation SD for body size
#'     (default 0.05).}
#'   \item{`body_size_min`}{Numeric. Minimum body size (default 0.1).}
#'   \item{`body_size_max`}{Numeric. Maximum body size (default 5.0).}
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
#'   \item{`disease_seed_prob`}{Numeric in [0, 1]. Probability each agent is
#'     initially infected at tick 1 (default 0.01).}
#'   \item{`transmission_prob`}{Numeric in [0, 1]. Probability of transmission
#'     to a susceptible neighbour per infected-susceptible adjacent pair per
#'     tick (default 0.1). Effective transmission = transmission_prob *
#'     (1 - receiver's immune_strength).}
#'   \item{`disease_duration`}{Integer. Ticks an agent remains infectious
#'     (default 10L).}
#'   \item{`immune_duration`}{Integer. Ticks of immunity after recovery
#'     (default 20L). After this, agent returns to Susceptible.}
#'   \item{`disease_energy_cost`}{Numeric. Energy deducted per tick while
#'     infected (default 5).}
#'   \item{`disease_death_prob`}{Numeric in [0, 1]. Per-tick probability of
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
#'   \item{`dispersal_evolution`}{Logical. Enable heritable dispersal tendency
#'     (default `FALSE`). Dispersal tendency scales the probability of moving
#'     to a random cell rather than a locally optimal cell.}
#'   \item{`dispersal_init_mean`}{Numeric. Initial mean dispersal tendency
#'     (default 0.1).}
#'   \item{`dispersal_mutation_sd`}{Numeric. Mutation SD (default 0.02).}
#'   \item{`dispersal_min`}{Numeric. Minimum dispersal tendency (default 0.0).}
#'   \item{`dispersal_max`}{Numeric. Maximum dispersal tendency (default 1.0).}
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
#' }
#'
#' ## Signal evolution and mate choice
#' \describe{
#'   \item{`signal_dims`}{Integer. Number of signal dimensions (default 0L = off).
#'     When > 0, each agent evolves a heritable signal vector and a preference
#'     vector; mates are chosen by proximity of signal to preference.}
#'   \item{`signal_cost`}{Numeric. Energy cost per unit of signal magnitude
#'     per tick (default 0.1). Models honest signalling costs (Zahavi 1975).
#'     Reference: Zahavi (1975) Mate selection — a selection for a handicap,
#'     *Journal of Theoretical Biology* 53(1):205--214.}
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
#'   \item{`shelter_build_prob`}{Numeric in [0, 1]. Probability of building a
#'     shelter unit per tick when eligible (default 0.1).}
#'   \item{`shelter_max_depth`}{Integer. Maximum shelter depth per cell
#'     (default 5L).}
#'   \item{`shelter_min_energy`}{Numeric. Minimum energy required to build
#'     (default 80).}
#'   \item{`shelter_decay_prob`}{Numeric in [0, 1]. Per-tick probability that
#'     each shelter unit decays (default 0.05).}
#' }
#'
#' ## Scavenging
#' \describe{
#'   \item{`scavenging`}{Logical. Enable carrion dynamics (default `FALSE`).
#'     Dead agents deposit body mass as carrion; scavengers consume it.}
#'   \item{`carrion_fraction`}{Numeric in [0, 1]. Fraction of energy_init
#'     deposited as carrion upon agent death (default 0.5). Uses energy_init
#'     not agent$energy at death, because body mass does not change with
#'     starvation.}
#'   \item{`carrion_decay_rate`}{Numeric in [0, 1]. Per-tick fraction of
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
    n_agents_init          = 50L,
    max_agents             = 500L,
    max_ticks              = 500L,

    # ── Energy and metabolism ──────────────────────────────────────────────
    energy_init            = 100.0,
    energy_max             = 200.0,
    move_cost              = 1.0,
    idle_cost              = 0.5,
    eat_gain               = 5.0,
    min_repro_energy       = 120.0,
    repro_cost             = 30.0,
    offspring_energy       = 60.0,
    starvation_threshold   = 0.0,

    # ── Grass ──────────────────────────────────────────────────────────────
    grass_init_prob        = 0.5,
    grass_rate             = 0.05,
    grass_max              = 5.0,

    # ── Brain architecture ─────────────────────────────────────────────────
    brain_type             = "bnn",
    hidden_layers          = c(8L),
    n_genes                = 20L,
    transformer_history    = 8L,
    transformer_heads      = 2L,
    synthesis_max_rules    = 10L,

    # ── Brain energy cost ──────────────────────────────────────────────────
    brain_energy_mode      = "activity",
    brain_energy_base      = 0.001,
    brain_energy_activity  = 0.5,

    # ── Genome and ploidy ──────────────────────────────────────────────────
    ploidy                 = 1L,
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

    # ── Epigenetics ────────────────────────────────────────────────────────
    epigenetics                    = FALSE,
    epigenetic_learning_coupling   = 0.10,
    epigenetic_inheritance         = 0.50,
    epigenetic_effect_size         = 0.20,
    methylation_rate               = 0.001,
    demethylation_rate             = 0.002,

    # ── Predators ──────────────────────────────────────────────────────────
    n_predators_init           = 0L,
    predator_energy_init       = 150.0,
    predator_attack_cost       = 2.0,
    predator_kill_gain         = 50.0,
    predator_mutation_sd       = 0.1,
    max_predators              = 20L,

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
    body_size_mutation_sd      = 0.05,
    body_size_min              = 0.1,
    body_size_max              = 5.0,

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
    dispersal_init_mean        = 0.1,
    dispersal_mutation_sd      = 0.02,
    dispersal_min              = 0.0,
    dispersal_max              = 1.0,

    # ── Parental care ──────────────────────────────────────────────────────
    parental_care              = FALSE,
    care_duration              = 5L,
    care_cost_per_offspring    = 2.0,
    max_clutch_size            = 1L,

    # ── Signal evolution ───────────────────────────────────────────────────
    signal_dims                = 0L,
    signal_cost                = 0.1,

    # ── Mimicry / toxicity ─────────────────────────────────────────────────
    mimicry                    = FALSE,

    # ── Niche construction ─────────────────────────────────────────────────
    niche_construction         = FALSE,
    shelter_build_prob         = 0.1,
    shelter_max_depth          = 5L,
    shelter_min_energy         = 80.0,
    shelter_decay_prob         = 0.05,

    # ── Scavenging ─────────────────────────────────────────────────────────
    scavenging                 = FALSE,
    carrion_fraction           = 0.5,
    carrion_decay_rate         = 0.1,
    carrion_eat_gain           = 3.0,

    # ── Group defense ──────────────────────────────────────────────────────
    group_defense              = FALSE,

    # ── Habitat preference (IFD) ───────────────────────────────────────────
    habitat_preference_evolution = FALSE,

    # ── Seasonal dynamics ──────────────────────────────────────────────────
    seasonal_amplitude         = 0.0,
    seasonal_period            = 100L,

    # ── Speciation ─────────────────────────────────────────────────────────
    speciation                 = FALSE,
    isolation_threshold        = 0.45,

    # ── Social learning ────────────────────────────────────────────────────
    social_learning            = FALSE,
    social_learning_freq       = 10L,
    social_learning_rate       = 0.1,

    # ── World evolution ────────────────────────────────────────────────────
    world_evolution            = FALSE,
    world_mutation_sd          = 0.02,
    world_params_to_evolve     = character(0L),

    # ── Logging ────────────────────────────────────────────────────────────
    log_freq                   = 1L,
    log_genomes                = FALSE,
    random_seed                = NA_integer_
  )
}
