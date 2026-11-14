# After task: Equal-density policy mixtures

## 1. Goal

Test whether behavioural policies benefit from living together, using equal-
density groups and balanced single-policy controls on Totoro.

## 2. Implemented

Each of 600 corrected source populations supplies eight uniformly sampled
policies. Compare 48 founders containing six copies of each policy with eight
48-founder monocultures. The per-seed contrast subtracts the mean of all eight
controls; the 100 source seed blocks per cell provide independent replication.
The 50 tick primary assay enforces equal density and disables reproduction.
The 300 tick secondary assay follows canonical reproduction and offspring
survival, including density feedback and diploid recombination.
Findings and numerical intervals are in dev/data/policy-mixture/findings.md.

## 3a. Decisions and Rejected Alternatives

Preserve starting energy 70 and use 50 ticks, rather than increase energy for a
longer fixed-density assay. All founders are age 50, with shared scalar traits,
food, unique positions, exploration sigma.5 and initial RNG. Source brains
become synthetic haploid or homozygous diploid genotypes with mutation 0.
No original endpoint genome recovery is claimed.

Reject dropping failed monocultures or counting them as independent seed
replicates. The comparator always needs all eight. Main summaries retain all
blocks with defined outcomes; full-nine viability is a separate sensitivity.

## 4. Files Touched

Added mixture_assay.jl and test_mixture_assay.jl; included targeted tests in
Julia runtests.jl. dev/data/policy-mixture contains plan, research commands,
analysis, plotting, replay, findings and evidence. check-log and this report
record the work. Kernel code, public defaults and R API are unchanged.

## 5. Checks Run

Full Julia suite 370 assertions pass, including 28 new mixture assertions.
Pilot 108 runs:28.10 sec,535964 KiB peak, exit 0; all 54 primary worlds viable at
exactN 48. Secondary 48 viable,5 weak,1 crashed, all retained. Missing-control
fixture fails the analyzer's completeness check as intended. Invalid source
pin now fails before launching workers. Full 10,800 runs complete in 398.45 sec. Independent audit passes 37,800
windows, 2,178,703 births and 2,229,971 deaths. All 5,400 foraging groups are
viable at constant density. Demography has 5,042 viable, 214 weak and 144
crashed worlds. Independent block estimates agree to floating-point precision; n, mean and
MCSE agree across all 240 summary rows. All twelve primary intervals are within their
practical margins. Full results and hashes are in results/run.json.

Exact separate-process pilot replay reproduces all six raw tables:
108 runs,378 windows,21649 births,22270 deaths,6 panels and 48 policy rows.
All 24 observer-on/off controls pass with identical experimental initialization.
Every trial checks cohort survival against canonical death records.
No cross-platform bitwise-reproduction claim follows.

## 6. Tests of the Tests

The new test first fails with the missing implementation. Construction tests
check exact balanced copy counts and reject nondivisible or undersized inputs.
Identical-policy mixtures and monocultures reproduce the same full result.
Physical hashes, unique positions, ploidy, brain/genome equality, source
immutability, constant density, conservation and censored/dead cohorts are
checked independently of summary estimates. The incomplete-data fixture
proves that a missing comparator cannot be silently averaged away.

## 7a. Issue Ledger

No kernel defect was found or changed in this task. Previous performance
PR206 was accepted by the user and merged after its exact head's five green
checks; main R checks, coverage and site passed. No collaborator message
was needed. The mixture experiment remains a separate focused PR.

## 8. Consistency Audit

Code and protocol implement the same mixture-minus-eight-control estimand.
All metrics use seed-level replication; rate means give equal weight to each
world instead of pooling unequal exposures. No Core Contract change or
public vignette is needed for a private research driver. README provides
commands and evidence pointers. Exact stale-claim search:
`rg 'equal|balanced|viable|mutation|fitness|100|300' dev/data/policy-mixture`.

## 9. What Did Not Go Smoothly

Pilot analysis initially used strict integer/double identity and treated
lowercase Julia booleans as R logicals. Correcting those parser checks made
the unchanged pilot data pass. Full-run dynamics used the validated driver.

The launch passed a non-SHA revision label to the wrapper metadata argument.
The archived source, driver and executed wrapper hashes independently match
commit2e8a30f3932c297c09db106181f7615e4194f3c6 locally and on Totoro.
Original execution.json is retained unchanged, with source-binding.json
explicitly recording the metadata error and verified source identity.
The final wrapper rejects malformed pins before starting workers. Useful
simulation work was preserved; no output was changed to fix a label.

## 10. Known Residuals

This does NOT cover general benefits of genetic diversity, long-term fitness,
or effects across resource worlds. The primary comparison isolates living
together relative to this balanced benchmark, conditional on sampled policies
and the specified world. The secondary phase additionally changes density,
policy frequencies and diploid offspring combinations. Initial policy
composition is exactly balanced overall, not at every specific grid position;
assignment is randomized independently. Serialized sources require the recorded
Julia version. Missing survival rates and selected viability denominators
remain explicit, without dropping a failed control from its benchmark.

## 11. Team Learning

Fisher's design review identifies the 100 seed-block contrasts as the units of
replication and separates equal-density foraging from demographic feedback.
Gauss checks identical initialization and pure observation through full-result
parity. Rose records source identity through actual archives and file hashes,
including metadata mistakes, rather than treating a supplied label as proof.

## 12. Cross-Product Coverage

The research driver, targeted Julia checks, raw tables, R analysis, figure,
replay, audit, README, findings, protocol and check-log cover this experiment.
This does NOT cover new public APIs, kernel changes, release/CRAN work,
other brain architectures or a general theory of diversity benefits.
The completed results are ready for scientific review before choosing another
world or a longer-term experiment.
