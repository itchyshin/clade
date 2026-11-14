# Genetic-diversity environment sampling

> **Kernel qualification, 14 November 2026.** These results describe a
> pinned legacy implementation that limited each agent to one focal
> reproductive episode in its lifetime, including the default iteroparous
> mode. Mate contributions were not restricted by that flag. The numbers
> remain historical source-bound results and require rerunning before
> interpreting the corrected iteroparous model. See the
> [reproduction reset report](../../dev-log/after-task/2026-11-14-iteroparous-reset.md).

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
labels. The new run is recorded below, with its exact source, machine, command,
version, timings and checksums.

These are exploratory simulations, with five seeds sharing each sampled
environment. Extinction and diversity conditional on survival answer
separate questions. Surviving runs are selected by the environment and
population dynamics; adjusting for final population size does not establish
a causal environmental effect.


## Verified rerun on 14 November 2026

`verified_results.csv` contains the 100 by five rerun using the distinct-pair
estimator from #201 and the replay-safe driver at
`d00ae6fdf6279fa4984e5ce103c5f2d9a39de3c6`. It ran on Totoro with Julia
1.10.0 in 74.29 seconds, using at most 405500 KiB (about 396 MiB).
The one-environment pilot took 10.32 seconds and produced five valid rows.

Exact command, environment variables, source archive and file checksums
are in `verified-run.json`; raw timing is in `verified-run-time.txt`.
The source archive and full output remain on Totoro under the recorded
archive path. Both submitted CSVs remain unchanged.

A surviving and an extinct run were replayed on the same machine and Julia
version from the recorded CSV inputs. Tick, population counts and the
six-decimal genetic-distance output matched (eight assertions). Replay
on a different Julia version or CPU is not established by those checks.


The independent data audit confirmed all 500 unique pairs, sampled ranges,
within-environment parameter constancy, extinction flags and missing-value
positions. Exploratory two-stage results, diagnostics and their limits are
in `analysis.md`; `analyze_verified.R` and `analysis-output.txt` make the
review reproducible. No overall best environment is claimed.
