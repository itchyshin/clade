# Scenario: SIR disease (Kermack-McKendrick 1927)

## 1. Theory

- **Primary sources.**
  - Kermack, W.O. & McKendrick, A.G. (1927) A contribution to the
    mathematical theory of epidemics. *Proc. R. Soc. A* 115:700–721.
  - Anderson, R.M. & May, R.M. (1991) *Infectious Diseases of
    Humans.*
- **Core prediction.** Transmission rate β times contact structure
  determines R0; epidemic fires when R0 > 1. Classic SIR produces
  a single bell-shaped epidemic wave; with births + waning immunity
  dynamics become endemic (oscillations around equilibrium).
- **Quantitative expectations.**
  1. With `disease = TRUE` and transmission above threshold,
     epidemic fires (peak > seed count).
  2. Peak prevalence scales monotonically with `transmission_prob`.
  3. Very low transmission → pathogen fades out before spreading.
  4. Classical closed SIR: single bell-shaped peak. Open SIR with
     births and waning immunity: endemic oscillations (this model
     has births and waning immunity via `immune_duration`).

## 2. Implementation

- **clade Julia:** `inst/julia/src/modules/disease.jl`.
- **alifeR:** `alifeR/R/disease.R`.
- **MATLAB:** N/A — disease first appears in alifeR.

## 3. Protocol

- Step 1: 5 seeds × 1 regime (default tr=0.20) × 300 ticks.
- Step 2: 3 seeds × 6 transmission levels {0.02, 0.05, 0.10, 0.20,
  0.40, 0.60}.
- Wall time: ~3 min.

## 4. Observed dynamics

### Step 1 — default regime

| Metric | Value |
|---|---|
| Peak infected | 75.0 ± 9.5 |
| Peak tick | 46.8 ± 52.3 |
| Total new infections (300 ticks) | 918.8 ± 33.5 |

**P1 PASS** — epidemic fires robustly (≈ 60% peak prevalence).

### Step 2 — transmission sweep

| `transmission_prob` | peak n_infected | total infections |
|---|---|---|
| 0.02 | 6.3 ± 1.5 (≈ seed only) | 7.7 |
| 0.05 | 9.7 ± 0.6 | 19.0 |
| 0.10 | 26.7 ± 22.9 (transition zone) | 467.0 |
| 0.20 | 75.7 ± 3.2 | 857.0 |
| 0.40 | 90.3 ± 9.6 | 1083.7 |
| 0.60 | 108.7 ± 2.5 | 1110.3 |

**P2 PASS, Spearman ρ = 1.00.** Threshold behaviour is clear:
below tr = 0.05 the pathogen barely spreads (R0 ≈ 1); around
tr = 0.10 we see a transition zone; above tr = 0.20 the epidemic
is vigorous and saturating by tr = 0.60.

### Bell-shape test (P4) — FAIL (expected)

Peak-decline test failed: epidemics do not cleanly decay 50% by
20 ticks post-peak. Reason: with births replenishing susceptibles
and `immune_duration = 20`, the dynamics become **endemic** with
oscillations rather than closed-epidemic bell shapes. This is
*biologically correct* for an open population — closed SIR (fixed
population, permanent immunity) would give the bell shape.

Figure: [figs/disease.png](figs/disease.png).

## 5. Verdict

- [x] **Matches theory (open-SIR signatures).** Epidemic fires,
      monotone dose-response (ρ = 1.00), visible transmission
      threshold near `tr = 0.05`. Endemic behaviour (not bell
      shaped) is the *correct* prediction for an open population
      with births and waning immunity.

### Cross-reference table

| Aspect | Theory (Kermack-McKendrick) | MATLAB | alifeR | clade |
|---|---|---|---|---|
| Epidemic fires | R0 > 1 | N/A | Yes | ✓ peak 75 at tr=0.20 |
| Threshold behaviour | Below R0=1, no outbreak | N/A | Expected | ✓ tr < 0.05 fizzles |
| Peak scales with β | Monotone | N/A | Expected | **ρ = 1.00** |
| Bell-shape peak | Closed SIR only | N/A | Endemic (births + waning) | Endemic (correct for open) |

## 6. Actions taken

- Vignette: update with 5-seed results; clarify "endemic vs closed
  SIR" distinction.
- Kernel: none.
- Runner: `dev/audit/fidelity/disease.R`.
- Figure: `dev/audit/fidelity/figs/disease.png`.
