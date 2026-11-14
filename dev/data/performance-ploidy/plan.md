# Foraging and reproductive performance at fixed ploidy

## Aim and controls

Replay the same 600 populations from the behavioural study: 100 matched
seed blocks20001:20100, mutation SD0/.05/.20, separately within haploid
and diploid-with-selfing regimes. Founder allele SD=.05, fixed BNNsigma=.5,
30x30 low-cost world,50 founders and1000 ticks; all other settings exactly
reuse BehaviourAssay.specs. Preserve the canonical tick loop. A private
passive observer must leave returned simulation results unchanged.

The earlier 600 endpoint brain archives are the common-garden subjects.
Compare new endpoint brains and initial hashes exactly with that archive.
Apply actual viability_report to new runs; retain all population outcomes,
with paired both-viable comparisons primary and eligible n explicit.
Mutation effects are interpreted within ploidy. Heterogeneity itself is
not manipulated independently of policy composition.

## Population performance, defined before execution

Primary time window is ticks501:1000; full1:1000 is sensitivity. Record
pre-action live N, grass mass and total energy immediately before and
after tick_agents!. With optional resource modules off, grass loss is actual
gross grass consumption. Energy change includes movement/idle cost, food
credit, cap losses and brain cost; it excludes later reproduction and
mortality. Use sums within each seed, not averages of tick-level ratios.

Primary rates: grass/agent-tick, net foraging-phase energy/agent-tick,
births per1000 agent-ticks. Observe env.n_births/n_deaths after logging,
before extinction break, because logged death counts omit the extinction
tick. Verify N_after=N_before+births-deaths. Record starvation, population
size and total births alongside rates; higher turnover is not fitness.

Secondary recruitment: births at501:900 (and1:900 sensitivity), with their
alive status exactly100 ticks after birth. Births after900 are censored,
not failed. Recruitment yield uses agent-time from the same eligible birth
window. These are cohort outcomes, not intrinsic lifetime reproductive rates.

## Common-garden consequences of endpoint policies

Use all brains from each prior viable endpoint population. For every brain,
reset a one-agent5x5 world before each independent trial: focal at centre,
energy40, age seen by brain50, body/metabolic size1, same movement/idle/brain
costs and fixed exploration. Place food at centre or one of four cardinal
neighbours, amounts .5 or20: ten equally weighted cases. Other cells empty,
no competitors, no grass growth during the one-step assay. Run the actual
canonical sense/forward/argmax/move/eat/cap/brain-cost tick_agents! phase.
Clear only the copied BNN sample cache each trial to ensure fresh draws.
Use64 trials per brain/case, shared trial seeds across mutation conditions;
source brains and their hashes remain unchanged.

Measure actual grass eaten and net energy change. The five-location panel
includes staying when food is at the focal cell. Richest-cell labels are
not rewards: max_bite2 caps intake. Compare the same ten cases with uniform
random choices as a descriptive reference, not an adaptive optimum.
Reassay the first10 blocks at256 trials on the same archived brains.
Numerical mean changes and their MCSE in the high-M paired gross-intake
contrast must each be below .003125 grass/trial (one-quarter of5% of the
uniform-panel intake .25). The paired bootstrap relative-change interval
classifications (above+5%,below-5%,within5%,or uncertain) must also agree
between64 and256 draws on the same first10 viable pairs, with identical
bootstrap resamples. Otherwise increase assay draws before claiming
practical benefit; no seed expansion is planned.

## Alignment and uncertainty

| Quantity | Measurement | Invariant |
| --- | --- | --- |
| Gross intake | grass_before minus grass_after | 0 <= intake <=2*N |
| Net foraging energy | energy_after minus energy_before | phase excludes births/deaths |
| Exposure | live pre-action count per tick | all acting agents counted once |
| Birth/death totals | after-tick counters | population conservation including extinction |
| Recruitment | recorded newborn IDs,alive at birth+100 | correct censoring at900 |
| Common garden | canonical one-agent tick with reset state | known-bias food fixtures and source immutability |
| Same populations | initial/endpoint hashes and prior totals | exact archive match |

Seed blocks are replicates. Report paired means, MCSE,t-based95% intervals
and n. For relative changes use paired seed-block bootstrap2000 draws of
ratios of cell means, with frozen analysis RNG. Primary high-M comparisons
are prespecified; moderate M and full-window results are secondary.
A practically relevant benefit requires the95% relative-change interval
to exceed+5% for common-garden gross intake or late birth yield, separately.
An interval wholly within[-5%,+5%] supports small changes on that assay
scale. This is a model reporting convention, not biological calibration.
Net energy and all continuous effects remain visible even when a label is
unavailable. Do not infer benefits of diversity itself from a mutation-
regime effect, or infer foraging ability from population intake alone.

## Execution

Local deterministic observer, conservation, food-cap, cache and clone tests
first. Totoro12-run pilot plus common garden, estimate under5 minutes.
Measure runtime and viability before600-run launch. Pin Julia1.10.0,
OPENBLAS_NUM_THREADS=1,JULIA_NUM_THREADS=4. Reuse saved endpoint states;
never rerun the older behavioural assay merely to create activity. Archive
source, raw sufficient statistics, per-birth cohort records, timings and
checksums. No simulations on GitHub Actions.

## Numerical refinement after the first precision check

The original64/256-draw assay failed its numerical gate in all four
comparisons (maximum paired numerical MCSE .00654 grass/trial). Its common
noise across all brains made population-average rewards unnecessarily
variable. Preserve those data and their failed precision receipt.

For this linear mean-reward assay, use independent trials across brain
indices, paired by index/case/repetition across mutation treatments.
This changes numerical variance, not the reward estimand; index pairing
is not biological matching of individuals. Do not alter the earlier
cross-bank behavioural-distance assay. Repeat all600 gardens at256 draws
and the first10 blocks at1024 draws, without repeating population dynamics.
Use stable collision-free bit-packed RNG keys and retain the same benefit
margin and precision/classification gates. Original simulation controls,
biological hypotheses, seed count and cohort definitions stay fixed.
Measured60-population256-draw time57.58s implies about13.5 minutes plus
compilation; conservative new-phase estimate20 minutes. This refinement
was recorded before examining its outcomes.
