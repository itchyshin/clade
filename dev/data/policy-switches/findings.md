# Policy frequencies with matched individual switches

Making the policy mix more even at tick 600 did not prevent the late population reversal in this experiment. At tick 1,000, the treatment had 0.03 more individuals than the frequency-preserving shuffle (95% paired interval -1.43 to 1.49). This interval includes zero; no equivalence margin was specified. At tick 800 the treatment had 1.97 more individuals (0.75 to 3.19), an exploratory comparison without adjustment for multiple checkpoints.

| Tick | More even mix | Frequency-preserving shuffle | Mean of eight single-policy controls | Treatment minus shuffle |
| --- | ---: | ---: | ---: | ---: |
| 600 | 100.50 | 100.50 | 93.00 | 0 |
| 800 | 101.69 | 99.72 | 102.16 | 1.97 (0.75, 3.19) |
| 1,000 | 119.28 | 119.25 | 123.92 | 0.03 (-1.43, 1.49) |

Intervals in the table are 95% paired t intervals. The primary bootstrap interval at tick 1,000 was -1.36 to 1.42. Each comparison contains 100 matched seed blocks, with no discarded runs. All 300 runs were viable at their endpoint under `viability_report()`; the reported minimum uses the initial state and 50-tick checkpoints, not every tick.

## Design and manipulation check

For each seed, both intervention arms began from the same tick-600 state. They changed the policies of exactly the same individuals, averaging 59 changes in each arm (range 2–96). In the sham, disjoint pairs exchanged policies, preserving the policy counts. The treatment reassigned the same individuals to make the mix more even. The paired-selection algorithm stops when its next pair cannot make the count distribution more even, so a fully balanced mix is not guaranteed. It can reintroduce policies that had disappeared; on average 2.51 were restored.

The effective number of policies rose from 2.89 before intervention to 6.78 after treatment, versus 2.89 after the sham. At tick 1,000 it remained 3.61 in the treatment and 2.03 in the sham. Thus the intervention produced a persistent frequency difference despite the matched switch count and identities.

## Density and age

The grid has 900 cells, so occupancy density is population size divided by 900. At tick 800 the difference was 0.00219 individuals per cell (95% interval 0.00083 to 0.00354); at tick 1,000 it was 0.00003 (-0.00159 to 0.00166). This is the same population contrast expressed per unit area, not an independent outcome.

At tick 600, mean age was 67.85 ticks in both groups. At tick 1,000 it was 102.71 in the treatment and 102.88 in the sham, a paired difference of -0.17 ticks (-1.42 to 1.08). Age-bin counts suggested a different composition at tick 1,000: treatment minus sham averaged +1.86 individuals aged 50–99 (0.73 to 2.99) and -1.92 aged 100–149 (-3.10 to -0.74). These are exploratory comparisons among several age bins and checkpoints, with no multiplicity adjustment. They are not evidence that age structure caused the reversal.

Population density, age, energy, positions, food and the simulation RNG were exactly matched at the intervention. Afterward, age structure and density could respond to the treatment. The experiment therefore does not estimate an effect under continuously fixed demographic conditions. Both arms change the same individuals but assign them different policies, which is the intended contrast; the artificial reintroduction of lost policies limits its biological interpretation. These results do not rule out causal effects of naturally changing policy frequencies or other interventions.

## Validation

The natural arm reproduced population and grass in the previous run at all 20 checkpoints for all 100 seeds. The driver asserts identical changed-individual sets and switch counts. A separate audit checked 6,000 rows, physical-state hashes, age and policy totals, prior trajectories and 360 summary means. The source was commit `2b6ea12bbbccf06f62e700edf5653eeb7c950cc6`, with the hook applied only to an isolated research copy. No package kernel or public API changed. The run, source hashes, analysis and viability records are retained alongside this report.
