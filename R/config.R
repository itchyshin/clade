#' Default simulation parameters for clade
#'
#' Returns a named list of all simulation parameters with type-annotated
#' defaults. Every parameter is documented below. Pass a modified copy to
#' [run_alife()] or [search_map_elites()].
#'
#' @details
#' ## Grid and population
#' \describe{
#'   \item{`grid_rows`}{Integer. Number of rows in the grid (default 30).}
#'   \item{`grid_cols`}{Integer. Number of columns in the grid (default 30).}
#'   \item{`toroidal`}{Logical. `TRUE` (default) wraps grid edges so that
#'     moving off one side re-enters on the opposite side (classic torus).
#'     `FALSE` clamps at boundaries, producing true edges — required for
#'     Huffaker-1958-style spatial-refugia dynamics and any scenario
#'     where corner/edge effects matter. Used by movement, sensing,
#'     dispersal, kin-scan, group-defense, and cooperative-breeding
#'     code paths via `wrap_or_clamp()`.}
#'   \item{`random_tick_order`}{Logical. `TRUE` (default, since 0.7.0)
#'     shuffles agent and predator iteration order each tick — random
#'     asynchronous scheduling per Grimm & Railsback (2005) and the
#'     IBM literature. **This restores the original behaviour from the
#'     MATLAB ancestor** (Bulitko 2023, `alife.m:324`:
#'     `env.agent = env.agent(randperm(length(env.agent)))`), which was
#'     lost in the alifeR R port and inherited as a regression by clade.
#'     `FALSE` restores the legacy fixed-array-order scheduling, which
#'     biased every clade simulation prior to 0.7.0 (earlier-array
#'     agents systematically had first access to foraging, mates, free
#'     cells, and prey). Only set FALSE to reproduce pre-0.7.0 results.
#'     See `dev/docs/consolidation-audit.md` for the full ancestor diff.}
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
#'   \item{`brain_type`}{Character. Currently implemented: `"bnn"`
#'     (default), `"ann"`, `"ctrnn"`, `"grn"`, `"random"`. Listed but
#'     **not yet implemented** (kernel errors with "planned for later
#'     phases"): `"transformer"`, `"synthesis"` — they're reserved
#'     names, not working architectures as of 0.5.6.
#'     BNN = Bayesian neural network (Neal 1996; Blundell et al. 2015);
#'     ANN = multilayer perceptron (Rumelhart et al. 1986);
#'     CTRNN = continuous-time recurrent network (Beer 1995);
#'     GRN = gene regulatory network (Kauffman 1993);
#'     random = null baseline. See [clade-package] documentation for
#'     a one-line summary of each architecture and
#'     `vignette("s-brain-comparison")` for a side-by-side benchmark
#'     of the five working types.}
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
#'   \item{`transformer_history`}{Integer. **Reserved placeholder** for a
#'     future transformer brain type — currently unused by any brain
#'     implementation; kernel rejects `brain_type = "transformer"` at
#'     runtime. The field's eventual semantics: number of past sensory
#'     inputs the transformer attends over (default 8L).}
#'   \item{`transformer_heads`}{Integer. **Reserved placeholder** —
#'     same status as `transformer_history`. Eventual semantics:
#'     number of attention heads (default 2L).}
#'   \item{`synthesis_max_rules`}{Integer. **Reserved placeholder**
#'     for a future symbolic-rule-synthesis brain — currently unused;
#'     kernel rejects `brain_type = "synthesis"` at runtime. Eventual
#'     semantics: maximum number of IF-THEN rules per agent (default 10L).}
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
#'   \item{`bnn_sigma_init`}{Numeric. Initial posterior SD for BNN weights
#'     when `bnn_sigma_source = "fixed"` or `"heterozygosity"` (default 0.5).}
#'   \item{`bnn_sigma_min`}{Numeric. Floor on per-weight BNN sigma (default
#'     0.01). Prevents the posterior collapsing to a point estimate under
#'     strong canalisation.}
#'   \item{`bnn_sigma_source`}{Character. How BNN posterior sigma is derived
#'     at each genome expression: `"heterozygosity"` (default; sigma =
#'     |mat - pat| / 2 = half parental-allele difference), `"fixed"` (always
#'     `bnn_sigma_init`), or `"trait"` (sigma = TRAIT_PLASTICITY). Added
#'     0.4.0 Tier 5A.}
#'   \item{`bnn_sample_freq`}{Integer. Ticks between BNN Thompson resample
#'     (default 1L). With `rl_mode = "actor_critic"`, setting this to 5
#'     lets REINFORCE gradients accumulate before the next resample.
#'     Added 0.4.0 Tier 5B.}
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
#'   \item{`brain_energy_sigma_scale`}{Numeric. Log-scaled information
#'     cost on BNN posterior width (sigma). When > 0, each tick costs
#'     `scale * mean(max(log(sigma / sigma_min), 0))` energy.
#'     Default 0 (no cost). Set 0.005--0.1 for Baldwin canalisation
#'     scenarios. Reference: Aiello & Wheeler (1995) expensive-tissue
#'     hypothesis. Added 0.4.1 Tier 5C.}
#'   \item{`bnn_action_noise_scale`}{Numeric in \[0, 1\]. Controls how
#'     much BNN sigma contributes to action noise during the forward
#'     pass: `w = mu + scale * sigma * z`. At 1.0 (default) = full
#'     coupling (legacy). At 0 = deterministic actions from mu;
#'     sigma only affects the learning/cost channel. Added 0.5.5 for
#'     sigma-action decoupling in Baldwin/plasticity scenarios.}
#'   \item{`action_exploration_epsilon`}{Numeric in \[0, 1\]. Epsilon-
#'     greedy exploration rate, orthogonal to BNN sigma. 0 (default) =
#'     pure argmax over action logits (legacy). > 0 = each tick, with
#'     probability epsilon the agent picks a uniformly random action
#'     instead of the greedy one. Intended for scenarios that set
#'     `bnn_action_noise_scale = 0`: BNN sigma then drives only
#'     learning/cost, and exploration comes from epsilon-greedy, so
#'     canalisation (sigma → 0) can happen without eliminating the
#'     foraging variability agents need to survive. Added 0.5.6.}
#'   \item{`bnn_sigma_lr_scale`}{Numeric in \[0, 1\]. When `> 0`, the
#'     BNN within-lifetime learning rate in `bnn_update!` is mixed
#'     between the constant-per-agent `lr` and
#'     `lr × mean(sigma) / bnn_sigma_lr_ref`, so canalised (low-sigma)
#'     agents learn slowly and plastic (high-sigma) agents learn
#'     fast. Complements `bnn_action_noise_scale`: that decouples
#'     sigma from action noise, this couples sigma to learning
#'     speed. Makes the cost of canalisation sit on learning rate
#'     rather than exploration. Default 0 preserves legacy
#'     behaviour. Added 0.5.6.}
#'   \item{`bnn_sigma_lr_ref`}{Numeric. Reference sigma for the
#'     `bnn_sigma_lr_scale` mapping. Defaults to 0.5, or the
#'     `plasticity_init_mean` value when unset explicitly. Added
#'     0.5.6.}
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
#'   \item{`phenotypic_plasticity`}{Logical. Enable heritable plasticity
#'     trait (default `FALSE`). Gates the DeWitt & Scheiner 2004 pathway.}
#'   \item{`plasticity_init_mean`}{Numeric. Starting mean of the plasticity
#'     trait (default 0.3).}
#'   \item{`plasticity_mutation_sd`}{Numeric. Per-offspring mutation SD on
#'     the plasticity trait (default 0.03).}
#'   \item{`plasticity_min`, `plasticity_max`}{Numeric clamps for the
#'     heritable plasticity trait (default 0 / 1).}
#'   \item{`plasticity_sense_radius`}{Integer. Sensory-radius bonus when
#'     plasticity is high (default 3L). Unused at plasticity = 0.}
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
#'   \item{`predator_attack_strength`}{Numeric. Energy damage dealt to prey
#'     per successful predator attack (default 40). Named `predator_attack_cost`
#'     in docs before 0.5.6.}
#'   \item{`predator_energy_gain`}{Numeric. Energy predator gains per successful
#'     kill (default 30). Named `predator_kill_gain` in docs before 0.5.6.}
#'   \item{`predator_mutation_sd`}{Numeric. Mutation SD for predator brain
#'     weights (default 0.1).}
#'   \item{`predator_max_agents`}{Integer. Hard cap on predator population
#'     (default 50L). Named `max_predators` in docs before 0.5.6.}
#'   \item{`predator_max_age`}{Integer. Predator-specific maximum age
#'     (default 100L — predators typically outlive prey: owl > mouse).
#'     Added 0.5.6.}
#'   \item{`predator_min_repro_energy`}{Numeric. Energy threshold for
#'     predator reproduction (default 200).}
#'   \item{`predator_min_repro_age`}{Integer. Minimum predator age before
#'     reproduction (default 5L).}
#'   \item{`predator_move_energy`}{Numeric. Energy deducted per predator
#'     move (default 1.0).}
#'   \item{`predator_live_energy`}{Numeric. Per-tick passive energy cost
#'     for each live predator (default 2.0).}
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
#'   \item{`senescence_shape`}{Numeric > 0. Curvature exponent on age in
#'     the 2-parameter Gompertz hazard
#'     \eqn{p = 1 - \exp(-r \cdot \exp(r \cdot \mathrm{age}^{\mathrm{shape}}))}{p = 1 - exp(-r * exp(r * age^shape))},
#'     with \eqn{r = \mathrm{senescence\_rate} \times \mathrm{aging\_rate}}{r = senescence_rate * aging_rate}.
#'     Default 1.0 = classic Gompertz (Gompertz 1825). Values > 1
#'     accelerate senescence late in life; values < 1 give a late-life
#'     mortality plateau (Vaupel et al. 1998). Only matters when
#'     `senescence_rate > 0`.}
#'   \item{`max_age_scales_with_metabolism`}{Logical. If `TRUE`, effective
#'     lifespan scales inversely with metabolic rate (pace-of-life
#'     syndrome, Réale et al. 2010). Default `FALSE`. Added 0.4.0 Tier 2.}
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
#'   \item{`juvenile_independence_age`}{Integer. Tick age at which an
#'     offspring leaves parental care (default 10L). Replaces the pre-0.4.0
#'     `care_duration` spec.}
#'   \item{`juvenile_independence_energy`}{Numeric. Energy level at which
#'     an offspring leaves parental care early (default 50.0).}
#'   \item{`feeding_rate`}{Numeric. Energy transferred per tick from
#'     carrying parent to offspring (default 5.0).}
#'   \item{`care_cost_per_tick`}{Numeric. Energy cost paid by the parent
#'     per tick of active care (default 1.0). Named `care_cost_per_offspring`
#'     in docs before 0.5.6.}
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
#'   \item{`parental_investment_evolution`}{Logical. Enable Trivers 1972
#'     quality-quantity trade-off (default `FALSE`). When `TRUE`, the
#'     female (focal agent) bears `female_investment` of the per-offspring
#'     cost and the male bears `1 - female_investment`; offspring birth
#'     energy also scales by `2 * female_investment`. See
#'     `inst/julia/src/reproduce.jl` for the implementation.}
#'   \item{`female_investment`}{Numeric in \[0, 1\]. Fraction of offspring
#'     energy cost paid by the mother (default 0.7; 0.5 = equal). Added
#'     0.4.0 Tier 3.}
#'   \item{`male_repro_cost`}{Numeric. Per-offspring energy cost paid by
#'     the father when `female_investment < 1` (default 0.3).}
#'   \item{`cooperative_breeding`}{Logical. Enable helper-at-the-nest
#'     dynamics (default `FALSE`).}
#'   \item{`helper_tendency_init_mean`}{Numeric in \[0, 1\]. Heritable
#'     willingness to help (default 0.1).}
#'   \item{`helper_tendency_mutation_sd`}{Numeric. Mutation SD on the
#'     helper trait (default 0.02).}
#'   \item{`helper_transfer`}{Numeric. Energy transferred per helping event
#'     (default 5.0).}
#'   \item{`helper_kin_threshold`}{Numeric. Minimum relatedness for a
#'     helping attempt (default 0.25 = full-siblings).}
#'   \item{`helper_min_energy`}{Numeric. Minimum helper energy before a
#'     transfer is refused (default 80.0).}
#' }
#'
#' ## Clutch size evolution
#'
#' Lack (1947) r/K clutch-size evolution.
#'
#' \describe{
#'   \item{`clutch_size_evolution`}{Logical. Enable heritable clutch size
#'     (default `FALSE`).}
#'   \item{`clutch_size_init_mean`}{Numeric. Initial mean clutch size
#'     (default 1.0).}
#'   \item{`clutch_size_min`, `clutch_size_max`}{Integer clamps (default
#'     1L / 5L).}
#'   \item{`clutch_size_mutation_sd`}{Numeric. Mutation SD (default 0.3).}
#' }
#'
#' ## Stress hypermutation
#'
#' Rosenberg (2001), Foster (2007): under low energy ("stress"), mutation
#' rate rises transiently. Controlled by three specs:
#'
#' \describe{
#'   \item{`stress_hypermutation`}{Logical. Enable stress-induced
#'     hypermutation (default `FALSE`).}
#'   \item{`stress_threshold`}{Numeric. Energy below which an agent is
#'     considered "stressed" (default 20.0). **Note**: stress hypermutation
#'     fires at reproduction time, not per-tick. Reproduction requires
#'     `energy >= min_repro_energy` (default 120), so `stress_threshold`
#'     must be GREATER than `min_repro_energy` for hypermutation to
#'     ever trigger. With defaults (threshold = 20, min_repro = 120),
#'     the module is structurally silent — set `stress_threshold > 120`
#'     for stress-mutation to actually fire at reproduction events.}
#'   \item{`stress_mutation_multiplier`}{Numeric. Multiplier applied
#'     to `mutation_sd` at reproduction when the parent's energy is
#'     below `stress_threshold` (default 3.0).}
#' }
#'
#' ## Signal evolution and mate choice
#' \describe{
#'   \item{`signal_dims`}{Integer. Number of signal dimensions (default 0L = off).
#'     When > 0, each agent evolves a heritable signal vector and a preference
#'     vector; mates are chosen by proximity of signal to preference.}
#'   \item{`signal_cost`}{Numeric. Energy cost per unit of signal magnitude
#'     per tick (default 0.1). Indirect handicap cost — high-signal agents
#'     lose energy and starve faster. Often masked by drift at realistic
#'     parameters; see also `signal_cost_mortality` for direct viability
#'     cost. Reference: Zahavi (1975) Mate selection -- a selection for a
#'     handicap, *Journal of Theoretical Biology* 53(1):205--214.}
#'   \item{`signal_cost_mortality`}{Numeric in \[0, 1\]. Direct per-tick
#'     mortality probability scaling with signal magnitude (default 0.0 =
#'     off). Implements the Zahavi handicap as the Fuller, Houle & Travis
#'     (2005) β_Sv viability-selection gradient — the right cost mechanism
#'     for distinguishing Fisher runaway from sensory bias from Zahavi
#'     handicap. Distinct from `signal_cost` (which only drains energy).
#'     References: Grafen (1990) Biological signals as handicaps, *JTB*
#'     144:517--546. Fuller, Houle & Travis (2005) Sensory bias as an
#'     explanation for the evolution of mate preferences, *Am Nat*
#'     166:437--446. Added 0.6.3.}
#'   \item{`preference_bias_target`}{Numeric vector of length
#'     `signal_dims`, or `NULL` (default). A fixed target vector that
#'     agent preferences are pulled toward each tick. Installs a
#'     *pre-existing* sensory bias — the Ryan (1990) sensory-
#'     exploitation mechanism and the β_N leg of Fuller, Houle &
#'     Travis (2005). Signals under preference-based mate choice
#'     should evolve to match this target over generations. Active
#'     only when `preference_bias_strength > 0` and `signal_dims > 0`.
#'     Added 0.6.5.}
#'   \item{`preference_bias_strength`}{Numeric in \[0, 1\]. Per-tick
#'     pull strength κ on the preference vector toward
#'     `preference_bias_target` (default 0.0 = off, opt-in). The
#'     update is `preference[i] ← (1 - κ) × preference[i] +
#'     κ × target[i]`, clamped to \[-1, 1\]. κ = 0.01 is a weak bias;
#'     0.1 is strong. References: Ryan (1990) *Oxford Surveys in
#'     Evolutionary Biology* 7:157--195; Endler & Basolo (1998)
#'     *TREE* 13:415--420. Added 0.6.5.}
#'   \item{`signal_toxicity_coupling`}{Numeric in \[0, 1\]. Strength of
#'     aposematic pleiotropy between the first signal dimension and the
#'     heritable `toxicity` trait. At 0 (default) signal and toxicity
#'     evolve independently; at 1, `signal[1]` is locked to each agent's
#'     toxicity value so predators can learn a reliable honest
#'     aposematic signal. Required to close the Bates (1862) /
#'     Müller (1879) feedback loop in clade. Active only when
#'     `mimicry = TRUE` and `signal_dims > 0`. Added 0.4.4.}
#'   \item{`signal_drift_sd`}{Numeric. Neutral drift SD applied per-tick to
#'     an agent's signal vector (default 0.01). At 0 the signal is fixed at
#'     birth; > 0 lets signals drift within-lifetime.}
#'   \item{`signal_evolution_drift`}{Logical. If `TRUE` (default), apply
#'     inter-generational drift to the inherited signal at the SD given
#'     by `signal_drift_sd`. Set `FALSE` to disable signal drift entirely.
#'     Separate from the sensory mutation rate.}
#'   \item{`signal_memory_rate`}{Numeric. Rate at which predator memory
#'     updates toward observed prey signals (default 0.3). Relevant only
#'     when `mimicry = TRUE` and predators are present.}
#'   \item{`mate_choice_mode`}{Character. Mate-choice rule:
#'     `"preference"` (default, score on -||preference - candidate
#'     signal||^2 and sample softmax), `"random"` (uniform random
#'     among eligible neighbours), or `"highest_signal"` (score on
#'     signal magnitude). Wired in 0.6.4; before then this field was
#'     a latent stub and `signal_dims > 0` always produced hard argmax
#'     on preference-distance regardless of mode. See `NEWS.md` 0.6.4
#'     for migration notes.}
#'   \item{`mate_choice_strength`}{Numeric in \[0, 1\]. Softmax
#'     temperature parameter (default 1.0, greedy argmax). At 1, choice
#'     is a hard argmax on the mode-specific score (preserves pre-0.6.4
#'     observed behaviour); at 0, uniform random regardless of mode;
#'     intermediate values sample softmax with temperature
#'     `1 / mate_choice_strength`. Ignored when
#'     `mate_choice_mode = "random"`.}
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
#'   \item{`batesian_mimicry`}{Logical. Enable Batesian mimicry branch
#'     (default `FALSE`): palatable prey (`toxicity = 0`) can exploit the
#'     predator's learned aversion to toxic signals. Predator-betrayal
#'     decay prevents runaway cheating. Active only when `mimicry = TRUE`.}
#'   \item{`toxicity_init_mean`}{Numeric. Starting toxicity (default 0).}
#'   \item{`toxicity_mutation_sd`}{Numeric. Mutation SD on the toxicity
#'     trait (default 0.05).}
#'   \item{`toxicity_cost_per_tick`}{Numeric. Per-tick energy cost paid by
#'     agents with `toxicity > 0` (default 2.0; Zahavi handicap).}
#'   \item{`toxin_dose`}{Numeric. Damage dealt to the attacker per unit
#'     of prey toxicity (default 30.0).}
#'   \item{`avoid_threshold`}{Numeric. Predator-memory value above which
#'     the predator chooses to avoid the prey (default 0.5).}
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
#'   \item{`shelter_occupancy_bonus`}{Numeric. Energy bonus per tick per
#'     unit shelter depth for agents occupying a sheltered cell (default
#'     0, meaning shelters don't feed their occupants). Heritable
#'     niche-construction amplifier in the Odling-Smee et al. 2003 sense.
#'     Added 0.3.0.}
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
#'   \item{`carrion_transmission_prob`}{Numeric in \[0, 1\]. Probability
#'     that a scavenger feeding on infected carrion contracts the disease
#'     (default 0; active only when `disease = TRUE` and `scavenging =
#'     TRUE`). Cross-module fomite-transmission pathway.}
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
#'   \item{`group_defense_radius`}{Integer. Moore radius for counting
#'     neighbours when computing per-prey dilution (default 2L = 5×5
#'     neighbourhood).}
#'   \item{`group_defense_strength`}{Numeric in \[0, 1\]. Maximum fraction
#'     of predator attack success reduced under maximum grouping
#'     (default 0.3). 2026-04-17 audit found the population-level effect
#'     inverts Hamilton 1971 at all tested values — see
#'     `dev/audit/fidelity/group_defense_strength_sweep.R`.}
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
#'   \item{`habitat_preference_init_mean`}{Numeric in \[-1, 1\]. Initial mean
#'     preference (default 0 — no preference). Negative values = prefer
#'     low-grass cells; positive = prefer high-grass.}
#'   \item{`habitat_preference_mutation_sd`}{Numeric. Mutation SD on the
#'     preference trait (default 0.03).}
#'   \item{`habitat_preference_min`, `habitat_preference_max`}{Numeric
#'     clamps (default -1 / 1).}
#'   \item{`habitat_preference_strength`}{Numeric in \[0, ∞). Scales the
#'     probability that an agent attempts a preference-directed move per
#'     tick (default 0.5). The 2026-04-17 audit found that the default is
#'     below the drift floor; `strength = 2.0` is required for a detectable
#'     Fretwell-Lucas signal at 5 seeds.}
#'   \item{`habitat_move_cost`}{Numeric. Energy cost of a preference-directed
#'     move (default 0, meaning the move is free).}
#' }
#'
#' ## Seasonal dynamics
#' \describe{
#'   \item{`seasonal_amplitude`}{Numeric. Amplitude of sinusoidal grass_rate
#'     modulation (default 0 = off). grass_rate_t = grass_rate *
#'     (1 + seasonal_amplitude * sin(2 * pi * t / season_length)).}
#'   \item{`season_length`}{Integer. Period of seasonal cycle in ticks
#'     (default 100L). Named `seasonal_period` in docs before 0.5.6.}
#'   \item{`winter_death_prob`}{Numeric in \[0, 1\]. Per-tick death probability
#'     during the low phase of the seasonal cycle (default 0). Only
#'     engages when `seasonal_amplitude > 0`.}
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
#'     successful mating (default 0.5). Species are inferred by hierarchical
#'     clustering of genome distances at each logging tick.}
#'   \item{`speciation_cluster_interval`}{Integer. Ticks between species-
#'     count recomputations (default 10L). Reducing this improves temporal
#'     resolution of the `n_species` log at a CPU cost.}
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
#'     canopy access (default 0.15).}
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
    random_tick_order      = TRUE,      # 0.7.0: random asynchronous scheduling per Grimm & Railsback 2005. FALSE = legacy fixed array order.
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
    bnn_action_noise_scale = 1.0,            # 0.5.5: sigma-action decoupling.
                                             # 1.0 = legacy (w = mu + sigma*z).
                                             # 0.0 = deterministic actions from
                                             # mu; sigma only affects the
                                             # learning/cost channel. Required
                                             # for clean Baldwin/plasticity
                                             # canalisation scenarios.
    action_exploration_epsilon = 0.0,        # 0.5.6: epsilon-greedy exploration
                                             # orthogonal to BNN sigma. 0 =
                                             # pure argmax (legacy). > 0 = each
                                             # tick, with prob epsilon pick a
                                             # uniformly random action instead
                                             # of the greedy one. Intended to
                                             # restore foraging variability
                                             # when bnn_action_noise_scale = 0
                                             # kills the BNN-driven
                                             # exploration channel.
    bnn_sigma_lr_scale  = 0.0,               # 0.5.6: Baldwin deeper lift. When
                                             # > 0, BNN effective learning rate
                                             # is scaled by mean(sigma)/sigma_ref
                                             # — canalised (low-sigma) agents
                                             # learn slowly, plastic (high-sigma)
                                             # agents learn fast. At 1.0, fully
                                             # proportional; 0 legacy. Makes the
                                             # cost of canalisation sit on
                                             # learning speed instead of action
                                             # noise.
    bnn_sigma_lr_ref    = 0.5,               # 0.5.6: reference sigma for
                                             # bnn_sigma_lr_scale scaling. When
                                             # unset, reads plasticity_init_mean.

    # ── Genome and ploidy ──────────────────────────────────────────────────
    ploidy                 = 2L,
    n_chromosomes          = 1L,
    crossover_rate         = 1.0,
    dominance_model        = "additive",
    self_fertilization_fallback = FALSE,   # 0.5.9: when TRUE + ploidy = 2 +
                                           # no mate found, draw paternal
                                           # haplotype from parent1 (self-
                                           # fertilization) instead of making
                                           # the offspring effectively haploid.
                                           # Required for evolved-heterozygosity
                                           # audits (s-plasticity, s-baldwin).
    mate_search_radius     = 1L,           # 0.5.10: radius of Moore search for
                                           # a mate (1 = 3x3, 2 = 5x5, 3 = 7x7).
                                           # Increasing this reduces Allee-
                                           # failure rate on sparse grids so
                                           # diploid sexual reproduction
                                           # operates reliably without the
                                           # selfing fallback kicking in.

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

    # ── Wolf et al. 2007 Nature personality syndrome (added 0.7.0) ────────
    # Spatially-explicit clade interpretation: hawk-dove pairs from Moore
    # neighborhood (mate_search_radius style); anti-predator fires only when
    # a real predator is within sensing range of the focal agent. The
    # life-history trade-off (g(x) = (1-x)^β) is preserved from Wolf 2007.
    # See inst/julia/src/modules/personality.jl for the mechanism and
    # vignettes/paper-wolf2007.Rmd for the reproduction context.
    personality_syndrome           = FALSE,
    # Trait initial means + mutation SDs
    exploration_init_mean          = 0.5,
    exploration_mutation_sd        = 0.05,
    boldness_init_mean             = 0.5,
    boldness_mutation_sd           = 0.05,
    aggressiveness_init_mean       = 0.5,
    aggressiveness_mutation_sd     = 0.05,
    # Wolf 2007 life-history trade-off curve g(x) = (1-x)^β
    personality_beta               = 1.25,
    # Wolf 2007 per-resource competition denominator: F_i = f_i / (1 + α·N).
    # In Wolf 2007, α·N regulates per-individual fecundity by total population
    # density at the resource. clade uses total live-agent count as N (Wolf's
    # f_i / (1+α·N_i) reduces to this when the population is well-mixed).
    # Set to 0.0 to disable the denominator (legacy 0.7.0 behaviour at first
    # release of the personality module). Wolf's original value is 0.005.
    personality_alpha              = 0.005,
    # Year-1/year-2 reproduction event ages (in clade ticks). Wolf doesn't
    # specify because his model is fecundity-based; clade needs concrete tick
    # counts. Defaults assume one tick ≈ a day for a small mammal.
    wolf_year1_repro_age           = 50L,
    wolf_year2_repro_age           = 100L,
    # Year-2 fecundity payoffs. Tuned so 2*f_low > f_high > 1 (Wolf's
    # dimorphism condition). Empirical calibration recommended for any
    # specific scenario; see vignette discussion.
    personality_f_high             = 3.0,
    personality_f_low              = 2.0,
    # Anti-predator game (per encounter): bold gets b energy, dies prob γ.
    # Scaled to be small relative to f_low (Wolf's V/f_high ≈ 3%); a single
    # game adds ≈ 0.25 expected offspring at year-2 reproduction.
    personality_b                  = 0.5,
    personality_gamma              = 0.1,
    # Hawk-dove game (per encounter): hawks fight for V, hawk-hawk loser
    # dies prob δ. Same scale rationale as personality_b.
    personality_V                  = 0.5,
    personality_delta              = 0.5,
    # Per-tick game frequencies during the between-phase (year1 < age < year2).
    # Wolf's "one or more games" → probabilistic per-tick firing.
    personality_hawkdove_per_tick  = 0.1,
    personality_antipred_per_tick  = 0.5,
    # Hawk-dove pairing radius (Moore neighborhood). Setting > 0 is the
    # spatially-explicit clade interpretation (vs Wolf's mean-field random
    # pairing). Default 1 = immediate neighbours.
    personality_hawkdove_radius    = 1L,

    # ── Trivers 1971 reciprocal altruism (added 0.7.0) ────────────────────
    # Spatially-explicit clade interpretation: encounters happen between
    # agents in the same Moore neighborhood (one-per-cell rule means no
    # co-occupancy, so the trigger is adjacency). Each agent carries a
    # ring-buffer partner memory; conditional cooperation strategies (TFT,
    # generous TFT) emerge under low dispersal + high partner re-encounter.
    # See inst/julia/src/modules/reciprocity.jl and paper-trivers1971.Rmd.
    reciprocal_altruism            = FALSE,
    # Trait initial means and mutation SDs. Wolf-style narrow normal init
    # (mean 0.5, sd 0.05) lets selection move them. Forgiveness defaults
    # to a low init mean (0.1) — pure TFT is the canonical "winning"
    # strategy in Axelrod tournaments.
    reciprocity_initial_init_mean        = 0.5,
    reciprocity_initial_mutation_sd      = 0.05,
    reciprocity_retaliation_init_mean    = 0.5,
    reciprocity_retaliation_mutation_sd  = 0.05,
    reciprocity_forgiveness_init_mean    = 0.1,
    reciprocity_forgiveness_mutation_sd  = 0.05,
    # Cooperation cost + benefit-to-cost ratio. Hamilton's rule: b > c
    # for kin selection; for reciprocal altruism, b > c is also required
    # but the gain comes from reciprocation rather than relatedness.
    reciprocity_cost                = 0.5,
    reciprocity_benefit_ratio       = 2.0,
    # Per-tick interaction probability. Two adjacent agents play one game
    # with this probability per tick (avoids degenerate every-tick games
    # between stationary neighbours). Default 0.1 ≈ one game per 10 ticks
    # of contact.
    reciprocity_interaction_rate    = 0.1,
    # Partner memory ring-buffer size. Default 8 = remember last 8
    # distinct partners. Larger = more stable conditional cooperation;
    # smaller = more "forgetful" (Axelrod's TFT in iterated PD assumes
    # perfect memory of one partner).
    partner_memory_size             = 8L,
    # Encounter neighborhood radius. Default 1 = immediate Moore
    # neighbours. Larger radius = more potential partners but less
    # likely to re-encounter the same partner (weakens reciprocity).
    reciprocity_radius              = 1L,

    # ── Wolf et al. 2008 PNAS responsive personalities (added 0.7.0) ──────
    # Spatially-explicit clade interpretation: responsive agents pay
    # `responsiveness_cost` energy per tick to sample local grass and
    # override their action toward the richest cardinal neighbour.
    # Frequency-dependent benefit emerges from grass competition (handling
    # time): when many agents are responsive, rich cells get depleted
    # and per-agent payoff to being responsive declines.
    # See inst/julia/src/modules/responsiveness.jl and paper-wolf2008.Rmd.
    responsive_personalities       = FALSE,
    responsiveness_init_mean       = 0.5,
    responsiveness_mutation_sd     = 0.05,
    # Per-tick energy cost paid by an agent that opts to sample. Wolf 2008
    # uses C=0.2 in his Methods; clade scale chosen so a moderate-
    # responsive agent (resp=0.5) loses ~0.2 energy per tick on average.
    responsiveness_cost            = 0.4,

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
    seasonal_spatial_bias       = 0.0,   # 0.5.18: when > 0, flips the
                                         # spatial grass distribution between
                                         # seasons. Summer (season > 0)
                                         # concentrates grass in the top
                                         # (north) half of the grid; winter
                                         # concentrates it in the bottom
                                         # (south) half. Creates fluctuating
                                         # selection (optimal foraging
                                         # direction flips with season), the
                                         # regime DeWitt & Scheiner 2004 /
                                         # Hinton & Nowlan 1987 require for
                                         # plasticity to be favoured.
                                         # Typical test values: 0.5–0.9.

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
    # 0.6.3: direct viability cost on signals, implementing the
    # Zahavi (1975) / Grafen (1990) handicap principle as the Fuller,
    # Houle & Travis (2005) β_Sv selection gradient. At each tick:
    #   p_die ← signal_cost_mortality × Σ |signal_i|
    # At 0.0 (default) only the energy drain of `signal_cost` operates
    # (backward-compatible). At > 0, agents carrying larger signals
    # face a direct per-tick mortality probability — the mechanism
    # required to differentiate Fisher runaway from sensory bias from
    # Zahavi handicap in the Fuller 2005 framework.
    signal_cost_mortality      = 0.0,
    # 0.6.5: sensory bias sensu Ryan 1990 — preference is pulled
    # toward a fixed target each tick, installing a pre-existing
    # bias that signals later evolve to exploit. The β_N leg of
    # Fuller 2005. Opt-in: default target is NULL and strength 0.
    # To activate, set both preference_bias_target (numeric of
    # length signal_dims) and preference_bias_strength > 0.
    preference_bias_target     = NULL,
    preference_bias_strength   = 0.0,
    signal_evolution_drift     = TRUE,
    signal_drift_sd            = 0.01,
    # 0.6.4: mate_choice_mode and mate_choice_strength are now wired
    # in reproduce.jl (were silently ignored before). The defaults
    # ("preference", 1.0) exactly preserve pre-0.6.4 observed behaviour
    # for every caller that had signal_dims > 0 — the kernel always
    # argmax'd on preference-distance regardless of mode. Callers that
    # explicitly set mate_choice_mode = "random" or a strength < 1
    # now get the semantics they asked for (see NEWS 0.6.4).
    mate_choice_mode           = "preference",
    mate_choice_strength       = 1.0,
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
    predator_max_age           = NA,   # 0.5.6: separate predator lifespan.
                                       # NA = same as prey max_age (legacy).
                                       # Set explicitly for realistic scenarios
                                       # where predators outlive prey (e.g.
                                       # owl > mouse: predator_max_age = 150,
                                       # max_age = 30).
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

    # ── Parental investment evolution (Trivers 1972) ──────────────────────
    parental_investment_evolution = FALSE,
    female_investment          = 0.7,
    male_repro_cost            = 0.3,

    # ── Stress hypermutation ───────────────────────────────────────────────
    stress_hypermutation       = FALSE,
    stress_mutation_multiplier = 3.0,
    stress_threshold           = 20.0,

    # ── Senescence shape (Gompertz hazard curvature exponent) ─────────────
    # Default 1.0 = classic Gompertz; only consulted when senescence_rate > 0.
    senescence_shape           = 1.0,

    # ── Reproduction ──────────────────────────────────────────────────────
    min_repro_age              = 0L,

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

#' Fast-generation specs for evolutionary scenarios
#'
#' Returns [default_specs()] calibrated for **fast generational
#' turnover** — 66 generations in 2000 ticks (vs ~2.6 at defaults).
#' Use this preset whenever the scenario tests a prediction about
#' **trait evolution across generations** (plasticity, Baldwin effect,
#' mimicry, mating systems, dispersal evolution, etc.).
#'
#' The timescale calibration is based on the MATLAB ancestor's
#' parameters (Bulitko 2023), which ran ~40x faster generations than
#' clade's defaults because agents started at reproduction energy with
#' short `minReproductionAge`. See `dev/docs/timescale-analysis.md` for
#' the full analysis.
#'
#' @details
#' Key changes from `default_specs()`:
#' \describe{
#'   \item{`max_age`}{30L (vs 200L). Short lifespan forces generational
#'     turnover at a biologically realistic rate for a small organism
#'     (e.g., Drosophila, small rodent).}
#'   \item{`min_repro_energy`}{60 (vs 120). Lower threshold means agents
#'     breed after ~10 ticks of foraging, not ~100.}
#'   \item{`min_repro_age`}{3L (vs 0L). Minimum maturation age prevents
#'     newborn-immediately-reproducing artefacts.}
#'   \item{`grass_rate`}{0.20 (vs 0.05). Adequate food to sustain a
#'     viable population of ~65 agents with fast turnover.}
#'   \item{`max_ticks`}{2000L. At gen time ~30 ticks, this gives ~66
#'     generations — adequate for most evolutionary predictions.}
#'   \item{`n_agents_init`}{80L. Moderate starting population.}
#'   \item{`max_agents`}{400L. Room for population growth.}
#'   \item{`grid_rows`, `grid_cols`}{30L. Standard grid.}
#'   \item{`predator_max_age`}{100L (vs `NA`-means-same-as-prey at
#'     defaults). Predators outlive 30-tick prey by ~3×, matching
#'     the owl > mouse lifespan ratio.}
#' }
#'
#' @return A specs list calibrated for fast evolutionary dynamics.
#' @seealso [default_specs()], [slow_specs()], [quick_specs()]
#' @export
fast_specs <- function() {
  s <- default_specs()
  s$max_age          <- 30L       # short prey life → fast generations
  s$min_repro_energy <- 60.0      # breed after ~10 ticks of foraging
  s$min_repro_age    <- 3L        # minimum maturation
  s$grass_rate       <- 0.20      # adequate food for fast turnover
  s$n_agents_init    <- 80L       # moderate pop; higher density = stronger selection
  s$max_agents       <- 400L      # room for growth
  s$grid_rows        <- 30L       # standard grid (density matters more than size)
  s$grid_cols        <- 30L
  s$max_ticks        <- 2000L     # 66 generations
  s$predator_max_age <- 100L      # predators outlive prey (owl > mouse)
  s
}

#' Realistic-scale specs for ecologically meaningful audits
#'
#' Returns [fast_specs()] scaled up to a larger grid and an explicit
#' predator age structure. Designed for re-auditing scenarios where
#' the default 30×30 grid is too small to let genuine spatial
#' dynamics (dispersal gradients, predator–prey waves, metapopulation
#' structure) express themselves.
#'
#' Built on top of [fast_specs()] because 2000-tick / 66-generation
#' runs are the longest the BNN kernel stays stable without trait
#' drift degrading the population.  A 5000-tick scale-up was tested
#' but produced a systematic population decline after t ≈ 1500 across
#' seeds.
#'
#' @details
#' All [fast_specs()] settings are preserved (`max_age = 30`,
#' `min_repro_energy = 60`, `min_repro_age = 3`, `grass_rate = 0.20`).
#' Additional changes:
#' \describe{
#'   \item{`grid_rows`, `grid_cols`}{60L × 60L (4× the default
#'     area). Enough room for metapopulation structure, dispersal
#'     gradients, and predator–prey waves.}
#'   \item{`n_agents_init`}{150L. Right-sized to the post-boom
#'     equilibrium on the 60×60 grid; all 5 tested seeds report
#'     `viability_report() = viable`.}
#'   \item{`max_agents`}{1500L. Supports the transient population
#'     peak (~280) before the equilibrium sets in.}
#'   \item{`max_ticks`}{2000L. 66 generations at `max_age = 30`.}
#'   \item{`predator_max_agents`}{150L. 3× default; room for a
#'     predator guild on the larger map.}
#'   \item{`predator_max_age`}{60L. Predators outlive prey by 2×
#'     (owl > mouse) — biologically realistic age structure when
#'     predation is engaged.}
#' }
#'
#' Typical wall time: 30–60 seconds per run depending on modules; 8
#' seeds in parallel on 16–32 PSOCK workers easily fit under the
#' 200-core / 300-GB machine budget.
#'
#' @return A specs list calibrated for larger-grid, predator-aware
#'   audit runs.
#' @seealso [default_specs()], [fast_specs()], [slow_specs()]
#' @export
realistic_specs <- function() {
  s <- fast_specs()
  s$grid_rows           <- 60L     # 4x the default area
  s$grid_cols           <- 60L
  s$n_agents_init       <- 150L    # right-sized to post-boom equilibrium
  s$max_agents          <- 1500L
  s$max_ticks           <- 2000L   # 66 generations at max_age=30
  s$predator_max_agents <- 150L
  s$predator_max_age    <- 60L     # predator outlives prey 2x (owl > mouse)
  s
}

#' Ultra-realistic specs for finite-size-sensitive audits
#'
#' Returns [realistic_specs()] scaled up further for scenarios whose
#' theoretical signal is dominated by finite-population corrections
#' — notably the Red Queen (Otto & Michalakis 1998: advantage scales
#' as ~μN) and Hamilton 1971 selfish herd (risk dilution scales as
#' ~1/√N). At `realistic_specs()` equilibrium N ≈ 120, these signals
#' are 5–10× below analytical limits.
#'
#' @details
#' Preserves all [realistic_specs()] settings except:
#' \describe{
#'   \item{`grid_rows`, `grid_cols`}{120L × 120L (16× the default
#'     area, 4× realistic).}
#'   \item{`n_agents_init`}{500L. Right-sized to the ~400 equilibrium
#'     on the 120×120 grid (an earlier audit at 800L overshot and
#'     occasionally hit `max_agents`).}
#'   \item{`max_agents`}{5000L. Supports the larger carrying
#'     capacity.}
#'   \item{`max_ticks`}{2500L. ~80 generations at `max_age = 30`.
#'     Longer runs destabilise the BNN kernel.}
#'   \item{`predator_max_agents`}{400L.}
#' }
#'
#' Typical wall time: 3–6 minutes per run (15M agent-ticks); 8 seeds
#' in parallel on 16 PSOCK workers finish in one coffee break. Fits
#' comfortably under the 200-core / 300-GB machine budget.
#'
#' @return A specs list at ecological-theory scale (N ≈ 400
#'   equilibrium, ~80 generations).
#' @seealso [realistic_specs()], [fast_specs()]
#' @export
ultra_realistic_specs <- function() {
  s <- realistic_specs()
  s$grid_rows           <- 120L
  s$grid_cols           <- 120L
  s$n_agents_init       <- 500L    # right-sized to ~400 equilibrium
  s$max_agents          <- 5000L
  s$max_ticks           <- 2500L
  s$predator_max_agents <- 400L
  s
}

#' Slow-generation specs for long-lived organism scenarios
#'
#' Returns [default_specs()] calibrated for **long-lived organisms**
#' (elephant, whale, large primate). Generation time ~50 ticks;
#' requires longer runs (10000+ ticks) for meaningful evolution.
#'
#' @details
#' \describe{
#'   \item{`max_age`}{200L (same as default). Long lifespan.}
#'   \item{`min_repro_energy`}{150 (vs 120). High parental investment.}
#'   \item{`min_repro_age`}{20L. Late maturation.}
#'   \item{`max_ticks`}{10000L. At gen time ~200, gives ~50 generations.}
#'   \item{`grass_rate`}{0.10 (vs 0.05). Slightly richer environment
#'     compensates for the higher `min_repro_energy` threshold.}
#'   \item{`n_agents_init`}{100L (vs 50L). Moderate starting
#'     population for the long horizon.}
#'   \item{`max_agents`}{500L (same as default). Standard cap.}
#' }
#'
#' @return A specs list calibrated for K-strategist organisms.
#' @seealso [default_specs()], [fast_specs()]
#' @export
slow_specs <- function() {
  s <- default_specs()
  s$max_age          <- 200L
  s$min_repro_energy <- 150.0
  s$min_repro_age    <- 20L
  s$grass_rate       <- 0.10
  s$n_agents_init    <- 100L
  s$max_agents       <- 500L
  s$max_ticks        <- 10000L
  s
}
