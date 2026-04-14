# Scenario report template

Used for the Phase 4 fix bundle. One `dev/audit/scenario_reports/<vignette>.md`
per scenario, generated when the audit diagnoses anything other than `OK` +
`NO_ORACLE`. Structure is fixed so the fix PRs read uniformly.

---

# `<s-name>.Rmd` — `<diagnosis>`

**Status.** One line: "<displayed chunk reproduces / does not reproduce>
the claimed signal."

## Biological hypothesis

One paragraph in plain prose: what the scenario *claims* the simulation
should show, and what the canonical biological result is. Cite the primary
reference (author year, journal or venue). Example pattern:

> The Baldwin effect (Baldwin 1896; Hinton & Nowlan 1987, *Complex Systems*
> 1:495–502) predicts that within-lifetime learning can *canalise* genetic
> variation: alleles that place an organism's genome nearer the
> learnable target are favoured, so the population's genotypic variance
> for the learned trait narrows even though no direct genetic selection
> for the trait is applied.

## Parameter regime in the literature

Bullet list of the parameter values the canonical experiment used, plus
scaling notes (grid size, generations, learning-rate / mutation-rate
balance). This is the "what should work" anchor.

## Observed in clade

- **Displayed specs:** `max_ticks`, `n_agents_init`, flags, seed — verbatim
  from the Rmd chunk.
- **Rerun result:** early-vs-late mean of the oracle metric, observed
  direction, effect size.
- **Figure caption claim vs data:** one line quoting the caption and one
  line stating what the trajectory actually did.

## Why the signal is absent or wrong

Diagnosis from the five buckets — pick one primary reason and (optionally)
list secondary contributors:

- **TOO_SMALL** — `max_ticks`/`n_agents_init`/generations below the regime
  where the literature effect emerges. Quote the canonical scale.
- **GENERATOR_DRIFT** — displayed chunk ≠ generator-script specs ≠ "What
  we found" prose specs. List the specific mismatches.
- **BIOLOGY_BUG** — adequate parameters but Julia module produces wrong
  direction or magnitude. Point to the suspect function in
  `inst/julia/src/modules/<x>.jl` with a line reference.
- **MODEL_SIMPLIFICATION** — model lacks a mechanism the literature
  assumes (e.g. a fixed target, explicit fitness function, pedigree
  coefficient). Scenario should say so in "Caveats".
- **PROSE_OVERSTATED** — data and figure agree, "What we found" oversells.

## Proposed fix

Concrete diff-level actions:

1. Rmd chunk edit (line range, what changes).
2. Generator script (`vignettes/generate_figures.R` section) edit or
   replacement with `source()`-of-chunk.
3. PNG regeneration trigger.
4. `What we found` rewrite (bullet the new numbers).
5. `fig.cap` rewrite to match data, not hypothesis.
6. Test to add in `tests/testthat/test-scenario-signals.R`.

## Runtime note

Wall-clock to regenerate: `X s` at `max_ticks=N, n_agents=M`. Whether this
should be part of routine `devtools::build_vignettes()` or deferred to
`dev/audit/regenerate_figures.R`.

## References

APA-ish style, primary literature only. Include DOI or URL when available.

---

## Notes on writing these reports

- Be explicit about *direction* (up/down) and *magnitude* (≈X%) —
  never just "evolution occurred".
- When citing literature, prefer the original paper over reviews.
- If the effect's parameter regime is broad (e.g. any `r > 0` for
  Hamilton's rule), say so — don't fabricate narrow bounds.
- If you're not sure the reference matches the scenario, say so and mark
  the citation `[uncertain — please verify]`.
