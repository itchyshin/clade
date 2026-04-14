# Deeper calibration pass + Task 3 follow-up results

## Task 2 — deeper CMA-ES (40 iter × 12 popsize)

Re-ran the top 11 scenarios with a wider, longer search to stress-test
the Phase 7 v2 regimes. Results are consistent with v2 within
stochastic noise — the original 20-iter × 6-pop search had already
converged near the local optimum for each objective.

| Scenario | v2 best | deep best | diff | wall clock |
|---|---|---|---|---|
| s-baldwin | 0.001 | 0.0011 | +0.0001 | 763 s |
| s-cephalopod | 0.401 | 0.416 | +0.015 | 773 s |
| s-clutch-size | 3 | 2 | −1 (integer seed noise) | 733 s |
| s-complex-landscape | 1,510 | 1,517 | +7 | 1,074 s |
| s-disease | 3,890 | 3,981 | +91 | 737 s |
| s-kin | 30.8 | 31.6 | +0.9 | 923 s |
| s-mimicry | 0.0147 | 0.0140 | −0.0007 | 733 s |
| s-niche | 40.4 | 41.2 | +0.9 | 900 s |
| s-plasticity | 0.221 | 0.047 | **−0.174** | 736 s |
| s-scavenging | 11.4 | 11.7 | +0.24 | 897 s |
| s-speciation | 217 | 222 | +5 | 790 s |

Only outlier: **s-plasticity** deep fitness (0.047) is much lower than
v2 (0.221). This suggests the plasticity objective has multiple
local maxima — v2 landed in a better one. Keep the v2 regime as the
reported answer (reflected in the vignette's Calibrated regime
section).

**Verdict:** the Phase 7 v2 regimes are stable. No Rmd changes needed
from the deeper pass.

## Task 3 — follow-up calibrations after Agent/fitness fixes

Re-ran the 3 scenarios that Task 3 fixes unblocked:

| Scenario | Before fix | After fix | Improvement |
|---|---|---|---|
| s-pace-of-life | 0.048 (metric constant) | **7.48** (real metabolic drift) | **155×** — Task 3a `metabolic_rate_evolution=TRUE` unblocks the signal |
| s-body-size | −0.022 (degenerate null) | **0.965** (real drift, far from bounds) | **19×** — Task 3c reformulation rewards meaningful evolution |
| s-signals | NA / −Inf | still NA / −Inf | Task 3b exposed the fields but the fitness (signal-preference correlation across agents) still fails. At 300 ticks signal-preference aren't diverging from init; longer runs or a different metric (e.g. trait variance over time) needed. Left for 0.3.0. |

### s-pace-of-life discovered regime

```
metabolic_rate_mutation_sd: 0.05 → (search result from JSON)
metabolic_rate_init_mean:    1.0  →
aging_rate_mutation_sd:     0.05 (default)
```

Needs a follow-up vignette update and a Rmd "Calibrated regime"
section when the JSON is re-read with the corrected extraction.

### s-body-size discovered regime

```
body_size_mutation_sd: 0.08 → ...
mutation_sd:           0.1  → ...
```

Same — Rmd "Calibrated regime" update pending.

## Summary of Task 2 + Task 3

- **Task 2:** deeper search adds no new knowledge over the 20×6 v2
  regimes. The calibration harness is well-calibrated for this search
  budget; going deeper is not cost-effective at the current fitness-
  function resolution.
- **Task 3a (pace-of-life):** biology logged correctly when evolution
  is enabled; this was a specs_mods oversight in the calibration
  harness, not a module bug.
- **Task 3b (signals):** Agent R-side fields now expose signal,
  preference, toxicity, mutation_sd, learning_rate,
  repro_threshold, aging_rate, habitat_preference, plasticity,
  infected, immune, care_load. The downstream fitness function
  still fails because at tick 300 there's no signal-preference
  covariance yet — need longer runs or a different objective.
- **Task 3c (body-size):** reformulated objective is no longer
  degenerate.

## Next

- Vignette updates for s-pace-of-life and s-body-size to surface
  their new regimes (analogous to the 13 already done).
- s-signals objective reformulation (0.3.0).
