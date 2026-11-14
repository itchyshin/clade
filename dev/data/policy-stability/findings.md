# Policy mixtures in a more stable population setting

The earlier tick-1,000 food pattern did not persist in the same form. In the earlier setting, moderate food limitation gave mixtures an advantage of 1.66 individuals with fixed founder ages and 2.16 with staggered ages. In the new setting, the corresponding estimates were -0.53 and -0.95, with 95% intervals that include zero. This does not establish equivalence, or prove that avoiding bottlenecks caused the difference: the new setting also changes founder density, source initialization, the reproductive threshold and the upper population cap.

| Food and founder ages | Tick 800 | Tick 1,000 | Change from 800 to 1,000 |
| --- | ---: | ---: | ---: |
| Original, fixed | -0.86 (-1.98, 0.27) | -2.05 (-3.47, -0.63) | -1.20 (-3.00, 0.61) |
| Original, staggered | -2.18 (-3.39, -0.96) | -0.06 (-1.18, 1.05) | 2.11 (0.38, 3.84) |
| Limited, fixed | -0.17 (-1.20, 0.85) | -0.53 (-1.53, 0.48) | -0.36 (-1.90, 1.19) |
| Limited, staggered | 0.92 (-0.16, 2.00) | -0.95 (-1.93, 0.02) | -1.88 (-3.51, -0.24) |

Values are the mixture population minus the mean of eight single-policy controls, in individuals, with paired 95% t intervals across 100 independent seed blocks. The last column is the paired change in the mixture contrast. At tick 1,000 the difference between limited and original food contrasts was 1.52 (-0.13, 3.17) with fixed ages and -0.89 (-2.45, 0.67) with staggered ages. At tick 800 the corresponding secondary contrasts were 0.68 (-0.81, 2.17) and 3.10 (1.66, 4.54). Multiple endpoints and food-by-age comparisons were examined without multiplicity adjustment. The tick-800 age and food findings are exploratory.

## How stable were the populations?

The independent test retained all 100 source populations and 3,600 assay outcomes. All 100 source populations stayed at or above 20 throughout, with minimum populations ranging from 42 to 81. Of the assay populations, 3,595 of 3,600 stayed at or above 20; the five exceptions reached minima of 16–19 and all later recovered. In 95 of 100 blocks, the source and all 36 assay populations met the every-tick threshold. Restricting analysis to these 95 complete blocks gave limited-food tick-1,000 contrasts of -0.49 and -0.91 for fixed and staggered ages, respectively. This is a selected sensitivity analysis, not the primary estimate.

All 100 source endpoints and 3,585 assay endpoints were classified viable by `viability_report()`; 15 assay endpoints were weak and none extinct. No source or assay touched the 700-agent hard cap at any tick. Peak assay population was 644 on a 900-cell grid, so crowding can still matter despite no cap contact. Every source and assay was checked for one agent per cell after each tick. The threshold of 20 is an operational population-size criterion, not proof that genetic or ecological diversity is stable.

## Design and pilot selection

The final world uses 96 assay founders, 100 source founders, a reproductive energy threshold of 80 and a 700-agent cap. The earlier world used 48 and 50 founders, threshold 120 and a cap of 500. Source founders now start in distinct cells; assay founders also start in distinct cells. Each mixture contains 12 copies of each of eight source policies; each control contains 96 copies of one. Fixed ages are all 50 and staggered ages cover 25–72 twice. Food treatments retain the earlier definitions: original initial grass .50 and regrowth .05, versus limited .25 and .025. These treatments change initial grass and regrowth together.

The candidate screens, their failures and the modified endpoint gate are recorded in `plan.md` and the pilot raw tables. In the first independent validation, all runs avoided the low-number threshold, but two finished one individual below the package's endpoint-viable cutoff. That validation failed the original all-viable endpoint gate. A revised gate of at least 95% viable assay endpoints was set and passed on a further independent five-block validation. The main experiment then used separate seeds 51001–51100, with no pilot blocks included.

These results concern this specific haploid clonal world. Altering the reproductive threshold can directly change birth timing and food competition; increasing founder density changes crowding. The experiment therefore tests whether the earlier pattern generalizes to a lower-bottleneck setting, rather than isolating a causal effect of bottlenecks. It also does not establish absence of food effects at other times or regimes.

## Validation

The final run used 100 source and 3,600 assay simulations on Totoro. An independent audit reconstructed all reported means and checked 72,000 50-tick population ledgers and matching of physical starts and policy panels. Per-tick assertions checked occupancy in source and assay populations. All 100 source-state SHA-256 checks passed. The 100-block run took 308.16 seconds with eight workers, four Julia threads and one BLAS thread each. Source code, research-only patches, screening data and receipts are retained alongside this report.
