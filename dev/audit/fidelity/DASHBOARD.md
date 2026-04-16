# Fidelity audit dashboard — 2026-04-16

One-page summary of all 35 scenarios after the 0.4.2→0.5.4 kernel
work. Counts reflect the current STATUS.md ledger.

## Verdict counts

| Status | Count | Scenarios |
|---|---|---|
| ✅ passed | **22** | baseline, bad-science, predator-prey, body-size, brain-size, pop-genetics, stress-hypermutation, complex-landscape, niche, seasonal, scavenging, kin, cooperation, signals, speciation, parental-care, life-history, clutch-size, parental-investment, pace-of-life, group-defense, rl, social-learning, map-elites, disease |
| 🟠 passed-consistent | **5** | dispersal-ifd, mating-systems, mimicry, plasticity, baldwin |
| ⚪ N/A | **5** | predation-neural, cephalopod, module-comparison, kitchen-sink, cross-module |
| 🔴 contradicts | **0** | — |

**Net: 22 ✅ / 5 🟠 / 0 🔴 out of 30 auditable scenarios (83% ✅).**

## 🟠 scenario detail

| Scenario | Theory | Blocker | Evidence strength | Path to ✅ |
|---|---|---|---|---|
| s-dispersal-ifd | Fretwell & Lucas 1970 | Signal saturates at +0.006 (below 0.02 threshold) at strength=2 | Grid-best at 2 seeds; directional | Longer runs (2000+ ticks) or tighter fitness-preference coupling |
| s-mating-systems | Hamilton 1980 Red Queen | Direction correct on average across 19 parameter regimes; magnitude ~+1% below 2×SE at 16 seeds | 448 total audit runs; long-run shows +1.8 ± 1.8 at 2000 ticks | 64-seed at 2000 ticks OR mixed-ploidy competition |
| s-mimicry | Bates 1862 / Müller 1879 | Zahavi handicap cost > benefit by ~10× at all 8 tested regimes | 40 calibration runs; kernel P3/P4 PASS, P2 ecology-limited | Bootstrapping (correlated signal+toxicity) OR much lower tox cost |
| s-plasticity | Pigliucci 2001 | Sigma mediates BOTH learning AND behavioural variance | 1500-tick direction correct (seasonal > stable) but magnitude +0.002 | Decouple sigma from behavioural variance in BNN |
| s-baldwin | Hinton & Nowlan 1987 | Same kernel limitation as plasticity | Transient canalisation at 600 ticks reverses at 1500 ticks | Same fix as plasticity (sigma decoupling) |

## Promotions this session (0.4.2→0.5.4)

| Scenario | Was | Now | Mechanism |
|---|---|---|---|
| s-brain-size | 🟠 | ✅ | 0.4.2 brain_energy_base override + 0.4.3 neonatal deficit / super-linear cost |
| s-rl | 🟠 | ✅ | 0.4.1 Tier 5B bnn_sample_freq=5 |
| s-group-defense | 🟠 | ✅ | 0.4.1 dose-response grid at n_pred=30 |
| s-body-size | ✅ (with caveats) | ✅ (clean) | 0.5.2 16-seed P2 NULL resolution |
| s-map-elites | 🟠 | ✅ | 0.4.1 MAP-Elites default-mutation fix |
| s-baldwin | 🔴 | 🟠 | 0.4.0 Tier 5A + 0.4.1 Tier 5C (direction reversal from pre-0.4.0 🔴) |

## Retractions this session

| Claim | Source | Retracted in | Reason |
|---|---|---|---|
| Body-size P2 "detectability" (ratio 0.81) | 0.4.1 5-seed | 0.5.2 16-seed | Null within 2×SE |
| Body-size P2 "Shine acceleration" (ratio 1.08) | 0.4.3 5-seed | 0.5.2 16-seed | Same null |
| Red Queen "first sex > asex" (Δn +1.1) | 0.5.1 3-seed | 0.5.3 16-seed | 3-seed noise |
| Mimicry "21× fitness improvement" (CMA-ES) | vignette | 0.4.4 audit | Not reproduced |

## Honest nulls documented

| Finding | Evidence | Significance |
|---|---|---|
| Red Queen ~+1% effect at 2000 ticks | 96 runs, 3 regimes × 16 seeds | Direction correct, below 2×SE |
| Mimicry toxicity declines at all 8 regimes | 40 runs, Zahavi cost > benefit by ~10× | Ecology, not kernel, limitation |
| Baldwin equilibrium: transient canalisation disappears | 18 runs, 3 scales × 2 envs × 3 seeds × 1500 ticks | Sigma couples to behavioural variance |
| Continuous-trait parasites favour ASEX (anti-Red Queen) | 16-seed robust (Δn = −6.84 ± 3.12) | Expected kernel limitation (0.5.0) |

## Kernel modules added this session

| Module | File | Theory | Key spec |
|---|---|---|---|
| Graded predator sensing | sense.jl | Cooper & Frederick 2007 | `predator_sense_graded` |
| Neonatal foraging deficit | tick.jl | Aiello & Wheeler 1995 | `neonatal_foraging_deficit` |
| Super-linear brain cost | tick.jl | Isler & van Schaik 2009 | `brain_energy_size_exponent` |
| Aposematic pleiotropy | signals.jl | Endler 1988 | `signal_toxicity_coupling` |
| Vector-signal memory + delta-rule RW | mimicry.jl | Bates/Müller | `signal_memory` field |
| Coevolving parasites (continuous) | coevolving_parasite.jl | Hamilton 1980 | `coevolving_parasites` |
| Discrete-allele Red Queen | coevolving_parasite.jl + reproduce.jl | Hamilton 1980 | `n_parasite_loci` |
| Senescence vs max_age | death.jl | Gompertz 1825 | `senescence_rate > 0` |
| Signal input clamp | sense.jl | — | Bugfix |

## Total audit compute this session

~1200 simulation runs across all experiments (audit reruns, parameter
searches, 16-seed resolutions, long-run experiments, calibration grids).
