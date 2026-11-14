# After task: behavioural consequences of mutation at fixed ploidy

## 1. Goal

Test on Totoro whether additional inherited-weight variation changes
individual behavioural policies, with ploidy and exploration controlled,
using viable populations for the primary comparisons.

## 2. Implemented

Private research driver uses the existing matched-founder initializer and
canonical simulation loop. It crosses mutation SD0/.05/.20 with fixed
haploid or diploid genomes, 100 matched seeds per cell. Diploid selfing
fallback prevents no-mate haploid offspring. Founder allele SD=.05 and
BNN sigma=.5 are fixed. No public API, defaults, spec or kernel-loop change.

The assay applies the actual sampled-weight ANN forward and argmax rule
to 48 frozen sensory contexts. Independent noise banks remove finite-draw
inflation of squared between-agent policy differences. Within-agent
independent-choice disagreement is reported separately. Integer sufficient
statistics permit an independent reconstruction of both metrics. Assay
calls preserve simulation RNG and brain states.

## 3a. Decisions and Rejected Alternatives

Did not equate population-wide action entropy or mean softmax outputs
with individual choice policies. Did not pool haploid and diploid effects:
ploidy also changes reproductive pathways and founder expressed variance.
Did not change default mate-failure biology. The explicit selfing option
provides fixed diploidy only for this experimental world.

Practical-importance labels require both a prespecified margin and a
fourfold-draw precision check on the same viable pairs. The margin is a
model convention without empirical ecological calibration. Failed or
nonviable seeds are retained in population summaries and never replaced.

## 4. Files Touched

- inst/julia/scripts/behaviour_assay.jl: experiment, common-context assay,
  endpoint state archive and reassay.
- inst/julia/test/test_behaviour_assay.jl and runtests.jl: arithmetic,
  choice-rule, immutable-state and fixed-ploidy controls.
- dev/data/behaviour-ploidy/: plan, analysis, plot, findings, evidence and review.
- dev/dev-log/check-log.md and this report: commands and limitations.

## 5. Checks Run

- Local Julia1.10.12 full suite:295 assertions pass, exit0.
- Six-run two-tick local output/analysis smoke passes. The first fourfold
  reassay fixture has only one seed and correctly leaves importance flags
  unset rather than treating insufficient replication as a positive result.
- Totoro Julia1.10.0 pilot:12 runs,21.60 seconds,peak440732 KiB,exit0;
  all12 viable, all four founder blocks matched, endpoint ploidy fixed.
- Full study source7a2d78b9fa4efbd6f6ab5553f00f0422491ffa80. Single BLAS
  thread and four Julia threads, visible25-minute estimate before launch.
- Full study:600/600 runs and200 matched founder blocks passed, all600
  viable, all28800 context rows complete. Main run6:16.18, peak466712 KiB;
  fourfold endpoint reassay44.87 seconds, all four precision checks pass.
- Independent raw-data audit reconstructs every context B/W and run mean,
  verifies actual viability and all paired contrasts. All100 seed pairs
  are retained in each contrast. Integer totals conserve N times draws.
- Exact separate-process seed20001 replay reproduces every19 fields in
  six run rows and every20 fields in288 assay rows on TotoroJulia1.10.0.
- Proportion intervals use exact binomial limits. For100/100 successes,
  lower95% bound independently checked against .025^(1/100), rather than
  the misleading all-success t interval[1,1].
- Compressed raw sufficient statistics and source/endpoint-state checksum
  manifests are saved. Full endpoint brain states remain on Totoro for
  reassay without rerunning population dynamics.

## 6. Tests of the Tests

Constructed opposite-choice brains give between-agent distance1 and
within-agent disagreement0. Cloned brains give exact between-agent0 even
with stochastic exploration. Opposed independent banks produce a negative
estimate in a fixed fixture, confirming the implementation does not clip
finite-draw values. Canonical offspring tests retain haploid/diploid
structure, including diploid no-mate selfing fallback. Invalid replication
and input-count paths fail as expected.

## 7a. Issue Ledger

This user-approved experiment follows PR204, now merged after all checks
settled green. New work is PR205. Main after PR204 also passed its own R check,
coverage and pkgdown deployment. No message to Bhavya was sent.

## 8. Consistency Audit

Public R syntax, defaults and the single R to Julia boundary are unchanged.
No roxygen, generated Rd, NAMESPACE, vignette or release-note edit is needed
for this private study. The README gives a runnable example. The design
uses existing specs and calls the actual R viability_report. Source and
figures describe marginal independent-choice probabilities, with no claim
of temporal personality repeatability or adaptation.

## 9. What Did Not Go Smoothly

The default local Julia launcher points to a missing1.10.0 installation;
used installed+1.10 locally without changing global tooling. Totoro remains
pinned to1.10.0. A misspelled action_epsilon spec emitted a warning in the
first test and was corrected before deployment. Independent review found
that importance flags needed an explicit precision gate and that reassay
eligibility must match both-viable pairs; both were corrected before
interpreting full results. The numerical fixture exercises insufficient
replication as well as the successful metric controls.
Scientific review found the all-success proportion intervals needed
binomial bounds; corrected and checked before packaging. Tiny error bars
made R arrows emit zero-length warnings, so figure intervals use segments.

## 10. Known Residuals

One low-cost world, one BNN architecture, fixed exploration and one horizon.
The 48 contexts are a frozen assay distribution, not the frequency of
contexts encountered in nature. Ploidy groups differ in reproduction and
founder expressed variance; cross-ploidy differences are not a pure
copy-number effect. Viability-conditioned contrasts can select populations.
The operational margin is not empirically calibrated. No behavioural
fitness benefit, adaptation or personality trait has been established.

The full study supports large mutation-regime effects on endpoint policy
heterogeneity in both ploidy regimes. High mutation increases B by .2146
in haploids and .1517 in diploids, each with100 viable matched pairs and
intervals above the .00625 operational margin. It also reduces conditional
repeated-choice disagreement while sigma stays fixed. Mean final counts
are lower under high mutation, so no performance benefit is claimed.
Full values and uncertainty appear in the findings report. PR205 contains
the reviewable code and evidence; no further simulation has been launched.

## 11. Team Learning

Large population action entropy can coexist with nearly identical
individual policies. Measure between-individual choice probabilities and
within-individual noise separately. Use the source action rule, frozen
shared contexts, noise shared across treatments, independent banks and
unchanged simulation state. Save sufficient statistics so numerical claims
can be checked without trusting the production analysis script.

## 12. Cross-Product Coverage

Two fixed-ploidy regimes by three mutation levels,100 seeds per cell,
48 contexts and a prespecified endpoint-only numerical sensitivity check.
This does NOT cover alternative environments, architectures, learning,
heterozygosity-driven exploration, other founder spreads, longer horizons
or biological calibration. No additional campaign has been started.
