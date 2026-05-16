# Cousin-hunts: items 6 + 8 (deferred-fix follow-ups)

Deferred fixes from Phase A items 6 and 8 ran as a single cousin-hunt
session (2026-05-16, `claude/cousin-hunts-items-6-8`).

## Item 6 hunt — "Pre-0.X.Y guard added, no regression test landed"

Flagged in item 6 (viability_report) audit. Originally estimated as
~40 candidates via `rg "Pre-0\\." R/`. Actual result:

```sh
$ rg -n "Pre-0\.[0-9]" R/
R/analysis.R:1114:  # Pre-0.7.0, viability_report flagged every small-population test as
```

**Just 1 hit**, and it's the viability_report Pre-0.7.0 comment that
item 6 *already* added the regression test for (flat-pop bypass tests
in `test-analysis.R`). Class is empty; no further work needed.

I also broadened the scan (`(added in|since |\\b0\\.[0-9]+\\.x[: ])`)
and got zero additional hits. The "Pre-0.X.Y guard" pattern is rare
in clade; item 6's flag was based on a different version-annotation
style (`# 0.7.0:` etc., which are spec-field-addition markers, not
behaviour-guard markers, and which are already covered by the
existing `test-spec-wiring.R` drift guard).

**Item 6 cousin-hunt: closed clean.**

## Item 8 hunt — "Documented default value disagrees with code value"

Flagged in item 8 (preset family) audit. Originally estimated as
~50 candidates via `rg "default[s]? \\d" R/*.R`. The cousin-hunt
script at `/tmp/cousin_hunt_item8.R` (and committed conceptually as
part of this audit) extracts every `\item{<field>}{... default X ...}`
claim from `R/config.R`'s `default_specs()` `@details`, then compares
the claimed value against `default_specs()[[field]]`.

### Scan results (pre-fix)

- 214 `\item{...}` entries parsed.
- 214 of them carry a "default X" claim.
- **22 mismatches between claim and code.**
- 0 claims for fields not in `default_specs()` (good — PR #129's
  drift-guard makes that condition impossible).

### Real vs false-positive

| Field | Claimed | Actual | Status |
|---|---|---|---|
| `bnn_sigma_init` | 0.1 | 0.5 | real |
| `plasticity_mutation_sd` | 0.05 | 0.03 | real |
| `plasticity_sense_radius` | 1L | 3L | real |
| `predator_min_repro_age` | 20L | 5L | real |
| `predator_live_energy` | 0.5 | 2.0 | real |
| `female_investment` | 1.0 | 0.7 | real |
| `male_repro_cost` | 0.0 | 0.3 | real |
| `helper_tendency_init_mean` | 0.2 | 0.1 | real |
| `helper_tendency_mutation_sd` | 0.05 | 0.02 | real |
| `helper_transfer` | 3.0 | 5.0 | real |
| `helper_kin_threshold` | 0.125 (= half-siblings) | 0.25 (= full-siblings) | real (value + biological-meaning annotation also wrong) |
| `helper_min_energy` | 60.0 | 80.0 | real |
| `stress_mutation_multiplier` | 5.0 | 3.0 | real |
| `signal_drift_sd` | 0 | 0.01 | real |
| `signal_evolution_drift` | "Numeric ... default 0" | `TRUE` (logical) | real (**type AND value** mismatch — docstring's whole framing was wrong) |
| `signal_memory_rate` | 0.1 | 0.3 | real |
| `toxin_dose` | 2.0 | 30.0 | real |
| `avoid_threshold` | 0.3 | 0.5 | real |
| `habitat_preference_mutation_sd` | 0.05 | 0.03 | real |
| `isolation_threshold` | 0.45 | 0.5 | real |
| `canopy_threshold` | 0.6 | 0.15 | real |
| `random_seed` | (regex caught "0" by accident) | NA_integer_ | **false positive** (docstring is "NA_integer_ uses a random seed (default)" — "default" annotates NA_integer_, not 0) |

**20 real mismatches + 1 type-mismatch (signal_evolution_drift) + 1 false positive** = 21 real fixes, all in `R/config.R`'s `default_specs()` `@details`.

### Fixes shipped

All 21 docstring corrections applied to `R/config.R`. Direction:
**code is the source of truth** (matches the item 8 PR's convention
where `ultra_realistic_specs` docstring was updated to match the
code value 500L). Particularly notable:

- `helper_kin_threshold` had both value (0.125 → 0.25) AND
  biological-meaning annotation (`= half-siblings` → `= full-siblings`)
  wrong. Fixed both — the actual default 0.25 IS the full-sibling
  relatedness coefficient.
- `signal_evolution_drift` had a complete type-mismatch — docstring
  said "Numeric ... default 0" but code is a `Logical` toggle
  (`TRUE`). Rewrote the description as "Logical. If `TRUE` (default),
  apply inter-generational drift to the inherited signal at the SD
  given by `signal_drift_sd`. Set `FALSE` to disable signal drift
  entirely."

### Verification post-fix

- `Rscript /tmp/cousin_hunt_item8.R` → 0 real mismatches; only the
  random_seed false positive remains (regex limitation).
- `devtools::document()` regenerated `man/default_specs.Rd` cleanly.
- `test-config.R`, `test-specs.R`, `test-presets.R`,
  `test-spec-groups-coverage.R`, `test-test-field-assertions.R`:
  all green.

### Why this matters

Item 8's deferred-fix flagged these as "the kind of finding that
would confuse a user reading the rendered help page." Users
reading `?default_specs` would have seen, for example,
`female_investment` documented as "default 1.0" but received 0.7
when calling `default_specs()$female_investment`. Same for the
other 20 fields. All such gaps are now closed for the
`default_specs()` docstring.

The four other fidelity-script-audited spec functions
(`quick_specs`, `full_specs`, `fast_specs`, `realistic_specs`,
`ultra_realistic_specs`, `slow_specs`, and the three paper
presets) are already covered by the documented-values tests
added in items 8 and 11+12+13. So if anyone updates those
preset functions' code without updating the docstring, the
existing test suite will catch it.

For `default_specs()` itself, there's no test that asserts the
docstring matches the code — the drift-guard for SPEC_GROUPS
(PR #129) catches *missing* fields but not value mismatches.
Adding a Rd-vs-code value-comparison test would close this loop
structurally — the cousin-hunt script in /tmp/ is the prototype.
Worth a follow-up.

**Item 8 cousin-hunt: closed clean for default_specs() docstring;
structural follow-up flagged.**

## Cumulative session-level take

The "documented value disagrees with code" class found 20 instances
in `default_specs()`'s `@details` alone — a single function. The
class deserved the cousin-hunt; the result substantially improves
the rendered help page for the most-used function in clade.

The "Pre-0.X.Y guard without regression test" class was overstated
in the item 6 flag — the actual count is 1 (already covered) and
the broader version-annotation pattern (`# 0.7.0:` style) is
spec-field-addition, not behaviour-guard, and already protected by
`test-spec-wiring.R`.
