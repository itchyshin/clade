# clade 0.1.1 (development)

## Bug fixes

- `plasticity_init_mean` default changed from 0.0 to 0.3. The previous default
  sat at the trait floor; mutation pressure could not push it upward, so
  `mean_plasticity` was always 0 in practice.
- `wing_size_init_mean` default changed from 0.0 to 0.08; `canopy_threshold`
  changed from 0.6 to 0.15. The previous gap between init and threshold was
  unreachable by mutation in any realistic run, so `n_canopy_agents` was always
  0.
- `signal_evolution_drift` default changed from `FALSE` to `TRUE`. Without
  drift, signals remained exactly 0 forever, making mate-choice experiments
  uninformative.

## New features

- **Lamarckian evolution** (`lamarckian = TRUE`): when `rl_mode` is not
  `"none"`, the within-lifetime RL-updated brain weights are written back to
  the parent's genome before meiosis so offspring inherit the learned solution
  directly. Implemented in `inst/julia/src/modules/lamarckian.jl`. Distinct
  from the epigenetics module (which inherits methylation marks, not weight
  values) and from the Baldwin Effect (which leaves the genome unchanged).
  References: Baldwin (1896); Weismann (1892); Jablonka & Lamb (2005).

- **Discrete / quantized ANN weights** (`ann_weight_values`): when set to a
  numeric vector (e.g. `c(-1, 0, 1)` for ternary weights), every synaptic
  weight and bias is snapped to the nearest allowed value after genome
  expression. Applies to `"ann"` and `"bnn"` brain types. Biologically
  motivated by evidence that biological synapses operate in discrete strength
  states (Bhumbra & Bhatt 2020). Enables symbolic formula distillation from
  evolved ANNs (as in the original MATLAB `alife2025usra` codebase).

- **ANN weight regularisation** (`ann_regularization`): per-tick energy
  penalty for brain weight complexity. Two modes: `"weight_magnitude"` (L1
  penalty, drives weights toward zero) and `"weight_count"` (L0-like penalty,
  fixed cost per active synapse). Scaled by `ann_regularization_lambda`
  (default 0.001). The mean weight magnitude is now logged in every run as
  `mean_ann_weight_magnitude`. References: Laughlin et al. (1998);
  Attwell & Laughlin (2001).

- **Native Julia test directory** (`inst/julia/test/`): unit tests for
  quantization, regularisation, and Lamarckian logic that can be run directly
  in Julia without the R side. Run with
  `julia --project=inst/julia inst/julia/test/runtests.jl`.

- **Module triage script** (`inst/scripts/triage_modules.R`): runs each
  module in isolation for 300 ticks and reports whether a key biological signal
  is detected (`[OK]`), absent (`[FLAT]`), or crashing (`[ERR]`). Run with
  `Rscript inst/scripts/triage_modules.R`.

- **`expect_evolution()` test helper** (in `tests/testthat/helper.R`): asserts
  that a logged trait moves directionally over a simulation run. Also
  consolidates the duplicated `skip_no_julia()` definition into `helper.R` so
  individual test files no longer need to re-define it.

- **Non-toroidal grid** (`toroidal = FALSE`): all Julia modules now use a
  `wrap_or_clamp()` helper that either wraps (toroidal) or clamps to the grid
  boundary (linear). Required for spatial sorting and invasion-front experiments
  with a defined front.
- **Carrion as pathogen reservoir** (`carrion_transmission_prob`): when
  `scavenging = TRUE` and `disease = TRUE`, agents that die while infected
  deposit a flagged carcass; any agent that scavenges from it becomes infected
  with probability `carrion_transmission_prob` (default 0.0 — off for
  backwards compatibility).
- **`batch_seeds()`**: convenience wrapper around `batch_alife()` that takes a
  single specs object and a vector of seeds and returns a named list of results.
- **`quick_specs()` / `full_specs()`**: preset specs for fast exploratory runs
  (50 agents, 200 ticks, 20×20 grid) and publication-quality runs (200 agents,
  1000 ticks, 30×30 grid).

## Logging additions

Six previously-NA log columns are now populated:

- `mean_relatedness` — mean pairwise relatedness when `kin_selection = TRUE`.
- `n_scavenge_events` — number of carrion-eating events per tick.
- `n_gd_events` — number of group-defense damage reductions per tick.
- `mean_shelter_depth` — mean shelter depth across occupied cells.
- `mean_mutation_rate` — mean evolved `mutation_sd` when
  `mutation_rate_evolution = TRUE`.
- `mean_clutch_size` — mean clutch size when `clutch_size_evolution = TRUE`.

## Other

- Social learning warning: `run_alife()` now warns when
  `social_learning = TRUE` and `n_agents_init < 100`, since neighbour density
  at that population size is rarely sufficient to trigger copying events.

# clade 0.1.0

First public release.

## Core simulation

- Agent-based evolutionary simulation running entirely in Julia via
  JuliaConnectoR, eliminating per-tick R/Julia boundary overhead.
- Toroidal grid with logistic grass regrowth and seasonal amplitude modulation.
- Diploid or haploid genome with meiosis, Mendelian dominance models, and
  configurable crossover and mutation rates.
- Six brain types: Bayesian neural network (BNN, default), multilayer
  perceptron (ANN), continuous-time RNN (CTRNN), gene regulatory network
  (GRN), random null model, and stubs for transformer and synthesis brains.
- `run_alife()` — single simulation run; returns a named list compatible with
  `get_run_data()` and `plot_run()`.
- `batch_alife()` — run multiple replicates in sequence.
- `default_specs()` — fully documented parameter list with sensible defaults.

## Optional biological modules

Each module is a no-op when its flag is `FALSE`; overhead is zero.

- **Disease / SIR** (`disease = TRUE`): stochastic transmission, energy costs,
  recovery, and immunity.
- **Kin selection** (`kin_selection = TRUE`): pedigree-based relatedness;
  donors transfer energy to the most-related Moore-neighbourhood agent above a
  relatedness threshold.
- **Cooperation** (`cooperation = TRUE`): reciprocal altruism mediated by a
  heritable cooperation-level trait.
- **Scavenging** (`scavenging = TRUE`): carrion deposited on agent death;
  scavengers gain energy from decaying carcasses.
- **Niche construction** (`niche_construction = TRUE`): agents build shelters
  that slow grass regrowth and reduce predator damage; shelters decay
  stochastically.
- **Epigenetics** (`epigenetics = TRUE`): heritable methylation marks
  canalize BNN weight uncertainty (sigma); transgenerational epigenetic
  inheritance (TEI) transmits marks to offspring with configurable probability.
- **Within-lifetime RL** (`rl_mode = "actor_critic"`): REINFORCE with
  baseline updates the output layer of each agent's neural network each tick,
  driven by energy-gain reward.
- **Social learning** (`social_learning = TRUE`): prestige-biased copying —
  agents blend a fraction of the highest-energy neighbour's output-layer
  weights into their own policy.
- **Brain size evolution** (`brain_size_evolution = TRUE`): heritable
  `brain_size` trait (Float32, reference 1.0) modelling the parental
  provisioning hypothesis (van Schaik et al. 2023; Griesser et al. 2023;
  Song et al. 2025). Larger brains incur a per-tick idle-cost surcharge
  (expensive brain hypothesis) and a proportional cognitive foraging bonus.
  The bootstrapping problem — large-brained offspring pay the metabolic cost
  from birth before their foraging advantage emerges — means brain size only
  evolves when `parental_care = TRUE` buffers the infancy energy deficit.
  A third effect — sensing quality — scales grass perception inputs by
  `brain_size ^ brain_size_sensing_exponent`, giving larger-brained agents a
  directional navigation advantage. Logged as `mean_brain_size` in
  `env$progress`. New parameters: `brain_size_evolution`,
  `brain_size_init_mean`, `brain_size_mutation_sd`, `brain_size_min`,
  `brain_size_max`, `brain_size_cost_scale`, `brain_size_sensing_exponent`.

## Parameter search

- `search_map_elites()` — MAP-Elites quality-diversity search over simulation
  parameters (Mouret & Clune 2015). Returns an archive of parameter sets
  covering a behavioural descriptor space.
- `search_cmaes()` — CMA-ES optimisation via the GA package.
- `search_gradient()` — finite-difference gradient ascent on the log parameter
  scale; backend-agnostic (no Zygote.jl dependency).

## Analysis

- `get_run_data()` — convert raw Julia environment to tidy `$ticks` and
  `$deaths` data frames.
- `estimate_heritability()` — lag-1 autocorrelation proxy for trait
  heritability (Falconer & Mackay 1996).
- `compute_ld()` — stub for linkage disequilibrium (Lewontin & Kojima 1960).
- `species_tree()` — stub for phylogenetic reconstruction.

## Visualisation

- `plot_run()` — population dynamics panel (n_agents, mean_energy,
  genetic_diversity, grass_coverage).
- `plot_environment()` — snapshot of the grid at a given tick.

## Vignettes

- *Getting started with clade* — installation, minimal run, parameter table,
  brain types, module table, disease example.
- *The Baldwin Effect* — within-lifetime RL and social learning accelerating
  genetic evolution; comparison of three conditions; epigenetic canalization.

## Testing

- 18 pure-R and Julia integration tests for RL and social learning.
- 12 tests for MAP-Elites, CMA-ES, and gradient search.
- 13 tests for epigenetics (methylation, TEI, sigma canalization).
- Full test suite covers genome, brains (ANN, BNN, CTRNN, GRN), disease, kin,
  cooperation, scavenging, niche, analysis helpers, and visualization.
