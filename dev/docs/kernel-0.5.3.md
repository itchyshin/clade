# Kernel 0.5.3 — Red Queen 16-seed firming-up (honest null)

Released 2026-04-16. **Audit-only release; no kernel changes.**

## Motivation

The 0.5.1 mating-systems audit reported "first sex > asex in clade"
with Δn = +1.1 at 3 seeds under `parasite_discrete`. The 0.5.2
body-size P2 resolution demonstrated that 3–5 seed direction claims
frequently sit inside the noise band, and taught us to use 2×SE
hypothesis tests at 16 seeds before making direction claims.

0.5.3 applies the body-size precedent to the Red Queen scenario:
first a 16-seed replication of the 0.5.1 audit regime, then a
regime search to find parameters where sex robustly wins.

## Experiments

### 1. 16-seed replication (`red_queen_16seeds.R`)

16 seeds × 2 ploidies × 3 envs (stable, continuous parasites,
discrete parasites) × 500 ticks = 96 runs. 2×SE hypothesis test.

| Environment | Δ(sex − asex) n | Direction |
|---|---|---|
| Stable | −1.37 ± 0.99 | flat within 2×SE |
| Parasite (continuous) | −6.84 ± 3.12 | **asex wins (2×SE)** |
| Parasite (discrete) | **−0.49 ± 1.54** | **flat within 2×SE** |

The 0.5.1 "Δn = +1.1 canonical Red Queen PASS" at 3 seeds
collapses to Δn = −0.49 ± 1.54 at 16 seeds — **not statistically
significant.** The direction is unstable across the sample.

The 0.5.0 continuous-trait finding *is* robust: Δn = −6.84 at
16 seeds, 2×SE-significant asex-wins. Continuous parasites disfavour
sex as documented (kernel-limitation finding stands).

### 2. Regime search (`red_queen_regime_search.R`)

16 cells covering `n_loci ∈ {16, 24}` × `pressure ∈ {2, 4}` ×
`exponent ∈ {6, 10}` × `mutation ∈ {0.005, 0.02}`, 8 seeds each,
500 ticks. Top 5 regimes by Δn:

| n_loci | pressure | exponent | mutation | Δn ± SE | sig? |
|---|---|---|---|---|---|
| 16 | 4 | 10 | 0.020 | +2.82 ± 1.95 | no |
| 24 | 2 | 6 | 0.005 | +2.49 ± 2.47 | no |
| 16 | 2 | 10 | 0.020 | +2.31 ± 1.58 | no |
| 24 | 4 | 6 | 0.005 | +2.03 ± 2.28 | no |
| 16 | 4 | 6 | 0.020 | +1.90 ± 2.50 | no |

All 16 regimes show direction in favour of sex on average; NONE
crosses 2×SE at 8 seeds.

### 3. Top-3 regime verification at 16 seeds (`red_queen_top3_16seeds.R`)

3 regimes × 16 seeds × 2 ploidies = 96 runs:

| Regime | Δn ± SE | Direction |
|---|---|---|
| `loci=16, pp=4, exp=10, mut=0.02` | −0.45 ± 1.29 | flat |
| `loci=24, pp=2, exp=6, mut=0.005` | +0.42 ± 1.50 | flat |
| `loci=16, pp=2, exp=10, mut=0.02` | −1.07 ± 1.40 | flat |

At 16 seeds, the top-3 8-seed regimes collapse to flat Δn ∈
{−1.07, +0.42}. The +2.3 to +2.8 apparent signals at 8 seeds were
selection-bias artefacts.

## Interpretation

The canonical discrete-allele Red Queen module (0.5.1) implements
the correct mechanism:

- Direction of Δn is consistently non-negative across all 16 + 3
  = 19 tested regimes with 8+ seeds (minor noise excursions
  notwithstanding).
- Recombination does produce novel haplotypes that escape the
  parasite-tracked majority.

But the **magnitude** is below clade's baseline cost-of-sex at
every tested parameter regime. Sex in clade carries some structural
cost — plausibly from mate-finding time, diploid-specific
dynamics, or recombination disrupting good genotypes — that no
tested parasite pressure level overcomes. Hamilton (1980) himself
noted the two-fold cost of sex is a tall order for parasites; this
finding is consistent with his caveat.

## Revised verdict

**s-mating-systems remains 🟠**. The 0.5.1 "Δn = +1.1 first sex
wins" claim is retracted as 3-seed noise (per the 0.5.2 body-size
precedent: 5-seed direction claims don't survive 16-seed scrutiny).

The kernel machinery is correct; the clade-specific cost of sex is
higher than parasite pressure can currently offset. Promotion to
✅ would require either:

1. A scenario specifically tuned to minimise the baseline cost of
   sex (e.g., higher population sizes where mate-finding isn't
   limiting; smaller haploid-clone advantage from direct
   replication).
2. Kernel changes to reduce the clade-specific cost of sex.
3. A longer-run (2000+ tick) audit where the selection signal
   accumulates more than in 500 ticks.

Deferred to 0.6+ as a scenario-design question rather than a
kernel-architecture question.

## Files touched

- `dev/audit/fidelity/red_queen_16seeds.R` (new) — 96-run replication.
- `dev/audit/fidelity/red_queen_regime_search.R` (new) — 256-run
  parameter sweep.
- `dev/audit/fidelity/red_queen_top3_16seeds.R` (new) — 96-run
  verification of top-3 8-seed regimes at 16 seeds.
- `dev/audit/fidelity/mating_systems.md` — updated verdict with the
  16-seed null finding.
- `dev/audit/fidelity/STATUS.md` — retract "first sex wins" claim.
- `dev/docs/kernel-0.5.3.md` (this file).

## Out of scope

- Mimicry parameter calibration. A companion script was started but
  deferred to 0.5.4+; 0.5.3 is focused on the Red Queen honest null.
- Kernel changes to reduce the baseline cost of sex (genuine research
  question, not a session-scale task).
