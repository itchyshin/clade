# Food regime changes the mixture advantage; age effects are uncertain

The matched experiment points to food conditions as the clearer influence on
the population advantage of policy mixtures at tick 1,000. Staggered founder
ages did not produce a clearly detectable change at any of the three food
levels. The age intervals remain wide enough to include effects in either
direction, especially under the most severe shortage.

Each of 100 matched seed blocks per ploidy supplies one eight-policy mixture
and eight single-policy controls in each of six food-by-age conditions.
The mixture advantage is its population minus the equal mean population of
all eight controls. There are 10,800 simulations; every outcome, including
extinction and nonviable populations, enters the main contrasts.

## Matched effects at tick 1,000

| Food regime | Age treatment | Haploid mixture advantage | Diploid mixture advantage |
|---|---|---:|---:|
| Original: initial grass .50, regrowth .05 | Fixed at 50 | -4.42 (-5.49 to -3.36) | -1.86 (-3.02 to -0.70) |
| Original | Ages 25–72 | -3.47 (-4.49 to -2.44) | -1.37 (-2.34 to -0.40) |
| Moderate: initial grass .25, regrowth .025 | Fixed at 50 | +2.09 (1.03 to 3.15) | +1.07 (0.11 to 2.02) |
| Moderate | Ages 25–72 | +2.18 (1.16 to 3.20) | +0.91 (-0.17 to 1.99) |
| Severe: initial grass .25, regrowth .0125 | Fixed at 50 | -3.75 (-5.80 to -1.71) | -1.69 (-3.73 to +0.35) |
| Severe | Ages 25–72 | -2.95 (-5.25 to -0.64) | -2.42 (-4.64 to -0.20) |

Values are differences in number of agents, with 95% paired-seed t intervals.
The moderate regime increases the mixture advantage relative to the original
regime by 6.51 agents in fixed-age haploids (95% interval 4.90 to 8.13) and
2.93 agents in fixed-age diploids (1.45 to 4.42). Staggered-age comparisons
show the same direction: +5.65 and +2.28 agents. This is a difference between
mixture advantages, rather than the effect of food on raw population size.

Food effects are not monotonic. Comparing the severe with the moderate regime
holds initial grass at .25 and reduces regrowth from .025 to .0125. That
reduces the mixture advantage by 5.84 agents in fixed-age haploids (-8.31 to
-3.38) and 2.76 in fixed-age diploids (-5.01 to -0.51); both staggered-age
contrasts are also negative. The original-versus-limited comparison changes
initial grass and regrowth together; the moderate-versus-severe contrast
isolates their regrowth difference within the .25 initial-grass setting.

At every food level, the paired staggered-minus-fixed difference in mixture
advantage has an interval including zero. For example, at moderate food it is
+0.09 agents in haploids (-1.34 to +1.53) and -0.16 in diploids (-1.52 to
+1.20). All tested food-by-age interaction intervals include zero. This is
uncertainty about the effects, not proof of equality. Bootstrap intervals
are included in results/factorial_summary.csv as a sensitivity check.

## The earlier 300-tick advantage changed over time

The original-food, fixed-age haploid comparison exactly reproduces the
preceding study at tick 300: mixtures average 56.85 agents and controls
46.57, a 22.07% advantage. By tick 600 it is +8.07%; at tick 1,000 it is
-3.57% (paired bootstrap interval -4.38 to -2.77). This is the same matched
setting followed longer; the reversal does not require changing food or age.
The paired change in the haploid mixture advantage from tick 300 to 1,000
is -14.70 agents (95% interval -17.02 to -12.39). The corresponding
diploid differences are +3.99%, +1.08% and -1.61%; their paired change is
-3.68 agents (-5.79 to -1.57).
All 1,800 matching earlier baseline runs agree on population, births and
deaths through tick 300. The time-course percentages are exploratory and do
not by themselves establish a permanent reversal beyond tick 1,000.

## Limits and checks

At original food, all nine groups were viable in all 100 blocks for both
age treatments and ploidies. At moderate food, all were viable in 98 to 100
blocks. Restricting the haploid moderate-food age comparison to the 98
blocks with all groups viable in both age treatments gives -0.07 agents
(-1.51 to +1.37), consistent with the all-block comparison. At severe food,
no block had all nine groups viable, so all-block comparisons include
crashed and extinct populations and no all-nine-viable sensitivity exists.
Extinction differences are provided separately in the figure and summary.

The fixed founders are all age 50; the staggered schedule has mean age 48.5.
Thus it changes mean age slightly as well as age spread. The food effects
concern the specified regimes, not every possible resource world. The
intervention tests mixing relative to the average of the same monocultures;
selection, frequency shifts, density feedback and diploid recombination can
contribute. It does not establish complementarity or lifetime fitness.

The 108-run pilot reproduced all 36 earlier staggered limited-food cases.
Across the full campaign, all 3,600 earlier staggered limited-food run rows
and 72,000 window rows reproduce exactly. Forty-two initialization assertions
passed. Independent raw-table reconstruction verified 10,800 keys, 216,000
windows, demographic ledgers and every factorial mean. The full run took
596.10 seconds on Totoro; source and data checksums are in results/run.json.
