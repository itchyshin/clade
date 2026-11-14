# Founder density, reproduction and the food effect

Both founder density and reproductive threshold changed the food-dependent mixture pattern in this matched experiment. At the original threshold of 120, increasing the founder count weakened the food effect. At 48 founders, lowering the threshold from 120 to 80 weakened it even more. The effects of the two factors were not simply additive: each factor's effect depended on the setting of the other.

Define the mixture contrast as mixture population minus the mean of eight single-policy controls. The table shows the **food effect on that contrast**, calculated as limited-food contrast minus original-food contrast at tick 1,000. Positive values mean the mixture did better relative to its controls under limited food than under original food.

| Founders | Reproduction threshold | Same founder ages | Staggered founder ages |
| ---: | ---: | ---: | ---: |
| 48 | 120 | 7.52 (6.10, 8.95) | 5.77 (4.32, 7.21) |
| 48 | 80 | -0.15 (-1.75, 1.45) | -2.33 (-3.89, -0.78) |
| 96 | 120 | 2.42 (0.85, 3.99) | 2.88 (1.45, 4.31) |
| 96 | 80 | 0.79 (-0.81, 2.38) | -1.17 (-2.64, 0.30) |

Values are paired means across 100 seed blocks, in individuals, with 95% t intervals. Each block uses the same eight source policies across all cells. Lowering the threshold at 48 founders changed the food effect by -7.67 (-9.57, -5.77) with same-age founders and -8.10 (-10.37, -5.83) with staggered founders. Increasing the founder count at threshold 120 changed it by -5.10 (-7.12, -3.08) and -2.89 (-4.73, -1.04), respectively. At threshold 80, the density-change intervals include zero. The paired density-by-threshold interaction was 6.04 (3.22, 8.85) for same-age founders and 4.05 (1.22, 6.88) for staggered founders.

The detailed cell estimates show the earlier pattern in the 48-founder, threshold-120 setting: with same-age founders, the mixture contrast was -4.18 under original food and +3.35 under limited food. At 96 founders and threshold 80, it was -1.15 and -0.37. The full set of cell, tick-800 and time-change estimates and bootstrap sensitivity intervals is in `results/summary.csv`. The 95% intervals are not adjusted for the multiple planned contrasts; they should be interpreted together with the design and effect sizes, not as simultaneous confirmatory tests.

## Population stability

All 100 source populations remained at or above 20 individuals throughout, with minimum values from 47 to 74. At threshold 120, 5,286 of 7,200 assay runs fell below 20 at some tick. At threshold 80, 19 of 7,200 did so. Thus the threshold change also strongly changed the frequency of bottlenecks. This association does not establish that bottlenecks mediate the food effect: the threshold can directly alter reproductive timing, population composition and competition.

Of all 14,400 assay endpoints, 14,359 were viable, 40 weak and one extinct under `viability_report()`. Every run remains in the comparisons. No source or assay touched the 700-agent cap. The peak assay population was 648 on a 900-cell grid, so spatial crowding remains possible even without cap contact. Per-tick assertions checked one agent per cell. The 20-individual threshold is an operational definition of a population-size bottleneck, not a measure of genetic stability.

## Design and limits

For each seed, one source population was generated with 100 founders, reproduction threshold 80, haploid mutation SD .20, unique starting cells and a 700-agent cap. Its eight selected policies were reused in every assay. The assay crossed founder count 48 or 96, reproduction threshold 120 or 80, original or limited food, and fixed or staggered founder ages. Each cell contained a mixture and eight equal-density controls. Assay mutation was disabled. The source policies were held fixed across factors, so this isolates the effects of assay settings in this source-policy population; it does not test how changing the source-generation regime affects the result.

The food treatments change both initial grass and regrowth. The study cannot isolate those two components, establish the effect of bottlenecks separately from reproduction, or generalize automatically to other ploidies and biological systems. The design also holds the cap and source initialization at the newer setting, so it does not reproduce every aspect of the oldest experiment. The pilot used three separate source blocks and was excluded from the final 100-block analysis.

## Validation

The 432-run pilot passed population ledgers, matching, occupancy and independent summary reconstruction. The full campaign included 100 source simulations, 14,400 assays and 288,000 50-tick windows. A separate audit reconstructed all 84 summary means and checked physical-state and policy-panel matching and population balances. One hundred and twenty initialization assertions checked thresholds, other agent fields, ages, positions, food, RNG and policy identities. Source-state file checksums passed for all 100 blocks. The full run took 536.52 seconds on Totoro, with 24 workers, four Julia threads and one BLAS thread each. The simulation source, research-only patches, pilot and full data are retained alongside this report.
