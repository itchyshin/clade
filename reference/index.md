# Package index

## Running simulations

Entry points for running and batching evolutionary simulations.

- [`run_alife()`](run_alife.md) : Run an evolutionary simulation
- [`run_clade()`](run_clade.md) : Synonym for run_alife()
- [`batch_alife()`](batch_alife.md) : Run multiple simulations in
  parallel
- [`batch_seeds()`](batch_seeds.md) : Run one specs object with multiple
  random seeds
- [`default_specs()`](default_specs.md) : Default simulation parameters
  for clade
- [`quick_specs()`](quick_specs.md) : Quick preset specs for fast
  exploratory runs
- [`full_specs()`](full_specs.md) : Full preset specs for
  publication-quality runs
- [`load_specs()`](load_specs.md) : Load simulation specs from a JSON
  file

## Results & visualisation

Extract tidy output and produce plots.

- [`clade-visualization`](clade-visualization.md) : Visualisation layer
  for clade simulation output
- [`get_run_data()`](get_run_data.md) : Extract simulation results as
  tidy data frames
- [`get_genome_data()`](get_genome_data.md) : Extract per-tick genome
  data (allele frequencies, diversity, FST)
- [`plot_run()`](plot_run.md) : Dashboard plot summarising a clade
  simulation run
- [`plot_environment()`](plot_environment.md) : Plot the current state
  of a clade environment
- [`plot_diversity()`](plot_diversity.md) : Plot genetic diversity over
  the run
- [`plot_signal_evolution()`](plot_signal_evolution.md) : Plot signal
  evolution (Phase 2 placeholder)
- [`plot_disease_dynamics()`](plot_disease_dynamics.md) : Plot disease
  dynamics over time
- [`plot_body_size_evolution()`](plot_body_size_evolution.md) : Plot
  body-size evolution over time
- [`plot_dispersal_events()`](plot_dispersal_events.md) : Plot natal
  dispersal events over time
- [`plot_kin_network()`](plot_kin_network.md) : Plot kin network (Phase
  2 placeholder)
- [`plot_dead_agents()`](plot_dead_agents.md) : Plot lifetime statistics
  of dead agents
- [`plot_genome_diversity()`](plot_genome_diversity.md) : Plot genetic
  diversity over time
- [`plot_tsne_genomes()`](plot_tsne_genomes.md) : Plot genome PCA to
  reveal population genetic structure
- [`plot_weight_heatmap()`](plot_weight_heatmap.md) : Visualise a neural
  genome as a weight heatmap
- [`plot_module_metrics()`](plot_module_metrics.md) : Plot
  module-specific metrics from a clade simulation run
- [`visualize_progress()`](visualize_progress.md) : Render the full
  simulation dashboard

## Parameter search

Automated tools for finding parameter combinations that produce target
evolutionary outcomes.

- [`search_map_elites()`](search_map_elites.md) : MAP-Elites
  quality-diversity search over simulation parameters
- [`search_cmaes()`](search_cmaes.md) : CMA-ES optimisation over
  simulation parameters
- [`search_gradient()`](search_gradient.md) : Finite-difference gradient
  ascent over simulation parameters
- [`search_random()`](search_random.md) : Stochastic parameter sweep for
  evolutionary outcome discovery
- [`search_viability()`](search_viability.md) : Grid-search parameter
  viability: which combinations allow population survival?

## Scenario objectives

Pre-built objective functions for the complex landscape, spatial
sorting, and IFfolk modules. Pass to
[`search_cmaes()`](../reference/search_cmaes.md) or write your own with
the same signature.

- [`objective_complex_landscape()`](objective_complex_landscape.md) :
  Objective function for the complex landscape scenario
- [`objective_spatial_sorting()`](objective_spatial_sorting.md) :
  Objective function for the spatial sorting scenario
- [`objective_iffolk()`](objective_iffolk.md) : Objective function for
  the IFfolk inclusive fitness scenario

## Convenience tuning wrappers

Pre-configured [`search_cmaes()`](../reference/search_cmaes.md) /
[`search_map_elites()`](../reference/search_map_elites.md) calls for
each major module. Use these instead of wiring up objectives and
parameter lists manually.

- [`tune_complex_landscape()`](tune_complex_landscape.md) : Tune
  parameters for the complex landscape module
- [`tune_spatial_sorting()`](tune_spatial_sorting.md) : Tune parameters
  for the spatial sorting module
- [`tune_iffolk()`](tune_iffolk.md) : Tune parameters for the IFfolk
  inclusive fitness module

## Custom modules

Register user-defined hook functions that run at each tick.

- [`register_module()`](register_module.md) : Register a custom module
  function
- [`list_modules()`](list_modules.md) : List registered custom modules
- [`clear_modules()`](clear_modules.md) : Remove all registered custom
  modules

## Pure-R scenarios

Scenarios that run entirely in R (no Julia required).

- [`run_bad_science()`](run_bad_science.md) : Simulate the evolution of
  scientific practice

## Population genetics & analysis

Estimate heritability, relatedness, LD, and genome diversity.

- [`estimate_heritability()`](estimate_heritability.md) : Estimate
  narrow-sense heritability from a logged trait time-series
- [`heritability_estimate()`](heritability_estimate.md) : Estimate
  narrow-sense heritability from parent-offspring data
- [`compare_conditions()`](compare_conditions.md) : Compare evolutionary
  outcomes across simulation conditions
- [`compute_relatedness()`](compute_relatedness.md) : Compute
  pedigree-based relatedness between two agents
- [`compute_ld()`](compute_ld.md) : Compute linkage disequilibrium from
  a logged genome time-series
- [`genome_distance()`](genome_distance.md) : Compute normalised
  Euclidean genome distance between two agents
- [`diversity_landscape()`](diversity_landscape.md) : Visualise the
  multi-trait diversity landscape
- [`species_tree()`](species_tree.md) : Reconstruct a species tree from
  a logged simulation

## Map generation

Create structured landscape maps for the simulation grid.

- [`generate_map()`](generate_map.md) : Generate a procedural habitat
  map
- [`prepare_map()`](prepare_map.md) : Validate and resize a habitat map
- [`load_map()`](load_map.md) : Load a bundled or saved habitat map
- [`plot_map()`](plot_map.md) : Plot the spatial distribution of agents
  on the grid

## Agent internals

Inspect individual agent brains, weights, and actions.

- [`inspect_brain()`](inspect_brain.md) : Inspect the brain structure of
  a single agent
- [`get_brain_weights()`](get_brain_weights.md) : Extract weight values
  from an agent's brain
- [`sense_env()`](sense_env.md) : Build the sensory input vector for an
  agent
- [`take_action()`](take_action.md) : Choose an action for an agent
  given its sensory input

## Julia session management

Check Julia availability and version.

- [`julia_is_ready()`](julia_is_ready.md) : Check whether the Julia
  session is active
- [`julia_version()`](julia_version.md) : Report the Julia version used
  by clade

## Inspection utilities

Pretty-print specs, summarise environments.

- [`print_specs()`](print_specs.md) : Pretty-print all simulation
  parameters
