# Food, reproductive threshold and birth timing in a lower-bottleneck world

## Main result

The earlier food-by-threshold population pattern was not clearly reproduced in this world. At tick 1,000, the interaction was +0.60 individuals for same-age founders and -1.39 for staggered founders. Their 95% intervals were -1.26 to +2.46 and -3.25 to +0.48, respectively. The intervals include zero, but do not establish that the interaction is absent.

For each source seed and treatment, the population contrast D is the mixture's population minus the average of eight single-policy controls. The food effect F is D under limited food minus D under original food. The reported interaction is F at reproductive threshold 80 minus F at threshold 120. Thus a positive interaction means that limiting food shifts the mixture contrast more positively at threshold 80 than at threshold 120.

| Founder ages | Food effect at threshold 80 | Food effect at threshold 120 | Interaction | Paired 95% interval for interaction |
| --- | ---: | ---: | ---: | ---: |
| Same age | +0.69 | +0.09 | +0.60 | -1.26 to +2.46 |
| Staggered | -1.47 | -0.08 | -1.39 | -3.25 to +0.48 |

The first two columns are effects on the mixture-minus-control population contrast, in individuals. Each interaction is calculated within each of 100 independent source blocks; the eight controls receive equal weight. The tick-200, 400, 600 and 800 interactions also had intervals spanning zero. These additional time points and the two founder-age analyses are unadjusted for multiplicity.

## Reproductive timing

The age accounting suggests a shift in where the interaction appears, even though the net population interaction is uncertain. For same-age founders, the interaction in the mixture-minus-control count of births to parents under 50 was -8.62, with an unadjusted 95% interval of -12.28 to -4.95. The corresponding contribution from parents aged 150 and older was +8.61, interval +3.60 to +13.61. With staggered founders the two estimates were -9.96 (-14.39 to -5.54) and +12.37 (+7.05 to +17.70). These are differences of differences in birth counts, not the numbers of parents who changed age at reproduction. They are exploratory age-band accounting components, with multiple comparisons; neither component establishes a causal pathway.

Among mixture individuals who first became eligible before age 50, the mean age at that opportunity was 19.2 ticks at threshold 80 with original food, 28.1 at threshold 80 with limited food, 25.3 at threshold 120 with original food, and 35.3 at threshold 120 with limited food, for same-age founders. These cohorts differ across treatments: for example, an average of 215 mixture individuals per run entered the first cohort, compared with 28 in the last. The figures describe those who reached eligibility before 50 and cannot be interpreted as the same individual aging under both conditions.

We followed 844,371 young-eligible individuals to their first birth, death or end of the run. The competing-risk analysis estimated the chance of birth within 50 ticks after first eligibility; it accounted for censoring and death as a competing event. In these no-block simulations, over 99% gave birth on the eligibility tick at each threshold. There were no deaths before birth or end-of-run censorings within the 50-tick follow-up, so the formal competing-risk adjustment had little opportunity to change this particular result. Threshold and food may affect whether and when young individuals become eligible, in addition to the waiting time after eligibility. No natural mediation effect is identified.

## How stable was the setting?

The candidate screen used 96 assay founders, a 700-agent cap and maximum lifespans of 250, 300 or 400 ticks, applying each lifespan equally to every assay treatment. The first candidate failed its preset endpoint viability criterion at threshold 120: 169 of 180 runs ended viable. The first passing candidate was lifespan 300: in the screen, 176 of 180 threshold-120 runs stayed at or above 20 and all 180 ended viable; a separate five-seed validation found 179 of 180 stayed at or above 20 and all 180 ended viable. Both stages had no cap contact at either threshold. The same source panels were used in all candidate settings. Lifespan 300 is a different world from the earlier 200-tick setting, so differences cannot be attributed to avoiding bottlenecks alone.

The final run retained all 7,200 assays. All 3,600 threshold-80 runs stayed at or above 20 agents and ended viable. At threshold 120, 3,523 of 3,600 stayed at or above 20; 3,598 ended viable and two ended weak. None crashed, became extinct or touched the cap. The dips were concentrated in limited food: with same-age founders, 836 of 900 runs stayed at or above 20, or 92.9%; with staggered ages, 887 of 900 did. Both original-food groups had 900 of 900 above the threshold. The source populations all stayed above 20, with minima from 44 to 77. The threshold of 20 is an operational size criterion, not a demonstration of ecological or genetic stability.

## Reproducibility and limits

The five-seed screen and independent validation used seeds separate from the 100 final source seeds. The initial fingerprint contains the genomic reproductive-threshold trait, so it legitimately changes between threshold arms. A second check reconstructed all 400 final starts after removing only that trait and verified the remaining physical and random state matched. All 100 source panels had eight distinct policies with positive behavioural disagreement, and panel hashes matched every assay. The no-block, 200-tick-lifespan replay matched ten fields in 36 earlier threshold-80 assays.

Independent reconstruction of pilot opportunity records checked cohort entries, parent ages, births and deaths, and tick-by-tick population histories. Aalen-Johansen results matched `survival::survfit` on 16 screen, 16 validation and 16 final run/cohort combinations. The final audit checked 844,371 cohorts, age-band birth totals, death ledgers, physical matching within thresholds and population conservation; the reconstructed normalized starts checked matching across thresholds. All 500 final raw-file and three compressed-summary hashes passed. No run was excluded from the population contrasts.

The food treatments change initial grass and regrowth together. Founder density and physical states match initially, but density, ages and policy frequencies may diverge after treatment. The lifespan change affects reproduction and survival directly. The study concerns these haploid clonal simulated populations, not a general claim about natural populations. The age-band findings are descriptive and cannot prove that age-specific reproduction caused a population interaction.
