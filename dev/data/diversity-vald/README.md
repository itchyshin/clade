# Genetic-diversity environment sampling

These files record separate simulation campaigns. Preserve the submitted
files so the original analyses remain traceable.

## Submitted campaigns

- `drac_results_legacy_repro.csv`: 100 environments by five seeds. The
  `repro_threshold` column was unused by the kernel; reproduction retained
  the default `min_repro_energy`. Treat this as the original exploratory
  dataset with an ineffective design axis.
- `full_drac_results.csv`: Bhavya's corrected 100 by five DRAC run, reported
  at commit `9b5935a`, job `2264997`, wall time 00:02:04 and about 452 MB.
  Command: `julia --project=inst/julia inst/julia/scripts/sample_env.jl 100 full_drac_results.csv`.
  The five sampled spec columns are rounded representations of the values
  simulated, and zero-filled snapshots after termination are unobserved.
  The old genetic estimator also included attempted self-pairs in its
  denominator. These limitations prevent treating this file as a final
  validation dataset. Job details are contributor-reported in PR #185.

## Current driver

`inst/julia/scripts/sample_env.jl` uses a separate Xoshiro(42) design RNG,
five simulation seeds (101 through 105), 1000 ticks and 50 initial prey.
No predators are seeded. Grass growth is explicitly stochastic.

The CSV records sampled inputs with round-trip Float64 precision.
`final_*` values use the actual final tick. Snapshots after that tick are
`NA`, while a zero population observed at the extinction tick remains
zero. A one-individual genetic distance of zero is the kernel convention;
there is no observed pairwise distance when fewer than two remain.

The corrected distinct-pair estimator changes random draws and simulation
trajectories. Results from different estimator versions require separate
labels. A new run and its machine, exact code revision, command, Julia
version, timings and checksums will be recorded before interpreting it.

These are exploratory simulations, with five seeds sharing each sampled
environment. Extinction and diversity conditional on survival answer
separate questions. Surviving runs are selected by the environment and
population dynamics; adjusting for final population size does not establish
a causal environmental effect.
