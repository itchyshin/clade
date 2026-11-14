# After task: Behavioural variation and performance

## 1. Goal

Test whether mutation-associated behavioural differences improve foraging and
reproductive performance, controlling founder variation, ploidy and exploration,
using viable populations on Totoro.

## 2. Implemented

A corrected-source 600-run campaign compares three mutation SDs within each of
two fixed ploidies, with 100 matched founder blocks. All 600 runs are viable.
High mutation gives small intake and birth-yield gains but lower offspring
survival, smaller final populations and worse standardized net energy gain.
The primary food/birth intervals lie inside the prespecified +/-5% margin.
Detailed estimates and interpretations are in dev/data/performance-ploidy/findings.md.

## 3a. Decisions and Rejected Alternatives

Use a passive observer in the shared canonical Julia loop, with no extra
R/Julia crossings. Assay actual tick_agents! food and energy changes instead
of softmax scores. Use independent trial noise across endpoint brains, paired
by numerical index across treatments, to estimate mean reward efficiently.
Keep the existing independent-bank behavioural estimator unchanged.

The performance investigation exposed a missing reproduced-flag reset. Repair
was isolated in PR #207 and merged with targeted regressions. Generate all 600
populations and their own brains again after that fix. Reject reuse of legacy
endpoint brains or numerical claims as corrected iteroparous evidence.

## 4. Files Touched

inst/julia/src/Clade.jl adds private observer phases. The performance_assay.jl
driver, targeted Julia tests, analyze.R, plot.R, replay.jl and run_totoro.py
implement the campaign and checks. dev/data/performance-ploidy contains the
protocol, findings and source-bound evidence. check-log records outcomes.
The separate reproduction fix updated R/Julia docs, NEWS and historical
qualifications, as recorded in its own after-task report.

## 5. Checks Run

- Full combined Julia suite: 342 assertions pass, exit0, before campaign.
- Corrected full-horizon six-run pilot: 24.52 sec, 474480 KiB peak, all 6 viable.
- Corrected full 600 with four isolated 25-seed workers plus precision reassay:
  392.13sec wall; each worker 4 Julia threads, 1 BLAS thread. Execution commands,
  per-process memory/timing and source b982e9739c1064224ca49f77ff56d06ec8e0c7c4
  are bound in results/run.json and execution.json.
- Rscript dev/data/performance-ploidy/analyze.R OUTDIR 100: all design,
  conservation, cohort, food/energy and reconstructed policy checks pass;
  actual viability_report 600/600 viable; four 64/256 precision gates pass.
- Independent raw audit: 600 runs, 1,200 windows, 574,476 cohorts, 6,000 garden cases,
  28,800 policy contexts,600 reassay cases pass. Separately resampled contrasts
  agree, allowing finite bootstrap differences.
- Separate-process seed 20001 replay: all fields exactly equal in 6 run,
  12 window, 5,658 cohort, 60 garden and 288 behavior rows. Canonical death ledger
  agrees with 5,658 births; observation-disabled same-initializer control agrees
  in all 6 cells. Initial invalid control and corrected logs remain archived.
- Rscript dev/data/performance-ploidy/plot.R OUTDIR: figure generated and
  visually checked for labels, clipping and uncertainty interpretation.
- Earlier live R life-history 29 assertions pass with 2 existing viability
  warnings; entropy 41 and sensory 14 checks pass. No new public R API.

## 6. Tests of the Tests

Deterministic food-policy fixtures verify caps, brain-cache resetting and
actual energy costs. The oracle earns five times the uniform-policy intake.
Extinction and censored cohorts exercise failure/boundary paths. Observer
parity compares full canonical results; packed RNG keys pass 40,960 uniqueness
checks. The reproduction regression failed before repair, with 1 episode
versus 3 expected. Independent raw ledgers and death records validate measures
without relying on reported summary columns.

## 7a. Issue Ledger

The reproduction defect is fixed and merged in #207. Legacy 600 performance
and failed numerical gates are preserved separately. Corrected 600 supersede
those results. No message to Bhavya was necessary for this experiment.

## 8. Consistency Audit

R/Julia biological defaults and public signatures are unchanged by the
performance observer. The reproduction fix has its own decision, generated
docs and historical qualifications. No new vignette or pkgdown page is needed
for this research-only campaign; README gives runnable commands. No Core
Contract row changes. Exact stale-claim search:
`rg 'legacy|corrected|same.*brain|PASS|5%' dev/data/performance-ploidy`.
Historical protocol entries remain as history, with a corrected-source
supersession. Planned mixture-transplant experiment is explicitly unrun.

## 9. What Did Not Go Smoothly

Initial common noise across all brains gave poor numerical precision; those
failed outputs were retained. A six-population independent-noise probe
preceded the kernel discovery. No full legacy refinement was launched.
The initial cohort analyzer rebuilt string groups repeatedly; cached group
indices fixed that analysis cost without changing simulation outputs.

The corrected replay helper first compared matched founders with default
founders, failing at mutation 0/.20. Diagnosis showed same-initializer equality
true at all three levels and default equality true only at .05. Correcting
the validation control fixes that error; campaign source/data are unchanged.
The final helper checksum is recorded separately from simulation source.

## 10. Known Residuals

This does NOT cover lifetime fitness, adaptation across environments, causal
benefits of heterogeneity itself, or demographic equivalence. Mutation changes
both policy spread and composition; realized rates include density/age effects.
The one-step garden removes density differences but is deliberately short.
Secondary intervals are exploratory and unadjusted. First-ten precision checks
do not bound numerical error separately for every endpoint. Julia serialized
states have no cross-version guarantee. No full local R package check was
repeated after evidence-only edits; exact-head CI is the package-wide gate.

## 11. Team Learning

Fisher: require viable paired populations, aligned cohort exposure and an
explicit practical margin before performance claims. Gauss: canonical
observation must use identical experimental initialization in parity tests.
Rose: source changes require new populations and renewed claims, while raw
legacy artifacts and failed checks remain inspectable.

## 12. Cross-Product Coverage

Kernel observer, tests, research driver, raw tables, analysis, plot, README,
findings, check-log and after-task report cover this task. This does NOT cover public API expansion, CRAN submission or release work. PR #206 carries the
reviewable campaign. Next experiment proposed in findings would compare
policy mixtures at standardized density; it awaits a separate user decision.
