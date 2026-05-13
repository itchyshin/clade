# Package index

## Running simulations

Entry points for running and batching evolutionary simulations.

- [`run_alife()`](https://itchyshin.github.io/clade/reference/run_alife.md)
  : Run an evolutionary simulation
- [`run_clade()`](https://itchyshin.github.io/clade/reference/run_clade.md)
  : Synonym for run_alife()
- [`batch_alife()`](https://itchyshin.github.io/clade/reference/batch_alife.md)
  : Run multiple simulations in parallel
- [`batch_seeds()`](https://itchyshin.github.io/clade/reference/batch_seeds.md)
  : Run one specs object with multiple random seeds
- [`grid_specs()`](https://itchyshin.github.io/clade/reference/grid_specs.md)
  : Generate a factorial grid of specs
- [`sample_specs()`](https://itchyshin.github.io/clade/reference/sample_specs.md)
  : Sample specs randomly from parameter distributions
- [`summarize_batch()`](https://itchyshin.github.io/clade/reference/summarize_batch.md)
  : Summarize a batch of run results into a tidy data frame
- [`stream_specs_to_csv()`](https://itchyshin.github.io/clade/reference/stream_specs_to_csv.md)
  : Stream a parameter-space sweep to disk, one row per run
- [`submit_sweep_slurm()`](https://itchyshin.github.io/clade/reference/submit_sweep_slurm.md)
  : Generate a SLURM array-job template for a parameter-space sweep
- [`default_specs()`](https://itchyshin.github.io/clade/reference/default_specs.md)
  : Default simulation parameters for clade
- [`quick_specs()`](https://itchyshin.github.io/clade/reference/quick_specs.md)
  : Quick preset specs for fast exploratory runs
- [`full_specs()`](https://itchyshin.github.io/clade/reference/full_specs.md)
  : Full preset specs for publication-quality runs
- [`fast_specs()`](https://itchyshin.github.io/clade/reference/fast_specs.md)
  : Fast-generation specs for evolutionary scenarios
- [`slow_specs()`](https://itchyshin.github.io/clade/reference/slow_specs.md)
  : Slow-generation specs for long-lived organism scenarios
- [`realistic_specs()`](https://itchyshin.github.io/clade/reference/realistic_specs.md)
  : Realistic-scale specs for ecologically meaningful audits
- [`ultra_realistic_specs()`](https://itchyshin.github.io/clade/reference/ultra_realistic_specs.md)
  : Ultra-realistic specs for finite-size-sensitive audits
- [`load_specs()`](https://itchyshin.github.io/clade/reference/load_specs.md)
  : Load simulation specs from a JSON file
- [`wolf_personality_specs()`](https://itchyshin.github.io/clade/reference/wolf_personality_specs.md)
  : Spec preset for the Wolf 2007 personality reproduction
- [`trivers_reciprocity_specs()`](https://itchyshin.github.io/clade/reference/trivers_reciprocity_specs.md)
  : Spec preset for the Trivers 1971 reciprocal-altruism reproduction
- [`wolf2008_responsiveness_specs()`](https://itchyshin.github.io/clade/reference/wolf2008_responsiveness_specs.md)
  : Spec preset for the Wolf 2008 responsive-personalities reproduction

## Hypothesis testing

Helpers for the sweep-\>test-\>report workflow common in fidelity audits
and paper reproductions. Helpers for the sweep-\>test-\>report workflow
used in fidelity audits and paper reproductions. See
[`vignette("paper-kokko-brooks-2003")`](https://itchyshin.github.io/clade/articles/paper-kokko-brooks-2003.md)
for a worked example.

- [`hypothesis_sweep()`](https://itchyshin.github.io/clade/reference/hypothesis_sweep.md)
  : Sweep hypothesis conditions across seeds and compute per-run metrics
- [`hypothesis_report()`](https://itchyshin.github.io/clade/reference/hypothesis_report.md)
  : Compute contrast tests from a hypothesis_sweep

## Results & visualisation

Extract tidy output and produce plots.

- [`clade-visualization`](https://itchyshin.github.io/clade/reference/clade-visualization.md)
  : Visualisation layer for clade simulation output
- [`get_run_data()`](https://itchyshin.github.io/clade/reference/get_run_data.md)
  : Extract simulation results as tidy data frames
- [`get_genome_data()`](https://itchyshin.github.io/clade/reference/get_genome_data.md)
  : Extract per-tick genome data (allele frequencies, diversity, FST)
- [`plot_run()`](https://itchyshin.github.io/clade/reference/plot_run.md)
  : Dashboard plot summarising a clade simulation run
- [`plot_environment()`](https://itchyshin.github.io/clade/reference/plot_environment.md)
  : Plot the current state of a clade environment
- [`plot_diversity()`](https://itchyshin.github.io/clade/reference/plot_diversity.md)
  : Plot genetic diversity over the run
- [`plot_signal_evolution()`](https://itchyshin.github.io/clade/reference/plot_signal_evolution.md)
  : Plot evolution of mean signal magnitude over ticks
- [`plot_disease_dynamics()`](https://itchyshin.github.io/clade/reference/plot_disease_dynamics.md)
  : Plot disease dynamics over time
- [`plot_body_size_evolution()`](https://itchyshin.github.io/clade/reference/plot_body_size_evolution.md)
  : Plot body-size evolution over time
- [`plot_dispersal_events()`](https://itchyshin.github.io/clade/reference/plot_dispersal_events.md)
  : Plot natal dispersal events over time
- [`plot_kin_network()`](https://itchyshin.github.io/clade/reference/plot_kin_network.md)
  : Plot kin network (not yet implemented — placeholder)
- [`plot_dead_agents()`](https://itchyshin.github.io/clade/reference/plot_dead_agents.md)
  : Plot lifetime statistics of dead agents
- [`plot_genome_diversity()`](https://itchyshin.github.io/clade/reference/plot_genome_diversity.md)
  : Plot genetic diversity over time
- [`plot_tsne_genomes()`](https://itchyshin.github.io/clade/reference/plot_tsne_genomes.md)
  : Plot genome PCA to reveal population genetic structure
- [`plot_weight_heatmap()`](https://itchyshin.github.io/clade/reference/plot_weight_heatmap.md)
  : Visualise a neural genome as a weight heatmap
- [`plot_module_metrics()`](https://itchyshin.github.io/clade/reference/plot_module_metrics.md)
  : Plot module-specific metrics from a clade simulation run
- [`visualize_progress()`](https://itchyshin.github.io/clade/reference/visualize_progress.md)
  : Render the full simulation dashboard

## Parameter search

Automated tools for finding parameter combinations that produce target
evolutionary outcomes.

- [`search_map_elites()`](https://itchyshin.github.io/clade/reference/search_map_elites.md)
  : MAP-Elites quality-diversity search over simulation parameters
- [`search_cmaes()`](https://itchyshin.github.io/clade/reference/search_cmaes.md)
  : CMA-ES optimisation over simulation parameters
- [`search_gradient()`](https://itchyshin.github.io/clade/reference/search_gradient.md)
  : Finite-difference gradient ascent over simulation parameters
- [`search_random()`](https://itchyshin.github.io/clade/reference/search_random.md)
  : Stochastic parameter sweep for evolutionary outcome discovery
- [`search_viability()`](https://itchyshin.github.io/clade/reference/search_viability.md)
  : Grid-search parameter viability: which combinations allow population
  survival?

## Scenario objectives

Pre-built objective functions for the complex landscape, spatial
sorting, and IFfolk modules. Pass to
[`search_cmaes()`](https://itchyshin.github.io/clade/reference/search_cmaes.md)
or write your own with the same signature.

- [`objective_complex_landscape()`](https://itchyshin.github.io/clade/reference/objective_complex_landscape.md)
  : Objective function for the complex landscape scenario
- [`objective_spatial_sorting()`](https://itchyshin.github.io/clade/reference/objective_spatial_sorting.md)
  : Objective function for the spatial sorting scenario
- [`objective_iffolk()`](https://itchyshin.github.io/clade/reference/objective_iffolk.md)
  : Objective function for the IFfolk inclusive fitness scenario

## Convenience tuning wrappers

Pre-configured
[`search_cmaes()`](https://itchyshin.github.io/clade/reference/search_cmaes.md)
/
[`search_map_elites()`](https://itchyshin.github.io/clade/reference/search_map_elites.md)
calls for each major module. Use these instead of wiring up objectives
and parameter lists manually.

- [`tune_complex_landscape()`](https://itchyshin.github.io/clade/reference/tune_complex_landscape.md)
  : Tune parameters for the complex landscape module
- [`tune_spatial_sorting()`](https://itchyshin.github.io/clade/reference/tune_spatial_sorting.md)
  : Tune parameters for the spatial sorting module
- [`tune_iffolk()`](https://itchyshin.github.io/clade/reference/tune_iffolk.md)
  : Tune parameters for the IFfolk inclusive fitness module

## Pure-R scenarios

Scenarios that run entirely in R (no Julia required).

- [`run_bad_science()`](https://itchyshin.github.io/clade/reference/run_bad_science.md)
  : Simulate the evolution of scientific practice

## Population genetics & analysis

Estimate heritability, relatedness, LD, and genome diversity.

- [`estimate_heritability()`](https://itchyshin.github.io/clade/reference/estimate_heritability.md)
  : Estimate narrow-sense heritability from a logged trait time-series
- [`heritability_estimate()`](https://itchyshin.github.io/clade/reference/heritability_estimate.md)
  : Estimate narrow-sense heritability from parent-offspring data
- [`compare_conditions()`](https://itchyshin.github.io/clade/reference/compare_conditions.md)
  : Compare evolutionary outcomes across simulation conditions
- [`compute_relatedness()`](https://itchyshin.github.io/clade/reference/compute_relatedness.md)
  : Compute pedigree-based relatedness between two agents
- [`compute_ld()`](https://itchyshin.github.io/clade/reference/compute_ld.md)
  : Compute linkage disequilibrium from a logged genome time-series
- [`genome_distance()`](https://itchyshin.github.io/clade/reference/genome_distance.md)
  : Compute normalised Euclidean genome distance between two agents
- [`diversity_landscape()`](https://itchyshin.github.io/clade/reference/diversity_landscape.md)
  : Visualise the multi-trait diversity landscape
- [`species_tree()`](https://itchyshin.github.io/clade/reference/species_tree.md)
  : Reconstruct a species tree from a logged simulation
- [`viability_report()`](https://itchyshin.github.io/clade/reference/viability_report.md)
  : Viability report for an evolutionary-audit run

## Map generation

Create structured landscape maps for the simulation grid.

- [`generate_map()`](https://itchyshin.github.io/clade/reference/generate_map.md)
  : Generate a procedural habitat map
- [`prepare_map()`](https://itchyshin.github.io/clade/reference/prepare_map.md)
  : Validate and resize a habitat map
- [`load_map()`](https://itchyshin.github.io/clade/reference/load_map.md)
  : Load a bundled or saved habitat map
- [`plot_map()`](https://itchyshin.github.io/clade/reference/plot_map.md)
  : Plot the spatial distribution of agents on the grid

## Agent internals

Inspect individual agent brains, weights, and actions.

- [`inspect_brain()`](https://itchyshin.github.io/clade/reference/inspect_brain.md)
  : Inspect the brain structure of a single agent
- [`get_brain_weights()`](https://itchyshin.github.io/clade/reference/get_brain_weights.md)
  : Extract weight values from an agent's brain
- [`sense_env()`](https://itchyshin.github.io/clade/reference/sense_env.md)
  : Build the sensory input vector for an agent
- [`take_action()`](https://itchyshin.github.io/clade/reference/take_action.md)
  : Choose an action for an agent given its sensory input

## Julia session management

Check Julia availability and version.

- [`julia_is_ready()`](https://itchyshin.github.io/clade/reference/julia_is_ready.md)
  : Check whether the Julia session is active
- [`julia_version()`](https://itchyshin.github.io/clade/reference/julia_version.md)
  : Report the Julia version used by clade

## Inspection utilities

Pretty-print specs, summarise environments.

- [`print_specs()`](https://itchyshin.github.io/clade/reference/print_specs.md)
  : Pretty-print all simulation parameters
