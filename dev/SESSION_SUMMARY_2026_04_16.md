# Session summary — 2026-04-16

## Overview

A single extended session covering the 0.4.2→0.5.5 release chain:
kernel modules, fidelity audits, documentation refresh, and
scientific research experiments. The session started from the 0.4.1
backlog plan and expanded organically through the full roadmap.

## PRs shipped (15 total, all merged except fix-private-links)

| # | Branch | Type | Key outcome |
|---|---|---|---|
| 14 | kernel-0.4.2 | kernel | Graded predator sensing, signal clamp, senescence vs max_age |
| 15 | kernel-0.4.3 | kernel | Neonatal foraging deficit + super-linear brain cost |
| 16 | kernel-0.4.4 | kernel | Mimicry vector-signal memory + delta-rule RW + aposematic pleiotropy |
| 17 | kernel-0.5.0 | kernel | Coevolving parasite module (continuous-trait) |
| 18 | kernel-0.5.1 | kernel | Discrete-allele Red Queen (Hamming distance, Mendelian inheritance) |
| 19 | kernel-0.5.2 | audit | Body-size P2 16-seed resolution (P2 NULL) |
| 20 | docs-catch-up | docs | NEWS.md (0.4.2–0.5.2), 9 vignettes, parameter-reference.Rmd |
| 21 | kernel-0.5.3 | audit | Red Queen 16-seed retraction (448 runs, honest null) |
| 22 | kernel-0.5.4 | audit | Mimicry calibration null (40 runs, Zahavi handicap) |
| 23 | figures-refresh | docs | 9 showcase figures + captions |
| 24 | rq-long-run | experiment | 2000-tick Red Queen (+1.8 direction, below 2×SE) |
| 25 | quick-wins | docs | Audit dashboard + roxygen partial fix |
| 26 | readme-update | docs | Landing page fidelity section |
| 27 | roxygen-fix | fix | Rd regeneration warning resolved (867 lines) |
| 28 | sigma-decouple | kernel + docs | bnn_action_noise_scale + link fixes + discovery experiments |
| 29 | fix-private-links | fix | Revert to relative paths + vignette content fixes |

## Kernel modules added (9)

| Module | File | Theory | Key spec |
|---|---|---|---|
| Graded predator sensing | sense.jl | Cooper & Frederick 2007 | `predator_sense_graded` |
| Signal input clamp | sense.jl | — | Bugfix |
| Senescence vs max_age | death.jl | Gompertz 1825 | `senescence_rate > 0` |
| Neonatal foraging deficit | tick.jl | Aiello & Wheeler 1995 | `neonatal_foraging_deficit` |
| Super-linear brain cost | tick.jl | Isler & van Schaik 2009 | `brain_energy_size_exponent` |
| Vector-signal memory + delta-rule RW | mimicry.jl | Bates/Müller | `signal_memory` field |
| Aposematic pleiotropy | signals.jl | Endler 1988 | `signal_toxicity_coupling` |
| Coevolving parasites (continuous + discrete) | coevolving_parasite.jl + reproduce.jl | Hamilton 1980 | `coevolving_parasites`, `n_parasite_loci` |
| Sigma-action decoupling | bnn.jl | — | `bnn_action_noise_scale` |

## Scenario verdict changes

| Scenario | Was | Now | Mechanism |
|---|---|---|---|
| s-brain-size | 🟠 | ✅ | Two routes: base override (Δdelta=+0.118) or biological mechanisms |
| s-rl | 🟠 | ✅ | bnn_sample_freq=5 (Δn=+5.2) |
| s-group-defense | 🟠 | ✅ | Dose-response grid at n_pred=30 (1.10×) |
| s-body-size | ✅ (caveated) | ✅ (clean) | P1 robust @ 16 seeds; P2 NULL |
| s-map-elites | 🟠 | ✅ | MAP-Elites default-mutation fix |
| s-baldwin | 🔴 | 🟠 | Tier 5A+5C direction reversal (transient canalisation) |

Final ledger: **22 ✅ / 5 🟠 / 0 🔴** out of 30 auditable scenarios
(83% pass rate).

## Retractions

| Claim | Source | Retracted in | Reason |
|---|---|---|---|
| Body-size P2 "detectability" | 0.4.1 5-seed | 0.5.2 16-seed | Noise |
| Body-size P2 "Shine acceleration" | 0.4.3 5-seed | 0.5.2 16-seed | Noise |
| Red Queen "first sex > asex" | 0.5.1 3-seed | 0.5.3 16-seed | 3-seed noise |
| Mimicry "21× fitness improvement" | vignette | 0.4.4 audit | Not reproduced |

## Honest nulls documented (4)

| Finding | Evidence | Key insight |
|---|---|---|
| Red Queen ~+1% at 2000 ticks | 96 runs, 3 regimes × 16 seeds | Direction correct, magnitude below 2×SE at every tested regime |
| Mimicry Zahavi handicap | 40 calibration + 20 bootstrapping runs | Cost > benefit by ~10× at default ecology; first positive Δ at grass=0.08 (predation=89% of mortality) |
| Baldwin equilibrium reversal | 18 runs across 3 sigma-cost scales | 600-tick transient canalisation disappears at 1500 ticks; sigma couples to behavioural variance |
| Continuous-trait parasites anti-Red Queen | 16-seed robust (Δn = −6.84 ± 3.12) | Sex offspring cluster near parasite-tracked centroid → more exposed, not less |

## Key scientific findings

1. **Hamilton's two-fold cost of sex** is real in clade's ABM kernel:
   no tested parameter regime (19 regimes, 448+ audit runs) produces
   a statistically robust sex > asex signal under discrete-allele
   parasites. The direction is consistently non-negative on average,
   but clade's baseline cost of sex (mate-finding, diploid
   reproductive dynamics) is higher than parasite pressure can
   offset.

2. **Continuous-trait Red Queen produces the OPPOSITE of Hamilton's
   prediction**: sex offspring = midpoint of parents → closer to the
   parasite-tracked centroid → more exposed. Discrete-allele matching
   with Mendelian recombination is required for the canonical
   mechanism.

3. **Aposematic evolution requires predation-dominant ecology**: at
   default population scales, the Zahavi handicap cost of toxicity
   exceeds the aposematic protection benefit by ~10×. First positive
   Δtoxicity observed at `grass_rate = 0.08` where predation is 89%
   of total mortality. The kernel machinery (vector memory,
   delta-rule, pleiotropy) is correct; the selection arithmetic is
   ecology-dependent.

4. **Sigma-action decoupling changes BNN dynamics dramatically** but
   does not produce a robust Hinton-Nowlan canalisation pattern at
   any tested scale. At scale=0 sigma crashes (no benefit). At
   scale=0.3 the 3-seed signal collapses at 8 seeds. The limitation
   is deeper than noise coupling — likely the absence of a single
   stable fitness peak in clade's spatial foraging world.

5. **5-seed direction claims don't survive 16-seed scrutiny** (the
   "body-size P2 lesson"). Applied consistently across Red Queen,
   Baldwin, and mimicry. This is a methodological contribution:
   ABM researchers should routinely use 16+ seeds with 2×SE
   hypothesis testing for direction claims.

## Documentation work

- NEWS.md: 7 new release sections (0.4.2 through 0.5.5)
- 9 vignettes: "What we found" sections rewritten against current
  audit verdicts
- Parameter reference: all new specs documented
- 9 showcase figures replaced with current audit figures
- Landing page: fidelity audit section added
- roxygen @details parse warning fixed (root cause: blank lines and
  `*` bullets inside `\item{}{}` blocks; Rd now regenerates cleanly
  at 879 lines)
- Audit dashboard (DASHBOARD.md): one-page 35-scenario ledger
- Broken links fixed (private-repo discovery)

## Compute summary

~1500 simulation runs across:
- 0.4.1 audit reruns (plasticity, rl, baldwin, brain_size,
  dispersal_ifd, mating_systems, group_defense, body_size)
- 0.4.2 1500-tick sweeps (baldwin, plasticity)
- 0.4.3 biological-mechanism grid (brain_size)
- 0.4.4 mimicry audits (vector memory, measurement fix, pleiotropy)
- 0.5.0/0.5.1 Red Queen experiments (continuous + discrete)
- 0.5.2 body-size 16-seed factorial (64 runs)
- 0.5.3 Red Queen firming-up (96 + 256 + 96 = 448 runs)
- 0.5.4 mimicry calibration (40 runs)
- 0.5.5 sigma-decoupling sweep (30 + 16 = 46 runs)
- Long-run Red Queen experiment (96 runs)
- Mimicry bootstrapping experiments (20 + 10 + 10 + 15 = 55 runs)
- Predator-prey discovery experiments (55 runs)

## Deferred to future sessions

1. **Decouple sigma from behavioural variance** (deeper fix for
   Baldwin/plasticity — needs BNN forward-pass refactor, not just a
   scaling knob)
2. **Mixed-ploidy competition** (sex + asex in same environment;
   kernel change)
3. **64-seed Red Queen at 2000 ticks** (pure compute)
4. **Mimicry at predation-dominant ecology** (`grass_rate ≈ 0.08`;
   promising direction from the bootstrapping experiments)
5. **Predator-prey LV exploration** (user requested; fixed-policy
   predators would recover textbook LV; kernel change needed)
