# The reversal is part of a demographic cycle

The haploid mixture advantage does not reverse once and stay reversed. In the
original-food world, mixture and control populations repeatedly boom and
contract, and the mixture advantage changes sign several times. Policy
frequencies also become much more uneven. These patterns account for what
happens; they do not establish a single causal mechanism.

This experiment replays 100 matched seed blocks for the original-food,
fixed-age, high-source-mutation haploid condition. Each mixture begins with
six individuals of each of eight policies and is compared with the equal
mean of its eight monocultures. New mutation is disabled. Haploid offspring
carry exact copies of their parent's policy, verified at each birth and
checkpoint. Counts below are averages across seed blocks; intervals describe
seed-level Monte Carlo uncertainty.

## The advantage oscillates

| Tick | Mixture minus balanced controls | 95% interval |
|---:|---:|---:|
| 250 | +10.42 agents | +8.68 to +12.17 |
| 400 | -8.91 | -10.41 to -7.41 |
| 600 | +7.50 | +5.85 to +9.16 |
| 750 | -6.23 | -7.50 to -4.95 |
| 850 | +4.34 | +3.00 to +5.68 |
| 1,000 | -4.42 | -5.49 to -3.36 |

The mixture population averages 56.85 agents at tick 300, 100.50 at 600 and
119.50 at 1,000; the controls average 46.57, 93.00 and 123.92. Density is
these counts divided by 900 cells. The positive result at tick 300 and the
negative result at tick 1,000 sample different phases of a repeating,
damped demographic pattern. The same broad swings occur in the previous
matched runs with founder ages 25–72. Staggering founders by this amount
therefore does not eliminate the pattern. It does not exclude later cohort
synchrony or establish the origin of the cycles.

From ticks 600 to 1,000, mixtures have 10.92 fewer births per population than
the balanced controls (95% interval -12.98 to -8.86). The total death
comparison is +1.00 (-0.90 to +2.91). Their difference is the observed
-11.93-agent change in the mixture advantage. Births per 1,000 agent-ticks
are 5.88 in mixtures versus 6.04 in controls over this interval. The paired
rate difference is -0.167 (-0.211 to -0.123). These ledgers explain the
arithmetic of the reversal; they do not by themselves explain why birth
rates differ.

## Policies and demographic composition change

At tick 300, an average of 6.56 founder policies remain present in mixtures;
at tick 1,000, 3.89 remain. Uneven frequencies make their effective number
1 / sum(frequency squared) fall from 4.55 to 2.00 over the same period.
The most common policy rises from 34.6% to 70.0% on average. At tick 1,000,
23 of 100 mixtures have a policy at 90% or more, while only three have lost
all but one policy. Policy concentration is substantial without universal
fixation.

A descriptive accounting identity weights each monoculture's population by
its corresponding policy's frequency in the mixture. The resulting
composition-associated term is +4.46 agents at tick 600 and -1.88 at tick
1,000. The remaining terms are +3.04 and -2.55. This calculation compares
outcomes from separate interacting populations; it cannot say how the
mixture would behave if its policy frequencies were held fixed.

Age composition also shifts. Immediately before reproduction at tick 600,
mixture agents average 68.73 ticks old versus 63.79 in controls, a paired
difference of +4.94 (95% interval +3.77 to +6.11). At tick 800, mixtures
are 5.28 ticks younger on average (-6.72 to -3.84). At tick 600, the fraction
meeting energy and age thresholds is 1.02% in mixtures versus 1.30% in
controls. This pre-reproduction measure excludes agents at the age cap but
is only a readiness proxy: space and the population cap can also prevent
birth. It is measured at checkpoints, not continuously.

## Food and density provide clues, but not a complete causal answer

Standing grass in mixture worlds falls from 1.68 units per cell at tick 300
to .71 at 600 and .44 at 1,000; controls have 2.05, .87 and .48. Over ticks
600–1,000, however, mixture food intake per agent-tick is slightly higher
than the balanced controls by .00193 (95% interval .00108 to .00278).
Thus less food intake per agent is insufficient to explain the later birth
deficit. Energy expenditure, reproductive thresholds, space and age/policy
composition can still matter.

A matched intervention doubles grass regrowth from .05 to .10, keeping the
same initial maps, policies and seeds. It changes the transient mixture
advantage by +10.66 agents at tick 300 and -5.05 at tick 600. At tick 1,000,
the original-regrowth advantage is -4.42 agents and the higher-regrowth
advantage is -4.50; their paired difference is -0.07 (95% interval -1.94 to
+1.79). Mixture population rises from 119.50 to 226.55 agents, but the final
mixture disadvantage remains. This rules out a simple claim that doubling
regrowth removes the endpoint reversal; it does not rule out all effects of
resource limitation or density.

All 900 higher-regrowth runs meet the R viability verdict. The 500-agent cap
is reached in 250 of 900 runs, for 2,596 of 900,000 run-ticks, all through
tick 150. In the 32 seed blocks with no cap exposure in any of the nine
higher-regrowth groups, the tick-1,000 regrowth effect is +1.04 agents
(-2.99 to +5.07). This selected sensitivity is imprecise and does not erase
possible carryover from early cap exposure in the other blocks.

## What is established

The reversal is a repeated demographic pattern with policy concentration,
age-structure changes and resource/population feedback. Later fewer births
account for the decline from tick 600 to tick 1,000. The resource intervention
changes transient dynamics but does not clearly change the endpoint advantage.
The causal roles of policy-frequency change, density, age and food remain
entangled. Results cover this haploid clonal world and these policies, not
recombining diploids, other resource worlds or lifetime fitness.

The original 900-run trace, higher-regrowth 900-run intervention and 900-run
age replay took 100.47, 152.29 and 90.31 seconds on Totoro. All 18,000 original
windows match the earlier run on population, births, deaths, exposure and
food. All 144,000 age-replay rows reproduce their original fields exactly.
The higher-regrowth audit verifies policy-level ledgers, cap records and exact
matching of physical starting states. Source/data hashes and all results are
in results/run.json.
