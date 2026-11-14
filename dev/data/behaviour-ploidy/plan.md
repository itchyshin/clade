# Behavioural effects of mutation with fixed ploidy

## Goal and finite acceptance

Test whether additional inherited-weight variation changes persistent
between-agent action policies, separately within fixed haploid and fixed
diploid populations that pass the actual viability_report. Run on Totoro.
Deliver complete raw run/context summaries, paired uncertainty, assay
controls, exact source and timing, replay and an after-task report.

## Design fixed before pilot

Use the preceding low-cost world: grid30x30, 50 founders, 1000 ticks,
move_cost1, grass_max20, min_repro_energy120, energy_init70, stochastic
grass, per_cell radius1, BNN fixed sigma0.5. Learning and optional modules
remain off. Founder allele SD is fixed at .05. Cross ploidy1/2 with
mutation SD0/.05/.20; use 100 independent seed blocks20001:20100, shared
across cells: 600 runs. Diploid self-fertilization fallback is enabled to
prevent no-mate haploid offspring. Assert founder and endpoint structures;
unit-test the canonical offspring paths. No kernel loop changes are needed.

Complete initial-state hashes must match across mutation treatments within
each ploidy/seed block. Ploidy also changes reproduction and founder
expressed variance, so mutation contrasts are interpreted within ploidy.
The experiment does not isolate chromosome copy number as a causal effect.

## Symbolic assay alignment

For agent i, context x and action a, define
p_i,a(x)=Pr[argmax ANN(mu_i+sigma_i*z,x)=a], z~N(0,I).
This matches the kernel's argmax after sampled-weight forward pass.
It is not the mean of the ANN softmax vector.

Use 48 equally weighted contexts: energy .25/.75, age .25/.75, six grass
patterns (empty, full, one rich cell in each cardinal direction), and
occupancy all-empty/all-occupied. Bias=1. These are physically possible
11-slot radius1 inputs, frozen before outcomes are inspected.

Primary B=mean_context mean_distinct_pair sum_a(p_i,a-p_j,a)^2/2.
Use two independent noise banks A/B, shared across agents, to estimate
squared differences by cross-products. With count vectors cA/cB from R
repetitions per bank, B_x=[N*sum_i dot(cAi,cBi)-dot(sum_i cAi,sum_i cBi)] /
[N*(N-1)*R^2]. Do not truncate negative finite-draw estimates.
Within-agent stochasticity W_x=1-sum_i dot(cAi,cBi)/(N*R^2), estimated
separately. Secondary: pairwise disagreement of noise-free argmax(mu)
actions. Saved context sufficient statistics permit independent recovery.

| Target | Source/operation | Verification |
| --- | --- | --- |
| Same founders across M | MatchedFounders.trial, F=.05 | full state hash |
| Fixed ploidy | existing ploidy + selfing fallback | genome checks and offspring tests |
| Actual choice rule | canonical make_ann_brain/forward then argmax | direct constructed-weight fixture |
| Persistent policy differences | independent-bank cross-product B | clones zero; opposite biases B=1 |
| Within-agent randomness | independent-bank disagreement W | constructed fixtures |
| Viable outcomes | R viability_report | retain all runs, paired viable primary |

## Precision and meaning

Start with 64 repetitions per bank. Fresh independent assay noise for
each seed block; identical banks across mutation treatments in that block.
Assay RNG is separate from the simulation; copied/read-only brain values
and RNG-state hashes must be unchanged. Save endpoint brain states on
Totoro for reassay without resimulation.

Primary contrast M=.20 minus0 within each ploidy, among pairs where both
runs are viable. M=.05 contrasts are secondary. Seed blocks, not agents
or contexts, are replicates. Report n, paired mean, MCSE and t-based95%
intervals. All-seed survival, final N and viability remain visible; do not
replace excluded seeds. If viability is poor, report that finding and
avoid a behavioural success claim.

A prespecified practical margin is deltaB=.00625. From B=0 this corresponds
to RMS five-percentage-point differences per action: sqrt(2B/5)=.05.
Call a mutation effect operationally meaningful only if its paired95%
interval exceeds this margin. This is an assay convention, not a validated
ecological importance threshold. Report continuous effects regardless.

Reassay the first10 seed blocks in all6 cells with fourfold draws on the
same endpoint populations; compare paired conclusions and Monte Carlo
error, using the same both-viable first10 pairs. Threshold flags remain
provisional until both draw settings give the same interval classification
(above/below/uncertain relative to the margin), with mean numerical change
and its MCSE each below one-quarter of the margin. If this check fails,
increase draws before
making the threshold claim. No data-dependent seed expansion is planned.

## Pilot and routing

Local deterministic tests first. Totoro pilot2 seeds/cell, full1000 ticks,
including assay and viability. Estimate under5 minutes from the prior
simulation campaign plus repeated forward passes; measure before scaling.
Then state a full-run estimate. Pin Julia1.10.0, single BLAS thread and
four Julia threads. Stop and re-estimate on budget overrun. Canonical
archive stays in ~/sim-archive/clade; no simulations run on GitHub Actions.
