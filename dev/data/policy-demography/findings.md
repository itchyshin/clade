# Births and deaths after matched policy switches

The temporary population advantage at tick 800 was accompanied mainly by additional births. Between ticks 600 and 800, the more even policy group averaged 2.94 more births and 0.97 more deaths than its matched frequency-preserving shuffle. Their difference, 1.97, exactly equals the population advantage at tick 800. The paired 95% intervals were 1.32 to 4.56 for the birth difference and -0.41 to 2.35 for the death difference. These intervals describe the components separately; the birth–death accounting is exact for each seed.

| Interval | Extra births | Extra deaths | Change in population difference |
| --- | ---: | ---: | ---: |
| 600–650 | -0.78 | 0.18 | -0.96 |
| 650–700 | 2.05 | 0.83 | 1.22 |
| 700–750 | 1.13 | 0.72 | 0.41 |
| 750–800 | 0.54 | -0.76 | 1.30 |
| 600–800 total | 2.94 | 0.97 | 1.97 |
| 800–1,000 total | 0.08 | 2.02 | -1.94 |

The 800–1,000 death difference had a paired 95% interval of 0.41 to 3.63, and the birth difference had an interval of -1.61 to 1.77. By tick 1,000 the cumulative differences were 3.02 more births and 2.99 more deaths, leaving a 0.03 population difference. All intervals and age splits are exploratory follow-up comparisons: the window was chosen after seeing the original population trajectories and no multiple-comparison adjustment was made.

## Which ages contributed?

Of the 2.94 additional births from ticks 600 to 800, 2.44 came from parents aged 100–149 (paired interval 0.93 to 3.95) and 1.34 from parents aged 50–99 (0.13 to 2.55). Parents aged 150 or more contributed -0.87 and those younger than 50 contributed 0.03; these four numbers sum to 2.94. Birth counts combine the number of individuals in each age group with their birth rates. The saved data include age-specific agent-tick exposure, but the counts alone do not establish whether more births arose from age composition or a higher individual birth rate.

During the same interval there were 1.69 more deaths under age 50 (0.18 to 3.20) and 0.69 fewer deaths at age 150 or older (-1.27 to -0.11), with smaller differences in the other bands. These age-specific figures are also exploratory. They do not identify individual causes of death or show that changing age structure caused the population pattern.

## Scope and checks

This is a passive replay of the previous matched-switch experiment in the original-food, fixed-founder-age, haploid clonal setting. The intervention is causal for the specified policy reassignment, while the birth and death decomposition does not independently establish a causal mediator. Age and density were identical at the intervention and could change afterward. More even frequencies can reintroduce lost policies.

The observer matched the kernel's birth and death counters and population conservation every tick. All 6,000 checkpoint records exactly reproduced the prior run's shared fields; an independent audit checked all interval balances and 248 summary means. All 300 runs were viable at the endpoint. The observed minimum is based on 50-tick checkpoints and cannot establish the true within-run minimum. The execution used source commit `2b6ea12bbbccf06f62e700edf5653eeb7c950cc6`, and the callback was confined to an isolated source copy.
