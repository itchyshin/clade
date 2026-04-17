# Cross-scenario crash audit at fast_specs (2026-04-17)

Using the new `viability_report()` utility, ran 17 scenarios × 5 seeds
× 2000 ticks at `fast_specs()` to check which are viable at the faster
timescale.

## Verdict counts

| Category | Count | Scenarios |
|---|---|---|
| **Crashed** (mean frac_final < 0.20) | 4 | body_size, signals, parental_care, stress_hypermutation |
| **Weak** (mean frac 0.20–0.50)       | 9 | baseline, disease, speciation, niche, life_history (both), group_defense, seasonal_short, seasonal_long |
| **Viable** (mean frac > 0.50)        | 4 | cooperation, scavenging, kin, clutch_size |

## The 4 crashed scenarios

These scenarios produce `n_final ≈ 0` at fast_specs — any trait-mean
audit at these parameters is meaningless. The common factor is an
extra mortality pressure (predation, costly signals, parental-care
cost, scarce grass) stacked on top of the already-short fast_specs
lifespan.

| Scenario | Cause of crash | Fix |
|---|---|---|
| body_size | body-size mutation load at short lifespan | use default_specs in vignette |
| signals | signal-cost × sexual selection at short lifespan | use default_specs |
| parental_care | care_cost_per_tick × short lifespan | stays default_specs (already correct) |
| stress_hypermutation | grass_rate = 0.05 × short lifespan | use default_specs |

Vignettes for body_size, signals, parental_investment, and
stress_hypermutation were silently switched to `fast_specs()` in the
2026-04-17 morning commit (`d4c5280`) and have now been reverted to
`default_specs()` with matching max_ticks. The scenario figures were
*not* regenerated at fast_specs by the morning commit — they were
generated at default_specs by earlier audit runs — so the figures
themselves are not crash-driven. Only the vignette demo-chunk *claim*
was mismatched.

## The 4 viable scenarios

These grew populations at fast_specs (mean frac_final > 0.5, and two
even *exceeded* initial population count). Safe to use fast_specs in
vignettes and audits:

- **cooperation** — 1.72× init. Cooperation evolution doesn't constrain
  viability; in fact the cooperative-breeding-like dynamics boost
  survival.
- **clutch_size** — 1.79× init. Fast reproduction under clutch_size
  evolution feeds growth.
- **scavenging** — 0.54× init. Carrion supplements grass-limited
  energy.
- **kin** — 0.58× init. Kin altruism energy transfers buffer
  individuals.

## The 9 weak scenarios

These remain viable (n_final ≥ 20) but populations shrink to
20–50% of init. Audit results at fast_specs are *probably* OK but
should be checked case-by-case with `viability_report()`. The
"weak" verdict is a warning, not a disqualifier.

- `baseline`, `disease`, `niche`, `group_defense`: generic-ecology
  scenarios with no extra mutation load — populations shrink
  proportionately but don't collapse.
- `life_history_sem`, `life_history_ite`, `speciation`: evolutionary
  scenarios where the trait under audit imposes modest cost but not
  enough to crash.
- `seasonal_short`, `seasonal_long`: seasonality at amp=0.35 is
  survivable but suppresses carrying capacity.

## Recommended workflow update

When writing a new audit script:

```r
env <- run_alife(specs)
vr  <- viability_report(get_run_data(env),
                        n_agents_init = specs$n_agents_init)
if (vr$verdict == "crashed") {
  stop("Run crashed — trait means are meaningless. ", vr$message)
} else if (vr$verdict == "weak") {
  warning("Run weak (n_final < 50% of init). Interpret with care. ",
          vr$message)
}
# ... only now interpret trait means
```

For batch audits, log the verdict vector across all runs, not just
the "passed" count.

## Future kernel work suggested by this audit

1. **body_size / signals viability at fast_specs.** These scenarios
   fail because mutation load × short lifespan overwhelms viability.
   A scenario-specific "body_size_cost" trait that could evolve
   downward when fast reproduction is selected would resolve this.
   (Not currently exposed.)
2. **stress_hypermutation × fast_specs.** `grass_rate = 0.05` is
   uncrossable at fast_specs. Either the scenario needs to live at
   `default_specs` permanently, or a `starvation_resistance` trait
   would need to evolve before the stress-hypermutation signal can
   emerge.

These are recorded here rather than in `PRIORITY_ROADMAP.md` because
they are observations, not currently planned work.

## Body-size crash mechanism (diagnosed 2026-04-17 afternoon)

`dev/audit/fidelity/body_size_crash_diagnosis.R` ran a focused sweep
of the body_size × fast_specs interaction. Result:

| body_size_mutation_sd | crashed/5 | mean n_final | mean bs_final |
|---|---|---|---|
| 0.000 (no mutation)   | 0 | 39 | 1.00 |
| 0.005 (tiny)          | 1 | 25 | 0.99 |
| 0.020 (small)         | 4 | 17 | 1.02 |
| 0.050 (default)       | 5 |  5 | **0.53** |
| 0.100 (large)         | 5 |  3 | **0.49** |

Body-size evolution OFF: 0/5 crashed, n=35. Body-size ON + grass=0.35:
0/5 crashed, n=50.

**Root cause — asymmetric foraging correction for small agents.** In
`inst/julia/src/modules/body_size.jl`, `apply_body_size!` charges
small agents (`bs < 1`) an energy correction of `eat_gain × (1 - bs)`
every tick they foraged, to refund the "over-credited" grass gain.
But this correction is not capped by the eat_gain received — so when
`bs ≈ 0.5`, the correction is `5 × 0.5 = 2.5`, which exceeds the
typical per-tick eat gain on cells with low grass.

Under fast_specs (short lifespan, moderate grass), body_size mutation
drives some lineages small. Small agents foraging on medium-grass
cells end up net-negative energy per tick. They starve, shrinking
population, reducing selection power to push size back up — death
spiral. Equilibrium at `bs ≈ 0.5` and `n_final < 10`.

**Kernel-polish candidate**: clamp the small-agent correction so
`energy_after_correction >= energy_before_eat`, i.e. eating can give
zero net energy but never net-negative. Small change in
`apply_body_size!`, prevents death-spiral dynamics at any timescale.
Does not affect large-agent mechanics or the body_size P1/P2 audits
at default_specs.

Workaround for users who want body_size + fast_specs: set
`grass_rate >= 0.35` to push equilibrium grass density above the
small-agent loss threshold. Documented for future vignette variants.
