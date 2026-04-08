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
