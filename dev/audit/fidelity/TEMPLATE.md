# Scenario fidelity report template

Copy this file to `dev/audit/fidelity/<scenario>.md` and fill every
section. Do not leave placeholders — a half-filled report is worse
than no report because it looks authoritative.

Companion runner: `dev/audit/fidelity/<scenario>.R` (deterministic,
multi-seed, writes figures to `figs/<scenario>.png`).

---

# Scenario: &lt;name&gt;

## 1. Theory

- **Primary source.** `<Author year, Journal, vol:pp, DOI>`
- **Core prediction (one sentence).** What the paper claims happens,
  in the same variables the code tracks. **Note:** this is typically
  a mean-field, non-spatial, non-evolving prediction.
- **Quantitative expectations.** Magnitudes, slopes, signs, time-to-
  effect. E.g. "heritability of body size should be 0.3–0.6 under
  stabilising selection" — the concrete bar this scenario is trying
  to clear.
- **Edge cases and null results the paper predicts.** Where the
  effect should NOT appear (useful for sanity checks).
- **Why the evolutionary ABM may differ from the math.** One or two
  sentences. clade evolves traits over generations; a mean-field
  paper does not. Predict the direction of the divergence and check
  the alifeR prototype before deciding the difference is a bug.

## 2. Implementation under audit

- **Relevant `default_specs()` flags** (copy values, not names only):

  ```r
  list(
    flag_a = <value>,
    flag_b = <value>
  )
  ```

- **R entry points** (file:line, short description).
- **Julia kernel files** (file:line, what they do differently from
  defaults when the flag is on).
- **alifeR R prototype reference** (`~/Documents/alifeR/`):
  - Relevant module: `alifeR/R/<module>.R` and `alifeR/src/<file>.cpp`.
  - Vignette discussion: `alifeR/vignettes/showcase.Rmd` §`<n>`.
  - **Behaviour documented in alifeR.** One sentence on what the
    prototype produces and why (often the package author has already
    written this). If you find an explicit "why this differs from
    theory" passage, quote it.
- **MATLAB base code reference.** *(pending: source not yet
  located; once located, mirror the alifeR cross-reference.)*
- **Formula fidelity.** Equation from the paper on the left, code
  from the repo on the right, match Y/N + note. Flag every
  discrepancy; do not paper over them. **Also flag any divergence
  between the clade Julia kernel and the alifeR R/C++ prototype** —
  these often pinpoint where intentional refactoring during the
  port changed semantics.

## 3. Run protocol

- **Seeds.** `seq(1L, 10L)` unless the scenario needs more.
- **Ticks.** Long enough for the predicted dynamics to resolve. Cite
  the paper's timescale.
- **Agents.** At least the paper's N; scale up only with a reason.
- **Sweep.** If a flag is on/off or a parameter is scanned, list the
  exact grid.
- **Exact command.** `Rscript dev/audit/fidelity/<scenario>.R`.

## 4. Observed dynamics

- **Summary table** (mean ± SD across seeds for each condition):

  | Condition | Metric | Tick 0 | Tick `T/2` | Tick `T` |
  |---|---|---|---|---|
  | ... | ... | ... | ... | ... |

- **Direction and magnitude vs theory.** State each prediction from
  §1 and whether the data supports it, with numbers.
- **Figure.** `figs/<scenario>.png` — what the reader should see in
  one sentence.

## 5. Verdict

Check exactly one. **Theory** here means the *evolutionary-ABM
extension* of the cited paper, not necessarily the strict mean-field
prediction; if those differ, justify the divergence by reference to
the alifeR prototype or to a clearly-stated mechanism (e.g. arms-race
equilibrium suppressing LV decline phase).

- [ ] **Matches theory.** Quantitative expectations in §1 are met
      within seed-level noise (or the documented evolutionary-ABM
      extension is met).
- [ ] **Consistent but underpowered.** Direction correct, magnitudes
      softer than §1. List what a larger run would need.
- [ ] **Contradicts theory — kernel bug.** Named file:line + short
      description of the bug. File issue.
- [ ] **Contradicts theory — vignette overclaim.** The code runs
      fine; the vignette's "What we found" prose is stronger than
      the evidence warrants. List the prose edits needed.
- [ ] **Contradicts theory — formula mismatch.** Code departs from
      paper equations. Name the equation and the departure.

Always include a **cross-reference table** in the report:

| Aspect | Theory (paper) | alifeR prototype | MATLAB base | clade Julia |
|---|---|---|---|---|
| `<aspect>` | ... | ... | ... | ... |

## 6. Actions taken

- **Vignette prose edits.** Path + one-line diff summary per edit.
- **Kernel changes.** Path + SHA of commit, or "deferred to 0.4.0"
  with reason.
- **Tests added.** `tests/testthat/test-<scenario>.R` if the
  scenario now has a runtime invariant worth locking in.
- **Commit SHA that closed this report.**
