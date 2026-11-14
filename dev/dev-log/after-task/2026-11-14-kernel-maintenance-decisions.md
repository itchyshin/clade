# After Task: Kernel ownership and mutation paths

## 1. Goal

Record Shinichi's 14 November ownership correction and answer the mutation
redundancy question in #111 from current source.

## 2. Implemented

The integrator owns both R and Julia work. The old Sergio reservation has
been removed from AGENTS.md. A short design note explains genome mutation
in prey reproduction and direct brain mutation in predator reproduction.

## 3a. Decisions and Rejected Alternatives

Retain both mutation paths. Their representations, inheritance rules and
architecture-specific state handling differ. Combining Gaussian noise
helpers would obscure those distinctions or change simulation behavior.

## 4. Files Touched

AGENTS.md, dev/design/mutation-paths.md, decisions.md, check-log.md and this
report. A source comment in genome.jl links the design note beside the
allele mutation helper. No executable code, test, generated help or public
signature changed.

## 5. Checks Run

Reviewed the active calls in genome.jl::meiosis and predator reproduction,
then all four implemented neural-brain mutate methods. git diff --check,
after-task structure check and prose check passed. The portable R suite
also passed in workflow run 43605037297 at f48ea70. A final source comment
was added after that run; PR checks are required on the updated head.

## 6. Tests of the Tests

No tests changed. Source call-path inspection answers this design question;
this change makes no numerical or behavioral claim requiring a new test.

## 7a. Issue Ledger

#111 can close with the documented distinction. #122 is historical reset
scoping; this change neither implements nor approves its proposed reset.

## 8. Consistency Audit

Searched `Sergio|Track A|Track B|coordination` in AGENTS.md and
`_mutate_weights|mutate\(` in Julia source. Active ownership statements now
agree. Historical notes and contributor credit were preserved.

## 9. What Did Not Go Smoothly

The obsolete ownership rule initially required clarification. Shinichi
explicitly removed that boundary, and the repository now records the change.

## 10. Known Residuals

Predator brain mutation and genome inheritance remain different from prey.
A future unification requires a separate biological decision and tests.
No package tests or simulations were run for this documentation-only change.

## 11. Team Learning

Check mutation call paths and representations before consolidating similar
function names. Keep current ownership separate from historical plans.

## 12. Cross-Product Coverage

Covered genome mutation and ANN, BNN, CTRNN and GRN brain mutation source.
This task does NOT cover biological validation of predator inheritance,
a v0.8 reset, or changes to any reproduction algorithm.

## Documentation and Review

The design note is linked in decisions.md and this check-log entry.
Self-reviewed factual documentation against the named source paths.
Perceived AI-like style 2/10, moderate confidence: concrete call paths and
explicit scope keep the report specific. Science and facts pass within
this source-review scope; references are repository paths. Exact-draft
benchmark completion check NOTASSESSED. Self-review, 14 November 2026.
