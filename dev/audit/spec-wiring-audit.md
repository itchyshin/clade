# R↔Julia spec wiring audit (post-0.7.0)

Generalises the 0.6.4 incident ([`release(0.6.4)`](https://github.com/itchyshin/clade/commit/bd97234)),
in which `mate_choice_mode` and `mate_choice_strength` were defined in
R's `default_specs()`, R-tested, and vignette-cited for two releases —
but the Julia kernel never branched on them. The R-side test suite
caught the *shape* but not the *semantics*.

## Method

For every field in `default_specs()` (304 total), grep
`inst/julia/src/` for `"field_name"` as a string literal (the
canonical `get(specs, "name", default)` pattern). Fields with zero
occurrences are candidates; each is then triaged by inspecting the
relevant module and the R-side declaration.

Script: `/tmp/spec_audit.R` (not committed; reproducible from this
report).

## Headline numbers

| Category | Count |
|---|---:|
| Spec fields total | 304 |
| Used by Julia | 292 |
| **Suspect (zero Julia occurrence)** | **12** |
| Confirmed unwired (after triage) | 11 |
| False positive (used via different name) | 0 |
| R-only / legitimately not in Julia | 1 |

The 0.7.0 work added ~30 new spec fields and all of them passed the
audit (good — they were tested at write time). The unwired fields
predate the 0.7.0 work.

## Findings

### A. Brain architecture over-claim (severity: significant)

The package DESCRIPTION states clade provides *"one of six brain
architectures (Bayesian neural network, multilayer perceptron,
continuous-time RNN, gene regulatory network, transformer, or
symbolic rule synthesis)"*, and `R/clade-package.R:46-55` describes
all six as if they exist. In reality, only four are implemented:

| Brain | Julia file | Status |
|---|---|---|
| BNN | `inst/julia/src/brains/bnn.jl` | implemented |
| ANN | `inst/julia/src/brains/ann.jl` | implemented |
| CTRNN | `inst/julia/src/brains/ctrnn.jl` | implemented |
| GRN | `inst/julia/src/brains/grn.jl` | implemented |
| **Transformer** | — | **missing** (`Clade.jl:594` reads `transformer_heads`/`transformer_history` but there's no `transformer.jl`) |
| **Synthesis** | — | **missing** (`Clade.jl:600` comment: "placeholder; replaced in a later phase") |

`R/config.R:104` acknowledges this in passing ("reserved for future
development phases") but the DESCRIPTION and clade-package.R don't.

Spec fields involved:
- `transformer_history` — read in Clade.jl but consumed by no brain
- `transformer_heads` — same
- `synthesis_max_rules` — not even read in Julia

**Recommendation**: correct the DESCRIPTION to say "four brain
architectures" + a note about reserved future types; align
clade-package.R; keep the spec fields (cheap placeholders for the
eventual implementation).

### B. `world_evolution` module disabled (severity: significant)

`inst/julia/src/Clade.jl:93` contains the line
`# include("modules/world_evolution.jl")` — commented out. The
companion R-side flags exist:

| Spec | Default | Status |
|---|---|---|
| `world_evolution` | `FALSE` | flag exists, never actually enables anything |
| `world_mutation_sd` | `0.02` | unused |
| `world_params_to_evolve` | `character(0L)` | unused |

`R/run.R:23` has a docstring mentioning `world_evolution = TRUE`
behaviour that cannot occur in the current kernel.

**Recommendation**: either (a) restore the include line and verify
the module still works, or (b) delete the three spec fields and the
docstring claim. Decision depends on whether world-evolution is a
near-term goal.

### C. Senescence model only half-implemented (severity: minor)

`inst/julia/src/death.jl:37` consumes `senescence_rate` for the
Gompertz curve `p = 1 - exp(-r · aging_rate · exp(r · age))`. But the
2-parameter Gompertz family also takes a shape parameter, declared
on the R side but unused:

| Spec | Default | Used? |
|---|---|---|
| `senescence_rate` | `0.0` | ✅ death.jl:37 |
| `senescence_shape` | `2.0` | ❌ never read |
| `repro_senescence` | `0.0` | ❌ never read |

`R/config.R:1078` block-comments "Senescence shape (Gompertz)" but
the Gompertz code in death.jl doesn't take a shape parameter.

**Recommendation**: either (a) extend death.jl to use
`senescence_shape` as a true 2-parameter Gompertz, or (b) delete the
two spec fields and the block comment. `repro_senescence` is a
distinct concept (reproductive senescence vs survival senescence) —
if not planned, delete.

### D. `plasticity_cost` defined but unused (severity: minor)

`inst/julia/src/modules/plasticity.jl` exists and implements phenotypic
plasticity, but does not consume `plasticity_cost = 0.05` from specs.

**Recommendation**: read R-side intent for whether plasticity is
supposed to incur an energy cost. If yes, wire it into plasticity.jl.
If no, delete the spec.

### E. `parental_investment_init_mean` orphaned (severity: minor)

R block-comment says "Parental investment evolution":
```r
parental_investment_evolution = FALSE,
parental_investment_init_mean = 0.5,
```

But the Julia module is `parental_care.jl` and gates on
`specs["parental_care"]`. There's no `parental_investment` consumer
anywhere.

The `_evolution` flag is also unused. So the entire 2-spec block is
unwired.

**Recommendation**: clarify whether "parental investment evolution" is
a distinct planned feature from parental_care, or a renamed/aborted
attempt. If aborted, delete both fields and the block comment.

### F. `log_genomes` flag unwired (severity: minor)

`env.genome_log::Vector{Any}` exists in the Environment struct
([types.jl:479](inst/julia/src/types.jl)) and is exported as
`genome_log` in `_agents_to_records` (Clade.jl:782). But no code
populates it. The R-side spec `log_genomes = FALSE` toggles nothing:

- `R/visualization.R:533` shows a placeholder "Enable log_genomes =
  TRUE to see genome structure" — but enabling it produces no data
  because the field is never populated.

**Recommendation**: implement the population logic in
`inst/julia/src/logging.jl` (push to `env.genome_log` per
`log_freq` ticks when the flag is on), or delete the flag and the
placeholder UI.

### G. `wall_density` / `wall_clusters` vestigial (severity: trivial)

R block-comment "Map generation (walls/barriers)" but neither
`R/maps.R` nor any Julia file reads these. The `generate_map()` and
`prepare_map()` functions in R generate landscapes via the
`complex_landscape` mechanism, not via wall fields.

**Recommendation**: delete both spec fields and the block comment.

### H. `life_history_evolution` flag unwired (severity: trivial)

Only mentioned in a comment in `types.jl:211`:
> "reproduction (may differ from specs when life_history_evolution = true)"

No code branches on it.

**Recommendation**: delete the flag and the comment, or wire it.

## Suggested fix prioritisation

Tier 1 (user-facing claims that mislead):
- A: Brain architecture DESCRIPTION (CRAN-blocker if we ever submit)

Tier 2 (significant unwired features):
- B: world_evolution module disabled

Tier 3 (cleanup, low impact):
- C: senescence_shape / repro_senescence
- D: plasticity_cost
- E: parental_investment_*
- F: log_genomes
- G: wall_density / wall_clusters
- H: life_history_evolution

## Followup-PR scaffold

A clean follow-up PR titled "fix(0.7.x): remove unwired spec fields
+ correct brain-architecture overclaim" would:

1. Edit DESCRIPTION + clade-package.R to say "four brain architectures"
   (Tier 1).
2. Either implement or delete each Tier 2 / Tier 3 item — one commit
   per concern, matching the Karpathy surgical-changes discipline.
3. Add a `tests/testthat/test-spec-wiring.R` that runs this audit
   programmatically on every test run, so a future spec field added in
   R without a Julia consumer is caught immediately.

The test in (3) is the structural fix that turns "spec wiring" from a
manual audit into a permanent guard. That's the generalisation of
the 0.6.4 lesson.

## What this audit does NOT cover

- Whether each field is consumed by the *correct* Julia module (only
  whether it appears anywhere).
- Whether the values are biologically calibrated.
- Whether the default values match the cited literature.
- Modules added in 0.7.0 (personality, reciprocity, responsiveness) —
  all their fields passed the audit, but their semantic correctness is
  what the vignettes assert, not this audit.
