# Young-parent reproduction dose-response pilot

## Finding

Restricting early reproductive opportunities led many individual parents to reproduce later. A complete block before age 50 removed all births in that age band, while total births fell much less. This demonstrates a compensating response to this intervention in these simulated worlds. It does not establish that naturally varying age-specific reproduction causes the earlier food-dependent population pattern.

Five new source seeds supplied 900 matched assays on Totoro. Each source contributed a mixture and eight balanced monocultures at two food levels and two reproductive thresholds. Each world was run at five doses. All founders began at age 50, and the young gate applied to descendants and any other agents younger than 50. Cells shared their initial physical state and source panel; later trajectories were free to diverge.

| Opportunities blocked below age 50 | Mean young-parent births per run | Mean total births per run | Later birth within 50 ticks among observed first-blocked parents |
| --- | ---: | ---: | ---: |
| 0% | 249.7 | 868.9 | Not applicable |
| 25% | 245.5 | 865.3 | 98.3% |
| 50% | 236.0 | 863.3 | 97.9% |
| 75% | 217.0 | 858.0 | 96.8% |
| 100% | 0.0 | 835.6 | 92.6% |

Birth counts are equally weighted over the 180 runs per dose. The 100% count compares 835.6 with 868.9 total births, a 3.8% decline, despite the loss of all young-parent births. These pooled descriptions are not independent replicate-level confidence intervals. Five source seeds are the independent units.

For the 100% dose, 27,787 of 29,994 parents with an observed 50-tick outcome reproduced after their first blocked opportunity; 132 others were censored by the end of the simulation. All 27,787 later births occurred at age 50 or older. Among those who did reproduce, the mean delay was 23.2 ticks. The percentage is descriptive: early births are observable even for parents near the end, whereas parents without enough remaining time are censored. It should not be treated as an unbiased survival estimate. In individual source panels the corresponding percentage ranged from 91.9% to 93.5%.

In this group, mean parent energy was 100.5 at the first blocked opportunity, 141.5 immediately before the later birth, and 70.7 at the end of that birth tick. The blocked decision is made before reproductive cost; in these runs energy at the end of a blocked tick equalled energy at the gate on average. These observations are consistent with retaining energy and accumulating more before a later birth. Changes across ticks include feeding, metabolism and other processes; they do not isolate a reproductive cost or prove what would have happened to the same parent without blocking.

For the mixture with threshold 80 and original food, mean total births fell from 1,400.0 to 1,315.6 at 100% blocking, while final population changed from 120.8 to 121.8. The paired five-seed final-population difference was 1.0 with an exploratory 95% t interval from -12.0 to 14.0. This small pilot cannot establish equivalence or resolve the earlier food-by-threshold mixture contrast. That contrast varied across the five seeds and doses without a consistent dose-response.

## Checks and limits

All 900 assay endpoints met the earlier viability criterion; 340 dipped below 20 individuals at least once. All five source runs reached tick 1,000, had minimum populations of 43 to 65, and supplied eight distinct policies with positive deterministic behavioural disagreement. No outcomes were excluded.

A separate sham replay used prior source seed 71001. All 36 matching runs agreed with the preceding experiment on physical and panel hashes, final tick and population, minimum population, exposure, births and deaths. The independent Python audit checked 1,609,561 opportunity records, including replay, all keyed decisions, birth and death totals, parent follow-up and initial matching. The first follow-up analysis erroneously treated some missing future events as tick-1001 births; this was fixed, boundary fixtures were added, and the audit was rerun. Raw event, death, run and source files remain on Totoro at the path in `results/raw-data.json`; their checksums are in `results/raw.sha256`.

The gate acts after age, energy and cap eligibility, before local-space, mate and cost checks. A blocked opportunity is not necessarily a foregone birth. The pilot covers only young-parent blocking, haploid clonal policies, equal-age founders, and the tested food and threshold settings. Density, ages and random trajectories can change after intervention. The reproducibility study and any stronger causal claims require more independent source seeds and a prespecified viable operating range.
