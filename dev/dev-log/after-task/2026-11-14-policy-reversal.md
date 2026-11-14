# After task: Policy frequencies and population reversal

## 1. Goal

Investigate the changing policy-mixture population advantage over time,
tracking policy frequencies, density and resources on Totoro.

## 2. Implemented

Replayed 100 haploid seed blocks, each with one mixture and eight controls,
for 1,000 ticks with exact policy-identity, demographic and food tracking.
The advantage oscillates rather than reversing once. Policy frequencies
concentrate and age structure shifts. Fewer births explain the arithmetic
of the decline from tick 600 to tick 1,000. The matched higher-regrowth
intervention changes transient dynamics but has no clear endpoint effect.
Findings provide estimates, uncertainty and causal limits.

## 3a. Decisions and Rejected Alternatives

Track exact haploid clonal policies with mutation disabled; do not extend
this label to diploid recombination. Keep the original monoculture
benchmark and all seed blocks. Use the composition-associated accounting
identity as descriptive evidence only. Double regrowth while matching the
physical starting state and policies, but do not treat the total intervention
as an isolated food, density or selection mechanism. Add a separate passive
pre-reproduction age/energy observer; readiness is a threshold proxy, not
a guarantee of birth.

## 4. Files Touched

Research drivers and launchers, analyses, independent checks, raw traces,
figures, findings, protocol and provenance live under dev/data/policy-reversal.
The check log and this report record the task. Public kernel, defaults and
API are unchanged. Drivers build on the prior private mixture assay.

## 5. Checks Run

Original trace: 900 runs, 100.47 seconds. Higher regrowth: 900 runs,
152.29 seconds. Pre-reproduction age replay: 900 runs, 90.31 seconds.
Each used eight Totoro workers, four Julia threads and one BLAS thread per
worker, within its stated eight-minute bound. Pilot timing was under a minute.

The original observer reproduces all 18,000 earlier windows on population,
births, deaths, exposure and food. Exact inherited policy identities are
checked at every birth and checkpoint. The age replay reproduces all 144,000
original trace rows exactly. Higher-regrowth raw checks cover 18,000 windows,
144,000 policy rows, policy/population ledgers, cap bounds and identical
physical starts. Independent matched-effect calculation reconstructs all
2,000 regrowth block means. The actual R viability verdict classifies all
900 higher-regrowth runs viable. All 600 source brain hashes pass.

## 6. Tests of the Tests

The one-seed baseline independently reproduces all 180 previous windows.
The capacity-instrumented high-regrowth pilot reproduces every field of its
un-instrumented predecessor. The age pilot reproduces all 1,440 baseline
rows exactly, then full replay repeats that check across every seed. Raw
ledger checks establish count/exposure conservation; the descriptive
composition terms independently sum to the original mixture advantage.

## 7a. Issue Ledger

No public-kernel bug was found. The shared SSH master twice refused new
sessions; the existing connection later recovered. No worker was interrupted.
The preceding research PRs remain separate dependencies; no collaborator
message was sent.

## 8. Consistency Audit

Food rate, density, policy diversity, age/readiness and demographic results
use the same 100 matched blocks and mean-of-eight-control benchmark. The
regrowth intervention has a separate source hash and exact matched starting
states. Original versus high regrowth changes downstream density, composition
and early cap exposure, so the endpoint comparison is a total regime effect.
No public vignette or release note is needed. Exact search:
`rg 'policy|density|birth|cap|causal|regrowth' dev/data/policy-reversal`.

## 9. What Did Not Go Smoothly

The initial high-regrowth pilot hit the 500-agent cap. A second pilot added
cap monitoring without changing any earlier trace fields. In the full run,
250 of 900 groups hit the cap for 2,596 of 900,000 run-ticks, all by tick 150.
The 32 cap-free seed blocks give an imprecise selected sensitivity. A shared
SSH session-limit failure temporarily delayed data retrieval, and a command
chain attempted analysis before the missing data arrived; the analysis was
rerun successfully after retrieval. No failed output was treated as evidence.

## 10. Known Residuals

This does NOT isolate causal effects of policy frequencies, density, age
structure or food from one another. The high-regrowth intervention changes
multiple downstream states and can have early cap effects. Frequency-weighted
monoculture decomposition is arithmetic, not a causal mediation analysis.
Readiness is a checkpoint proxy rather than actual eligibility for a birth.
Findings cover one haploid clonal setting and times through tick 1,000;
recombining diploids, other worlds and lifetime fitness remain untested.
No full package check was repeated for research-only drivers.

## 11. Team Learning

Fisher: inspect the whole trajectory before treating two endpoints as a
permanent reversal. Gauss: track exact clone identity and validate passive
observers against the same source. Rose: distinguish food intake from standing
resources and report early cap history in environmental interventions.

## 12. Cross-Product Coverage

The three research drivers, raw traces, source binding, independent audits,
analysis, figures, findings, check log and report cover this experiment.
It does NOT cover public API work, release, recombining diploid lineages,
or a general causal theory of diversity. Further manipulation of policy
frequencies or density would require an explicit, separately validated design.
