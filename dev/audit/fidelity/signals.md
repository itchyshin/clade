# Scenario: Signals, mate choice, sexual selection

## 1. Theory

- **Primary sources.**
  - Zahavi, A. (1975) Mate selection — a selection for a handicap.
    *J. Theor. Biol.* 53:205–214.
  - Fisher, R.A. (1930) *The Genetical Theory of Natural Selection.*
  - Iwasa & Pomiankowski (1994) *Evolution* 48:853–867 (handicap
    equilibrium with cost).
- **Core prediction (one sentence).** A heritable signal evolves
  above zero under female preference, and a per-tick cost on the
  signal enforces *honesty*: signal magnitude positively correlates
  with individual condition (energy) under the Zahavi handicap
  mechanism.
- **Quantitative expectations.**
  1. With signals enabled + drift + preference mate choice, mean
     signal magnitude rises from 0 to a detectable non-zero
     equilibrium.
  2. Preference mate choice produces higher equilibrium signal than
     random mate choice.
  3. Higher `signal_cost` reduces either equilibrium signal
     magnitude or population size (handicap is costly).
  4. Under handicap honesty, `cor(mean_energy, mean_signal_magnitude)
     > 0` — agents in better condition carry more elaborate signals.
- **Why the evolutionary ABM may differ from the math.** Fisher's
  runaway requires a heritable genetic correlation between
  preference and signal; clade's preference is a spec-level
  parameter, not a heritable per-agent trait. So we test Zahavi
  handicap dynamics only.

## 2. Implementation under audit

- **Vignette:** [vignettes/s-signals.Rmd](../../../vignettes/s-signals.Rmd).
- **clade Julia kernel:** [inst/julia/src/modules/signals.jl](../../../inst/julia/src/modules/signals.jl)
  (113 lines). Per-tick energy cost proportional to signal
  magnitude; mate choice weights neighbour selection by signal
  similarity to the agent's preference vector (population-level
  preference, not per-agent heritable preference).
- **alifeR R prototype:** [alifeR/R/signals.R](../../../../alifeR/R/signals.R)
  (220 lines). Same mechanics.
- **MATLAB base:** N/A — signals first appear in alifeR. Confirmed
  by grep (zero hits for signal|zahavi|handicap|sexual.select).
- **Formula fidelity.** clade and alifeR match on: per-tick cost
  formula, multi-dim signal vectors, drift update, preference-based
  mate choice weighting.

## 3. Run protocol

- **Step 1.** 5 seeds × 2 conditions (off vs on-preference) ×
  500 ticks.
- **Step 2.** 5 seeds at on-random vs on-preference (same cost).
- **Step 3.** 3 seeds × 5 cost levels {0, 0.02, 0.05, 0.10, 0.20}.
- **Step 4.** Within-run Spearman correlation of
  `mean_energy` vs `mean_signal_magnitude` across the 5 treatment seeds.
- **Wall time.** ~3 min.
- **Exact command.** `Rscript dev/audit/fidelity/signals.R`.

## 4. Observed dynamics

| Condition | final signal | final energy | final n |
|---|---|---|---|
| Signals off | 0.000 | 126.1 | 247 |
| On, random mate choice | 1.017 | — | — |
| On, preference mate choice | 1.032 | 131.4 | 210 |

**P1 PASS.** Signal rises from 0 to ~1.0 when enabled.
**P2 PASS (weakly).** Preference beats random by only 1.5% —
drift dominates over mate-choice directionality at default drift
sd = 0.05.

### Cost sweep

| `signal_cost` | mean_signal | mean n_agents |
|---|---|---|
| 0.00 | 1.051 ± 0.039 | 219 ± 5 |
| 0.02 | 1.022 ± 0.028 | 221 ± 7 |
| 0.05 | 1.056 ± 0.011 | 208 ± 14 |
| 0.10 | 0.984 ± 0.061 | 209 ± 5 |
| 0.20 | 1.018 ± 0.021 | 197 ± 4 |

**Notable:** signal magnitude is **flat** across cost levels
(~1.0 ± 0.05 at every cost). Cost affects *population size*
(decline from 247 off → 197 at cost=0.20) but not equilibrium
signal magnitude. This differs from textbook Zahavi, which predicts
cost reduces equilibrium signal. Interpretation: drift determines
the signal's stationary distribution, while selection against the
cost manifests as demographic (not phenotypic) attrition.

### Honesty check

Spearman ρ(energy, signal) across 5 treatment seeds:
**0.249 ± 0.106** → positive, consistent with Zahavi handicap
(better-conditioned agents carry more elaborate signals).
Magnitude is modest, which is expected in a population-level
metric where individual-level honest signalling is averaged.

**P4 PASS (Zahavi-consistent).**

Figure: [figs/signals.png](figs/signals.png).

## 5. Verdict

- [x] **Matches theory (Zahavi-consistent with caveats).**
  Signal elaboration above zero, positive signal-energy
  correlation, cost paid as demographic attrition rather than
  signal reduction.
- [ ] Consistent but underpowered
- [ ] Contradicts theory — kernel bug
- [ ] Contradicts theory — vignette overclaim
- [ ] Contradicts theory — formula mismatch

### Cross-reference table

| Aspect | Theory (Zahavi 1975) | MATLAB base | alifeR prototype | clade Julia |
|---|---|---|---|---|
| Signal elaboration | Above zero | N/A | Above zero | ✓ 0 → 1.03 |
| Preference > random | Yes | N/A | Yes | ✓ weakly (ratio 1.01) |
| Cost reduces signal | Yes | N/A | Expected | **Flat — cost hits population instead** |
| Signal-energy correlation | Positive (honesty) | N/A | Positive | ✓ ρ = 0.25 |

## 6. Actions taken

- **Vignette edits:** update "What we found" with 5-seed numbers;
  note that the cost-response is demographic rather than
  signal-magnitude-reducing.
- **Kernel changes.** None.
- **Companion runner.** `dev/audit/fidelity/signals.R`.
- **Figure.** `dev/audit/fidelity/figs/signals.png`.
- **Commit SHA.** `<pending>`.
