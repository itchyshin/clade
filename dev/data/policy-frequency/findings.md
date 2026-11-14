# Does restoring policy frequencies prevent the reversal?

Restoring an even mix of the eight founder policies at tick 600 did not prevent the population disadvantage at tick 1,000 in this experiment. The estimated difference from the shuffled control was -1.56 agents (95% paired interval -3.14 to 0.02). This interval includes zero and does not establish equivalence. At tick 800 the restored population was larger by 2.19 agents (0.87 to 3.51); that intermediate comparison is exploratory and has not been adjusted for multiple checkpoints.

| Tick | Restored mix | Shuffled control | Mean of eight single-policy controls | Restored minus shuffled, 95% interval |
| --- | ---: | ---: | ---: | ---: |
| 600 | 100.50 | 100.50 | 93.00 | 0 |
| 800 | 101.12 | 98.93 | 102.16 | 2.19 (0.87, 3.51) |
| 1,000 | 118.93 | 120.49 | 123.92 | -1.56 (-3.14, 0.02) |

Each estimate uses 100 matched seed blocks. The primary outcome was the difference at tick 1,000. Paired bootstrap intervals were similar: -3.05 to 0.02 at 1,000, and 0.95 to 3.57 at 800. All 300 intervention runs were viable at the endpoint according to `viability_report()`. That check does not measure the minimum population within a run.

## What was changed

The original food, fixed-founder-age, haploid clonal setting was replayed to tick 600. Three arms then continued from each identical population: natural evolution, a shuffle of the existing policy counts across individuals, and a shuffle restoring equal founder-policy counts. The eight single-policy controls are the matched benchmark from the previous experiment. At the intervention, hashes verified equal population density, ages, energy, positions, food and simulation RNG state across arms. Density and age structure were free to change afterward, so these results include subsequent demographic feedback and do not estimate an effect at continuously fixed density or age structure.

The effective number of policies was 2.89 before intervention and 7.99 immediately after restoration. At tick 1,000 it was 4.31 in the restored group and 1.99 in the shuffled control, so the contrast in composition persisted. Restoration reintroduced an average of 2.55 founder policies that had disappeared. It changed the policy of 87.72 individuals on average, compared with 59.60 in the shuffled control. Both shuffles disrupted the original associations between policy and individual state, but the numbers of switches differed.

The intervention therefore shows that this particular restoration, with its associated reassignment, was insufficient to prevent the late reversal. The temporary difference at tick 800 is consistent with a time-dependent response. It does not establish that naturally changing frequencies have no causal role, or isolate their effects from the unequal amount of reassignment. These artificial policy swaps are a mechanistic probe, not a biological account of mutation or inheritance.

## Validation and provenance

The natural arm matched the previous simulation's population and grass at all 20 checkpoints in all 100 seeds. Independent reconstruction checked 6,000 checkpoint rows, physical-state hashes, policy assignments and the 240 reported summary means. The original source commit was `2b6ea12bbbccf06f62e700edf5653eeb7c950cc6`. The callback was applied only to an isolated research copy; no package kernel or public API was changed. `results/` retains the data and execution receipts, and the accompanying scripts reproduce the summaries.
