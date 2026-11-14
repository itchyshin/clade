# A coordinated investigation of the policy-mixture advantage

The immediate result is a transient birth surplus followed by a death surplus in one matched policy-restoration experiment. A single mechanism has not been established. The studies below are a staged research plan, with stopping and validation checks, rather than a promise that every conceivable mechanism can be ruled out.

## 1. Consolidate the existing evidence

Reanalyse the matched-switch trajectories with age-specific births and deaths per agent-tick, resource use, policy frequencies and population density on the same time axis. Prespecify the main windows before reviewing any independent validation seeds. Agent-ticks describe exposure; birth eligibility and competing mortality require care when interpreting a rate. Check whether a small number of seed blocks drive the observed surplus. The current seed set is exploratory because it selected the tick-800 window.

## 2. Replicate and test environmental context together

Generate a seed-disjoint founder panel and first verify that populations are viable and that policies differ behaviourally. Cross food availability (original and limited) with founder age arrangement (same age and staggered). Within each of the four worlds, run equal-density policy mixtures and all eight corresponding single-policy controls using common seed blocks. Primary outcome: the mixture-minus-average-control population contrast at prespecified tick 800 and its change by tick 1,000. Report both absolute differences and uncertainty, retaining extinct and failed runs. This is 36 simulations per seed block; choose replication only after measuring pilot runtime, variability and feasibility. Avoid interpreting a pilot power estimate as proof of adequate power.

## 3. Test mechanisms with matched interventions

If the replication supports a time-dependent contrast, branch matched populations at tick 600 and apply a factorial policy-frequency-by-food intervention. Include the frequency-preserving same-individual shuffle and a sham food operation. Verify physical state and intervention exposure, and track resources, births, deaths, age, policy and density through tick 1,000. This tests whether food availability modifies the specific policy-restoration effect; it does not isolate all other features of the original mixture.

Demographic interventions need a separate design review. Directly resetting ages may create biologically implausible age–energy combinations; changing density may alter spatial crowding and food access at the same time. Start with matched-state designs that preserve each individual's viable state, explicitly state the resulting estimand, and pilot physical-state and conservation checks. Do not interpret adjustment for post-treatment age or density as a causal mediation analysis without additional assumptions or interventions.

## 4. Probe generality and biological meaning

Repeat key contrasts at more than one intervention time and across independently generated policy panels; compare clonal haploids with a separately validated inheritance and mutation setting. Measure parent-specific foraging, energy and reproduction alongside offspring survival, with explicitly defined event timing. Test whether policy composition changes the distribution of outcomes across environments, not just the grand mean. Preserve the distinction between artificial reassignment and natural evolution.

## Decision rules and compute

Use matched seed blocks as the independent units; define primary outcomes, intervals, relevant effect sizes and planned contrasts before each confirmatory run. Treat intermediate time points, age bands and additional mechanisms as exploratory or apply an explicit multiplicity strategy. Keep all seed denominators and viability verdicts, inspect extinctions, and reproduce natural trajectories with passive observers. Pilot on Totoro to estimate wall time and memory; stay within the shared core limit and record source hashes, execution receipts and failed runs. Decide whether to proceed to later stages from the evidence, feasibility and biological plausibility, rather than automatically running every combination.
