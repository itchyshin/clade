# After task: Matched food and founder-age experiment

## 1. Goal

Separate food-regime and founder-age effects on the population advantage
of mixed policies in matched 1,000-tick simulations on Totoro.

## 2. Implemented

A six-cell factorial crosses three food regimes with fixed versus staggered
founder ages, separately by ploidy. Each of 100 matched seed blocks contains
one eight-policy mixture and eight balanced monocultures in every cell.
Food regime changes the mixture advantage; all age and food-by-age interaction
intervals include zero. The original-food haploid advantage at tick 300
reverses by tick 1,000. Findings include estimates and uncertainty.

## 3a. Decisions and Rejected Alternatives

Use absolute mixture-minus-control differences and matched differences of
those differences, with seed blocks as replicates. Keep every control and
population, including extinctions. The two limited-food regimes both start
at .25 grass probability, so their comparison isolates the regrowth change
within that setting. Original versus limited changes both initial food and
regrowth. Fixed age is 50; staggered ages 25:72 have mean 48.5. Do not call
this a fixed-mean age-variance intervention.

## 4. Files Touched

Research driver, age-treatment patch, initial-state checks, pilot and campaign
launcher, R analysis, independent audit, sensitivity/time-course analyses,
figure, findings and evidence are under dev/data/policy-factorial. The check
log and this report record the task. No public kernel, API or default changed.

## 5. Checks Run

The 108-run pilot completed in 53.80 seconds. All 36 pilot cases corresponding
to the preceding staggered limited-food study reproduce exactly. Forty-two
initialization assertions check ages, shared food, positions, policies, RNG
and ploidy across all food regimes. The 10,800-run campaign completed in
596.10 seconds on eight Totoro workers, each capped at four Julia threads and
one BLAS thread, within the 15-minute estimate.

The R analysis verifies all keys, 216,000 windows, demographic and exposure
balances and actual viability_report outcomes. An independent Python audit
reconstructs all ledgers and factorial means from raw tables. All 3,600 prior
staggered limited-food run rows and 72,000 window rows reproduce exactly.
The original-food fixed-age first 300 ticks match 1,800 earlier runs on
population, birth and death totals. All 600 source brain checksums pass.
Applying the saved patch to the pinned source produces the exact remote patch
hash. The plot was generated and visually reviewed.

## 6. Tests of the Tests

A two-seed synthetic fixture duplicated the pilot to exercise factorial
analysis and independent mean reconstruction; it is not biological evidence.
Removing one fixture run makes the complete-design guard fail. The previous
study's 370 Julia assertions remain source-bound to the unchanged kernel;
this task separately exercises the new age initializer and replay controls.

## 7a. Issue Ledger

No kernel defect or public-interface change was found. Source commit
2b6ea12 is the preceding policy-mixture experiment, with later documentation
under the separate policy-long branch. No collaborator message was sent.

## 8. Consistency Audit

Code, plan and findings use the same matched seed-block estimand and retain
all controls. All-nine viability counts accompany cell estimates; there is
no severe-food all-nine viable subset. Initial grass and regrowth are one
combined food regime in the original-versus-limited contrast; the two
limited regimes permit an additional regrowth-only comparison at fixed initial
grass. Exact stale search:
`rg 'age|regrowth|viable|interaction|1,000' dev/data/policy-factorial`.
No public vignette, package documentation or release note is needed for the
research-only experiment.

## 9. What Did Not Go Smoothly

The shared Totoro SSH master briefly refused new sessions while the campaign
continued. Its process completed within the bound and the existing master
later accepted access. A synthetic fixture first printed a hard-coded full
row count; the audit now prints observed counts. No raw simulation was
interrupted or changed.

## 10. Known Residuals

This does NOT isolate age variance at fixed mean age, or initial-food from
regrowth effects in the original-versus-limited comparison. Severe-food
factorial effects include collapsed populations, with no all-nine-viable
subset. No extrapolation is made to lifetime fitness, complementarity, other
source policies, worlds or times beyond 1,000 ticks. Secondary intervals are
unadjusted. No full package check was repeated for research-only files.

## 11. Team Learning

Fisher: compare matched mixture advantages directly, rather than interpreting
whether separate cell intervals cross zero. Gauss: reproduce prior rows and
verify initialization when altering a private assay. Rose: report time,
initial-food and mean-age differences when explaining a previous result.

## 12. Cross-Product Coverage

The research driver, isolated patch, checks, full raw tables, analysis,
figure, findings, check log and report cover this experiment. It does NOT cover public API development, CRAN release, other ploidies or a general
biological theory of diversity. The work builds on the earlier stacked
research branches and their separately reviewed evidence.
