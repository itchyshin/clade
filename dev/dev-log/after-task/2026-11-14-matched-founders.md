# After task: matched founder variation and offspring mutation

## 1. Goal

Separate starting inherited-weight variation from later mutation in a
matched-founder experiment on Totoro, then explain what each contributes.

## 2. Implemented

A private Julia initializer seam shares the canonical run_clade loop.
The experiment crosses three founder SDs, three offspring mutation SDs,
two movement costs and two exploration rules. Each cell has 100 shared
seed blocks. Fixed exploration is primary; heterozygosity-based
exploration is sensitivity. Initial model-state hashes include RNG state
and exclude treatment specs and empty logging buffers.

The analyzer checks the complete factorial design, trajectory keys,
matching, endpoint alignment and zero-variation controls. It calls the
actual R viability_report using exact minimum/time and endpoint statistics.
It reports all-seed population outcomes, conditional diversity, paired
mutation and founder contrasts, and a predeclared four-cell interaction.

## 3a. Decisions and Rejected Alternatives

Did not change mutation_sd public semantics or add a founder spec field.
Did not duplicate the tick loop. Reference founder scalar traits stay at
mutation SD 0.05, inactive when mutation_rate_evolution is false; only
founder alleles are rescaled. Fixed sigma avoids treating starting
heterozygosity-driven exploration as a pure weight-spread effect.

Did not code extinction as zero pairwise distance. Diversity needs at
least two agents, and paired diversity comparisons need eligibility in
both treatments. Both-viable results provide an additional sensitivity
analysis, without establishing a population-wide causal effect.

## 4. Files Touched

- inst/julia/src/Clade.jl: private initializer seam, public path unchanged.
- inst/julia/scripts/matched_founders.jl: runner and exact pairwise endpoints.
- inst/julia/test/test_matched_initialization.jl and test_matched_founders.jl,
  registered in runtests.jl: baseline parity, matching and control tests.
- dev/data/matched-founders/: pre-run plan, analysis, plotting, results and provenance.
- dev/dev-log/check-log.md and this report: validation and limitations.

## 5. Checks Run

- Full local Julia suite: 278 assertions passed, exit 0.
- Independent old-source comparison: five seeds, exact full returned-result
  equality against origin/main before the initializer seam, 5/5 passed.
- Live R boundary tests: entropy/extractor 41 and sensory snapshots 14 passed.
- Portable R suite: passed, 647 explicit Julia-gated skips, no failures or warnings.
- Local 72-run two-tick output and analysis smoke: passed.
- Totoro 72-run full-horizon pilot: all gates passed, 31.27 seconds, peak
  411648 KiB, Julia 1.10.0, single BLAS thread and four Julia threads.
- Local full package check, including vignettes: 0 errors, 3 warnings,
  5 notes. Warnings concern unchanged non-ASCII R files and undeclared
  optional NLMR/yaml dependencies. Notes include existing documentation
  findings and transient graft cache/top-level files; this is not a clean
  release check. No package source was changed to mask those findings.
- Totoro full campaign: 3600/3600 runs, 36 complete cells and 1200 matched
  hash blocks, all controls passed. Wall time 16:25.48, peak 429372 KiB.
  Source 07bc4949b9ff9fe64119335736897dbe7e960af8; exact commands, hashes
  and source archive are recorded in results/run.json.
- Independent raw-data audit: 26 checks passed, zero failures. Final
  outcomes: 193 extinct, 13 singleton, 3394 with N>=2; 39792 trace rows,
  including 238 post-termination rows with correct missing values.
- Separate-process Totoro replay: seed 10001 across all 36 conditions,
  all 19 fields in 36 run rows and all 9 fields in 396 trace rows identical.
- Final analysis and plot regenerated successfully. Scientific review
  confirmed the primary findings and required restricting founder
  attenuation to the low-cost world under both exploration modes.

## 6. Tests of the Tests

The missing private initializer failed before implementation. New tests
compare baseline output with canonical run_clade, check matched founder
states, zero-founder/zero-mutation invariance, positive-mutation offspring,
invalid inputs and rejection of existing output directories. Exact
pairwise distance also has an independently computed fixture.

A deliberately incomplete-world CSV was rejected by the analyzer's exact
Cartesian design check. The singleton summary addition was exercised by
rerunning the complete tiny output analysis.
The three-genome constant-vector fixture has pair distances 1, 3 and 2,
so its expected all-pair mean is exactly 2 without reusing kernel arithmetic.

## 7a. Issue Ledger

This is a follow-up to the corrected 500-run diversity campaign and user
approval for a matched-founder experiment. It does not reopen the resolved
sensing, group-defense or estimator fixes. No message to Bhavya was sent
for this experiment.

## 8. Consistency Audit

Public function signatures, spec fields, defaults and the R to Julia
boundary did not change. No roxygen, generated Rd, NAMESPACE or vignette
API edit was needed. The Core Contract and decisions log need no change.
The new README supplies the runnable example and interpretation boundaries.
No public feature release note is needed for this private research driver.

Searches: rg 'matched.founder|founder.*mutation|mutation.*founder' over the
experiment files; rg 'TODO|FIXME|not implemented|planned.*implemented'
over the same scope found no stale implementation claims. git diff --check
passed. Historical reports were preserved.

## 9. What Did Not Go Smoothly

An initial test compared normalized Float32 mutation to a Float64 literal;
it now checks the kernel's actual Float32 contract. Independent review
required fixed-exploration controls and complete Cartesian trajectory keys;
both were added before the campaign. Singleton frequency was promoted
from a derived count to a direct proportion with an interval.

The progress meter counts files, so two streaming CSVs cannot represent
3600-run progress. It now uses the final analysis receipt as a completion
flag; row counts provide actual progress. A transient graft cache was
included in the local package check and will not be committed.
The independent audit initially expected 360 founder-scaling strata;
the correct design has 1200. The checker was corrected and all checks rerun.

## 10. Known Residuals

These are two designed worlds, one BNN architecture, one horizon and one
set of other defaults. Genetic distance is RMS expressed inherited-weight
distance, not behavioural diversity or calibrated biological heterozygosity.
Common seeds match starts, not all future random events. Conditional
survival selection remains explicit. Biological calibration and fitness
benefits of mutation are not established.

At low movement cost, fixed-exploration founder F=.20 versus zero changes
final diversity by .2157 without mutation and .0230 at mutation SD .20,
with all 100 paired seeds. Usual exploration supports that pattern there.
At high cost only 0/900 fixed and 2/900 usual-exploration runs are viable;
the corresponding both-viable contrasts have no eligible pairs. Default
high-cost interaction uncertainty includes zero, so a universal founder
attenuation claim is unsupported. Full numbers and intervals are in
dev/data/matched-founders/findings.md.

The work is supplied in PR #204 for review, without merging or sending a
new message to Bhavya. The next scientific action is to assess behavioural
consequences in viable populations while controlling ploidy. No additional
simulation has been started.

## 11. Team Learning

A single public mutation parameter can confound initialization and ongoing
change. A matched-state intervention should hold scalar traits and RNG
state fixed, check the full state, and use the canonical loop. Hashes and
controls supplement targeted unit tests; they do not prove biological
realism. Direct founder contrasts are needed alongside mutation contrasts.

## 12. Cross-Product Coverage

The factorial study covers two movement costs, three founder SDs, three
mutation SDs and two BNN exploration modes, with 100 matched seed blocks
per cell. This does NOT cover other architectures, climates, sensing
rules, optional modules, mutation-rate evolution, longer horizons or
empirical calibration. Standard public initialization remains covered by
exact baseline parity and existing tests.
