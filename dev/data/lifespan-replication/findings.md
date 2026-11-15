# Food and reproductive threshold at a second lifespan

## Main result

The population interaction remained small and uncertain at a maximum assay lifespan of 400 ticks. It was evaluated in 100 source blocks matched to the earlier 300-tick study and 100 independent new source blocks, with 72 simulations in each block.

For each block, D is the mixture population minus the mean of eight balanced single-policy controls. The reported interaction is the effect of limited versus original food on D at threshold 80, minus that food effect at threshold 120. Values are in individuals at tick 1,000; parentheses give paired 95% intervals across source blocks.

| Source blocks | Same-age founders | Staggered founders |
| --- | ---: | ---: |
| Earlier lifespan 300, matched sources | +0.60 (-1.26, +2.46) | -1.39 (-3.25, +0.48) |
| Lifespan 400, the same sources | -0.67 (-2.22, +0.87) | -1.25 (-2.87, +0.37) |
| Lifespan 400, new sources | +0.45 (-1.33, +2.22) | +0.32 (-1.40, +2.04) |

The seed-paired change in the interaction from lifespan 300 to 400 was -1.27 (-3.49, +0.94) for same-age founders and +0.13 (-2.25, +2.52) for staggered founders. These intervals do not establish equivalence. The new-seed result likewise does not demonstrate that there is no interaction. The two founder-age comparisons and secondary timing and age analyses are not adjusted for multiple testing.

## Birth-age pattern

The exploratory interaction in births to parents under 50 was negative in both 400-tick seed sets with same-age founders: -5.26 (-8.76, -1.76) in the matched set and -5.36 (-8.73, -1.98) in the new set. With staggered founders it was -3.61 (-7.25, +0.03) and -2.52 (-6.29, +1.24), respectively. These are differences of differences in the mixture-minus-control birth count, not counts of individuals who changed their reproductive age.

The interaction in the original 150-or-older birth band was positive in both 400-tick sets. That band is wider than in the 300-tick world: it now includes parents aged 300–399. In the independent five-seed validation, such parents accounted for approximately 30–44% of the births in that band, depending on food and threshold. The planned full age-band replay was stopped at the user's request to finish sooner, before any block completed; no partial replay results were analyzed. We therefore cannot tell from the main 400-tick data how much of the older-parent interaction lies in the exact 150–299 range used previously. The age-band results remain descriptive and do not establish that birth timing caused the population outcome.

## Stability and matching

An independent five-source validation passed the preset gates: all 360 assays ended viable, remained at or above 20 agents and avoided the 700-agent cap. A 72-run repeat of an earlier 400-tick source matched 20 recorded fields. In the final 14,400 assays, all endpoints were viable, all populations remained at or above 20, and none contacted the cap. The 200 source populations all stayed above 20, with minima of 44–81. This operational population-size check is not evidence of genetic or ecological stability.

The 100 paired source-state files had identical SHA-256 hashes to the prior 300-tick study, and all 7,200 matched starts had identical physical and policy-panel fingerprints across lifespan settings. The remaining cross-threshold starts matched after removing only the deliberately changed genomic threshold trait. All 200 panels had eight distinct policies and positive deterministic behavioural disagreement. Independent pilot event reconstruction, demographic ledgers and `survival::survfit` checks passed. No source or assay outcome was excluded.

The longer lifespan changes survival, possible parent ages and density directly; initial physical matching does not keep population trajectories identical. The food treatments change initial grass and regrowth together. These results concern the specified haploid simulated populations.
