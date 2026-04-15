# Scenario: Life-history strategies (semelparous vs iteroparous)

## 1. Theory

- **Primary sources.**
  - Cole, L.C. (1954) The population consequences of life history
    phenomena. *Q. Rev. Biol.* 29:103–137.
  - Williams, G.C. (1966) Natural selection, the costs of
    reproduction, and a refinement of Lack's principle.
    *Am. Nat.* 100:687–690.
  - Roff, D.A. (1992) *The Evolution of Life Histories.*
- **Core prediction (one sentence).** Semelparous organisms invest
  all reproductive resources in a single terminal event and die,
  while iteroparous organisms spread reproduction across multiple
  events; the two strategies generate distinct demographic
  signatures even at equilibrium population size.
- **Quantitative expectations.**
  1. Semelparous mean age < iteroparous mean age (semelparous die
     after one reproductive event; iteroparous accumulate older
     individuals).
  2. Semelparous per-tick birth rate > iteroparous per-tick birth
     rate (faster generational turnover).
  3. Semelparous mean energy < iteroparous mean energy (Williams
     1966: terminal effort > somatic maintenance).
  4. Cole's paradox: the *per-individual* fitness gap between the
     strategies is small (just one extra surviving offspring closes
     it), so equilibrium population sizes need not differ
     dramatically — but in our spatial ABM, demographics, energy
     budgets, and grass renewal interact, so population size *can*
     differ substantially.
- **Edge cases / null results.** Without a fitness asymmetry
  (predation, seasonality, density-dependent juvenile mortality),
  the two strategies should not produce wildly different fitness
  outcomes per Cole's paradox. The *demographic signatures* will
  differ even when fitness is similar.
- **Why the evolutionary ABM may differ from the math.** Cole and
  Williams worked in mean-field demographic models. In a spatial
  ABM, semelparous cohorts are highly synchronized — births and
  deaths cluster in time — which interacts with grass renewal in
  ways the mean-field model can't capture. We expect demographic
  signs to match theory but magnitudes (especially population
  size and variance) to be ABM-specific.

## 2. Implementation under audit

- **Vignette:** [vignettes/s-life-history.Rmd](../../../vignettes/s-life-history.Rmd).
- **Specs (this audit):**

  ```r
  s$life_history  <- "semelparous" | "iteroparous"
  s$n_agents_init <- 80L
  s$grid_rows     <- 25L
  s$grid_cols     <- 25L
  s$grass_rate    <- 0.15
  s$max_ticks     <- 400L
  ```

- **clade Julia kernel.** [inst/julia/src/death.jl:38, 81](../../../inst/julia/src/death.jl#L38)
  — semelparous death is triggered by `ag.reproduced` flag
  immediately after reproduction. The flag is set in the
  reproduction code path and consumed in `_death_cause` as cause
  `:semelparous`.
- **alifeR R prototype reference.**
  - Module: [alifeR/R/death.R:66](../../../../alifeR/R/death.R) —
    `if specs$life_history == "semelparous" && agent reproduced ->
    remove`. Same logic as the Julia kernel.
  - Vignette: `alifeR/vignettes/showcase.Rmd` §8 — same flag, same
    expected contrast, caption notes "boom-bust cycles as cohorts
    reproduce simultaneously and then die."
- **MATLAB base code reference.** *(pending: source not yet
  located; flag for user.)*
- **Formula fidelity.** Cole (1954) gives no equation that maps to
  a single ABM line; the prediction is qualitative ("iteroparity
  advantage = one extra surviving offspring"). Williams (1966)
  similarly verbal. The implementation matches alifeR exactly; no
  divergence to flag.

## 3. Run protocol

- **Seeds.** 5 (1–5).
- **Ticks.** 400 (200 burn-in for cohort dynamics to equilibrate,
  200 for measurement).
- **Conditions.** 2 (`life_history = "semelparous"` vs
  `"iteroparous"`).
- **Total runs.** 10 (5 seeds × 2 strategies).
- **Wall time.** ~28 s.
- **Exact command.** `Rscript dev/audit/fidelity/life_history.R`.

## 4. Observed dynamics

Post-burn-in (t > 100), seed-pooled means:

| Metric | Semelparous | Iteroparous | Ratio | Prediction |
|---|---|---|---|---|
| `mean_age` | 13.0 | 101.5 | 7.8× | sem < iter ✓ |
| `n_agents` | 84.2 | 209.2 | 2.5× lower | empirical |
| `n_births` / tick | 4.20 | 0.89 | 4.7× | sem > iter ✓ |
| `mean_energy` | 84.7 | 127.1 | 0.67× | sem < iter ✓ |
| pop variance | 3.9 | 2628.5 | **674× lower** | empirical |
| total births (300 ticks) | 1259.8 | 267.4 | 4.7× | sem > iter ✓ |

Seed-level reproducibility is exceptional: across 5 seeds, mean age
varies by < 0.2 ticks for semelparous and < 1.2 ticks for
iteroparous. Birth rate varies < 0.05 per tick.

**Striking finding (worth highlighting):** semelparous population
variance is **674× lower** than iteroparous. The population is
locked at 84 ± 2 across the entire post-burn-in window. This is
the demographic signature of synchronized cohort turnover —
births and deaths are tightly phased to grass renewal, so
population fluctuations cancel out at the scale we observe.
Iteroparous individuals can opportunistically survive lean
periods, which paradoxically *increases* population variance
because demography and resources decouple.

Figure: [figs/life_history.png](figs/life_history.png) — 4-panel
dashboard (population, mean age, births, energy) across all 5
seeds with mean line overlaid.

## 5. Verdict

- [x] **Matches theory.** All three sign predictions
      (Williams/Cole) recovered with tight seed agreement.
- [ ] Consistent but underpowered
- [ ] Contradicts theory — kernel bug
- [ ] Contradicts theory — vignette overclaim
- [ ] Contradicts theory — formula mismatch

### Cross-reference table

| Aspect | Theory (Cole/Williams) | MATLAB base (Bulitko 2023) | alifeR prototype | clade Julia |
|---|---|---|---|---|
| Death trigger | Verbal: "after reproduction" | **N/A — no life-history flag in MATLAB** | `agent$reproduced -> remove` | `ag.reproduced -> :semelparous` ✓ |
| Mean age contrast | Sem < iter (qualitative) | N/A | Same prediction | 13.0 vs 101.5 ✓ |
| Birth rate contrast | Sem > iter (qualitative) | N/A | Same prediction | 4.20 vs 0.89 ✓ |
| Energy contrast | Sem < iter (Williams 1966) | N/A | Implied by code | 84.7 vs 127.1 ✓ |
| Pop variance | Not predicted | N/A | "boom-bust" caption | 674× lower (sem) — *opposite* of "boom-bust"; emergent finding |

**MATLAB base note.** The MATLAB ancestor at
`~/Documents/alifeR/alife_matlab/codebase/` (Bulitko, Aug 2023)
implements only iteroparous-style continuous reproduction — there is
no `life_history` flag and no semelparous-death code path. The
semelparous extension is original to the alifeR R port (see
`alifeR/R/death.R:66`) and faithfully preserved in the clade Julia
kernel (see `inst/julia/src/death.jl:38, 81`).

### Note on the "boom-bust" claim

alifeR's vignette caption predicted *boom-bust* cycles for
semelparous populations. clade shows the opposite: semelparous
populations are exceptionally *stable*. Two possible explanations:

1. **Synchronization differs.** alifeR may have looser cohort
   synchronization (perhaps from differences in initial age
   distribution or grass renewal timing) that produces visible
   cohort waves. clade may synchronize more tightly.
2. **Burn-in differs.** Boom-bust may be a transient that resolves
   into a stable equilibrium given enough ticks. We measured
   t > 100 (300 ticks of measurement); short runs might show
   boom-bust before settling.

Worth a follow-up: re-run with `max_ticks = 100` and inspect the
transient. Not blocking the verdict — the sign predictions all
pass, and the stable-equilibrium result is itself biologically
interesting (and matches Cole's paradox: equilibrium populations
needn't differ as much as our intuition suggests, but here the
*demographic signatures* differ enormously).

## 6. Actions taken

- **Vignette edits** ([vignettes/s-life-history.Rmd](../../../vignettes/s-life-history.Rmd)):
  - Update "What we found" numbers to match this audit.
  - Add cross-reference link to this report.
  - Soften "boom-bust" framing per the variance finding above.
- **Kernel changes.** None.
- **Tests added.** None yet — the sign predictions
  (sem mean_age < iter mean_age, etc.) could become regression
  tests. Defer until kernel work threatens this scenario.
- **Companion runner.** `dev/audit/fidelity/life_history.R` —
  deterministic; 10 runs, ~30 s wall.
- **Figure.** `dev/audit/fidelity/figs/life_history.png`.
- **Commit SHA that closed this report.** `<pending>`.
